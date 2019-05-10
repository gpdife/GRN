//
//  GRNPackage.h
//  CTBusiness
//
//  Created by GRN on 16/7/21.
//  Copyright © 2016年 Ctrip. All rights reserved.
//

#import "GRNPlugin.h"
#import "GRNURL.h"

@interface GRNUnbundlePackage : NSObject

- (GRNUnbundlePackage *)initWithURL:(GRNURL *)url;

//主入口moduleid
@property (nonatomic, readonly) NSString *mainModuleId;

//moduleId和js文件的mapping关系
@property (nonatomic, readonly) NSDictionary *moduleIdDict;

@end
