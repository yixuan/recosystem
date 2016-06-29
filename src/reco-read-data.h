#ifndef RECO_READ_DATA_H
#define RECO_READ_DATA_H

#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cmath>
#include <stdexcept>
#include <algorithm>

#include <Rcpp.h>
#include "mf.h"

class DataReader
{
protected:
    typedef mf::mf_int   mf_int;
    typedef mf::mf_long  mf_long;
    typedef mf::mf_float mf_float;
    
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
    DataFileReader(const std::string& file_path, bool index1 = false) :
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
        u -= ind_offset;
        v -= ind_offset;
        
        return !ss.fail();
    }
    
    void close()
    {
        in_file.close();
    }
};


mf::mf_problem read_data(DataReader* reader);



#endif // RECO_READ_DATA_H
