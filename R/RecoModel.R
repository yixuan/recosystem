RecoModel = setRefClass("RecoModel",
                        fields = list(dir = "character",
                                      binfile = "character"))

RecoModel$methods(
    initialize = function()
    {
        .self$dir = tempdir()
    }
)


RecoModel$methods(
    view = function()
    {
        status = .Call("view_model_wrapper", .self$binfile,
                       PACKAGE = "Recosystem")
        
        if(!status)
        {
            stop("viewing model file failed")
        }
        
        invisible(.self)
    }
)

