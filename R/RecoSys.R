RecoSys = setRefClass("RecoSys",
                      fields = list(trainset = "RecoDat",
                                    testset = "RecoDat",
                                    model = "RecoModel"))

RecoSys$methods(
    initialize = function()
    {
        .self$trainset$type = "trainset"
        .self$testset$type = "testset"
    }
)

RecoSys$methods(
    train = function()
    {
        ## TODO
        
        invisible(.self)
    }
)

RecoSys$methods(
    predict = function(outfile)
    {
        ## TODO
        
        invisible(.self)
    }
)

RecoSys$methods(
    show = function(outfile)
    {
        cat(">>> Training set >>>\n\n")
        .self$trainset$show()
        cat("\n")
        cat(">>> Testing set >>>\n\n")
        .self$testset$show()
        cat("\n")
        cat(">>> Model >>>\n\n")
        .self$model$show()
        
        invisible(.self)
    }
)

Reco = function()
{
    return(RecoSys$new())
}
