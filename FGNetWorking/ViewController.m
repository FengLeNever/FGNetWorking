//
//  ViewController.m
//  FGNetWorking
//
//  Created by FengLe on 2018/4/3.
//  Copyright © 2018年 FengLe. All rights reserved.
//

#import "ViewController.h"
#import "FGRequestCenter.h"
#import "FGNetConstant.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //对网络请求中的参数进行配置,只需要一次....
    [self configHttpAPI];
    //常用的需要成功和失败回调的示例...
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        //请求的路径
        item.api = k_auth_qqLogin;
        //配置请求的参数
        item.parameters = @{
                            @"666":@"999"
                            };
        //若此接口需要调用与默认配置的服务器不同,可在此修改separateServer属性
        item.separateServer = @"----";
        //请求的间隔,避免频繁发送请求给服务器,默认是:2s,如有需要单独设置,也可修改默认值
        item.requestInterval = 2.f;
        //如果在间隔内发送请求,到时后是否继续处理,默认是NO,不做处理
        item.isFrequentContinue = NO;
        //失败后重复次数,默认为0
        item.retryCount = 1;
    } onSuccess:^(id  _Nullable responseObject) {
        //成功回调
    } onFailure:^(NSError * _Nullable error) {
        //失败回调
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        //请求完成回调(不论成功或失败)
    }];
    
    //不需要回调
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    }];
    
    //只需要成功回调
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    } onSuccess:^(id  _Nullable responseObject) {
        
    }];
    
    //只需要完成后的回调
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        
    }];
    
    
    NSString *identifier = [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    }];
    [FGRequestCenter cancelRequest:identifier onCancel:^{
        
    }];
}


- (void)configHttpAPI {
    [FGRequestCenter setupConfig:^(FGRequestConfig * _Nonnull config) {
        //默认的请求服务器地址...
        config.generalServer =  @"http:// ----- ";
        //返回数据的线程,若不设置,默认子线程...
        config.callbackQueue = dispatch_get_main_queue();
        //路径中拼接,与服务器约定的一些不会改动的参数,比如:渠道,系统版本...
        config.generalParameters = @{
                                     @"os":@"---",
                                     @"channel":@"---",
                                     @"osversion":@"---",
                                     };
        //路径中拼接,与服务器约定的一些会改动的参数,比如:网络状态,请求时间戳...
        config.realTimeParametersBlock = ^NSDictionary * _Nonnull{
            return @{
                     @"time":@"---",
                     @"network":@"---"
                     };
        };
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
