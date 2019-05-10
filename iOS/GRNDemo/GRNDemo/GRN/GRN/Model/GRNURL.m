//
//  GRNURL.m
//  CTBusiness
//
//  Created by GRN on 5/26/16.
//  Copyright © 2016 Ctrip. All rights reserved.
//


#import "GRNURL.h"
#import "GRNDefine.h"
#import "RCTBridge+GRN.h"
#import "NSString+URL.h"
#import "GRNUtils.h"


#define kUnbundleFileName   @"_grn_unbundle"

@interface GRNURL()

@property (nonatomic, copy) NSString *fileAbsolutePath;
@property (nonatomic, copy)  NSString *moduleName;
@property (nonatomic, copy)  NSString *title;
@property (nonatomic, strong) NSURL *bundleURL;
@property (nonatomic, copy) NSString *inRelativeURLStr;
@property (nonatomic, strong) NSString *unBundleFilePath;
@property (nonatomic, strong) NSString *productName;

@end

@implementation GRNURL

+ (BOOL)isGRNURL:(NSString *)url {
    NSString *lurl = url.lowercaseString;
    BOOL isGRNCommonURL = [lurl isEqualToString:[[self commonJSURL] absoluteString].lowercaseString];
    BOOL isGRNBizURL = [lurl containsString:kGRNModuleName.lowercaseString] &&
    [lurl containsString:kGRNModuleType.lowercaseString];
    return isGRNBizURL || isGRNCommonURL;

}


+ (NSURL *)commonJSURL {
    return [NSURL fileURLWithPath:[self commonJSPath]];
}

+ (NSString *)commonJSPath {
    return [kWebAppDirPath stringByAppendingFormat:@"%@/%@", kGRNCommonJsBundleDirName, kGRNCommonJsBundleFileName];
}

- (BOOL)isUnbundleRNURL {
    [self readUnbundleFilePathIfNeed];
    return self.unBundleFilePath.length > 0;
}

- (NSString *)unBundleWorkDir {
    return [self.fileAbsolutePath stringByDeletingLastPathComponent];
}

- (id)initWithPath:(NSString *)urlPath {
    if (self = [super init]) {
        self.inRelativeURLStr = urlPath;
        if ([urlPath.lowercaseString hasPrefix:@"http"] || [urlPath.lowercaseString hasPrefix:@"file:"]) {
            self.fileAbsolutePath = urlPath;
            self.bundleURL = [NSURL URLWithString:urlPath];
        }
        else if ([urlPath hasPrefix:@"/"]) {
            NSRange paramRange = [urlPath rangeOfString:@"?"];
            if (paramRange.location != NSNotFound) {
                self.fileAbsolutePath = [urlPath substringToIndex:paramRange.location];
                self.fileAbsolutePath = [kWebAppDirPath stringByAppendingPathComponent:self.fileAbsolutePath];
                
                NSString *queryString = [urlPath substringFromIndex:paramRange.location];
                self.bundleURL = [NSURL fileURLWithPath:self.fileAbsolutePath];
                NSString *urlStr = [self.bundleURL.absoluteString stringByAppendingString:[queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                self.bundleURL = [NSURL URLWithString:urlStr];
            }
            //read unbundle file path
            [self readUnbundleFilePathIfNeed];
            self.productName = [GRNUtils getPackageNameFromURLString:self.fileAbsolutePath];
        }
        
        NSDictionary *query = [self.bundleURL.absoluteString query];
        for (NSString *key in query.allKeys) {
            if ([key.lowercaseString isEqualToString:@"grnmodulename"]) {
                self.moduleName = query[key];
                if ([self.bundleURL isFileURL] && [self isUnbundleRNURL]) {
                    self.moduleName = [RCTBridge productNameFromFileURL:self.bundleURL];
                }
            }
            else if ([key.lowercaseString isEqualToString:@"grntitle"]) {
                self.title = query[key];
            }
        }
    }
    
    return self;
}


- (void)readUnbundleFilePathIfNeed {
    if (self.unBundleFilePath == nil) {
        NSString *unBundlFilePath = [[self.fileAbsolutePath stringByDeletingLastPathComponent]
                                     stringByAppendingPathComponent:kUnbundleFileName];
        if (access([unBundlFilePath UTF8String], 0) == 0) {
            self.unBundleFilePath = unBundlFilePath;
        }
    }
}

- (NSString *)rnFilePath {
    return self.fileAbsolutePath;
}

- (NSString *)rnModuleName {
    return self.moduleName;
}

- (NSURL *)rnBundleURL {
    return self.bundleURL;
}

- (NSString *)rnTitle {
    return self.title;
}

- (NSString *)packageName {
    return self.productName;
}




@end
