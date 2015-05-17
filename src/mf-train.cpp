#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <cmath>
#include <stdexcept>
#include <algorithm>
#include <vector>

#include <Rcpp.h>

#include "mf.h"

using namespace std;
using namespace mf;

struct TrainOption
{
    TrainOption() : param(mf_get_default_param()), nr_folds(1), do_cv(false) {}
    string tr_path, va_path, model_path;
    mf_parameter param;
    mf_int nr_folds;
    bool do_cv;
};

TrainOption parse_train_option(Rcpp::CharacterVector train_path,
                               Rcpp::CharacterVector model_path,
                               Rcpp::List opts)
{
    TrainOption option;

    // Regularization parameter
    option.param.lambda = Rcpp::as<mf_float>(opts["cost"]);
    if(option.param.lambda < 0)
        throw invalid_argument("regularization parameter should not be smaller than zero");

    // Dimension
    option.param.k = Rcpp::as<mf_int>(opts["dim"]);
    if(option.param.k <= 0)
        throw invalid_argument("number of factors should be greater than zero");

    // Number of iterations
    option.param.nr_iters = Rcpp::as<mf_int>(opts["niter"]);
    if(option.param.nr_iters <= 0)
        throw invalid_argument("number of iterations should be greater than zero");

    // Learning rate
    option.param.eta = Rcpp::as<mf_float>(opts["lrate"]);
    if(option.param.eta <= 0)
        throw invalid_argument("learning rate should be greater than zero");

    // Number of threads
    option.param.nr_threads = Rcpp::as<mf_int>(opts["nthread"]);
    if(option.param.nr_threads <= 0)
        throw invalid_argument("number of threads should be greater than zero");

    // Whether perform NMF or not
    option.param.do_nmf = Rcpp::as<mf_int>(opts["nmf"]);

    // Verbose or not
    option.param.quiet = !(Rcpp::as<bool>(opts["verbose"]));

    // Path of validation set if specified, otherwise an empty string
    option.va_path = Rcpp::as<string>(opts["va_path"]);

    // If validation set is unspecified, use cross validation
    option.nr_folds = Rcpp::as<mf_int>(opts["nfold"]);
    if(option.nr_folds > 1)
        option.do_cv = true;

    // Path to training set
    option.tr_path = Rcpp::as<string>(train_path);

    // Path to model file
    option.model_path = Rcpp::as<string>(model_path);

    // Whether to copy data matrix or not
    option.param.copy_data = false;

    return option;
}

mf_problem read_problem(string path)
{
    mf_problem prob;
    prob.m = 0;
    prob.n = 0;
    prob.nnz = 0;
    prob.R = nullptr;

    if(path.empty())
    {
        return prob;
    }

    ifstream f(path);
    if(!f.is_open())
        throw runtime_error("cannot open " + path);
    string line;
    while(getline(f, line))
        prob.nnz++;

    mf_node *R = new mf_node[prob.nnz];

    f.close();
    f.open(path);

    mf_long idx = 0;
    for(mf_node N; f >> N.u >> N.v >> N.r;)
    {
        if(N.u+1 > prob.m)
            prob.m = N.u+1;
        if(N.v+1 > prob.n)
            prob.n = N.v+1;
        R[idx] = N;
        idx++;
    }

    prob.R = R;

    return prob;
}

RcppExport SEXP reco_train(Rcpp::CharacterVector train_path,
                           Rcpp::CharacterVector model_path,
                           Rcpp::List opts)
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

        string msg = "cannot save model to " + option.model_path;
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
