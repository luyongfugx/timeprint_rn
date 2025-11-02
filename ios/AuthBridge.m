//
//  AuthBridge.m
//  timeprint_rn
//
//  Created by waynelu on 2025/11/2.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(AuthBridge, NSObject)

RCT_EXTERN_METHOD(saveSession:(NSString *)sessionJson)
RCT_EXTERN_METHOD(getSession:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
