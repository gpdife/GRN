//
//  GRNBridgeManager.m
//  GRNDemo
//
//  Created by GRN on 2019/3/5.
//  Copyright © 2019 com.ctrip. All rights reserved.
//


#import "GRNDefine.h"
#import "GRNBridgeManager.h"
#import <React/RCTJavaScriptLoader.h>
#import <React/RCTBridge+Private.h>
#import "RCTBridge+GRN.h"
#import <React/RCTBridgeDelegate.h>
#import <React/RCTAssert.h>
#import "GRNUnbundlePackage.h"
#import <React/RCTJavaScriptExecutor.h>
#import <React/RCTExceptionsManager.h>
#import <React/RCTLog.h>
#import <React/RCTBridge.h>
#import "GRNUtils.h"

#define kMaxIdealDirtyBridgeCount 5

@interface GRNBridgeManager(){
    
}

@property (nonatomic, strong) NSMutableArray *cachedBridgeList;

@property (nonatomic, strong) RCTSource *commonJSSource;

@property (nonatomic, strong) NSDictionary *reuseInstanceConfig;

@end

static GRNBridgeManager *g_bridgeManager = NULL;

static int g_bridge_GUID = 0;

@implementation GRNBridgeManager

+ (GRNBridgeManager *)sharedGRNBridgeManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (g_bridgeManager == NULL) {
            g_bridgeManager = [[GRNBridgeManager alloc] init];
        }
    });
    return g_bridgeManager;
}


- (id)init {
    if (self = [super init]) {
        self.cachedBridgeList = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(GRNViewControllerDidReleased:)
                                                     name:kGRNViewDidReleasedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(GRNViewControllerDidUsed:)
                                                     name:kGRNViewDidCreateNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bridgeDidLoadSuccess:)
                                                     name:RCTJavaScriptDidLoadNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(bridgeDidLoadFailed:)
                                                     name:RCTJavaScriptDidFailToLoadNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];

        RCTSetFatalHandler(^(NSError *error) {
            {//记录metrics和js Error日志，埋点上报
                error.errorBridge.bridgeState = Bridge_State_Error;
            }
        });
        
        RCTSetLogFunction(^(RCTLogLevel level, RCTLogSource source, NSString *fileName, NSNumber *lineNumber, NSString *message) {

        });
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cacheBridge:(RCTBridge *)inBridge {
    if (inBridge == nil || ![inBridge.bundleURL isFileURL]) {
        return;
    }
    @synchronized(self) {
        if (![self.cachedBridgeList containsObject:inBridge]) {
            NSString *inBridgeCacheKey = inBridge.cachedKey;
            BOOL isContain = NO;
            NSString *commonJsKey =  [RCTBridge keyFromURL:[GRNURL commonJSURL]];
            for (RCTBridge *bridge in self.cachedBridgeList) {
                if (bridge.cachedKey == inBridgeCacheKey &&
                    ![commonJsKey isEqualToString:inBridgeCacheKey]) {
                    isContain = YES;
                    break;
                }
            }
            if (!isContain) {
                inBridge.createTimestamp = CFAbsoluteTimeGetCurrent();
                [self.cachedBridgeList addObject:inBridge];
            }
        }
    }
}


- (void)prepareBridgeIfNeed {
    int readyBridgeCount = 0;
    int loadingBridgeCount = 0;
    
    for (RCTBridge *bridge in self.cachedBridgeList) {
        if (bridge.bridgeState == Bridge_State_Ready) {
            readyBridgeCount += 1;
        }
        else if (bridge.bridgeState == Bridge_State_Loading) {
            loadingBridgeCount += 1;
        }
    }
    
    if (loadingBridgeCount >= 1 || readyBridgeCount >= 1) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self createNewUnbundleBridge];
    });
    
}

- (RCTBridge*)createNewUnbundleBridge {
    if (access([[GRNURL commonJSPath] UTF8String], 0) == 0 ) {
        __weak id weakSelf = self;
        RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:weakSelf launchOptions:nil];
        bridge.isUnbundlePackage = YES;

        [weakSelf cacheBridge:bridge];
        return bridge;
    }
    
    return NULL;
}


- (int)emitRequirePackageEntryMessage:(RCTBridge*)bridge isFromCacheBridge:(BOOL)isCahce{
    NSString *moduleId  = NULL;
    
    {
        GRNUnbundlePackage *unbundlePackage = [[GRNUnbundlePackage alloc] initWithURL:bridge.grnURL];
        moduleId = unbundlePackage.mainModuleId;
        RCTBridge *cxxBridge = bridge.batchedBridge;
        if ([cxxBridge respondsToSelector:@selector(updateModuleIdConfig:)]) {
            [cxxBridge updateModuleIdConfig:unbundlePackage.moduleIdDict];
        }
    }
    
    NSString *businessURL = bridge.businessURL.absoluteString;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:moduleId forKey:@"moduleId"];
    [userInfo setValue:bridge.rnProductName forKey:@"productName"];
    [userInfo setValue:businessURL forKey:@"packagePath"];

    bridge.bridgeState = Bridge_State_Dirty;
    
    [bridge enqueueJSCall:@"RCTDeviceEventEmitter.emit" args:@[@"requirePackageEntry",userInfo]];

    return 0;
}

+ (BOOL)hasInUseBridgeForURL:(GRNURL*)url {
    if (url == NULL) {
        return  NO;
    }
    NSString *pkgName = url.packageName;
    for (RCTBridge *bridge in [GRNBridgeManager sharedGRNBridgeManager].cachedBridgeList) {
        if ([pkgName isEqualToString:bridge.grnURL.packageName] &&
            bridge.bridgeState == Bridge_State_Dirty && bridge.inUseCount > 0) {
            return YES;
        }
    }
    return NO;
}

+ (void)invalidateDirtyBridgeForURL:(GRNURL *)url {
    if (url == NULL) {
        return;
    }
    
    NSString *pkgName = url.packageName;
    for (RCTBridge *bridge in [GRNBridgeManager sharedGRNBridgeManager].cachedBridgeList) {
        if ([pkgName isEqualToString:bridge.grnURL.packageName]) {
            bridge.bridgeState = Bridge_State_Error;
        }
    }
}


- (RCTBridge *)bridgeForURL:(GRNURL *)url
             viewCreateTime:(double)viewCreateTime
             moduleProvider:(RCTBridgeModuleListProvider)block
               launchOption:(NSDictionary *)options
{
    if (url == nil) {
        return nil;
    }
    
    RCTBridge *resultBridge = nil;
    
    //获取业务URL对应的缓存Bridge
    NSString *urlKey = [RCTBridge keyFromURL:url.rnBundleURL];
    BOOL isIgnoreCache = [[[url.rnBundleURL absoluteString] lowercaseString] containsString:[@"ignoreCached=1" lowercaseString]];
    if (!isIgnoreCache) {
        BOOL reuseInstance = [self isReuseInstance:url];
        for (RCTBridge *bridge in self.cachedBridgeList) {
            BOOL isSame = reuseInstance?[url.packageName isEqualToString:bridge.grnURL.packageName] : [urlKey isEqualToString:bridge.cachedKey];
            BOOL canUse;
            if (reuseInstance) {
                canUse = isSame && bridge.bridgeState == Bridge_State_Dirty;
            }else{
                canUse = isSame && bridge.inUseCount == 0 && bridge.bridgeState == Bridge_State_Dirty && bridge.isRenderSuccess;
            }
            if (canUse) {
                resultBridge = bridge;
                resultBridge.grnURL = url;
                resultBridge.originalBridgeState = Bridge_State_Dirty;
                [GRNUtils emitEventForBridge:resultBridge
                                        name:kGRNStartLoadEvent
                                        info:@{@"startLoadTime":@(viewCreateTime*1000)}];
                break;
            }
        }
    }
    
    if (resultBridge == nil){
        if (url.isUnbundleRNURL) {  //业务URL没有缓存Bridge，如果是unbundle，获取common Bridge
            NSString *commonUrlKey = [RCTBridge keyFromURL:[GRNURL commonJSURL]];
            for (RCTBridge *bridge in self.cachedBridgeList) {
                if ([bridge.cachedKey isEqualToString:commonUrlKey] &&
                    bridge.inUseCount == 0 &&
                    bridge.bridgeState == Bridge_State_Ready) {
                    resultBridge = bridge;
                    resultBridge.businessURL = url.rnBundleURL;
                    resultBridge.grnURL = url;
                    resultBridge.originalBridgeState = Bridge_State_Ready;
                    [GRNUtils emitEventForBridge:resultBridge
                                            name:kGRNStartLoadEvent
                                            info:@{@"startLoadTime":@(viewCreateTime*1000)}];
                    
                    [self emitRequirePackageEntryMessage:resultBridge isFromCacheBridge:YES];
                    [self prepareBridgeIfNeed];
                    break;
                }
            }
            
            if (resultBridge == nil) {
                resultBridge = [self createNewUnbundleBridge];
                resultBridge.bridgeState = Bridge_State_Loading;
                resultBridge.businessURL = url.rnBundleURL;
                resultBridge.originalBridgeState = Bridge_State_Loading;
                resultBridge.grnURL = url;
            }
            
            resultBridge.isUnbundlePackage = YES;
        }
        else { //非unbundle打包，也没有缓存
            RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self bundleURL:url.rnBundleURL moduleProvider:block launchOptions:options];
            bridge.businessURL = url.rnBundleURL;
            bridge.isUnbundlePackage = NO;
            resultBridge = bridge;
            [self cacheBridge:bridge];
        }
    }
    
    return  resultBridge;
}


- (void)receiveMemoryWarning{
    @synchronized(self) {
        for (int i = 0; i < [self.cachedBridgeList count]; i++) {
            RCTBridge *bridge = [self.cachedBridgeList objectAtIndex:i];
            if (bridge.inUseCount == 0 && (bridge.bridgeState == Bridge_State_Dirty || bridge.bridgeState == Bridge_State_Error)) {
                [self removeBridgeFromCacheList:bridge];
                i--;
            }
        }
    }
}


#pragma mark - --- Notification
- (void)bridgeDidLoadFailed:(NSNotification *)notify {
    NSDictionary *userInfo = notify.userInfo;
    RCTBridge *bridge = userInfo[@"bridge"];
    bridge = [RCTBridge realGRNBridge:bridge];
    
    if (bridge.bridgeState == Bridge_State_Loading || bridge.bridgeState == Bridge_State_None) {
        bridge.bridgeState = Bridge_State_Error;
        [GRNBridgeManager notifyGRNViewLoadFailedForBridge:bridge code:-505];
    }
}

- (void)bridgeDidLoadSuccess:(NSNotification *)notify {
    NSDictionary *userInfo = notify.userInfo;
    RCTBridge *bridge = userInfo[@"bridge"];
    bridge = [RCTBridge realGRNBridge:bridge];
    bridge.bridgeReadyTime = [[NSDate date] timeIntervalSince1970];
    if (bridge.isUnbundlePackage) {
        bridge.bridgeState = Bridge_State_Ready;
        if (bridge.businessURL != NULL) {//进入业务模块，bridge加载完成
            [GRNUtils emitEventForBridge:bridge
                                    name:kGRNStartLoadEvent
                                    info:@{@"startLoadTime":@(bridge.enterViewTime*1000)}];
            [self emitRequirePackageEntryMessage:bridge isFromCacheBridge:NO];
        }
        
        [self prepareBridgeIfNeed];
    }
    else {
        //普通Bundle加载完成
        bridge.bridgeState = Bridge_State_Dirty;
    }
}

- (int)getMaxIdealDirtyBridgeCount {
    return kMaxIdealDirtyBridgeCount;
}

- (void)performLRUCheck {
    @synchronized(self) {
        for (int i = 0; i < [self.cachedBridgeList count]; i++) {
            RCTBridge *bridge = [self.cachedBridgeList objectAtIndex:i];
            BOOL isErrorBridge = (bridge.bridgeState == Bridge_State_Error && bridge.inUseCount == 0);
            BOOL isIlegalStateBridge = bridge.bridgeState == Bridge_State_Dirty && bridge.inUseCount == 0 && (!bridge.isRenderSuccess);
            if (isIlegalStateBridge || isErrorBridge) {
                [self removeBridgeFromCacheList:bridge];
                i--;
            }
        }
    }
    
    int dirtyBridgeCount = 0;
    RCTBridge *firstIdealBridge = NULL;
    for (RCTBridge *bridge in self.cachedBridgeList) {
        if (bridge.bridgeState == Bridge_State_Dirty ) {
            dirtyBridgeCount++;
            if (bridge.inUseCount == 0) {
                if (firstIdealBridge == NULL) {
                    firstIdealBridge = bridge;
                }
                else if (bridge.createTimestamp < firstIdealBridge.createTimestamp) {
                    firstIdealBridge = bridge;
                }
            }
        }
    }
    
    if (dirtyBridgeCount > [self getMaxIdealDirtyBridgeCount] && firstIdealBridge != NULL) {
        [self removeBridgeFromCacheList: firstIdealBridge];
    }
}

- (void)removeBridgeFromCacheList:(RCTBridge *)bridge {
    if (bridge == NULL) {
        return;
    }
    @synchronized (self) {
        RCTExecuteOnMainQueue(^{
            [bridge invalidate];
        });
        [self.cachedBridgeList removeObject:bridge];
    }
}

- (void)GRNViewControllerDidReleased:(NSNotification *)notification {
    RCTBridge *cachedBridge = [notification.userInfo valueForKey:@"bridge"];
    @synchronized(self) {
        cachedBridge.inUseCount -= 1;
        if (cachedBridge.inUseCount == 0) {
            [self performLRUCheck];
        }
    }
}

- (void)GRNViewControllerDidUsed:(NSNotification *)notification {
    RCTBridge *cachedBridge = [notification.userInfo valueForKey:@"bridge"];
    @synchronized(self) {
        cachedBridge.inUseCount += 1;
    }
}

#pragma mark - ---- RCTBridge delegate

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    if (bridge.bundleURL.absoluteString.length > 0) {
        return bridge.bundleURL;
    }else{
        return [GRNURL commonJSURL];
    }
}

- (void)loadSourceForBridge:(RCTBridge *)bridge
                  withBlock:(RCTSourceLoadBlock)loadCallback {
    if (loadCallback == nil) {
        return;
    }
    if (bridge.bundleURL.absoluteString.length > 0){
        [RCTJavaScriptLoader loadBundleAtURL:bridge.bundleURL onProgress:^(RCTLoadingProgress *progressData) {
            NSLog(@"progressData.....");
        } onComplete:^(NSError *error, RCTSource *source) {
            loadCallback(error, source);
        }];
    }
    else{
        if (access([[GRNURL commonJSPath] UTF8String], 0) == 0) {
            [RCTJavaScriptLoader loadBundleAtURL:[GRNURL commonJSURL] onProgress:^(RCTLoadingProgress *progressData) {
                NSLog(@"progressData.....");
            } onComplete:^(NSError *error, RCTSource *source) {
                loadCallback(error, source);
            }];
        } else {
            loadCallback([NSError errorWithDomain:@"Unbundle打包的Common JS文件不存在！" code:-10001 userInfo:nil], nil);
        }
    }
    
}

- (void)bridgeInitialized:(RCTBridge*)bridge{
    bridge.instanceID = [self createInstanceID];
    bridge.bridgeInitTime = [[NSDate date] timeIntervalSince1970];
    bridge.pluginObjectsDict = [NSMutableDictionary dictionary];
}

- (void)reactViewRenderSuccess:(UIView *)view forBridge:(RCTBridge*)bridge {
    if (!bridge.isRenderSuccess) {
        //首屏rendersuccess
        bridge.renderDoneTime = [[NSDate date] timeIntervalSince1970];
        double totalTime = bridge.renderDoneTime  - bridge.enterViewTime;
        [GRNUtils emitEventForBridge:bridge name:kGRNLoadSuccessEvent info:@{@"time":@(totalTime*1000)}];
        bridge.isRenderSuccess = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:GRNViewDidRenderSuccess
                                                            object:nil
                                                          userInfo:@{@"bridge":bridge}];
        if (GRN_DEV) { //加载时间
            [GRNUtils showToast:[NSString stringWithFormat:@"加载时间：%.2f",totalTime]];
        }
    }
}

+ (void)notifyGRNViewLoadFailedForBridge:(RCTBridge *)bridged code:(int)errorCode {
    if (bridged == NULL) {
        return;
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    [userInfo setValue:bridged forKey:@"bridge"];
    [userInfo setValue:@(errorCode) forKey:@"errorCode"];
    [[NSNotificationCenter defaultCenter] postNotificationName:GRNViewLoadFailedNotification
                                                        object:nil
                                                      userInfo:userInfo];
}


#pragma mark - ---- private
- (BOOL)isReuseInstance:(GRNURL *)grnurl{
    return NO;
}

- (NSString *)createInstanceID{
    NSString *dateStr = [self currentDateStr];
    NSString *instanceID = [NSString stringWithFormat:@"%@-%d",dateStr,g_bridge_GUID];
    g_bridge_GUID++;
    return instanceID;
}

- (NSString *)currentDateStr{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmssSSS"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    return dateString;
}



@end
