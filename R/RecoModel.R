RecoModel = setRefClass("RecoModel",
                        fields = list(path  = "character",
                                      nuser = "integer",
                                      nitem = "integer",
                                      nfac  = "integer",
                                      matrices = "list"))

RecoModel$methods(
    initialize = function()
    {
        .self$path  = ""
        .self$nuser = 0L
        .self$nitem = 0L
        .self$nfac  = 0L
        .self$matrices = list()
    }
)

RecoModel$methods(
    show = function()
    {
        catl = function(key, val, ...)
            cat(sprintf("%-20s = %s\n", key, val), ..., sep = "")
        
        catl("Path to model file", .self$path)
        catl("Number of users",    .self$nuser)
        catl("Number of items",    .self$nitem)
        catl("Number of factors",  .self$nfac)
        if(length(.self$matrices))
            cat("(Contains in-memory model matrices)")
    }
)
