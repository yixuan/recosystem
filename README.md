## Recommender system with Recosystem package

### About this package

`Recosystem` is an R wrapper of the `LIBMF` library developed by
Yu-Chin Juan, Yong Zhuang, Wei-Sheng Chin and Chih-Jen Lin
(http://www.csie.ntu.edu.tw/~cjlin/libmf/),
an open source library for recommender system using marix factorization.

A more detailed introduction can be found in the vignette of this package.

### A quick view of recommender system

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

### Features of LIBMF and Recosystem

`LIBMF` itself is a parallelized library, meaning that users can take
advantage of multicore CPUs to speed up the computation. It also utilizes 
some advanced CPU features to further improve the performance.

`Recosystem` is a complete wrapper of `LIBMF`, hence the features of `LIBMF`
are all included in `Recosystem`. Also, unlike most other R packages for
statistical modeling which store the whole dataset into memory,
`LIBMF` (and hence `Recosystem`) is much hard-disk-based. The dataset
is not loaded into memory at one time, but rather converted into a
temporary binary file. Similarly, the constructed model which contains
information for prediction is stored in the hard disk. Finally,
prediction result is also not in memory but written into a file.
That is to say, `Recosystem` will have a comparatively small memory usage.

### Usage of Recosystem

The usage of `Recosystem` is quite simple, mainly consisting of four steps:

1. Create a model object by calling `Reco()`.
2. Call methods `convert_train()` and `convert_test()` to convert data
files in text mode into binary form.
3. Train the model by calling `train()` method. A number of parameters
can be set inside the function.
4. Use the `predict()` method to compute predictions and write results
into hard disk.

Below is an example on some simulated data:


```r
library(Recosystem)
trainset = system.file("dat", "smalltrain.txt", package = "Recosystem")
testset = system.file("dat", "smalltest.txt", package = "Recosystem")
r = Reco()
r$convert_train(trainset)
```

```
## Converting...done.  0.01
## binary file generated at /tmp/Rtmpw21wCv/smalltrain.txt.bin
```

```r
r$convert_test(testset)
```

```
## Converting...done.  0.01
## binary file generated at /tmp/Rtmpw21wCv/smalltest.txt.bin
```

```r
r$train(opts = list(dim = 100, niter = 100,
                    cost.p = 0.001, cost.q = 0.001))
```

```
## Warning: AVX is enabled.
## Reading training data...done.  0.00
## Initializing model...done.  0.00
## iter       time
## 1          0.00
## 2          0.00
## 3          0.00
<output omitted>
## 98         0.03
## 99         0.03
## 100        0.03
## Writing model...done.  0.00
## model file generated at /tmp/Rtmpw21wCv/smalltrain.txt.bin.model
```

```r
print(r)
```

```
## >>> Training set >>>
## 
## number of users   = 1000
## number of items   = 1000
## number of ratings = 10000
## average           = 3.007000
## 
## >>> Testing set >>>
## 
## number of users   = 1000
## number of items   = 1000
## number of ratings = 10000
## average           = 3.005600
## 
## >>> Model >>>
## 
## number of users = 1000
## number of items = 1000
## dimensions      = 100
## lambda p        = 0.001000
## lambda q        = 0.001000
## lambda ub       = -1.000000
## lambda ib       = -1.000000
## gamma           = 0.001000
## average         = 0.000000
```

```r
outfile = tempfile()
r$predict(outfile)
```

```
## Predicting...done.  0.01
## RMSE: 0.991
## output file generated at /tmp/Rtmpw21wCv/file11037ac85e70
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
##  [1] 3.209904 3.012498 3.058191 3.496680 2.031080 3.241574 2.668896
##  [8] 2.811245 2.026762 3.457333
```

Detailed help document for each function is available in topics
`?Recosystem::Reco`, `?Recosystem::convert`, `?Recosystem::train`
and `?Recosystem::predict`.

### Installation issue

`LIBMF` utilizes some compiler and CPU features that may be unavailable
in some systems. Currently `Recosystem` mainly supports UNIX-like operating
systems, with experimental support for Windows
(See section **Precompiled packages**). To build `Recosystem`
from source, one needs a C++ compiler that supports C++11 standard.

Also, there are some flags in file `src/Makevars` that may have influential
effect on performance. It's strongly suggested to set proper flags
according to your type of CPU before compiling the package, in order to
achieve the best performance:

- If your CPU doesn't support SSE3 (typically very old CPUs), set
```
PKG_CXXFLAGS = -DNOSSE
```
in the `src/Makevars` file.
- If SSE3 is supported
([a list of supported CPUs](http://en.wikipedia.org/wiki/SSE3)), set
```
PKG_CXXFLAGS = -msse3
```
- If not only SSE3 is supported but also AVX
([a list of supported CPUs](http://en.wikipedia.org/wiki/Advanced_Vector_Extensions)), set
```
PKG_CXXFLAGS = -DUSEAVX -mavx
```

After editing the `Makevars` file, run `R CMD INSTALL Recosystem` on
the package source directory to install `Recosystem`.

### Precompiled packages

Below are the links for some precompiled binary packages for testing:
- [Recosystem 0.1 - Windows](https://bitbucket.org/yixuan/cn/downloads/Recosystem_0.1.zip)
- [Recosystem 0.1 - Ubuntu 14.04 (64-bit)](https://bitbucket.org/yixuan/cn/downloads/Recosystem_0.1_R_x86_64-pc-linux-gnu.tar.gz)
- [Recosystem 0.1 - Fedora 20 (64-bit)](https://bitbucket.org/yixuan/cn/downloads/Recosystem_0.1_R_x86_64-unknown-linux-gnu.tar.gz)

