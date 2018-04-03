//
//  FGRequestEngine.h
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class FGRequestItem,AFNetworkReachabilityManager;

typedef void (^FGCompletionHandler) (id _Nullable responseObject, NSError * _Nullable error);

@interface FGRequestEngine : NSObject

+ (instancetype)defaultEngine;

- (void)sendRequest:(FGRequestItem *)item completionHandler:(nullable FGCompletionHandler)completionHandler;

- (void)cancelRequestByIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END

