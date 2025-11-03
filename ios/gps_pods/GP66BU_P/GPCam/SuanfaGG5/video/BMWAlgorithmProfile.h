#import <Foundation/Foundation.h>
#import "BMWMediaBaseModel.h"

NS_ASSUME_NONNULL_BEGIN
@class BMWRect;
@interface BMWAlgorithmProcessProfile : NSObject
@property (nonatomic) CVPixelBufferRef pixelBuffer;
@property (nonatomic) NSArray* metadataObjects;
@property (nonatomic) BMWRect *rectOfInterest;
@property (nonatomic) BOOL isMirror;
@property (nonatomic) BMWDeviceOrientation orient;
@property (nonatomic) BOOL enableSmooth;
@property (nonatomic) BOOL sync;
@end


@interface BMWAlgorithmConfigModel : BMWMediaBaseModel
@property(nonatomic, strong) NSString* version;
@property(nonatomic, strong) NSString* version2;
@property(nonatomic, assign) NSInteger opset;
@property(nonatomic, assign) NSInteger epoch;
@property(nonatomic, assign) NSInteger size;
@property(nonatomic, strong) NSArray<NSString*>* labels;
@property(nonatomic, strong) NSArray<NSNumber*>* labelProbThresholds;
@property(nonatomic, strong) NSArray<NSString*>* labelZH;
@property(nonatomic, assign) CGFloat probThreshold;
@property(nonatomic, assign) CGFloat nmsThreshold;
@property(nonatomic, assign) int encrypt;

+ (BMWAlgorithmConfigModel*)buildModel:(NSArray<NSString*>*)labels;

+ (NSString*)buildJsonFromModel:(BMWAlgorithmConfigModel*)model;

+ (BMWAlgorithmConfigModel*)buildModelFromJsonPath:(NSString*)jsonPath;

@end


NS_ASSUME_NONNULL_END
