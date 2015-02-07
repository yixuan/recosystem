#include <Rcpp.h>
#include "mf.h"

using Rcpp::as;
using Rcpp::wrap;
using Rcpp::CharacterVector;

RcppExport SEXP output(SEXP model, SEXP P, SEXP Q)
{
BEGIN_RCPP

    std::string model_path = as<std::string>(model);
    CharacterVector P_path(P);
    CharacterVector Q_path(Q);

    std::shared_ptr<Model> model = read_model(model_path);
    if(!model)
        Rcpp::stop("Unable to read model file");
    
    int const dim = model->param.dim;
    int const dim_aligned = get_aligned_dim(dim);
    
    FILE *f;
    float *reader;
    
    if(P_path.length())
    {
        std::string P = as<std::string>(P_path);
        f = fopen(P.c_str(), "w");
        if(!f)
        {
            fclose(f);
            Rcpp::stop("Cannot write " + P);
        }
        
        for(int irow = 0; irow < model->nr_users; irow++)
        {
            reader = model->P + irow * dim_aligned;
            for(int icol = 0; icol < dim - 1; icol++, reader++)
            {
                fprintf(f, "%f ", *reader);
            }
            fprintf(f, "%f\n", *reader);
        }
        fclose(f);
    }
    
    if(Q_path.length())
    {
        std::string Q = as<std::string>(Q_path);
        f = fopen(Q.c_str(), "w");
        if(!f)
        {
            fclose(f);
            Rcpp::stop("Cannot write " + Q);
        }
        
        for(int irow = 0; irow < model->nr_items; irow++)
        {
            reader = model->Q + irow * dim_aligned;
            for(int icol = 0; icol < dim - 1; icol++, reader++)
            {
                fprintf(f, "%f ", *reader);
            }
            fprintf(f, "%f\n", *reader);
        }
        fclose(f);
    }

    return R_NilValue;
    
END_RCPP
}
