RecoDat = setRefClass("RecoDat",
                      fields = list(dir = "character",
                                    rawfile = "character",
                                    binfile = "character",
                                    type = "character"))

RecoDat$methods(
    initialize = function()
    {
        .self$dir = tempdir()
        .self$rawfile = ""
        .self$binfile = ""
        .self$type = ""
    }
)

RecoDat$methods(
    convert = function(rawfile, outdir)
    {
        ## Check if rawfile exists
        if(!file.exists(rawfile))
        {
            stop("rawfile: file doesn't exist")
        }
        
        ## Set directory to write binary file
        if(missing(outdir))
        {
            ## If outdir not specified, use temp directory
            .self$dir = tempdir()
        } else {
            ## Check validity of outdir argument
            if(file.exists(outdir))
            {
                if(file.info(outdir)$isdir) {
                    .self$dir = path.expand(outdir)
                } else {
                    stop("outdir: not a directory")
                }
            } else {
                stop("outdir: directory doesn't exist")
            }
        }
        
        ## Path of the binary file to be written
        outfile = file.path(.self$dir,
                            paste(basename(rawfile), "bin", sep = "."))
        
        infile = path.expand(rawfile)
        status = .Call("convert_wrapper", infile, outfile,
                       PACKAGE = "Recosystem")
        ## status: TRUE for success, FALSE for failure
        if(!status)
        {
            stop("conversion of data file failed")
        }
        cat(sprintf("binary file generated at %s\n", outfile));
        
        .self$rawfile = infile
        .self$binfile = outfile
        
        invisible(.self)
    }
)

RecoDat$methods(
    view = function()
    {
        if(!file.exists(.self$binfile))
        {
            cat("Data file not set\n")
            cat(sprintf("[Call $%s$convert() method to set data]\n",
                        .self$type))
            return(.self)
        }
        
        status = .Call("view_data_wrapper", .self$binfile,
                       PACKAGE = "Recosystem")
        
        if(!status)
        {
            stop("viewing data file failed")
        }
        
        invisible(.self)
    }
)

RecoDat$methods(
    show = function()
    {
        .self$view()
    }
)
