RecoModel = setRefClass("RecoModel",
                        fields = list(path = "character",
                                      nuser = "integer",
                                      nitem = "integer",
                                      nfac = "integer",
                                      tr_rmse = "numeric",
                                      va_rmse = "numeric"))

RecoModel$methods(
    initialize = function()
    {
        .self$path = ""
        .self$nuser = 0L
        .self$nitem = 0L
        .self$nfac = 0L
        .self$tr_rmse = NA_real_
        .self$va_rmse = NA_real_
    }
)

RecoModel$methods(
    show = function()
    {
        cat("Path to model file  =", ' "', .self$path, '"\n', sep = "")
        cat("Number of users     =", .self$nuser, "\n")
        cat("Number of items     =", .self$nitem, "\n")
        cat("Number of factors   =", .self$nfac, "\n")
        cat("Training set RMSE   =", .self$tr_rmse, "\n")
        cat("Validation set RMSE =", .self$va_rmse, "\n")
    }
)
