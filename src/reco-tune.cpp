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

struct TuneOption
{
    TuneOption() : param(mf_get_default_param()), nr_folds(5) {}
    mf_parameter param;
    mf_int nr_folds;
};

TuneOption parse_tune_option(SEXP opts_)
{
    Rcpp::List opts(opts_);

    TuneOption option;

    // k, lambda and eta are tuning parameters. They will be set in the main
    // program. Here we just give some default values.

    // Dimension
    option.param.k = 10;
    // Regularization parameter
    option.param.lambda = 0.1;
    // Learning rate
    option.param.eta = 0.1;

    // Cross validation folds
    option.nr_folds = Rcpp::as<mf_int>(opts["nfold"]);
    if(option.nr_folds <= 1)
        throw std::invalid_argument("nfold should be greater than one");

    // Number of iterations
    option.param.nr_iters = Rcpp::as<mf_int>(opts["niter"]);
    if(option.param.nr_iters <= 0)
        throw std::invalid_argument("number of iterations should be greater than zero");

    // Number of threads
    option.param.nr_threads = Rcpp::as<mf_int>(opts["nthread"]);
    if(option.param.nr_threads <= 0)
        throw std::invalid_argument("number of threads should be greater than zero");

    // Whether to perform NMF or not
    option.param.do_nmf = Rcpp::as<mf_int>(opts["nmf"]);

    // Verbose or not
    option.param.quiet = !(Rcpp::as<bool>(opts["verbose"]));

    // Whether to copy data matrix or not
    option.param.copy_data = false;

    return option;
}

mf_problem read_data(std::string path)
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

    std::ifstream f(path);
    if(!f.is_open())
        throw std::runtime_error("cannot open " + path);
    std::string line;
    while(std::getline(f, line))
        prob.nnz++;

    mf_node *R = new mf_node[prob.nnz];

    f.close();
    f.open(path);

    mf_node N;
    mf_long idx = 0, lino = 0;
    for(lino = 0; lino < prob.nnz; lino++)
    {
        std::getline(f, line);
        std::stringstream ss(line);

        ss >> N.u >> N.v >> N.r;
        if(!ss)
            continue;

        if(N.u+1 > prob.m)
            prob.m = N.u+1;
        if(N.v+1 > prob.n)
            prob.n = N.v+1;
        R[idx] = N;
        idx++;
    }
    prob.nnz = idx;
    prob.R = R;

    return prob;
}

RcppExport SEXP reco_tune(SEXP train_path_, SEXP opts_tune_, SEXP opts_other_)
{
BEGIN_RCPP

    Rcpp::DataFrame opts_tune(opts_tune_);
    Rcpp::IntegerVector tune_dim   = opts_tune["dim"];
    Rcpp::NumericVector tune_cost  = opts_tune["cost"];
    Rcpp::NumericVector tune_lrate = opts_tune["lrate"];
    int n = tune_dim.length();
    Rcpp::NumericVector rmse(n);

    TuneOption option = parse_tune_option(opts_other_);

    std::string train_path = Rcpp::as<std::string>(train_path_);
    mf_problem tr = read_data(train_path);

    for(int i = 0; i < n; i++)
    {
        if(!option.param.quiet)
        {
            Rcpp::Rcout << "===== dim = " << tune_dim[i];
            Rcpp::Rcout << ", cost = " << tune_cost[i];
            Rcpp::Rcout << ", lrate = " << tune_lrate[i] << " =====" << std::endl;
        }
        
        // Set value for k, lambda and eta
        option.param.k      = tune_dim[i];
        option.param.lambda = tune_cost[i];
        option.param.eta    = tune_lrate[i];

        rmse[i] = mf_cross_validation(&tr, option.nr_folds, option.param);
        
        if(!option.param.quiet)
            Rcpp::Rcout << "==============" << std::endl << std::endl;
    }

    delete[] tr.R;

    return rmse;

END_RCPP
}
