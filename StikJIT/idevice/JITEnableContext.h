//
//  JITEnableContext.h
//  StikJIT
//
//  Created by s s on 2025/3/28.
//
@import Foundation;
#include "idevice.h"

typedef void (^HeartbeatCompletionHandler)(int result, NSString *message);
typedef void (^LogFuncC)(const char* message, ...);
typedef void (^LogFunc)(NSString *message);

@interface JITEnableContext : NSObject
+ (instancetype)shared;
- (IdevicePairingFile*)getPairingFileWithError:(NSError**)error;
- (void)startHeartbeatWithCompletionHandler:(HeartbeatCompletionHandler)completionHandler logger:(LogFunc)logger;
- (void)debugAppWithBundleID:(NSString*)bundleID isLC:(BOOL)isLC logger:(LogFunc)logger;
- (NSDictionary<NSString*, NSString*>*)getAppListWithError:(NSError**)error;
@end
