//
//  ViewController.m
//  PayDemo
//
//  Created by 李金柱 on 16/4/21.
//  Copyright © 2016年 likeme. All rights reserved.
//

#import <PassKit/PassKit.h>
#import "ViewController.h"
#import "Order.h"
#import "DataSigner.h"
#import "Product.h"
#import "payRequsestHandler.h"
#import "UPPaymentControl.h"


#define kVCTitle          @"商户测试"
#define kBtnFirstTitle    @"获取订单，开始测试"
#define kWaiting          @"正在获取TN,请稍后..."
#define kNote             @"提示"
#define kConfirm          @"确定"
#define kErrorNet         @"网络错误"
#define kResult           @"支付结果：%@"


#define kMode_Development             @"01"
#define kURL_TN_Normal                @"http://101.231.204.84:8091/sim/getacptn"
#define kURL_TN_Configure             @"http://101.231.204.84:8091/sim/app.jsp?user=123456789"

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>
{
    UIAlertView* _alertView;
    NSMutableData* _responseData;
    CGFloat _maxWidth;
    CGFloat _maxHeight;
    
    UITextField *_urlField;
    UITextField *_modeField;
    UITextField *_curField;
    
    NSMutableArray *_summaryItemsArray;
    NSMutableArray *_shippingMethodsArray;
}
@property(nonatomic, copy)NSString *tnMode;


- (IBAction)alipayEvent:(id)sender;
- (IBAction)wxpayEvent:(id)sender;
- (IBAction)unionPayEvent:(id)sender;
- (IBAction)applePayEvent:(id)sender;

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

- (IBAction)unionPayEvent:(id)sender {
    self.tnMode = kMode_Development;
    [self startNetWithURL:[NSURL URLWithString:kURL_TN_Normal]];
}

- (IBAction)applePayEvent:(id)sender {
    
    if([PKPaymentAuthorizationViewController canMakePayments]) {//判断是否支持ApplePay
        
        if ([PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:@[PKPaymentNetworkChinaUnionPay, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]] ) {//判断是否已经绑定银行卡(银联卡，万事达卡，visa卡)
            
            NSLog(@"可以使用Applepay");
            
            PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
            
            PKPaymentSummaryItem *goods = [PKPaymentSummaryItem summaryItemWithLabel:@"修身小马甲"
                                                                              amount:[NSDecimalNumber decimalNumberWithString:@"698.00"]];
            
            PKPaymentSummaryItem *goods1 = [PKPaymentSummaryItem summaryItemWithLabel:@"无敌风火轮"
                                                                               amount:[NSDecimalNumber decimalNumberWithString:@"998.00"]];
            
            PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"杭州像我一样科技有限公司"
                                                                              amount:[NSDecimalNumber decimalNumberWithString:@"0.11"]];
            
            _summaryItemsArray = [NSMutableArray arrayWithArray:@[goods, goods1, total]];
            
            request.paymentSummaryItems = _summaryItemsArray;
            request.countryCode = @"CN";//中国 国家代码
            request.currencyCode = @"CNY";//货币代码
            request.supportedNetworks = @[PKPaymentNetworkChinaUnionPay, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];
            request.merchantIdentifier = @"merchant.com.likeme.DesignerLikeMe";
            request.merchantCapabilities =  PKMerchantCapabilityEMV;
            
            
            //
            //            request.requiredShippingAddressFields = PKAddressFieldPostalAddress|PKAddressFieldPhone|PKAddressFieldName;
            //            //送货地址信息，这里设置需要地址和联系方式和姓名，如果需要进行设置，默认PKAddressFieldNone(没有送货地址)
            //            //设置两种配送方式
            //            PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"包邮" amount:[NSDecimalNumber zero]];
            //            freeShipping.identifier = @"freeshipping";
            //            freeShipping.detail = @"6-8 天 送达";
            //
            //            PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"极速送达" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
            //            expressShipping.identifier = @"expressshipping";
            //            expressShipping.detail = @"2-3 小时 送达";
            //
            //            _shippingMethodsArray = [NSMutableArray arrayWithArray:@[freeShipping, expressShipping]];
            //            //shippingMethods为配送方式列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行配送方式的调整。
            //            request.shippingMethods = _shippingMethodsArray;
            //
            //
            
            
            PKPaymentAuthorizationViewController *paymentPane = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
            paymentPane.delegate = self;
            [self presentViewController:paymentPane animated:YES completion:nil];
        }else{//未绑卡 前往wallet绑卡
            
            PKPassLibrary *library = [[PKPassLibrary alloc]init];
            [library openPaymentSetup];
        }
        
        
    } else {
        
        NSLog(@"设备不支持ApplePay");
    }
    

    
}
- (void)startNetWithURL:(NSURL *)url
{
    [_curField resignFirstResponder];
    _curField = nil;
    [self showAlertWait];
    
    NSURLRequest * urlRequest=[NSURLRequest requestWithURL:url];
    NSURLConnection* urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [urlConn start];
}
- (void)showAlertWait
{
    [self hideAlert];
    _alertView = [[UIAlertView alloc] initWithTitle:kWaiting message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
    [_alertView show];
    UIActivityIndicatorView* aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    aiv.center = CGPointMake(_alertView.frame.size.width / 2.0f - 15, _alertView.frame.size.height / 2.0f + 10 );
    [aiv startAnimating];
    [_alertView addSubview:aiv];
    
}
- (void)hideAlert
{
    if (_alertView != nil)
    {
        [_alertView dismissWithClickedButtonIndex:0 animated:NO];
        _alertView = nil;
    }
   
}

#pragma
#pragma  mark =================connection=================

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response
{
    NSHTTPURLResponse* rsp = (NSHTTPURLResponse*)response;
    NSInteger code = [rsp statusCode];
    if (code != 200)
    {
        
        [self showAlertMessage:kErrorNet];
        [connection cancel];
    }
    else
    {
        
        _responseData = [[NSMutableData alloc] init];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self hideAlert];
    NSString* tn = [[NSMutableString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    if (tn != nil && tn.length > 0)
    {
        
        NSLog(@"tn=%@",tn);
        [[UPPaymentControl defaultControl] startPay:tn fromScheme:@"PayDemo" mode:self.tnMode viewController:self];
        
    }
    
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self showAlertMessage:kErrorNet];
}
- (void)showAlertMessage:(NSString*)msg
{
    [self hideAlert];
    _alertView = [[UIAlertView alloc] initWithTitle:kNote message:msg delegate:self cancelButtonTitle:kConfirm otherButtonTitles:nil, nil];
    
}
#pragma
#pragma  mark =================paymentAuthorizationViewControllerDelegate=================
//必须实现的两个代理
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion{
    NSLog(@"支付已授权: payment%@", payment);
    BOOL asyncSuccessful = NO;
    
    //    PKPaymentToken *payToken = payment.token;
    //    //支付凭据，发给服务端进行验证支付是否真实有效
    //    PKContact *billingContact = payment.billingContact;     //账单信息
    //    PKContact *shippingContact = payment.shippingContact;   //送货信息
    //
    //    NSLog(@"payToken:%@ billingContact:%@ shippingContact:%@",payToken,billingContact,shippingContact);
    //等待服务器返回结果后再进行系统block调用
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        //模拟服务器通信
    //        completion(PKPaymentAuthorizationStatusSuccess);
    //    });
    
    
    //授权状态
    //    PKPaymentAuthorizationStatusSuccess, // Merchant auth'd (or expects to auth) the transaction successfully. //授权成功
    //    PKPaymentAuthorizationStatusFailure, // Merchant failed to auth the transaction.   //授权失败
    //
    //    PKPaymentAuthorizationStatusInvalidBillingPostalAddress,  // Merchant refuses service to this billing address.//无效的账单地址
    //    PKPaymentAuthorizationStatusInvalidShippingPostalAddress, // Merchant refuses service to this shipping address.//无效的邮寄地址
    //    PKPaymentAuthorizationStatusInvalidShippingContact        // Supplied contact information is insufficient.//无效的联系方式 信息不足
    
    if(asyncSuccessful) {
        completion(PKPaymentAuthorizationStatusSuccess);
        
        NSLog(@"===支付成功===%@",completion);//处理支付成功后的逻辑
        
    } else {
        completion(PKPaymentAuthorizationStatusFailure);
        
        NSLog(@"===支付失败===:%@",completion);//处理支付失败的逻辑
        
    }
    
    
}
-(void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller{
    
    NSLog(@"支付结束");
    
    // 隐藏支付控制器
    [controller dismissViewControllerAnimated:YES completion:nil];
}
////选择实现的代理方法
//- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
//                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
//                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems))completion{
////    //配送方式回调，如果需要根据不同的送货方式进行支付金额的调整，比如包邮和付费加速配送，可以实现该代理
////    PKShippingMethod *oldShippingMethod = [_summaryItemsArray objectAtIndex:2];
////    PKPaymentSummaryItem *total = [_summaryItemsArray lastObject];
////    total.amount = [total.amount decimalNumberBySubtracting:oldShippingMethod.amount];
////    total.amount = [total.amount decimalNumberByAdding:shippingMethod.amount];
////
////    completion(PKPaymentAuthorizationStatusSuccess, _summaryItemsArray);
//
//}
//- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
//                  didSelectShippingContact:(PKContact *)contact
//                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods,
//                                                     NSArray<PKPaymentSummaryItem *> *summaryItems))completion{
//    //contact送货地址信息，PKContact类型
//
//
//}
//- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
//    //支付银行卡回调，如果需要根据不同的银行调整付费金额，可以实现该代理
//  
//}


@end
