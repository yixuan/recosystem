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

class DataReader
{
public:
    // Whether this is a valid data source
    // File name is empty? Data frame contains no data? etc.
    virtual bool is_valid() = 0;
    
    // Return an upper limit of prob.nnz
    // When there exist invalid data in the file or data frame, this will be
    // greater than prob.nnz
    virtual mf_long count() = 0;
    
    // Ready to read
    virtual void open() = 0;
    
    // Read the data into u, v, r and return the status
    // true for success and false for failure
    // u and v start from 0
    virtual bool next(mf_int& u, mf_int& v, mf_float& r) = 0;
    
    // Finish reading
    virtual void close() = 0;
};


class DataFileReader: public DataReader
{
private:
    std::string   path;
    int           ind_offset;
    std::ifstream in_file;
    std::string   line;
public:
    DataFileReader(const std::string& file_path, bool index1) :
        path(file_path), ind_offset(index1)
    {}
    
    bool is_valid()
    {
        std::ifstream f(path);
        return f.is_open();
    }
    
    mf_long count()
    {
        std::ifstream f(path);
        if(!f.is_open())
            throw std::runtime_error("cannot open " + path);
        
        std::string line;
        mf_long nlines = 0;
        while(std::getline(f, line))
            nlines++;
        
        f.close();
        return nlines;
    }
    
    void open()
    {
        in_file.open(path);
        if(!in_file.is_open())
            throw std::runtime_error("cannot open " + path);
    }
    
    bool next(mf_int& u, mf_int& v, mf_float& r)
    {
        std::getline(in_file, line);
        std::stringstream ss(line);
        
        ss >> u >> v >> r;
        return !ss.fail();
    }
    
    void close()
    {
        in_file.close();
    }
};



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
