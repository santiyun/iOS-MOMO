#import "TabBarViewController.h"
#import "Application.h"

@interface TabBarViewController () <UITabBarControllerDelegate>

@end

@implementation TabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.delegate = self;
    
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [Application supportedInterfaceOrientations];
}

/*
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    BOOL landscape = [[NSUserDefaults standardUserDefaults] boolForKey:@"landscape_preference"];
    if (landscape) {
        return UIInterfaceOrientationLandscapeRight;
    }
    else {
        return UIInterfaceOrientationPortrait;
    }
}
*/

- (void)showAlertMessage:(NSString *)alertMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:actionOK];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    if (index == 0) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RtmpPublishing"]) {
            [self showAlertMessage:@"必须停止推流才能切换到“连麦演示”！"];
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        return YES;
    }
}

@end
