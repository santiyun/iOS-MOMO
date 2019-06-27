#import "ViewController.h"
#import "MyVideoApi.h"
#import "MyAudioApi.h"
#import "SVProgressHUD.h"

#import <netdb.h>
#import "Application.h"
#import "LiveRoomViewController.h"
#import "HttpClient.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *viewBack;
@property (weak, nonatomic) IBOutlet UIView *viewRTMP;
@property (weak, nonatomic) IBOutlet UITextField *textIP;
@property (weak, nonatomic) IBOutlet UITextField *textPort;
@property (weak, nonatomic) IBOutlet UITextField *textUserID;
@property (weak, nonatomic) IBOutlet UITextField *textSessionID;
@property (weak, nonatomic) IBOutlet UISwitch *switchIsHost;
@property (weak, nonatomic) IBOutlet UISwitch *switchOnlyAudio;
@property (weak, nonatomic) IBOutlet UITextView *textRTMP;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentBizMode;
@property (weak, nonatomic) IBOutlet UITextField *textSecID;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@end


@implementation ViewController
{
    AudioConverterRef m_converter;
    
    NSString* m_logMsg;
}
//#define app_Key     @"momolive"

//a967ac491e3acf92eed5e1b5ba641ab7
#define app_Key     @"test900572e02867fab8131651339518"

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.viewBack.layer.borderWidth = 1;
    self.viewBack.layer.borderColor = [UIColor colorWithRed:225/255.0 green:225/255.0 blue:225/255.0 alpha:1].CGColor;
    self.viewBack.layer.cornerRadius = 5;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *strIP = [userDefaults stringForKey:@"EnterIP"];
    if (strIP == nil) {
        self.textIP.text = @"114.80.212.235";
        self.textIP.text = @"114.80.212.236";
        self.textIP.text = @"39.107.252.75";
        
        self.textIP.text = @"103.192.254.99";//for token
    }
    else {
    	self.textIP.text = strIP;
    }
    
    NSString *strPort = [userDefaults stringForKey:@"EnterPort"];
    if (strPort == nil) {
        self.textPort.text = @"25000";
    }
    else {
        self.textPort.text = strPort;
    }
    
    NSString *strUserID = [userDefaults stringForKey:@"EnterUserID"];
    if ([strUserID length] > 0) {
        self.textUserID.text = strUserID;
    }
    else {
        self.textUserID.text = [NSString stringWithFormat:@"%@%d", @"100", arc4random() % 1000];
    }
    
    NSString *strSessionID = [userDefaults stringForKey:@"EnterSessionID"];
    if ([strSessionID length] > 0) {
        self.textSessionID.text = strSessionID;
    }
    else {
        self.textSessionID.text = [NSString stringWithFormat:@"%d", arc4random() % 100000];
    }
    [self.textSessionID addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.segmentBizMode.selectedSegmentIndex = [userDefaults integerForKey:@"EnterBizMode"];
    self.switchIsHost.on = [userDefaults boolForKey:@"EnterIsHost"];
    self.switchOnlyAudio.on = [userDefaults boolForKey:@"EnterOnlyAudio"];
    
    self.textRTMP.text = [NSString stringWithFormat:@"%@%@", @"rtmp://push.3ttech.cn/sdk/", self.textSessionID.text];
    self.viewRTMP.layer.borderWidth = 0.6;
    self.viewRTMP.layer.cornerRadius = 6.0;
    self.viewRTMP.layer.borderColor = [UIColor colorWithRed:225.0 / 255.0 green:225.0 / 255.0 blue:225.0 / 255.0 alpha:1].CGColor;
    self.textRTMP.hidden = (self.segmentBizMode.selectedSegmentIndex != 0) || !self.switchIsHost.on;
    
    self.textSecID.text = [userDefaults objectForKey:@"EnterSecID"];

    NSLog(@"version is %@", [enterConfApi getVersion]);
    
//    [enterConfApi setup:app_Key logLevel:GS_LOG_LEVEL_DEBUG];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *logFileName = [path stringByAppendingFormat:@"/%@.log", strSessionID];
//    [enterConfApi setup:app_Key logLevel:GS_LOG_LEVEL_DEBUG];
    [enterConfApi setup:app_Key enableChat:NO logLevel:GS_LOG_LEVEL_OFF logFile:logFileName];
    
    [externalVideoModule setExternalVideoModuleDelegate:myVideoApi];
    [externalVideoModule setMaxBufferDuration:2000];
    [externalAudioModule setExternalAudioModuleDelegate:myAudioApi];
    [myVideoApi addVideoConsignor:externalVideoModule];
    [enterConfApi setAudioQualityProfile:GSAudioQualityProfileMusicHighQualityStereo];
//    [enterConfApi ]
//    [externalAudioModule enableSoftAEC:GS_AEC_LEVEL_OFF withNoiseSuppression:GS_NS_LEVEL_VERY_HIGH];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(showKickConfInfo:) name:@"KickConf" object:nil];
    [notificationCenter addObserver:self selector:@selector(tttError:) name:@"TTT_ERROR" object:nil];
    self.versionLabel.text = [enterConfApi getVersion];
}

- (void)tttError:(NSNotification *)note {
    NSLog(@"3TLog------%@",note.object);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-(void)doSomething
//{
//    while (1)
//    {
//        int duration = [externalVideoModule getBufferDuration];
//        
//        int vbytes = [externalVideoModule getTotalSendBytes];
//        int abytes = [externalAudioModule getTotalSendBytes];
//        
//        //printf("total send bytes v:[%d], a:[%d] \n", vbytes, abytes);
//        
//        //if (myAudioApi)
//        {
//            ExternalAudioModule* externalAudioModule = externalAudioModule;
//            [externalAudioModule setExternalAudioModuleDelegate:nil];
//            //myAudioApi = nil;
//            
//            ExternalVideoModule* externalVideoModule = externalVideoModule;
//            [externalVideoModule setExternalVideoModuleDelegate:nil];
//        }
//        /*else
//        {
//            myAudioApi = [[MyAudioApi alloc] init];
//            
//            ExternalAudioModule* externalAudioModule = externalAudioModule;
//            [externalAudioModule SetExternalAudioModuleDelegate:myAudioApi];
//            
//            ExternalVideoModule* externalVideoModule = externalVideoModule;
//            [externalVideoModule SetExternalVideoModuleDelegate:myVideoApi];
//        }*/
//        
//        usleep(1000*1000);
//    }
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    enterConfApi.enterConfApiDelegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    enterConfApi.enterConfApiDelegate = nil;
    [enterConfApi teardown];
}

- (IBAction)enterConf:(id)sender {
    // 数据输入校验
    long long userID = [self.textUserID.text longLongValue];
    if (userID <= 0) {
        [SVProgressHUD showInfoWithStatus:@"“用户ID”输入不正确！"];
        return;
    }
    
    long long sessionID = [self.textSessionID.text longLongValue];
    if (sessionID <= 0) {
        [SVProgressHUD showInfoWithStatus:@"“会话ID”输入不正确！"];
        return;
    }
    
    BOOL isHost = self.switchIsHost.on;
    NSString *rtmpUrl = self.textRTMP.hidden ? @"" : self.textRTMP.text;
    if (!self.textRTMP.hidden && [rtmpUrl length] <= 0) {
        [SVProgressHUD showInfoWithStatus:@"“推流地址”输入不正确！"];
        return;
    }

    // 保存输入数据
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:self.textIP.text forKey:@"EnterIP"];
    [userDefaults setValue:self.textPort.text forKey:@"EnterPort"];
    [userDefaults setValue:self.textUserID.text forKey:@"EnterUserID"];
    [userDefaults setValue:self.textSessionID.text forKey:@"EnterSessionID"];
    [userDefaults setBool:self.switchIsHost.on forKey:@"EnterIsHost"];
    [userDefaults setBool:self.switchOnlyAudio.on forKey:@"EnterOnlyAudio"];
    [userDefaults setInteger:self.segmentBizMode.selectedSegmentIndex forKey:@"EnterBizMode"];
    [userDefaults setObject:self.textSecID.text forKey:@"EnterSecID"];
    
    // 清空日志文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:app.logFileName]) {
        [fileManager removeItemAtPath:app.logFileName error:nil];
    }
    //
    [[NSFileManager defaultManager] createFileAtPath:app.logFileName contents:nil attributes:nil];
    app.logFileHandle = [NSFileHandle fileHandleForWritingAtPath:app.logFileName];
    NSString *theText = [[NSString string] stringByPaddingToLength:100 withString:@"*" startingAtIndex:0];
    theText = [NSString stringWithFormat:@"%@\n%@ %lld\n%@\n", theText, [app.logFileName lastPathComponent], userID, theText];
    [app.logFileHandle seekToEndOfFile];
    [app.logFileHandle writeData:[theText dataUsingEncoding:NSUTF8StringEncoding]];
//    [enterConfApi useHighQualityAudio:YES];
//    [HttpClient getTokenFromServerWithUserID:self.textUserID.text ChannelID:self.textSessionID.text AppID:app_Key success:^(NSString *msg) {
    
//        NSLog(@"获取token___%@",msg);
    
        /*
        dispatch_async(dispatch_get_main_queue(), ^{
            if (msg.length > 0)
            {
                [HttpClient checkTokenFromServerWithToken:[HttpClient encodeString:msg] UserID:self.textUserID.text ChannelID:self.textSessionID.text AppKey:app_Key success:^(NSString *token) {
                    
                    NSLog(@"urlencode过的token  %@",token);
                    if (token.length > 0)
                    {
         */
        dispatch_async(dispatch_get_main_queue(), ^{
                        // 进入房间
                        [SVProgressHUD show];
            
//            [enterConfApi setServerIp:@"39.107.252.75" port:25000];
            
            //------
//            [enterConfApi enableDualVideoStream:YES];
            
                        [enterConfApi setServerIp:self.textIP.text port:[self.textPort.text intValue]];
            
                        //NSString *channelKey = self.textSecID.text;
                        if (self.segmentBizMode.selectedSegmentIndex == 0)
                        {
//                            [enterConfApi useHighQualityAudio:self.switchOnlyAudio.on];
//                            [enterConfApi useHighQualityAudio:YES];
                            if (self.switchOnlyAudio.on) {
                                if (![enterConfApi enterAudioRoomByKey:nil userId:userID sessionId:sessionID userRole:isHost?WS_USER_HOST:WS_USER_PARTICIPANT rtmpUrl:rtmpUrl])
                                {
                                    [SVProgressHUD dismiss];
                                }
                            } else {
                                //[enterConfApi enableCrossRoom:YES];
                                //[enterConfApi enableDualVideoStream:YES];
                                //[enterConfApi setRoomMode:ROOM_MODE_COMMUNICATION];
                                //[enterConfApi setVideoMixerBitrate:700 fps:20 width:352 height:640];
                                if (![enterConfApi enterRoomByKey:nil userId:userID sessionId:sessionID userRole:isHost?WS_USER_HOST:WS_USER_PARTICIPANT rtmpUrl:rtmpUrl])
                                //if (![enterConfApi enterRoomByKey:msg userId:userID sessionId:sessionID userRole:isHost?WS_USER_HOST:WS_USER_AUDIANCE rtmpUrl:rtmpUrl])
                                {
                                    [SVProgressHUD dismiss];
                                }
                            }
                        }
                        else
                        {
                            if (![enterConfApi enterConfByKey:nil userId:userID sessionId:sessionID password:@"123" mixVideo:YES rtmpUrl:rtmpUrl])
                            {
                                [SVProgressHUD dismiss];
                            }
                        }
        });
        /*
                    }
                    
                } failure:^(NSError *reqError) {
                    NSLog(@"鉴权失败___%@",reqError.localizedDescription);
                    dispatch_async(dispatch_get_main_queue(), ^{
                         [SVProgressHUD showInfoWithStatus:reqError.localizedDescription];
                    });
                }];
            }
        });
         */
        
//    } failure:^(NSError *reqError) {
//        NSLog(@"error____%@",reqError.localizedDescription);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD showInfoWithStatus:reqError.localizedDescription];
//        });
//    }];
}

- (IBAction)switchIsHostValueChanged:(id)sender {
    self.textRTMP.hidden = (self.segmentBizMode.selectedSegmentIndex != 0) || !self.switchIsHost.on;
}

- (IBAction)switchOnlyAudioValueChanged:(id)sender {
    //
}

- (IBAction)segmentBizModeValueChanged:(id)sender {
    self.textRTMP.hidden = (self.segmentBizMode.selectedSegmentIndex != 0) || !self.switchIsHost.on;
}

- (void)onEnterRoom:(ENTERCONFAPI_ERROR)error userRole:(WS_USER_ROLE)userRole deviceID:(NSString *)deviceID
{
    //dispatch_async(dispatch_get_main_queue(), ^(){
    
    [SVProgressHUD dismiss];
    
    if (error != ENTERCONFAPI_NOERROR)
    {
        NSString *errorInfo = @"";
        switch (error) {
            case ENTERCONFAPI_TIMEOUT:
                errorInfo = @"超时,10秒未收到服务器返回结果";
                break;
            case ENTERCONFAPI_ENTER_FAILED:
                errorInfo = @"进入房间失败"; //@"无法连接服务器";
                break;
            case ENTERCONFAPI_VERIFY_FAILED:
                errorInfo = @"验证码错误";
                break;
            case ENTERCONFAPI_BAD_VERSION:
                errorInfo = @"版本错误";
                break;
            default:
                errorInfo = @"进入房间未知错误";
                break;
        }
        [SVProgressHUD showErrorWithStatus:errorInfo];
    }
    else
    {
        GSVideoConfig videoConfig = [myVideoApi getVideoConfig];
        if (userRole == WS_USER_HOST) {
            videoConfig.videoSize.width = 352;
            videoConfig.videoSize.height = 640;
            videoConfig.videoBitRate = 400*1000;
        } else {
            videoConfig.videoSize.width = 120;
            videoConfig.videoSize.height = 160;
            videoConfig.videoBitRate = 200*1000;
        }
        [myVideoApi setVideoConfig:videoConfig];
        
        app.isOnlyAudio = self.switchOnlyAudio.on;
        app.isLiveRoom = (self.segmentBizMode.selectedSegmentIndex == 0);
        long long sessionID = [self.textSessionID.text longLongValue];
        long long userID = [self.textUserID.text longLongValue];
        WSTUser *user = [[WSTUser alloc] initWithSessionID:sessionID userID:userID userType:WSTUserTypeMe isMe:YES isHost:userRole == WS_USER_HOST];
        app.userMe = user;
        if (userRole == WS_USER_HOST) {
            app.userHost = user;
        }
        WSTVideoDevice *videoDevice = [[WSTVideoDevice alloc] initWithID:deviceID];
        if (!app.isOnlyAudio) {
            if (userRole == WS_USER_HOST) {
                videoDevice.isOpened = YES;
            }
        }
        [user.deviceArray addObject:videoDevice];
        [app.userArray removeAllObjects];
        [app.userArray addObject:user];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LiveRoom" bundle:nil];
        LiveRoomViewController *lrvc = [storyboard instantiateViewControllerWithIdentifier:@"LiveRoom"];
        lrvc.logMsg = m_logMsg;
        [lrvc setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
        [self presentViewController:lrvc animated:YES completion:nil];
    }
    //});
}

- (void)showKickConfInfo:(NSNotification *)notification {
    [SVProgressHUD showInfoWithStatus:[[notification userInfo] objectForKey:@"reason"]];
}

- (void)textFieldDidChange:(id)sender {
    if (sender == self.textSessionID) {
        self.textRTMP.text = [NSString stringWithFormat:@"%@%@", @"rtmp://push.3ttech.cn/sdk/", self.textSessionID.text];
    }
}

- (void)onLogMsg:(NSString*)logMsg {
    m_logMsg = logMsg;
}

- (void)onExitRoom {
}

- (void)onMemberEnter:(long long)sessionId userId:(long long)userId
               userRole:(WS_USER_ROLE)userRole speaking:(BOOL)speaking devid:(NSString *)devid {
    NSLog(@"TTTT-----------:%@",devid);
}

- (void)onMemberExit:(long long)sessionId userId:(long long)userId reason:(ENTERCONFAPI_ERROR)reason{
}

- (void)onSetSubVideoPosRation:(long long)operUserId userId:(long long)userId devId:(NSString *)devId
                videoPosRation:(CGRect)videoPosRation {
}

- (void)onSetSei:(long long)operUserId sei:(NSString *)sei {
}

- (void)onKickedOut:(long long)sessionId operUserId:(long long)operUserId userId:(long long)userId reason:(ENTERCONFAPI_ERROR)reason {
}

- (void)onDisconnected:(int)errNo {
}

- (void)onUpdateRtmpStatus:(long long)sessionId rtmpUrl:(NSString *)rtmpUrl status:(BOOL)status {
}

- (void)onApplySpeakPermission:(long long)userId {
}

- (void)onGrantSpeakPermission:(long long)userId status:(PERMISSION_STATUS)status {
    if (userId == app.userMe.userID)
    {
        [enterConfApi setAudioLevelReportInterval:500];
    }
}

- (void)onAnchorEnter:(long long)sessionId userId:(long long)userId devId:(NSString *)devId error:(int)error {
    printf("onAnchorEnter %lld, %lld, %s, %d \n", sessionId, userId, [devId UTF8String], error);
}

- (void)onAnchorExit:(long long)sessionId userId:(long long)userId {
    printf("onAnchorExit %lld, %lld \n", sessionId, userId);
}

- (void)onAnchorLinkResponse:(long long)sessionId userId:(long long)userId devId:(NSString *)devId {
    printf("onAnchorLinkResponse %lld, %lld, %s \n", sessionId, userId, [devId UTF8String]);
}

- (void)onAnchorUnlinkResponse:(long long)sessionId userId:(long long)userId {
    printf("onAnchorUnlinkResponse %lld, %lld \n", sessionId, userId);
}

- (void)onApplyConfChairman:(long long)sessionId userId:(long long)userId result:(BOOL)result {
}

- (void)onConfChairmanChanged:(long long)sessionId userId:(long long)userId {
}

- (void)onNativeLog:(NSString *)nativeLog {
    /*
    [app.logData appendData:[nativeLog dataUsingEncoding:NSUTF8StringEncoding]];
    [app.logData writeToFile:app.logFileName atomically:YES];
     */
}

-(void) onReportAuidoLevel:(long long)userId audioLevel:(int)audioLevel audioLevelFullRange:(int)audioLevelFullRange
{
    
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

- (void)onVideoaDualStreamEnabled:(BOOL)enabled userId:(long long)userId
{
    
}

- (void)onRequestChannelKey
{
    
}

- (void)onRenewChannelKeyResult:(int)result
{
    
}

- (void)onReportLocalVideoStats:(GSVideoStats)videoStats
{
    
}

- (void)onReportLocalVideoLossRate:(float)lossRate
{
    
}

- (void)onReportRemoteVideoStats:(GSVideoStats *)videoStats count:(int)count
{
    
}

- (void)onReportRemoteAudioStats:(GSAudioStats*)audioStats count:(int)count
{
    
}

- (void)onChangedUserRole:(WS_USER_ROLE)userRole userId:(long long)userId {
    
}


- (void)onMediaDataSending {
    
}

-(void) onReconnectServerTimeout
{
    
}

@end
