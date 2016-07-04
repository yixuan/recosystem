#include <Rcpp.h>
#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
#include "mf.h"

using namespace mf;

RcppExport SEXP reco_output_memory(SEXP model)
{
BEGIN_RCPP

    std::string model_path = Rcpp::as<std::string>(model);

    mf_model *model = mf_load_model(model_path.c_str());
    if(model == nullptr)
        Rcpp::stop("cannot load model from " + model_path);

    Rcpp::NumericVector P(model->k * model->m);
    Rcpp::NumericVector Q(model->k * model->n);

    // Note: conversion from float to double here
    std::copy(model->P, model->P + model->m * model->k, P.begin());
    std::copy(model->Q, model->Q + model->n * model->k, Q.begin());

    mf_destroy_model(&model);

    return Rcpp::List::create(
        Rcpp::Named("Pdata") = P,
        Rcpp::Named("Qdata") = Q
    );

END_RCPP
}

RcppExport SEXP reco_output(SEXP model, SEXP P, SEXP Q)
{
BEGIN_RCPP

    std::string model_path = Rcpp::as<std::string>(model);
    std::string P_path = Rcpp::as<std::string>(P);
    std::string Q_path = Rcpp::as<std::string>(Q);

    std::ifstream f(model_path);
    if(!f.is_open())
        Rcpp::stop("cannot open " + model_path);

    // Get dimensions
    std::string line;
    // mf_int m, n, k;
    mf_int m, n;
    std::getline(f, line);
    m = atoi(line.substr(line.find(' ') + 1).c_str());
    std::getline(f, line);
    n = atoi(line.substr(line.find(' ') + 1).c_str());
    std::getline(f, line);
    // k = atoi(line.substr(line.find(' ') + 1).c_str());

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
            // Remove the beginning pos+1 characters, and the space at the tail
            fp << line.substr(pos + 1, line.length() - pos - 2) << std::endl;
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
            // Remove the beginning pos+1 characters, and the space at the tail
            fq << line.substr(pos + 1, line.length() - pos - 2) << std::endl;
        }

        fq.close();
    }

    return R_NilValue;

END_RCPP
}
