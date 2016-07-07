#include <Rcpp.h>
#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
#include <cstdlib>
#include "mf.h"

using namespace mf;

class ModelExporter
{
protected:
    typedef mf::mf_int   mf_int;
    typedef mf::mf_long  mf_long;
    typedef mf::mf_float mf_float;
    
public:
    // Process one line
    virtual void process_line(const std::string& line) = 0;
    
    virtual ~ModelExporter() {}
};

class ModelExporterFile: public ModelExporter
{
private:
    std::ofstream out_file;
    const mf_int  nfactor;
    
public:
    ModelExporterFile(const std::string& out_path_, const mf_int& nfactor_) :
        out_file(out_path_), nfactor(nfactor_)
    {
        if(!out_file.is_open())
            Rcpp::stop("cannot write to " + out_path_);
    }
    
    void process_line(const std::string& line)
    {
        // Sample line:
        //     p0 T 0.560987 0.605718 0.528195 0.506409 ...
        // p0 means line 0 of P matrix
        // T  means values after are not NaN
        // F  means values in this line are actually NaN
        std::size_t pos = line.find(' ');
        char TF = line[pos + 1];
        if(TF == 'T')
        {
            // Removing trailing space
            std::size_t last = line.find_last_not_of(' ');
            out_file << line.substr(pos + 3, last - pos - 2) << std::endl;
        } else {
            for(mf_int i = 0; i < nfactor - 1; i++)
                out_file << "NaN ";
            
            out_file << "NaN" << std::endl;
        }
    }
};

class ModelExporterMemory: public ModelExporter
{
private:
    double*       pen;
    const mf_int  nfactor;
    
public:
    ModelExporterMemory(double* dest_, const mf_int& nfactor_) :
        pen(dest_), nfactor(nfactor_)
    {}
    
    void process_line(const std::string& line)
    {
        std::size_t pos = line.find(' ');
        char TF = line[pos + 1];
        
        if(TF == 'T')
        {
            std::stringstream dat(line.substr(pos + 3));
            for(mf_int i = 0; i < nfactor; i++)
            {
                dat >> *pen;
                pen++;
            }
        } else {
            for(mf_int i = 0; i < nfactor; i++)
            {
                *pen = std::numeric_limits<mf_float>::quiet_NaN();
                pen++;
            }
        }
    }
};

class ModelExporterNothing: public ModelExporter
{
public:
    void process_line(const std::string& line) {}
};



RcppExport SEXP reco_export(SEXP model_path_, SEXP P_, SEXP Q_)
{
BEGIN_RCPP
    
    std::string model_path = Rcpp::as<std::string>(model_path_);
    std::ifstream model_file(model_path);
    if(!model_file.is_open())
        Rcpp::stop("cannot open model file " + model_path);
    
    std::string line;
    mf_int m, n, k;
    // Read meta information
    //   f 0
    //   m 1000
    //   n 1000
    //   k 20
    //   b 3.007
    std::getline(model_file, line);  // f
    std::getline(model_file, line);  // m
    m = atoi(line.substr(line.find(' ') + 1).c_str());
    std::getline(model_file, line);  // n
    n = atoi(line.substr(line.find(' ') + 1).c_str());
    std::getline(model_file, line);  // k
    k = atoi(line.substr(line.find(' ') + 1).c_str());
    std::getline(model_file, line);  // b
         
    Rcpp::S4 P(P_), Q(Q_);
    std::string P_type = Rcpp::as<std::string>(P.slot("type"));
    std::string Q_type = Rcpp::as<std::string>(Q.slot("type"));
    
    int Pdim = 0, Qdim = 0;
    if(P_type == "memory")  Pdim = m;
    if(Q_type == "memory")  Qdim = n;
    Rcpp::NumericMatrix Pdata(k, Pdim), Qdata(k, Qdim);

    ModelExporter* Pexporter = nullptr;
    ModelExporter* Qexporter = nullptr;
    
    if(P_type == "file")
    {
        Pexporter = new ModelExporterFile(Rcpp::as<std::string>(P.slot("dest")), k);
    } else if(P_type == "memory") {
        Pexporter = new ModelExporterMemory(Pdata.begin(), k);
    } else if(P_type == "nothing") {
        Pexporter = new ModelExporterNothing();
    } else {
        Rcpp::stop("unsupported output format");
    }
    
    for(mf_int i = 0; i < m; i++)
    {
        std::getline(model_file, line);
        Pexporter->process_line(line);
    }

    if(Q_type == "file")
    {
        Qexporter = new ModelExporterFile(Rcpp::as<std::string>(Q.slot("dest")), k);
    } else if(Q_type == "memory") {
        Qexporter = new ModelExporterMemory(Qdata.begin(), k);
    } else if(Q_type == "nothing") {
        Qexporter = new ModelExporterNothing();
    } else {
        Rcpp::stop("unsupported output format");
    }
    
    for(mf_int i = 0; i < n; i++)
    {
        std::getline(model_file, line);
        Qexporter->process_line(line);
    }
    
    return Rcpp::List::create(
        Rcpp::Named("Pdata") = Pdata,
        Rcpp::Named("Qdata") = Qdata
    );
    
END_RCPP
}
