#import "DebugSettingsViewController.h"
#import "MyVideoApi.h"
#import "MyAudioApi.h"
#import "Application.h"
#import <AVFoundation/AVFoundation.h>

@interface DebugSettingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *switchStatsInfo;
@property (weak, nonatomic) IBOutlet UISwitch *switchLogMsg;
@property (weak, nonatomic) IBOutlet UISwitch *switchUploadVideo;
@property (weak, nonatomic) IBOutlet UISwitch *switchUploadAudio;

@end

@implementation DebugSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.switchStatsInfo.on   = [userDefaults boolForKey:@"ShowStatsInfo"];
    self.switchLogMsg.on      = [userDefaults boolForKey:@"ShowLogMsg"];
    self.switchUploadVideo.on = [userDefaults boolForKey:@"UploadVideo"];
    if (app.isOnlyAudio) {
        self.switchUploadVideo.on = NO;
        self.switchUploadVideo.enabled = NO;
    }
    self.switchUploadAudio.on = [userDefaults boolForKey:@"UploadAudio"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    return [Application supportedInterfaceOrientations];
//}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)switchStatsInfo_ValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"ShowStatsInfo"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SwitchShowStatsInfo" object:nil];
}

- (IBAction)switchLogMsg_ValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"ShowLogMsg"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SwitchShowLogMsg" object:nil];
}

- (IBAction)switchUploadVideo_ValueChangd:(UISwitch *)sender {
    [enterConfApi muteLocalVideo:!sender.on];
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"UploadVideo"];
}

- (IBAction)switchUploadAudio_ValueChangd:(UISwitch *)sender {
    [enterConfApi muteLocalAudio:!sender.on];
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"UploadAudio"];
}

- (IBAction)doneAction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
