RecoSys = setRefClass("RecoSys",
                      fields = list(model = "RecoModel"))

RecoSys$methods(
    train = function(train_path, model_path, opts = list())
    {
        train_path = as.character(train_path)
        model_path = as.character(model_path)
        
        ## Check whether training set file exists
        if(!file.exists(train_path))
        {
            stop(sprintf("%s does not exist", train_path))
        }
        
        ## Use the default file name if model path is not set
        if(missing(model_path))
        {
            model_path = sprintf("%s.model", train_path)
        }
        
        ## Parse options
        opts_train = list(dim = 8L, niter = 20L, nthread = 1L,
                          cost = 0.1, lrate = 0.1,
                          nmf = FALSE, verbose = TRUE)
        opts_common = intersect(names(opts), names(opts_train))
        opts_train[opts_common] = opts[opts_common]
        
        ## Additional parameters to be passed to libmf but not set by users here
        opts_train$nfold = 1L;
        opts_train$va_path = "";
        
        model_param = .Call("reco_train", train_path, model_path, opts_train,
                            package = "recosystem")
        
        .self$model$path = model_path
        .self$model$nuser = model_param$nuser
        .self$model$nitem = model_param$nitem
        .self$model$nfac = model_param$nfac
        
        invisible(.self)
    }
)

RecoSys$methods(
    output = function(out_P = file.path(tempdir(), "mat_P.txt"),
                      out_Q = file.path(tempdir(), "mat_Q.txt"))
    {
        ## Check whether model have been trained
        modelfile = .self$model$binfile
        if(!file.exists(modelfile))
        {
            stop("Model not trained
[Call $train() method to train model]")
        }
        
        out_P = path.expand(as.character(out_P))
        out_Q = path.expand(as.character(out_Q))
        
        .Call("output", modelfile, out_P, out_Q, PACKAGE = "recosystem")
        
        if(length(out_P))
            cat(sprintf("P matrix generated at %s\n", out_P))
        
        if(length(out_Q))
            cat(sprintf("Q matrix generated at %s\n", out_Q))
        
        invisible(.self)
    }
)

RecoSys$methods(
    predict = function(outfile = file.path(tempdir(), "predict.txt"), verbose = TRUE)
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
        
        if(!verbose)  sink(tmpf <- tempfile())
        status = tryCatch(
            .Call("predict_wrapper", testfile, modelfile, outfile,
                       PACKAGE = "recosystem"),
            error = function(e) {
                if(sink.number())  sink()
                stop(e$message)
            })
        ## status: TRUE for success, FALSE for failure
        if(!status)
        {
            if(sink.number())  sink()
            stop("model predicting failed")
        }
        cat(sprintf("output file generated at %s\n", outfile))
        if(sink.number())  sink()
        if(!verbose)  unlink(tmpf)
        
        invisible(.self)
    }
)

RecoSys$methods(
    show = function(outfile)
    {
        cat("[=== Training set ===]\n\n")
        .self$trainset$show()
        cat("\n")
        cat("[=== Testing set ===]\n\n")
        .self$testset$show()
        cat("\n")
        cat("[=== Model ===]\n\n")
        .self$model$show()
        
        invisible(.self)
    }
)

#' Construct a Recommender System Object
#' 
#' This function simply returns an object of class "\code{RecoSys}"
#' that can be used to construct recommender model and conduct prediction.
#' 
#' @return \code{Reco()} returns an object of class "\code{RecoSys}"
#' equipped with methods
#' \code{$\link{convert_train}()}, \code{$\link{convert_train}()},
#' \code{$\link{train}()}, \code{$\link{output}()} and \code{$\link{predict}()},
#' which describe the typical process of reading data, building model and
#' predicting results. See their help documents for details.
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{\link{convert}}, \code{\link{train}}, \code{\link{output}},
#' \code{\link{predict}}
#' @references LIBMF: A Matrix-factorization Library for Recommender Systems.
#' \url{http://www.csie.ntu.edu.tw/~cjlin/libmf/}
#' 
#' Y. Zhuang, W.-S. Chin, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' Technical report 2014.
#' @export
#' @keywords models
Reco = function()
{
    return(RecoSys$new())
}


#' Read Data File and Convert to Binary Format
#' 
#' @description These methods are member functions of class "\code{RecoSys}"
#' that convert training and testing data files into binary format.
#' The conversion is a preprocessing step prior to the model training part,
#' since data with this binary format could be accessed more efficiently.
#' 
#' The common usage of these methods is
#' \preformatted{r = Reco()
#' r$convert_train(rawfile, outdir, verbose = TRUE)
#' r$convert_test(rawfile, outdir, verbose = TRUE)}
#' 
#' @name convert
#' @aliases convert_train convert_test
#' @param r Object returned by \code{\link{Reco}}()
#' @param rawfile Path of data file, see section 'Data format' for details
#' @param outdir Directory in which the output binary file will be
#'               generated. If missing, \code{tempdir()} will be used.
#' @param verbose Whether to show detailed information. Default is \code{TRUE}.
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
#' \bold{NOTE}: For testing data, the file also needs to contain three
#' numbers each line. If the rating values are unknown, you can put any
#' number as placeholders.
#' \cr
#' Example data files are contained in the \code{recosystem/dat} directory.
#' @examples trainset = system.file("dat", "smalltrain.txt", package = "recosystem")
#' testset = system.file("dat", "smalltest.txt", package = "recosystem")
#' r = Reco()
#' r$convert_train(trainset)
#' r$convert_test(testset)
#' print(r)
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{\link{train}}, \code{\link{output}}, \code{\link{predict}}
#' @references LIBMF: A Matrix-factorization Library for Recommender Systems.
#' \url{http://www.csie.ntu.edu.tw/~cjlin/libmf/}
#' 
#' Y. Zhuang, W.-S. Chin, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' Technical report 2014.
NULL


#' Train a Recommender Model
#' 
#' @description This method is a member function of class "\code{RecoSys}"
#' that trains a recommender model. It will create a model file
#' in the specified directory, containing necessary information for
#' prediction.
#' Training data must have already been converted into binary form
#' through \code{$\link{convert_train}()} before calling this method.
#' 
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$train(outdir, opts, verbose = TRUE)}
#' 
#' @name train
#' @param r Object returned by \code{\link{Reco}}()
#' @param outdir Directory in which the model file will be
#'               generated. If missing, \code{tempdir()} will be used.
#' @param opts Various options and tuning parameters in the model training
#'             procedure. See section \strong{Options and Parameters}
#'             for details.
#' @param verbose Whether to show detailed information. Default is \code{TRUE}.
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
#'                      parallel SGD. Default is \code{c(2*nthread,
#'                      2*nthread)}}
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
#' @examples set.seed(123) # this is a randomized algorithm
#' trainset = system.file("dat", "smalltrain.txt", package = "recosystem")
#' testset = system.file("dat", "smalltest.txt", package = "recosystem")
#' r = Reco()
#' r$convert_train(trainset)
#' r$convert_test(testset)
#' r$train(opts = list(dim = 80, cost.p = 0.01, cost.q = 0.01))
#' print(r)
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{\link{convert}}, \code{\link{output}}, \code{\link{predict}}
#' @references LIBMF: A Matrix-factorization Library for Recommender Systems.
#' \url{http://www.csie.ntu.edu.tw/~cjlin/libmf/}
#' 
#' Y. Zhuang, W.-S. Chin, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' Technical report 2014.
NULL


#' Output Factorization Matrices
#' 
#' @description This method is a member function of class "\code{RecoSys}"
#' that could write the user score matrix \eqn{P} and item score matrix \eqn{Q}
#' to text files.
#' 
#' Prior to calling this method, model needs to be trained by calling
#' \code{$\link{train}()}.
#' 
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$output(out_P = file.path(tempdir(), "mat_P.txt"),
#'          out_Q = file.path(tempdir(), "mat_Q.txt"))}
#' 
#' @name output
#' @param r Object returned by \code{\link{Reco}()}
#' @param out_P Filename of the output user score matrix. Note that this contains
#'              the \strong{transpose} of the \eqn{P} matrix, hence each row in
#'              the file stands for a user, and each column stands for a latent
#'              factor. Values are space seperated.
#' @param out_Q Filename of the output item score matrix. Note that this contains
#'              the \strong{transpose} of the \eqn{Q} matrix, hence each row in
#'              the file stands for an item, and each column stands for a latent
#'              factor. Values are space seperated.
#' 
#' @examples set.seed(123) # this is a randomized algorithm
#' trainset = system.file("dat", "smalltrain.txt", package = "recosystem")
#' testset = system.file("dat", "smalltest.txt", package = "recosystem")
#' r = Reco()
#' r$convert_train(trainset)
#' r$convert_test(testset)
#' r$train(opts = list(dim = 10))
#' P = tempfile()
#' Q = tempfile()
#' r$output(P, Q)
#' 
#' ## Inspect these two matrices
#' head(read.table(P, header = FALSE, sep = " "))
#' head(read.table(Q, header = FALSE, sep = " "))
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{\link{convert}}, \code{\link{train}}, \code{\link{predict}}
#' @references LIBMF: A Matrix-factorization Library for Recommender Systems.
#' \url{http://www.csie.ntu.edu.tw/~cjlin/libmf/}
#' 
#' Y. Zhuang, W.-S. Chin, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' Technical report 2014.
NULL


#' Recommender Model Predictions
#' 
#' @description This method is a member function of class "\code{RecoSys}"
#' that predicts unknown entries in the rating matrix.
#' Prior to calling this method, model needs to be trained by calling
#' \code{$\link{train}()}, and testing data also must be set through
#' \code{$\link{convert_test}()}.
#' Prediction results will be written into the specified file, one value
#' per line, corresponding to the testing data.
#' 
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$predict(outfile = file.path(tempdir(), "predict.txt"), verbose = TRUE)}
#' 
#' @name predict
#' @param r Object returned by \code{\link{Reco}()}
#' @param outfile Name of the output file for prediction
#' @param verbose Whether to show detailed information. Default is \code{TRUE}.
#' @examples set.seed(123) # this is a randomized algorithm
#' trainset = system.file("dat", "smalltrain.txt", package = "recosystem")
#' testset = system.file("dat", "smalltest.txt", package = "recosystem")
#' r = Reco()
#' r$convert_train(trainset)
#' r$convert_test(testset)
#' r$train(opts = list(dim = 100, niter = 100,
#'                     cost.p = 0.001, cost.q = 0.001))
#' outfile = tempfile()
#' r$predict(outfile)
#' 
#' ## Compare the first few true values of testing data
#' ## with predicted ones
#' print(read.table(testset, header = FALSE, sep = " ", nrows = 10)$V3)
#' print(scan(outfile, n = 10))
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{\link{convert}}, \code{\link{train}}, \code{\link{output}}
#' @references LIBMF: A Matrix-factorization Library for Recommender Systems.
#' \url{http://www.csie.ntu.edu.tw/~cjlin/libmf/}
#' 
#' Y. Zhuang, W.-S. Chin, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' Technical report 2014.
NULL