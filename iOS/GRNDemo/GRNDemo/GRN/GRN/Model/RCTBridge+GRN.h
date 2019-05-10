//
//  RCTBridge+GRN.h
//  CTBusiness
//
//  Created by GRN on 16/7/21.
//  Copyright © 2016年 Ctrip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GRNURL.h"

#import <React/RCTBridge.h>


@class GRNView;

typedef enum eGRNBridgeState {
    Bridge_State_None = 0,
    Bridge_State_Loading = 1,
    Bridge_State_Ready = 2,
    Bridge_State_Dirty = 3,
    Bridge_State_Error = 4,
} eGRNBridgeState;

@interface RCTBridge(GRN)

//缓存的key值
+ (NSString *)keyFromURL:(NSURL *)url;

//从URL获取业务模块名
+ (NSString *)productNameFromFileURL:(NSURL *)fileURL;

@property (nonatomic, readonly) NSString *cachedKey;

@property (nonatomic, readwrite) eGRNBridgeState originalBridgeState;

@property (nonatomic, readwrite) eGRNBridgeState bridgeState;

//该bridge当前被多少业务使用
@property (nonatomic, readwrite) NSUInteger inUseCount;

@property (nonatomic, readwrite) CFAbsoluteTime createTimestamp;

@property (nonatomic, readonly) NSString *rnProductName;

@property (nonatomic, readwrite) GRNURL *grnURL;

//业务url
@property (nonatomic, readwrite) NSURL *businessURL;
//是否unbundle
@property (nonatomic, assign) BOOL isUnbundlePackage;

@property (nonatomic, assign) NSTimeInterval  enterViewTime;  //从1970年开始的时间戳
@property (nonatomic, assign) NSTimeInterval  renderDoneTime;

@property (nonatomic, assign) NSTimeInterval  bridgeInitTime;
@property (nonatomic, assign) NSTimeInterval  bridgeReadyTime;

@property (nonatomic, assign) BOOL isRenderSuccess;  //防止重复埋success的点

@property (nonatomic, copy) NSString *instanceID;

//plugin 列表
@property (nonatomic, strong) NSMutableDictionary *pluginObjectsDict;

@property (nonatomic, weak) GRNView *grnView;

@end
