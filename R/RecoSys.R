RecoSys = setRefClass("RecoSys",
                      fields = list(model = "RecoModel"))

RecoSys$methods(
    tune = function(train_path, opts = list(dim = c(10L, 15L, 20L),
                                            cost = c(0.01, 0.1),
                                            lrate = c(0.01, 0.1)))
    {
        ## Check whether training set file exists
        train_path = path.expand(train_path)
        if(!file.exists(train_path))
        {
            stop(sprintf("%s does not exist", train_path))
        }
        
        ## Tuning parameters: dim, cost, lrate
        ## First set up default values
        opts_tune = list(dim   = c(10L, 15L, 20L),
                         cost  = c(0.01, 0.1),
                         lrate = c(0.01, 0.1))
        ## Update opts_tune from opts
        if("dim" %in% names(opts))
        {
            opts_tune$dim = as.integer(opts$dim)
        }
        if("cost" %in% names(opts))
        {
            opts_tune$cost = as.numeric(opts$cost)
        }
        if("lrate" %in% names(opts))
        {
            opts_tune$lrate = as.numeric(opts$lrate)
        }
        ## Expand combinations
        opts_tune = expand.grid(opts_tune)
        
        ## Other options
        opts_train = list(nfold = 5L, niter = 20L, nthread = 1L,
                          nmf = FALSE, verbose = FALSE)
        opts_common = intersect(names(opts), names(opts_train))
        opts_train[opts_common] = opts[opts_common]
        
        rmse = .Call("reco_tune", train_path, opts_tune, opts_train,
                            package = "recosystem")
        
        opts_tune$rmse = rmse
        opts_tune = na.omit(opts_tune)
        if(!nrow(opts_tune))
            stop("results are all NA/NaN")

        tune_min = opts_tune[which.min(rmse), ]
        opts_min = list(dim = tune_min$dim, cost = tune_min$cost, lrate = tune_min$lrate)
        
        return(list(min = c(opts_min, opts_train), res = opts_tune))
    }
)

RecoSys$methods(
    train = function(train_path, out = file.path(tempdir(), "model.txt"), opts = list())
    {
        ## Check whether training set file exists
        train_path = path.expand(train_path)
        if(!file.exists(train_path))
        {
            stop(sprintf("%s does not exist", train_path))
        }
        
        model_path = path.expand(out)
        
        ## Parse options
        opts_train = list(dim = 10L, cost = 0.1, lrate = 0.1,
                          niter = 20L, nthread = 1L,
                          nmf = FALSE, verbose = TRUE)
        opts_common = intersect(names(opts), names(opts_train))
        opts_train[opts_common] = opts[opts_common]
        
        ## Additional parameters to be passed to libmf but not set by users here
        opts_train$nfold = 1L;
        opts_train$va_path = ""
        
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
        ## Check whether model has been trained
        model_path = .self$model$path
        if(!file.exists(model_path))
        {
            stop("model not trained yet
[Call $train() method to train model]")
        }
        
        ## If both are NULL, return P and Q matrices in memory
        if(is.null(out_P) & is.null(out_Q))
        {
            res = .Call("reco_output_memory", model_path)
            return(list(P = matrix(res$Pdata, .self$model$nuser, byrow = TRUE),
                        Q = matrix(res$Qdata, .self$model$nitem, byrow = TRUE)))
        }
        
        out_P = path.expand(out_P)
        out_Q = path.expand(out_Q)
        
        .Call("reco_output", model_path, out_P, out_Q, PACKAGE = "recosystem")
        
        if(nchar(out_P))
            cat(sprintf("P matrix generated at %s\n", out_P))
        
        if(nchar(out_Q))
            cat(sprintf("Q matrix generated at %s\n", out_Q))
        
        invisible(.self)
    }
)

RecoSys$methods(
    predict = function(test_path, out = file.path(tempdir(), "predict.txt"))
    {
        ## Check whether testing set file exists
        test_path = path.expand(test_path)
        if(!file.exists(test_path))
        {
            stop(sprintf("%s does not exist", test_path))
        }
        
        ## Check whether model has been trained
        model_path = .self$model$path
        if(!file.exists(model_path))
        {
            stop("model not trained yet
[Call $train() method to train model]")
        }
        
        ## If out is NULL, return prediction in memory
        if(is.null(out))
        {
            res = .Call("reco_predict_memory", test_path, model_path)
            return(res)
        }
        
        out_path = path.expand(out)
        
        .Call("reco_predict", test_path, model_path, out_path, PACKAGE = "recosystem")
        
        cat(sprintf("prediction output generated at %s\n", out_path))
        
        invisible(.self)
    }
)

RecoSys$methods(
    show = function(outfile)
    {
        cat("[=== Fitted Model ===]\n\n")
        .self$model$show()
        
        invisible(.self)
    }
)

#' Constructing a Recommender System Object
#' 
#' This function simply returns an object of class "\code{RecoSys}"
#' that can be used to construct recommender model and conduct prediction.
#' 
#' @return \code{Reco()} returns an object of class "\code{RecoSys}"
#' equipped with methods
#' \code{$\link{tune}()}, \code{$\link{train}()}, \code{$\link{output}()}
#' and \code{$\link{predict}()}, which describe the typical process of
#' building and tuning model, outputing coefficients, and
#' predicting results. See their help documents for details.
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{$\link{tune}()}, \code{$\link{train}()}, \code{$\link{output}()},
#' \code{$\link{predict}()}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#' 
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A learning-rate schedule for stochastic gradient methods to matrix factorization.
#' PAKDD, 2015. 
#' 
#' @export
#' @keywords models
Reco = function()
{
    return(RecoSys$new())
}


#' Tuning Model Parameters
#' 
#' @description This method is a member function of class "\code{RecoSys}"
#' that uses cross validation to tune the model parameters.
#' 
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$tune(train_path, opts = list(dim = c(10, 15, 20),
#'                                cost = c(0.01, 0.1),
#'                                lrate = c(0.01, 0.1))
#' )}
#' 
#' @name tune
#' @param r Object returned by \code{\link{Reco}}()
#' @param train_path Path to the traning data file, same as the one in
#'                   \code{$\link{train}()}. See the help page there for the
#'                   details about the data format.
#' @param opts A number of candidate tuning parameter values and extra options in the
#'             model tuning procedure. See section \strong{Parameters and Options}
#'             for details.
#' 
#' @return A list with two components:
#' 
#' \describe{
#'   \item{\code{min}}{Parameter values with minimum cross validation RMSE. This
#'                     is a list that can be passed to the \code{opts} argument
#'                     in \code{$\link{train}()}.}
#'   \item{\code{res}}{A data frame giving the supplied candidate
#'                     values of tuning parameters, and one column showing the
#'                     RMSE associated with each combination.}
#' }
#'             
#' @section Parameters and Options:
#' The \code{opts} argument should be a list that provides the candidate values
#' of tuning parameters and some other options. For tuning parameter (\code{dim},
#' \code{cost} or \code{lrate}), users can provide a numeric vector, so that
#' the model will be evaluated on each combination of the candidate values.
#' For other non-tuning options, users should give a single value. If a parameter
#' or option is not set by the user, the program will use a default one.
#' 
#' See below for the list of available parameters and options:
#'
#' \describe{
#' \item{\code{dim}}{Tuning parameter, the number of latent factors.
#'                   Can be specified as an integer vector, with default value
#'                   \code{c(10, 15, 20)}.}
#' \item{\code{cost}}{Tuning parameter, the regularization cost for latent factors.
#'                    Can be specified as a numeric vector, with default value
#'                    \code{c(0.01, 0.1)}.}
#' \item{\code{lrate}}{Tuning parameter, the learning rate, which can be thought
#'                     of as the step size in gradient descent.
#'                     Can be specified as a numeric vector, with default value
#'                     \code{c(0.01, 0.1)}.}
#' \item{\code{nfold}}{Integer, the number of folds in cross validation. Default is 5.}
#' \item{\code{niter}}{Integer, the number of iterations. Default is 20.}
#' \item{\code{nthread}}{Integer, the number of threads for parallel
#'                       computing. Default is 1.}
#' \item{\code{nmf}}{Logical, whether to perform non-negative matrix factorization.
#'                   Default is \code{FALSE}.}
#' \item{\code{verbose}}{Logical, whether to show detailed information. Default is
#'                       \code{FALSE}.}
#' }
#' 
#' @examples trainset = system.file("dat", "smalltrain.txt", package = "recosystem")
#' r = Reco()
#' res = r$tune(
#'     trainset,
#'     opts = list(dim = c(10, 20, 30), lrate = c(0.05, 0.1, 0.2), nthread = 2)
#' )
#' r$train(trainset, opts = res$min)
#' 
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{\link{train}}, \code{\link{output}}, \code{\link{predict}}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#' 
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A learning-rate schedule for stochastic gradient methods to matrix factorization.
#' PAKDD, 2015. 
#' 
NULL


#' Training a Recommender Model
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
#' 
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
#' 
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


#' Outputing Factorization Matrices
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