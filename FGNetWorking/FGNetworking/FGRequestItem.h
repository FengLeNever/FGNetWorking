//
//  FGRequestItem.h
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGRequestConst.h"
NS_ASSUME_NONNULL_BEGIN

@interface FGRequestItem : NSObject

+ (instancetype)requestItem;
/**
 "/im/getServer"格式,拼接到服务器地址后面
 */
@property (nonatomic, copy) NSString *api;
/**
 最终请求的url
 */
@property (nonatomic, copy, readonly) NSString *url;
/**
 默认使用FGRequestConfig的generalServer地址,如果不为nil,则使用separateServer
 */
@property (nonatomic, copy, nullable) NSString *separateServer;
/**
 默认是FGMHTTPMethodGET , 'GET'请求
 */
@property (nonatomic, assign) FGHTTPMethodType httpMethod;
/**
 请求的间隔,避免频繁发送请求给服务器,默认是:2s,如有需要单独设置
 */
@property (nonatomic, assign) NSTimeInterval requestInterval;
/**
 如果在间隔内发送请求,到时候是否继续处理,默认是NO,不做处理
 */
@property (nonatomic, assign) BOOL isFrequentContinue;
/**
 请求的超时时间,默认60秒
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/**
 请求发送后分配的标识符
 */
@property (nonatomic, copy, readonly) NSString *identifier;
/**
 请求发送数据格式,默认是JSON
 */
@property (nonatomic, assign) FGRequestSerializerType requestSerializerType;
/**
 请求返回的数据格式,默认是JSON
 */
@property (nonatomic, assign) FGResponseSerializerType responseSerializerType;
/**
 请求的参数
 */
@property (nonatomic, strong, nullable) NSDictionary *parameters;
/**
 失败后的回调
 */
@property (nonatomic, copy, readonly, nullable) FGSuccessBlock failureBlock;
/**
 成功后的回调
 */
@property (nonatomic, copy, readonly, nullable) FGFailureBlock successBlock;
/**
 结束后的回调
 */
@property (nonatomic, copy, readonly, nullable) FGFinishedBlock finishedBlock;
/**
 失败后重复次数,默认为0
 */
@property (nonatomic, assign) NSUInteger retryCount;
/**
 清除回调
 */
- (void)cleanCallbackBlocks;

@end
NS_ASSUME_NONNULL_END
