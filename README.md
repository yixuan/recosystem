## Recommender System with the recosystem Package

### About This Package

`recosystem` is an R wrapper of the `LIBMF` library developed by
Yu-Chin Juan, Yong Zhuang, Wei-Sheng Chin and Chih-Jen Lin
(http://www.csie.ntu.edu.tw/~cjlin/libmf/),
an open source library for recommender system using marix factorization.

A more detailed introduction can be found in the vignette of this package.

### A Quick View of Recommender System

The main task of recommender system is to predict unknown entries in the
rating matrix based on observed values, as is shown in the table below:

|        | item_1 | item_2 | item_3 | ... | item_n |
|--------|--------|--------|--------|-----|--------|
| user_1 | 2      | 3      | ??     | ... | 5      |
| user_2 | ??     | 4      | 3      | ... | ??     |
| user_3 | 3      | 2      | ??     | ... | 3      |
| ...    | ...    | ...    | ...    | ... |        |
| user_m | 1      | ??     | 5      | ... | 4      |

Each cell with number in it is the rating given by some user on a specific
item, while those marked with question marks are unknown ratings that need
to be predicted. In some other literatures, this problem may be given other
names, e.g. collaborative filtering, matrix completion, matrix recovery, etc.

### Highlights of LIBMF and recosystem

`LIBMF` itself is a parallelized library, meaning that users can take
advantage of multicore CPUs to speed up the computation. It also utilizes 
some advanced CPU features to further improve the performance. [@LIBMF]

`recosystem` is a wrapper of `LIBMF`, hence the features of `LIBMF`
are all included in `recosystem`. Also, unlike most other R packages for
statistical modeling which store the whole dataset and model object in memory,
`LIBMF` (and hence `recosystem`) is much hard-disk-based, for instance
the constructed model which contains information for prediction can be stored
in the hard disk, and prediction result can also be directly written into a file
rather than kept in memory. That is to say, `recosystem` will have a
comparatively small memory usage.

### Data Format

The data file for training set needs to be arranged in
sparse matrix triplet form, i.e., each line in the file contains three
numbers

```
user_id item_id rating
```

Testing data file is similar to training data, but since the ratings in
testing data are usually unknown, the `rating` entry in testing data file
can be omitted, or can be replaced by any placeholder such as `0` or `?`.

Be careful with the convention that `user_id` and `item_id` start from 0,
so the training data file for the example in the beginning will look like

```
0 0 2
0 1 3
1 1 4
1 2 3
2 0 3
2 1 2
...
```

And testing data file is

```
0 2
1 0
2 2
...
```

Since ratings for testing data are unknown, here we simply omit the third entry.
However if their values are really given, the testing data will serve as
a validation set on which RMSE of prediction can be calculated.

Example data files are contained in the `recosystem/dat`
(or `recosystem/inst/dat`, for source package) directory.

### Usage of recosystem

The usage of `recosystem` is quite simple, mainly consisting of the following steps:

1. Create a model object (a Reference Class object in R) by calling `Reco()`.
2. (Optionally) call the `$tune()` method to select best tuning parameters
along a set of candidate values.
3. Train the model by calling the `$train()` method. A number of parameters
can be set inside the function, possibly coming from the result of `$tune()`.
4. (Optionally) output the model, i.e. write the factorized $P$ and $Q$
matrices info files.
5. Use the `$predict()` method to compute predictions and write results
into a file.

Below is an example on some simulated data:

```r
library(recosystem)
set.seed(123) # This is a randomized algorithm
trainset = system.file("dat", "smalltrain.txt", package = "recosystem")
testset = system.file("dat", "smalltest.txt", package = "recosystem")
r = Reco()
opts = r$tune(trainset, opts = list(dim = c(10, 20, 30), lrate = c(0.05, 0.1, 0.2),
                                    nthread = 1, niter = 10))
opts
```

```
## $min
## $min$dim
## [1] 10
## 
## $min$cost
## [1] 0.1
## 
## $min$lrate
## [1] 0.05
## 
## 
## $res
##    dim cost lrate      rmse
## 1   10 0.01  0.05 0.9508706
## 2   20 0.01  0.05 0.9769276
## 3   30 0.01  0.05 0.9552881
## 4   10 0.10  0.05 0.9494486
## 5   20 0.10  0.05 0.9745281
## 6   30 0.10  0.05 0.9665343
## 7   10 0.01  0.10 1.0146531
## 8   20 0.01  0.10 1.0176182
## 9   30 0.01  0.10 1.0006795
## 10  10 0.10  0.10 0.9697273
## 11  20 0.10  0.10 0.9870130
## 12  30 0.10  0.10 0.9751481
## 13  10 0.01  0.20 1.1101094
## 14  20 0.01  0.20 1.0386463
## 15  30 0.01  0.20 1.0129634
## 16  10 0.10  0.20 1.0422394
## 17  20 0.10  0.20 1.0249771
## 18  30 0.10  0.20 1.0148717
```

```r
r$train(trainset, opts = c(opts$min, nthread = 1, niter = 10))
```

```
## iter   tr_rmse          obj
##    0    2.5987   6.9706e+04
##    1    1.8298   3.7380e+04
##    2    1.2323   2.0192e+04
##    3    0.9563   1.4674e+04
##    4    0.8542   1.3051e+04
##    5    0.8128   1.2467e+04
##    6    0.7926   1.2200e+04
##    7    0.7803   1.2033e+04
##    8    0.7725   1.1929e+04
##    9    0.7671   1.1863e+04
## real tr_rmse = 0.7411
```

```r
outfile = tempfile()
r$predict(testset, outfile)
```

```
## prediction output generated at /tmp/RtmpqxN3AV/file2043363dc41b
```

```r
## Compare the first few true values of testing data
## with predicted ones
# True values
print(read.table(testset, header = FALSE, sep = " ", nrows = 10)$V3)
```

```
##  [1] 3 4 2 3 3 4 3 3 3 3
```

```r
# Predicted values
print(scan(outfile, n = 10))
```

```
##  [1] 3.70478 3.02759 2.97616 3.46205 2.15736 3.03603 2.74433 2.96865
##  [9] 2.02960 3.24131
```

Detailed help document for each function is available in topics
`?recosystem::Reco`, `?recosystem::tune`, `?recosystem::train`,
`?recosystem::output` and `?recosystem::predict`.

### Installation Issue

`LIBMF` utilizes some compiler and CPU features that may be unavailable
in some systems. To build `recosystem` from source, one needs a C++
compiler that supports C++11 standard.

Also, there are some flags in file `src/Makevars` that may have influential
effect on performance. It is strongly suggested to set proper flags
according to your type of CPU before compiling the package, in order to
achieve the best performance:

1. The default `Makevars` provides generic options that should apply to most
CPUs.
2. If your CPU supports SSE3
([a list of supported CPUs](http://en.wikipedia.org/wiki/SSE3)), set
```
PKG_CPPFLAGS = -DUSESSE
PKG_CXXFLAGS = -msse3
```
3. If not only SSE3 is supported but also AVX
([a list of supported CPUs](http://en.wikipedia.org/wiki/Advanced_Vector_Extensions)), set
```
PKG_CPPFLAGS = -DUSEAVX
PKG_CXXFLAGS = -mavx
```

After editing the `Makevars` file, run `R CMD INSTALL recosystem` on
the package source directory to install `recosystem`.
