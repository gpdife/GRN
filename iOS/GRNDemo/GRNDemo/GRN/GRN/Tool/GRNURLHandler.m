//
//  GRNDispatcher.m
//  CTBusiness
//
//  Created by GRN on 5/16/16.
//  Copyright © 2016 Ctrip. All rights reserved.
//

#import "GRNURLHandler.h"
#import "GRNViewController.h"
#import "GRNURL.h"


@implementation GRNURLHandler

+ (BOOL)openURLString:(NSString *)urlString fromViewController:(UIViewController *)vc
{
    if (![GRNURL isGRNURL:urlString] || vc == NULL) {
        return NO;
    }
    GRNURL *url = [[GRNURL alloc] initWithPath:urlString];
    return [self openURL:url fromViewController:vc];
}

+ (BOOL)openURL:(GRNURL *)url fromViewController:(UIViewController *)vc
{
    if (url == NULL || vc == NULL) {
        return NO;
    }
    
    GRNViewController *rvc = [[GRNViewController alloc] initWithURL:url];

    rvc.title = url.rnTitle;
    BOOL ret = NO;
    BOOL isAnimated = YES;
    NSString *urlStr = url.rnBundleURL.absoluteString;

    if ([[self class] isShowTypePresent:urlStr]) {
        [vc.navigationController presentViewController:rvc animated:isAnimated completion:nil];
        ret = YES;
    }
    else{
        [vc.navigationController pushViewController:rvc animated:isAnimated];
        ret = YES;
    }
    return ret;
}

+ (BOOL)isShowTypePresent:(NSString *)urlStr{
    return [urlStr.lowercaseString containsString:@"showType=present".lowercaseString];
}


@end
