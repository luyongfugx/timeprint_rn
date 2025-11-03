#pragma once

#include "des.h"
#include <iostream>
#include <vector>
#include <math.h>

class __attribute__((visibility("hidden"))) MessageParser {
public:
    MessageParser();

    ~MessageParser();

    int parse(const char *inputPath, char **outputBuffer, unsigned long *size);
    int parseV2(const char *inputPath, char **outputBuffer, unsigned long *size);

    int crypt(const char *inputPath, const char *outputPath, uint32_t op);

    // outData need 8 byte align
    int crypt(const char *inputData, const size_t dataSize, const char *outData, uint32_t op);

    uint64_t crypt(uint64_t code, uint32_t op);

private:
    key_set *key_sets_;
};

