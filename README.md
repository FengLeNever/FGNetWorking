背景:
上一个项目中对AFN的二次封装是写一个单例的基类持有AFN请求对象,具体的业务通过集成来区分,不同的业务逻辑对应着一个单例类,这样随着业务扩大,单例逐渐增多;而有些功能之间的界限并没有那么明显,就产生了臃肿,逻辑不清晰等缺点.重构的话耗时耗力..

正好公司开启新的项目,有感于之前网络请求的封装模式不够优雅,专门对AFN进行了一次封装,改进之前的弊端.
- 调用简单,接口优雅.
- 可定制不同请求接口.
- 可控制请求频率,同一个请求时间间隔.
- 请求未发送前,可取消请求.
- 若某个请求失败,可配置重发次数.
- 支持GET和POST
- 适合中小型,不需要很复杂网络请求的项目可适用.
---
源码[简书](https://www.jianshu.com/p/9194daf4d5eb),喜欢的同学给个✨ ✨.
调用示例
- 对网络请求中使用的参数进行配置,只需要一次.
```
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
```
- 常用,需要成功和失败回调的示例
```
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        //请求的路径
        item.api = k_auth_qqLogin;
        //配置请求的参数
        item.parameters = @{
        @"666":@"999"
        };
        } onSuccess:^(id  _Nullable responseObject) {
        //成功回调
        } onFailure:^(NSError * _Nullable error) {
        //失败回调
        } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        //请求完成回调(不论成功或失败)
    }];
```
- 不需要回调
```
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    }];
```
- 只需要成功回调
```
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    } onSuccess:^(id  _Nullable responseObject) {

    }];
```
- 只需要完成后的回调+可针对请求进行定制示例
```
    [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
        //若此接口需要调用与默认配置的服务器不同,可在此修改separateServer属性
        item.separateServer = @"----";
        //请求的间隔,避免频繁发送请求给服务器,默认是:2s,如有需要单独设置,也可修改默认值
        item.requestInterval = 2.f;
        //如果在间隔内发送请求,到时后是否继续处理,默认是NO,不做处理
        item.isFrequentContinue = NO;
        //失败后重复次数,默认为0
        item.retryCount = 1;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {

    }];
```
- 取消请求,注意是在请求未发送前
```
    NSString *identifier = [FGRequestCenter sendRequest:^(FGRequestItem * _Nonnull item) {
        item.api = k_auth_qqLogin;
    }];
    [FGRequestCenter cancelRequest:identifier onCancel:^{

    }];
```
- 更多使用请参考源码.

架构介绍

- FGRequestConfig: 请求配置类,比如默认服务器,回调线程,请求参数等内容.
- FGRequestItem:  针对每一个网络请求封装的模型类,通过对属性的设置,可以对每个网络请求进行定制.
- FGRequestCenter: 对上层提供接口,调用下层方法.在这里操作:路径拼接,请求配置,网络状态监测,请求处理等.
- FGRequestEngine: 对AFN的封装,负责调用AFN发送请求.

控制请求间隔思路

在FGRequestCenter类中,持有一个pool形式的NSMutableDictionary , 每次收到发送的请求以keyValue的形式将请求的url和一下次允许请求的时间存起来.下次调用前对pool进行检测是否允许请求,当未满足请求时间时,判断是否等待,再发送请求.并通过定时器轮询的方式对pool内的键值对进行筛选,移除超时的keyValue.

使用技巧

因为网络请求在项目中很多文件都会使用,如果item.api = @"/auth/login"这样去写,修改起来会很麻烦,我们可以在写个接口文件,统一将接口在文件中配置.若接口非常多,可以根据业务创建多个文件来区分.

![1](https://upload-images.jianshu.io/upload_images/1637319-6859c901443aab88.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


