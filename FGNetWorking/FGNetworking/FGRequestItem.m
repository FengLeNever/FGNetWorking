//
//  FGRequestItem.m
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#import "FGRequestItem.h"

@implementation FGRequestItem

+ (instancetype)requestItem
{
    return [[[self class] alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _httpMethod = kFGHTTPMethodGET;
        _requestSerializerType = kFGRequestSerializerJSON;
        _responseSerializerType = kFGResponseSerializerJSON;
        _requestInterval = 2.f;
        _timeoutInterval = 60.f;
        _retryCount = 0;
        _isFrequentContinue = NO;
        _separateServer = nil;
    }
    return self;
}

- (void)setHttpMethod:(FGHTTPMethodType)httpMethod
{
    _httpMethod = httpMethod;
    _requestSerializerType = kFGRequestSerializerHTTP;
}

- (void)cleanCallbackBlocks {
    _successBlock = nil;
    _failureBlock = nil;
}

@end
