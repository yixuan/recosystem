library(RSpectra)
library(Matrix)
nuser = 1000
nitem = 1000

set.seed(123)
# Create a fully observed rating matrix
m = matrix(sample(1:5, nuser * nitem, replace = TRUE), nuser, nitem)
# Reduce the rank to 100
decomp = svds(m, 100)
mreduce = decomp$u %*% diag(decomp$d) %*% t(decomp$v)
mreduce = round(mreduce)
mreduce[mreduce < 1] = 1
mreduce[mreduce > 5] = 5
# Convert to triplet form
msp = as(mreduce, "dgTMatrix")
dat = cbind(msp@i, msp@j, msp@x)
# Write data files
ntrain = 10000
ntest = 10000
smalltrain = dat[sample(nrow(dat), ntrain), ]
smalltest = dat[sample(nrow(dat), ntest), 1:2]
write.table(smalltrain, "smalltrain.txt", sep = " ",
            col.names = FALSE, row.names = FALSE)
write.table(smalltest, "smalltest.txt", sep = " ",
            col.names = FALSE, row.names = FALSE)
