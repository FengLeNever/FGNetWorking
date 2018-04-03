//
//  FGRequestCenter.m
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#import "FGRequestCenter.h"
#import "FGRequestItem.h"
#import "FGRequestEngine.h"
#import "FGNetworkStatus.h"

NSString *const FG_HTTP_DOMAIN = @"douqu.httpServer.host";

@interface FGRequestCenter ()
{
    dispatch_semaphore_t _selfLock;
}
@property (nonatomic, strong) FGRequestConfig *requestConfig;

@property (nonatomic, strong) NSMutableDictionary *requestTimestampPool;

@property (nonatomic, strong) dispatch_source_t clearnTimer;

@end

@implementation FGRequestCenter

+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock
{
    return [[FGRequestCenter defaultCenter] sendRequest:configBlock onSuccess:NULL onFailure:NULL onFinished:NULL];
}

+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(FGSuccessBlock)successBlock
{
    return [[FGRequestCenter defaultCenter] sendRequest:configBlock onSuccess:successBlock onFailure:NULL onFinished:NULL];
}

+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onFailure:(FGFailureBlock)failureBlock
{
    return [[FGRequestCenter defaultCenter] sendRequest:configBlock onSuccess:NULL onFailure:failureBlock onFinished:NULL];
}

+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onFinished:(FGFinishedBlock)finishedBlock
{
    return [[FGRequestCenter defaultCenter] sendRequest:configBlock onSuccess:NULL onFailure:NULL onFinished:finishedBlock];
}
+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(nullable FGSuccessBlock)successBlock onFailure:(FGFailureBlock)failureBlock
{
    return [[FGRequestCenter defaultCenter] sendRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:NULL];
}

+ (nullable NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(nullable FGSuccessBlock)successBlock onFailure:(nullable FGFailureBlock)failureBlock onFinished:(FGFinishedBlock)finishedBlock
{
    return [[FGRequestCenter defaultCenter] sendRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (void)setupConfig:(void(^)(FGRequestConfig *config))configBlock
{
    [[FGRequestCenter defaultCenter] setupConfig:configBlock];
}

+ (void)cancelRequest:(NSString *)identifier
{
    [[FGRequestCenter defaultCenter] cancelRequest:identifier onCancel:nil];
}

+ (void)cancelRequest:(NSString *)identifier onCancel:(nullable FGCancelBlock)cancelBlock
{
    [[FGRequestCenter defaultCenter] cancelRequest:identifier onCancel:cancelBlock];
}

#pragma mark - 私有方法

+ (instancetype)defaultCenter {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _selfLock = dispatch_semaphore_create(1);
        [self creatCleanTimer];
    }
    return self;
}

- (void)dealloc
{
    [_requestTimestampPool removeAllObjects];
    [self stopClearnTimer];
}

- (void)setupConfig:(void(^)(FGRequestConfig *config))configBlock
{
    FG_SAFE_BLOCK(configBlock,self.requestConfig);
    NSAssert(!kStringIsEmpty(self.requestConfig.generalServer), @"generalServer is nil ...");
}

- (void)cancelRequest:(NSString *)identifier onCancel:(nullable FGCancelBlock)cancelBlock
{
    [[FGRequestEngine defaultEngine] cancelRequestByIdentifier:identifier];
    FG_SAFE_BLOCK(cancelBlock);
}

- (NSString *)sendRequest:(FGConfigItemBlock)configBlock onSuccess:(nullable FGSuccessBlock)successBlock onFailure:(nullable FGFailureBlock)failureBlock onFinished:(FGFinishedBlock)finishedBlock
{
    FGRequestItem *requestItem = [FGRequestItem requestItem];
    FG_SAFE_BLOCK(configBlock,requestItem);
    __block NSString *identifier;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processRequestItem:requestItem onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
        if ([self checkNetworkWithRequestItem:requestItem]) {
            [self sendRequestItem:requestItem];
            identifier = requestItem.identifier;
        }
    });
    return identifier;
}

- (BOOL)checkLimitTimeWithRequestItem:(FGRequestItem *)requestItem
{
    BOOL isAllow = NO;
    NSInteger currentTime = [self getCurrentTimestamp];
    FGSelfLock();
    NSNumber *lastTime = [self.requestTimestampPool objectForKey:requestItem.api];
    FGSelfUnlock();
    if (lastTime && currentTime < lastTime.integerValue) {
        if (!requestItem.isFrequentContinue){
            NSError *error = [self generateErrorWithErrorReason:@"频繁的发送同一个请求" errorCode:kFGNetWorkFrequentRequestError];
            [self failureWithError:error forRequestItem:requestItem];
            return isAllow;
        }
        NSInteger nextRequestTime = lastTime.integerValue - currentTime;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(nextRequestTime * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self sendRequestItem:requestItem];
        });
        return isAllow;
    }
    NSNumber *limitTime = @(currentTime + requestItem.requestInterval);
    FGSelfLock();
    [self.requestTimestampPool setObject:limitTime forKey:requestItem.api];
    FGSelfUnlock();
    return isAllow = YES;
}

- (void)processRequestItem:(FGRequestItem *)requestItem onSuccess:(FGSuccessBlock)successBlock onFailure:(FGFailureBlock)failureBlock onFinished:(FGFinishedBlock)finishedBlock
{
    NSAssert(!kStringIsEmpty(requestItem.api), @"The request api can't be null.");
    if (successBlock) {
        [requestItem setValue:successBlock forKey:@"_successBlock"];
    }
    if (failureBlock) {
        [requestItem setValue:failureBlock forKey:@"_failureBlock"];
    }
    if (finishedBlock) {
        [requestItem setValue:finishedBlock forKey:@"_finishedBlock"];
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (!kDictIsEmpty(self.requestConfig.generalParameters)) {
        [parameters addEntriesFromDictionary:self.requestConfig.generalParameters];
    }
    NSDictionary *realTimeParameters = FG_SAFE_BLOCK(self.requestConfig.realTimeParametersBlock);
    if (!kDictIsEmpty(realTimeParameters)) {
        [parameters addEntriesFromDictionary:realTimeParameters];
    }
    if (!kDictIsEmpty(requestItem.parameters)) {
        [parameters addEntriesFromDictionary:requestItem.parameters];
    }
    requestItem.parameters = parameters;
    if (kStringIsEmpty(requestItem.separateServer)) {
        requestItem.separateServer = self.requestConfig.generalServer;
    }
    NSString *url = [NSString stringWithFormat:@"%@%@",requestItem.separateServer,requestItem.api];
    [requestItem setValue:url forKey:@"_url"];
}

- (BOOL)checkNetworkWithRequestItem:(FGRequestItem *)requestItem
{
    if (![[FGNetworkStatus shareNetworkStatus] isReachable]) {
        NSError *error = [self generateErrorWithErrorReason:@"当前网络不可用" errorCode:kFGNetworkStatusAvailableError];
        [self failureWithError:error forRequestItem:requestItem];
        return NO;
    }
    return YES;
}

- (void)sendRequestItem:(FGRequestItem *)requestItem
{
    if ([self checkLimitTimeWithRequestItem:requestItem]) {
        [[FGRequestEngine defaultEngine] sendRequest:requestItem completionHandler:^(id  _Nullable responseObject, NSError * _Nullable error) {
            if (error) {
                [self failureWithError:error forRequestItem:requestItem];
            }
            else{
                [self successWithResponse:responseObject forRequestItem:requestItem];
            }
        }];
    }
}

- (void)successWithResponse:(id)responseObject forRequestItem:(FGRequestItem *)requestItem
{
    NSError *error;
    if ([self checkOutResult:responseObject forRequestItem:requestItem error:&error])
    {
        if (self.requestConfig.callbackQueue) {
            dispatch_async(self.requestConfig.callbackQueue, ^{
                [self execureSuccessBlockWithResponse:responseObject forRequest:requestItem];
            });
        }
        else{
            [self execureSuccessBlockWithResponse:responseObject forRequest:requestItem];
        }
    }
    else
    {
        [self failureWithError:error forRequestItem:requestItem];
    }
}

- (void)execureSuccessBlockWithResponse:(id)responseObject forRequest:(FGRequestItem *)requestItem
{
    if (requestItem.responseSerializerType == kFGResponseSerializerJSON && [responseObject isKindOfClass:[NSDictionary class]]) {
        responseObject = (NSDictionary *)responseObject[@"data"];
    }
    NSLog(@"http request success...%@",responseObject);
    FG_SAFE_BLOCK(requestItem.successBlock,responseObject);
    FG_SAFE_BLOCK(requestItem.finishedBlock,responseObject,nil);
    [requestItem cleanCallbackBlocks];
}

- (void)failureWithError:(NSError *)error forRequestItem:(FGRequestItem *)requestItem
{
    if (requestItem.retryCount > 0) {
        requestItem.retryCount --;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self sendRequestItem:requestItem];
        });
        return;
    }
    NSLog(@"http request error...%@",error);
    if (self.requestConfig.callbackQueue) {
        dispatch_async(self.requestConfig.callbackQueue, ^{
            [self execureFailureBlockWithError:error forRequest:requestItem];
        });
    }else{
        [self execureFailureBlockWithError:error forRequest:requestItem];
    }
}

- (void)execureFailureBlockWithError:(NSError *)error forRequest:(FGRequestItem *)requestItem
{
    FG_SAFE_BLOCK(requestItem.failureBlock,error);
    FG_SAFE_BLOCK(requestItem.finishedBlock,nil,error);
    [requestItem cleanCallbackBlocks];
}

- (void)creatCleanTimer
{
    if (_clearnTimer) return;
    self.clearnTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(self.clearnTimer, dispatch_walltime(NULL, 0), 1 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.clearnTimer, ^{
        [self cleanTimestampPool];
    });
    dispatch_resume(self.clearnTimer);
}

- (void)cleanTimestampPool
{
    if (kDictIsEmpty(self.requestTimestampPool)) return;
    FGSelfLock();
    NSDictionary *tempDict = [self.requestTimestampPool mutableCopy];
    FGSelfUnlock();
    NSInteger currentTime = [self getCurrentTimestamp];
    for (NSString *api in tempDict) {
        NSInteger limitTime = [[self.requestTimestampPool objectForKey:api] integerValue];
        if (currentTime >= limitTime) {
            FGSelfLock();
            [self.requestTimestampPool removeObjectForKey:api];
            FGSelfUnlock();
        }
    }
}

- (void)stopClearnTimer
{
    if (_clearnTimer) {
        dispatch_source_cancel(_clearnTimer);
        _clearnTimer = NULL;
    }
}

- (NSInteger)getCurrentTimestamp
{
    return ((NSInteger)[[NSDate date] timeIntervalSince1970] * 1000);
}

- (BOOL)checkOutResult:(id)responseObject forRequestItem:(FGRequestItem *)requestItem error:(NSError **)error
{
    BOOL isSuccess = NO;
    if (!responseObject)
    {
        if (error != NULL) *error = [self generateErrorWithErrorReason:@"responseObject is nil - 返回数据为空" errorCode:KFGNetWorkResponseObjectError];
        return isSuccess;
    }
    // JSON格式
    if (requestItem.responseSerializerType == kFGResponseSerializerJSON)
    {
        if (![responseObject isKindOfClass:[NSDictionary class]])
        {
            if (error != NULL) *error = [self generateErrorWithErrorReason:@"responseObject type is not right - 返回数据类型错误" errorCode:KFGNetWorkResponseObjectError];
            return isSuccess;
        }
        NSNumber *code = ((NSDictionary *)responseObject)[@"code"];
        if ([code isEqualToNumber:@(kCorrectReturnCode)])
        {
            return isSuccess = YES;
        }
        else
        {
            if (error != NULL) *error = [self generateErrorWithErrorReason:((NSDictionary *)responseObject)[@"message"] errorCode:code.integerValue];
            return isSuccess;
        }
    }
    // data格式
    else
    {
        if (![responseObject isKindOfClass:[NSData class]])
        {
            if (error != NULL) *error = [self generateErrorWithErrorReason:@"responseObject type is not right - 返回数据类型错误" errorCode:KFGNetWorkResponseObjectError];
            return isSuccess;
        }
        return isSuccess = YES;
    }
}

- (NSError *)generateErrorWithErrorReason:(NSString *)errorReason errorCode:(NSInteger)errorCode
{
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(errorReason, @""),NSLocalizedFailureReasonErrorKey:NSLocalizedString(errorReason, @"")};
    NSError *error = [[NSError alloc] initWithDomain:FG_HTTP_DOMAIN code:errorCode userInfo:errorInfo];
    return error;
}

- (FGRequestConfig *)requestConfig
{
    if (!_requestConfig) {
        _requestConfig = [[FGRequestConfig alloc] init];
    }
    return _requestConfig;
}

- (NSMutableDictionary *)requestTimestampPool
{
    if (!_requestTimestampPool) {
        _requestTimestampPool = [NSMutableDictionary dictionary];
    }
    return _requestTimestampPool;
}

@end

@implementation FGRequestConfig

@end


