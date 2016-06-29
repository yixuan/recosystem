#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cmath>
#include <stdexcept>
#include <algorithm>
#include <vector>

#include <Rcpp.h>

#include "mf.h"

using namespace mf;

struct TrainOption
{
    TrainOption() : param(mf_get_default_param()), nr_folds(1), do_cv(false) {}
    std::string tr_path, va_path, model_path;
    mf_parameter param;
    mf_int nr_folds;
    bool do_cv;
};

TrainOption parse_train_option(SEXP train_path_,
                               SEXP model_path_,
                               SEXP opts_)
{
    Rcpp::CharacterVector train_path(train_path_);
    Rcpp::CharacterVector model_path(model_path_);
    Rcpp::List opts(opts_);

    TrainOption option;

    // Regularization parameter
    option.param.lambda = Rcpp::as<mf_float>(opts["cost"]);
    if(option.param.lambda < 0)
        throw std::invalid_argument("regularization parameter should not be smaller than zero");

    // Dimension
    option.param.k = Rcpp::as<mf_int>(opts["dim"]);
    if(option.param.k <= 0)
        throw std::invalid_argument("number of factors should be greater than zero");

    // Number of iterations
    option.param.nr_iters = Rcpp::as<mf_int>(opts["niter"]);
    if(option.param.nr_iters <= 0)
        throw std::invalid_argument("number of iterations should be greater than zero");

    // Learning rate
    option.param.eta = Rcpp::as<mf_float>(opts["lrate"]);
    if(option.param.eta <= 0)
        throw std::invalid_argument("learning rate should be greater than zero");

    // Number of threads
    option.param.nr_threads = Rcpp::as<mf_int>(opts["nthread"]);
    if(option.param.nr_threads <= 0)
        throw std::invalid_argument("number of threads should be greater than zero");

    // Whether perform NMF or not
    option.param.do_nmf = Rcpp::as<mf_int>(opts["nmf"]);

    // Verbose or not
    option.param.quiet = !(Rcpp::as<bool>(opts["verbose"]));

    // Path of validation set if specified, otherwise an empty string
    option.va_path = Rcpp::as<std::string>(opts["va_path"]);

    // If validation set is unspecified, use cross validation
    option.nr_folds = Rcpp::as<mf_int>(opts["nfold"]);
    if(option.nr_folds > 1)
        option.do_cv = true;

    // Path to training set
    option.tr_path = Rcpp::as<std::string>(train_path);

    // Path to model file
    option.model_path = Rcpp::as<std::string>(model_path);

    // Whether to copy data matrix or not
    option.param.copy_data = false;

    return option;
}

RcppExport SEXP reco_train(SEXP train_path, SEXP model_path, SEXP opts)
{
BEGIN_RCPP

    TrainOption option = parse_train_option(train_path, model_path, opts);

    mf_problem tr, va;
    tr = read_problem(option.tr_path);
    va = read_problem(option.va_path);

    mf_model *model = mf_train_with_validation(&tr, &va, option.param);
    mf_int status = mf_save_model(model, option.model_path.c_str());

    if(status != 0)
    {
        mf_destroy_model(&model);

        delete[] tr.R;
        delete[] va.R;

        std::string msg = "cannot save model to " + option.model_path;
        Rcpp::stop(msg.c_str());
    }

    Rcpp::List model_param = Rcpp::List::create(
        Rcpp::Named("nuser") = Rcpp::wrap(model->m),
        Rcpp::Named("nitem") = Rcpp::wrap(model->n),
        Rcpp::Named("nfac") = Rcpp::wrap(model->k)
    );

    mf_destroy_model(&model);

    delete[] tr.R;
    delete[] va.R;

    return model_param;

END_RCPP
}
