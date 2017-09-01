#ifndef REGISTER_ROUTINES_H
#define REGISTER_ROUTINES_H

#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>


SEXP reco_tune(SEXP train_data_, SEXP opts_tune_, SEXP opts_other_);
SEXP reco_train(SEXP train_data_, SEXP model_path_, SEXP opts_);
SEXP reco_output(SEXP model_path_, SEXP P_, SEXP Q_);
SEXP reco_predict(SEXP test_data_, SEXP model_path_, SEXP output_);


#endif
