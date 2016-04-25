//
//  payRequsestHandler.h
//  PayDemo
//
//  Created by 李金柱 on 16/4/21.
//  Copyright © 2016年 likeme. All rights reserved.
//

#import <Foundation/Foundation.h>

#define APP_ID          @""               //APPID

#define APP_SECRET      @"" //appsecret

//商户号，填写商户对应参数

#define MCH_ID          @""

//商户API密钥，填写相应参数

#define PARTNER_ID      @""

//服装订单支付结果回调页面
#define FZ_NOTIFY_URL      @"http://zc.like-me.cn/mobile/cart/wechat_notify"

//众筹订单支付结果回调页面
#define ZC_NOTIFY_URL      @""

//获取服务器端支付数据地址（商户自定义）
#define SP_URL          @"http://wxpay.weixin.qq.com/pub_v2/app/app_pay.php"

@interface payRequsestHandler : NSObject{
    //预支付网关url地址
    NSString *payUrl;
    
    //lash_errcode;
    long     last_errcode;
    //debug信息
    NSMutableString *debugInfo;
    NSString *appid,*mchid,*spkey;
}
//初始化函数
-(BOOL) init:(NSString *)app_id mch_id:(NSString *)mch_id;
-(NSString *) getDebugifo;
-(long) getLasterrCode;
//设置商户密钥
-(void) setKey:(NSString *)key;
//创建package签名
-(NSString*) createMd5Sign:(NSMutableDictionary*)dict;
//获取package带参数的签名包
-(NSString *)genPackage:(NSMutableDictionary*)packageParams;
//提交预支付
-(NSString *)sendPrepay:(NSMutableDictionary *)prePayParams;
//签名实例测试
- ( NSMutableDictionary *)sendPayWithOrderName:(NSString *)orderName AndOrderPrice:(NSString *)orderPrice AndToken:(NSString *)token AndOrderId:(NSString *)orderId AndNotifyUrl:(NSString *)notifyUrlType;

@end
