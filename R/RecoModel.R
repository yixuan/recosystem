RecoModel = setRefClass("RecoModel",
                        fields = list(dir = "character",
                                      binfile = "character"))

RecoModel$methods(
    initialize = function()
    {
        .self$dir = tempdir()
        .self$binfile = ""
    }
)


RecoModel$methods(
    view = function()
    {
        if(!file.exists(.self$binfile))
        {
            cat("Model not trained\n[Call $train() method to train model]\n")
            return(.self)
        }
        
        status = .Call("view_model_wrapper", .self$binfile,
                       PACKAGE = "Recosystem")
        
        if(!status)
        {
            stop("viewing model file failed")
        }
        
        invisible(.self)
    }
)

RecoModel$methods(
    show = function()
    {
        .self$view()
    }
)
