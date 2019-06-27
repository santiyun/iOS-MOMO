#import "WSTUser.h"

/**
 视频设备类
 */
@implementation WSTVideoDevice

- (instancetype)initWithID:(NSString *)deviceID {
    self = [super init];
    if (self) {
        _deviceID = deviceID;
        _isOpened = NO;
    }
    return self;
}

@end

/**
 用户类
 */
@implementation WSTUser

- (instancetype)initWithSessionID:(long long)sessionID userID:(long long)userID userType:(WSTUserType)userType
                             isMe:(BOOL)isMe isHost:(BOOL)isHost {
    self = [super init];
    if (self) {
        _sessionID = sessionID;
        _userID = userID;
        _userType = userType;
        _isMe = isMe;
        _isHost = isHost;
        #if TARGET_OS_IOS
        _speakStatus = PERMISSION_STATUS_NORMAL;
        #endif
        _deviceArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)userName {
    return [NSString stringWithFormat:@"%lld", self.userID];
}

- (WSTVideoDevice *)defaultVideoDevice {
    return self.deviceArray[0];
}

- (WSTVideoDevice *)videoDeviceWithID:(NSString *)deviceID {
    for (WSTVideoDevice *videoDevice in self.deviceArray) {
        if ([videoDevice.deviceID isEqualToString:deviceID]) {
            return videoDevice;
        }
    }
    return nil;
}

@end
