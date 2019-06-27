//
//  HttpClient.h
//  WSTDemo
//
//  Created by 小小白 on 2017/10/18.
//  Copyright © 2017年 wushuangtech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomError.h"
@interface HttpClient : NSObject


/**
 获取token

 @param userid 用户id
 @param channelid 会议id
 @param success 成功
 @param failure 失败
 */
+(void)getTokenFromServerWithUserID:(NSString *)userid ChannelID:(NSString *)channelid AppID:(NSString*)appid
                            success:(void(^)(NSString *msg))success
                            failure:(void(^)(NSError *reqError))failure;





/**
 鉴权token有效期

 @param token 从服务器获取的token
 @param userid 用户id
 @param channelid 会议id
 @param appkey 应用的appkey
 @param success 成功
 @param failure 失败
 */
+(void)checkTokenFromServerWithToken:(NSString *)token
                              UserID:(NSString *)userid
                           ChannelID:(NSString *)channelid
                              AppKey:(NSString *)appkey
                             success:(void(^)(NSString *token))success
                             failure:(void(^)(NSError *reqError))failure;



/**
 urlencode

 @param unencodedString 需要urlcode的字符串
 @return 返回值
 */
+(NSString*)encodeString:(NSString*)unencodedString;




/**
 urldecode

 @param encodedString
 @return 
 */
+(NSString*)decodeString:(NSString*)encodedString;















@end
