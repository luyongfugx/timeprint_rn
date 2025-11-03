#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "GPCamDefine.h"
#import "BMWAlgorithmProfile.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BMWVideoProcessDelegate <NSObject>

- (void)processWithbuilder:(void (^)(BMWAlgorithmProcessProfile* profile))builder;

- (BOOL)shouldTrigger:(double)timeStamp;

- (BOOL)resetTimestamp;

- (NSString*)id;

@end

@protocol BMWVideoAlgorithmSourceInterface <NSObject>

@required

- (NSString*)tag;

- (BOOL)addDelegate:(id<BMWVideoProcessDelegate>)delegate;

- (BOOL)removeDelegate:(id<BMWVideoProcessDelegate>)delegate;

- (void)pull;

- (BOOL)retry;

@end

NS_ASSUME_NONNULL_END
