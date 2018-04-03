//
//  FGRequestConst.h
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#ifndef FGRequestConst_h
#define FGRequestConst_h

NS_ASSUME_NONNULL_BEGIN

#define FG_SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })
#define FGSelfLock() dispatch_semaphore_wait(self->_selfLock, DISPATCH_TIME_FOREVER)
#define FGSelfUnlock() dispatch_semaphore_signal(self->_selfLock)

/*
 * 判断是否有效字符串
 */
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )
/**
 判断数组是否为空
 */
#define kArrayIsEmpty(array) (array == nil || [array isKindOfClass:[NSNull class]] || array.count == 0)
/**
 判断字典是否为空
 */
#define kDictIsEmpty(dic) (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys.count == 0 || dic.allKeys == nil)
/**
 data是否为空
 */
#define kDataIsEmpty(data) (![data isKindOfClass:[NSData class]] || data == nil || [data length] < 1 ? YES : NO )


@class FGRequestItem;

//服务器返回的正确校验码,各个公司不同,配置不同,需作出修改...
static NSInteger kCorrectReturnCode = 200;


typedef NS_ENUM(NSInteger, FGHTTPMethodType) {
    kFGHTTPMethodGET    = 0,    // GET
    kFGHTTPMethodPOST   = 1,    // POST
};

typedef NS_ENUM(NSInteger, FGRequestSerializerType) {
    kFGRequestSerializerHTTP     = 0, // 默认POST的请求数据方式
    kFGRequestSerializerJSON    = 1, // 默认GET的请求数据方式
};

typedef NS_ENUM(NSInteger, FGResponseSerializerType) {
    kFGResponseSerializerHTTP    = 0,
    kFGResponseSerializerJSON   = 1,  //默认响应的数据形式
};

NS_ENUM(NSInteger)
{
    KFGNetWorkResponseObjectError  =                     -1,   //返回数据错误
    kFGNetworkStatusAvailableError =                     2004, //当前网络状态不可用
    kFGNetWorkFrequentRequestError =                     2005, //网络频繁请求
};
    
typedef void (^FGConfigItemBlock)(FGRequestItem *item);
typedef void (^FGSuccessBlock)(id _Nullable responseObject);
typedef void (^FGFailureBlock)(NSError * _Nullable error);
typedef void (^FGFinishedBlock)(id _Nullable responseObject, NSError * _Nullable error);
typedef void (^FGCancelBlock)(void);


NS_ASSUME_NONNULL_END

#endif /* FGRequestConst_h */
