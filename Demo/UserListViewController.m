#import "UserListViewController.h"
#import "Application.h"
#import "LiveRoomViewController.h"
#import "WSTUser.h"

@interface UserListViewController ()

@end

@implementation UserListViewController
{
    LiveRoomViewController *_liveRoomViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _liveRoomViewController = (LiveRoomViewController *)self.presentingViewController;
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onRefreshUserList:) name:@"RefreshUserList" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [app.userArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    WSTUser *user = [app userWithIndex:section];
    return [user.deviceArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
    
    // Configure the cell...
    WSTUser *user = [app userWithIndex:indexPath.section];
    WSTVideoDevice *videoDevice = [user.deviceArray objectAtIndex:indexPath.row];
    
    UILabel *lblDeviceText = [cell.contentView viewWithTag:21];
    if (indexPath.row == 0) {
        lblDeviceText.text = user.userName;
    }
    else {
        lblDeviceText.text = videoDevice.deviceID;
    }
    
    //User
    UIButton *btnUser = [cell.contentView viewWithTag:10];
    if (user.isHost) {
        [btnUser setImage:[UIImage imageNamed:@"UserHost"] forState:UIControlStateNormal];
        //lblDeviceID.font = [UIFont boldSystemFontOfSize:15.0];
    }
    else if (user.isMe) {
        [btnUser setImage:[UIImage imageNamed:@"UserMe"] forState:UIControlStateNormal];
        //lblDeviceID.font = [UIFont boldSystemFontOfSize:15.0];
    }
    else {
//        if (app.userMe.isHost) {
//            [btnUser setImage:[UIImage imageNamed:@"UserKick"] forState:UIControlStateNormal];
//        }
//        else {
            [btnUser setImage:[UIImage imageNamed:@"User"] forState:UIControlStateNormal];
//        }
    }
    
    //Video
    UIView *deviceView = [cell.contentView viewWithTag:20];
    deviceView.layer.cornerRadius = 5;
    UIButton *btnVideo = [cell.contentView viewWithTag:11];
    UIColor *deviceColor = [UIColor colorWithRed:(float)117/255 green:(float)186/255 blue:(float)255/255 alpha:1];
    if (videoDevice.isOpened) {
        deviceView.backgroundColor = deviceColor;
        [btnVideo setImage:[UIImage imageNamed:@"Camera"] forState:UIControlStateNormal];
    }
    else {
        deviceView.backgroundColor = [UIColor clearColor];
        [btnVideo setImage:[UIImage imageNamed:@"CameraGray"] forState:UIControlStateNormal];
    }
    
    //Speak
    UIButton *btnSpeak = [cell.contentView viewWithTag:12];
    switch (user.speakStatus) {
        case PERMISSION_STATUS_GRANTED:
            [btnSpeak setImage:[UIImage imageNamed:@"Microphone"] forState:UIControlStateNormal];
            break;
        case PERMISSION_STATUS_APPLYING:
            [btnSpeak setImage:[UIImage imageNamed:@"ApplySpeak"] forState:UIControlStateNormal];
            break;
        default:
            [btnSpeak setImage:[UIImage imageNamed:@"MicrophoneGray"] forState:UIControlStateNormal];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WSTUser *user = [app userWithIndex:indexPath.section];
    WSTVideoDevice *videoDevice = [user.deviceArray objectAtIndex:indexPath.row];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_liveRoomViewController switchOpenUser:user videoDevice:videoDevice completion:^{
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    });
}

- (IBAction)userDeviceButton_Clicked:(UIButton *)sender {
    UITableViewCell *cell = (UITableViewCell *)sender.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    WSTUser *user = [app userWithIndex:indexPath.section];
    WSTVideoDevice *videoDevice = [user.deviceArray objectAtIndex:indexPath.row];
    
    //User
    if (sender.tag == 10) {
        if (!app.userMe.isHost || user.isMe) {
            return;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:user.userName message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *actionKickUser = [UIAlertAction actionWithTitle:@"踢出房间" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [enterConfApi kickUser:user.userID];
        }];
        [alertController addAction:actionKickUser];
        
        if (!app.isLiveRoom) {
            UIAlertAction *actionChangeChairman = [UIAlertAction actionWithTitle:@"置换主席" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [enterConfApi changeConfChairman:user.userID];
            }];
            [alertController addAction:actionChangeChairman];
        }
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:actionCancel];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    //Video
    else if (sender.tag == 11) {
        if (!app.isOnlyAudio) {
            if (!user.isHost) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_liveRoomViewController switchOpenUser:user videoDevice:videoDevice completion:^{
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                });
            }
        }
    }
    //Speak
    else if (sender.tag == 12) {
        if ([enterConfApi getRoomMode] != ROOM_MODE_LIVE
            && [enterConfApi getRoomMode] != ROOM_MODE_COMMUNICATION)
        {
            if (user.isMe) {
                if (user.speakStatus != PERMISSION_STATUS_APPLYING && user.speakStatus != PERMISSION_STATUS_GRANTED) {
                    [enterConfApi applySpeakPermission:TRUE];
                }
            }
            else if (app.userMe.isHost) {
                if (user.speakStatus == PERMISSION_STATUS_APPLYING) {
                    [enterConfApi grantSpeakPermission:user.userID];
                }
            }
        }
    }
}

- (void)onRefreshUserList:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (IBAction)doneAction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
