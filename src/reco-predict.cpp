#include <string>
#include <fstream>
#include <iostream>
#include <sstream>
#include <cmath>
#include <stdexcept>
#include <algorithm>

#include <Rcpp.h>

#include "mf.h"
#include "reco-read-data.h"

using namespace mf;

// Readers
class TestDataFileReader: public DataFileReader
{
public:
    TestDataFileReader(const std::string& file_path, bool index1 = false) :
        DataFileReader(file_path, index1)
    {}

    bool next(mf_int& u, mf_int& v, mf_float& r)
    {
        std::getline(in_file, line);
        std::stringstream ss(line);

        ss >> u >> v;
        u -= ind_offset;
        v -= ind_offset;

        return !ss.fail();
    }
};

class TestDataMemoryReader: public DataReader
{
protected:
    const mf_long len;
    const int*    pen_userid;
    const int*    pen_itemid;
    const mf_int  ind_offset;

public:
    TestDataMemoryReader(Rcpp::IntegerVector user_ind,
                         Rcpp::IntegerVector item_ind,
                         bool index1 = false) :
        len(user_ind.length()),
        pen_userid(user_ind.begin()),
        pen_itemid(item_ind.begin()),
        ind_offset(index1)
    {}

    mf_long count() { return len; }

    void open() {}

    bool next(mf_int& u, mf_int& v, mf_float& r)
    {
        u = *pen_userid - ind_offset;
        v = *pen_itemid - ind_offset;

        bool failure = Rcpp::IntegerVector::is_na(*pen_userid) ||
                       Rcpp::IntegerVector::is_na(*pen_itemid);

        pen_userid++;
        pen_itemid++;

        return !failure;
    }

    void close() {}
};

// Exporters
class PredictionExporter
{
protected:
    typedef mf::mf_int   mf_int;
    typedef mf::mf_long  mf_long;
    typedef mf::mf_float mf_float;

public:
    // Process one line
    virtual void process_value(const mf_float& val) = 0;

    virtual ~PredictionExporter() {}
};

class PredictionExporterFile: public PredictionExporter
{
private:
    std::ofstream out_file;

public:
    PredictionExporterFile(const std::string& out_path_) :
        out_file(out_path_)
    {
        if(!out_file.is_open())
            Rcpp::stop("cannot write to " + out_path_);
    }

    void process_value(const mf_float& val)
    {
        if(std::isnan(val))
            out_file << "NA" << std::endl;
        else
            out_file << val << std::endl;
    }
};

class PredictionExporterMemory: public PredictionExporter
{
private:
    double* pen;

public:
    PredictionExporterMemory(double* dest_) :
        pen(dest_)
    {}

    void process_value(const mf_float& val)
    {
        if(std::isnan(val))
            *pen = NA_REAL;
        else
            *pen = val;

        pen++;
    }
};

class PredictionExporterNothing: public PredictionExporter
{
public:
    void process_value(const mf_float& val) {}
};



RcppExport SEXP reco_predict(SEXP test_data_, SEXP model_path_, SEXP output_, SEXP model_inmemory_)
{
BEGIN_RCPP

    // Reader of testing data
    DataReader* reader = nullptr;
    Rcpp::S4 test_data(test_data_);
    std::string type = Rcpp::as<std::string>(test_data.slot("type"));
    if(type == "file")
    {
        std::string path = Rcpp::as<std::string>(test_data.slot("source"));
        bool index1 = Rcpp::as<bool>(test_data.slot("index1"));
        reader = new TestDataFileReader(path, index1);
    } else if(type == "memory") {
        Rcpp::List lst = test_data.slot("source");
        bool index1 = Rcpp::as<bool>(test_data.slot("index1"));
        reader = new TestDataMemoryReader(lst[0], lst[1], index1);
    } else {
        Rcpp::stop("unsupported data source");
    }
    mf_long len = reader->count();

    // Exporter
    PredictionExporter* exporter = nullptr;
    Rcpp::S4 output(output_);
    type = Rcpp::as<std::string>(output.slot("type"));
    Rcpp::NumericVector res((type == "memory") ? len : 0);
    if(type == "file")
    {
        exporter = new PredictionExporterFile(Rcpp::as<std::string>(output.slot("dest")));
    } else if(type == "memory") {
        exporter = new PredictionExporterMemory(res.begin());
    } else if(type == "nothing") {
        exporter = new PredictionExporterNothing();
    } else {
        Rcpp::stop("unsupported output format");
    }

    // Read model file or in-memory contents
    mf_model* model;
    mf_model model_;
    Rcpp::List model_inmemory = model_inmemory_;
    if(model_inmemory.size())
    {
        model_ = {
            Rcpp::as<mf_int>(model_inmemory["fun"]),
            Rcpp::as<mf_int>(model_inmemory["m"]),
            Rcpp::as<mf_int>(model_inmemory["n"]),
            Rcpp::as<mf_int>(model_inmemory["k"]),
            *((float*) INTEGER(model_inmemory["b"])),
            (float*) INTEGER(model_inmemory["P"]),
            (float*) INTEGER(model_inmemory["Q"])
        };
        model = &model_;
    } else {
        std::string model_path = Rcpp::as<std::string>(model_path_);
        model = mf_load_model(model_path.c_str());
        if(model == nullptr)
            Rcpp::stop("cannot load model from " + model_path);
    }

    // Prediction
    mf_int u, v;
    mf_float dummy;
    reader->open();
    for(mf_long lino = 1; lino <= len; lino++)
    {
        bool status = reader->next(u, v, dummy);
        // If status is false, then an error occurs in this line
        if(!status)
        {
            std::ostringstream message;
            message << "line " << lino << " of testing data is invalid, NA returned";
            Rcpp::warning(message.str());
            exporter->process_value(std::numeric_limits<mf_float>::quiet_NaN());
            continue;
        }

        mf_float val = mf_predict(model, u, v);
        exporter->process_value(val);
    }
    reader->close();

    if(!model_inmemory.size())
        mf_destroy_model(&model);
    delete exporter;
    delete reader;

    if(res.length() == 0)  return R_NilValue;
    return res;

END_RCPP
}
