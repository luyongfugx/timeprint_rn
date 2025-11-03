#pragma once

// OpenCV 可用性探测（与 .mm 保持一致）
#if defined(OpenCVFlag) && __has_include(<opencv2/opencv.hpp>)
  #define XH_OPENCV_AVAILABLE 1
#else
  #define XH_OPENCV_AVAILABLE 0
#endif

#if XH_OPENCV_AVAILABLE
  // 避免和 UIKit 的 YES/NO 宏冲突
  #pragma push_macro("YES")
  #pragma push_macro("NO")
  #ifdef YES
  #undef YES
  #endif
  #ifdef NO
  #undef NO
  #endif

  #include <opencv2/opencv.hpp>

  // 恢复 YES/NO 宏
  #pragma pop_macro("NO")
  #pragma pop_macro("YES")
#endif

#include <string>
#include <sstream>
#include <bitset>
#include <utility>

typedef enum {
    MEDIAN_FILTER = 1 << 0,
    SOBEL_FILTER  = 1 << 1,
    LBP_FILTER    = 1 << 2,
} FilterType;

class ImageProcessUtils {
public:
    ImageProcessUtils();
    ~ImageProcessUtils();

#if XH_OPENCV_AVAILABLE
    // 协议: "FilterType"+"imageFeature"+";"+"FilterType"+"imageFeature"+";"
    static std::string filterEncode(const cv::Mat& resizedImage, uint32_t filter);
#else
    // 未启用 OpenCV 时给个声明占位，防止外部误用（也可删掉）
    static std::string filterEncode(...) = delete;
#endif
};
