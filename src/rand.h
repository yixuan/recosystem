#include <Rcpp.h>

namespace Rand
{


// mimic the behaviour of a C version rand()
inline int rand(void)
{
    Rcpp::RNGScope scp;
    double res = R::unif_rand() * RAND_MAX;
    return (int)res;
}

// used in train.cpp => gen_map()
inline int rand_less_than(int i) { return Rand::rand() % i; }


} // namespace Rand
