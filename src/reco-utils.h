#ifndef RECO_UTILS_H
#define RECO_UTILS_H

#include <cstdlib>
#include <cstdint>
#include <Rcpp.h>

namespace Reco
{

// https://stackoverflow.com/questions/6563120/what-does-posix-memalign-memalign-do
inline void *malloc_aligned(size_t align, size_t len)
{
    // align == 0, or not a power of 2
    if(align == 0 || (align & (align - 1)))
        return (void *)0;

    // align is not a multiple of sizeof(void *)
    if(align % sizeof(void *))
        return (void *)0;

    // len + align - 1 to guarantee the length with alignment,
    // sizeof(size_t) to record the start position
    const size_t total = len + align - 1 + sizeof(size_t);
    char *data = (char *)malloc(total);

    if(data)
    {
        // the start location of "data"", used to free the memory
        const void * const start = (void *)data;
        // reserve space to store "start"
        data += sizeof(size_t);
        // find an integer greater than or equal to "data",
        // and is a multiple of "align"
        // the padding will be align - data % align
        size_t padding = align - (((size_t)data) % align);
        // move data to the aligned location
        data += padding;
        // location to write "start"
        size_t *recorder = (size_t *)(data - sizeof(size_t));
        // write "start" to recorder
        *recorder = (size_t)start;
    }

    return (void *)data;
}

inline void free_aligned(void *ptr)
{
    if(ptr)
    {
        char *data = (char *)ptr;
        size_t *recorder = (size_t *)(data - sizeof(size_t));
        data = (char *)(*recorder);
        free(data);
    }
}

// Used in random_shuffle()
inline int rand_less_than(int i)
{
    // Typically on Linux and MacOS, RAND_MAX == 2147483647
    // Windows has different definition, RAND_MAX == 32767
    // We manually set the limit to make sure that different OS are compatible
    std::int32_t rand_max = std::numeric_limits<std::int32_t>::max();
    std::int32_t r = std::int32_t(R::unif_rand() * rand_max);
    return int(r % i);
}

// On Mac, std::random_shuffle() uses a "backward" implementation,
// which leads to different results from Windows and Linux
// Therefore, we use a consistent implementation based on GCC
template <typename RandomAccessIterator, typename RandomNumberGenerator>
void random_shuffle(RandomAccessIterator first, RandomAccessIterator last, RandomNumberGenerator& gen)
{
    if(first == last)
        return;
    for(RandomAccessIterator i = first + 1; i != last; ++i)
    {
        RandomAccessIterator j = first + gen((i - first) + 1);
        if(i != j)
            std::iter_swap(i, j);
    }
}


} // namespace Reco


#endif // RECO_UTILS_H
