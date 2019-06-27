#import "Application.h"

static Application *sharedApplication = nil;

@implementation Application
{
    NSLock *_lockUserData;
}

+ (Application *)sharedInstance {
    @synchronized(self) {
        if (sharedApplication == nil) {
            sharedApplication = [[Application alloc] init];
        }
    }
    return sharedApplication;
}

- (instancetype)init {
    @synchronized(self) {
        self = [super init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"%@.log", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey]];
        _logFileName = [documentsDirectory stringByAppendingPathComponent:fileName];
        _logFileHandle = nil;
        
        _userMe = nil;
        _userHost = nil;
        _userArray = [[NSMutableArray alloc] init];
        
        _lockUserData = [[NSLock alloc] init];
        
        return self;
    }
}

#if TARGET_OS_IOS
+ (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    BOOL landscape = [[NSUserDefaults standardUserDefaults] boolForKey:@"landscape_preference"];
    if (landscape) {
        return UIInterfaceOrientationMaskLandscapeRight;
    }
    else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

+ (void)showAlert:(UIViewController *)viewController message:(NSString *)messageText {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:messageText preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:actionOK];
    [viewController presentViewController:alertController animated:YES completion:nil];
}
#else
+ (void)showAlert:(NSWindow *)window messageText:(NSString *)messageText informativeText:(NSString *)informativeText {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:messageText];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:@"确定"];
    [alert setAlertStyle:NSAlertStyleWarning];
    if (window != nil) {
        [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {}];
    }
    else {
        [alert runModal];
    }
}
#endif

- (WSTUser *)userWithIndex:(NSInteger)index {
    [_lockUserData lock];
    WSTUser *user = self.userArray[index];
    [_lockUserData unlock];
    return user;
}

- (WSTUser *)userWithUserID:(long long)userID {
    WSTUser *user = nil;
    [_lockUserData lock];
    for (int i = 0; i < self.userArray.count; i++) {
        if (self.userArray[i].userID == userID) {
            user = self.userArray[i];
            break;
        }
    }
    [_lockUserData unlock];
    return user;
}

- (WSTUser *)userWithDeviceID:(NSString *)deviceID {
    WSTUser *theUser = nil;
    [_lockUserData lock];
    for (WSTUser *user in self.userArray) {
        if ([user videoDeviceWithID:deviceID] != nil) {
            theUser = user;
            break;
        }
    }
    [_lockUserData unlock];
    return theUser;
}

@end
