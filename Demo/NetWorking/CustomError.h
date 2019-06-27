//
//  CustomError.h
//  WSTDemo
//
//  Created by 小小白 on 2017/10/18.
//  Copyright © 2017年 wushuangtech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomError : NSError

- (id)initWithDomain:(NSString *)domain
                code:(NSInteger)code
            userInfo:(NSDictionary *)userInfo
localizedDescription:(NSString*)localizedDescription;


@end
