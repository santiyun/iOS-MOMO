#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "WSTUser.h"

@interface Application : NSObject

+ (Application *)sharedInstance;

#if TARGET_OS_IOS
+ (UIInterfaceOrientationMask)supportedInterfaceOrientations;

+ (void)showAlert:(UIViewController *)viewController message:(NSString *)messageText;
#else
+ (void)showAlert:(NSWindow *)window messageText:(NSString *)messageText informativeText:(NSString *)informativeText;
#endif

@property (nonatomic, readonly) NSString *logFileName;
@property (nonatomic, strong) NSFileHandle *logFileHandle;
@property (nonatomic, assign) BOOL isOnlyAudio;
@property (nonatomic, assign) BOOL isLiveRoom;
@property (nonatomic, assign) WSTUser *userMe;
@property (nonatomic, assign) WSTUser *userHost;
@property (nonatomic, readonly) NSMutableArray<WSTUser *> *userArray;

- (WSTUser *)userWithIndex:(NSInteger)index;
- (WSTUser *)userWithUserID:(long long)userID;
- (WSTUser *)userWithDeviceID:(NSString *)deviceID;

@end

#define app                 [Application sharedInstance]
#define enterConfApi        [EnterConfApi sharedInstance]
#define myVideoApi          [MyVideoApi sharedInstance]
#define myAudioApi          [MyAudioApi sharedInstance]
#define externalVideoModule [ExternalVideoModule sharedInstance]
#define externalAudioModule [ExternalAudioModule sharedInstance]
