Pod::Spec.new do |s|
    s.name         = "GPCam"
    s.version      = "3.0.1"
    s.summary      = "gpcma"
    s.description  = "gpcma SDK"
    s.author       = { "ccsdfsd3omsd.com" => "sandoi" }
    s.license      = "MIT"
    s.homepage     = "https://github.com/cCamd4er8SDK"
    s.source       = { :git => "https://github.com/cCamd4er8SDK", :tag => s.version.to_s }
    s.platform     = :ios, '13.0'
    s.requires_arc = true

    s.xcconfig     = { "HEADER_SEARCH_PATHS" => "${PODS_ROOT}/boost" }

    s.frameworks   = 'AVFoundation', 'Foundation', 'UIKit', 'CoreGraphics', 'OpenGLES', 'CoreMotion', 'CoreMedia'
    s.weak_frameworks = 'Photos', 'CoreML'
    s.libraries = 'c++', 'z'
    s.prefix_header_file = false
    s.prefix_header_file = 'GPCam/sdf99jjd.pch'
    
    s.subspec 'BBD59MM' do |ss|
        ss.source_files = [
            'GPCam/BMWUtils/BMWALifeCycleHelper.{h,m}',
            'GPCam/**/**/*.{h,m,mm,cpp,c}'
        ]
        ss.exclude_files = [
            'GPCam/SuanfaGG5/cv/**/*.{h,m,mm,cpp}']
        ss.public_header_files = [
            'GPCam/**/**/*.h'
        ]
        ss.private_header_files = [
            'GPCam/BMWJpegPacker/jpegpacker/*.h',
            'GPCam/SuanfaGG5/ssim/**/*.h',
            'GPCam/SuanfaGG5/cv/**/*.h',
            'GPCam/SuanfaGG5/code/**/*.h'
        ]
        ss.resources = ['GPCam/GPCam.bundle']
    end
        
    s.subspec 'OpenCV' do |ss|
      ss.source_files = [
        'GPCam/SuanfaGG5/cv/utils/*.{h,m,mm,cpp}',
        'GPCam/BMWUtils/BMWAlgorithmUtils.mm'
      ]
      ss.private_header_files = ['GPCam/SuanfaGG5/cv/**/*.h']
      ss.dependency 'OpenCV', '4.3.0'
      ss.pod_target_xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) OpenCVFlag=1',
        'GCC_ENABLE_CPP_RTTI'          => 'YES',
        'CLANG_CXX_LANGUAGE_STANDARD'  => 'gnu++14',
        'CLANG_CXX_LIBRARY'            => 'libc++'
      }
    end

    s.dependency  'YYModel', '~> 1.0.4'
    s.dependency  'Mantle', '~> 1.5.6'
    s.default_subspecs = 'BBD59MM', 'OpenCV'
end
