//
//  FGRequestEngine.m
//  MiMi
//
//  Created by 冯乐 on 17/3/15.
//  Copyright © 2017年 FGZB. All rights reserved.
//

#import "FGRequestEngine.h"
#import "FGRequestItem.h"
#import "FGRequestConst.h"
#import "AFNetworking.h"
#import <objc/runtime.h>
#import "AFNetworkActivityIndicatorManager.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "FGNetworkStatus.h"

static dispatch_queue_t request_Completion_Callback_Queue() {
    static dispatch_queue_t request_Completion_Callback_Queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        request_Completion_Callback_Queue = dispatch_queue_create("com.requestCompletionCallbackQueue.douqu", DISPATCH_QUEUE_CONCURRENT);
    });
    return request_Completion_Callback_Queue;
}


@implementation NSObject (BindingFGRequestItem)

static NSString * const kFGRequestBindingKey = @"kFGRequestBindingKey";

- (void)bindingRequestItem:(FGRequestItem *)requestItem {
    objc_setAssociatedObject(self, (__bridge CFStringRef)kFGRequestBindingKey, requestItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FGRequestItem *)bindedRequestItem {
    FGRequestItem *item = objc_getAssociatedObject(self, (__bridge CFStringRef)kFGRequestBindingKey);
    return item;
}

@end


@interface FGRequestEngine ()
{
    dispatch_semaphore_t _selfLock;
}
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@end


@implementation FGRequestEngine

+ (instancetype)defaultEngine
{
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
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        _selfLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)sendRequest:(FGRequestItem *)item completionHandler:(nullable FGCompletionHandler)completionHandler
{
    [self dataTaskWithRequest:item completionHandler:completionHandler];
}

- (void)cancelRequestByIdentifier:(NSString *)identifier
{
    if (kStringIsEmpty(identifier)) return;
    FGSelfLock();
    NSArray *tasks = self.sessionManager.tasks;
    if (!kArrayIsEmpty(tasks)) {
        [tasks enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.bindedRequestItem.identifier isEqualToString:identifier]) {
                [task cancel];
                *stop = YES;
            }
        }];
    }
    FGSelfUnlock();
}

#pragma mark - 私有方法

- (void)dataTaskWithRequest:(FGRequestItem *)item completionHandler:(FGCompletionHandler)completionHandler
{
    NSString *httpMethod = (item.httpMethod == kFGHTTPMethodPOST) ? @"POST" : @"GET";
    AFHTTPRequestSerializer *requestSerializer = [self getRequestSerializer:item];
    NSError *serializationError = nil;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:httpMethod URLString:item.url parameters:item.parameters error:&serializationError];
    NSLog(@"最终请求地址 ... %@",urlRequest.URL.absoluteString);
    if (serializationError) {
        if (completionHandler) {
            dispatch_async(request_Completion_Callback_Queue(), ^{
                completionHandler(nil, serializationError);
            });
        }
        return;
    }
    urlRequest.timeoutInterval = item.timeoutInterval;
    NSURLSessionDataTask *dataTask = nil;
    __weak __typeof(self)weakSelf = self;
    dataTask = [self.sessionManager dataTaskWithRequest:urlRequest completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf processResponse:response object:responseObject error:error requestItem:item completionHandler:completionHandler];
    }];
    NSString *identifier = [NSString stringWithFormat:@"%lu",(unsigned long)dataTask.taskIdentifier];
    [item setValue:identifier forKey:@"_identifier"];
    [dataTask bindingRequestItem:item];
    [dataTask resume];
}


- (void)processResponse:(NSURLResponse *)response object:(id)responseObject error:(NSError *)error requestItem:(FGRequestItem *)item completionHandler:(FGCompletionHandler)completionHandler {
    AFHTTPResponseSerializer *responseSerializer = [self getResponseSerializer:item];
    NSError *serializationError = nil;
    responseObject = [responseSerializer responseObjectForResponse:response data:responseObject error:&serializationError];
    if (completionHandler) {
        dispatch_async(request_Completion_Callback_Queue(), ^{
            if (serializationError) {
                completionHandler(nil, serializationError);
            } else {
                completionHandler(responseObject, error);
            }
        });
    }
}

- (AFHTTPRequestSerializer *)getRequestSerializer:(FGRequestItem *)item
{
    switch (item.requestSerializerType) {
        case kFGRequestSerializerHTTP:
            return [AFHTTPRequestSerializer serializer];
            break;
        case kFGRequestSerializerJSON:
            return [AFJSONRequestSerializer serializer];
            break;
        default:
            return [AFJSONRequestSerializer serializer];
            break;
    }
}

- (AFHTTPResponseSerializer *)getResponseSerializer:(FGRequestItem *)item
{
    switch (item.responseSerializerType) {
        case kFGResponseSerializerHTTP:
            return [AFHTTPResponseSerializer serializer];
            break;
        case kFGResponseSerializerJSON:
            return [AFJSONResponseSerializer serializer];
            break;
        default:
            return [AFJSONResponseSerializer serializer];
            break;
    }
}

#pragma mark - 懒加载

- (AFHTTPSessionManager *)sessionManager
{
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.securityPolicy = [AFSecurityPolicy defaultPolicy];
        _sessionManager.securityPolicy.allowInvalidCertificates = YES;
        _sessionManager.securityPolicy.validatesDomainName = NO;
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.operationQueue.maxConcurrentOperationCount = 5;
        _sessionManager.completionQueue = request_Completion_Callback_Queue();
    }
    return _sessionManager;
}

@end
