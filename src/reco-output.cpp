#include <Rcpp.h>
#include <iostream>
#include <fstream>
#include <string>
#include "mf.h"

using namespace mf;

RcppExport SEXP reco_output(SEXP model, SEXP P, SEXP Q)
{
BEGIN_RCPP

    std::string model_path = Rcpp::as<std::string>(model);
    std::string P_path = Rcpp::as<std::string>(P);
    std::string Q_path = Rcpp::as<std::string>(Q);

    std::ifstream f(model_path.c_str());
    if(!f.is_open())
        Rcpp::stop("cannot open " + model_path);

    // Get dimensions
    std::string line;
    mf_int m, n, k;
    std::getline(f, line);
    m = std::stoi(line.substr(line.find(' ') + 1));
    std::getline(f, line);
    n = std::stoi(line.substr(line.find(' ') + 1));
    std::getline(f, line);
    k = std::stoi(line.substr(line.find(' ') + 1));

    // Writing P matrix
    if(!P_path.empty())
    {
        std::ofstream fp(P_path);
        if(!fp.is_open())
            Rcpp::stop("cannot write " + P_path);

        for(mf_int i = 0; i < m; i++)
        {
            std::getline(f, line);
            std::size_t pos = line.find(' ');
            fp << line.substr(pos + 1) << std::endl;
        }

        fp.close();
    } else {
        // Skip m lines
        for(mf_int i = 0; i < m; i++)
            f.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    }

    // Writing Q matrix
    if(!Q_path.empty())
    {
        std::ofstream fq(Q_path);
        if(!fq.is_open())
            Rcpp::stop("cannot write " + Q_path);

        for(mf_int i = 0; i < n; i++)
        {
            std::getline(f, line);
            std::size_t pos = line.find(' ');
            fq << line.substr(pos + 1) << std::endl;
        }

        fq.close();
    }

    return R_NilValue;

END_RCPP
}
