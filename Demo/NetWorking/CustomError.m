//
//  CustomError.m
//  WSTDemo
//
//  Created by 小小白 on 2017/10/18.
//  Copyright © 2017年 wushuangtech. All rights reserved.
//

#import "CustomError.h"

@implementation CustomError
{
    NSString* _localizedDescription;
}


- (id)initWithDomain:(NSString *)domain
                code:(NSInteger)code
            userInfo:(NSDictionary *)userInfo
localizedDescription:(NSString *)localizedDescription {
    self = [super initWithDomain:domain code:code userInfo:userInfo];
    [self setLocalizedDescription:localizedDescription];
    return self;
}

- (void)setLocalizedDescription:(NSString*)desc {
    _localizedDescription = desc;
}

- (NSString*)localizedDescription {
    return _localizedDescription;
}









@end
