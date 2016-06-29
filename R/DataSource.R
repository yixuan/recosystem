data_file = function(path, index1 = FALSE, ...)
{
    ## Check whether data file exists
    file_path = path.expand(path)
    if(!file.exists(file_path))
    {
        stop(sprintf("%s does not exist", file_path))
    }
    
    structure(list(path = file_path, index1 = as.logical(index1)),
              class = "DataFile")
}

data_df = function(dat, index1 = FALSE, ...)
{
    ## Check whether the required columns exist
    dnames = names(dat)
    if(!("user" %in% dnames) || !("item" %in% dnames))
        stop("data frame should contain columns named 'user' and 'item'")
    
    structure(list(dat = dat, index1 = as.logical(index1)),
              class = "DataDF")
}

data_rmm = function(rmm, ...)
{
    
}