#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cmath>
#include <stdexcept>
#include <algorithm>

#include <Rcpp.h>
#include <Rcpp/unwindProtect.h>
#include "mf.h"
#include "reco-read-data.h"

using namespace mf;

mf_parameter parse_train_option(SEXP opts_)
{
    Rcpp::List opts(opts_);
    mf_parameter param = mf_get_default_param();

    // Regularization parameters
    param.lambda_p1 = Rcpp::as<mf_float>(opts["costp_l1"]);
    param.lambda_p2 = Rcpp::as<mf_float>(opts["costp_l2"]);
    param.lambda_q1 = Rcpp::as<mf_float>(opts["costq_l1"]);
    param.lambda_q2 = Rcpp::as<mf_float>(opts["costq_l2"]);
    if(param.lambda_p1 < 0 || param.lambda_p2 < 0 ||
       param.lambda_q1 < 0 || param.lambda_q2 < 0)
        throw std::invalid_argument("regularization parameters should not be negative");
    
    // Loss function
    param.fun = Rcpp::as<mf_int>(opts["loss"]);

    // Dimension
    param.k = Rcpp::as<mf_int>(opts["dim"]);
    if(param.k <= 0)
        throw std::invalid_argument("number of factors should be greater than zero");

    // Number of iterations
    param.nr_iters = Rcpp::as<mf_int>(opts["niter"]);
    if(param.nr_iters <= 0)
        throw std::invalid_argument("number of iterations should be greater than zero");

    // Learning rate
    param.eta = Rcpp::as<mf_float>(opts["lrate"]);
    if(param.eta <= 0)
        throw std::invalid_argument("learning rate should be greater than zero");

    // Number of threads
    param.nr_threads = Rcpp::as<mf_int>(opts["nthread"]);
    if(param.nr_threads <= 0)
        throw std::invalid_argument("number of threads should be greater than zero");

    // Number of bins
    param.nr_bins = Rcpp::as<mf_int>(opts["nbin"]);
    if(param.nr_bins <= 0 || param.nr_bins <= param.nr_threads)
        throw std::invalid_argument("number of bins should be greater than number of threads");
    
    // Whether to perform NMF or not
    param.do_nmf = Rcpp::as<bool>(opts["nmf"]);

    // Verbose or not
    param.quiet = !(Rcpp::as<bool>(opts["verbose"]));

    // Whether to copy data matrix or not
    param.copy_data = false;

    return param;
}

SEXP safe_mat(void *size_)
{
    int *size = (int*)size_;
    return Rcpp::IntegerMatrix(size[0], size[1]);
}

SEXP safe_scalar(void *size_)
{
    return Rcpp::IntegerVector(1);
}

RcppExport SEXP reco_train(SEXP train_data_, SEXP model_path_, SEXP opts_)
{
BEGIN_RCPP

    DataReader* data_reader = get_reader(train_data_);

    std::string model_path;
    if (model_path_ != R_NilValue)
        model_path = Rcpp::as<std::string>(model_path_);
    mf_parameter param = parse_train_option(opts_);

    mf_problem tr = read_data(data_reader);
    mf_model* model = mf_train(&tr, param);
    mf_int status = 0;
    if (model_path_ != R_NilValue)
        status = mf_save_model(model, model_path.c_str());

    if(status != 0)
    {
        mf_destroy_model(&model);
        delete[] tr.R;

        std::string msg = "cannot save model to " + model_path;
        Rcpp::stop(msg.c_str());
    }

    Rcpp::List model_param = Rcpp::List::create(
        Rcpp::Named("nuser") = Rcpp::wrap(model->m),
        Rcpp::Named("nitem") = Rcpp::wrap(model->n),
        Rcpp::Named("nfac")  = Rcpp::wrap(model->k)
    );

    if (model_path_ == R_NilValue) {
        try
        {
            int size_P[] = {model->k, model->m};
            int size_Q[] = {model->k, model->n};
            Rcpp::List matrices = Rcpp::List::create(
                Rcpp::_["P"] = Rcpp::unwindProtect(safe_mat, &size_P),
                Rcpp::_["Q"] = Rcpp::unwindProtect(safe_mat, &size_Q),
                Rcpp::_["b"] = Rcpp::unwindProtect(safe_scalar, (void*)nullptr)
            );
            memcpy((float*)INTEGER(matrices["P"]), model->P, (size_t)model->k*(size_t)model->m*sizeof(float));
            memcpy((float*)INTEGER(matrices["Q"]), model->Q, (size_t)model->k*(size_t)model->n*sizeof(float));
            *((float*)INTEGER(matrices["b"])) = model->b;
            model_param["matrices"] = matrices;
        }

        catch(const std::exception& e)
        {
            mf_destroy_model(&model);
            delete [] tr.R;
            delete data_reader;
            throw e;
        }
    }

    mf_destroy_model(&model);
    delete [] tr.R;
    delete data_reader;

    return model_param;

END_RCPP
}
