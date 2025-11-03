#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "GPCamDefine.h"
#import "BMWVideoAlgorithmResultInterface.h"
#import "BMWAlgorithmProfile.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BMWVideoAlgorithmInterface <NSObject>

@required

@property(nonatomic) NSString *tag;

- (void)start;

- (void)stop;

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder;

@end 

NS_ASSUME_NONNULL_END


