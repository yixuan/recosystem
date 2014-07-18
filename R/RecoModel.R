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
        ## TODO
        
        invisible(.self)
    }
)

