//
//  GRNDispatcher.h
//  CTBusiness
//
//  Created by GRN on 5/16/16.
//  Copyright © 2016 Ctrip. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRNDefine.h"
#import "GRNURL.h"

@interface GRNURLHandler : NSObject

// GRNURL分发
+ (BOOL)openURLString:(NSString *)urlString fromViewController:(UIViewController *)vc;

+ (BOOL)openURL:(GRNURL *)url fromViewController:(UIViewController *)vc;

@end
