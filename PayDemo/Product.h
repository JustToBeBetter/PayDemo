//
//  Product.h
//  PayDemo
//
//  Created by 李金柱 on 16/4/21.
//  Copyright © 2016年 likeme. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Product : NSObject
{
    NSInteger _price;
    NSString *_subject;
    NSString *_body;
    NSString *_orderId;
}

@property (nonatomic, assign)NSInteger price;
@property (nonatomic, copy)  NSString *subject;
@property (nonatomic, copy)  NSString *body;
@property (nonatomic, copy)  NSString *orderId;
@end
