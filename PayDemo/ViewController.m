//
//  ViewController.m
//  PayDemo
//
//  Created by 李金柱 on 16/4/21.
//  Copyright © 2016年 likeme. All rights reserved.
//

#import "ViewController.h"
#import "Order.h"
#import "DataSigner.h"
#import "Product.h"
#import "payRequsestHandler.h"

@interface ViewController ()
- (IBAction)alipayEvent:(id)sender;
- (IBAction)wxpayEvent:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)alipayEvent:(id)sender {
    /*
     *点击获取prodcut实例并初始化订单信息
     */
    Product *product = [[Product alloc]init];
    product.body = [self getTimestamp];
    product.price = 1;
    product.subject = @"测试";
    
    /*
     *商户的唯一的parnter和seller。
     *签约后，支付宝会为每个商户分配一个唯一的 parnter 和 seller。
     */
    
    /*======================================================*/
    /*================需要填写商户app申请的=====================*/
    /*=======================================================*/
    NSString *partner = @"";//支付宝商户号（身份ID）
    NSString *seller  = @"";//商户支付宝账号
    NSString *privateKey = @"";//商户私钥

    //partner和seller获取失败,提示
    if ([partner length] == 0 ||
        [seller length] == 0 ||
        [privateKey length] == 0)
    {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"缺少partner或者seller或者私钥。"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
    order.partner = partner;//合作者身份ID 必需
    order.seller  = seller;//支付宝账户 必需
    order.tradeNO = [self getTimestamp]; //订单ID（由商家自行制定）必需
    order.productName = @"测试"; //商品标题 必需
    order.productDescription = @"支付宝demo"; //商品描述 必需
    order.amount = [NSString stringWithFormat:@"%.2f",0.01]; //商品价格 必需
    order.notifyURL =  @""; //回调URL支付宝服务器主动通知商户网站里指定的页面http路径 必需
    
    order.service = @"mobile.securitypay.pay";//接口名称 固定值 必需
    order.paymentType = @"1";//支付类型 默认为1（商品购买）必需
    order.inputCharset = @"utf-8";//参数编码字符集 固定值 必需
    order.itBPay = @"30m";//未付款交易的超时时间
    order.showUrl = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = ALiAppId;
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign_type=\"%@\"&sign=\"%@\"",
                       orderSpec, @"RSA", signedString];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"comfirmOrder reslut = %@",resultDic);
            NSString *resultStatus = resultDic[@"resultStatus"];
            NSString *message = nil;
            if ([resultStatus isEqualToString:@"9000"]) {
                message = @"订单支付成功";
               
            }else if ([resultStatus isEqualToString:@"8000"]) {
                message = @"正在处理中";
            }else if ([resultStatus isEqualToString:@"4000"]){
                message = @"订单支付失败";
            }else if ([resultStatus isEqualToString:@"6001"]){
                message = @"支付取消";
                
            }else if ([resultStatus isEqualToString:@"6002"]){
                message = @"网络连接错误";
            }else{
                message = @"未知错误";
            }
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付结果" message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
            [alert show];
        }];
        
        
    }

}
//时间戳作为订单编号
- (NSString *)getTimestamp{
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    [dateFormatter setLocale:[[NSLocale alloc]initWithLocaleIdentifier:@"zh_CN"]];
    
    return [dateFormatter stringFromDate:today];
    
}

- (IBAction)wxpayEvent:(id)sender {
    
    if (![[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"weixin://"]]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您未安装微信请选择其他支付方式" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
//        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"您未安装微信请选择其他支付方式" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
//        [alert show];
        return;
    }
 
        //创建支付签名对象
        payRequsestHandler *req = [payRequsestHandler alloc];
        //初始化支付签名对象
        [req init:APP_ID mch_id:MCH_ID];
        //设置密钥
        [req setKey:PARTNER_ID];
        
        NSString *orderId = [self getTimestamp];
        
        //获取到实际调起微信支付的参数后，在app端调起支付
        // ordernum订单标题  orderid 订单编号
        NSMutableDictionary *dict = [req sendPayWithOrderName:@"测试" AndOrderPrice:@"1" AndToken:@"12" AndOrderId:orderId AndNotifyUrl:@"FZ"];
        if(dict == nil){
            //错误提示
            NSString *debug = [req getDebugifo];
            NSLog(@"%@\n\n",debug);
        }else{
            NSLog(@"%@\n\n",[req getDebugifo]);
            //[self alert:@"确认" msg:@"下单成功，点击OK后调起支付！"];
            NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
            
            //调起微信支付
            PayReq* req             = [[PayReq alloc] init];
            req.openID              = [dict objectForKey:@"appid"];
            req.partnerId           = [dict objectForKey:@"partnerid"];
            req.prepayId            = [dict objectForKey:@"prepayid"];
            req.nonceStr            = [dict objectForKey:@"noncestr"];
            req.timeStamp           = stamp.intValue;
            req.package             = [dict objectForKey:@"package"];
            req.sign                = [dict objectForKey:@"sign"];
            
            [WXApi sendReq:req];
        }

    
}


@end
