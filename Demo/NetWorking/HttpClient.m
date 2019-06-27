//
//  HttpClient.m
//  WSTDemo
//
//  Created by 小小白 on 2017/10/18.
//  Copyright © 2017年 wushuangtech. All rights reserved.
//

#import "HttpClient.h"

@interface HttpClient()


@end

@implementation HttpClient

+(void)getTokenFromServerWithUserID:(NSString *)userid ChannelID:(NSString *)channelid AppID:(NSString*)appid
                            success:(void(^)(NSString *msg))success
                            failure:(void(^)(NSError *reqError))failure
{
    if (userid.length == 0)
    {
        CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"用户id不能为空"];
        failure(error);
    }
    else if (channelid.length == 0)
    {
        CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"会议id不能为空"];
        failure(error);
    }
    else
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.usercenter.wushuangtech.com/token.php?userid=%@&channelid=%@&appkey=%@",userid,channelid,appid]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (data != nil)
            {
                NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                NSLog(@"get token____%@",dataDic);
                NSString *code = dataDic[@"code"];
                NSString *token = dataDic[@"data"];
                //if (code.intValue == 0)
                {
                    success(token);
                }
            }
            else
            {
                success(nil);
            }
        }];
        
        [sessionDataTask resume];
        
    }
}

+(void)checkTokenFromServerWithToken:(NSString *)token
                              UserID:(NSString *)userid
                           ChannelID:(NSString *)channelid
                              AppKey:(NSString *)appkey
                             success:(void(^)(NSString *token))success
                             failure:(void(^)(NSError *reqError))failure
{
    if (token.length == 0)
    {
        CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"token不能为空"];
        failure(error);
    }
    else if (userid.length == 0)
    {
        CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"用户id不能为空"];
        failure(error);
    }
    else if (channelid.length == 0)
    {
        CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"会议id不能为空"];
        failure(error);
    }
    else if (appkey.length == 0)
    {
        CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"appkey不能为空"];
        failure(error);
    }
    else
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.usercenter.wushuangtech.com/verify.php?token=%@&userid=%@&channelid=%@&appkey=%@",token,userid,channelid,appkey]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSURLSession *session = [NSURLSession sharedSession];
        
        NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            
            NSLog(@"鉴权token____%@",dataDic);
            NSString *code = dataDic[@"code"];
            if (code.intValue == 0)
            {
                NSString *tokenStr = [NSString stringWithFormat:@"%@",dataDic[@"data"][@"token"]];
                success(tokenStr);
            }
            else if(code.intValue == 1)
            {
                CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"鉴权失败"];
                failure(error);
            }
            else if(code.intValue == -1)
            {
                CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"参数异常"];
                failure(error);
            }
            else if(code.intValue == -2)
            {
                CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"token过期"];
                failure(error);
            }
            else if(code.intValue == -4)
            {
                CustomError *error = [[CustomError alloc]initWithDomain:@"" code:10000 userInfo:nil localizedDescription:@"刷新token失败"];
                failure(error);
            }
            
            
            if (error)
            {
                failure(error);
            }
        }];
        
        [sessionDataTask resume];
        
    }
    
}



+(NSString*)encodeString:(NSString*)unencodedString
{
    
    // CharactersToBeEscaped = @":/?&=;+!@#$()~',*";
    
    // CharactersToLeaveUnescaped = @"[].";
    
    NSString*encodedString=(NSString*)
    
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              
                                                              (CFStringRef)unencodedString,
                                                              
                                                              NULL,
                                                              
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              
                                                              kCFStringEncodingUTF8));
    
    return encodedString;
    
}


+(NSString*)decodeString:(NSString*)encodedString

{
    
    //NSString *decodedString = [encodedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    
    NSString*decodedString=(__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                               
                                                                                                               (__bridge CFStringRef)encodedString,
                                                                                                               
                                                                                                               CFSTR(""),
                                                                                                               
                                                                                                               CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    return decodedString;
    
}



















@end
