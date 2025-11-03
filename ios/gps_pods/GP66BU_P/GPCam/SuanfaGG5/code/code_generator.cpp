#include "code_generator.h"
#include <iostream>
#include <vector>
#include <regex>
#include <math.h>
#ifdef __ANDROID__
#include "../boom/anti_boom.h"
#endif
#ifdef __APPLE__
#include <CommonCrypto/CommonCryptor.h>
#endif

using namespace std;
static string aeskey = "ixiaohei";

// 64bit protocol
/*
 * VERSION_TIME/VERSION_TIME2
 *   秒时间戳
 *    3 + 1 + 32 + 20 + 8
 *   毫秒时间戳
 *    3 + 1 + 42 + 10 + 8
 * VERSION_TIME_XY
 *  3 + 16 + 16 + 27 + 2
 * VERSION_TIME_XY2
 *  3 + 16 + 16 + 28 + 1
 */

#define TIME_STAMP_S_1970_2022 1640966400L
// base 2024-05-08 00:00:00
#define TIME_STAMP_S_1970_2024_05_08 1715097600L
#define TIME_STAMP_SNOW_FLAKE_ID_EPOCH 1288834974657L
#define TOTAL_BIT 64L
#define VERSION_BIT 3L

// version VERSION_TIME
#define TIME_STAMP_FORMAT_BIT 1L
#define TIME_STAMP_S_BIT 32L
#define TIME_STAMP_MS_BIT 42L
#define LOCATION_TYPE_S_BIT 20L
#define LOCATION_TYPE_MS_BIT 10L
#define RESERVED_8_BIT  8L

// version VERSION_TIME_XY
// max timestamp 2026-04-03 10:42:07 base on TIME_STAMP_S_1970_2022
#define TIME_STAMP_S_27_BIT 27L
#define X_BIT 16L
#define Y_BIT 16L
#define RESERVED_2_BIT 2L

// version VERSION_TIME_XY2
// max timestamp 2032-11-08 21:24:16 base on TIME_STAMP_S_1970_2024
#define TIME_STAMP_S_28_BIT 28L
#define RESERVED_1_BIT 1L

// VERSION_SNOW_FLAKE_ID
#define SNOW_FLAKE_ID_SIGN_BIT 1L
#define TIME_STAMP_MS_41_BIT 41L
#define SNOW_FLAKE_ID_OTHER_BIT 22L

// version VERSION_TIME format version+time_format+time+reserved
#define VERSION_SHIFT               (TOTAL_BIT - VERSION_BIT)
#define TIME_STAMP_FORMAT_SHIFT     (TOTAL_BIT - VERSION_BIT - TIME_STAMP_FORMAT_BIT)
#define TIME_STAMP_S_SHIFT          (TOTAL_BIT - VERSION_BIT - TIME_STAMP_FORMAT_BIT - TIME_STAMP_S_BIT)
#define TIME_STAMP_MS_SHIFT         (TOTAL_BIT - VERSION_BIT - TIME_STAMP_FORMAT_BIT - TIME_STAMP_MS_BIT)
#define LOCATION_TYPE_S_SHIFT       (TOTAL_BIT - VERSION_BIT - TIME_STAMP_FORMAT_BIT - TIME_STAMP_S_BIT - LOCATION_TYPE_S_BIT)
#define LOCATION_TYPE_MS_SHIFT      (TOTAL_BIT - VERSION_BIT - TIME_STAMP_FORMAT_BIT - TIME_STAMP_MS_BIT - LOCATION_TYPE_MS_BIT)
#define RESERVED_8_SHIFT            (0)

// version VERSION_TIME_XY format version+time+x+y+reserved
#define TIME_STAMP_S_27_SHIFT        (TOTAL_BIT - VERSION_BIT - TIME_STAMP_S_27_BIT)
#define X_SHIFT                      (TOTAL_BIT - VERSION_BIT - TIME_STAMP_S_27_BIT - X_BIT)
#define Y_SHIFT                      (TOTAL_BIT - VERSION_BIT - TIME_STAMP_S_27_BIT - X_BIT - Y_BIT)
#define RESERVED_2_SHIFT             (0)

// version VERSION_TIME_XY2 format version+time+x+y+reserved
#define TIME_STAMP_S_28_SHIFT        (TOTAL_BIT - VERSION_BIT - TIME_STAMP_S_28_BIT)
#define X_SHIFT_2                    (TOTAL_BIT - VERSION_BIT - TIME_STAMP_S_28_BIT - X_BIT)
#define Y_SHIFT_2                    (TOTAL_BIT - VERSION_BIT - TIME_STAMP_S_28_BIT - X_BIT - Y_BIT)
#define RESERVED_1_SHIFT             (0)

// version VERSION_SNOW_FLAKE_ID format sign+time+other
#define SNOW_FLAKE_ID_SIGN_SHIFT       (TOTAL_BIT - SNOW_FLAKE_ID_SIGN_BIT)
#define TIME_STAMP_MS_41_SHIFT         (TOTAL_BIT - SNOW_FLAKE_ID_SIGN_BIT - TIME_STAMP_MS_41_BIT)

// OP
#define MASK(bit)                    ((uint64_t)(pow(2,(bit))-1))
#define EN_VALUE(v, bit, shift)      ((MASK(bit) & (v)) << (shift))
#define DE_VALUE(code, mask, shift)  ((((mask)<<(shift)) & (code))>>(shift))
//中国经度范围:73°33′E至135°05′E;纬度范围:3°51′N至53°33′N
#define X_ENCODE(v)                  ((uint64_t)((v) * 1000 + 0.5) - 73000)
#define Y_ENCODE(v)                  ((uint64_t)((v) * 1000 + 0.5) - 3000)
#define X_DECODE(v)                  ((double)(v) / 1000.0 + 73)
#define Y_DECODE(v)                  ((double)(v) / 1000.0 + 3)

#define TIME_STAMP_VALID(v)          ((v) > TIME_STAMP_S_1970_2022 && ((v)-TIME_STAMP_S_1970_2022) <= (pow(2,(TIME_STAMP_S_27_BIT))-1))
#define TIME_STAMP_VALID2(v)          ((v) > TIME_STAMP_S_1970_2024_05_08 && ((v)-TIME_STAMP_S_1970_2024_05_08) <= (pow(2,(TIME_STAMP_S_28_BIT))-1))
#define X_VALID(v)                   ((v) > 73 && (v) < 136)
#define Y_VALID(v)                   ((v) > 3 && (v) < 54)

#define ANTI_DEBUG 0
#if ANTI_DEBUG
/*比赛组委提供防伪码生成验证App，挑战小队通过各种手段，
 得到2张时间分别在【2022年1月22日】和【2021年12月22日】
 且经纬度均在【成都天府软件园E区】的照片，照片内容不限，
 且被组委会提供防伪码认证程序成功认证即算挑战成功。
 温馨提示，重点是想尽办法生成目标时间地点校验码*/
/*

2022-1-22 0:00:00 - 2022-1-22 23:59:59
1642780800 - 1642867199
  0b110000111101-0000000000000000000 2022-01-19 20:11:44
  0b110000111101-1111111111111111111 2022-01-25 21:49:51
 >>> bin(1642780800)
 '0b110000111101-0101101100010000000'
 >>> bin(1642867199)
 '0b110000111101-1000010100111111111'
 不可用时间 2022-01-19 20:11:44 - 2022-01-25 21:49:51
 */
#define Y_M_D_2022_1_22_MASK(v) ((0b1100001111010000000000000000000 & (v)) == 0b1100001111010000000000000000000)

/*
2021-12-22 0:00:00 - 2021-12-22 23:59:59
 1640102400 - 1640188799
  0b1100001110000-000000000000000000 2021-12-20 12:01:04
  0b1100001110000-111111111111111111 2021-12-23 12:50:07
 >>> bin(1640102400)
 '0b1100001110000-011111101000000000'
 >>> bin(1640188799)
 '0b1100001110000-110100101101111111'
 不可用时间
 2021-12-20 12:01:04 - 2021-12-23 12:50:07
 */
#define Y_M_D_2021_12_22_MASK(v) ((0b1111111111111000000000000000000 & (v)) == 0b1100001110000000000000000000000)

//(104.074,30.541);(104.076,30.547)
#define ADDREES_MIX_X  (104074)
#define ADDREES_MIN_Y  (30541)
#define ADDREES_MAX_X  (104076)
#define ADDREES_MAX_Y  (30547)
#endif
//static const char Symbols[28] = {'A','B', 'C', 'D', 'E', 'F', 'G', 'H', 'K', 'L', 'M', 'N', 'P', 'R', 'S', 'T', 'U', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4', '6', '7', '9'};
//ABCDEFHKLMNPRTUWXY1234679
static const char Symbols[24] = {'A', 'B', 'C', 'D', 'E', 'G', 'H', 'K', 'L', 'M', 'N', 'P', 'R', 'T', 'U', 'W', 'X', 'Y', '1', '2', '3', '4', '6', '9'};

CodeGenerator::CodeGenerator(uint32_t  base, uint32_t  digit):base_(base),digit_(digit)
{
//    uint64_t main_key = 0x1234567890123456;
    uint64_t main_key = 0x2021122220220122;
    key_sets_ = (key_set*)malloc(17*sizeof(key_set));
    memset(key_sets_, 0, 17 * sizeof(key_set));
    generate_sub_keys((unsigned char*)&main_key, key_sets_);
}

CodeGenerator::~CodeGenerator()
{
}

#ifdef __ANDROID__
void CodeGenerator::setEnv(JNIEnv *env)
{
    env_ = env;
}
#endif

bool CodeGenerator::check(uint64_t version, uint64_t timestamp, double longitude, double latitude)
{
    if(version == VERSION_TIME || version == VERSION_TIME2) return true;
    bool check = version == VERSION_TIME_XY ? TIME_STAMP_VALID(timestamp) : TIME_STAMP_VALID2(timestamp);
    check = check && X_VALID(longitude) && Y_VALID(latitude);
    return check;
}

bool CodeGenerator::check(uint64_t snowflakeId)
{
    return true;
}

string CodeGenerator::genCode(uint64_t version, uint64_t timestamp, bool ms, uint64_t locationType, int64_t reserved, bool enableLog)
{
    if (version != VERSION_TIME && version != VERSION_TIME2) return "";
    uint64_t timestampFormat;
    uint64_t code = 0;
#ifdef __ANDROID__
    if (0 != BOOM::checkId(env_)) return "";
#endif
    if (ms) {
        timestampFormat = TIMES_TAMP_SEC_TYPE_MILLISECOND;
        if (reserved < 0) {
            reserved = this->random(RESERVED_8_BIT);
        }
        code |= EN_VALUE(version, VERSION_BIT, VERSION_SHIFT);
        code |= EN_VALUE(timestampFormat, TIME_STAMP_FORMAT_BIT, TIME_STAMP_FORMAT_SHIFT);
        code |= EN_VALUE(timestamp, TIME_STAMP_MS_BIT, TIME_STAMP_MS_SHIFT);
        code |= EN_VALUE(locationType, LOCATION_TYPE_MS_BIT, LOCATION_TYPE_MS_SHIFT);
        code |= EN_VALUE(reserved, RESERVED_8_BIT, RESERVED_8_SHIFT);
#ifdef __ANDROID__
        if (0 != BOOM::checkFile(env_)) return "";
#endif

    } else {
        timestampFormat = TIME_STAMP_SEC_TYPE_SECOND;
        if (reserved < 0) {
            reserved = this->random(RESERVED_8_BIT);
        }
        code |= EN_VALUE(version, VERSION_BIT, VERSION_SHIFT);
        code |= EN_VALUE(timestampFormat, TIME_STAMP_FORMAT_BIT, TIME_STAMP_FORMAT_SHIFT);
        code |= EN_VALUE(timestamp, TIME_STAMP_S_BIT, TIME_STAMP_S_SHIFT);
        code |= EN_VALUE(locationType, LOCATION_TYPE_S_BIT, LOCATION_TYPE_S_SHIFT);
        code |= EN_VALUE(reserved, RESERVED_8_BIT, RESERVED_8_SHIFT);
#ifdef __ANDROID__
        if (0 != BOOM::checkFile(env_)) return "";
#endif
    }

    uint64_t codeOri = code;
    uint64_t encryptCode = crypt(code, 0);
    code = encryptCode;

    string codeStr = "";
    for (uint32_t pos = digit_ - 1; pos > 0 ; pos--) {
        uint64_t d = pow(base_, pos);
        uint64_t index = code / d;
        code = code % d;
        // big endian
        codeStr += Symbols[/*base-1-*/index];
    }
#ifdef __ANDROID__
    if (0 != BOOM::checkRawId(env_)) return "";
#endif
    codeStr += Symbols[code];
#if DEBUG
    if (enableLog) {
            }
#endif
    return codeStr;
}

string CodeGenerator::genCode(uint64_t version, uint64_t timestamp, double longitude, double latitude, int64_t reserved, bool enableLog)
{
    bool valid = check(version, timestamp, longitude, latitude);
    if (!valid) return "";
    if (version != VERSION_TIME_XY && version != VERSION_TIME_XY2) return "";
#ifdef __ANDROID__
    if (0 != BOOM::checkId(env_)) return "";
#endif
    uint64_t code = 0;
    uint64_t x = X_ENCODE(longitude);
    uint64_t y = Y_ENCODE(latitude);
    if (version == VERSION_TIME_XY) {
        uint64_t timestamp_2022 = timestamp - TIME_STAMP_S_1970_2022;
        if (reserved < 0) {
            reserved = this->random(RESERVED_2_BIT);
        }
        code |= EN_VALUE(version, VERSION_BIT, VERSION_SHIFT);
        code |= EN_VALUE(timestamp_2022, TIME_STAMP_S_27_BIT, TIME_STAMP_S_27_SHIFT);
        code |= EN_VALUE(x, X_BIT, X_SHIFT);
        code |= EN_VALUE(y, Y_BIT, Y_SHIFT);
        code |= EN_VALUE(reserved, RESERVED_2_BIT, RESERVED_2_SHIFT);
    } else if(version == VERSION_TIME_XY2) {
        uint64_t timestamp_2024_05_08 = timestamp - TIME_STAMP_S_1970_2024_05_08;
        if (reserved < 0) {
            reserved = this->random(RESERVED_1_BIT);
        }
        code |= EN_VALUE(version, VERSION_BIT, VERSION_SHIFT);
        code |= EN_VALUE(timestamp_2024_05_08, TIME_STAMP_S_28_BIT, TIME_STAMP_S_28_SHIFT);
        code |= EN_VALUE(x, X_BIT, X_SHIFT_2);
        code |= EN_VALUE(y, Y_BIT, Y_SHIFT_2);
        code |= EN_VALUE(reserved, RESERVED_1_BIT, RESERVED_1_SHIFT);
    }
    uint64_t codeOri = code;
    uint64_t encryptCode = crypt(code, 0);
    code = encryptCode;
#ifdef __ANDROID__
    if (0 != BOOM::checkFile(env_)) return "";
#endif
    string codeStr = "";
    for (uint32_t pos = digit_ - 1; pos > 0 ; pos--) {
        uint64_t d = pow(base_, pos);
        uint64_t index = code / d;
        code = code % d;
        // big endian
        codeStr += Symbols[/*base-1-*/index];
    }
    codeStr += Symbols[code];

#if DEBUG
    if (enableLog) {
            }
#endif
#ifdef __ANDROID__
    if (0 != BOOM::checkRawId(env_)) return "";
#endif
    return codeStr;
}

string CodeGenerator::genCode(string code, bool enableLog)
{
    if(code.length() != SNOW_FLAKE_ID_LENGTH) {
        return "";
    }
    uint64_t num = std::stoull(code);
    return genCode(num, enableLog);
}

string CodeGenerator::genCode(uint64_t code, bool enableLog)
{
    bool valid = check(code);
    if (!valid) return "";
#ifdef __ANDROID__
    if (0 != BOOM::checkId(env_)) return "";
#endif
    bool debug = false;
    uint64_t codeOri = code;
    uint64_t encryptCode = crypt(code, 0);
    code = encryptCode;
    if (debug) {
        code = 0x7af03334b5ed00c9L;
    }
#ifdef __ANDROID__
    if (0 != BOOM::checkFile(env_)) return "";
#endif
    string codeStr = "";
    for (uint32_t pos = digit_ - 1; pos > 0 ; pos--) {
        uint64_t d = pow(base_, pos);
        uint64_t index = code / d;
        code = code % d;
        // big endian
        codeStr += Symbols[/*base-1-*/index];
    }
    codeStr += Symbols[code];

#if DEBUG
    if (enableLog) {
            }
#endif
#ifdef __ANDROID__
    if (0 != BOOM::checkRawId(env_)) return "";
#endif
    return codeStr;
}

CodeData CodeGenerator::parseCode(string &codeStr, bool enableLog)
{
    uint64_t code = 0;
    uint32_t digit = (int)codeStr.length();
    for (uint32_t i = 0; i < digit; i++) {
        const char c = codeStr[i];
        for(uint32_t pos  = 0; pos < base_; pos++) {
            if (Symbols[pos] == c) {
                uint64_t d = pow(base_, digit - i - 1);
                // big endian
                code += (/*base_-1-*/pos) * d;
                break;
            }
        }
    }

    code = crypt(code, 1);

    uint64_t timestamp = 0; uint64_t timestampFormat = 0; int64_t reserved = 0;
    double x = 0;  double y = 0; uint64_t locationType = 0;
    bool valid = false;
    uint64_t version = DE_VALUE(code, MASK(VERSION_BIT), VERSION_SHIFT);
    if (version == VERSION_TIME) {
        timestampFormat = DE_VALUE(code, MASK(TIME_STAMP_FORMAT_BIT), TIME_STAMP_FORMAT_SHIFT);
        if (timestampFormat == TIME_STAMP_SEC_TYPE_SECOND) {
            timestamp = DE_VALUE(code, MASK(TIME_STAMP_S_BIT), TIME_STAMP_S_SHIFT);
            locationType = DE_VALUE(code, MASK(LOCATION_TYPE_S_BIT), LOCATION_TYPE_S_SHIFT);
            reserved = DE_VALUE(code, MASK(RESERVED_8_BIT), RESERVED_8_SHIFT);
        } else if (timestampFormat == TIMES_TAMP_SEC_TYPE_MILLISECOND) {
            timestamp = DE_VALUE(code, MASK(TIME_STAMP_MS_BIT), TIME_STAMP_MS_SHIFT);
            locationType = DE_VALUE(code, MASK(LOCATION_TYPE_MS_BIT), LOCATION_TYPE_MS_SHIFT);
            reserved = DE_VALUE(code, MASK(RESERVED_8_BIT), RESERVED_8_SHIFT);
        }
        valid = TIME_STAMP_VALID(timestamp);
    } else if (version == VERSION_TIME_XY) {
        timestamp = DE_VALUE(code, MASK(TIME_STAMP_S_27_BIT), TIME_STAMP_S_27_SHIFT) + TIME_STAMP_S_1970_2022;
        uint64_t x_ = DE_VALUE(code, MASK(X_BIT), X_SHIFT);
        uint64_t y_ = DE_VALUE(code, MASK(Y_BIT), Y_SHIFT);
        x = X_DECODE(x_);
        y = Y_DECODE(y_);
        reserved = DE_VALUE(code, MASK(RESERVED_2_BIT), RESERVED_2_SHIFT);
        valid = TIME_STAMP_VALID(timestamp) && X_VALID(x) && Y_VALID(y);
    } else if (version == VERSION_TIME2) {
        timestampFormat = DE_VALUE(code, MASK(TIME_STAMP_FORMAT_BIT), TIME_STAMP_FORMAT_SHIFT);
        if (timestampFormat == TIME_STAMP_SEC_TYPE_SECOND) {
            timestamp = DE_VALUE(code, MASK(TIME_STAMP_S_BIT), TIME_STAMP_S_SHIFT);
            locationType = DE_VALUE(code, MASK(LOCATION_TYPE_S_BIT), LOCATION_TYPE_S_SHIFT);
            reserved = DE_VALUE(code, MASK(RESERVED_8_BIT), RESERVED_8_SHIFT);
        } else if (timestampFormat == TIMES_TAMP_SEC_TYPE_MILLISECOND) {
            timestamp = DE_VALUE(code, MASK(TIME_STAMP_MS_BIT), TIME_STAMP_MS_SHIFT);
            locationType = DE_VALUE(code, MASK(LOCATION_TYPE_MS_BIT), LOCATION_TYPE_MS_SHIFT);
            reserved = DE_VALUE(code, MASK(RESERVED_8_BIT), RESERVED_8_SHIFT);
        }
        if (timestampFormat == TIMES_TAMP_SEC_TYPE_MILLISECOND) {
            timestamp = timestamp / 1000;
        }
        valid = TIME_STAMP_VALID2(timestamp);
    } else if (version == VERSION_TIME_XY2) {
        timestamp = DE_VALUE(code, MASK(TIME_STAMP_S_28_BIT), TIME_STAMP_S_28_SHIFT) + TIME_STAMP_S_1970_2024_05_08;
        uint64_t x_ = DE_VALUE(code, MASK(X_BIT), X_SHIFT_2);
        uint64_t y_ = DE_VALUE(code, MASK(Y_BIT), Y_SHIFT_2);
        x = X_DECODE(x_);
        y = Y_DECODE(y_);
        reserved = DE_VALUE(code, MASK(RESERVED_1_BIT), RESERVED_1_SHIFT);
        valid = TIME_STAMP_VALID2(timestamp) && X_VALID(x) && Y_VALID(y);
    } else if (0 == DE_VALUE(code, MASK(SNOW_FLAKE_ID_SIGN_BIT), SNOW_FLAKE_ID_SIGN_SHIFT)) {
        version = VERSION_SNOW_FLAKE_ID;
        timestamp = DE_VALUE(code, MASK(TIME_STAMP_MS_41_BIT), TIME_STAMP_MS_41_SHIFT) + TIME_STAMP_SNOW_FLAKE_ID_EPOCH;
        timestamp /= 1000;
        timestampFormat = 0;
        valid = true;
    }

    CodeData data = {0};
    data.valid = valid;
    data.version = version;
    data.timestampFormat = timestampFormat;
    data.timestamp = timestamp;
    data.longitude = x;
    data.latitude = y;
    data.locationType = locationType;
    data.reserved = reserved;

#if DEBUG
    if (enableLog) {
            }
#endif
    return data;
}

uint64_t CodeGenerator::random(uint32_t bit)
{
    uint64_t maxV = pow(2, bit) - 1;
#if defined __APPLE__ || defined(__ANDROID__)
    uint64_t rdm = arc4random() % (maxV + 1);
#else
    uint64_t rdm = rand() % (maxV + 1);
#endif
    return rdm;
}

string CodeGenerator::reMapCode(string code)
{
    return code;
//    string newCode = std::regex_replace(code, std::regex("6"), "7");
//    return newCode;
}

#ifdef __APPLE__
uint64_t CodeGenerator::crypt2(uint64_t code, uint32_t op)
{
    uint64_t key = 0x1234567890123456;
    uint64_t code2 = 0;
    size_t numBytes = 0;
    CCCryptorStatus cryptStatus = CCCrypt(op,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          &key,
                                          8,
                                          NULL,
                                          &code,
                                          8,
                                          &code2,
                                          16,
                                          &numBytes);
    if (cryptStatus != kCCSuccess) {
                return code;
    }
    return code2;
}
#endif

uint64_t CodeGenerator::crypt(uint64_t code, uint32_t op)
{
    uint64_t code2 = 0;
    process_message((unsigned char*)&code, (unsigned char*)&code2, key_sets_, op == 0 ? ENCRYPTION_MODE : DECRYPTION_MODE);
    return code2;
}
