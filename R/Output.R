setClass("Output",
         slots = c(dest = "ANY",
                   type = "character")
         )

#' Specifying Output Format
#' 
#' Functions in this page are used to specify the format of output results.
#' They are intended to provide the argument of functions such as
#' \code{$\link{output}()} and \code{$\link{predict}()}.
#' Currently there are three types of output: \code{out_file()} indicates
#' that the result should be written into a file, \code{out_memory()} makes
#' the result to be returned as R objects, and \code{out_nothing()} means
#' the result is not needed and will not be returned.
#' 
#' @param path Path to the output file.
#' @param \dots Currently unused.
#' @return An object of class "Output" as required by
#' \code{$\link{output}()} and \code{$\link{predict}()}.
#' 
#' @author Yixuan Qiu <\url{http://statr.me}>
#' @seealso \code{$\link{output}()}, \code{$\link{predict}()}
#' 
#' @rdname output_format
#' @name output_format
#' @export
out_file = function(path, ...)
{
    new("Output", dest = as.character(path), type = "file")
}

#' @rdname output_format
#' @export
out_memory = function(...)
{
    new("Output", dest = "", type = "memory")
}

#' @rdname output_format
#' @export
out_nothing = function(...)
{
    new("Output", dest = "", type = "nothing")
}