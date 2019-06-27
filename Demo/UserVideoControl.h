#import <UIKit/UIKit.h>
#import "UserVideoContainer.h"
#import "WSTUser.h"

@class UserVideoControl;

/**
 UserVideoControl 的代理协议
 */
@protocol UserVideoControlDelegate <NSObject>

- (void)userVideoControl:(UserVideoControl *)userVideoControl tapImageView:(UIImageView *)imageView;
- (void)userVideoControl:(UserVideoControl *)userVideoControl panImageView:(UIImageView *)imageView
   withGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)userVideoControl:(UserVideoControl *)userVideoControl videoDeviceOpened:(BOOL)opened;

@end

/**
 UserVideoControl
 */
@interface UserVideoControl : UIControl

@property (nonatomic, weak) id<UserVideoControlDelegate> delegate;
@property (nonatomic, assign) UserVideoContainer *container;
@property (nonatomic, readonly) WSTUser *user;
@property (nonatomic, readonly) WSTVideoDevice *videoDevice;
@property (nonatomic, assign) NSLayoutConstraint *layoutConstraintTrailing;
@property (nonatomic, readonly) BOOL isHuge;
@property (nonatomic, assign) BOOL mixedByHost;
//@property (nonatomic, assign) double aspectRatio;
@property (nonatomic, readonly) CGRect subVideoPos;

- (void)initWithUser:(WSTUser *)user andOpenVideoDevice:(WSTVideoDevice *)videoDevice;

- (void)closeVideoDevice;

- (void)showBorders:(BOOL)visible;

- (void)refreshControlStatus;

- (BOOL)isSubVideoPosIn:(CGPoint)origin;

@end
