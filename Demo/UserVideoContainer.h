#import <UIKit/UIKit.h>

@class UserVideoControl;

/**
 UserVideoControl的容器
 */
@interface UserVideoContainer : UIControl

@property (weak, nonatomic) IBOutlet UserVideoControl *userVideoControl;

- (void)showBorders:(BOOL)visible;

- (void)exchangeUserVideoControlWith:(UserVideoContainer *)targetContainer;

@end
