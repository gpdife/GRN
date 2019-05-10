//
//  GRNPlugin.h
//  CTBusiness
//
//  Created by GRN on 15/11/18.
//  Copyright © 2015年 Ctrip. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRNDefine.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTAssert.h>

#define GRNResult(s, k, v) [GRNPlugin RNResultWithStatusCode:(s) methodName:(k) errorDesc:(v)]

@interface GRNPlugin : NSObject

@property (nonatomic, weak) RCTBridge *bridge;

@property (nonatomic, weak) UIView *grnView;

+ (void)callModule:(NSString *)moduleName
          function:(NSString *)functionName
        parameters:(NSDictionary *)parameters
            bridge:(RCTBridge *)bridge
          callback:(RCTResponseSenderBlock)callback;

//子类重载，实现对应的plugin功能
- (void)callFunction:(NSString *)functionName
          parameters:(NSDictionary *)parameters
            callback:(RCTResponseSenderBlock)callback;

//子类重载
- (void)clear;

//plugin api调用通用result
+ (NSDictionary *)RNResultWithStatusCode:(int)statusCode
                              methodName:(NSString *)methodName
                               errorDesc:(NSString *)errorDesc;

@end
