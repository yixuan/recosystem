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
    train = function(outdir, opts = list())
    {
        ## Check whether training data have been converted
        infile = .self$trainset$binfile
        if(!file.exists(infile))
        {
            stop("Training data not set
[Call $trainset$convert() method to set data]")
        }
        
        ## Check and set output directory
        if(missing(outdir))
        {
            outdir = .self$model$dir;
        }
        ## Check validity of outdir argument
        if(file.exists(outdir))
        {
            if(file.info(outdir)$isdir) {
                .self$model$dir = path.expand(outdir)
            } else {
                stop("outdir: not a directory")
            }
        } else {
            stop("outdir: directory doesn't exist")
        }
        
        ## Path of the model file to be written
        outfile = file.path(.self$model$dir,
                            paste(basename(infile), "model", sep = "."))
        
        ## Parse options
        opts.train = list(dim = 40L, niter = 40L, nthread = 1L,
                          cost.p = 1, cost.q = 1,
                          cost.ub = -1, cost.ib = -1,
                          gamma = 0.001,
                          vaset = "",
                          blocks = c(2L, 2L),
                          rand_shuffle = TRUE,
                          show_tr_rmse = FALSE,
                          show_obj = FALSE,
                          use_avg = FALSE)
        opts.common = intersect(names(opts), names(opts.train))
        opts.train[opts.common] = opts[opts.common]
        opts_cname = c("k", "t", "s", "p", "q", "ub", "ib", "g", "v",
                       "blk", "rand_shuffle", "show_tr_rmse",
                       "show_obj", "use_avg")
        names(opts.train) = opts_cname
        
        status = .Call("train_wrapper", infile, outfile, opts.train,
                       PACKAGE = "Recosystem")
        ## status: TRUE for success, FALSE for failure
        if(!status)
        {
            stop("training model failed")
        }
        cat(sprintf("model file generated at %s\n", outfile));
        
        .self$model$binfile = outfile
        
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
