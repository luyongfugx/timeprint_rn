#pragma once
#include <string>
#include "des.h"
#ifdef __ANDROID__
#include <jni.h>
#endif
using namespace std;
#define SNOW_FLAKE_ID_LENGTH  19
enum {
    TIME_STAMP_SEC_TYPE_SECOND = 0,
    TIMES_TAMP_SEC_TYPE_MILLISECOND =  1
};

enum {
    VERSION_SNOW_FLAKE_ID = 0,
    VERSION_TIME_XY2 = 4,
    VERSION_TIME2 = 5,
    VERSION_TIME_XY = 6,
    VERSION_TIME = 7
};

class __attribute__((visibility("hidden"))) CodeData {
public:
    bool valid;
    uint64_t version;
    uint64_t timestampFormat;
    uint64_t timestamp;
    uint64_t reserved;
    uint64_t locationType;
    double longitude;
    double latitude;
};

class __attribute__((visibility("hidden"))) CodeGenerator {
public:
    CodeGenerator(uint32_t base, uint32_t digit);
    ~CodeGenerator();
    bool check(uint64_t version, uint64_t timestamp, double longitude, double latitude);
    bool check(uint64_t snowflakeId);
    string genCode(uint64_t version, uint64_t timestamp, bool ms, uint64_t locationType, int64_t reserved, bool enableLog = false);
    string genCode(uint64_t version, uint64_t timestamp, double longitude, double latitude, int64_t reserved, bool enableLog);
    string genCode(string code, bool enableLog = false);
    string genCode(uint64_t snowflakeId, bool enableLog = false);
    CodeData parseCode(string &codeStr, bool enableLog = false);
    uint64_t crypt(uint64_t code, uint32_t op);
#ifdef __ANDROID__
    void setEnv(JNIEnv *env);
#endif
#ifdef __APPLE__
    uint64_t crypt2(uint64_t code, uint32_t op);
#endif
private:
    uint64_t random(uint32_t bit);
    string reMapCode(string);
    uint32_t base_ = 24;
    uint32_t digit_ = 14;
    key_set* key_sets_;
#ifdef __ANDROID__
    JNIEnv *env_;
#endif
};
