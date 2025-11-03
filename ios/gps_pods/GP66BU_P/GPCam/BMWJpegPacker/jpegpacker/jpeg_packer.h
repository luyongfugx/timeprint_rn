#pragma once

#include <iostream>
#include <vector>
#include <math.h>
#include <stdio.h>
#include <iostream>
#include <string>
#include <fstream>
#include <errno.h>
#ifdef __ANDROID__
#include "../code/message_parser.h"
#else
#include "message_parser.h"
#endif

using namespace std;

#define BYTE unsigned char
#define PROTOCOL_HEADER_LENGTH 4
#define PROTOCOL_VERSION_LENGTH 4
#define PROTOCOL_RESERVE_LENGTH 16
#define DATA_START_LENGTH 2
#define DATA_TYPE_LENGTH 1
#define DATA_ID_LENGTH 4
#define DATA_RECT_LENGTH 16
#define DATA_SIZE_LENGTH 4
#define PROTOCOL_DATA_SIZE_LENGTH 4
#define PROTOCOL_END_LENGTH 4
#define PROTOCOL_SLICE_LENGTH (DATA_START_LENGTH + DATA_TYPE_LENGTH + DATA_ID_LENGTH + DATA_RECT_LENGTH + DATA_SIZE_LENGTH)
#define PLEN (PROTOCOL_HEADER_LENGTH + PROTOCOL_VERSION_LENGTH + PROTOCOL_RESERVE_LENGTH + DATA_START_LENGTH + DATA_TYPE_LENGTH + DATA_ID_LENGTH + DATA_RECT_LENGTH + DATA_SIZE_LENGTH + PROTOCOL_DATA_SIZE_LENGTH + PROTOCOL_END_LENGTH)
#define JPG_APPN_LENGTH 2
#define JPG_APPN_SIZE_LENGTH 2
#define JPG_APPN_SLICE_MAX_SIZE 65535
#define JPG_APPN_SLICE_IMAGE_MAX_SIZE (JPG_APPN_SLICE_MAX_SIZE - JPG_APPN_LENGTH - PLEN)

typedef enum {
    IMAGE_ENCODE_APP_N = 0,
    IMAGE_ENCODE_APPEND_END = 1
} IMAGE_ENCODE_POS;

typedef enum {
    SUC = 0,
    COMMON_ERROR = -100,
    FILE_OPEN_FAILED = -101,
    ENCODE_ERROR = -200,
    ENCODE_ERROR_CHECK_FIALED = -201,
    ENCODE_ERROR_CHECK_SIZE_ERR = -202,
    ENCODE_ERROR_CHECK_BIT_ERR  = -203,
    ENCODE_ERROR_SLICE_SIZE_TOO_BIG = -204,
    ENCODE_ERROR_FORMAT_NOT_JPG = -205,
    ENCODE_ERROR_ENCRYPT_FAILED = -206,
    ENCODE_ERROR_FILE_WRITE_FAILED = -207,
    ENCODE_ERROR_FILE_NOT_FOUND = -208,
    DECODE_ERROR = -300,
    DECODE_FORMAT_ERROR = -301,
    DECODE_ERROR_NOT_FOUND_SLICE_IMAGE = -302,
    DECODE_ERROR_OUT_OF_RANGE = -303,
    DECODE_ERROR_PROTOCOL_DATA_SIZE_ERR = -304,
    DECODE_ERROR_DECRYPT_FAILED = -305,
    FILE_MERGE_ERROR = -306,
    DECODE_ERROR_CREATE_DIRECTORY = -307,
    DECODE_ERROR_SAVE_FAILED = -308,
    DECODE_ERROR_CREATE_FILE = -309,
    DECODE_ERROR_CREATE_DIR = -310,
} IMAGE_ENCODE_ERROR;

class SliceDataInfo {
public:
    long type;
    long id;
    std::vector<char> data;
    // left/top/right/bottom
    std::vector<float> rect;
    std::string filePath;

    ~SliceDataInfo();
};

class JpegPackerImp {
public:
    JpegPackerImp(const char *workDir);
    ~JpegPackerImp();

    vector<int> getCanjpegDecode(vector <string> filePaths, vector <int> positions);

    int videoEncode(long version, const std::string &video_file_path, const std::vector<SliceDataInfo> &slices);
    int videoDecode(long &version, const std::string &video_file_path, const std::string &dstDir, std::vector<SliceDataInfo> &slices);
    int extractWatermarkedVideo(const std::string &video_file_path, const std::string &dst_file_path);
    
    int jpegEncode(IMAGE_ENCODE_POS position, long version, const char *filePath, vector <SliceDataInfo> &slices, std::vector<char> &packedData);
    int jpegEncode(IMAGE_ENCODE_POS position, long version, vector <char> &filedata, vector <SliceDataInfo> &slices, std::vector<char> &packedData);
    int jpegMerge(IMAGE_ENCODE_POS position, const char *packedDataPath, const char *filePath);

    int jpegDecode(IMAGE_ENCODE_POS position, long &version, const char *filePath, vector <SliceDataInfo> &slices);
    int jpegDecode(IMAGE_ENCODE_POS position, long &version, vector <char> &filedata, vector <SliceDataInfo> &slices);

private:
    string workDir_;
    MessageParser paeser_;
private:
    int encodeSliceimagebyAppend(long version, const char *filePath, vector <SliceDataInfo> &slices, vector<char> &packedData);
    int encodeSliceimagebyAppn(long version, const char *filePath, vector <SliceDataInfo> &slices, vector<char> &packedData);

    int encodeSliceimagebyAppend(long version, vector <char> &filedata, vector <SliceDataInfo> &slices, vector<char> &packedData);
    int encodeSliceimagebyAppn(long version, vector <char> &filedata, vector <SliceDataInfo> &slices, vector<char> &packedData);

    int decodebyAppend(long &version, vector <SliceDataInfo> &slices, vector <char> &filedata);
    int decodebyAppn(long &version, vector <SliceDataInfo> &slices, vector <char> &filedata);

    int jpegMergeAppend(const char *filePath, const char *packedDataPath);
    int jpegMergeAppn(const char *filePath, const char *packedDataPath);

    int isCanjpegDecode(string filePath, int positions);

    long _filesize(FILE *stream);
    int writeBinFile(const char* name,char* buf, long nSize);

    vector<BYTE> longTobyte(long num);
    void floatTobytes(float data, BYTE bytes[]);
    float bytesTofloat(BYTE bytes[]);

    int encrypt(SliceDataInfo slice, vector<BYTE> &data);
    int decrypt(vector<BYTE> data, SliceDataInfo& slice, long& sliceDataSize);
    
    bool createDirectoryRecursive(const std::string &path);
};
