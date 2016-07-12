### IMPORTANT NOTES

> The API of this package has changed since version 0.4, due
> to the API change of LIBMF 2.01 and some other design improvement.

- The `cost` option in `$train()` and `$tune()` has been expanded to and replaced
  by `costp_l1`, `costp_l2`, `costq_l1`, and `costq_l2`, to allow for more
  flexibility of the model.
- A new `loss` parameter in `$train()` and `$tune()` to specify loss function.
- Data input and output are now managed in a unified way via functions
  `data_file()`, `data_memory()`, `out_file()`, `out_memory()`, and
  `out_nothing()`. See section **Data Input and Output** below.
- As a result, a number of arguments in functions `$tune()`, `$train()`,
  `$export()`, and `$predict()` now should be objects returned by these
  input/output functions.

## Recommender System with the recosystem Package

### About This Package

`recosystem` is an R wrapper of the `LIBMF` library developed by
Yu-Chin Juan, Wei-Sheng Chin, Yong Zhuang, Bo-Wen Yuan, Meng-Yuan Yang,
and Chih-Jen Lin (http://www.csie.ntu.edu.tw/~cjlin/libmf/),
an open source library for recommender system using parallel marix
factorization.

### Highlights of LIBMF and recosystem

`LIBMF` is a high-performance C++ library for large scale matrix factorization.
`LIBMF` itself is a parallelized library, meaning that
users can take advantage of multicore CPUs to speed up the computation.
It also utilizes some advanced CPU features to further improve the performance.

`recosystem` is a wrapper of `LIBMF`, hence it inherits most of the features
of `LIBMF`, and additionally provides a number of user-friendly R functions to
simplify data processing and model building. Also, unlike most other R packages
for statistical modeling that store the whole dataset and model object in
memory, `LIBMF` (and hence `recosystem`) can significantly reduce memory use,
for instance the constructed model that contains information for prediction
can be stored in the hard disk, and output result can also be directly
written into a file rather than be kept in memory.

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
to be predicted. In some other literatures, this problem may be named
collaborative filtering, matrix completion, matrix recovery, etc.

In `recosystem`, we provide convenient functions for model training, parameter
tuning, model exporting, and model prediction.

### Data Input and Output

Each step in the recommender system involves data input and output, as the
table below shows:

| Step             | Input             | Output                           |
|------------------|-------------------|----------------------------------|
| Model training   | Training data set | --                               |
| Parameter tuning | Training data set | --                               |
| Exporting model  | --                | User matrix `P`, item matrix `Q` |
| Prediction       | Testing data set  | Predicted values                 |

Data may have different formats and types of storage, for example the input
data set may be saved in a file or stored as R objects, and users may want
the output results to be directly written into file or to be returned as R
objects for further processing. In `recosystem`, we use two classes,
`DataSource` and `Output`, to handle data input and output in a unified way.

An object of class `DataSource` specifies the source of a data set (either
training or testing), which can be created by the following two functions:

- `data_file()`: Specifies a data set from a file in the hard disk
- `data_memory()`: Specifies a data set from R objects

And an object of class `Output` describes how the result should be output,
typically returned by the functions below:

- `out_file()`: Result should be saved to a file
- `out_memory()`: Result should be returned as R objects
- `out_nothing()`: Nothing should be output

More data source formats and output options may be supported in the future
along with the development of this package.

### Data Format

The data file for training set needs to be arranged in
sparse matrix triplet form, i.e., each line in the file contains three
numbers

```
user_index item_index rating
```

User index and item index may start with either 0 or 1, and this can be
specified by the `index1` parameter in `data_file()` and `data_memory()`.
For example, with `index1 = FALSE`, the training data file for the rating matrix
in the beginning of this article may look like

```
0 0 2
0 1 3
1 1 4
1 2 3
2 0 3
2 1 2
...
```

Testing data file is similar to training data, but since the ratings in
testing data are usually unknown, the `rating` entry in testing data file
can be omitted, or can be replaced by any placeholder such as `0` or `?`.

The testing data file for the same rating matrix would be

```
0 2
1 0
2 2
...
```

Example data files are contained in the `<recosystem>/dat`
(or `<recosystem>/inst/dat`, for source package) directory.

### Usage of recosystem

The usage of `recosystem` is quite simple, mainly consisting of the following steps:

1. Create a model object (a Reference Class object in R) by calling `Reco()`.
2. (Optionally) call the `$tune()` method to select best tuning parameters
along a set of candidate values.
3. Train the model by calling the `$train()` method. A number of parameters
can be set inside the function, possibly coming from the result of `$tune()`.
4. (Optionally) export the model via `$output()`, i.e. write the factorization matrices
`P` and `Q` into files or return them as R objects.
5. Use the `$predict()` method to compute predicted valeus.

Below is an example on some simulated data:

```r
library(recosystem)
set.seed(123) # This is a randomized algorithm
train_set = data_file(system.file("dat", "smalltrain.txt", package = "recosystem"))
test_set  = data_file(system.file("dat", "smalltest.txt",  package = "recosystem"))
r = Reco()
opts = r$tune(train_set, opts = list(dim = c(10, 20, 30), lrate = c(0.1, 0.2),
                                     costp_l1 = 0, costq_l1 = 0,
                                     nthread = 1, niter = 10))
opts
```

```
$min
$min$dim
[1] 20

$min$costp_l1
[1] 0

$min$costp_l2
[1] 0.1

$min$costq_l1
[1] 0

$min$costq_l2
[1] 0.01

$min$lrate
[1] 0.1

$min$rmse
[1] 0.9804937


$res
   dim costp_l1 costp_l2 costq_l1 costq_l2 lrate      rmse
1   10        0     0.01        0     0.01   0.1 0.9996368
2   20        0     0.01        0     0.01   0.1 1.0040111
3   30        0     0.01        0     0.01   0.1 0.9967101
4   10        0     0.10        0     0.01   0.1 0.9930384
5   20        0     0.10        0     0.01   0.1 0.9804937
6   30        0     0.10        0     0.01   0.1 0.9921565
7   10        0     0.01        0     0.10   0.1 0.9857116
8   20        0     0.01        0     0.10   0.1 1.0006225
9   30        0     0.01        0     0.10   0.1 0.9891277
10  10        0     0.10        0     0.10   0.1 0.9826748
11  20        0     0.10        0     0.10   0.1 0.9807865
12  30        0     0.10        0     0.10   0.1 0.9863404
13  10        0     0.01        0     0.01   0.2 1.1022376
14  20        0     0.01        0     0.01   0.2 1.0266608
15  30        0     0.01        0     0.01   0.2 1.0039170
16  10        0     0.10        0     0.01   0.2 1.0734307
17  20        0     0.10        0     0.01   0.2 1.0393326
18  30        0     0.10        0     0.01   0.2 1.0003177
19  10        0     0.01        0     0.10   0.2 1.0769594
20  20        0     0.01        0     0.10   0.2 1.0323938
21  30        0     0.01        0     0.10   0.2 1.0061849
22  10        0     0.10        0     0.10   0.2 1.0365456
23  20        0     0.10        0     0.10   0.2 1.0023265
24  30        0     0.10        0     0.10   0.2 1.0044131
```

```r
r$train(train_set, opts = c(opts$min, nthread = 1, niter = 10))
```

```
iter      tr_rmse          obj
   0       2.2673   5.3765e+04
   1       1.0267   1.3667e+04
   2       0.8372   1.0147e+04
   3       0.7977   9.4773e+03
   4       0.7703   9.0439e+03
   5       0.7402   8.5967e+03
   6       0.7048   8.1202e+03
   7       0.6609   7.5638e+03
   8       0.6133   7.0246e+03
   9       0.5614   6.4770e+03
```

```r
## Write predictions to file
pred_file = tempfile()
r$predict(test_set, out_file(pred_file))
print(scan(pred_file, n = 10))
```

```
 [1] 3.92323 3.05510 2.98484 3.42607 2.53514 2.88135 2.93226 3.11718 2.40406 3.46282
```

```r
## Or, directly return an R vector
pred_rvec = r$predict(test_set, out_memory())
head(pred_rvec, 10)
```

```
 [1] 3.923234 3.055096 2.984840 3.426066 2.535142 2.881347 2.932261 3.117176 2.404063
[10] 3.462822
```

Detailed help document for each function is available in topics
`?recosystem::Reco`, `?recosystem::tune`, `?recosystem::train`,
`?recosystem::export` and `?recosystem::predict`.

### Performance Improvement with Extra Installation Options

To build `recosystem` from source, one needs a C++ compiler that supports
the C++11 standard.

Also, there are some flags in file `src/Makevars`
(`src/Makevars.win` for Windows system) that may have influential
effect on performance. It is strongly suggested to set proper flags
according to your type of CPU before compiling the package, in order to
achieve the best performance:

1. The default `Makevars` provides generic options that should apply to most
CPUs.
2. If your CPU supports SSE3
([a list of supported CPUs](http://en.wikipedia.org/wiki/SSE3)), add
```
PKG_CPPFLAGS += -DUSESSE
PKG_CXXFLAGS += -msse3
```
3. If not only SSE3 is supported but also AVX
([a list of supported CPUs](http://en.wikipedia.org/wiki/Advanced_Vector_Extensions)), add
```
PKG_CPPFLAGS += -DUSEAVX
PKG_CXXFLAGS += -mavx
```

After editing the `Makevars` file, run `R CMD INSTALL recosystem` on
the package source directory to install `recosystem`.
