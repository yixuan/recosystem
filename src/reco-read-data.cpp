#include "reco-read-data.h"

using namespace mf;

// An mf_problem stands for a data object
mf_problem read_data(DataReader* reader)
{
    // Default empty data object
    mf_problem prob;
    prob.m = 0;
    prob.n = 0;
    prob.nnz = 0;
    prob.R = nullptr;

    if(!reader->is_valid())
        return prob;
    
    // Upper limit of nnz
    mf_long max_nnz = reader->count();

    // We have to allocate R to the maximum length
    // In reality if there exist invalid lines in the file, for example,
    // prob.nnz will be smaller than max_nnz
    mf_node *R = new mf_node[max_nnz];

    // Read data
    mf_node N;
    mf_long idx = 0;
    reader->open();
    for(mf_long lino = 1; lino <= max_nnz; lino++)
    {
        bool status = reader->next(N.u, N.v, N.r);
        // If status is false, then an error occurs in this line
        if(!status)
        {
            std::ostringstream message;
            message << "line " << lino << " is invalid, ignored";
            Rcpp::warning(message.str());
            continue;
        }

        if(N.u+1 > prob.m)
            prob.m = N.u+1;
        if(N.v+1 > prob.n)
            prob.n = N.v+1;
        R[idx] = N;
        idx++;
    }
    reader->close();
    prob.nnz = idx;
    prob.R = R;

    return prob;
}
