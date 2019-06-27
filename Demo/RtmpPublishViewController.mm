#import "RtmpPublishViewController.h"
#import "MyVideoApi.h"
#import "MyAudioApi.h"
#import "SVProgressHUD.h"
#import "Common.h"
#import "Application.h"

@interface RtmpPublishViewController () <ExternalRtmpPublishModuleDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnSwitchCamera;
@property (weak, nonatomic) IBOutlet UITextField *tfRtmpUrl;
@property (weak, nonatomic) IBOutlet UIImageView *videoView;
@property (weak, nonatomic) IBOutlet UIButton *btnRtmpPublish;
@property (weak, nonatomic) IBOutlet UIButton *btnStopPublish;

@end

@implementation RtmpPublishViewController
{
    ExternalRtmpPublishModule *_externalRtmpPublishModule;
    BOOL _isPreviewing;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _externalRtmpPublishModule = [ExternalRtmpPublishModule sharedInstance];
    _externalRtmpPublishModule.delegate = self;
    [_externalRtmpPublishModule setExternalVideoModuleDelegate:myVideoApi];
    [myVideoApi addVideoConsignor:_externalRtmpPublishModule];
    [_externalRtmpPublishModule setExternalAudioModuleDelegate:myAudioApi];
    [myAudioApi addAudioConsignor:_externalRtmpPublishModule];
    
    _isPreviewing = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_isPreviewing) {
        [myVideoApi setViewForCapture:self.videoView];
        [myVideoApi startPreview];
        _isPreviewing = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"RtmpPublishing"]) {
        if (_isPreviewing) {
            [myVideoApi stopPreview];
            [myVideoApi setViewForCapture:nil];
            _isPreviewing = NO;
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)registerApplicationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground)
    //                                             name:UIApplicationDidEnterBackgroundNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate)
    //                                             name:UIApplicationWillTerminateNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground)
    //                                             name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)unregisterApplicationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RtmpPublishing"]) {
            [_externalRtmpPublishModule pausePublish];
        }
    });
}

- (void)applicationDidBecomeActive {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RtmpPublishing"]) {
            [_externalRtmpPublishModule resumePublish];
        }
    });
}

- (IBAction)rtmpPublish:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RtmpPublishing"];
    [self.btnRtmpPublish setEnabled:NO];
    [self.btnStopPublish setEnabled:YES];
    [_externalRtmpPublishModule startPublish:[self.tfRtmpUrl.text UTF8String] retrytime:3];
    
    [self registerApplicationObservers];
}

- (IBAction)stopPublish:(id)sender {
    [self unregisterApplicationObservers];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"RtmpPublishing"];
    [self.btnRtmpPublish setEnabled:YES];
    [self.btnStopPublish setEnabled:NO];
    [_externalRtmpPublishModule stopPublish];
}

- (void)receiveRtmpStatus:(RtmpErrorType)errorType {
    NSString *errorText;
    switch (errorType) {
        case RtmpErrorType_InitError:
            errorText = @"初始化RTMP发送器失败";
            break;
        case RtmpErrorType_OpenError:
            errorText = @"打开RTMP链接失败";
            break;
        case RtmpErrorType_AudioNoBuf:
            errorText = @"音频数据缓冲区空间不足";
            break;
        case RtmpErrorType_VideoNoBuf:
            errorText = @"视频数据缓冲区空间不足";
            break;
        case RtmpErrorType_LinkFailed:
            errorText = @"发送视频数据失败";
            break;
        case RtmpErrorType_LinkSuccessed:
            errorText = @"发送成功";
            break;
        default:
            errorText = @"RTMP 未知错误";
            break;
    }
    [SVProgressHUD showErrorWithStatus:errorText];
}

- (IBAction)switchCamera:(id)sender {
    GSVideoConfig videoConfig = [myVideoApi getVideoConfig];
    videoConfig.enableFrontCam = !videoConfig.enableFrontCam;
    [myVideoApi setVideoConfig:videoConfig];
}

@end
