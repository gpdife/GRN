//
//  GRNBridgeManager.h
//  GRNDemo
//
//  Created by GRN on 2019/3/5.
//  Copyright © 2019 com.ctrip. All rights reserved.
//

#import "RCTBridge+GRN.h"
#import "GRNURL.h"


@interface GRNBridgeManager : NSObject <RCTBridgeDelegate>

+ (GRNBridgeManager *)sharedGRNBridgeManager;

//根据URL，判断是否有缓存的bridge
+ (BOOL)hasInUseBridgeForURL:(GRNURL*)url;
+ (void)invalidateDirtyBridgeForURL:(GRNURL *)url;

//根据URL，获取Bridge
- (RCTBridge *)bridgeForURL:(GRNURL *)url
             viewCreateTime:(double)viewCreateTime
             moduleProvider:(RCTBridgeModuleListProvider)block
               launchOption:(NSDictionary *)options;

//预加载框架Bridge
- (void)prepareBridgeIfNeed;

@end

