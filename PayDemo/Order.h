//
//  Order.h
//  PayDemo
//
//  Created by 李金柱 on 16/4/21.
//  Copyright © 2016年 likeme. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Order : NSObject

@property(nonatomic, copy) NSString * partner;//合作者ID 必需
@property(nonatomic, copy) NSString * seller;//支付宝账户 必需
@property(nonatomic, copy) NSString * tradeNO;//订单ID 必需
@property(nonatomic, copy) NSString * productName;//商品标题 必需
@property(nonatomic, copy) NSString * productDescription; //商品描述 必需
@property(nonatomic, copy) NSString * amount;//商品价格 必需
@property(nonatomic, copy) NSString * notifyURL;//回调URL支付宝服务器主动通知商户网站里指定的页面http路径 必需

@property(nonatomic, copy) NSString * service;//接口名称 固定值 必需
@property(nonatomic, copy) NSString * paymentType;//支付类型 默认为1（商品购买）必需
@property(nonatomic, copy) NSString * inputCharset;//参数编码字符集 固定值 必需
@property(nonatomic, copy) NSString * itBPay;//未付款交易的超时时间 非必需
@property(nonatomic, copy) NSString * showUrl;


@property(nonatomic, copy) NSString * rsaDate;//可选
@property(nonatomic, copy) NSString * appID;//可选 客户端号

@property(nonatomic, readonly) NSMutableDictionary * extraParams;

@end
