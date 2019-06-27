#import "LiveRoomViewController.h"
#import "SVProgressHUD.h"
#import "Application.h"
#import "UserVideoContainer.h"
#import "AudioMixingViewController.h"
//#import <facekit/facekit.h>
//#import "GPUImage.h"

#define app_Key     @"test900572e02867fab8131651339518"

@interface LiveRoomViewController () <UIPopoverPresentationControllerDelegate, UserVideoControlDelegate,
    AudioMixingViewControllerDelegate, AudioFileMixStatusDelegate>

@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainerHost;
@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainer1;
@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainer2;
@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainer3;
@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainer4;
@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainer5;
@property (weak, nonatomic) IBOutlet UserVideoContainer *userVideoContainer6;



@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *statsInfoView;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoSend;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoRecv;
@property (weak, nonatomic) IBOutlet UILabel *lblAudioSend;
@property (weak, nonatomic) IBOutlet UILabel *lblAudioRecv;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoEncoded;
@property (weak, nonatomic) IBOutlet UILabel *lblAudioEncoded;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintTrailing1;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintTrailing2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintTrailing3;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintStatsInfoTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintStatsInfoTrailing;
@property (weak, nonatomic) IBOutlet UITextView *logMsgView;
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
@property (weak, nonatomic) IBOutlet UISlider *musicProgressSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *volumeScaleLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeScaleSlider;

@property (strong, nonatomic) RPBroadcastController *broadcastVC;

@end

@implementation LiveRoomViewController
{
    BOOL _viewDidAppeared;
    BOOL _viewDidDisappeared;
    BOOL bFullScreen;
    BOOL _videoPaused;
    BOOL isBack;
    NSMutableArray<UserVideoContainer *> *_userVideoContainers;
    NSMutableArray<UserVideoControl *> *_userVideoControls;
    NSTimer *_statsTimer;
    int _lastVideoSendBytes, _lastVideoRecvBytes;
    int _lastAudioSendBytes, _lastAudioRecvBytes;
    int _lastVideoEncoded, _lastAudioEncoded;
    
    //LMRenderEngine *renderEngine;
    
    CGPoint _sourceCenter;
    CGRect _sourceFrame;
    UserVideoControl *_targetControl;
    NSString *_musicFileName;
    BOOL _isMusicSliderBeingDragged;
}
-(void)dealloc {
    //2018-06-20 14:53:00.727366+0800 WSTDemo[6740:2023609] leaveRoom -- Start
    //2018-06-20 14:53:25.563867+0800 WSTDemo[6740:2023609] LiveRoom dealloc
    NSLog(@"LiveRoom dealloc");
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _viewDidAppeared = NO;
    _viewDidDisappeared = NO;
    enterConfApi.enterConfApiDelegate = self;
    [myVideoApi setVideoStatReportDelegate:self];
    [myAudioApi setAudioFileMixStatusDelegate:self];
    [myAudioApi setExternalAudioProcessDelegate:self];
    
    isBack = NO;
    //
    
    _userVideoContainers = [[NSMutableArray alloc] init];
    
    [_userVideoContainers addObject:self.userVideoContainer1];
    [_userVideoContainers addObject:self.userVideoContainer2];
    [_userVideoContainers addObject:self.userVideoContainer3];
    [_userVideoContainers addObject:self.userVideoContainer4];
    [_userVideoContainers addObject:self.userVideoContainer5];
    [_userVideoContainers addObject:self.userVideoContainer6];
    
    [_userVideoContainers addObject:self.userVideoContainerHost];

    _userVideoControls = [[NSMutableArray alloc] init];
    for (UserVideoContainer *userVideoContainer in _userVideoContainers) {
        [_userVideoControls addObject:userVideoContainer.userVideoControl];
        userVideoContainer.userVideoControl.delegate = self;
    }
    
    self.userVideoContainer1.userVideoControl.layoutConstraintTrailing = self.layoutConstraintTrailing1;
    self.userVideoContainer2.userVideoControl.layoutConstraintTrailing = self.layoutConstraintTrailing2;
    self.userVideoContainer3.userVideoControl.layoutConstraintTrailing = self.layoutConstraintTrailing3;
    
    _musicFileName = nil;
    
    _lastVideoSendBytes = 0;
    _lastVideoRecvBytes = 0;
    _lastAudioSendBytes = 0;
    _lastAudioRecvBytes = 0;
    _lastVideoEncoded = 0;
    _lastAudioEncoded = 0;
    _statsTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(statsTimerFired:) userInfo:nil repeats:YES];
    self.statsInfoView.layer.cornerRadius = 8;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self.statsInfoView setHidden:![userDefaults boolForKey:@"ShowStatsInfo"]];
    self.logMsgView.layer.cornerRadius = 8;
    [self.logMsgView setText:_logMsg];
    [self.logMsgView setHidden:![userDefaults boolForKey:@"ShowLogMsg"]];
    [userDefaults setBool:YES forKey:@"UploadVideo"];
    [userDefaults setBool:YES forKey:@"UploadAudio"];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onSwitchShowStatsInfo:) name:@"SwitchShowStatsInfo" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onSwitchShowLogMsg:) name:@"SwitchShowLogMsg" object:nil];
    
    if ([enterConfApi getRoomMode] != ROOM_MODE_LIVE
        && [enterConfApi getRoomMode] != ROOM_MODE_COMMUNICATION)
    {
        if (app.userMe.isHost || app.isOnlyAudio) {
            [enterConfApi applySpeakPermission:YES];
        }
    }
    
    [myVideoApi startPreview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self showToolbar];
}

- (void)onSwitchShowStatsInfo:(NSNotification *)notification {
    [self.statsInfoView setHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowStatsInfo"]];
}

- (void)onSwitchShowLogMsg:(NSNotification *)notification {
    [self.logMsgView setHidden:![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowLogMsg"]];
}

- (void)setAllVideoSEI {
    if (!app.userMe.isHost) {
        return;
    }
    
    NSMutableDictionary *seiDictionary = [[NSMutableDictionary alloc] init];
    // ver
    [seiDictionary setValue:@"20161020" forKey:@"ver"];
    // ts
    long ts = [[NSDate date] timeIntervalSince1970] * 1000;
    [seiDictionary setValue:[NSNumber numberWithLong:ts] forKey:@"ts"];
    // mid
    [seiDictionary setValue:app.userHost.defaultVideoDevice.deviceID forKey:@"mid"];
    // canvas
//    int encWidth, encHeight;
//    [externalVideoModule getEncodeWidth:&encWidth height:&encHeight];
    int encWidth = 352;
    int encHeight = 640;
    NSMutableDictionary *canvasDictionary = [[NSMutableDictionary alloc] init];
    [canvasDictionary setValue:[NSNumber numberWithInt:encWidth] forKey:@"w"];
    [canvasDictionary setValue:[NSNumber numberWithInt:encHeight] forKey:@"h"];
    [canvasDictionary setValue:[NSArray arrayWithObjects:@(80), @(80), @(80), nil] forKey:@"bgrgb"];
    [seiDictionary setValue:canvasDictionary forKey:@"canvas"];
    // pos
    NSMutableArray *posArray = [[NSMutableArray alloc] init];
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.user == nil) {
            continue;
        }
        
        /*
        if (userVideoControl.user.userID == app.userMe.userID) {
            GSVideoConfig videoConfig = [myVideoApi getVideoConfig];
            if (userVideoControl.isHuge) {
                videoConfig.videoSize.width = 352;
                videoConfig.videoSize.height = 640;
                videoConfig.videoBitRate = 500*1000;
            } else {
                videoConfig.videoSize.width = 176;
                videoConfig.videoSize.height = 176;
                videoConfig.videoBitRate = 100*1000;
            }
            [myVideoApi setVideoConfig:videoConfig];
        }
         */
        
        NSMutableDictionary *posDictionary = [[NSMutableDictionary alloc] init];

        /*
        if (userVideoControl.user.userID == app.userMe.userID)
        {
            [posDictionary setValue:userVideoControl.videoDevice.deviceID forKey:@"id"];
            [posDictionary setValue:[NSNumber numberWithDouble:0.1] forKey:@"x"];
            [posDictionary setValue:[NSNumber numberWithDouble:0.1] forKey:@"y"];
            [posDictionary setValue:[NSNumber numberWithDouble:0.3] forKey:@"w"];
            [posDictionary setValue:[NSNumber numberWithDouble:0.3] forKey:@"h"];
            int posZ = 0;
            [posDictionary setValue:[NSNumber numberWithInt:posZ] forKey:@"z"];
        }
        else
         */
        {
            [posDictionary setValue:userVideoControl.videoDevice.deviceID forKey:@"id"];
            [posDictionary setValue:[NSNumber numberWithDouble:userVideoControl.subVideoPos.origin.x] forKey:@"x"];
            [posDictionary setValue:[NSNumber numberWithDouble:userVideoControl.subVideoPos.origin.y] forKey:@"y"];
            [posDictionary setValue:[NSNumber numberWithDouble:userVideoControl.subVideoPos.size.width] forKey:@"w"];
            [posDictionary setValue:[NSNumber numberWithDouble:userVideoControl.subVideoPos.size.height] forKey:@"h"];
            int posZ = userVideoControl.isHuge ? 0 : 1;
            [posDictionary setValue:[NSNumber numberWithInt:posZ] forKey:@"z"];
        }
        
        [posArray addObject:posDictionary];
    }
    [seiDictionary setValue:posArray forKey:@"pos"];
    
    if ([NSJSONSerialization isValidJSONObject:seiDictionary]) {
        NSError *error;
        NSData *seiData = [NSJSONSerialization dataWithJSONObject:seiDictionary options:NSJSONWritingPrettyPrinted error:&error];
        NSString *seiText = [[NSString alloc] initWithData:seiData encoding:NSUTF8StringEncoding];
        
        [enterConfApi setSei:seiText seiExt:@""];
    }
}

- (void)switchCamera {

    GSVideoConfig videoConfig = [myVideoApi getVideoConfig];
    videoConfig.enableFrontCam = !videoConfig.enableFrontCam;
    [myVideoApi setVideoConfig:videoConfig];
    
    // watermark
    /*(UIView* view = [[UIView alloc] initWithFrame:CGRectMake(100.0f, 200.0f, 128.0f, 128.0f)];
    [view setBackgroundColor:[UIColor redColor]];
    view.hidden = NO;
    view.alpha = 0.7;
    [myVideoApi setWaterMarkView:view];*/
    
    /*
    [myVideoApi setCuteProcessDelegate:self];
    
    
    LMRenderEngineOption option;
    option.faceless = NO;
    option.orientation = AVCaptureVideoOrientationPortrait;
    renderEngine = [LMRenderEngine engineForTextureWithGLContext:[LFGPUImageContext sharedImageProcessingContext].context queue:[LFGPUImageContext sharedContextQueue] option:option];
    
    NSBundle *resBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"LMEffectResource" ofType:@"bundle"]];
    NSString *sandboxPath = [resBundle pathForResource:@"effect/cat_ear" ofType:@""];
    LMFilterPos pos = [renderEngine applyWithPath:sandboxPath];
    printf("************************ [%d] *******************\n", pos);
     */
}

-(IBAction)changeFrontAndBackCam
{
    [self switchCamera];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return  UIStatusBarStyleLightContent;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    CGFloat screenwidth  = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat screenheight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    CGSize contentSize = CGSizeZero;
    if ([segue.identifier isEqualToString:@"LiveSettings"]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            segue.destinationViewController.modalPresentationStyle = UIModalPresentationPopover;
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                contentSize = CGSizeMake(screenwidth * 0.8, screenheight * 0.7);
            }
            else /* Landscape */ {
            }
        }
        else /* Pad */ {
            segue.destinationViewController.modalPresentationStyle = UIModalPresentationPopover;
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                contentSize = CGSizeMake(screenwidth * 0.5, screenheight * 0.55);
            }
            else /* Landscape */ {
                contentSize = CGSizeMake(screenwidth * 0.4, screenheight * 0.7);
            }
        }
    }
    else if ([segue.identifier isEqualToString:@"UserList"]
             || [segue.identifier isEqualToString:@"DebugSettings"]
             || [segue.identifier isEqualToString:@"AudioMixing"]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            segue.destinationViewController.modalPresentationStyle = UIModalPresentationPopover;
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                contentSize = CGSizeMake(screenwidth * 0.8, screenheight * 0.6);
            }
            else /* Landscape */ {
            }
        }
        else /* Pad */ {
            segue.destinationViewController.modalPresentationStyle = UIModalPresentationPopover;
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                contentSize = CGSizeMake(screenwidth * 0.5, screenheight * 0.55);
            }
            else /* Landscape */ {
                contentSize = CGSizeMake(screenwidth * 0.4, screenheight * 0.7);
            }
        }
    }
    //CGFloat heightWidth = MAX(CGRectGet Width([[UIScreen mainScreen] bounds]), CGRectGetHeight([[UIScreen mainScreen] bounds]));
    if (!CGSizeEqualToSize(contentSize, CGSizeZero)) {
        segue.destinationViewController.preferredContentSize = contentSize;
    }
    segue.destinationViewController.popoverPresentationController.barButtonItem = sender;
    segue.destinationViewController.popoverPresentationController.delegate = self;
    
    if ([segue.identifier isEqualToString:@"AudioMixing"]) {
        [[NSUserDefaults standardUserDefaults] setObject:_musicFileName forKey:@"SelectedMusicFileName"];
    }
    
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToolbar) object:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [Application supportedInterfaceOrientations];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
//    for (UIBarButtonItem *barButtonItem in self.toolbar.items) {
//        barButtonItem.enabled = (barButtonItem == popoverPresentationController.barButtonItem);
//    }
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
//    for (UIBarButtonItem *barButtonItem in self.toolbar.items) {
//        barButtonItem.enabled = YES;
//    }
}

- (CGRect)getSmallFrame:(CGRect)superFame {
    CGRect theFrame;
    theFrame.size = CGSizeMake(superFame.size.width - 8, superFame.size.height - 8);
    theFrame.origin = CGPointMake(superFame.origin.x + 4, superFame.origin.y + 4);
    return superFame;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _viewDidAppeared = YES;
    
    if (!_viewDidDisappeared) {
        /*
        GSVideoConfig videoConfig = [myVideoApi getVideoConfig];

        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            videoConfig.videoSize.width  = 720;
            videoConfig.videoSize.height = 1280;
        }
        else {
            videoConfig.videoSize.width  = 1280;
            videoConfig.videoSize.height = 720;
        }
        videoConfig.sessionPreset = GSCaptureSessionPreset720x1280;
        [myVideoApi setVideoConfig:videoConfig];
         */
        
        if (!app.isOnlyAudio) {
            _videoPaused = NO;
            
            if (app.userMe.isHost) {
                UserVideoControl *hostControl = self.userVideoContainerHost.userVideoControl;
                [hostControl initWithUser:app.userMe andOpenVideoDevice:[app.userMe defaultVideoDevice]];
            }
            /*
            else {
                UserVideoControl *userControl = [self getAvailableUserVideoControl];
                if (userControl != nil) {
                    [userControl initWithUser:app.userMe andOpenVideoDevice:[app.userMe defaultVideoDevice]];
                }
            }
             */
        }
        
        if (!app.isOnlyAudio) {
            [self performSelector:@selector(setBeautyFaceStatus) withObject:nil afterDelay:0.5];
            [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    _viewDidDisappeared = YES;
    [myVideoApi stopPreview];
    
    [super viewDidDisappear:animated];
}

- (void)setBeautyFaceStatus {
    float beautyLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"BeautyLevel"];
    float brightLevel = [[NSUserDefaults standardUserDefaults] floatForKey:@"BrightLevel"];
//    [myVideoApi setBeautyFaceStatus:YES beautyLevel:beautyLevel brightLevel:brightLevel];
}

- (void)hideToolbar {
    [self.toolbar setHidden:YES];
    [self.playerView setHidden:YES];
}

- (void)showToolbar {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToolbar) object:nil];
    
    [self.toolbar setHidden:NO];
    [self.playerView setHidden:(_musicFileName == nil)];
    
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    for (UserVideoContainer *userVideoContainer in _userVideoContainers) {
        [userVideoContainer setFrame:userVideoContainer.frame];
    }
    
    if (!_viewDidAppeared) {
        for (UserVideoControl *userVideoControl in _userVideoControls) {
            CGRect theFrame = userVideoControl.superview.frame;
            theFrame.origin = CGPointZero;
            userVideoControl.frame = theFrame;
            [userVideoControl setFrame:userVideoControl.frame];
        }
    }
}

- (IBAction)exitConf:(id)sender {
    /*
    for (UIBarButtonItem *barButtonItem in self.toolbar.items) {
        barButtonItem.enabled = NO;
    }
     */
    
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.user != nil) {
            [myVideoApi stopVideoPlay:userVideoControl.user.defaultVideoDevice.deviceID];
            [myVideoApi setViewForPlay:userVideoControl.user.defaultVideoDevice.deviceID imgView:nil];
        }
    }
    [_statsTimer invalidate];
    _statsTimer = nil;
    [myVideoApi setVideoStatReportDelegate:nil];
    [myAudioApi setAudioFileMixStatusDelegate:nil];
    [myAudioApi setExternalAudioProcessDelegate:nil];
    NSLog(@"leaveRoom -- Start");
    [enterConfApi exitRoom];
    [enterConfApi teardown];

    [myVideoApi setViewForCapture:nil];
    
    if (_musicFileName != nil) {
        [myAudioApi stopAudioFileMixing];
        _musicFileName = nil;
    }
    
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
     
    enterConfApi.enterConfApiDelegate = self.presentingViewController;
    NSLog(@"3TLog------dismiss_2");
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [app.logFileHandle closeFile];
        app.logFileHandle = nil;
    }];
    
    /*
    [enterConfApi setup:app_Key];
    [enterConfApi enterRoomByKey:nil userId:8888 sessionId:1234567 userRole:WS_USER_HOST rtmpUrl:@"rtmp://push.3ttech.cn/sdk/1234567"];
     */
}
- (IBAction)doReplayKit:(id)sender {
    [RPBroadcastActivityViewController loadBroadcastActivityViewControllerWithHandler:^(RPBroadcastActivityViewController * _Nullable broadcastActivityViewController, NSError * _Nullable error) {
        if (nil != error) {
            NSLog(@"loadBroadcastActivityViewControllerWithHandler with error %@", error.domain);
            return ;
        }
        
        broadcastActivityViewController.delegate = self;
        [self presentViewController:broadcastActivityViewController animated:YES completion:^{
        }];
    }];
}
- (IBAction)startReplayKit:(id)sender {
    static BOOL once = NO;
    
    [RPScreenRecorder sharedRecorder].microphoneEnabled = YES;
    
    if (!once) {
        [_broadcastVC startBroadcastWithHandler:^(NSError * _Nullable error) {
            if (nil != error) {
                return ;
            }
        }];
        once = YES;
    } else {
        [_broadcastVC finishBroadcastWithHandler:^(NSError * _Nullable error) {
        }];
        once = NO;
    }
}

- (IBAction)switchVideo:(id)sender {
    _videoPaused = !_videoPaused;
    if (_videoPaused) {
        [myVideoApi pauseVideo];
    }
    else {
        [myVideoApi resumeVideo];
        [self setBeautyFaceStatus];
    }
}

- (UserVideoControl *)getHostUserVideoControl {
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.user != nil && userVideoControl.user.isHost) {
            return userVideoControl;
        }
    }
    return nil;
}

- (UserVideoControl *)getAnchorUserVideoControl:(long long)userID {
    WSTUser *theUser = nil;
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        theUser = userVideoControl.user;
        if (theUser != nil && theUser.userType == WSTUserTypeAnchor && theUser.userID == userID) {
            return userVideoControl;
        }
    }
    return nil;
}

- (NSArray<UserVideoControl *> *)findUserVideoControlWithUser:(WSTUser *)user {
    NSMutableArray *controlArray = [[NSMutableArray alloc] init];
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.user != nil && userVideoControl.user == user)
            [controlArray addObject:userVideoControl];
    }
    return controlArray;
}

- (UserVideoControl *)findUserVideoControlWithDevice:(WSTVideoDevice *)videoDevice {
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.videoDevice != nil && userVideoControl.videoDevice == videoDevice)
            return userVideoControl;
    }
    return nil;
}

- (UserVideoControl *)findUserVideoControlWithDeviceID:(NSString *)deviceID {
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.videoDevice != nil && [userVideoControl.videoDevice.deviceID isEqualToString:deviceID])
            return userVideoControl;
    }
    return nil;
}

- (UserVideoControl *)findUserVideoControlWithOrigin:(CGPoint)origin {
    CGPoint theOrigin;
    double errorX, errorY;
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        theOrigin = userVideoControl.subVideoPos.origin;
        errorX = fabs(theOrigin.x - origin.x);
        errorY = fabs(theOrigin.y - origin.y);
        if (errorX < 0.1 && errorY < 0.1) {
            return userVideoControl;
        }
    }
    return nil;
}

- (void)userVideoControl:(UserVideoControl *)userVideoControl videoDeviceOpened:(BOOL)opened {
    if (opened) {
        if (app.userMe.isHost) {
            [self setAllVideoSEI];
        }
    }
    else {
        UserVideoControl *hostControl = [self getHostUserVideoControl];
        if (userVideoControl.isHuge && userVideoControl != hostControl) {
            [userVideoControl.container exchangeUserVideoControlWith:hostControl.container];
            hostControl.container.userInteractionEnabled = YES;
        }
        
        NSMutableArray<UserVideoContainer *> *smallUserVideoContainers = [[NSMutableArray alloc] init];
        for (UserVideoContainer *userVideoContainer in _userVideoContainers) {
            if (!userVideoContainer.userVideoControl.isHuge) {
                [smallUserVideoContainers addObject:userVideoContainer];
            }
        }
        
        UserVideoContainer *thisContainer, *nextContainer;
        for (int i = 0; i < smallUserVideoContainers.count; i++) {
            thisContainer = smallUserVideoContainers[i];
            if (thisContainer.userVideoControl.user == nil && i < smallUserVideoContainers.count - 1) {
                nextContainer = nil;
                for (int j = i + 1; j < smallUserVideoContainers.count; j++) {
                    if (smallUserVideoContainers[j].userVideoControl.user != nil) {
                        nextContainer = smallUserVideoContainers[j];
                        break;
                    }
                }
                if (nextContainer != nil) {
                    [thisContainer exchangeUserVideoControlWith:nextContainer];
                }
            }
            
        }
        
        if (app.userMe.isHost) {
            [self setAllVideoSEI];
        }
    }
}

- (void)onExitRoom
{
    /*
    
    [myVideoApi setViewForCapture:nil];
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    
    if (_musicFileName != nil) {
        [myAudioApi stopAudioFileMixing];
        _musicFileName = nil;
    }
    
    enterConfApi.enterConfApiDelegate = self.presentingViewController;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [app.logFileHandle closeFile];
        app.logFileHandle = nil;
    }];
     */
}

- (UserVideoControl *)getAvailableUserVideoControl {
    UserVideoControl *userControl;
    for (int i = 0; i < [_userVideoControls count]; i++) {
        userControl = _userVideoControls[i];
        if (userControl.user == nil)
            return userControl;
    }
    return nil;
}

- (void)onMemberEnter:(long long)sessionId userId:(long long)userId userRole:(WS_USER_ROLE)userRole
             speaking:(BOOL)speaking devid:(NSString *)devid {
    WSTUser *user = [[WSTUser alloc] initWithSessionID:sessionId userID:userId userType:WSTUserTypeRemoteUser
                                                  isMe:NO isHost:userRole==WS_USER_HOST];
    if (speaking)
        user.speakStatus = PERMISSION_STATUS_GRANTED;
    else
        user.speakStatus = PERMISSION_STATUS_NORMAL;
    WSTVideoDevice *videoDevice = [[WSTVideoDevice alloc] initWithID:devid];
    [user.deviceArray addObject:videoDevice];
    if (userRole==WS_USER_HOST) {
        app.userHost = user;
        [app.userArray insertObject:user atIndex:0];
    }
    else {
        [app.userArray addObject:user];
    }
    
    //主播进入房间
    if (!app.isOnlyAudio) {
        if (user.isHost && !user.isMe) {
            UserVideoControl *hostControl = self.userVideoContainerHost.userVideoControl;
            [hostControl initWithUser:user andOpenVideoDevice:videoDevice];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
    
    //[enterConfApi sendCustomizedMsg:@"123" toUser:0];
}

- (void)onSetSubVideoPosRation:(long long)operUserId userId:(long long)userId devId:(NSString *)devId
                videoPosRation:(CGRect)videoPosRation {
    NSLog(@"onSetSubVideoPosRation: operUserId = %lld, devId = %@, x = %f, y = %f, w = %f, h = %f",
          operUserId, devId, videoPosRation.origin.x, videoPosRation.origin.y, videoPosRation.size.width, videoPosRation.size.height);
    
    if (app.userMe.isHost) {
        return;
    }

    /*
    if (!app.isOnlyAudio) {
        WSTUser *theUser = [app userWithID:userId];
        WSTVideoDevice *theVideoDevice = [theUser videoDeviceWithID:devId];
        
        UserVideoControl *theOpenedControl = [self findUserVideoControlWithDevice:theVideoDevice];
        if (theOpenedControl != nil) {
            [theOpenedControl closeVideoDevice];
        }
        
        UserVideoControl *theControl = [self findUserVideoControlWithVideoTop:videoPosRation.origin.y andVideoLeft:videoPosRation.origin.x];
        if (theControl != nil) {
            if (theControl.videoDevice != nil) {
                [theControl closeVideoDevice];
            }
            
            [theControl initWithUser:theUser andOpenVideoDevice:theVideoDevice];
            [theControl refreshControlStatus];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
    }
     */
}

- (void)onSetSei:(long long)operUserId sei:(NSString *)sei {
    NSLog(@"onSetSei: %@", sei);
    
    if (app.userMe.isHost) {
        return;
    }

    if (app.isOnlyAudio) {
        return;
    }
    
    NSMutableArray<UserVideoControl *> *openedControls = [[NSMutableArray alloc] init];
    NSData *seiData = [sei dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *seiDictionary = [NSJSONSerialization JSONObjectWithData:seiData options:NSJSONReadingMutableLeaves error:&error];
    NSArray *posArray = [seiDictionary objectForKey:@"pos"];
    NSString *deviceID;
    double theX, theY, theW, theH;
    for (NSDictionary *posDictionary in posArray) {
        deviceID = [posDictionary objectForKey:@"id"];
        theX = [[posDictionary objectForKey:@"x"] doubleValue];
        theY = [[posDictionary objectForKey:@"y"] doubleValue];
        theW = [[posDictionary objectForKey:@"w"] doubleValue];
        theH = [[posDictionary objectForKey:@"h"] doubleValue];
        
        UserVideoControl *theOpenedControl = [self findUserVideoControlWithDeviceID:deviceID];
        if (theOpenedControl != nil) {
            if ([theOpenedControl isSubVideoPosIn:CGPointMake(theX, theY)]) {
                if (![openedControls containsObject:theOpenedControl]) {
                    [openedControls addObject:theOpenedControl];
                }
                continue;
            }
            else {
                [theOpenedControl closeVideoDevice];
            }
        }
        
        UserVideoControl *theControl = [self findUserVideoControlWithOrigin:CGPointMake(theX, theY)];
        if (theControl != nil) {
            if (theControl.videoDevice != nil) {
                [theControl closeVideoDevice];
            }
            
            WSTUser *theUser = nil;
            NSRange range = [deviceID rangeOfString:@":"];
            if (range.length > 0) {
                long long userID = [[deviceID substringToIndex:range.location] longLongValue];
                theUser = [app userWithUserID:userID];
            }
            else {
                theUser = [app userWithDeviceID:deviceID];
            }
            
            if (theUser != nil) {
                WSTVideoDevice *theVideoDevice = [theUser videoDeviceWithID:deviceID];
                if (theVideoDevice != nil) {
                    [theControl initWithUser:theUser andOpenVideoDevice:theVideoDevice];
                    [theControl refreshControlStatus];
                    
                    if (![openedControls containsObject:theControl]) {
                        [openedControls addObject:theControl];
                    }
                }
            }
        }
    }
    
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (![openedControls containsObject:userVideoControl]) {
            [userVideoControl closeVideoDevice];
        }
        
        /*
        if (userVideoControl.user.userID == app.userMe.userID && !app.userMe.isHost) {
            GSVideoConfig videoConfig = [myVideoApi getVideoConfig];
            if (userVideoControl.isHuge) {
                videoConfig.videoSize.width = 352;
                videoConfig.videoSize.height = 640;
                videoConfig.videoBitRate = 500*1000;
            } else {
                videoConfig.videoSize.width = 176;
                videoConfig.videoSize.height = 176;
                videoConfig.videoBitRate = 100*1000;
            }
            [myVideoApi setVideoConfig:videoConfig];
        }
         */
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
}

- (void)updateRemoteVideo:(NSString*)devID videoSize:(CGSize)videoSize {
//    UserVideoControl *userControl = [self findUserVideoControlWithUserID:userID];
//    if (userControl != nil) {
//        userControl.aspectRatio = videoSize.width / videoSize.height;
//    }
}

- (void)onMemberExit:(long long)sessionId userId:(long long)userId reason:(ENTERCONFAPI_ERROR)reason{
    WSTUser *theUser = [app userWithUserID:userId];
    NSArray<UserVideoControl *> *controlArray = [self findUserVideoControlWithUser:theUser];
    if (controlArray.count > 0) {
        for (UserVideoControl *userVideoControl in controlArray) {
            [userVideoControl closeVideoDevice];
        }
    }
    [app.userArray removeObject:theUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
}

- (void)onKickedOut:(long long)sessionId operUserId:(long long)operUserId userId:(long long)userId reason:(ENTERCONFAPI_ERROR)reason {
    NSString *reasonText;
    switch (reason) {
        case ENTERCONFAPI_KICKEDBYHOST:
            reasonText = @"被主播踢出";
            break;
        case ENTERCONFAPI_PUSHRTMPFAILED:
            reasonText = @"rtmp推流失败";
            break;
        case ENTERCONFAPI_SERVEROVERLOAD:
            reasonText = @"服务器过载";
            break;
        case ENTERCONFAPI_MASTER_EXIT:
            reasonText = @"主播已退出";
            break;
        case ENTERCONFAPI_RELOGIN:
            reasonText = @"重复登录";
            break;
        case ENTERCONFAPI_NOAUDIODATA:
            reasonText = @"长时间没有上行音频数据";
            break;
        case ENTERCONFAPI_NOVIDEODATA:
            reasonText = @"长时间没有上行视频数据";
            break;
        case ENTERCONFAPI_NEWCHAIRENTER:
            reasonText = @"其他人以主播身份进入";
            break;
        case ENTERCONFAPI_CHANNELKEYEXPIRED:
            reasonText = @"Channel Key失效";
            break;
        default:
            reasonText = @"未知原因";
            break;
    }
    reasonText = [NSString stringWithFormat:@"您已经被踢出房间“%lld”，原因“%@”。", sessionId, reasonText];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:reasonText, @"reason", nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"KickConf" object:self userInfo:userInfo];
    NSNotification *notification = [NSNotification notificationWithName:@"KickConf" object:self userInfo:userInfo];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle];
    
    [enterConfApi exitRoom];
    [enterConfApi teardown];
    NSLog(@"3TLog------dismiss_3");
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [app.logFileHandle closeFile];
        app.logFileHandle = nil;
    }];
}

- (void)onDisconnected:(int)nErrorCode {
    [SVProgressHUD showErrorWithStatus:@"onDisconnect **************"];
    /*
    [enterConfApi exitRoom];
    [enterConfApi teardown];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [app.logFileHandle closeFile];
        app.logFileHandle = nil;
        [SVProgressHUD showErrorWithStatus:@"onDisconnect **************"];
    }];
     */
}

- (void)prepareHideToolbar {
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
}

- (void)switchOpenUser:(WSTUser *)user videoDevice:(WSTVideoDevice *)videoDevice completion:(void (^)(void))completion {
    if (user.isHost) {
        return;
    }
    
    if (!app.isOnlyAudio) {
        UserVideoControl *userControl = [self findUserVideoControlWithDevice:videoDevice];
        if (userControl != nil) {
            [userControl closeVideoDevice];
        }
        else {
            userControl = [self getAvailableUserVideoControl];
            if (userControl != nil) {
                [userControl initWithUser:user andOpenVideoDevice:videoDevice];
            }
        }
        
        completion();
    }
}

- (void)linkOtherAnchor:(long long)sessionID userID:(long long)userID {
    [enterConfApi linkOtherAnchor:sessionID userId:userID];
}

- (void)onUpdateRtmpStatus:(long long)sessionId rtmpUrl:(NSString *)rtmpUrl status:(BOOL)status {
    NSLog(@"onUpdateRtmpStatus: %@", status ? @"YES" : @"NO");
}

- (void)onLogMsg:(NSString*)logMsg
{
    NSString* oldValue = [_logMsgView text];
    NSString* newValue = [[oldValue stringByAppendingString:@"\r\n"] stringByAppendingString:logMsg];;
    [_logMsgView setText:newValue];
}

- (void)onApplySpeakPermission:(long long)userId {
    NSLog(@"onApplySpeakPermission: %lld", userId);
    
    WSTUser *user = [app userWithUserID:userId];
    user.speakStatus = PERMISSION_STATUS_APPLYING;
    
    if ([enterConfApi getRoomMode] != ROOM_MODE_LIVE
        && [enterConfApi getRoomMode] != ROOM_MODE_COMMUNICATION)
    {
        if (app.isOnlyAudio) {
            [enterConfApi grantSpeakPermission:user.userID];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
        }
    }
}

- (void)onGrantSpeakPermission:(long long)userId status:(PERMISSION_STATUS)status {
    NSLog(@"onGrantSpeakPermission: userID = %lld, status = %d", userId, status);
    
    if (userId == app.userMe.userID)
    {
        [enterConfApi setAudioLevelReportInterval:500];
    }
    else
    {
        //[externalAudioModule enableSoftAEC:true];
    }
    
    WSTUser *user = [app userWithUserID:userId];
    user.speakStatus = status;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
}

- (void)onAnchorEnter:(long long)sessionId userId:(long long)userId devId:(NSString *)devId error:(int)error {
    NSLog(@"onAnchorEnter: %lld, %lld, %d", sessionId, userId, error);
    
    if (!app.userMe.isHost)
        return;
    
    if (error != 0) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"onAnchorEnter: error = %d", error]];
        return;
    }
    
    if (!app.isOnlyAudio) {
        UserVideoControl *userControl = [self getAvailableUserVideoControl];
        if (userControl != nil) {
            WSTUser *user = [[WSTUser alloc] initWithSessionID:sessionId userID:userId userType:WSTUserTypeAnchor isMe:NO isHost:NO];
            user.speakStatus = PERMISSION_STATUS_GRANTED;
            WSTVideoDevice *videoDevice = [[WSTVideoDevice alloc] initWithID:devId];
            [user.deviceArray addObject:videoDevice];
            [userControl initWithUser:user andOpenVideoDevice:videoDevice];
        }
    }
}

- (void)onAnchorExit:(long long)sessionId userId:(long long)userId {
    NSLog(@"onAnchorExit: %lld, %lld", sessionId, userId);
    
    if (!app.userMe.isHost)
        return;
    
    UserVideoControl *anchorControl = [self getAnchorUserVideoControl:userId];
    if (anchorControl != nil) {
        [anchorControl closeVideoDevice];
    }
}

- (void)onAnchorLinkResponse:(long long)sessionId userId:(long long)userId devId:(NSString *)devId {
    NSLog(@"onAnchorLinkResponse: %lld, %lld", sessionId, userId);
    
    if (!app.userMe.isHost)
        return;
    
    UserVideoControl *anchorControl = [self getAnchorUserVideoControl:userId];
    if (anchorControl == nil) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithLongLong:sessionId] forKey:@"LinkSessionID"];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithLongLong:userId] forKey:@"LinkUserID"];
        [enterConfApi linkOtherAnchor:sessionId userId:userId];
    }
}

- (void)onAnchorUnlinkResponse:(long long)sessionId userId:(long long)userId {
    NSLog(@"onAnchorUnlinkResponse: %lld, %lld", sessionId, userId);
    
    if (!app.userMe.isHost)
        return;
    
    UserVideoControl *anchorControl = [self getAnchorUserVideoControl:userId];
    if (anchorControl != nil) {
        [enterConfApi unlinkOtherAnchor:sessionId userId:userId devId:anchorControl.videoDevice.deviceID];
    }
}

- (void)userVideoControl:(UserVideoControl *)userVideoControl tapImageView:(UIImageView *)imageView {
    if (self.toolbar.hidden) {
        [self showToolbar];
    }
    else {
        [self hideToolbar];
    }
}

- (UserVideoControl *)getHugeUserVideoControl {
    for (UserVideoControl *userVideoControl in _userVideoControls) {
        if (userVideoControl.isHuge) {
            return userVideoControl;
        }
    }
    return nil;
}

- (UserVideoControl *)getIntersectantUserVideoControlButHuge:(UserVideoControl *)sourceControl {
    CGRect sourceFrame = [sourceControl.superview convertRect:sourceControl.frame toView:self.videoView];
    CGRect targetFrame = CGRectZero;
    for (UserVideoControl *targetControl in _userVideoControls) {
        if (targetControl.videoDevice == nil || targetControl.videoDevice == sourceControl.videoDevice) {
            continue;
        }
        [targetControl showBorders:NO];
        
        targetFrame = [targetControl.superview convertRect:targetControl.frame toView:self.videoView];
        if (!targetControl.isHuge && CGRectIntersectsRect(sourceFrame, targetFrame)) {
            return targetControl;
        }
    }
    return nil;
}

- (void)userVideoControl:(UserVideoControl *)userVideoControl panImageView:(UIImageView *)imageView
   withGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    
    if (!app.userMe.isHost) {
        return;
    }
    
    UserVideoControl *sourceControl = userVideoControl;
    UIView *sourceSuperView = sourceControl.superview;
    CGPoint transPoint = CGPointZero;
    NSInteger sourceIndex, targetIndex;
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            _sourceCenter = sourceControl.center;
            _sourceFrame = sourceControl.frame;
            _targetControl = nil;
            
            [sourceControl showBorders:YES];
            [sourceControl.container showBorders:YES];
            break;
            
        case UIGestureRecognizerStateChanged:
            //sourceControl.center = [gestureRecognizer locationInView:];
            transPoint = [gestureRecognizer translationInView:sourceSuperView];
            sourceControl.center = CGPointMake(sourceControl.center.x + transPoint.x,
                                                   sourceControl.center.y + transPoint.y);
            [gestureRecognizer setTranslation:CGPointZero inView:sourceSuperView];
            
            _targetControl = [self getIntersectantUserVideoControlButHuge:sourceControl];
            if (_targetControl != nil) {
                sourceIndex = [self.videoView.subviews indexOfObject:sourceControl.container];
                targetIndex = [self.videoView.subviews indexOfObject:_targetControl.container];
                if (sourceIndex < targetIndex) {
                    [self.videoView exchangeSubviewAtIndex:sourceIndex withSubviewAtIndex:targetIndex];
                }
                [_targetControl showBorders:YES];
            }
            else {
                if (!CGRectIntersectsRect(sourceControl.frame, _sourceFrame)) {
                    _targetControl = [self getHugeUserVideoControl];
                    if (_targetControl != nil) {
                        [_targetControl showBorders:YES];
                    }
                }
            }
            break;
            
        case UIGestureRecognizerStateEnded:
            if (_targetControl == nil) {
                sourceControl.center = _sourceCenter;
                [sourceControl showBorders:NO];
                [sourceControl.container showBorders:NO];
            }
            else {
                [sourceControl.container exchangeUserVideoControlWith:_targetControl.container];
                [sourceControl refreshControlStatus];
                [_targetControl refreshControlStatus];
                
                [self setAllVideoSEI];
            }
            
            break;
            
        default:
            break;
    }
}

- (void)statsTimerFired:(NSTimer *)theTimer {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setPositiveFormat:@"#,##0.00"];
    
    //视频发送接收
    int thisVideoSendBytes = [externalVideoModule getTotalSendBytes];
    double videoSendBitrate = (thisVideoSendBytes - _lastVideoSendBytes) / 1024.0 * 8;
    _lastVideoSendBytes = thisVideoSendBytes;
    self.lblVideoSend.text = [NSString stringWithFormat:@"%.2f", videoSendBitrate];
    
    int thisVideoRecvBytes = [externalVideoModule getTotalRecvBytes];
    double videoRecvBitrate = (thisVideoRecvBytes - _lastVideoRecvBytes) / 1024.0 * 8;
    _lastVideoRecvBytes = thisVideoRecvBytes;
    self.lblVideoRecv.text = [NSString stringWithFormat:@"%.2f", videoRecvBitrate];
    
    //音频发送接收
    int thisAudioSendBytes = [externalAudioModule getTotalSendBytes];
    double audioSendBitrate = (thisAudioSendBytes - _lastAudioSendBytes) / 1024.0 * 8;
    _lastAudioSendBytes = thisAudioSendBytes;
    self.lblAudioSend.text = [NSString stringWithFormat:@"%.2f", audioSendBitrate];
    
    int thisAudioRecvBytes = [externalAudioModule getTotalRecvBytes];
    double audioRecvBitrate = (thisAudioRecvBytes - _lastAudioRecvBytes) / 1024.0 * 8;
    _lastAudioRecvBytes = thisAudioRecvBytes;
    self.lblAudioRecv.text = [NSString stringWithFormat:@"%.2f", audioRecvBitrate];
    
    //视频编码
    int thisVideoEncoded =  [externalVideoModule getEncodeDataSize];
    //double videoEncoded = (thisVideoEncoded - _lastVideoEncoded) / 1024.0;
    double videoEncoded = thisVideoEncoded / 1024.0;
    _lastVideoEncoded = thisVideoEncoded;
    self.lblVideoEncoded.text = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:videoEncoded]];
    
    //音频编码
    int thisAudioEncoded = [externalAudioModule getEncodeDataSize];
    //double audioEncoded = (thisAudioEncoded - _lastAudioEncoded) / 1024.0;
    double audioEncoded = thisAudioEncoded / 1024.0;
    _lastAudioEncoded = thisAudioEncoded;
    self.lblAudioEncoded.text = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:audioEncoded]];
}

- (void)onEnterRoom:(ENTERCONFAPI_ERROR)error userRole:(WS_USER_ROLE)userRole deviceID:(NSString *)deviceID {
}

- (void)onApplyConfChairman:(long long)sessionId userId:(long long)userId result:(BOOL)result {
    NSLog(@"onApplyConfChairman: %lld, %lld result:%@", sessionId, userId, result ? @"YES" : @"NO");
    
    if (result) {
        WSTUser *theUser = [app userWithUserID:userId];
        if (theUser != nil) {
            theUser.isHost = YES;
            app.userHost.isHost = NO;
            app.userHost = theUser;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
        }
    }
}

- (void)onConfChairmanChanged:(long long)sessionId userId:(long long)userId {
    NSLog(@"onConfChairmanChanged: %lld, %lld", sessionId, userId);
    
    WSTUser *theUser = [app userWithUserID:userId];
    if (theUser != nil && !theUser.isHost) {
        theUser.isHost = YES;
        app.userHost.isHost = NO;
        app.userHost = theUser;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshUserList" object:nil];
    }
}

- (void)onNativeLog:(NSString *)nativeLog {
    [app.logFileHandle seekToEndOfFile];
    [app.logFileHandle writeData:[nativeLog dataUsingEncoding:NSUTF8StringEncoding]];
}

/*
- (void)processCute:(GLuint)texId size:(CGSize)size outputTexture:(GLuint*)outputTexId
{
    [renderEngine processTexture:texId size:size outputTexture:outputTexId];
}
 */

- (void)cameraDidReady {
}

- (void)videoDidStop {
}

- (void)firstLocalVideoFrameWithSize:(CGSize)size {
}

- (void)firstRemoteVideoFrame:(NSString *)deviceID videoSize:(CGSize)videoSize {
}

- (void)firstRemoteVideoDecoded:(NSString *)deviceID videoSize:(CGSize)videoSize {
}

- (void)playMusicFile:(NSString *)musicFileName loopback:(BOOL)loopback loopTimes:(int)loopTimes {
    NSLog(@"3TLog------dismiss_4");
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (_musicFileName != nil) {
        [myAudioApi stopAudioFileMixing];
        _musicFileName = nil;
    }
    
    BOOL theResult = [myAudioApi startAudioFileMixing:[musicFileName UTF8String] loopback:loopback loopTimes:loopTimes];
    if (theResult) {
        _musicFileName = musicFileName;
        [myAudioApi adjustAudioFileVolumeScale:0.50];
        [self showToolbar];
    }
    else {
        [Application showAlert:self message:@"startAudioFileMixing failed"];
    }
}

- (IBAction)onClickPlayOrPauseButton:(id)sender {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToolbar) object:nil];
    
    if (self.playOrPauseButton.tag > 0) {
        [myAudioApi pauseAudioFileMixing];
        self.playOrPauseButton.tag = 0;
        [self.playOrPauseButton setImage:[UIImage imageNamed:@"btn_player_play"] forState:UIControlStateNormal];
    }
    else {
        [myAudioApi resumeAudioFileMixing];
        self.playOrPauseButton.tag = 1;
        [self.playOrPauseButton setImage:[UIImage imageNamed:@"btn_player_pause"] forState:UIControlStateNormal];
    }
    
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
}

- (void)OnReportAudioFileDuration:(int)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playOrPauseButton.tag = 1;
        [self.playOrPauseButton setImage:[UIImage imageNamed:@"btn_player_pause"] forState:UIControlStateNormal];
        self.musicProgressSlider.maximumValue = duration;
        self.musicProgressSlider.value = 0;
        self.currentTimeLabel.text = @"00:00";
        self.totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(duration / 60), (int)(duration % 60)];
    });
}

- (void)OnReportAudioFilePlayedSeconds:(int)seconds {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_isMusicSliderBeingDragged) {
            self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(seconds / 60), (int)(seconds % 60)];
            self.musicProgressSlider.value = seconds;
        }
    });
}

- (void)OnReportAudioFileEof {
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.currentTimeLabel.text = self.totalDurationLabel.text;
        self.musicProgressSlider.value = self.musicProgressSlider.maximumValue;
        self.playOrPauseButton.tag = 0;
        [self.playOrPauseButton setImage:[UIImage imageNamed:@"btn_player_play"] forState:UIControlStateNormal];
        [self showToolbar];
    });
    [myAudioApi stopAudioFileMixing];
    _musicFileName = nil;
}

#pragma mark 播放进度条控制

- (IBAction)didSliderTouchDown {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideToolbar) object:nil];
    _isMusicSliderBeingDragged = YES;
}

- (IBAction)didSliderTouchCancel {
    _isMusicSliderBeingDragged = NO;
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
}

- (IBAction)didSliderTouchUpInside {
    [myAudioApi seekAudioFileTo:self.musicProgressSlider.value];
    _isMusicSliderBeingDragged = NO;
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
}

- (IBAction)didSliderTouchUpOutside {
    _isMusicSliderBeingDragged = NO;
    [self performSelector:@selector(hideToolbar) withObject:nil afterDelay:30];
}

- (IBAction)didSliderValueChanged {
    if (_isMusicSliderBeingDragged) {
        int seconds = self.musicProgressSlider.value;
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(seconds / 60), (int)(seconds % 60)];
    }
}

- (IBAction)volumeScaleSliderValueChanged:(id)sender {
    self.volumeScaleLabel.text = [NSString stringWithFormat:@"%.2f", self.volumeScaleSlider.value];
}

- (IBAction)volumeScaleSliderTouchUpInside:(id)sender {
    [myAudioApi adjustAudioFileVolumeScale:self.volumeScaleSlider.value];
    [myAudioApi adjustAudioSoloVolumeScale:self.volumeScaleSlider.value];
}

- (IBAction)volumeScaleSliderTouchUpOutside:(id)sender {
    [myAudioApi adjustAudioFileVolumeScale:self.volumeScaleSlider.value];
    [myAudioApi adjustAudioSoloVolumeScale:self.volumeScaleSlider.value];
}

- (void)onReportAuidoLevel:(long long)userId audioLevel:(int)audioLevel audioLevelFullRange:(int)audioLevelFullRange
{
    printf("[%lld] ----- [%d], [%d] \n", userId, audioLevel, audioLevelFullRange);
}

- (void)onRecordAudioData:(char*)data len:(int)len samplingFreq:(int)samplingFreq isStereo:(bool)isStereo {
#if 0
    NSArray* myPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* myDocPath = [myPaths objectAtIndex:0];
    NSString *path = [myDocPath stringByAppendingPathComponent:@"aaa3.pcm"];
    
    [writer appendBytes:data length:len];
    [writer writeToFile:path atomically:YES];
#endif
}

- (void)onPlaybackAudioData:(char*)data len:(int)len samplingFreq:(int)samplingFreq isStereo:(bool)isStereo {
    
}

- (void)onAudioMuted:(BOOL)muted userId:(long long)userId
{
    
}

- (void)onVideoMuted:(BOOL)muted userId:(long long)userId
{
    
}

- (void)onRecvCustomizedMsg:(long long)userId msg:(NSString *)msg
{
    
}

- (void)onRecvCustomizedAudioMsg:(NSString*)msg
{
    
}

- (void)onRecvCustomizedVideoMsg:(NSString *)msg
{
    
}

- (void)onRequestChannelKey {
    NSLog(@"3tLog___onRequestChannelKey");
//    [enterConfApi renewChannelKey:@"123456"];
//    [enterConfApi renewChannelKey:@"55HWNONuStC2nvUOxXhwh84NNbUuUmfqCFarsgWKz2PPiomkuw9IZk9eSu6nRzJLLnOlv2cNSLio+/htn6QOjw=="];
}

- (void)onRenewChannelKeyResult:(int)result {
    NSLog(@"3tlog onRenewChannelKeyResult: %@", result ? @"YES" : @"NO");
}

- (void)onReportLocalVideoStats:(GSVideoStats)videoStats
{
    //NSLog(@"onReportLocalVideoStats: %d, %d", videoStats.bitrate, videoStats.framerate);
}

- (void)onReportLocalVideoLossRate:(float)lossRate
{
    NSLog(@"onReportLocalVideoLossRate %f!!!!", lossRate);
}

- (void)onVideoaDualStreamEnabled:(BOOL)enabled userId:(long long)userId {
    NSLog(@"3TLog------%d  %lld",enabled, userId);
}

- (void)onReportRemoteVideoStats:(GSVideoStats *)videoStats count:(int)count
{
    for (int i = 0; i < count; i++) {
        NSLog(@"onReportRemoteVideoStats: %lld, %d, %d", videoStats[i].userid, videoStats[i].bitrate, videoStats[i].framerate);
    }
}

- (void)onReportRemoteAudioStats:(GSAudioStats*)audioStats count:(int)count
{
    for (int i = 0; i < count; i++) {
        NSLog(@"onReportRemoteAudioStats: %lld, %d", audioStats[i].userid, audioStats[i].lossRate);
    }
}

- (void)onMediaDataSending
{
    NSLog(@"onMediaDataSending!!!!");
}

- (void) reportH264Sei:(NSString *)deviceID sei:(uint8_t *)sei seiSize:(int)seiSize {
    NSLog(@"report h264 sei %@", [NSString stringWithFormat:@"%s", sei]);
}

- (void)firstRemoteVideoFrameDecoded:(NSString *)deviceID videoSize:(CGSize)videoSize {
    
}


- (void)firstRemoteVideoFrameRendered:(NSString *)deviceID videoSize:(CGSize)videoSize {
    
}


- (void)outputCaptured:(CVPixelBufferRef)pixelBuffer {
    
}

- (void)remoteVideoDecoded:(NSString *)deviceID pixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}


- (void) onChangedUserRole:(WS_USER_ROLE)userRole userId:(long long)userId {
    NSLog(@"onChangedUserRole %d, %lld", userRole, userId);
    if (userRole == WS_USER_AUDIANCE)
    {
        [enterConfApi applySpeakPermission:NO];
    }
    else
    {
        [enterConfApi applySpeakPermission:YES];
    }
}

-(void) onReconnectServerTimeout
{
    NSLog(@"onReconnectServerTimeout");
}

#pragma mark RPBroadcastActivityViewControllerDelegate

- (void)broadcastActivityViewController:(RPBroadcastActivityViewController *)broadcastActivityViewController didFinishWithBroadcastController:(nullable RPBroadcastController *)broadcastController error:(nullable NSError *)error {
    
    if (nil != error) {
        NSLog(@"didFinishWithBroadcastController with error %@", error.domain);
    }
    
    _broadcastVC = broadcastController;
    NSLog(@"3TLog------dismiss_1");
    [broadcastActivityViewController dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

@end

