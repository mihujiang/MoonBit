#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/// Read entire file into a heap-allocated string.
/// Caller (MoonBit runtime) is responsible for freeing the returned buffer.
char* moon_config_read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return strdup("");

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    if (size <= 0) {
        fclose(f);
        return strdup("");
    }
    rewind(f);

    char* buf = (char*)malloc(size + 1);
    if (!buf) {
        fclose(f);
        return strdup("");
    }
    size_t read = fread(buf, 1, (size_t)size, f);
    fclose(f);
    buf[read] = '\0';
    return buf;
}
