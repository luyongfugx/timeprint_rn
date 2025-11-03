#include "ImageProcessUtils.h"

static const std::string ZERO_PENDING = "00"; // 2个0组成的字符串
static const std::string BASE64_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#";
static const std::string SEPARATOR = ";";
std::string binaryToBase64(const std::string& binaryString) {
    std::string base64Result;
    for (size_t i = 0; i < binaryString.length(); i += 6) {
        std::string sevenBits = binaryString.substr(i, 6);
        int decimal = 0;
        int base = 1;
        std::string base64;
        for (auto it = sevenBits.rbegin(); it != sevenBits.rend(); ++it) {
            if (*it == '1') {
                decimal += base;
            }
            base *= 2;
        }
        if (decimal == 0) base64 = "0";
        while (decimal > 0) {
            int remainder = decimal % 64;
            decimal /= 64;
            base64 = BASE64_CHARS[remainder] + base64;
        }
        base64Result += base64;
    }
    return base64Result;
}

// radius=1, neighbors=8
cv::Mat computeRORLBP(const cv::Mat& image, int radius, int neighbors) {
    cv::Mat lbpImage = cv::Mat::zeros(image.size(), CV_8UC1);
    for (int i = radius; i < image.rows - radius; i++) {
        for (int j = radius; j < image.cols - radius; j++) {
            float center = image.at<uchar>(i, j);
            uchar lbpCode = 0;
            int bit = 0;
            std::vector<float> samples;

            // Collect samples in a circular manner
            for (int k = -radius; k <= radius; k++) {
                for (int l = -radius; l <= radius; l++) {
                    if (k == 0 && l == 0) {
                        continue;
                    }
                    float sample = image.at<uchar>(i + k, j + l);
                    samples.push_back(sample);
                }
            }

            // Sort the samples to find the transition from 0 to 1
            std::sort(samples.begin(), samples.end());
            for (size_t m = 0; m < samples.size(); m++) {
                lbpCode |= (samples[m] >= center) << bit;
                bit++;
            }

            // Perform ROR (Rotate on Right) 增加旋转不变性
            uchar rotatedCode = lbpCode;
            int minNonZeroBit = -1;
            for (int n = 0; n < neighbors; n++) {
                if ((lbpCode & (1 << n)) != 0) {
                    if (minNonZeroBit == -1) {
                        minNonZeroBit = n;
                    }
                }
            }
            if (minNonZeroBit != -1) {
                rotatedCode = (lbpCode >> minNonZeroBit) | (lbpCode << (neighbors - minNonZeroBit));
            }

            lbpImage.at<uchar>(i, j) = rotatedCode;
        }
    }
    return lbpImage;
}

std::string ImageProcessUtils::filterEncode(const cv::Mat& grayImage, uint32_t filter) {

    std::string codeStr = "";
    // 计算二值化阈值
    int threshold = cv::mean(grayImage)[0];
    
    // 中值计算
    if(filter & MEDIAN_FILTER) {
        cv::Mat mediaImage, mediaBinaryImage;
        // 中值滤波图像二值化
        cv::medianBlur(grayImage, mediaImage, 3);
        cv::threshold(mediaImage, mediaBinaryImage, threshold, 255, cv::THRESH_BINARY);
        // 二值编码
        std::stringstream midCode;
        for (int y = 0; y < mediaBinaryImage.rows; ++y) {
            for (int x = 0; x < mediaBinaryImage.cols; ++x) {
                if (mediaBinaryImage.at<uchar>(y, x) == 255) {
                    midCode << "1";
                } else {
                    midCode << "0";
                }
            }
        }
        std::string midCodeStr = std::to_string(MEDIAN_FILTER) + binaryToBase64(midCode.str() + ZERO_PENDING);
        codeStr += midCodeStr + SEPARATOR;
    }
    
    if(filter & SOBEL_FILTER) {
        cv::Mat sobelX, sobelY, sobelImage;
        // Sobel计算
        cv::Sobel(grayImage, sobelX, CV_16S, 1, 0);
        cv::Sobel(grayImage, sobelY, CV_16S, 0, 1);
        cv::convertScaleAbs(sobelX, sobelX);
        cv::convertScaleAbs(sobelY, sobelY);
        cv::addWeighted(sobelX, 0.5, sobelY, 0.5, 0, sobelImage);
        
        // sobel图像二值化
        cv::Mat sobelBinaryImage;
        cv::threshold(sobelImage, sobelBinaryImage, threshold, 255, cv::THRESH_BINARY);
        std::stringstream sobelCode;
        for (int y = 0; y < sobelBinaryImage.rows; ++y) {
            for (int x = 0; x < sobelBinaryImage.cols; ++x) {
                if (sobelBinaryImage.at<uchar>(y, x) == 255) {
                    sobelCode << "1";
                } else {
                    sobelCode << "0";
                }
            }
        }
        std::string sobelCodeStr = std::to_string(SOBEL_FILTER) + binaryToBase64(sobelCode.str() + ZERO_PENDING);
        codeStr += sobelCodeStr + SEPARATOR;
    }
    
    // lbp计算
    if(filter & LBP_FILTER) {
        cv::Mat lbpBinaryImage;
        cv::Mat lbpImage = computeRORLBP(grayImage, 1, 8);
        // lbp图像二值化
        int lbpThreshold = cv::mean(lbpImage)[0];
        cv::threshold(lbpImage, lbpBinaryImage, lbpThreshold, 255, cv::THRESH_BINARY);
        std::stringstream lbpCode;
        for (int y = 0; y < lbpBinaryImage.rows; ++y) {
            for (int x = 0; x < lbpBinaryImage.cols; ++x) {
                if (lbpBinaryImage.at<uchar>(y, x) == 255) {
                    lbpCode << "1";
                } else {
                    lbpCode << "0";
                }
            }
        }
        std::string lbpCodeStr = std::to_string(LBP_FILTER) + binaryToBase64(lbpCode.str() + ZERO_PENDING);
        codeStr += lbpCodeStr + SEPARATOR;
    }
    return codeStr;
}

ImageProcessUtils::ImageProcessUtils() {
}

ImageProcessUtils::~ImageProcessUtils() {
}
