RecoSys = setRefClass("RecoSys",
                      fields = list(trainset = "RecoDat",
                                    testset = "RecoDat",
                                    model = "RecoModel"))

RecoSys$methods(
    initialize = function()
    {
        .self$trainset$type = "train"
        .self$testset$type = "test"
    }
)

RecoSys$methods(
    convert_train = function(rawfile, outdir)
    {
        .self$trainset$convert(rawfile, outdir)
        invisible(.self)
    },
    convert_test = function(rawfile, outdir)
    {
        .self$testset$convert(rawfile, outdir)
        invisible(.self)
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
[Call $convert_train() method to set data]")
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
                          blocks = c(0L, 0L),
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
        ## Check whether model have been trained
        modelfile = .self$model$binfile
        if(!file.exists(modelfile))
        {
            stop("Model not trained
[Call $train() method to train model]")
        }
        
        ## Check whether testing data have been converted
        testfile = .self$testset$binfile
        if(!file.exists(testfile))
        {
            stop("Testing data not set
[Call $convert_test() method to set data]")
        }
        
        outfile = path.expand(outfile)
        
        status = .Call("predict_wrapper", testfile, modelfile, outfile,
                       PACKAGE = "Recosystem")
        ## status: TRUE for success, FALSE for failure
        if(!status)
        {
            stop("model predicting failed")
        }
        cat(sprintf("output file generated at %s\n", outfile));
        
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

#' Construct a recommender system object
#' 
#' This function simply returns an object of class "\code{RecoSys}"
#' that can be used to construct recommender model and conduct prediction.
#' 
#' @return \code{Reco()} returns an object of class "\code{RecoSys}" with
#' methods \code{convert_train()}, \code{convert_test()},
#' \code{train()} and \code{predict()}. See topics \code{\link{convert}},
#' \code{\link{train}} and \code{\link{predict}} for details.
Reco = function()
{
    return(RecoSys$new())
}


#' Read data file and convert to binary format
#' 
#' These methods are member functions of class "\code{RecoSys}"
#' that convert training and testing data files into binary format.
#' The conversion is a preprocessing step prior to the model training part,
#' since data with this binary format could be accessed more efficiently.
#' 
#' @name convert
#' @aliases convert_train convert_test
#' @usage reco_obj$convert_train(rawfile, outdir)
#' reco_obj$convert_test(rawfile, outdir)
#' @param reco_obj Object returned by \code{\link{Reco}}()
#' @param rawfile Path of data file, see section 'Data format' for details
#' @param outdir Directory in which the output binary file will be
#'               generated. If missing, \code{tempdir()} will be used.
#' @section Data format:
#' The data file required by these methods takes the format of sparse matrix
#' in triplet form, i.e., each line in the file contains three numbers
#' \preformatted{row col value}
#' representing a number in the rating matrix
#' with its location. In real applications, it typically looks like
#' \preformatted{user_id item_id rating}
#' 
#' \bold{NOTE}: \code{row} and \code{col} start from 0. So if the first user
#' rates 3 on the first item, the line will be
#' \preformatted{0 0 3}
#' 
#' Example data files are contained in the \code{Recosystem/dat} directory.
#' @examples trainset = system.file("dat", "smalltrain.txt", package = "Recosystem")
#' testset = system.file("dat", "smalltest.txt", package = "Recosystem")
#' r = Reco()
#' r$convert_train(trainset)
#' r$convert_test(testset)
#' print(r)
NULL


#' Train a recommender model
#' 
#' This method is a member function of class "\code{RecoSys}"
#' that trains a recommender model. It will create a model file
#' in the specified directory, containing necessary information for
#' prediction.
#' Training data must have already been converted into binary form
#' through \code{$\link{convert_train}()} before calling this method.
#' 
#' @name train
#' @usage reco_obj$train(outdir, opts)
#' @param reco_obj Object returned by \code{\link{Reco}}()
#' @param outdir Directory in which the model file will be
#'               generated. If missing, \code{tempdir()} will be used.
#' @param opts Various options and tuning parameters in the model training
#'             procedure. See section "Options and Parameters" for details.
#' @section Options and Parameters:
#' The \code{opts} argument is a list that can supply any of the
#' following parameters:
#'
#' \describe{
#' \item{\code{dim}}{Integer, the width of the factorized matrix, i.e.,
#'                   the number of latent factors. Default is 40.}
#' \item{\code{niter}}{Integer, the number of iterations. Default is 40.}
#' \item{\code{nthread}}{Integer, the number of threads for parallel
#'                       computing. Default is 1.}
#' \item{\code{cost.p}}{Nonnegative real number, the regularization cost
#'                      for P. Default is 1.}
#' \item{\code{cost.q}}{Nonnegative real number, the regularization cost
#'                      for Q. Default is 1.}
#' \item{\code{cost.ub}}{Real number, the regularization cost for user bias.
#'                       Set <0 to disable. Default is -1.}
#' \item{\code{cost.ib}}{Real number, The regularization cost for item bias.
#'                       Set <0 to disable. Default is -1.}
#' \item{\code{gamma}}{Positive real number, the learning rate for parallel
#'                     SGD. Default is 0.001.}
#' \item{\code{blocks}}{Integer vector of length 2, the number of blocks for
#'                      parallel SGD. Default is \code{c(2 * nthread,
#'                      2 * nthread)}}
#' \item{\code{rand_shuffle}}{Logical, whether to enable random shuffle.
#'                            This should be enabled when data are
#'                            imbalanced. Default is \code{TRUE}.}
#' \item{\code{show_tr_rmse}}{Logical, whether to show RMSE on training
#'                            data. Default is \code{FALSE}.}
#' \item{\code{show_obj}}{Logical, whether to show the objective value.
#'                        This option may slow down the training procedure.
#'                        Default is \code{FALSE}.}
#' \item{\code{use_avg}}{Logical, whether to use training data average.
#'                       Default is \code{FALSE}.}
#' }
#' @examples trainset = system.file("dat", "smalltrain.txt", package = "Recosystem")
#' testset = system.file("dat", "smalltest.txt", package = "Recosystem")
#' r = Reco()
#' r$convert_train(trainset)
#' r$convert_test(testset)
#' r$train(opts = list(dim = 80, cost.p = 0.01, cost.q = 0.01))
#' print(r)
NULL
