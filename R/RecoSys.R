RecoSys = setRefClass("RecoSys",
                      fields = list(trainset = "RecoDat",
                                    testset = "RecoDat",
                                    model = "RecoModel"))

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

Reco = function()
{
    return(RecoSys$new())
}
