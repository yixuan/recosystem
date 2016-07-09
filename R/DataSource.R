setClass("DataSource",
         slots = c(source = "ANY",
                   index1 = "logical",
                   type   = "character")
         )

#' Specifying Data Source
#' 
#' Functions in this page are used to specify the source of data in the recommender system.
#' They are intended to provide the input objects of functions such as
#' \code{$\link{tune}()} and \code{$\link{train}()}.
#' Currently two data formats are supported: data file (via function \code{data_file()})
#' and data frame (via function \code{data_df()}).
#' 
#' The training data file takes the format of sparse matrix
#' in triplet form, i.e., each line in the file contains three numbers
#' \preformatted{row col value}
#' representing a number in the rating matrix
#' with its location. In real applications, it typically looks like
#' \preformatted{user_id item_id rating}
#' 
#' The testing data have the same format as training data, except that the value (rating)
#' column is not required, and will be ignored if it is provided.
#' 
#' @param path Path to the data file.
#' @param dat The data frame that represents the training or testing data set.
#' @param index1 Whether the user id and item id start with 1 (\code{index1 = TRUE}) or
#'               0 (\code{index1 = FALSE}).
#' @return An object of class "DataSource" as required by
#' \code{$\link{tune}()} and \code{$\link{train}()}.
#' 
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{$\link{tune}()}, \code{$\link{train}()}
#' 
#' @rdname data_source
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
data_memory = function(user_id, item_id, rating = NULL, index1 = FALSE, ...)
{
    new("DataSource", source = list(user_id, item_id, rating),
                      index1 = index1, type = "memory")
}

data_rmm = function(rmm, ...)
{
    
}