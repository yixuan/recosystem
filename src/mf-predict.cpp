#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <iomanip>
#include <memory>
#include <cmath>
#include <stdexcept>
#include <vector>

#include <Rcpp.h>

#include "mf.h"

using namespace mf;

RcppExport SEXP reco_predict(SEXP test, SEXP model, SEXP output)
{
BEGIN_RCPP

    std::string test_path = Rcpp::as<std::string>(test);
    std::string model_path = Rcpp::as<std::string>(model);
    std::string output_path = Rcpp::as<std::string>(output);

    std::ifstream f_te(test_path);
    if(!f_te.is_open())
        Rcpp::stop("cannot open " + test_path);

    std::ofstream f_out(output_path);
    if(!f_out.is_open())
        Rcpp::stop("cannot open " + output_path);

    mf_model *model = mf_load_model(model_path.c_str());
    if(model == nullptr)
        Rcpp::stop("cannot load model from " + model_path);

    mf_node N;
    while(f_te >> N.u >> N.v)
    {
        f_te.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        mf_float r = mf_predict(model, N.u, N.v);
        f_out << r << std::endl;
    }

    mf_destroy_model(&model);

    return R_NilValue;

END_RCPP
}
