#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import "Common.h"
#endif

/**
 视频设备类
 */
@interface WSTVideoDevice : NSObject

@property (nonatomic, readonly) NSString *deviceID;
@property (nonatomic, assign) BOOL isOpened;

- (instancetype)initWithID:(NSString *)deviceID;

@end

/**
 用户类型
 */
typedef NS_ENUM(NSInteger, WSTUserType) {
    WSTUserTypeMe = 0,
    WSTUserTypeRemoteUser,
    WSTUserTypeAnchor
};

/**
 用户类
 */
@interface WSTUser : NSObject

@property (nonatomic, readonly) long long sessionID;
@property (nonatomic, readonly) long long userID;
@property (nonatomic, readonly) NSString *userName;
@property (nonatomic, readonly) WSTUserType userType;
@property (nonatomic, readonly) BOOL isMe;
@property (nonatomic, assign) BOOL isHost;
#if TARGET_OS_IOS
@property (nonatomic, assign) PERMISSION_STATUS speakStatus;
#endif
@property (nonatomic, readonly) NSMutableArray<WSTVideoDevice *> *deviceArray;

- (instancetype)initWithSessionID:(long long)sessionID userID:(long long)userID userType:(WSTUserType)userType
                             isMe:(BOOL)isMe isHost:(BOOL)isHost;

- (WSTVideoDevice *)defaultVideoDevice;

- (WSTVideoDevice *)videoDeviceWithID:(NSString *)deviceID;

@end
