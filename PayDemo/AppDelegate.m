//
//  AppDelegate.m
//  PayDemo
//
//  Created by 李金柱 on 16/4/21.
//  Copyright © 2016年 likeme. All rights reserved.
//

#import "AppDelegate.h"
#import <CommonCrypto/CommonDigest.h>
#import "RSA.h"
@interface AppDelegate ()<WXApiDelegate>
{
    NSUserDefaults *_userDefaults;
    AFHTTPSessionManager *_manager;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    _userDefaults = [NSUserDefaults standardUserDefaults];
    [WXApi registerApp:WXAppId];
    return YES;
}
#pragma
#pragma  mark =================授权后回调 WXApiDelegate=================

-(void)onResp:(BaseReq *)resp
{
    /*
     ErrCode ERR_OK = 0(用户同意)
     ERR_AUTH_DENIED = -4（用户拒绝授权）
     ERR_USER_CANCEL = -2（用户取消）
     code    用户换取access_token的code，仅在ErrCode为0时有效
     state   第三方程序发送时用来标识其请求的唯一性的标志，由第三方程序调用
     sendReq时传入，由微信终端回传，state字符串长度不能超过1K
     lang    微信客户端当前语言
     country 微信用户当前国家信息
     */
    
    
    //获取access_token和openid
    if([resp isKindOfClass:[SendAuthResp class]])
    {
        
        SendAuthResp *sendResp = (SendAuthResp *) resp;
        if (0 == sendResp.errCode) {
            // NSString *code = SendResp.code;
            //NSDictionary *dic = @{@"code":code};
            NSLog(@"用户同意");
        }else if (-4 == sendResp.errCode)
        {
            NSLog(@"用户拒绝授权");
        }else if (-2 == sendResp.errCode){
            NSLog(@"用户取消");
            return;
        }
        
        //登录流程
        NSString *wxGetTokenUrl = @"https://api.weixin.qq.com/sns/oauth2/access_token";
        NSString *authorization_code = @"authorization_code";
        
        
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                             WXAppId,@"appid",
                             WXSecret,@"secret",
                             sendResp.code,@"code",
                             authorization_code,@"grant_type", nil];
        
        _manager = [AFHTTPSessionManager manager];
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        [_manager GET:wxGetTokenUrl parameters:dic progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSDictionary *token = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
            
            [self getUserInfoWith:token];
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }else{
        
        BaseResp *res = (BaseResp *)resp;
        NSString *strMsg = nil;
        NSString *strTitle = [[NSString alloc]init];;
        
        if([resp isKindOfClass:[PayResp class]]){
            //支付返回结果，实际支付结果需要去微信服务器端查询
            strTitle = @"支付结果";
            
            switch (res.errCode) {
                case WXSuccess:
                    strMsg = @"支付结果：成功！";
                      NSLog(@"支付成功－PaySuccess，retcode = %d", res.errCode);
                    break;
                default:
                {
                    NSString *meassage = nil;
                    if (-2 == res.errCode) {
                        meassage = @"您已取消支付！";
                    }else if (-1 == res.errCode){
                        meassage = @"支付异常！";
                    }
                    strMsg = [NSString stringWithFormat:@"支付结果：失败！ %@", meassage];
                    NSLog(@"错误，retcode = %d, retstr = %@", res.errCode,res.errStr);
                }
                    break;
            }
       
        }
    }
    
}
- (void)getUserInfoWith:(NSDictionary *)accessTokenDic
{
    //返回数据
    NSLog(@"Dictionary:%@", accessTokenDic);
    NSString *access_token = [accessTokenDic objectForKey:@"access_token"];
    [[NSUserDefaults standardUserDefaults]setObject:access_token forKey:@"access_token"];
    NSString *openid = [accessTokenDic objectForKey:@"openid"];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         access_token,@"access_token",
                         openid,@"openid", nil];
    
    NSString *wxUserInfoUrl = @"https://api.weixin.qq.com/sns/userinfo";
    [_manager GET:wxUserInfoUrl parameters:dic progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        
        NSLog(@"%@",userInfo);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];}
-(void)getUserInfoSuccessWith:(NSDictionary *)userInfoDic{
    
    //返回数据
    NSLog(@"Dictionary:%@", userInfoDic);
    
}

//重写AppDelegate的handleOpenURL和openURL方法
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    //银联支付
    [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
        
        //结果code为成功时，先校验签名，校验成功后做后续处理
        if([code isEqualToString:@"success"]) {
            
            //判断签名数据是否存在
            if(data == nil){
                //如果没有签名数据，建议商户app后台查询交易结果
                return;
            }
            
            //数据从NSDictionary转换为NSString
            NSData *signData = [NSJSONSerialization dataWithJSONObject:data
                                                               options:0
                                                                 error:nil];
            NSString *sign = [[NSString alloc] initWithData:signData encoding:NSUTF8StringEncoding];
            
            
            
            //验签证书同后台验签证书
            //此处的verify，商户需送去商户后台做验签
            if([self verifyLocal:sign]) {
                //支付成功且验签成功，展示支付成功提示
            }
            else {
                //验签失败，交易结果数据被篡改，商户app后台查询交易结果
            }
        }
        else if([code isEqualToString:@"fail"]) {
            //交易失败
        }
        else if([code isEqualToString:@"cancel"]) {
            //交易取消
        }
    }];
    
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
            
        }];
    }
    
    return [WXApi handleOpenURL:url delegate:self];
}
-(BOOL) verify:(NSString *) resultStr {
    
    //验签证书同后台验签证书
    //此处的verify，商户需送去商户后台做验签
    return NO;
}
-(BOOL) verifyLocal:(NSString *) resultStr {

    //从NSString转化为NSDictionary
    NSData *resultData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:resultData options:0 error:nil];

    //获取生成签名的数据
    NSString *sign = data[@"sign"];
    NSString *signElements = data[@"data"];
    //NSString *pay_result = signElements[@"pay_result"];
    //NSString *tn = signElements[@"tn"];
    //转换服务器签名数据
    NSData *nsdataFromBase64String = [[NSData alloc]
                                      initWithBase64EncodedString:sign options:0];
    //生成本地签名数据，并生成摘要
//    NSString *mySignBlock = [NSString stringWithFormat:@"pay_result=%@tn=%@",pay_result,tn];
    NSData *dataOriginal = [[self sha1:signElements] dataUsingEncoding:NSUTF8StringEncoding];
    //验证签名
    //TODO：此处如果是正式环境需要换成public_product.key
    NSString *pubkey =[self readPublicKey:@"public_test.key"];
    OSStatus result=[RSA verifyData:dataOriginal sig:nsdataFromBase64String publicKey:pubkey];



    //签名验证成功，商户app做后续处理
    if(result == 0) {
        //支付成功且验签成功，展示支付成功提示
        return YES;
    }
    else {
        //验签失败，交易结果数据被篡改，商户app后台查询交易结果
        return NO;
    }

    return NO;
}

- (NSString *) readPublicKey:(NSString *) keyName
{
    if (keyName == nil || [keyName isEqualToString:@""]) return nil;
    
    NSMutableArray *filenameChunks = [[keyName componentsSeparatedByString:@"."] mutableCopy];
    NSString *extension = filenameChunks[[filenameChunks count] - 1];
    [filenameChunks removeLastObject]; // remove the extension
    NSString *filename = [filenameChunks componentsJoinedByString:@"."]; // reconstruct the filename with no extension
    
    NSString *keyPath = [[NSBundle mainBundle] pathForResource:filename ofType:extension];
    
    NSString *keyStr = [NSString stringWithContentsOfFile:keyPath encoding:NSUTF8StringEncoding error:nil];
    
    return keyStr;
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    
    return  [WXApi handleOpenURL:url delegate:self];
    
}
//iOS 9.0之后方法
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
            
        }];
    }
    return [WXApi handleOpenURL:url delegate:self];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (NSString*)sha1:(NSString *)string
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_CTX context;
    NSString *description;
    
    CC_SHA1_Init(&context);
    
    memset(digest, 0, sizeof(digest));
    
    description = @"";
    
    
    if (string == nil)
    {
        return nil;
    }
    
    // Convert the given 'NSString *' to 'const char *'.
    const char *str = [string cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Check if the conversion has succeeded.
    if (str == NULL)
    {
        return nil;
    }
    
    // Get the length of the C-string.
    int len = (int)strlen(str);
    
    if (len == 0)
    {
        return nil;
    }
    
    
    if (str == NULL)
    {
        return nil;
    }
    
    CC_SHA1_Update(&context, str, len);
    
    CC_SHA1_Final(digest, &context);
    
    description = [NSString stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   digest[ 0], digest[ 1], digest[ 2], digest[ 3],
                   digest[ 4], digest[ 5], digest[ 6], digest[ 7],
                   digest[ 8], digest[ 9], digest[10], digest[11],
                   digest[12], digest[13], digest[14], digest[15],
                   digest[16], digest[17], digest[18], digest[19]];
    
    return description;
}

@end
