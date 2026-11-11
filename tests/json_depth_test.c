/* cJSON's nesting limit (CMakeLists.txt): a value nested past 32 levels is refused rather than parsed with a frame of C
 * stack per level. A packet from another console and a file on the card are parsed on the console's 16 KB main task. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cJSON.h"

#define CHECK(c) do { if (!(c)) { fprintf(stderr, "json_depth: %s failed (line %d)\n", #c, __LINE__); exit(1); } } while (0)

static cJSON *nested(int n) { /* n arrays one inside the other */
    char s[256];
    memset(s, '[', (size_t)n), memset(s + n, ']', (size_t)n), s[2 * n] = 0;
    return cJSON_Parse(s);
}

int main(void) {
    cJSON *v = nested(32);
    CHECK(v);
    cJSON_Delete(v);
    CHECK(!nested(33));
    CHECK(!nested(100));
    puts("json_depth: ok");
    return 0;
}
