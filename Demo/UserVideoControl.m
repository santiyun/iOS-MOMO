#import "UserVideoControl.h"
#import <UIKit/UIKit.h>
#import "MyVideoApi.h"
#import "LiveRoomViewController.h"
#import "Application.h"

#define DUALVIDEO NO

@interface UserVideoControl ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *btnCloseVideo;
@property (weak, nonatomic) IBOutlet UILabel *lblSessionID;
@property (weak, nonatomic) IBOutlet UILabel *lblUserDevice;
@property (weak, nonatomic) IBOutlet UIButton *btnSwitchCamera;
@property (weak, nonatomic) IBOutlet UILabel *lblMixGuestVideo;
@property (weak, nonatomic) IBOutlet UISwitch *switchMixGuestVideo;
@property (weak, nonatomic) IBOutlet UIView *viewBorderTop;
@property (weak, nonatomic) IBOutlet UIView *viewBorderBottom;
@property (weak, nonatomic) IBOutlet UIView *viewBorderLeft;
@property (weak, nonatomic) IBOutlet UIView *viewBorderRight;

@end

@implementation UserVideoControl

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"UserVideoControl" owner:self options:nil];
        [self addSubview:self.contentView];
        
        _layoutConstraintTrailing = nil;
        
        [self reset];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGRect rect = frame;
    rect.origin = CGPointZero;
    self.contentView.frame = rect;
}

- (void)reset {
    _user = nil;
    if (_videoDevice != nil) {
        _videoDevice.isOpened = NO;
        _videoDevice = nil;
    }
    _mixedByHost = NO;
    self.imageView.image = nil;
    self.lblSessionID.text = @"";
    self.lblUserDevice.text = @"";
    self.btnCloseVideo.hidden = NO;
    
    [self showBorders:NO];
    self.hidden = YES;
    self.container.userInteractionEnabled = YES;
}

- (void)initWithUser:(WSTUser *)user andOpenVideoDevice:(WSTVideoDevice *)videoDevice {
    
    _user = user;
    _videoDevice = videoDevice;
    _videoDevice.isOpened = YES;
    WSTUser *userMe = app.userMe;
    
    self.btnSwitchCamera.hidden = YES;
    self.btnCloseVideo.hidden = NO;
    self.lblSessionID.hidden = NO;
    self.lblSessionID.text = [NSString stringWithFormat:@"[%lld]", user.sessionID];
    self.lblUserDevice.text = user.userName;
    switch (user.userType) {
        case WSTUserTypeMe:
            self.btnSwitchCamera.hidden = NO;
            //self.lblSessionID.hidden = !user.isHost;
            [self.btnCloseVideo setImage:[UIImage imageNamed:@"CloseVideo"] forState:UIControlStateNormal];
            self.btnCloseVideo.hidden = user.isHost;
            break;
        case WSTUserTypeAnchor:
            //self.lblSessionID.hidden = NO;
            [self.btnCloseVideo setImage:[UIImage imageNamed:@"Unlink"] forState:UIControlStateNormal];
            if (userMe.isHost) {
                //self.lblMixGuestVideo.hidden = NO;
                //self.switchMixGuestVideo.hidden = NO;
            }
            break;
        default:
            //self.lblSessionID.hidden = !user.isHost;
            [self.btnCloseVideo setImage:[UIImage imageNamed:@"CloseVideo"] forState:UIControlStateNormal];
            self.btnCloseVideo.hidden = user.isHost;
            if (userMe.isHost) {
                //self.lblMixGuestVideo.hidden = NO;
                //self.switchMixGuestVideo.hidden = NO;
            }
            break;
    }
    
    if (user.isMe) {
        [myVideoApi setViewForCapture:self.imageView];
    }
    else {
        if (user.userType != WSTUserTypeAnchor) {
            if (DUALVIDEO)
            {
                [enterConfApi openDualVideo:YES userID:user.userID];
                
            }
            else
            {
                [enterConfApi openVideoDevice:YES userID:user.userID deviceID:videoDevice.deviceID];
                
            }
            
            [myVideoApi setViewForPlay:videoDevice.deviceID imgView:self.imageView];
            
            [myVideoApi startVideoPlay:videoDevice.deviceID];
        }
        
        
        
        if (userMe.isHost) {
            [enterConfApi mixGuestVideo:user.userID devId:videoDevice.deviceID enabled:YES];
        }
    }

    self.hidden = NO;
    self.container.userInteractionEnabled = YES;
    
    if ([self.delegate respondsToSelector:@selector(userVideoControl:videoDeviceOpened:)]) {
        [self.delegate userVideoControl:self videoDeviceOpened:YES];
    }
}

- (void)dealloc
{
    [myVideoApi stopVideoPlay:_videoDevice.deviceID];
    [myVideoApi setViewForPlay:_videoDevice.deviceID imgView:nil];
}

- (void)closeVideoDevice {
    if (self.videoDevice != nil) {
        NSString *deviceID = self.videoDevice.deviceID;
        if (self.user.isMe) {
            [myVideoApi setViewForCapture:nil];
        }
        else {
            if (app.userMe.isHost) {
                //CGRect videoPosRation = {0};
                [enterConfApi mixGuestVideo:self.user.userID devId:self.videoDevice.deviceID enabled:NO];
                                             //andSetPosRation:videoPosRation];
            }
            
            [myVideoApi stopVideoPlay:deviceID];
            [myVideoApi setViewForPlay:deviceID imgView:nil];
            if (self.user.userType != WSTUserTypeAnchor) {
                if (DUALVIDEO)
                {
                    [enterConfApi openDualVideo:NO userID:self.user.userID];
                }
                else
                {
                    [enterConfApi openVideoDevice:NO userID:self.user.userID deviceID:deviceID];
                }
            }
        }
        [self reset];
        
        if ([self.delegate respondsToSelector:@selector(userVideoControl:videoDeviceOpened:)]) {
            [self.delegate userVideoControl:self videoDeviceOpened:YES];
        }
    }
}

- (IBAction)switchCamera:(id)sender {
    [[self LiveRoomViewController] switchCamera];
}

- (IBAction)btnCloseVideoClicked:(id)sender {
    switch (self.user.userType) {
        case WSTUserTypeAnchor: {
            NSString *alertMessage = @"您确定要结束主播连麦吗？";
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [enterConfApi unlinkOtherAnchor:self.user.sessionID userId:self.user.userID devId:self.videoDevice.deviceID];
            }];
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:actionOK];
            [alertController addAction:actionCancel];
            [[self LiveRoomViewController] presentViewController:alertController animated:YES completion:nil];
        }
            break;
            
        case WSTUserTypeMe:
        case WSTUserTypeRemoteUser:
            [self closeVideoDevice];
            break;
            
        default:
            break;
    }
}

- (IBAction)tapImageView:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(userVideoControl:tapImageView:)]) {
        [self.delegate userVideoControl:self tapImageView:self.imageView];
    }
}

- (IBAction)panImageView:(UIPanGestureRecognizer *)sender {
    if (self.isHuge) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(userVideoControl:panImageView:withGestureRecognizer:)]) {
        [self.delegate userVideoControl:self panImageView:self.imageView withGestureRecognizer:sender];
    }
}

- (IBAction)switchMixGuestVideoValueChanged:(UISwitch *)sender {
    if (app.userMe.isHost) {
        if (sender.on) {
            [enterConfApi mixGuestVideo:self.user.userID devId:self.videoDevice.deviceID enabled:YES andSetPosRation:self.subVideoPos];
        }
        else {
            CGRect videoPosRation = {0};
            [enterConfApi mixGuestVideo:self.user.userID devId:self.videoDevice.deviceID enabled:NO andSetPosRation:videoPosRation];
        }
    }
}

- (CGRect)subVideoPos {
    CGRect videoViewRect = self.container.superview.frame;
    CGRect selfRect = [self.superview convertRect:self.frame toView:self.container.superview];
    CGFloat x = selfRect.origin.x    / videoViewRect.size.width;
    CGFloat y = selfRect.origin.y    / videoViewRect.size.height;
    CGFloat w = selfRect.size.width  / videoViewRect.size.width;
    CGFloat h = selfRect.size.height / videoViewRect.size.height;
    CGRect rect;
    rect.origin.x    = [[NSString stringWithFormat:@"%.3f", x] doubleValue];
    rect.origin.y    = [[NSString stringWithFormat:@"%.3f", y] doubleValue];
    rect.size.width  = [[NSString stringWithFormat:@"%.3f", w] doubleValue];
    rect.size.height = [[NSString stringWithFormat:@"%.3f", h] doubleValue];
    return rect;
}

- (BOOL)isSubVideoPosIn:(CGPoint)origin {
    CGPoint selfOrigin = self.subVideoPos.origin;
    double errorX = fabs(selfOrigin.x - origin.x);
    double errorY = fabs(selfOrigin.y - origin.y);
    return (errorX < 0.1 && errorY < 0.1);
}

- (LiveRoomViewController *)LiveRoomViewController {
    for (UIView *nextView = [self superview]; nextView != nil; nextView = nextView.superview) {
        UIResponder *nextResponder = [nextView nextResponder];
        if ([nextResponder isKindOfClass:[LiveRoomViewController class]]) {
            return (LiveRoomViewController *)nextResponder;
        }
    }
    return nil;
}

- (void)showBorders:(BOOL)visible {
    self.viewBorderTop.hidden    = !visible;
    self.viewBorderBottom.hidden = !visible;
    self.viewBorderLeft.hidden   = !visible;
    self.viewBorderRight.hidden  = !visible;
}

- (BOOL)isHuge {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    return (self.frame.size.width > screenRect.size.width * 0.9);
}

- (void)refreshControlStatus {
    self.btnCloseVideo.enabled       = !self.isHuge;
    self.switchMixGuestVideo.enabled = !self.isHuge;
}

@end
