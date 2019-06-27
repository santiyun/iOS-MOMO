#import "UserVideoContainer.h"
#import "UserVideoControl.h"

@interface UserVideoContainer ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *viewBorderTop;
@property (weak, nonatomic) IBOutlet UIView *viewBorderBottom;
@property (weak, nonatomic) IBOutlet UIView *viewBorderLeft;
@property (weak, nonatomic) IBOutlet UIView *viewBorderRight;


@end

@implementation UserVideoContainer

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
        [[NSBundle mainBundle] loadNibNamed:@"UserVideoContainer" owner:self options:nil];
        [self addSubview:self.contentView];
        self.userVideoControl.container = self;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGRect rect = frame;
    rect.origin = CGPointZero;
    self.contentView.frame = rect;
}

- (void)showBorders:(BOOL)visible {
    self.viewBorderTop.hidden    = !visible;
    self.viewBorderBottom.hidden = !visible;
    self.viewBorderLeft.hidden   = !visible;
    self.viewBorderRight.hidden  = !visible;
}

- (void)exchangeUserVideoControlWith:(UserVideoContainer *)targetContainer {
    UserVideoControl *sourceControl = self.userVideoControl;
    UIView *sourceSuperView = sourceControl.superview;
    UserVideoControl *targetControl = targetContainer.userVideoControl;
    UIView *targetSuperView = targetControl.superview;
    
    [sourceControl removeFromSuperview];
    [targetControl removeFromSuperview];
    [targetSuperView addSubview:sourceControl];
    sourceControl.frame = targetSuperView.frame;
    sourceControl.container = targetContainer;
    targetContainer.userVideoControl = sourceControl;
    [sourceControl showBorders:NO];
    [targetContainer showBorders:NO];
    
    [sourceSuperView addSubview:targetControl];
    targetControl.frame = sourceSuperView.frame;
    targetControl.container = self;
    self.userVideoControl = targetControl;
    [targetControl showBorders:NO];
    [self showBorders:NO];
}

@end
