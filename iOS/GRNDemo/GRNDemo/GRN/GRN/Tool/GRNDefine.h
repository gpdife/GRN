//
//  GRNDefine.h
//  GRNDemo
//
//  Created by GRN on 16/11/8.
//  Copyright © 2016年 ctrip. All rights reserved.
//


#import <Foundation/Foundation.h>

#ifndef GRN_DEV
#if DEBUG
#define GRN_DEV 1
#else
#define GRN_DEV 0
#endif
#endif

//work目录
#define kDocumentDir    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define kWebappDirPrefixName @"webapp_work"

#define kWebAppDirName [kWebappDirPrefixName stringByAppendingFormat:@"_%@", getAppVersion()]
#define kWebAppDirPath  [kDocumentDir stringByAppendingFormat:@"/%@/",kWebAppDirName]


//GRN const
#define kDefaultGRNUnbundleMainModuleName   @"GRNApp"
#define kGRNCommonJsBundleDirName           @"rn_common"
#define kGRNCommonJsBundleFileName          @"common_ios.js"

#define kGRNModuleName      @"GRNModuleName="
#define kGRNModuleType      @"GRNType=1"

//Notifications
#define kGRNViewDidCreateNotification       @"kGRNViewDidCreateNotification"
#define kGRNViewDidReleasedNotification     @"kGRNViewDidReleasedNotification"


#define kGRNStartLoadEvent                  @"GRNStartLoadEvent"
#define kGRNLoadSuccessEvent                @"GRNLoadSuccessEvent"
#define kGRNPageRenderSuccess               @"GRNPageRenderSuccess"

#define GRNViewLoadFailedNotification       @"GRNViewLoadFailedNotification"
#define GRNViewDidRenderSuccess             @"GRNViewDidRenderSuccess"


#define dispatch_main_sync(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

#define dispatch_main_async(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }


@interface GRNDefine : NSObject

NSString *getAppVersion(void);

@end

#pragma mark - ----


