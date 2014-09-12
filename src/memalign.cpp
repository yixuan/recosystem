// http://stackoverflow.com/questions/6563120/what-does-posix-memalign-memalign-do

#include <cstdlib>

namespace MemAlign
{

void *malloc_aligned(size_t align, size_t len)
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

void free_aligned(void *ptr)
{
    if(ptr)
    {
        char *data = (char *)ptr;
        size_t *recorder = (size_t *)(data - sizeof(size_t));
        data = (char *)(*recorder);
        free(data);
    }
}


} // namespace MemAlign
