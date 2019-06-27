#import "StreamingPlayerViewController.h"

@interface StreamingPlayerViewController () <TTTPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *overlayPanel;
@property (weak, nonatomic) IBOutlet UIView *statusPanel;
@property (weak, nonatomic) IBOutlet UIView *topPanel;
@property (weak, nonatomic) IBOutlet UIView *bottomPanel;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UISlider *mediaProgressSlider;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playNextButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end

@implementation StreamingPlayerViewController
{
    TTTPlayer *_player;
    BOOL _statusBarHidden;
    BOOL _isMediaSliderBeingDragged;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _statusBarHidden = NO;
    [self initPlayerWithUrl:self.url];
    [self refreshMediaControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [_player play];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(hideOverlayPanel) withObject:nil afterDelay:10];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)initPlayerWithUrl:(NSURL *)aUrl {
    TTTPlayerOptions *options = [TTTPlayerOptions defaultOptions];
    _player = [TTTPlayer playerWithURL:aUrl options:options];
    _player.playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //_player.playerView.contentMode = UIViewContentModeScaleAspectFit;
    _player.playerView.frame = self.videoView.bounds;
    _player.playerView.userInteractionEnabled = NO;
    self.videoView.autoresizesSubviews = YES;
    [self.videoView addSubview:_player.playerView];
    _player.delegate = self;
}

- (void)player:(TTTPlayer *)player statusDidChange:(TTTPlayerStatus)playerStatus {
    switch (playerStatus) {
        case TTTPlayerStatusPreparing:
            [self.activityIndicatorView startAnimating];
            self.playOrPauseButton.enabled = NO;
            self.playNextButton.enabled = NO;
            break;
            
        case TTTPlayerStatusReady:
            self.playOrPauseButton.enabled = YES;
            self.playNextButton.enabled = YES;
            [self.activityIndicatorView stopAnimating];
            break;
            
        case TTTPlayerStatusCaching:
            [self.activityIndicatorView startAnimating];
            break;
            
        case TTTPlayerStatusPlaying:
            [self.playOrPauseButton setImage:[UIImage imageNamed:@"btn_player_pause"] forState:UIControlStateNormal];
            [self.activityIndicatorView stopAnimating];
            break;
            
        case TTTPlayerStatusPaused:
            [self.playOrPauseButton setImage:[UIImage imageNamed:@"btn_player_play"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)player:(TTTPlayer *)player stoppedWithError:(NSError *)error {
    self.playOrPauseButton.enabled = YES;
    self.playNextButton.enabled = YES;
    [self.activityIndicatorView stopAnimating];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示"
                                                                                 message:error.localizedDescription
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:actionOK];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark -

- (IBAction)onTouchOverlay:(id)sender
{
    [self hideOverlayPanel];
}

- (IBAction)onTouchVideoView:(id)sender {
   [self showOverlayPanel];
}

- (void)showOverlayPanel {
    [self cancelDelayedHide];
    
    _statusBarHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    self.overlayPanel.hidden = NO;
    [self refreshMediaControl];
    
    [self performSelector:@selector(hideOverlayPanel) withObject:nil afterDelay:10];
}

- (void)hideOverlayPanel {
    _statusBarHidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    self.overlayPanel.hidden = YES;
}

- (void)cancelDelayedHide {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideOverlayPanel) object:nil];
}

#pragma mark 播放器控制

/**
 点击”完成“按钮
 */
- (IBAction)onClickDone:(id)sender
{
    [_player stop];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

/**
 点击“播放下一个”按钮
 */
- (IBAction)onClickPlayNext:(id)sender {
    [_player stop];
    [_player.playerView removeFromSuperview];
    
    NSUInteger nextUrlIndex;
    if (![self.streamingUrls containsObject:[self.url absoluteString]]) {
        nextUrlIndex = 0;
    }
    else {
        if ([[self.url absoluteString] isEqualToString:[self.streamingUrls lastObject]]) {
            nextUrlIndex = 0;
        }
        else {
            nextUrlIndex = [self.streamingUrls indexOfObject:[self.url absoluteString]] + 1;
        }
    }
    self.url = [NSURL URLWithString:self.streamingUrls[nextUrlIndex]];
    
    [self initPlayerWithUrl:self.url];
    [_player play];
}

/**
 点击“播放”/“暂停”按钮
 */
- (IBAction)onClickPlayOrPause:(id)sender
{
    if (_player.status == TTTPlayerStatusError) {
        [_player stop];
        [_player.playerView removeFromSuperview];
        [self initPlayerWithUrl:self.url];
        [_player play];
    }
    else {
        if (_player.playing)
            [_player pause];
        else
            [_player resume];
    }
}

#pragma mark 进度条控制

- (IBAction)didSliderTouchDown
{
    [self beginDragMediaSlider];
}

- (IBAction)didSliderTouchCancel
{
    [self endDragMediaSlider];
}

- (IBAction)didSliderTouchUpInside
{
    [_player seekTo:self.mediaProgressSlider.value];
    [self endDragMediaSlider];
}

- (IBAction)didSliderTouchUpOutside
{
    [self endDragMediaSlider];
}

- (IBAction)didSliderValueChanged
{
    [self refreshMediaControl];
}

- (void)beginDragMediaSlider {
    _isMediaSliderBeingDragged = YES;
}

- (void)endDragMediaSlider {
    _isMediaSliderBeingDragged = NO;
}

- (void)refreshMediaControl {
    //时长
    NSTimeInterval duration = _player.totalDuration;
    NSInteger intDuration = duration + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.maximumValue = duration;
        self.totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
    } else {
        self.totalDurationLabel.text = @"--:--";
        self.mediaProgressSlider.maximumValue = 1.0f;
    }
    
    //播放位置
    NSTimeInterval position;
    if (_isMediaSliderBeingDragged) {
        position = self.mediaProgressSlider.value;
    } else {
        position = _player.currentTime;
    }
    NSInteger intPosition = position + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.value = position;
    } else {
        self.mediaProgressSlider.value = 0.0f;
    }
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
    

    //每隔0.5秒刷新一次
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    if (!self.overlayPanel.hidden) {
        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    }
}

- (void)player:(TTTPlayer *)player statsInfo:(TTTPlayerStatsInfo *)statsInfo {
    
}

- (void)player:(TTTPlayer *)player playbackH264SEI:(NSString *)sei {
    NSLog(@"%@", sei);
}

- (void)player:(TTTPlayer *)player playbackVolInfo:(NSArray<NSDictionary *> *)volInfo {
    for (NSDictionary *volInfoDictionary in volInfo) {
        long long uid = [[volInfoDictionary objectForKey:@"uid"] longLongValue];
        int vol = [[volInfoDictionary objectForKey:@"vol"] intValue];
        NSLog(@"uid = %lld, vol = %d", uid, vol);
    }
}

- (void)playerRenderOverlay:(nonnull TTTPlayer *)player {
    
}

@end
