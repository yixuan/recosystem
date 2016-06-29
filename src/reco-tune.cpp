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
#include "reco-read-data.h"

using namespace mf;

struct TuneOption
{
    mf_parameter param;
    mf_int       nr_folds;
    
    TuneOption() : param(mf_get_default_param()), nr_folds(5) {}
};

TuneOption parse_tune_option(SEXP opts_)
{
    Rcpp::List opts(opts_);
    TuneOption option;

    // k, lambda_* and eta are tuning parameters. They will be set in the main
    // program.

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
    option.param.do_nmf = Rcpp::as<bool>(opts["nmf"]);

    // Verbose or not
    option.param.quiet = !(Rcpp::as<bool>(opts["verbose"]));

    // Whether to copy data matrix or not
    option.param.copy_data = false;

    return option;
}



RcppExport SEXP reco_tune(SEXP train_data_, SEXP opts_tune_, SEXP opts_other_)
{
BEGIN_RCPP

    Rcpp::DataFrame opts_tune(opts_tune_);
    Rcpp::IntegerVector tune_dim       = opts_tune["dim"];
    Rcpp::NumericVector tune_costp_l1  = opts_tune["costp_l1"];
    Rcpp::NumericVector tune_costp_l2  = opts_tune["costp_l2"];
    Rcpp::NumericVector tune_costq_l1  = opts_tune["costq_l1"];
    Rcpp::NumericVector tune_costq_l2  = opts_tune["costq_l2"];
    Rcpp::NumericVector tune_lrate     = opts_tune["lrate"];
    mf_long n = tune_dim.length();
    Rcpp::NumericVector rmse(n);

    TuneOption option = parse_tune_option(opts_other_);

    DataReader* data_reader;
    // TODO: construct data_reader from train_data
    
    mf_problem tr = read_data(data_reader);

    for(mf_long i = 0; i < n; i++)
    {
        if(!option.param.quiet)
        {
            Rcpp::Rcout << "============================"   << std::endl;
            Rcpp::Rcout << "dim:      " << tune_dim[i]      << std::endl;
            Rcpp::Rcout << "costp_l1: " << tune_costp_l1[i] << std::endl;
            Rcpp::Rcout << "costp_l2: " << tune_costp_l2[i] << std::endl;
            Rcpp::Rcout << "costq_l1: " << tune_costq_l1[i] << std::endl;
            Rcpp::Rcout << "costq_l2: " << tune_costq_l2[i] << std::endl;
            Rcpp::Rcout << "lrate:    " << tune_lrate[i]    << std::endl;
        }
        
        // Set value for k, lambda and eta
        option.param.k         = tune_dim[i];
        option.param.lambda_p1 = tune_costp_l1[i];
        option.param.lambda_p2 = tune_costp_l2[i];
        option.param.lambda_q1 = tune_costq_l1[i];
        option.param.lambda_q2 = tune_costq_l2[i];
        option.param.eta       = tune_lrate[i];

        rmse[i] = mf_cross_validation(&tr, option.nr_folds, option.param);
        
        if(!option.param.quiet)
            Rcpp::Rcout << "============================" << std::endl << std::endl;
    }

    delete[] tr.R;

    return rmse;

END_RCPP
}
