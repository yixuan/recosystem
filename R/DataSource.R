setClass("DataSource",
         slots = c(source = "ANY",
                   index1 = "logical",
                   type   = "character")
         )

#' Specifying Data Source
#' 
#' Functions in this page are used to specify the source of data in the recommender system.
#' They are intended to provide the input argument of functions such as
#' \code{$\link{tune}()}, \code{$\link{train}()}, and \code{$\link{predict}()}.
#' Currently two data formats are supported: data file (via function \code{data_file()}),
#' and data in memory as R objects (via function \code{data_memory()}).
#' 
#' In \code{$\link{tune}()} and \code{$\link{train}()}, functions in this page
#' are used to specify the source of training data. \code{data_file()}
#' expects a text file that describes a sparse matrix
#' in triplet form, i.e., each line in the file contains three numbers
#' \preformatted{row col value}
#' representing a number in the rating matrix
#' with its location. In real applications, it typically looks like
#' \preformatted{user_index item_index rating}
#' The \file{smalltrain.txt} file in the \file{dat} directory of this package
#' shows an example of training data file.
#' 
#' From version 0.4 \pkg{recosystem} supports two special types of matrix
#' factorization: the binary matrix factorization (BMF), and the one-class
#' matrix factorization (OCMF). BMF requires ratings to take value from
#' \eqn{{-1, 1}}, and OCMF requires all the ratings to be positive.
#' 
#' If user index, item index, and ratings are stored as R vectors in memory,
#' they can be passed to \code{data_memory()} to form the training data source.
#' 
#' By default the user index and item index start with zeros, and the option
#' \code{index1 = TRUE} can be set if they start with ones.
#' 
#' In \code{$\link{predict}()}, functions in this page provide the source of
#' testing data. The testing data have the same format as training data, except
#' that the value (rating) column is not required, and will be ignored if it is
#' provided. The \file{smalltest.txt} file in the \file{dat} directory of this
#' package shows an example of testing data file.
#' 
#' @param path Path to the data file.
#' @param user_index An integer vector giving the user indices of rating scores.
#' @param item_index An integer vector giving the item indices of rating scores.
#' @param rating A numeric vector of the observed entries in the rating matrix.
#'               Can be specified as \code{NULL} for testing data, in which case
#'               it is ignored.
#' @param index1 Whether the user indices and item indices start with 1
#'               (\code{index1 = TRUE}) or 0 (\code{index1 = FALSE}).
#' @param \dots Currently unused.
#' @return An object of class "DataSource" as required by
#' \code{$\link{tune}()}, \code{$\link{train}()}, and \code{$\link{predict}()}.
#' 
#' @author Yixuan Qiu <\url{https://statr.me}>
#' @seealso \code{$\link{tune}()}, \code{$\link{train}()}, \code{$\link{predict}()}
#' 
#' @rdname data_source
#' @name data_source
#' @export
data_file = function(path, index1 = FALSE, ...)
{
    ## Check whether data file exists
    file_path = path.expand(path)
    if(!file.exists(file_path))
    {
        stop(sprintf("file '%s' does not exist", file_path))
    }
    
    new("DataSource", source = file_path, index1 = index1, type = "file")
}

#' @rdname data_source
#' @export
data_memory = function(user_index, item_index, rating = NULL, index1 = FALSE, ...)
{
    user_index = as.integer(user_index)
    item_index = as.integer(item_index)

    if(length(user_index) < 1)
        stop("length of user_index must be greater than zero")
    if(length(user_index) != length(item_index))
        stop("user_index and item_index must have the same length")
    if(!is.null(rating) && length(rating) != length(user_index))
        stop("user_index, item_index, and rating must have the same length")
    
    rating = as.numeric(rating)
    
    new("DataSource", source = list(user_index, item_index, rating),
                      index1 = index1, type = "memory")
}
