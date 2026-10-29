// @NAME@ (static_check template): three planted bugs for the `buggy` env (never built, only analysed).
// No system headers (see platformio.ini): malloc is declared here.
using size_t = decltype(sizeof 0);
extern "C" void *malloc(size_t size);

int out_of_bounds() {
    int table[4] = {0, 1, 2, 3};
    return table[4];                 // index 4 of a 4-element array
}

char *leak(size_t n) {
    char *buffer = static_cast<char *>(malloc(n));
    if (n > 16) return nullptr;      // buffer leaks on this path
    return buffer;
}

int use_uninitialised() {
    int value;
    return value + 1;                // value is never written
}
