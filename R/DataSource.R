setClass("DataSource",
         slots = c(source = "ANY",
                   index1 = "logical",
                   type   = "character")
         )

data_file = function(path, index1 = FALSE, ...)
{
    ## Check whether data file exists
    file_path = path.expand(path)
    if(!file.exists(file_path))
    {
        stop(sprintf("%s does not exist", file_path))
    }
    
    new("DataSource", source = file_path, index1 = index1, type = "file")
}

data_df = function(dat, index1 = FALSE, ...)
{
    ## Check whether the required columns exist
    dnames = names(dat)
    if(!("user" %in% dnames) || !("item" %in% dnames))
        stop("data frame should contain columns named 'user' and 'item'")
    
    new("DataSource", source = dat, index1 = index1, type = "data_frame")
}

data_rmm = function(rmm, ...)
{
    
}