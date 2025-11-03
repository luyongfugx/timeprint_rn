#include "jpeg_packer.h"
#ifdef __ANDROID__
#include "../JniUtils.h"
#define XLOGD XOSSLOGD
#define XLOGI XOSSLOGI
#define XLOGE XOSSLOGE
#else
#define XLOGD
#define XLOGI
#define XLOGE
#endif
#include <sys/stat.h>

SliceDataInfo::~SliceDataInfo() {
    XLOGI("JpegPacker", "~SliceDataInfo()");
    data.clear();
    rect.clear();
}

JpegPackerImp::JpegPackerImp(const char *workDir) : workDir_(workDir) {
}

JpegPackerImp::~JpegPackerImp() {
}

long JpegPackerImp::_filesize(FILE *stream) {
    long curpos, length;
    curpos = ftell(stream);
    fseek(stream, 0L, SEEK_END);
    length = ftell(stream);
    fseek(stream, curpos, SEEK_SET);
    return length;
}

int JpegPackerImp::writeBinFile(const char* name, char* buf, long nSize) {
    FILE *fp = fopen(name,"wb");
    if (fp == NULL) {
        XLOGE("JpegPacker", "File write failed：%s",name);
        return FILE_OPEN_FAILED;
    }
    fwrite(buf,nSize,1,fp);
    fclose(fp);
    return SUC;
}

vector<BYTE> JpegPackerImp::longTobyte(long num) {
    vector<BYTE> byte(4,(BYTE)0X00);
    long t = num;
    int32_t temp = 1;
    while (t > 0) {
        int32_t i = t%256;
        BYTE c = (BYTE)i;
        byte[4-temp] = c;
        t = t/256;
        temp++;
    }
    return byte;
}

void JpegPackerImp::floatTobytes(float data, BYTE bytes[]) {
    // 位操作时 使用一个unsigned int32_t变量来作为位容器。
    int32_t i;
    size_t length = sizeof(float);
    BYTE *pdata = (BYTE*)&data; //把float类型的指针强制转换为unsigned char型
    for (i = 0; i < length; i++) {
        bytes[i] = *pdata++;//把相应地址中的数据保存到unsigned char数组中
    }
    return;
}

float JpegPackerImp::bytesTofloat(BYTE* bytes) {
    // 位操作时 使用一个unsigned int变量来作为位容器。
    return *((float*)bytes);
}

int JpegPackerImp::jpegEncode(IMAGE_ENCODE_POS position, long version, const char *filePath, vector <SliceDataInfo> &slices, std::vector<char> &packedData){
    XLOGI("JpegPacker", "encode position: %d  image path: %s ", (int32_t)position, filePath);
    if (slices.size() <= 0) {
        XLOGE("JpegPacker", "slice image is NULL : %d", slices.size());
        return COMMON_ERROR;
    }
    int32_t r = 0;
    if (position == IMAGE_ENCODE_APPEND_END) {
        r = encodeSliceimagebyAppend(version, filePath, slices, packedData);

    } else if (position == IMAGE_ENCODE_APP_N) {
        r = encodeSliceimagebyAppn(version, filePath, slices, packedData);
    }
    return r;
}

int JpegPackerImp::jpegEncode(IMAGE_ENCODE_POS position, long version, vector <char> &filedata, vector <SliceDataInfo> &slices, std::vector<char> &packedData) {
    XLOGI("JpegPacker", "encode position: %d  filedatasize: %d", (int32_t)position, filedata.size());
    if (slices.size() <= 0) {
        XLOGE("JpegPacker", "slice image is NULL : %d", slices.size());
        return COMMON_ERROR;
    }
    int32_t r = 0;
    if (position == IMAGE_ENCODE_APPEND_END) {
        r = encodeSliceimagebyAppend(version, filedata, slices, packedData);

    } else if (position == IMAGE_ENCODE_APP_N) {
        r = encodeSliceimagebyAppn(version, filedata, slices, packedData);
    }
    return r;
}

int JpegPackerImp::videoEncode(long version, const std::string &video_file_path, const std::vector<SliceDataInfo> &slices) {
    {
        // get filedata_stream size
        std::ifstream filedata_stream(video_file_path, std::ios::binary);
        filedata_stream.seekg(0, std::ios::end);
        int32_t filedata_stream_size = filedata_stream.tellg();
            }

    // 初始化目标文件流
    std::ofstream filedata_stream;
    filedata_stream.open(video_file_path, std::ios::binary | std::ios::app);  // 以追加模式打开目标文件
    if (!filedata_stream.is_open()) {
        XLOGE("JpegPacker", "Failed to open output file: %s", video_file_path.c_str());
        return ENCODE_ERROR_FILE_WRITE_FAILED;
    }

    long protocol_data_size = slices.size() * PROTOCOL_SLICE_LENGTH;

    // 协议头 0X504B0102
    filedata_stream.put((BYTE)0X50);
    filedata_stream.put((BYTE)0X4B);
    filedata_stream.put((BYTE)0X01);
    filedata_stream.put((BYTE)0X02);

    // 版本 4字节
    vector<BYTE> version_byte(4, (BYTE)0X00);
    version_byte = longTobyte(version);
    for (int32_t j = 0; j < 4; ++j) {
        filedata_stream.put((BYTE)version_byte[j]);
    }

    // 预留位 16字节
    for (int32_t j = 0; j < 16; ++j) {
        filedata_stream.put((BYTE)0X00);
    }

    // 遍历所有切片并写入数据
    for (int32_t i = 0; i < slices.size(); i++) {
        std::ifstream file(slices[i].filePath, std::ios::binary);
        if (!file.is_open()) {
            XLOGE("JpegPacker", "Failed to open file: %s", slices[i].filePath.c_str());
            return ENCODE_ERROR_FILE_NOT_FOUND;
        }

        file.seekg(0, std::ios::end);
        int32_t sliceimagefilesize = file.tellg();  // 获取文件大小
        protocol_data_size += sliceimagefilesize;
        file.seekg(0, std::ios::beg);  // 移动回文件开头

        // 数据开始标志位 0XFF00
        filedata_stream.put((BYTE)0XFF);
        filedata_stream.put((BYTE)0X00);

        // 数据类型，1字节
        filedata_stream.put((BYTE)slices[i].type);

        if (version == 2) {
            vector<BYTE> encryptdata(24, (BYTE)0X00);
            int ret = encrypt(slices[i], encryptdata);
            if (ret == 0) {
                for (int j = 0; j < encryptdata.size(); j++) {
                    filedata_stream.put((BYTE)encryptdata[j]);
                }
            } else {
                return ENCODE_ERROR_ENCRYPT_FAILED;
            }
        } else {
            // 数据id, 4字节
            vector<BYTE> id_byte(4, (BYTE)0X00);
            id_byte = longTobyte(slices[i].id);
            for (int32_t j = 0; j < 4; ++j) {
                filedata_stream.put((BYTE)id_byte[j]);
            }

            // 坐标, 16字节
            if (slices[i].rect.size() > 0) {
                for (int32_t j = 0; j < slices[i].rect.size(); j++) {
                    BYTE coordinate_byte[4];
                    floatTobytes(slices[i].rect[j], coordinate_byte);
                    for (int32_t k = 0; k < 4; ++k) {
                        filedata_stream.put((BYTE)coordinate_byte[k]);
                    }
                }
            } else {
                for (int32_t j = 0; j < 16; ++j) {
                    filedata_stream.put((BYTE)0X00);
                }
            }

            // 数据长度，4字节
            vector<BYTE> size_byte = longTobyte(sliceimagefilesize);
            for (int32_t j = 0; j < 4; ++j) {
                filedata_stream.put((BYTE)size_byte[j]);
            }
        }

        // 将切片数据直接写入目标文件
        char buffer[1024];
        while (file.read(buffer, sizeof(buffer))) {
            filedata_stream.write(buffer, file.gcount());
        }
        if (file.gcount() > 0) {
            filedata_stream.write(buffer, file.gcount());
        }
        file.close();
    }

    // 数据长度，4字节
    vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
    for (int32_t j = 0; j < 4; ++j) {
        filedata_stream.put((BYTE)protocol_data_size_byte[j]);
    }

    // 协议尾 0X504B0304
    filedata_stream.put((BYTE)0X50);
    filedata_stream.put((BYTE)0X4B);
    filedata_stream.put((BYTE)0X03);
    filedata_stream.put((BYTE)0X04);

    // 关闭文件流
    filedata_stream.close();

    {
        // get filedata_stream size
        std::ifstream filedata_stream(video_file_path, std::ios::binary);
        filedata_stream.seekg(0, std::ios::end);
        int32_t filedata_stream_size = filedata_stream.tellg();
            }

    return SUC;
}

int JpegPackerImp::encodeSliceimagebyAppend(long version, const char *filePath, vector <SliceDataInfo> &slices, vector<char> &packedData) {
    int32_t sliceimagesize = 0;
    for (int32_t i=0; i<slices.size(); i++) {
        int32_t buffsize = slices[i].data.size();
        XLOGI("JpegPacker", "sliceimageinfo id：%d size:%d", slices[i].id, buffsize);
        sliceimagesize = sliceimagesize + buffsize;
    }
    long protocol_data_size = sliceimagesize + slices.size() * PROTOCOL_SLICE_LENGTH;
    sliceimagesize = PROTOCOL_HEADER_LENGTH + PROTOCOL_VERSION_LENGTH + PROTOCOL_RESERVE_LENGTH + PROTOCOL_DATA_SIZE_LENGTH + PROTOCOL_END_LENGTH + sliceimagesize + slices.size() * PROTOCOL_SLICE_LENGTH; //协议头尾8 + 所有图种文件大小 + 文件数 * 协议
    char *buff = (char *)malloc(sliceimagesize * sizeof(char));
    memset(buff, 0, sliceimagesize * sizeof(char));

    int32_t temp = 0;
    //协议头0X504B0102
    buff[temp++] = (BYTE)0X50;
    buff[temp++] = (BYTE)0X4B;
    buff[temp++] = (BYTE)0X01;
    buff[temp++] = (BYTE)0X02;

    //版本4字节
    vector<BYTE> version_byte(4,(BYTE)0X00);
    version_byte = longTobyte(version);
    for (int32_t j = 0; j < 4; ++j) {
        buff[temp++] = (BYTE)version_byte[j];
    }

    //预留位16字节
    for(int32_t j = 0; j < 16; ++j) {
        buff[temp++] = (BYTE)0X00;
    }

    for (int32_t i=0 ; i < slices.size() ; i++) {
        long sliceimagefilesize = slices[i].data.size();
        //数据开始标志位 0XFF00
        XLOGI("JpegPacker", "sliceimageinfo id：%d addr:%d sliceimagefilesize：%ld", slices[i].id, temp, sliceimagefilesize);
        buff[temp++] = (BYTE)0XFF;
        buff[temp++] = (BYTE)0X00;

        //数据类型，1字节
        buff[temp++] = (BYTE)slices[i].type;

        if (version == 2) {
            vector<BYTE> encryptdata(24,(BYTE)0X00);
            int ret = encrypt(slices[i], encryptdata);
            if (encryptdata.size() == 24 && ret == 0) {
                for (int j=0 ; j<encryptdata.size() ; j++) {
                    buff[temp++] = (BYTE)encryptdata[j];
                }
            } else {
                free(buff);
                buff = NULL;
                return ENCODE_ERROR_ENCRYPT_FAILED;
            }
        } else {
            //数据id,4字节
            vector<BYTE> id_byte(4,(BYTE)0X00);
            id_byte = longTobyte(slices[i].id);
            for (int32_t j = 0; j < 4; ++j) {
                buff[temp++] = (BYTE)id_byte[j];
            }

            //坐标,16字节
            if (slices[i].rect.size() > 0) {
                for (int32_t j=0 ; j < slices[i].rect.size() ; j++) {
                    BYTE coordinate_byte [4];
                    floatTobytes(slices[i].rect[j], coordinate_byte);
                    for (int32_t k = 0; k < 4; ++k) {
                        buff[temp++] = (BYTE)coordinate_byte[k];
                    }
                    XLOGI("JpegPacker", "slice image id:%d rect %d：%f %x-%x-%x-%x", slices[i].id, j, slices[i].rect[j], (BYTE)coordinate_byte[0], (BYTE)coordinate_byte[1], (BYTE)coordinate_byte[2], (BYTE)coordinate_byte[3]);
                }
            } else {
                for (int32_t j = 0; j < 16; ++j) {
                    buff[temp++] = (BYTE)0X00;
                }
            }

            //数据长度，4字节
            vector<BYTE> size_byte = longTobyte(sliceimagefilesize);
            for (int32_t j = 0; j < 4; ++j) {
                buff[temp++] = (BYTE)size_byte[j];
            }
        }

        for (int32_t j=0 ; j<sliceimagefilesize ; j++) {
            buff[temp++] = (BYTE)slices[i].data[j];
        }
    }

    //数据长度，4字节
    vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
    for (int32_t j = 0; j < 4; ++j) {
        buff[temp++] = (BYTE)protocol_data_size_byte[j];
    }

    //协议尾0X504B0304
    buff[temp++] = (BYTE)0X50;
    buff[temp++] = (BYTE)0X4B;
    buff[temp++] = (BYTE)0X03;
    buff[temp] = (BYTE)0X04;

    packedData.assign(buff,buff+sliceimagesize);

    FILE *fp;
    if ((fp=fopen(filePath, "ab")) == NULL){
        XLOGE("JpegPacker", "%s is open failed!", filePath);
        free(buff);
        buff = NULL;
        return FILE_OPEN_FAILED;
    }

    if (buff != NULL) {
        XLOGI("JpegPacker", "%s continuation addr：%d", filePath, sliceimagesize);
        fwrite(buff, sliceimagesize, 1, fp);
        free(buff);
        buff = NULL;
    }
    fclose(fp);

    return SUC;
}

int JpegPackerImp::encodeSliceimagebyAppend(long version, vector <char> &filedata, vector <SliceDataInfo> &slices, vector<char> &packedData) {

    vector <char> tmpdata;
    int32_t sliceimagesize = 0;
    for (int32_t i=0; i<slices.size(); i++) {
        int32_t buffsize = slices[i].data.size();
        XLOGI("JpegPacker", "sliceimageinfo id：%d size:%d", slices[i].id, buffsize);
        sliceimagesize = sliceimagesize + buffsize;
    }
    long protocol_data_size = sliceimagesize + slices.size() * PROTOCOL_SLICE_LENGTH;

    //协议头0X504B0102
    tmpdata.push_back((BYTE)0X50);
    tmpdata.push_back((BYTE)0X4B);
    tmpdata.push_back((BYTE)0X01);
    tmpdata.push_back((BYTE)0X02);

    //版本4字节
    vector<BYTE> version_byte(4,(BYTE)0X00);
    version_byte = longTobyte(version);
    for (int32_t j = 0; j < 4; ++j) {
        tmpdata.push_back((BYTE)version_byte[j]);
    }

    //预留位16字节
    for(int32_t j = 0; j < 16; ++j) {
        tmpdata.push_back((BYTE)0X00);
    }

    for (int32_t i=0 ; i < slices.size() ; i++) {
        long sliceimagefilesize = slices[i].data.size();
        //数据开始标志位 0XFF00
        XLOGI("JpegPacker", "sliceimageinfo id：%d", slices[i].id);
        tmpdata.push_back((BYTE)0XFF);
        tmpdata.push_back((BYTE)0X00);

        //数据类型，1字节
        tmpdata.push_back((BYTE)slices[i].type);

        if (version == 2) {
            vector<BYTE> encryptdata(24,(BYTE)0X00);
            int ret = encrypt(slices[i], encryptdata);
            if (ret == 0) {
                for (int j=0 ; j<encryptdata.size() ; j++) {
                    tmpdata.push_back((BYTE)encryptdata[j]);
                }
            } else {
                return ENCODE_ERROR_ENCRYPT_FAILED;
            }
        } else {
            //数据id,4字节
            vector<BYTE> id_byte(4,(BYTE)0X00);
            id_byte = longTobyte(slices[i].id);
            for (int32_t j = 0; j < 4; ++j) {
                tmpdata.push_back((BYTE)id_byte[j]);
            }

            //坐标,16字节
            XLOGI("JpegPacker", "encodeSliceimagebyAppend  rect");
            if (slices[i].rect.size() > 0) {
                for (int32_t j=0 ; j<slices[i].rect.size() ; j++) {
                    BYTE coordinate_byte [4];
                    floatTobytes(slices[i].rect[j], coordinate_byte);
                    for (int32_t k = 0 ; k < 4 ; ++k) {
                        tmpdata.push_back((BYTE)coordinate_byte[k]);
                    }
                    XLOGI("JpegPacker", "slice image id:%d rect %d：%f %x-%x-%x-%x", slices[i].id, j, slices[i].rect[j], (BYTE)coordinate_byte[0], (BYTE)coordinate_byte[1], (BYTE)coordinate_byte[2], (BYTE)coordinate_byte[3]);
                }
            } else {
                for (int32_t j = 0; j < 16; ++j) {
                    tmpdata.push_back((BYTE)0X00);
                }
            }

            //数据长度，4字节
            vector<BYTE> size_byte = longTobyte(sliceimagefilesize);
            for (int32_t j = 0; j < 4; ++j) {
                tmpdata.push_back((BYTE)size_byte[j]);
            }
        }

        for (int32_t j=0 ; j<sliceimagefilesize ; j++) {
            tmpdata.push_back((BYTE)slices[i].data[j]);
        }
    }

    //数据长度，4字节
    vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
    for (int32_t j = 0; j < 4; ++j) {
        tmpdata.push_back((BYTE)protocol_data_size_byte[j]);
    }

    //协议尾0X504B0304
    tmpdata.push_back((BYTE)0X50);
    tmpdata.push_back((BYTE)0X4B);
    tmpdata.push_back((BYTE)0X03);
    tmpdata.push_back((BYTE)0X04);

    for (char c : tmpdata){
        filedata.push_back(c);
        packedData.push_back(c);
    }

    return SUC;
}

int JpegPackerImp::encodeSliceimagebyAppn(long version, const char *filePath, vector <SliceDataInfo> &slices, vector<char> &packedData) {
    int32_t imagesize = 0;
    int32_t appn_slice = 0; //分片数,最大14, App2 -> E2-EF -> 239-252
    for (int32_t i=0; i<slices.size(); i++) {
        int32_t sliceimagesize = slices[i].data.size();
        XLOGI("JpegPacker", "sliceimageinfo id：%d size:%d", slices[i].id, sliceimagesize);
        appn_slice = appn_slice + (sliceimagesize % JPG_APPN_SLICE_IMAGE_MAX_SIZE > 0 ? sliceimagesize / JPG_APPN_SLICE_IMAGE_MAX_SIZE + 1 : sliceimagesize / JPG_APPN_SLICE_IMAGE_MAX_SIZE);
        imagesize += sliceimagesize;
    }

    char *inputFilebuff = NULL;
    long inputFilesize = 0;
    FILE *inputFilefp;
    if ((inputFilefp=fopen(filePath, "rb")) == NULL) {
        XLOGE("JpegPacker", "%s is open failed!", filePath);
        return FILE_OPEN_FAILED;
    }
    inputFilesize = _filesize(inputFilefp); //原文件size
    inputFilebuff = (char *)malloc(inputFilesize * sizeof(char));
    memset(inputFilebuff, 0, inputFilesize * sizeof(char));
    fread(inputFilebuff, inputFilesize, 1, inputFilefp);

    int32_t appnsstartbit = 0;
    int32_t errcode = 0;
    vector<BYTE> Appns = {0XE2, 0XE3, 0XE4, 0XE5, 0XE6, 0XE7, 0XE8, 0XE9, 0XEA, 0XEB, 0XEC, 0XED, 0XEE, 0XEF};

    if (inputFilesize < 4 ||
        (BYTE)inputFilebuff[0] != 0XFF ||
        (BYTE)inputFilebuff[1] != 0XD8 ) {
        XLOGE("JpegPacker", "encodeimage failed: %s is not jpg", filePath);
        errcode = ENCODE_ERROR_FORMAT_NOT_JPG;
    }
    for (int32_t i = appnsstartbit ; i<inputFilesize ; i++) {
        if ((BYTE)inputFilebuff[i] == 0XFF &&
            (BYTE)inputFilebuff[i+1] >= 0XE0 &&
            (BYTE)inputFilebuff[i+1] <= 0XEF) {
            for (int32_t j=0; j<Appns.size(); j++) {
                if ((BYTE)Appns[j] == (BYTE)inputFilebuff[i+1]) {
                    XLOGI("JpegPacker", "encodeimage inputFile is have appns：%x", (BYTE)inputFilebuff[i+1]);
                    Appns.erase(Appns.begin()+j);
                    int32_t appsize = (BYTE)inputFilebuff[i+2] * 256  + (BYTE)inputFilebuff[i+3];
                    i = i + 1 + appsize;
                }
            }
        } else if ((BYTE)inputFilebuff[i] == 0XFF &&
                   (BYTE)inputFilebuff[i+1] == 0XDB ) {
            appnsstartbit = i;
            break;
        }
    }

    free(inputFilebuff);
    inputFilebuff = NULL;

    long appnsMaxsize = Appns.size() * (JPG_APPN_SLICE_MAX_SIZE - JPG_APPN_SIZE_LENGTH - PLEN);
    if (imagesize > appnsMaxsize) {
        XLOGE("JpegPacker", "encodeimage failed: slice image is too big, size: %ld maxsize: %ld", imagesize, appnsMaxsize);
        errcode = ENCODE_ERROR_SLICE_SIZE_TOO_BIG;
    }
    if (appnsstartbit >= inputFilesize || appnsstartbit == 0) {
        XLOGE("JpegPacker", "encode failed: appnsstartbit = %d,  inputFilesize = %ld", appnsstartbit, inputFilesize);
        return ENCODE_ERROR;
    }
    if (errcode != 0) {
        return errcode;
    }

    imagesize = inputFilesize + imagesize + appn_slice * (PLEN + JPG_APPN_LENGTH + JPG_APPN_SIZE_LENGTH); //原图大小 + 所有图种文件大小 + 分片数 * (Appn标志位2 + 字节数2 + 协议55)
    char *buff = (char *)malloc(imagesize * sizeof(char));
    memset(buff, 0, imagesize * sizeof(char));

    int32_t appn_tab = 0;
    long buff_tab = 0;
    fseek(inputFilefp, 0, SEEK_SET);
    fread(buff, appnsstartbit, 1, inputFilefp);
    buff_tab = buff_tab + appnsstartbit;

    for (int32_t i=0 ; i < slices.size() ; i++) {
        long buffsize = slices[i].data.size();
        int32_t slice = buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE > 0 ? buffsize / JPG_APPN_SLICE_IMAGE_MAX_SIZE + 1 : buffsize / JPG_APPN_SLICE_IMAGE_MAX_SIZE;
        for (int32_t k=0 ; k<slice ; k++) {
            //Appn 标志位，2字节
            buff[buff_tab++] = (BYTE)0XFF;
            buff[buff_tab++] = (BYTE)Appns[appn_tab++];

            //Appn 数据长度，2字节
            if (k < slice-1) {
                buff[buff_tab++] = (BYTE)0XFF;
                buff[buff_tab++] = (BYTE)0XFF;
            } else {
                long slicesize = buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE + PLEN + JPG_APPN_LENGTH;
                vector<BYTE> slicesize_byte = longTobyte(slicesize);
                buff[buff_tab++] = slicesize_byte[2];
                buff[buff_tab++] = slicesize_byte[3];
            }

            //协议头0X504B0102
            buff[buff_tab++] = (BYTE)0X50;
            buff[buff_tab++] = (BYTE)0X4B;
            buff[buff_tab++] = (BYTE)0X01;
            buff[buff_tab++] = (BYTE)0X02;

            //版本4字节
            vector<BYTE> version_byte(4,(BYTE)0X00);
            version_byte = longTobyte(version);
            for (int32_t j = 0; j < 4; ++j) {
                buff[buff_tab++] = (BYTE)version_byte[j];
            }

            //预留16字节
            for (int32_t j = 0; j < 16; ++j) {
                buff[buff_tab++] = (BYTE)0X00;
            }

            //数据开始标志位 0XFF00
            buff[buff_tab++] = (BYTE)0XFF;
            buff[buff_tab++] = (BYTE)0X00;

            //数据类型，1字节
            buff[buff_tab++] = (BYTE)slices[i].type;

            //数据id,4字节
            vector<BYTE> id_byte = longTobyte(slices[i].id);
            for (int32_t j = 0; j < 4; ++j) {
                buff[buff_tab++] = (BYTE)id_byte[j];
            }

            XLOGI("JpegPacker", "encodeSliceimagebyAppn id：%d addr:%ld type：%d %x", slices[i].id, i, slices[i].type, (BYTE)slices[i].type);

            //坐标,16字节
            if (slices[i].rect.size() > 0) {
                for (int32_t j=0 ; j<slices[i].rect.size() ; j++) {
                    BYTE coordinate_byte [4];
                    floatTobytes(slices[i].rect[j], coordinate_byte);
                    for(int32_t k = 0; k < 4; ++k) {
                        buff[buff_tab++] = (BYTE)coordinate_byte[k];
                    }
                    XLOGI("JpegPacker", "slice image id:%d rect %d：%f %x-%x-%x-%x", slices[i].id, j, slices[i].rect[j], (BYTE)coordinate_byte[0], (BYTE)coordinate_byte[1], (BYTE)coordinate_byte[2], (BYTE)coordinate_byte[3]);
                }
            } else {
                for(int32_t j = 0; j < 16; ++j) {
                    buff[buff_tab++] = (BYTE)0X00;
                }
            }

            if (k < slice-1) {
                //数据长度，4字节
                long datalength = JPG_APPN_SLICE_IMAGE_MAX_SIZE;
                vector<BYTE> slicesize_byte = longTobyte(datalength);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = slicesize_byte[j];
                }
                //数据写入
                for (int32_t j= k * JPG_APPN_SLICE_IMAGE_MAX_SIZE ; j< (k + 1) * JPG_APPN_SLICE_IMAGE_MAX_SIZE ; j++) {
                    buff[buff_tab++] = slices[i].data[j];
                }
                //数据体长度4字节
                long protocol_data_size = JPG_APPN_SLICE_IMAGE_MAX_SIZE + PROTOCOL_SLICE_LENGTH;
                vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = protocol_data_size_byte[j];
                }
            } else {
                //数据长度，4字节
                long slicesize = buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE;
                vector<BYTE> slicesize_byte = longTobyte(slicesize);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = slicesize_byte[j];
                }
                //数据写入
                for (int32_t j = k * JPG_APPN_SLICE_IMAGE_MAX_SIZE; j< buffsize ; j++) {
                    buff[buff_tab++] = slices[i].data[j];
                }
                //数据体长度4字节
                long protocol_data_size = (buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE) + PROTOCOL_SLICE_LENGTH;
                vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = protocol_data_size_byte[j];
                }
            }

            //协议尾0X504B0304
            buff[buff_tab++] = (BYTE)0X50;
            buff[buff_tab++] = (BYTE)0X4B;
            buff[buff_tab++] = (BYTE)0X03;
            buff[buff_tab++] = (BYTE)0X04;
        }
    }

    //原图的数据写回
    fseek(inputFilefp, appnsstartbit, SEEK_SET);
    fread(buff+buff_tab, inputFilesize - appnsstartbit, 1, inputFilefp);
    fclose(inputFilefp);

    int32_t result = writeBinFile(filePath, buff, imagesize);
    if (result < 0) {
        XLOGE("JpegPacker", "encode image file writeback failed");
        free(buff);
        buff = NULL;
        return result;
    }

    free(buff);
    buff = NULL;
    return SUC;
}

int JpegPackerImp::encodeSliceimagebyAppn(long version, vector <char> &filedata, vector <SliceDataInfo> &slices, vector<char> &packedData) {
    int32_t imagesize = 0;
    int32_t appn_slice = 0; //分片数,最大14, App2 -> E2-EF -> 239-252
    for (int32_t i=0; i<slices.size(); i++) {
        int32_t sliceimagesize = slices[i].data.size();
        XLOGI("JpegPacker", "sliceimageinfo id：%d size:%d", slices[i].id, sliceimagesize);
        appn_slice = appn_slice + (sliceimagesize % JPG_APPN_SLICE_IMAGE_MAX_SIZE > 0 ? sliceimagesize / JPG_APPN_SLICE_IMAGE_MAX_SIZE + 1 : sliceimagesize / JPG_APPN_SLICE_IMAGE_MAX_SIZE);
        imagesize += sliceimagesize;
    }

    int32_t filesize = filedata.size();
    int32_t appnsstartbit = 0;
    int32_t errcode = 0;
    vector<BYTE> Appns = {0XE2, 0XE3, 0XE4, 0XE5, 0XE6, 0XE7, 0XE8, 0XE9, 0XEA, 0XEB, 0XEC, 0XED, 0XEE, 0XEF};

    if (filedata.size() < 4 ||
        (BYTE)filedata[0] != 0XFF ||
        (BYTE)filedata[1] != 0XD8 ) {
        errcode = ENCODE_ERROR_FORMAT_NOT_JPG;
    }
    for (int32_t i = appnsstartbit ; i<filesize ; i++) {
        if ((BYTE)filedata[i] == 0XFF &&
            (BYTE)filedata[i+1] >= 0XE0 &&
            (BYTE)filedata[i+1] <= 0XEF) {
            for (int32_t j=0; j<Appns.size(); j++) {
                if ((BYTE)Appns[j] == (BYTE)filedata[i+1]) {
                    XLOGI("JpegPacker", "encodeimage inputFile is have appns：%x", (BYTE)filedata[i+1]);
                    Appns.erase(Appns.begin()+j);
                    int32_t appsize = (BYTE)filedata[i+2] * 256  + (BYTE)filedata[i+3];
                    i = i + 1 + appsize;
                }
            }
        } else if ((BYTE)filedata[i] == 0XFF &&
                   (BYTE)filedata[i+1] == 0XDB ) {
            appnsstartbit = i;
            break;
        }
    }

    long appnsMaxsize = Appns.size() * (JPG_APPN_SLICE_MAX_SIZE - JPG_APPN_SIZE_LENGTH - PLEN);
    if (imagesize > appnsMaxsize) {
        XLOGE("JpegPacker", "encodeimage failed: slice image is too big, size: %ld maxsize: %ld", imagesize, appnsMaxsize);
        errcode = ENCODE_ERROR_SLICE_SIZE_TOO_BIG;
    }
    if (appnsstartbit >= filesize || appnsstartbit == 0) {
        XLOGE("JpegPacker", "encode failed: appnsstartbit = %d,  inputFilesize = %ld", appnsstartbit, filesize);
        errcode =  ENCODE_ERROR;
    }
    if (errcode != 0) {
        return errcode;
    }

    imagesize = filesize + imagesize + appn_slice * (PLEN + JPG_APPN_LENGTH + JPG_APPN_SIZE_LENGTH); //原图大小 + 所有图种文件大小 + 分片数 * (Appn标志位2 + 字节数2 + 协议55)
    char *buff = (char *)malloc(imagesize * sizeof(char));
    memset(buff, 0, imagesize * sizeof(char));

    for (int32_t i=0 ; i<appnsstartbit ; i++) {
        buff[i] = filedata[i];
    }

    int32_t appn_tab = 0;
    int32_t buff_tab = appnsstartbit;

    for (int32_t i=0 ; i < slices.size() ; i++) {
        long buffsize = slices[i].data.size();
        int32_t slice = buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE > 0 ? buffsize / JPG_APPN_SLICE_IMAGE_MAX_SIZE + 1 : buffsize / JPG_APPN_SLICE_IMAGE_MAX_SIZE;
        for (int32_t k=0 ; k<slice ; k++) {
            //Appn 标志位，2字节
            buff[buff_tab++] = (BYTE) 0XFF;
            buff[buff_tab++] = (BYTE) Appns[appn_tab++];

            //Appn 数据长度，2字节
            if (k < slice - 1) {
                buff[buff_tab++] = (BYTE) 0XFF;
                buff[buff_tab++] = (BYTE) 0XFF;
            } else {
                long slicesize = buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE + PLEN + JPG_APPN_LENGTH;
                vector<BYTE> slicesize_byte = longTobyte(slicesize);
                buff[buff_tab++] = slicesize_byte[2];
                buff[buff_tab++] = slicesize_byte[3];
            }

            //协议头0X504B0102
            buff[buff_tab++] = (BYTE) 0X50;
            buff[buff_tab++] = (BYTE) 0X4B;
            buff[buff_tab++] = (BYTE) 0X01;
            buff[buff_tab++] = (BYTE) 0X02;

            //版本4字节
            vector<BYTE> version_byte(4, (BYTE) 0X00);
            version_byte = longTobyte(version);
            for (int32_t j = 0; j < 4; ++j) {
                buff[buff_tab++] = (BYTE) version_byte[j];
            }

            //预留16字节
            for (int32_t j = 0; j < 16; ++j) {
                buff[buff_tab++] = (BYTE) 0X00;
            }

            //数据开始标志位 0XFF00
            buff[buff_tab++] = (BYTE) 0XFF;
            buff[buff_tab++] = (BYTE) 0X00;

            //数据类型，1字节
            buff[buff_tab++] = (BYTE) slices[i].type;

            //数据id,4字节
            vector<BYTE> id_byte = longTobyte(slices[i].id);
            for (int32_t j = 0; j < 4; ++j) {
                buff[buff_tab++] = (BYTE) id_byte[j];
            }

            XLOGI("JpegPacker", "encodeSliceimagebyAppn id：%d type：%d %x", slices[i].id, slices[i].type,
                  (BYTE) slices[i].type);

            //坐标,16字节
            if (slices[i].rect.size() > 0) {
                for (int32_t j = 0; j < slices[i].rect.size(); j++) {
                    BYTE coordinate_byte[4];
                    floatTobytes(slices[i].rect[j], coordinate_byte);
                    for (int32_t k = 0; k < 4; ++k) {
                        buff[buff_tab++] = (BYTE) coordinate_byte[k];
                    }
                    XLOGI("JpegPacker", "slice image id:%d rect %d：%f %x-%x-%x-%x", slices[i].id, j, slices[i].rect[j], (BYTE)coordinate_byte[0], (BYTE)coordinate_byte[1], (BYTE)coordinate_byte[2], (BYTE)coordinate_byte[3]);
                }
            } else {
                for (int32_t j = 0; j < 16; ++j) {
                    buff[buff_tab++] = (BYTE) 0X00;
                }
            }

            if (k < slice-1) {
                //数据长度，4字节
                long datalength = JPG_APPN_SLICE_IMAGE_MAX_SIZE;
                vector<BYTE> slicesize_byte = longTobyte(datalength);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = (BYTE)slicesize_byte[j];
                }
                //数据写入
                for (int32_t j= k * JPG_APPN_SLICE_IMAGE_MAX_SIZE ; j< (k + 1) * JPG_APPN_SLICE_IMAGE_MAX_SIZE ; j++) {
                    buff[buff_tab++] = (BYTE)slices[i].data[j];
                }
                //数据体长度4字节
                long protocol_data_size = JPG_APPN_SLICE_IMAGE_MAX_SIZE + PROTOCOL_SLICE_LENGTH;
                vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = (BYTE)protocol_data_size_byte[j];
                }
            } else {
                //数据长度，4字节
                long slicesize = buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE;
                vector<BYTE> slicesize_byte = longTobyte(slicesize);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = (BYTE)slicesize_byte[j];
                }
                //数据写入
                for (int32_t j = k * JPG_APPN_SLICE_IMAGE_MAX_SIZE; j< buffsize ; j++) {
                    buff[buff_tab++] = (BYTE)slices[i].data[j];
                }
                //数据体长度4字节
                long protocol_data_size = (buffsize % JPG_APPN_SLICE_IMAGE_MAX_SIZE) + PROTOCOL_SLICE_LENGTH;
                vector<BYTE> protocol_data_size_byte = longTobyte(protocol_data_size);
                for (int32_t j = 0; j < 4; ++j) {
                    buff[buff_tab++] = (BYTE)protocol_data_size_byte[j];
                }
            }

            //协议尾0X504B0304
            buff[buff_tab++] = (BYTE) 0X50;
            buff[buff_tab++] = (BYTE) 0X4B;
            buff[buff_tab++] = (BYTE) 0X03;
            buff[buff_tab++] = (BYTE) 0X04;
        }
    }
    for (int32_t i = appnsstartbit ; i < filedata.size() ; i++) {
        buff[buff_tab++] = filedata[i];
    }
    filedata.resize(imagesize);
    for (int32_t i=0 ; i<imagesize ; i++) {
        filedata[i] = buff[i];
    }
    free(buff);
    buff = NULL;
    return SUC;
}

int JpegPackerImp::jpegDecode(IMAGE_ENCODE_POS position, long &version, const char *filePath, vector <SliceDataInfo> &slices) {
    XLOGI("JpegPacker", "decode position: %d  image path: %s ", (int32_t)position, filePath);
    int32_t r = 0;
    FILE *fp;
    int32_t errnum = 0;
    if ((fp=fopen(filePath, "rb")) == NULL) {
        errnum = errno;
        XLOGI("JpegPacker", "open file failed errno = %d reason = %s", errnum, strerror(errnum));
        return FILE_OPEN_FAILED;
    }
    long buffsize = _filesize(fp);
    char *buff = (char *)malloc(buffsize*sizeof(char));
    memset(buff, 0, buffsize * sizeof(char));
    fread(buff, buffsize, 1, fp);
    fclose(fp);

    if (buffsize < 4 ||
        (BYTE)buff[0] != 0XFF ||
        (BYTE)buff[1] != 0XD8 ) {
        XLOGE("JpegPacker", "decode failed： %s is not jpg. 0-%x 1-%x", filePath, (BYTE)buff[0], (BYTE)buff[1]);
        free(buff);
        buff = NULL;
        return DECODE_FORMAT_ERROR;
    }

    vector<char> filedata(buff, buff+buffsize);
    XLOGI("JpegPacker", "decode image %x-%x-%x-%x %x-%x-%x-%x %x-%x-%x-%x %x-%x-%x-%x", (BYTE)filedata[0], (BYTE)filedata[1], (BYTE)filedata[2], (BYTE)filedata[3],
          (BYTE)filedata[4], (BYTE)filedata[5], (BYTE)filedata[6], (BYTE)filedata[7],(BYTE)filedata[8], (BYTE)filedata[9], (BYTE)filedata[10], (BYTE)filedata[11],(BYTE)filedata[12], (BYTE)filedata[13], (BYTE)filedata[14], (BYTE)filedata[15]);
    if (position == IMAGE_ENCODE_APPEND_END) {
        r = decodebyAppend(version, slices, filedata);

    } else if (position == IMAGE_ENCODE_APP_N) {
        r = decodebyAppn(version, slices, filedata);
    }
    free(buff);
    buff = NULL;
    return r;
}

int JpegPackerImp::jpegDecode(IMAGE_ENCODE_POS position, long &version, vector <char> &filedata, vector <SliceDataInfo> &slices) {
    XLOGI("JpegPacker", "decode position: %d  filedatasize: %d", (int32_t)position, filedata.size());
    if (filedata.size() < 4 ||
        (BYTE)filedata[0] != 0XFF ||
        (BYTE)filedata[1] != 0XD8 ) {
        XLOGE("JpegPacker", "decode failed： file is not jpg. 0-%x 1-%x", (BYTE)filedata[0], (BYTE)filedata[1]);
        return DECODE_FORMAT_ERROR;
    }

    int32_t r = 0;
    if (position == IMAGE_ENCODE_APPEND_END) {
        r = decodebyAppend(version, slices, filedata);

    } else if (position == IMAGE_ENCODE_APP_N) {
        r = decodebyAppn(version, slices, filedata);
    }
    return r;
}

bool JpegPackerImp::createDirectoryRecursive(const std::string &path) {
    // 检查路径是否已存在
    struct stat st;
    if (stat(path.c_str(), &st) == 0) {
        return true;  // 目录已经存在
    }

    // 如果父目录不存在，递归创建
    size_t pos = path.find_last_of("/\\");
    if (pos != std::string::npos) {
        if (!createDirectoryRecursive(path.substr(0, pos))) {
            return false;  // 如果父目录创建失败，则返回失败
        }
    }

    // 创建当前目录
    if (mkdir(path.c_str(), 0777) != 0) {
        std::cerr << "创建目录失败: " << strerror(errno) << std::endl;
        return false;
    }

    return true;
}

int JpegPackerImp::extractWatermarkedVideo(const std::string &video_file_path, const std::string &dst_file_path) {
    std::ifstream video_file(video_file_path, std::ios::binary);
    if (!video_file.is_open()) {
        XLOGE("JpegPacker", "Failed to open video file: %s", video_file_path.c_str());
        return FILE_OPEN_FAILED;
    }

    video_file.seekg(0, std::ios::end);
    long filedatasize = video_file.tellg();
    video_file.seekg(0, std::ios::beg);

    // 判断文件大小是否足够处理协议
    if (filedatasize < PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH) {
        XLOGE("JpegPacker", "File is too small to contain valid protocol data, size: %ld", filedatasize);
        return DECODE_FORMAT_ERROR;
    }

    char byte_buffer[1024];
    bool ishavesliceimageinfo = false;

    int read_size = PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH;
    video_file.seekg(-read_size, std::ios::end);
    video_file.read(byte_buffer, read_size);

    if (byte_buffer[read_size - 4] != 0X50 ||
        byte_buffer[read_size - 3] != 0X4B ||
        byte_buffer[read_size - 2] != 0X03 ||
        byte_buffer[read_size - 1] != 0X04) {
        XLOGE("JpegPacker", "File is not a valid protocol file");
        return DECODE_FORMAT_ERROR;
    }

    long protocol_data_size = (((BYTE)byte_buffer[read_size - 8]) << 24) + (((BYTE)byte_buffer[read_size - 7]) << 16) +
                                (((BYTE)byte_buffer[read_size - 6]) << 8) + ((BYTE)byte_buffer[read_size - 5]);
    if (protocol_data_size < 0) {
        XLOGE("JpegPacker", "Protocol data size is invalid: %ld", protocol_data_size);
        return DECODE_ERROR_PROTOCOL_DATA_SIZE_ERR;
    }

    int32_t protocol_start_bit = filedatasize - (PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH + protocol_data_size + PROTOCOL_RESERVE_LENGTH + PROTOCOL_VERSION_LENGTH) - 4;

    if (protocol_start_bit < 0) {
        XLOGE("JpegPacker", "decode err: data size too big, datasize:%d startbit:%d ", protocol_data_size, protocol_start_bit);
        return DECODE_ERROR_PROTOCOL_DATA_SIZE_ERR;
    }

    std::ofstream dst_file(dst_file_path, std::ios::binary);
    if (!dst_file.is_open()) {
        XLOGE("JpegPacker", "Failed to open destination file: %s", dst_file_path.c_str());
        return FILE_OPEN_FAILED;
    }

    const size_t buf_size = 1024;
    video_file.seekg(0, std::ios::beg);

    while (video_file.tellg() < protocol_start_bit) {
        long pos = video_file.tellg();
        long remain = protocol_start_bit - pos;
        std::streamsize to_read = static_cast<std::streamsize>(std::min<long>(buf_size, remain));
        video_file.read(byte_buffer, to_read);
        std::streamsize actually_read = video_file.gcount();
        if (actually_read <= 0) {
            break;
        }
        dst_file.write(byte_buffer, actually_read);
    }

    return SUC;
}

int JpegPackerImp::videoDecode(long &version, const std::string &video_file_path, const std::string &dstDir, std::vector<SliceDataInfo> &slices) {
    std::ifstream video_file(video_file_path, std::ios::binary);
    if (!video_file.is_open()) {
        XLOGE("JpegPacker", "Failed to open video file: %s", video_file_path.c_str());
        return FILE_OPEN_FAILED;
    }

    video_file.seekg(0, std::ios::end);
    long filedatasize = video_file.tellg();
    video_file.seekg(0, std::ios::beg);

    // 判断文件大小是否足够处理协议
    if (filedatasize < PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH) {
        XLOGE("JpegPacker", "File is too small to contain valid protocol data, size: %ld", filedatasize);
        return DECODE_FORMAT_ERROR;
    }

    std::string dst_dir = dstDir;

    if (!dst_dir.empty()) {
        if (!createDirectoryRecursive(dst_dir)) {
            XLOGE("JpegPacker", "Failed to create directory: %s", dst_dir.c_str());
            return DECODE_ERROR_CREATE_DIR;
        }
    } else {
        // 从video_file_path中提取目录和文件名
        dst_dir = video_file_path.substr(0, video_file_path.find_last_of("/"));
        if (dst_dir.empty()) {
            dst_dir = ".";
        }
    }
    std::string video_file_name = video_file_path.substr(video_file_path.find_last_of("/") + 1);

    // 定义缓冲区用于按块读取文件数据
    char byte_buffer[1024];
    char buffer[1024];
    bool ishavesliceimageinfo = false;

    int read_size = PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH;
    video_file.seekg(-read_size, std::ios::end);
    video_file.read(byte_buffer, read_size);

    if (byte_buffer[read_size - 4] != 0X50 ||
        byte_buffer[read_size - 3] != 0X4B ||
        byte_buffer[read_size - 2] != 0X03 ||
        byte_buffer[read_size - 1] != 0X04) {
        XLOGE("JpegPacker", "File is not a valid protocol file");
        return DECODE_FORMAT_ERROR;
    }

    long protocol_data_size = (((BYTE)byte_buffer[read_size - 8]) << 24) + (((BYTE)byte_buffer[read_size - 7]) << 16) +
                                (((BYTE)byte_buffer[read_size - 6]) << 8) + ((BYTE)byte_buffer[read_size - 5]);
    if (protocol_data_size < 0) {
        XLOGE("JpegPacker", "Protocol data size is invalid: %ld", protocol_data_size);
        return DECODE_ERROR_PROTOCOL_DATA_SIZE_ERR;
    }

    int32_t protocol_start_bit = filedatasize - (PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH + protocol_data_size + PROTOCOL_RESERVE_LENGTH + PROTOCOL_VERSION_LENGTH);

    if (protocol_start_bit < 0) {
        XLOGE("JpegPacker", "decode err: data size too big, datasize:%d startbit:%d ", protocol_data_size, protocol_start_bit);
        return DECODE_ERROR_PROTOCOL_DATA_SIZE_ERR;
    }

    XLOGI("JpegPacker", "decode video protocol_start_bit: %d ", protocol_start_bit);

    // 逐步处理视频文件数据
    video_file.seekg(protocol_start_bit, std::ios::beg);

    video_file.read(byte_buffer, PROTOCOL_RESERVE_LENGTH + PROTOCOL_VERSION_LENGTH);
    version = (((BYTE)byte_buffer[0]) << 24) + (((BYTE)byte_buffer[1]) << 16) + (((BYTE)byte_buffer[2]) << 8) + (BYTE)byte_buffer[3];
    long index = 0;

    while (true) {
        if (video_file.tellg() >= filedatasize - PROTOCOL_END_LENGTH - PROTOCOL_DATA_SIZE_LENGTH) {
            break;
        }

        video_file.read(byte_buffer, PROTOCOL_SLICE_LENGTH);
        if (byte_buffer[0] != 0xFF && byte_buffer[1] != 0x00) {
            break;
        }
        long sliceimagesize = 0;
        SliceDataInfo sliceimageinfo;
        sliceimageinfo.type = (BYTE)byte_buffer[2];
        if (version == 2) {
            std::vector<BYTE> data(byte_buffer + 3, byte_buffer + 27);
            int ret = decrypt(data, sliceimageinfo, sliceimagesize);
            XLOGI("JpegPacker", "decode sliceimageinfo id：%ld type:%ld sliceimagefilesize：%ld", sliceimageinfo.id, sliceimageinfo.type, sliceimagesize);
            if(sliceimagesize <= 0) {
                return DECODE_ERROR_DECRYPT_FAILED;
            }
        } else {
            sliceimageinfo.id = (((BYTE)byte_buffer[3]) << 24) + (((BYTE)byte_buffer[4]) << 16) + (((BYTE)byte_buffer[5]) << 8) + (BYTE)byte_buffer[6];
            for (int j = 0; j < 4; ++j) {
                BYTE byte[4] = {(BYTE)byte_buffer[7 + j * 4], (BYTE)byte_buffer[8 + j * 4],
                    (BYTE)byte_buffer[9 + j * 4], (BYTE)byte_buffer[10 + j * 4]};
                float rect = bytesTofloat(byte);
                sliceimageinfo.rect.push_back(rect);
            }
            sliceimagesize = (((BYTE)byte_buffer[23]) << 24) + (((BYTE)byte_buffer[24]) << 16) + (((BYTE)byte_buffer[25]) << 8) + (BYTE)byte_buffer[26];
        }
        std::string slice_file_path = dst_dir + "/nowatermark_slice_" + std::to_string(index++) + "_" + video_file_name;
        std::ofstream slice_file(slice_file_path, std::ios::binary);
        if (!slice_file.is_open()) {
            XLOGE("JpegPacker", "Failed to create slice file: %s", slice_file_path.c_str());
            return DECODE_ERROR_CREATE_FILE;
        }
        long read_bytes = 0;
        while (read_bytes < sliceimagesize) {
            int read_size = std::min((long)sizeof(buffer), sliceimagesize - read_bytes);
            video_file.read(buffer, read_size);

            int actual_read_size = video_file.gcount();

            if (actual_read_size <= 0) {
                break;
            }

            slice_file.write(buffer, actual_read_size);
            read_bytes += actual_read_size;
        }
        sliceimageinfo.filePath = slice_file_path;
        slice_file.close();
        slices.push_back(sliceimageinfo);
    }

    return SUC;
}

int JpegPackerImp::decodebyAppend(long &version, vector <SliceDataInfo> &slices, vector <char> &filedata){

    bool ishavesliceimageinfo = false;
    int32_t filedatasize = filedata.size();

    int32_t protocol_start_bit = 0;
    int32_t protocol_data_size = 0;

    if ((BYTE)filedata[filedatasize - 4] == 0X50 &&
        (BYTE)filedata[filedatasize - 3] == 0X4B &&
        (BYTE)filedata[filedatasize - 2] == 0X03 &&
        (BYTE)filedata[filedatasize - 1] == 0X04 &&
        (BYTE)filedata[filedatasize - 9] == 0XD9 &&
        (BYTE)filedata[filedatasize - 10] == 0XFF) {
        protocol_data_size = (BYTE)filedata[filedatasize - 8] * 256 * 256 * 256  + (BYTE)filedata[filedatasize - 7] * 256 * 256 + (BYTE)filedata[filedatasize - 6] * 256  + (BYTE)filedata[filedatasize - 5];
        protocol_start_bit = filedatasize - ( PROTOCOL_END_LENGTH + PROTOCOL_DATA_SIZE_LENGTH + protocol_data_size + PROTOCOL_RESERVE_LENGTH + PROTOCOL_VERSION_LENGTH + PROTOCOL_HEADER_LENGTH) - 1 - 2;
    } else {
        XLOGE("JpegPacker", "decode err: image size %d, not found slice image %x - %x", filedatasize, (BYTE)filedata[filedatasize - 2], (BYTE)filedata[filedatasize - 1]);
        return  DECODE_FORMAT_ERROR;
    }

    if (protocol_start_bit < 0) {
        XLOGE("JpegPacker", "decode err: data size too big,  datasize:%d  startbit:%d ", protocol_data_size, protocol_start_bit);
        return  DECODE_ERROR_PROTOCOL_DATA_SIZE_ERR;
    }

    XLOGI("JpegPacker", "decode image protocol_start_bit: %d ", protocol_start_bit);
    XLOGI("JpegPacker", "decode image ishavesliceimageinfo: %x-%x %x-%x-%x-%x %x-%x-%x-%x", (BYTE)filedata[protocol_start_bit], (BYTE)filedata[protocol_start_bit+1], (BYTE)filedata[protocol_start_bit+2], (BYTE)filedata[protocol_start_bit+3],
          (BYTE)filedata[protocol_start_bit+4], (BYTE)filedata[protocol_start_bit+5], (BYTE)filedata[filedatasize-4], (BYTE)filedata[filedatasize-3],(BYTE)filedata[filedatasize-2], (BYTE)filedata[filedatasize-1]);

    for (int32_t i = protocol_start_bit ; i< filedatasize - PLEN ; i++) {
        if ((BYTE)filedata[i+2] == 0X50 &&
            (BYTE)filedata[i+3] == 0X4B &&
            (BYTE)filedata[i+4] == 0X01 &&
            (BYTE)filedata[i+5] == 0X02 &&
            (BYTE)filedata[filedatasize-4]== 0X50 &&
            (BYTE)filedata[filedatasize-3] == 0X4B &&
            (BYTE)filedata[filedatasize-2] == 0X03 &&
            (BYTE)filedata[filedatasize-1] == 0X04) {

            ishavesliceimageinfo = true;
            version = (BYTE)filedata[i+6] * 256 * 256 * 256  + (BYTE)filedata[i+7] * 256 * 256 + (BYTE)filedata[i+8] * 256  + (BYTE)filedata[i+9];
            i = i + 5 + PROTOCOL_VERSION_LENGTH + PROTOCOL_RESERVE_LENGTH;
        }

        if (ishavesliceimageinfo && (BYTE)filedata[i] == 0XFF && (BYTE)filedata[i+1] == 0X00) {
            SliceDataInfo sliceimageinfo;
            sliceimageinfo.type = (BYTE)filedata[i+2];
            long sliceimagesize = 0;
            if (version == 2) {
                vector<char>::const_iterator first = filedata.begin() + i + 2 + 1;
                vector<char>::const_iterator last = filedata.begin() + i + 2 + 24 + 1;
                vector<BYTE> data(first, last);
                int ret = decrypt(data, sliceimageinfo, sliceimagesize);
                XLOGI("JpegPacker", "decode sliceimageinfo id：%ld type:%ld sliceimagefilesize：%ld", sliceimageinfo.id, sliceimageinfo.type, sliceimagesize);
                if(sliceimagesize <= 0) {
                    return DECODE_ERROR_DECRYPT_FAILED;
                }
            } else {
                sliceimageinfo.id = (BYTE)filedata[i+3] * 256 * 256 * 256  + (BYTE)filedata[i+4] * 256 * 256 + (BYTE)filedata[i+5] * 256  + (BYTE)filedata[i+6];
                for (int32_t j=0 ; j<4 ; j++) {
                    BYTE byte[4] = {(BYTE)filedata[i+7+4*j], (BYTE)filedata[i+8+4*j], (BYTE)filedata[i+9+4*j], (BYTE)filedata[i+10+4*j]};
                    XLOGI("JpegPacker", "rect. %x - %x - %x - %x ", (BYTE)filedata[i+7+4*j], (BYTE)filedata[i+8+4*j], (BYTE)filedata[i+9+4*j], (BYTE)filedata[i+10+4*j]);
                    XLOGI("JpegPacker", "rect. %f ", bytesTofloat(byte));
                    sliceimageinfo.rect.push_back(bytesTofloat(byte));
                }
                sliceimagesize  = (BYTE)filedata[i+23] * 256 * 256 * 256  + (BYTE)filedata[i+24] * 256 * 256 + (BYTE)filedata[i+25] * 256  + (BYTE)filedata[i+26];
            }

            XLOGI("JpegPacker", "decodebyappend liceimageinfo id：%d size: %d addr: %ld", sliceimageinfo.id, sliceimagesize, i);
            if (i + PROTOCOL_SLICE_LENGTH + sliceimagesize >= filedatasize || i + PROTOCOL_SLICE_LENGTH + sliceimagesize < 0) {
                return DECODE_ERROR_OUT_OF_RANGE;
            }

            vector<char> sliceimagedata(filedata.begin() + i + PROTOCOL_SLICE_LENGTH, filedata.begin() + i + PROTOCOL_SLICE_LENGTH + sliceimagesize);
            sliceimageinfo.data = sliceimagedata;
            slices.push_back(sliceimageinfo);
            i = i + DATA_START_LENGTH + DATA_TYPE_LENGTH + DATA_ID_LENGTH + DATA_RECT_LENGTH + DATA_SIZE_LENGTH + sliceimagesize - 1;
        }
    }

    if (ishavesliceimageinfo == false){
        XLOGE("JpegPacker", "decode err: not found slice image");
        slices.clear();
        return DECODE_ERROR_NOT_FOUND_SLICE_IMAGE;
    }
    return SUC;
}

int JpegPackerImp::decodebyAppn(long &version, vector <SliceDataInfo> &slices, vector <char> &filedata) {
    bool isneeddecode = false;
    bool ishavesliceimageinfo = false;
    long id = -1;//标记id，用来判断是否和前一个分片为同一文件
    int32_t filedatasize = filedata.size();

    //前2字节固定，直接跳过
    for (int32_t i=2; i < filedatasize-PLEN; i++) {
        if ((BYTE)filedata[i] == 0XFF &&
            (BYTE)filedata[i+1] >= 0XE2 &&
            (BYTE)filedata[i+1] <= 0XEF &&
            (BYTE)filedata[i+4] == 0X50 &&
            (BYTE)filedata[i+5] == 0X4B &&
            (BYTE)filedata[i+6] == 0X01 &&
            (BYTE)filedata[i+7] == 0X02) {

            ishavesliceimageinfo = true;
            isneeddecode = true;
            version = (BYTE)filedata[i+8] * 256 * 256 * 256  + (BYTE)filedata[i+9] * 256 * 256 + (BYTE)filedata[i+10] * 256  + (BYTE)filedata[i+11];
            i = i + 7 + PROTOCOL_VERSION_LENGTH + PROTOCOL_RESERVE_LENGTH;

        } else if ((BYTE)filedata[i] == 0XFF &&
                   (BYTE)filedata[i+1] >= 0XE0 &&
                   (BYTE)filedata[i+1] <= 0XEF) {
            long appnsize = (BYTE)filedata[i+2] * 256  + (BYTE)filedata[i+3];
            i = i + 1 + appnsize;
        } else if(isneeddecode &&
                  (BYTE)filedata[i] == 0XFF &&
                  (BYTE)filedata[i+1] == 0X00) {
            long sliceimageid = (BYTE)filedata[i+3] * 256 * 256 * 256  + (BYTE)filedata[i+4] * 256 * 256 + (BYTE)filedata[i+5] * 256  + (BYTE)filedata[i+6];
            if (sliceimageid == id && slices.size() >0) {
                //文件续写
                if (slices[slices.size()-1].data.size() <=0 ) {
                    XLOGE("JpegPacker", "file renew failed，id：", slices[slices.size()-1].id);
                    slices.clear();
                    return DECODE_ERROR;
                }
                long appn_image_size = (BYTE)filedata[i+23] * 256 * 256 * 256 + (BYTE)filedata[i+24] * 256 * 256 + (BYTE)filedata[i+25] * 256 + (BYTE)filedata[i+26];
                for (int32_t j=0 ; j<appn_image_size ; j++) {
                    slices[slices.size()-1].data.push_back(filedata[i + PROTOCOL_SLICE_LENGTH + j]);
                }
                i = i + PROTOCOL_SLICE_LENGTH + appn_image_size + PROTOCOL_DATA_SIZE_LENGTH + PROTOCOL_END_LENGTH - 1;
            } else {
                SliceDataInfo sliceimageinfo;
                sliceimageinfo.type = (BYTE)filedata[i+2];
                sliceimageinfo.id = sliceimageid;
                for (int32_t j=0 ; j<4 ; j++) {
                    BYTE byte[4] = {(BYTE)filedata[i+7+4*j], (BYTE)filedata[i+8+4*j], (BYTE)filedata[i+9+4*j], (BYTE)filedata[i+10+4*j]};
                    sliceimageinfo.rect.push_back(bytesTofloat(byte));
                }
                long appn_image_size = (BYTE)filedata[i+23] * 256 * 256 * 256  + (BYTE)filedata[i+24] * 256 * 256 + (BYTE)filedata[i+25] * 256  + (BYTE)filedata[i+26];
                XLOGI("JpegPacker", "decodebyAppn liceimageinfo id：%d size: %d addr: %ld", sliceimageinfo.id, appn_image_size, i);
                if (i + PROTOCOL_SLICE_LENGTH + appn_image_size >= filedatasize || i + PROTOCOL_SLICE_LENGTH + appn_image_size < 0) {
                    slices.clear();
                    return DECODE_ERROR_OUT_OF_RANGE;
                }
                vector<char> sliceimagedata(filedata.begin() + i + PROTOCOL_SLICE_LENGTH, filedata.begin() + i + PROTOCOL_SLICE_LENGTH + appn_image_size);
                sliceimageinfo.data = sliceimagedata;
                slices.push_back(sliceimageinfo);
                id = sliceimageinfo.id;
                i = i + PROTOCOL_SLICE_LENGTH + appn_image_size + PROTOCOL_DATA_SIZE_LENGTH + PROTOCOL_END_LENGTH - 1;
            }
            isneeddecode = false;
        } else if ((BYTE)filedata[i] == 0XFF &&
                   (BYTE)filedata[i+1] == 0XDB) {
            XLOGI("JpegPacker", "decodebyAppn finish addr：%ld", i);
            for (int32_t j=0 ; j<slices.size(); j++) {
                XLOGI("JpegPacker", "decodebyAppn id:%d size：%ld", slices[j].id, slices[j].data.size());
            }
            break;
        }
    }

    if (ishavesliceimageinfo == false){
        XLOGE("JpegPacker", "decode err: not found slice image");
        slices.clear();
        return DECODE_ERROR_NOT_FOUND_SLICE_IMAGE;
    }
    return SUC;
}

int JpegPackerImp::jpegMerge(IMAGE_ENCODE_POS position, const char *packedDataPath, const char *filePath) {
    XLOGI("JpegPacker", "jpegMerge position: %d  filePath: %s, packedDataPath: %s", (int32_t)position, filePath, packedDataPath);
    int32_t r = 0;
    if (position == IMAGE_ENCODE_APPEND_END) {
        r = jpegMergeAppend(filePath, packedDataPath);

    } else if (position == IMAGE_ENCODE_APP_N) {
        r = jpegMergeAppn(filePath, packedDataPath);
    }
    return r;
}

int JpegPackerImp::jpegMergeAppend(const char *filePath, const char *packedDataPath){
    std::ifstream packedDataStream(packedDataPath, std::ios::binary);
    if (!packedDataStream) {
        XLOGE("JpegPacker", "could not open file: %s", packedDataPath);
        return FILE_MERGE_ERROR;
    }

    std::ofstream fileStream(filePath, std::ios::binary | std::ios::app);
    if (!fileStream) {
        XLOGE("JpegPacker", "could not open file: %s", filePath);
        return FILE_MERGE_ERROR;
    }

    char buffer[4096];
    while (packedDataStream.read(buffer, sizeof(buffer)) || packedDataStream.gcount() > 0) {
        fileStream.write(buffer, packedDataStream.gcount());
        if (!fileStream) {
            XLOGE("JpegPacker", "Error writing file: %s", filePath);
            return FILE_MERGE_ERROR;
        }
    }

    if (!packedDataStream.eof()) {
        XLOGE("JpegPacker", "Error reading file: %s", packedDataPath);
        return FILE_MERGE_ERROR;
    }

    return SUC;
}

int JpegPackerImp::jpegMergeAppn(const char *filePath, const char *packedDataPath){
    return SUC;
}

int JpegPackerImp::isCanjpegDecode(string filePath, int positions) {
    int res = 0;
    FILE *fp;
    if ((fp=fopen(filePath.c_str(), "rb")) == NULL) {
        XLOGE("JpegPacker", "isCanjpegDecode filePath %s open  fail", filePath.c_str());
        res = 0;
        return res;
    }
    long buffsize = _filesize(fp);
    XLOGI("JpegPacker", "isCanjpegDecode... %s %ld", filePath.c_str(), buffsize);
    char *buff = (char *)malloc(buffsize*sizeof(char));
    memset(buff, 0, buffsize * sizeof(char));
    fread(buff, buffsize, 1, fp);
    fclose(fp);
    if (buffsize < 4 ||
        (BYTE)buff[0] != 0XFF ||
        (BYTE)buff[1] != 0XD8 ) {
        free(buff);
        buff = NULL;
        res = 0;
        return res;
    }
    if (positions == IMAGE_ENCODE_APPEND_END) {
        if ((BYTE)buff[buffsize - 4] != 0X50 ||
            (BYTE)buff[buffsize - 3] != 0X4B ||
            (BYTE)buff[buffsize - 2] != 0X03 ||
            (BYTE)buff[buffsize - 1] != 0X04 ||
            (BYTE)buff[buffsize - 9] != 0XD9 ||
            (BYTE)buff[buffsize - 10] != 0XFF) {
            free(buff);
            buff = NULL;
            res = 0;
            XLOGI("JpegPacker", "isCanjpegDecode... %s is not encode", filePath.c_str());
        } else {
            res = 1;
            free(buff);
            buff = NULL;
        }
    } else if (positions == IMAGE_ENCODE_APP_N) {
        bool isConfirm = false;
        for (int32_t i=2; i < buffsize-PLEN; i++) {
            if ((BYTE)buff[i] == 0XFF &&
                (BYTE)buff[i+1] >= 0XE2 &&
                (BYTE)buff[i+1] <= 0XEF &&
                (BYTE)buff[i+4] == 0X50 &&
                (BYTE)buff[i+5] == 0X4B &&
                (BYTE)buff[i+6] == 0X01 &&
                (BYTE)buff[i+7] == 0X02) {
                res = 1;
                free(buff);
                buff = NULL;
                isConfirm = true;
                break;
            } else if ((BYTE)buff[i] == 0XFF &&
                       (BYTE)buff[i+1] >= 0XE0 &&
                       (BYTE)buff[i+1] <= 0XEF) {
                long appnsize = (BYTE) buff[i + 2] * 256 + (BYTE) buff[i + 3];
                i = i + 1 + appnsize;
            } else if ((BYTE)buff[i] == 0XFF &&
                       (BYTE)buff[i+1] == 0XDB) {
                res = 0;
                free(buff);
                buff = NULL;
                isConfirm = true;
                break;
            }
        }
        if (!isConfirm) {
            res = 0;
            free(buff);
            buff = NULL;
        }
    } else {
        res = 0;
        free(buff);
        buff = NULL;
    }
    return res;
}

vector<int> JpegPackerImp::getCanjpegDecode(vector <string> filePaths, vector <int> positions) {
    XLOGI("JpegPacker", "getCanjpegDecode start .. filePaths size: %d", filePaths.size());
    vector<int> ret;
    if(filePaths.size() <= 0 || positions.size() <=0 || filePaths.size() != positions.size()) {
        XLOGE("JpegPacker", "getCanjpegDecode filePaths-size-%d positions-size-%d", filePaths.size(), positions.size());
        return ret;
    }
    for (int i=0 ; i<filePaths.size(); i++){
        ret.push_back(isCanjpegDecode(filePaths[i], positions[i]));
    }
    XLOGI("JpegPacker", "getCanjpegDecode end .. ret size: %d", ret.size());
    return ret;
}

int JpegPackerImp::encrypt(SliceDataInfo slice, vector<BYTE> &data){
    if(slice.rect.size() != 4) {
        return -1;
    }
    XLOGI("JpegPacker", "encrypt begin");
    clock_t start = clock();
    vector<BYTE> id= longTobyte(slice.id);
    BYTE left [4];
    floatTobytes(slice.rect[0], left);
    BYTE top [4];
    floatTobytes(slice.rect[1], top);
    BYTE right [4];
    floatTobytes(slice.rect[2], right);
    BYTE bottom [4];
    floatTobytes(slice.rect[3], bottom);
    long sliceimagefilesize = slice.data.size();
    vector<BYTE> slicesize = longTobyte(sliceimagefilesize);

    uint64_t* inputcode;
    uint64_t outcode;

    unsigned char value1[8] = {id[0], id[1], id[2], id[3], left[0], left[1], left[2], left[3]};
    inputcode = (uint64_t*)value1;
    outcode = paeser_.crypt(*inputcode, 0);
    unsigned char* value = (unsigned char*)&outcode;
    for (int32_t i = 0; i < 8; i++) {
        data[i] = value[i];
    }

    unsigned char value2[8] = {top[0], top[1], top[2], top[3], right[0], right[1], right[2], right[3]};
    inputcode = (uint64_t*)value2;
    outcode = paeser_.crypt(*inputcode, 0);
    value = (unsigned char*)&outcode;
    for (int32_t i = 0; i < 8; i++) {
        data[8 + i] = value[i];
    }

    unsigned char value3[8] = {bottom[0], bottom[1], bottom[2], bottom[3], slicesize[0], slicesize[1], slicesize[2], slicesize[3]};
    inputcode = (uint64_t*)value3;
    outcode = paeser_.crypt(*inputcode, 0);
    value = (unsigned char*)&outcode;
    for (int32_t i = 0; i < 8; i++) {
        data[16 + i] = value[i];
    }
    clock_t finish = clock();
    double timeTaken = (double) (finish - start) / (double) CLOCKS_PER_SEC;
    XLOGI("JpegPacker", "encrypt end %lf", timeTaken);
    return 0;
}

int JpegPackerImp::decrypt(vector<BYTE> data, SliceDataInfo& slice, long& sliceDataSize){
    if (data.size() != 24) {
        return -1;
    }

    uint64_t num = 0;
    uint64_t outcode;

    for (int32_t i = 7; i >= 0; i--) {
        num = (num << 8) + (data[i] & 0xFF);
    }
    outcode = paeser_.crypt(num,1);
    unsigned char* value = (unsigned char*)&outcode;
    slice.id = value[0] * 256 * 256 * 256  + value[1] * 256 * 256 + value[2] * 256  + value[3];
    BYTE left[4] = {value[4], value[5], value[6], value[7]};

    num = 0;
    for (int32_t i = 15; i >= 8; i--) {
        num = (num << 8) + (data[i] & 0xFF);
    }
    outcode = paeser_.crypt(num,1);
    value = (unsigned char*)&outcode;
    BYTE top[4] = {value[0], value[1], value[2], value[3]};
    BYTE right[4] = {value[4], value[5], value[6], value[7]};

    num = 0;
    for (int32_t i = 23; i >= 16; i--) {
        num = (num << 8) + (data[i] & 0xFF);
    }
    outcode = paeser_.crypt(num, 1);
    value = (unsigned char*)&outcode;
    BYTE bottom[4] = {value[0], value[1], value[2], value[3]};
    sliceDataSize = value[4] * 256 * 256 * 256  + value[5] * 256 * 256 + value[6] * 256  + value[7];

    slice.rect.push_back(bytesTofloat(left));
    slice.rect.push_back(bytesTofloat(top));
    slice.rect.push_back(bytesTofloat(right));
    slice.rect.push_back(bytesTofloat(bottom));

    return 0;
}
