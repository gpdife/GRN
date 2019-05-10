//
//  GRNDefine.m
//  GRNDemo
//
//  Created by GRN on 16/11/8.
//  Copyright © 2016年 ctrip. All rights reserved.
//

#import "GRNDefine.h"


@implementation GRNDefine

NSString *getAppVersion() {
    static NSString *currentVersion = nil;
    
    if (currentVersion == nil) {
        currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if (currentVersion.length == 0) {
            currentVersion = @"";
        }
    }
    
    return currentVersion;
}


@end

