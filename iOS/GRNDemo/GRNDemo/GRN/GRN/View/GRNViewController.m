//
//  GRNViewController.m
//  GRNDemo
//
//  Created by GRN on 2019/3/5.
//  Copyright © 2019 com.ctrip. All rights reserved.
//

#import "GRNDefine.h"

#import "GRNViewController.h"
#import "GRNView.h"
#import <React/RCTDefines.h>
#import <React/RCTBridge+Private.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#import "GRNBridgeManager.h"
#import "GRNPlugin.h"
#import "GRNUnbundlePackage.h"

@interface GRNViewController ()<GRNViewDelegate,GRNViewLoadingDelegate>
@property (nonatomic, strong) GRNURL *url;
@property (nonatomic, strong) GRNView *rctView;

@property (nonatomic, strong) NSDictionary *initialProperties;

@property (nonatomic, readonly) RCTBridge *rctBridge;


@end

@implementation GRNViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSDictionary *tmpDict = [self.rctBridge.pluginObjectsDict copy];
    for (GRNPlugin *plugIn in tmpDict) {
        if ([plugIn isKindOfClass:[GRNPlugin class]]) {
            [plugIn clear];
        }
    }
    @synchronized(self.rctBridge.pluginObjectsDict) {
        [self.rctBridge.pluginObjectsDict removeAllObjects];
    }
    self.rctBridge.grnView = nil;

}

- (instancetype)initWithURL:(GRNURL *)url_
{
    return [self initWithURL:url_ andInitialProperties:nil];
}

- (instancetype)initWithURL:(GRNURL *)url andInitialProperties:(NSDictionary *)initialProperties
{
    if (self = [super init]) {
        self.url = url;
        self.initialProperties = initialProperties;
    }
    
    return self;
}

-(GRNURL *)grnURL
{
    return self.url;
}

- (RCTBridge *)rctBridge {
    return self.rctView.bridge;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.rctView = [[GRNView alloc] initWithURL:self.url
                                          frame:self.view.bounds
                              initialProperties:self.initialProperties
                                  launchOptions:nil];
    self.rctView.frame = self.view.bounds;
    self.rctView.loadingDelegate = self;
    self.rctView.viewDelegate = self;
    [self.view addSubview:self.rctView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.rctView loadGRNViewWithURL:self.grnURL];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark ---- GRNViewDelegate
- (void)grnViewLoadFailed:(GRNView *)view errorCode:(NSNumber *)code {
    
}

- (void)grnViewWillAppear:(GRNView *)view {
    
}

#pragma mark ---- GRNViewLoadingDelegate
- (void)showLoadingView {

}

- (void)hideLoadingView {

}

- (void)showLoadFailViewWithCode:(NSNumber *)code {
    
}
@end

