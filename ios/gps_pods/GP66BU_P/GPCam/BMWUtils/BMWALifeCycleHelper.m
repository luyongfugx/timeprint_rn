#import "BMWALifeCycleHelper.h"
#import "BMWImageContext.h"
@interface BMWALifeCycleHelper ()

@property (nonatomic, assign) BOOL appInResignActive;
@property (nonatomic, assign) BOOL appInBackground;
@property (nonatomic, assign) BOOL launchedPassively;
@property (nonatomic) CGSize screenSize;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, id<BMWALifeCycleDelegate>>* backgroundObserverDic;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, id<BMWALifeCycleDelegate>>* willResignObserverDic;
@end

@implementation BMWALifeCycleHelper

+ (void)load
{
   [BMWALifeCycleHelper sharedInstance];
}

+ (BMWALifeCycleHelper*)sharedInstance
{
    static BMWALifeCycleHelper* helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!helper) {
            helper = [[BMWALifeCycleHelper alloc] init];
            helper.appInResignActive = NO;
            helper.appInBackground = NO;
            helper.backgroundObserverDic = [NSMutableDictionary new];
            helper.willResignObserverDic = [NSMutableDictionary new];
            helper.screenSize = [[UIScreen mainScreen] bounds].size;
        }
    });
    return helper;
}

- (void)dealloc
{
    [self removeObservers];
    [self.backgroundObserverDic removeAllObjects];
    [self.willResignObserverDic removeAllObjects];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addObservers];
    }
    return self;
}

- (void)setupAppState
{
    dispatch_block_t block = ^(){
        self.launchedPassively = UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
    };
    // 被动启动时 iOS 13 以下异步主队列的 block 不会执行
    if (@available(iOS 13.0, *)) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        runSynchronouslyOnMainQueue(block);
    }
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didBecomeActiveNotification:(NSNotification*)notification
{
    self.appInResignActive = NO;
    }

- (void)willResignActiveNotification:(NSNotification*)notification
{
        self.appInResignActive = YES;
    for (id<BMWALifeCycleDelegate> l in self.willResignObserverDic.allValues) {
        if([l respondsToSelector:@selector(willResignActive)]) {
            [l willResignActive];
        }
    }
}

- (void)willEnterForegroundNotification:(NSNotification*)notification
{
    self.screenSize = [[UIScreen mainScreen] bounds].size;
    self.appInBackground = NO;
    self.launchedPassively = NO;
    }

- (void)didEnterBackgroundNotification:(NSNotification*)notification
{
        self.appInBackground = YES;
    self.launchedPassively = NO;
    for (id<BMWALifeCycleDelegate> l in self.backgroundObserverDic.allValues) {
        if([l respondsToSelector:@selector(didEnterBackground)]) {
            [l didEnterBackground];
        }
    }
}

- (BOOL)addBackgroundObserver:(id<BMWALifeCycleDelegate>)observer
{
    NSNumber *key = @((int64_t)observer);
    if (!self.backgroundObserverDic[key]) {
        self.backgroundObserverDic[key] = observer;
    }
    return self.backgroundObserverDic.allKeys.count > 0;
}

- (BOOL)removeBackgroundObserver:(id<BMWALifeCycleDelegate>)observer
{
    NSNumber *key = @((int64_t)observer);
    [self.backgroundObserverDic removeObjectForKey:key];
    return self.backgroundObserverDic.allKeys.count > 0;
}

- (BOOL)addWillResignActiveObserver:(id<BMWALifeCycleDelegate>)observer
{
    NSNumber *key = @((int64_t)observer);
    if (!self.willResignObserverDic[key]) {
        self.willResignObserverDic[key] = observer;
    }
    return self.willResignObserverDic.allKeys.count > 0;
}

- (BOOL)removeWillResignActiveObserver:(id<BMWALifeCycleDelegate>)observer
{
    NSNumber *key = @((int64_t)observer);
    [self.willResignObserverDic removeObjectForKey:key];
    return self.willResignObserverDic.allKeys.count > 0;
}

@end
