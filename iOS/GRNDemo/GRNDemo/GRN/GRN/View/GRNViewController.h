//
//  GRNViewController.h
//  GRNDemo
//
//  Created by GRN on 2019/3/5.
//  Copyright © 2019 com.ctrip. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRNDefine.h"

#import <UIKit/UIKit.h>
#import "GRNURL.h"
#import "GRNView.h"

#import <React/RCTBridgeModule.h>


@interface GRNViewController : UIViewController

@property (nonatomic, readonly) GRNURL *grnURL;

- (instancetype)initWithURL:(GRNURL *)url;

- (instancetype)initWithURL:(GRNURL *)url
       andInitialProperties:(NSDictionary *)initialProperties;

@end

