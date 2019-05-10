//
//  GRNView.h
//  GRNDemo
//
//  Created by GRN on 2019/3/5.
//  Copyright © 2019 com.ctrip. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "GRNURL.h"
#import <React/RCTRootView.h>



@class GRNView;

@protocol GRNViewLoadingDelegate <NSObject>
@optional
- (void)showLoadingView;
- (void)hideLoadingView;
- (void)showLoadFailViewWithCode:(NSNumber *)code;
@end

@protocol GRNViewDelegate <NSObject>
@optional
- (void)grnViewLoadFailed:(GRNView *)view errorCode:(NSNumber *)code;
- (void)grnViewWillAppear:(GRNView *)view;

@end

@interface GRNView : UIView

@property (nonatomic, weak) id<GRNViewDelegate> viewDelegate;
@property (nonatomic, weak) id<GRNViewLoadingDelegate> loadingDelegate;
@property (nonatomic, readonly) RCTBridge *bridge;

@property (nonatomic, readonly) RCTRootView *reactRootView;

//初始化
- (id)initWithURL:(GRNURL *)rnURL
            frame:(CGRect)frame
initialProperties:(NSDictionary *)props
    launchOptions:(NSDictionary *)options;


- (void)loadGRNViewWithURL:(GRNURL *)url_;

@end



