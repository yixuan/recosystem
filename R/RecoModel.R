RecoModel = setRefClass("RecoModel",
                        fields = list(path = "character",
                                      nuser = "integer",
                                      nitem = "integer",
                                      nfac = "integer"))

RecoModel$methods(
    initialize = function()
    {
        .self$path  = ""
        .self$nuser = 0L
        .self$nitem = 0L
        .self$nfac  = 0L
    }
)

RecoModel$methods(
    show = function()
    {
        cat("Path to model file  =", ' "', .self$path, '"\n', sep = "")
        cat("Number of users     =", .self$nuser, "\n")
        cat("Number of items     =", .self$nitem, "\n")
        cat("Number of factors   =", .self$nfac, "\n")
    }
)
