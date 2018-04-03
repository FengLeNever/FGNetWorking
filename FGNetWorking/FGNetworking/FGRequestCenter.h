//
//  FGRequestCenter.h
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FGRequestConst.h"
#import "FGRequestItem.h"

NS_ASSUME_NONNULL_BEGIN

@class FGRequestConfig;

@interface FGRequestCenter : NSObject

@property (nonatomic, strong, readonly) FGRequestConfig *requestConfig;
/**
 请求配置信息
 */
+ (void)setupConfig:(void(^)(FGRequestConfig *config))configBlock;

+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock;
+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(FGSuccessBlock)successBlock;
+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onFailure:(FGFailureBlock)failureBlock;
+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onFinished:(FGFinishedBlock)finishedBlock;
+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(nullable FGSuccessBlock)successBlock onFailure:(nullable FGFailureBlock)failureBlock;
/**
 发送请求的方法

 @param configBlock 配置请求的item
 @param successBlock 成功回调
 @param failureBlock 失败回调
 @param finishedBlock 无论成功或失败,完成的回调
 @return 请求的task的表示符,可以用来取消
 */
+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(nullable FGSuccessBlock)successBlock onFailure:(nullable FGFailureBlock)failureBlock onFinished:(FGFinishedBlock)finishedBlock;
/**
 取消一个请求
 @param identifier 发送请求时返回的标识符
 */
+ (void)cancelRequest:(NSString *)identifier;
+ (void)cancelRequest:(NSString *)identifier onCancel:(nullable FGCancelBlock)cancelBlock;

@end


@interface FGRequestConfig : NSObject
/**
 配置服务器地址
 */
@property (nonatomic, copy, nullable) NSString *generalServer;
/**
 固定公共参数
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *generalParameters;
/**
 不固定的公共参数
 */
@property (nonatomic, copy) NSDictionary* (^realTimeParametersBlock)(void);
/**
 回调的线程(如果不设置,则在请求回调的异步线程)
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

@end

NS_ASSUME_NONNULL_END
