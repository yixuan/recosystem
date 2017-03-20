#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include "register_routines.h"

static R_CallMethodDef callMethods[] = {
    {"reco_tune",    (DL_FUNC) &reco_tune,    3},
    {"reco_train",   (DL_FUNC) &reco_train,   3},
    {"reco_output",  (DL_FUNC) &reco_output,  3},
    {"reco_predict", (DL_FUNC) &reco_predict, 3},
    {NULL, NULL, 0}
};

void R_init_recosystem(DllInfo *info)
{
    R_registerRoutines(info, NULL, callMethods, NULL, NULL);
    R_useDynamicSymbols(info, FALSE);
}
