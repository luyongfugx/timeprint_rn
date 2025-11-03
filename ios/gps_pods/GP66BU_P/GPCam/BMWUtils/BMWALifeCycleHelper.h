#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BMWALifeCycleDelegate <NSObject>
@optional
- (void)didEnterBackground;
- (void)willEnterForeground;
- (void)didBecomeActive;
- (void)willResignActive;

@end

@interface BMWALifeCycleHelper : NSObject

@property (nonatomic, readonly) BOOL appInResignActive;
@property (nonatomic, readonly) BOOL appInBackground;
@property (nonatomic, readonly) BOOL launchedPassively;
@property (nonatomic, readonly) CGSize screenSize;

+ (BMWALifeCycleHelper*)sharedInstance;
- (void)setupAppState;
- (BOOL)addBackgroundObserver:(id<BMWALifeCycleDelegate>)observer;
- (BOOL)removeBackgroundObserver:(id<BMWALifeCycleDelegate>)observer;

- (BOOL)addWillResignActiveObserver:(id<BMWALifeCycleDelegate>)observer;
- (BOOL)removeWillResignActiveObserver:(id<BMWALifeCycleDelegate>)observer;

@end

NS_ASSUME_NONNULL_END
