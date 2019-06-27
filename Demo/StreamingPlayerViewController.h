#import <UIKit/UIKit.h>
#import "Common.h"


@interface StreamingPlayerViewController : UIViewController

@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSMutableArray *streamingUrls;

@end
