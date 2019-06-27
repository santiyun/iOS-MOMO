#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MyVideoApi.h"
#import "MyAudioApi.h"
#import "WSTUser.h"
#import "UserVideoControl.h"

#import <ReplayKit/ReplayKit.h>

@interface LiveRoomViewController : UIViewController <EnterConfApiDelegate, VideoStatReportDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate, ExtAudioProcessDelegate, RPBroadcastActivityViewControllerDelegate>

@property (assign, nonatomic) NSString* logMsg;

- (void)prepareHideToolbar;

- (void)switchOpenUser:(WSTUser *)user videoDevice:(WSTVideoDevice *)videoDevice completion:(void (^)(void))completion;

- (void)linkOtherAnchor:(long long)sessionID userID:(long long)userID;

- (void)switchCamera;

- (UserVideoControl *)getAnchorUserVideoControl:(long long)userID;

@end
