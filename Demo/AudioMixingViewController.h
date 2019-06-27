#import <UIKit/UIKit.h>

@protocol AudioMixingViewControllerDelegate <NSObject>

- (void)playMusicFile:(NSString *)musicFileName loopback:(BOOL)loopback loopTimes:(int)loopTimes;

@end

@interface AudioMixingViewController : UIViewController

@property (nonatomic, weak) id<AudioMixingViewControllerDelegate> delegate;

@end
