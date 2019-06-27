
#import "LiveSettingsViewController.h"
#import "Application.h"
#import "LiveRoomViewController.h"
#import "MyVideoApi.h"
#import "UserVideoControl.h"

@interface LiveSettingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *switchBeautyFace;
@property (weak, nonatomic) IBOutlet UISlider *sliderBeautyLevel;
@property (weak, nonatomic) IBOutlet UILabel *labelBeautyLevel;
@property (weak, nonatomic) IBOutlet UISlider *sliderBrightLevel;
@property (weak, nonatomic) IBOutlet UILabel *labelBrightLevel;
@property (weak, nonatomic) IBOutlet UITextField *tfSessionID;
@property (weak, nonatomic) IBOutlet UITextField *tfUserID;
@property (weak, nonatomic) IBOutlet UIButton *btnLinkAnchor;
@property (weak, nonatomic) IBOutlet UITextField *textChairPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnApplyChairman;

@end

@implementation LiveSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //美颜
    self.switchBeautyFace.on = [userDefaults boolForKey:@"BeautyFace"];
    [self.sliderBeautyLevel setEnabled:self.switchBeautyFace.on];
    [self.sliderBrightLevel setEnabled:self.switchBeautyFace.on];
    
    self.sliderBeautyLevel.value = [userDefaults floatForKey:@"BeautyLevel"];
    self.labelBeautyLevel.text = [NSString stringWithFormat:@"%.1f", self.sliderBeautyLevel.value];
    self.sliderBrightLevel.value = [userDefaults floatForKey:@"BrightLevel"];
    self.labelBrightLevel.text = [NSString stringWithFormat:@"%.1f", self.sliderBrightLevel.value];
    if (app.isOnlyAudio) {
        self.switchBeautyFace.on = NO;
        [self switchBeautyFace_ValueChanged:self.switchBeautyFace];
        self.switchBeautyFace.enabled = NO;
    }
    //主播连麦
    if (app.userMe.isHost) {
        self.tfSessionID.text = [userDefaults stringForKey:@"LinkSessionID"];
        self.tfUserID.text    = [userDefaults stringForKey:@"LinkUserID"];
    }
    else {
        self.tfSessionID.text = @"";
        self.tfUserID.text = @"";
        self.btnLinkAnchor.enabled = NO;
    }
    //申请主席
    if (app.userMe.isHost) {
        self.textChairPassword.enabled = NO;
        self.btnApplyChairman.enabled = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    
    return cell;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (!app.isOnlyAudio) {
        if ([self.presentingViewController isKindOfClass:[LiveRoomViewController class]]) {
            LiveRoomViewController *lvvc = (LiveRoomViewController *)self.presentingViewController;
            [lvvc prepareHideToolbar];
        }
    }
}

- (IBAction)doneAction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchBeautyFace_ValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"BeautyFace"];
    
    if (sender.on) {
        [myVideoApi setBeautyFaceStatus:YES beautyLevel:self.sliderBeautyLevel.value brightLevel:self.sliderBrightLevel.value];
    }
    else {
        [myVideoApi setBeautyFaceStatus:NO beautyLevel:0 brightLevel:0];
    }
    
    [self.sliderBeautyLevel setEnabled:sender.on];
    [self.sliderBrightLevel setEnabled:sender.on];
}

- (IBAction)sliderBeautyLevel_ValueChanged:(id)sender {
    self.labelBeautyLevel.text = [NSString stringWithFormat:@"%.1f", _sliderBeautyLevel.value];
    [myVideoApi setBeautyFaceStatus:YES beautyLevel:self.sliderBeautyLevel.value brightLevel:self.sliderBrightLevel.value];
    [[NSUserDefaults standardUserDefaults] setFloat:self.sliderBeautyLevel.value forKey:@"BeautyLevel"];
}

- (IBAction)sliderBrightLevel_ValueChanged:(id)sender {
    self.labelBrightLevel.text = [NSString stringWithFormat:@"%.1f", _sliderBrightLevel.value];
    [myVideoApi setBeautyFaceStatus:YES beautyLevel:self.sliderBeautyLevel.value brightLevel:self.sliderBrightLevel.value];
    [[NSUserDefaults standardUserDefaults] setFloat:self.sliderBrightLevel.value forKey:@"BrightLevel"];
}

- (IBAction)linkOtherAnchor:(id)sender {
    long long sessionID = [self.tfSessionID.text longLongValue];
    if (sessionID == 0) {
        [Application showAlert:self message:@"对方主播的会话ID输入不正确！"];
        return;
    }

    long long userID = [self.tfUserID.text longLongValue];
    if (userID == 0) {
        [Application showAlert:self message:@"对方主播的用户ID输入不正确！"];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:self.tfSessionID.text forKey:@"LinkSessionID"];
    [[NSUserDefaults standardUserDefaults] setValue:self.tfUserID.text forKey:@"LinkUserID"];
    
    if ([self.presentingViewController isKindOfClass:[LiveRoomViewController class]]) {
        LiveRoomViewController *lvvc = (LiveRoomViewController *)self.presentingViewController;
        
        UserVideoControl *anchorControl = [lvvc getAnchorUserVideoControl:userID];
        if (anchorControl != nil) {
            [Application showAlert:self message:@"您已经与该主播连麦！"];
            return;
        }
        
        [lvvc linkOtherAnchor:sessionID userID:userID];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)applyConfChairman:(id)sender {
    NSString *chairPassword = self.textChairPassword.text;
    if ([chairPassword length] <= 0) {
        [Application showAlert:self message:@"主席密码不能为空！"];
        return;
    }
    
    [enterConfApi applyConfChairman:chairPassword];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
