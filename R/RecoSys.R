RecoSys = setRefClass("RecoSys",
                      fields = list(model      = "RecoModel",
                                    train_pars = "list"))

#' Constructing a Recommender System Object
#'
#' This function simply returns an object of class "\code{RecoSys}"
#' that can be used to construct recommender model and conduct prediction.
#'
#' @return \code{Reco()} returns an object of class "\code{RecoSys}"
#' equipped with methods
#' \code{$\link{train}()}, \code{$\link{tune}()}, \code{$\link{output}()}
#' and \code{$\link{predict}()}, which describe the typical process of
#' building and tuning model, exporting factorization matrices, and
#' predicting results. See their help documents for details.
#' @author Yixuan Qiu <\url{https://statr.me}>
#' @seealso \code{$\link{tune}()}, \code{$\link{train}()}, \code{$\link{output}()},
#' \code{$\link{predict}()}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#'
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Learning-rate Schedule for Stochastic Gradient Methods to Matrix Factorization.
#' PAKDD, 2015.
#'
#' W.-S. Chin, B.-W. Yuan, M.-Y. Yang, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' LIBMF: A Library for Parallel Matrix Factorization in Shared-memory Systems.
#' Technical report, 2015.
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
#' r$tune(train_data, opts = list(dim      = c(10L, 20L),
#'                                costp_l1 = c(0, 0.1),
#'                                costp_l2 = c(0.01, 0.1),
#'                                costq_l1 = c(0, 0.1),
#'                                costq_l2 = c(0.01, 0.1),
#'                                lrate    = c(0.01, 0.1))
#' )}
#'
#' @name tune
#'
#' @param r Object returned by \code{\link{Reco}}().
#' @param train_data An object of class "DataSource" that describes the source
#'                   of training data, typically returned by function
#'                   \code{\link{data_file}()}, \code{\link{data_memory}()},
#'                   or \code{\link{data_matrix}()}.
#' @param opts A number of candidate tuning parameter values and extra options in the
#'             model tuning procedure. See section \strong{Parameters and Options}
#'             for details.
#'
#' @return A list with two components:
#'
#' \describe{
#'   \item{\code{min}}{Parameter values with minimum cross validated loss.
#'                     This is a list that can be passed to the
#'                     \code{opts} argument in \code{$\link{train}()}.}
#'   \item{\code{res}}{A data frame giving the supplied candidate
#'                     values of tuning parameters, and one column showing the
#'                     loss function value associated with each combination.}
#' }
#'
#' @section Parameters and Options:
#' The \code{opts} argument should be a list that provides the candidate values
#' of tuning parameters and some other options. For tuning parameters (\code{dim},
#' \code{costp_l1}, \code{costp_l2}, \code{costq_l1}, \code{costq_l2},
#' and \code{lrate}), users can provide a numeric vector for each one, so that
#' the model will be evaluated on each combination of the candidate values.
#' For other non-tuning options, users should give a single value. If a parameter
#' or option is not set by the user, the program will use a default one.
#'
#' See below for the list of available parameters and options:
#'
#' \describe{
#' \item{\code{dim}}{Tuning parameter, the number of latent factors.
#'                   Can be specified as an integer vector, with default value
#'                   \code{c(10L, 20L)}.}
#' \item{\code{costp_l1}}{Tuning parameter, the L1 regularization cost for user factors.
#'                        Can be specified as a numeric vector, with default value
#'                        \code{c(0, 0.1)}.}
#' \item{\code{costp_l2}}{Tuning parameter, the L2 regularization cost for user factors.
#'                        Can be specified as a numeric vector, with default value
#'                        \code{c(0.01, 0.1)}.}
#' \item{\code{costq_l1}}{Tuning parameter, the L1 regularization cost for item factors.
#'                        Can be specified as a numeric vector, with default value
#'                        \code{c(0, 0.1)}.}
#' \item{\code{costq_l2}}{Tuning parameter, the L2 regularization cost for item factors.
#'                        Can be specified as a numeric vector, with default value
#'                        \code{c(0.01, 0.1)}.}
#' \item{\code{lrate}}{Tuning parameter, the learning rate, which can be thought
#'                     of as the step size in gradient descent.
#'                     Can be specified as a numeric vector, with default value
#'                     \code{c(0.01, 0.1)}.}
#' \item{\code{loss}}{Character string, the loss function. Default is "l2", see
#'                    section \strong{Parameters and Options} in \code{$\link{train}()}
#'                    for details.}
#' \item{\code{c}}{Float, value of negative entries (default 0.0001).
#'                 Every positive entry is assumed to be 1.
#'                 This is only relevant for one-class factorization.}
#' \item{\code{nfold}}{Integer, the number of folds in cross validation. Default is 5.}
#' \item{\code{niter}}{Integer, the number of iterations. Default is 20.}
#' \item{\code{nthread}}{Integer, the number of threads for parallel
#'                       computing. Default is 1.}
#' \item{\code{nbin}}{Integer, the number of bins. Must be greater than \code{nthread}.
#'                    Default is 20.}
#' \item{\code{nmf}}{Logical, whether to perform non-negative matrix factorization.
#'                   Default is \code{FALSE}.}
#' \item{\code{verbose}}{Logical, whether to show detailed information. Default is
#'                       \code{FALSE}.}
#' \item{\code{progress}}{Logical, whether to show a progress bar. Default is \code{TRUE}.}
#' }
#'
#' @examples \dontrun{
#' train_set = system.file("dat", "smalltrain.txt", package = "recosystem")
#' train_src = data_file(train_set)
#' r = Reco()
#' set.seed(123) # This is a randomized algorithm
#' res = r$tune(
#'     train_src,
#'     opts = list(dim = c(10, 20, 30),
#'                 costp_l1 = 0, costq_l1 = 0,
#'                 lrate = c(0.05, 0.1, 0.2), nthread = 2)
#' )
#' r$train(train_src, opts = res$min)
#' }
#'
#' @author Yixuan Qiu <\url{https://statr.me}>
#' @seealso \code{$\link{train}()}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#'
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Learning-rate Schedule for Stochastic Gradient Methods to Matrix Factorization.
#' PAKDD, 2015.
#'
#' W.-S. Chin, B.-W. Yuan, M.-Y. Yang, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' LIBMF: A Library for Parallel Matrix Factorization in Shared-memory Systems.
#' Technical report, 2015.
NULL

RecoSys$methods(
    tune = function(train_data, opts = list(dim      = c(10L, 20L),
                                            costp_l1 = c(0, 0.1),
                                            costp_l2 = c(0.01, 0.1),
                                            costq_l1 = c(0, 0.1),
                                            costq_l2 = c(0.01, 0.1),
                                            lrate    = c(0.01, 0.1)))
    {
        ## Backward compatibility for version 0.3
        if(is.character(train_data))
        {
            warning("API has changed since version 0.4
use data_file(path) for argument 'train_data' instead")
            train_data = data_file(train_data)
        }
        if("cost" %in% names(opts))
            stop("the 'cost' parameter has been expanded to and replaced by
costp_l1, costp_l2, costq_l1, and costq_l2 since version 0.4")

        if(!inherits(train_data, "DataSource") || !isS4(train_data))
            stop("'train_data' should be an object of class 'DataSource'")

        ## Tuning parameters: dim, costp_*, costq_*, lrate
        ## First set up default values
        opts_tune = list(dim      = c(10L, 20L),
                         costp_l1 = c(0, 0.1),
                         costp_l2 = c(0.01, 0.1),
                         costq_l1 = c(0, 0.1),
                         costq_l2 = c(0.01, 0.1),
                         lrate    = c(0.01, 0.1))

        ## Update opts_tune from opts
        opts = as.list(opts)
        opts_common = intersect(names(opts_tune), names(opts))
        opts_tune[opts_common] = opts[opts_common]
        opts_tune = lapply(opts_tune, as.numeric)
        opts_tune$dim = as.integer(opts_tune$dim)

        ## Expand combinations
        opts_tune = expand.grid(opts_tune)

        ## Other options
        opts_train = list(loss = "l2", nfold = 5L, niter = 20L, nthread = 1L, c = 0.0001,
                          nbin = 20L, nmf = FALSE, verbose = FALSE, progress = TRUE)
        opts_common = intersect(names(opts_train), names(opts))
        opts_train[opts_common] = opts[opts_common]

        loss_fun = c("l2" = 0, "l1" = 1, "kl" = 2,
                     "log" = 5, "squared_hinge" = 6, "hinge" = 7,
                     "row_log" = 10, "col_log" = 11, "sse" = 12)
        if(!(opts_train$loss %in% names(loss_fun)))
            stop(paste("'loss' must be one of", paste(names(loss_fun), collapse = ", "), sep = "\n"))
        if(opts_train$loss == "kl" && (!opts_train$nmf))
            stop("nmf must be TRUE if loss == 'kl'")
        opts_train$loss = as.integer(loss_fun[opts_train$loss])

        loss_fun = .Call(reco_tune, train_data, opts_tune, opts_train)

        opts_tune$loss_fun = loss_fun
        opts_tune = na.omit(opts_tune)
        if(!nrow(opts_tune))
            stop("results are all NA/NaN")

        tune_min = as.list(opts_tune[which.min(loss_fun), ])
        attr(tune_min, "out.attrs") = NULL

        return(list(min = tune_min, res = opts_tune))
    }
)



#' Training a Recommender Model
#'
#' @description This method is a member function of class "\code{RecoSys}"
#' that trains a recommender model. It will read from a training data source and
#' create a model file at the specified location. The model file contains
#' necessary information for prediction.
#'
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$train(train_data, out_model = file.path(tempdir(), "model.txt"),
#'         opts = list())}
#'
#' @name train
#'
#' @param r Object returned by \code{\link{Reco}}().
#' @param train_data An object of class "DataSource" that describes the source
#'                   of training data, typically returned by function
#'                   \code{\link{data_file}()}, \code{\link{data_memory}()},
#'                   or \code{\link{data_matrix}()}.
#' @param out_model Path to the model file that will be created.
#'                  If passing \code{NULL}, the model will be stored in-memory, and
#'                  model matrices can then be accessed under \code{r$model$matrices}.
#' @param opts A number of parameters and options for the model training.
#'             See section \strong{Parameters and Options} for details.
#'
#' @section Parameters and Options:
#' The \code{opts} argument is a list that can supply any of the following parameters:
#'
#' \describe{
#' \item{\code{loss}}{Character string, the loss function. Default is "l2", see below for details.}
#' \item{\code{dim}}{Integer, the number of latent factors. Default is 10.}
#' \item{\code{costp_l1}}{Numeric, L1 regularization parameter for user factors. Default is 0.}
#' \item{\code{costp_l2}}{Numeric, L2 regularization parameter for user factors. Default is 0.1.}
#' \item{\code{costq_l1}}{Numeric, L1 regularization parameter for item factors. Default is 0.}
#' \item{\code{costq_l2}}{Numeric, L2 regularization parameter for item factors. Default is 0.1.}
#' \item{\code{lrate}}{Numeric, the learning rate, which can be thought
#'                     of as the step size in gradient descent. Default is 0.1.}
#' \item{\code{c}}{Float, value of negative entries (default 0.0001).
#'                 Every positive entry is assumed to be 1.
#'                 This is only relevant for one-class factorization.}           
#' \item{\code{niter}}{Integer, the number of iterations. Default is 20.}
#' \item{\code{nthread}}{Integer, the number of threads for parallel
#'                       computing. Default is 1.}
#' \item{\code{nbin}}{Integer, the number of bins. Must be greater than \code{nthread}.
#'                    Default is 20.}
#' \item{\code{nmf}}{Logical, whether to perform non-negative matrix factorization.
#'                   Default is \code{FALSE}.}
#' \item{\code{verbose}}{Logical, whether to show detailed information. Default is
#'                       \code{TRUE}.}
#' }
#'
#' The \code{loss} option may take the following values:
#'
#' For real-valued matrix factorization,
#'
#' \describe{
#' \item{\code{"l2"}}{Squared error (L2-norm)}
#' \item{\code{"l1"}}{Absolute error (L1-norm)}
#' \item{\code{"kl"}}{Generalized KL-divergence}
#' }
#'
#' For binary matrix factorization,
#'
#' \describe{
#' \item{\code{"log"}}{Logarithmic error}
#' \item{\code{"squared_hinge"}}{Squared hinge loss}
#' \item{\code{"hinge"}}{Hinge loss}
#' }
#'
#' For one-class matrix factorization,
#'
#' \describe{
#' \item{\code{"row_log"}}{Row-oriented pair-wise logarithmic loss}
#' \item{\code{"col_log"}}{Column-oriented pair-wise logarithmic loss}
#' \item{\code{"sse"}}{Sum of squared errors}
#' }
#'
#' @examples ## Training model from a data file
#' train_set = system.file("dat", "smalltrain.txt", package = "recosystem")
#' train_data = data_file(train_set)
#' r = Reco()
#' set.seed(123) # This is a randomized algorithm
#' # The model will be saved to a file
#' r$train(train_data, out_model = file.path(tempdir(), "model.txt"),
#'         opts = list(dim = 20, costp_l2 = 0.01, costq_l2 = 0.01, nthread = 1)
#' )
#'
#' ## Training model from data in memory
#' train_df = read.table(train_set, sep = " ", header = FALSE)
#' train_data = data_memory(train_df[, 1], train_df[, 2], rating = train_df[, 3])
#' set.seed(123)
#' # The model will be stored in memory
#' r$train(train_data, out_model = NULL,
#'         opts = list(dim = 20, costp_l2 = 0.01, costq_l2 = 0.01, nthread = 1)
#' )
#'
#' ## Training model from data in a sparse matrix
#' if(require(Matrix))
#' {
#'     mat = Matrix::sparseMatrix(i = train_df[, 1], j = train_df[, 2], x = train_df[, 3],
#'                                repr = "T", index1 = FALSE)
#'     train_data = data_matrix(mat)
#'     r$train(train_data, out_model = NULL,
#'             opts = list(dim = 20, costp_l2 = 0.01, costq_l2 = 0.01, nthread = 1))
#' }
#'
#' @author Yixuan Qiu <\url{https://statr.me}>
#' @seealso \code{$\link{tune}()}, \code{$\link{output}()}, \code{$\link{predict}()}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#'
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Learning-rate Schedule for Stochastic Gradient Methods to Matrix Factorization.
#' PAKDD, 2015.
#'
#' W.-S. Chin, B.-W. Yuan, M.-Y. Yang, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' LIBMF: A Library for Parallel Matrix Factorization in Shared-memory Systems.
#' Technical report, 2015.
NULL

RecoSys$methods(
    train = function(train_data, out_model = NULL, opts = list())
    {
        ## Backward compatibility for version 0.3
        if(is.character(train_data))
        {
            warning("API has changed since version 0.4
use data_file(path) for argument 'train_data' instead")
            train_data = data_file(train_data)
        }
        if("cost" %in% names(opts))
            stop("the 'cost' parameter has been expanded to and replaced by
costp_l1, costp_l2, costq_l1, and costq_l2 since version 0.4")

        if(!inherits(train_data, "DataSource") || !isS4(train_data))
            stop("'train_data' should be an object of class 'DataSource'")

        ## Parse options
        opts_train = list(loss = "l2",
                          dim = 10L,
                          costp_l1 = 0, costp_l2 = 0.1,
                          costq_l1 = 0, costq_l2 = 0.1,
                          lrate = 0.1, c = 0.0001,
                          niter = 20L, nthread = 1L, nbin = 20L,
                          nmf = FALSE, verbose = TRUE)
        opts = as.list(opts)
        opts_common = intersect(names(opts), names(opts_train))
        opts_train[opts_common] = opts[opts_common]

        loss_fun = c("l2" = 0, "l1" = 1, "kl" = 2,
                     "log" = 5, "squared_hinge" = 6, "hinge" = 7,
                     "row_log" = 10, "col_log" = 11, "sse" = 12)
        if(!(opts_train$loss %in% names(loss_fun)))
            stop(paste("'loss' must be one of", paste(names(loss_fun), collapse = ", "), sep = "\n"))
        if(opts_train$loss == "kl" && (!opts_train$nmf))
            stop("nmf must be TRUE if loss == 'kl'")
        opts_train$loss = as.integer(loss_fun[opts_train$loss])

        ## `model_path = NULL` indicates that the model will not be saved to hard disk
        model_path = if(is.null(out_model)) NULL else path.expand(out_model)
        model_param = .Call(reco_train, train_data, model_path, opts_train)

        .self$model$path = if(is.null(out_model)) "" else model_path
        .self$model$nuser = model_param$nuser
        .self$model$nitem = model_param$nitem
        .self$model$nfac  = model_param$nfac
        if(length(model_param$matrices))
        {
            .self$model$matrices = list(
                P = new("float32", Data = model_param$matrices$P),
                Q = new("float32", Data = model_param$matrices$Q),
                b = new("float32", Data = model_param$matrices$b)
            )
        }
        .self$train_pars  = opts_train

        invisible(.self)
    }
)



#' Exporting Factorization Matrices
#'
#' @description This method is a member function of class "\code{RecoSys}"
#' that exports the user score matrix \eqn{P} and the item score matrix \eqn{Q}.
#'
#' Prior to calling this method, model needs to be trained using member function
#' \code{$\link{train}()}.
#'
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$train(...)
#' r$output(out_P = out_file("mat_P.txt"), out_Q = out_file("mat_Q.txt"))}
#'
#' @name output
#'
#' @param r Object returned by \code{\link{Reco}()}.
#' @param out_P An object of class \code{Output} that specifies the
#'              output format of the user matrix, typically returned by function
#'              \code{\link{out_file}()}, \code{\link{out_memory}()} or
#'              \code{\link{out_nothing}()}.
#'              \code{\link{out_file}()} writes the matrix into a file, with
#'              each row representing a user and each column representing a
#'              latent factor.
#'              \code{\link{out_memory}()} exports the matrix
#'              into the return value of \code{$output()}.
#'              \code{\link{out_nothing}()} means the matrix will not be exported.
#' @param out_Q Ditto, but for the item matrix.
#'
#' @return A list with components \code{P} and \code{Q}. They will be filled
#'         with user or item matrix if \code{\link{out_memory}()} is used
#'         in the function argument, otherwise \code{NULL} will be returned.
#'
#'
#' @examples train_set = system.file("dat", "smalltrain.txt", package = "recosystem")
#' r = Reco()
#' set.seed(123) # This is a randomized algorithm
#' r$train(data_file(train_set), out_model = file.path(tempdir(), "model.txt"),
#'         opts = list(dim = 10, nmf = TRUE))
#'
#' ## Write P and Q matrices to files
#' P_file = out_file(tempfile())
#' Q_file = out_file(tempfile())
#' r$output(P_file, Q_file)
#' head(read.table(P_file@dest, header = FALSE, sep = " "))
#' head(read.table(Q_file@dest, header = FALSE, sep = " "))
#'
#' ## Skip P and only export Q
#' r$output(out_nothing(), Q_file)
#'
#' ## Return P and Q in memory
#' res = r$output(out_memory(), out_memory())
#' head(res$P)
#' head(res$Q)
#'
#' @author Yixuan Qiu <\url{https://statr.me}>
#' @seealso \code{$\link{train}()}, \code{$\link{predict}()}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#'
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Learning-rate Schedule for Stochastic Gradient Methods to Matrix Factorization.
#' PAKDD, 2015.
#'
#' W.-S. Chin, B.-W. Yuan, M.-Y. Yang, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' LIBMF: A Library for Parallel Matrix Factorization in Shared-memory Systems.
#' Technical report, 2015.
NULL

RecoSys$methods(
    output = function(out_P = out_file("mat_P.txt"), out_Q = out_file("mat_Q.txt"))
    {
        ## Backward compatibility for version 0.3
        if(is.character(out_P))
        {
            warning("API has changed since version 0.4
use out_file(path) for argument 'out_P' instead")
            out_P = out_file(out_P)
        }
        if(is.character(out_Q))
        {
            warning("API has changed since version 0.4
use out_file(path) for argument 'out_Q' instead")
            out_Q = out_file(out_Q)
        }

        ## Check whether model has been trained
        ## If the model is saved to hard disk, check whether the model file exists
        ## If the model is stored in memory, check whether .self$model$matrices contains data
        model_path = .self$model$path
        trained = file.exists(model_path) || length(.self$model$matrices)
        if(!trained)
        {
            stop("model not trained yet
[Call $train() method to train model]")
        }

        P = NULL
        Q = NULL

        ## If model matrices are stored in memory, we directly export them
        if(length(.self$model$matrices))
        {
            ## Convert to double
            Pd = t(as.double(.self$model$matrices$P))
            Qd = t(as.double(.self$model$matrices$Q))

            if(out_P@type == "file")
            {
                write.table(Pd, out_P@dest, row.names = FALSE, col.names = FALSE, na = "NaN")
                cat(sprintf("P matrix generated at %s\n", out_P@dest))
            }
            if(out_P@type == "memory")
                P = Pd

            if(out_Q@type == "file")
            {
                write.table(Qd, out_Q@dest, row.names = FALSE, col.names = FALSE, na = "NaN")
                cat(sprintf("Q matrix generated at %s\n", out_Q@dest))
            }
            if(out_Q@type == "memory")
                Q = Qd

            return(list(P = P, Q = Q))
        }

        ## Otherwise, first read model file, and then output matrices
        res = .Call(reco_output, model_path, out_P, out_Q)

        if(out_P@type == "file")
            cat(sprintf("P matrix generated at %s\n", out_P@dest))
        if(out_P@type == "memory")
            P = t(res$Pdata)

        if(out_Q@type == "file")
            cat(sprintf("Q matrix generated at %s\n", out_Q@dest))
        if(out_Q@type == "memory")
            Q = t(res$Qdata)

        return(list(P = P, Q = Q))
    }
)



#' Recommender Model Predictions
#'
#' @description This method is a member function of class "\code{RecoSys}"
#' that predicts unknown entries in the rating matrix.
#'
#' Prior to calling this method, model needs to be trained using member function
#' \code{$\link{train}()}.
#'
#' The common usage of this method is
#' \preformatted{r = Reco()
#' r$train(...)
#' r$predict(test_data, out_pred = out_file("predict.txt")}
#'
#' @name predict
#'
#' @param r Object returned by \code{\link{Reco}()}.
#' @param test_data An object of class "DataSource" that describes the source
#'                  of testing data, typically returned by function
#'                   \code{\link{data_file}()}, \code{\link{data_memory}()},
#'                   or \code{\link{data_matrix}()}.
#' @param out_pred An object of class \code{Output} that specifies the
#'                 output format of prediction, typically returned by function
#'                 \code{\link{out_file}()}, \code{\link{out_memory}()} or
#'                 \code{\link{out_nothing}()}.
#'                 \code{\link{out_file}()} writes the result into a
#'                 file, \code{\link{out_memory}()} exports the vector of
#'                 predicted values into the return value of \code{$predict()},
#'                 and \code{\link{out_nothing}()} means the result will be
#'                 neither returned nor written into a file (but computation will
#'                 still be conducted).
#'
#' @examples \dontrun{
#' train_file = data_file(system.file("dat", "smalltrain.txt", package = "recosystem"))
#' test_file = data_file(system.file("dat", "smalltest.txt", package = "recosystem"))
#' r = Reco()
#' set.seed(123) # This is a randomized algorithm
#' opts_tune = r$tune(train_file)$min
#' r$train(train_file, out_model = NULL, opts = opts_tune)
#'
#' ## Write predicted values into file
#' out_pred = out_file(tempfile())
#' r$predict(test_file, out_pred)
#'
#' ## Return predicted values in memory
#' pred = r$predict(test_file, out_memory())
#'
#' ## If testing data are stored in memory
#' test_df = read.table(test_file@source, sep = " ", header = FALSE)
#' test_data = data_memory(test_df[, 1], test_df[, 2])
#' pred2 = r$predict(test_data, out_memory())
#'
#' ## Compare results
#' print(scan(out_pred@dest, n = 10))
#' head(pred, 10)
#' head(pred2, 10)
#'
#' ## If testing data are stored as a sparse matrix
#' if(require(Matrix))
#' {
#'     mat = Matrix::sparseMatrix(i = test_df[, 1], j = test_df[, 2], x = -1,
#'                                repr = "T", index1 = FALSE)
#'     test_data = data_matrix(mat)
#'     pred3 = r$predict(test_data, out_memory())
#'     print(head(pred3, 10))
#' }
#' }
#'
#' @author Yixuan Qiu <\url{https://statr.me}>
#' @seealso \code{$\link{train}()}
#' @references W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Fast Parallel Stochastic Gradient Method for Matrix Factorization in Shared Memory Systems.
#' ACM TIST, 2015.
#'
#' W.-S. Chin, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' A Learning-rate Schedule for Stochastic Gradient Methods to Matrix Factorization.
#' PAKDD, 2015.
#'
#' W.-S. Chin, B.-W. Yuan, M.-Y. Yang, Y. Zhuang, Y.-C. Juan, and C.-J. Lin.
#' LIBMF: A Library for Parallel Matrix Factorization in Shared-memory Systems.
#' Technical report, 2015.
NULL

RecoSys$methods(
    predict = function(test_data, out_pred = out_memory())
    {
        ## Backward compatibility for version 0.3
        if(is.character(test_data))
        {
            warning("API has changed since version 0.4
use data_file(path) for argument 'test_data' instead")
            test_data = data_file(test_data)
        }
        if(is.character(out_pred))
        {
            warning("API has changed since version 0.4
use out_file(path) for argument 'out_pred' instead")
            out_pred = out_file(out_pred)
        }

        if(!inherits(test_data, "DataSource") || !isS4(test_data))
            stop("'test_data' should be an object of class 'DataSource'")

        ## Check whether model has been trained
        ## If the model is saved to hard disk, check whether the model file exists
        ## If the model is stored in memory, check whether .self$model$matrices contains data
        model_path = .self$model$path
        trained = file.exists(model_path) || length(.self$model$matrices)
        if(!trained)
        {
            stop("model not trained yet
[Call $train() method to train model]")
        }

        model_inmemory = list()
        if(length(.self$model$matrices)) {
            model_inmemory = list(
                P = .self$model$matrices$P@Data,
                Q = .self$model$matrices$Q@Data,
                b = .self$model$matrices$b@Data,
                m = .self$model$nuser,
                n = .self$model$nitem,
                k = .self$model$nfac,
                fun = .self$train_pars$loss
            )
        }
        res = .Call(reco_predict, test_data, model_path, out_pred, model_inmemory)

        if(out_pred@type == "file")
            cat(sprintf("prediction output generated at %s\n", out_pred@dest))

        if(out_pred@type != "memory")
            return(invisible(NULL))

        return(res)
    }
)

RecoSys$methods(
    show = function()
    {
        cat("[=== Fitted Model ===]\n\n")
        .self$model$show()

        cat("\n\n[=== Training Options ===]\n\n")
        catl = function(key, val, ...)
            cat(sprintf("%-20s = %s\n", key, val), ..., sep = "")

        loss = .self$train_pars$loss
        loss_fun_name = if(is.null(loss)) character(0) else switch(as.character(loss),
            "0" = "Squared error (L2-norm)",
            "1" = "Absolute error (L1-norm)",
            "2" = "Generalized KL-divergence",
            "5" = "Logarithmic error",
            "6" = "Squared hinge loss",
            "7" = "Hinge loss",
            "10" = "Row-oriented pair-wise logarithmic loss",
            "11" = "Column-oriented pair-wise logarithmic loss",
            "12" = "Sum of squared errors",
            "Unknown"
        )

        catl("Loss function",        loss_fun_name)
        catl("L1 penalty for P",     .self$train_pars$costp_l1)
        catl("L2 penalty for P",     .self$train_pars$costp_l2)
        catl("L1 penalty for Q",     .self$train_pars$costq_l1)
        catl("L2 penalty for Q",     .self$train_pars$costq_l2)
        catl("Learning rate",        .self$train_pars$lrate)
        catl("Negative value",       .self$train_pars$c)
        catl("NMF",                  .self$train_pars$nmf)
        catl("Number of iterations", .self$train_pars$niter)
        catl("Number of threads",    .self$train_pars$nthread)
        catl("Verbose",              .self$train_pars$verbose)

        invisible(.self)
    }
)
