#include "message_parser.h"

MessageParser::MessageParser() {
    uint64_t main_key = 0x2020050420220420;
    key_sets_ = (key_set *) malloc(17 * sizeof(key_set));
    memset(key_sets_, 0, 17 * sizeof(key_set));
    generate_sub_keys((unsigned char *) &main_key, key_sets_);
}

MessageParser::~MessageParser() {
}

int MessageParser::parse(const char *inputPath, char **outputBuffer, unsigned long *size) {
    int ret = 0;
    do {
        unsigned long fileSize;
        unsigned long realSize = 0;
        unsigned short int padding;
        short int bytesWritten;
        unsigned long blockCount = 0, numberOfBlocks;
        unsigned char *dataBlock = (unsigned char *) malloc(8 * sizeof(char));
        unsigned char *processedBlock = (unsigned char *) malloc(8 * sizeof(char));

        clock_t start = clock();
        FILE *inputFile = fopen(inputPath, "rb");
        if (!inputFile) {
            return -1;
            break;
        }
        fseek(inputFile, 0L, SEEK_END);
        fileSize = ftell(inputFile);
        fseek(inputFile, 0L, SEEK_SET);

        numberOfBlocks = fileSize / 8 + ((fileSize % 8) ? 1 : 0);
        if (fileSize % 8 == 0) {
            realSize = fileSize - 8;
        } else {
            realSize = fileSize - (8 - fileSize % 8);
        }
        char *buffer = (char *) malloc(sizeof(char) * realSize);
        while (fread(dataBlock, 1, 8, inputFile)) {
            blockCount++;
            if (blockCount == numberOfBlocks) {
                process_message(dataBlock, processedBlock, key_sets_, DECRYPTION_MODE);
                padding = processedBlock[7];
                if (padding < 8) {
                    memcpy(buffer + 8 * (blockCount - 1), processedBlock, 8 - padding);
                }
            } else {
                process_message(dataBlock, processedBlock, key_sets_, DECRYPTION_MODE);
                memcpy(buffer + 8 * (blockCount - 1), processedBlock, 8);
            }
            memset(dataBlock, 0, 8);
        }

        *size = realSize;
        *outputBuffer = buffer;

        free(dataBlock);
        free(processedBlock);
        fclose(inputFile);
        clock_t finish = clock();
        double timeTaken = (double) (finish - start) / (double) CLOCKS_PER_SEC;
            } while (0);
    return ret;
}

int MessageParser::parseV2(const char *inputPath, char **outputBuffer, unsigned long *size) {
    clock_t start = clock();
    int ret = 0;
    unsigned long fileSize;
    unsigned long realSize = 0;
    unsigned short int padding;
    short int bytesWritten;
    unsigned long blockCount = 0, numberOfBlocks;
    unsigned char *dataBlock = (unsigned char *) malloc(8 * sizeof(char));
    unsigned char *processedBlock = (unsigned char *) malloc(8 * sizeof(char));
    FILE *inputFile = nullptr;
    do {
        inputFile = fopen(inputPath, "rb");
        if (!inputFile) {
            ret = -1;
            break;
        }
        fseek(inputFile, 0L, SEEK_END);
        fileSize = ftell(inputFile);
        fseek(inputFile, 0L, SEEK_SET);

        numberOfBlocks = fileSize / 8 + ((fileSize % 8) ? 1 : 0);
        // fileSize是加密后的size是8字节对齐的。
        realSize = fileSize;
                char *buffer = (char *) malloc(sizeof(char) * realSize);
        if(buffer == nullptr) {
            ret = -2;
            break;
        }
        memset(buffer, 0, sizeof(char) * realSize);

        while (fread(dataBlock, 1, 8, inputFile)) {
            blockCount++;
            if (blockCount == numberOfBlocks) {
                process_message(dataBlock, processedBlock, key_sets_, DECRYPTION_MODE);
                padding = processedBlock[7];
                if (padding < 8) {
                    memcpy(buffer + 8 * (blockCount - 1), processedBlock, 8 - padding);
                }
            } else {
                process_message(dataBlock, processedBlock, key_sets_, DECRYPTION_MODE);
                memcpy(buffer + 8 * (blockCount - 1), processedBlock, 8);
            }
            memset(dataBlock, 0, 8);
        }
        *size = realSize;
        *outputBuffer = buffer;
    } while (0);
    if(dataBlock != nullptr) free(dataBlock);
    if(processedBlock != nullptr) free(processedBlock);
    if(inputFile != nullptr) fclose(inputFile);
    clock_t finish = clock();
    double timeTaken = (double) (finish - start) / (double) CLOCKS_PER_SEC;
        return ret;
}

int MessageParser::crypt(const char *inputPath, const char *outputPath, uint32_t op) {
    int ret = 0;
    do {
        unsigned long fileSize;
        unsigned short int padding;
        short int bytesWritten;
        unsigned long blockCount = 0, numberOfBlocks;
        unsigned char *dataBlock = (unsigned char *) malloc(8 * sizeof(char));
        unsigned char *processedBlock = (unsigned char *) malloc(8 * sizeof(char));
        int processMode = op == 0 ? ENCRYPTION_MODE : DECRYPTION_MODE;

        clock_t start = clock();
        FILE *inputFile = fopen(inputPath, "rb");
        if (!inputFile) {
            return -1;
            break;
        }
        FILE *outputFile = fopen(outputPath, "wb");
        if (!outputFile) {
            return -2;
            break;
        }

        fseek(inputFile, 0L, SEEK_END);
        fileSize = ftell(inputFile);

        fseek(inputFile, 0L, SEEK_SET);
        numberOfBlocks = fileSize / 8 + ((fileSize % 8) ? 1 : 0);

        // Start reading input file, process and write to output file
        while (fread(dataBlock, 1, 8, inputFile)) {
            blockCount++;
            if (blockCount == numberOfBlocks) {
                if (processMode == ENCRYPTION_MODE) {
                    padding = 8 - fileSize % 8;
                    // Fill empty data block bytes with padding
                    if (padding < 8) {
                        memset((dataBlock + 8 - padding), (unsigned char) padding, padding);
                    }
                    process_message(dataBlock, processedBlock, key_sets_, processMode);
                    bytesWritten = fwrite(processedBlock, 1, 8, outputFile);
                    // Write an extra block for padding
                    if (padding == 8) {
                        memset(dataBlock, (unsigned char) padding, 8);
                        process_message(dataBlock, processedBlock, key_sets_, processMode);
                        bytesWritten = fwrite(processedBlock, 1, 8, outputFile);
                    }
                } else {
                    process_message(dataBlock, processedBlock, key_sets_, processMode);
                    padding = processedBlock[7];

                    if (padding < 8) {
                        bytesWritten = fwrite(processedBlock, 1, 8 - padding, outputFile);
                    }
                }
            } else {
                process_message(dataBlock, processedBlock, key_sets_, processMode);
                bytesWritten = fwrite(processedBlock, 1, 8, outputFile);
            }
            memset(dataBlock, 0, 8);
        }
        free(dataBlock);
        free(processedBlock);
        fclose(inputFile);
        fclose(outputFile);
        clock_t finish = clock();
        double timeTaken = (double) (finish - start) / (double) CLOCKS_PER_SEC;
            } while (0);
    return ret;
}

int MessageParser::crypt(const char *inputData, const size_t dataSize, const char *outData, uint32_t op) {
    int ret = 0;
    do {
        unsigned short int padding;
        short int bytesWritten;
        unsigned long blockCount = 0, numberOfBlocks = 0;
        unsigned char *dataBlock = (unsigned char *) malloc(8 * sizeof(char));
        unsigned char *processedBlock = (unsigned char *) malloc(8 * sizeof(char));
        int processMode = op == 0 ? ENCRYPTION_MODE : DECRYPTION_MODE;

        clock_t start = clock();
        numberOfBlocks = dataSize / 8 + ((dataSize % 8) ? 1 : 0);

        // Start reading input file, process and write to output file
        while (blockCount <= numberOfBlocks) {
            memcpy(dataBlock,(inputData + bytesWritten),8);
            blockCount++;
            if (blockCount == numberOfBlocks) {
                if (processMode == ENCRYPTION_MODE) {
                    padding = 8 - dataSize % 8;
                    // Fill empty data block bytes with padding
                    if (padding < 8) {
                        memset((dataBlock + 8 - padding), (unsigned char) padding, padding);
                    }
                    process_message(dataBlock, processedBlock, key_sets_, processMode);
                    memcpy((void *) (outData + bytesWritten), processedBlock, 8);
                    bytesWritten += 8;

                    // Write an extra block for padding
                    if (padding == 8) {
                        memset(dataBlock, (unsigned char) padding, 8);
                        process_message(dataBlock, processedBlock, key_sets_, processMode);
                        memcpy((void *) (outData + bytesWritten), processedBlock, 8);
                        bytesWritten += 8;
                    }
                } else {
                    process_message(dataBlock, processedBlock, key_sets_, processMode);
                    padding = processedBlock[7];
                    if (padding < 8) {
                        memcpy((void *) (outData + bytesWritten), processedBlock, 8 - padding);
                        bytesWritten += (8 - padding);
                    }
                }
            } else {
                process_message(dataBlock, processedBlock, key_sets_, processMode);
                memcpy((void *)(outData+bytesWritten), processedBlock, 8);
                bytesWritten +=8;
            }
            memset(dataBlock, 0, 8);
        }
        free(dataBlock);
        free(processedBlock);
        clock_t finish = clock();
        double timeTaken = (double) (finish - start) / (double) CLOCKS_PER_SEC;
            } while (0);
    return ret;
}

uint64_t MessageParser::crypt(uint64_t code, uint32_t op)
{
    uint64_t code2 = 0;
    process_message((unsigned char*)&code, (unsigned char*)&code2, key_sets_, op == 0 ? ENCRYPTION_MODE : DECRYPTION_MODE);
    return code2;
}
