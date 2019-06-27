#import "AudioMixingViewController.h"
#import "Application.h"
#import "MyAudioApi.h"

@interface AudioMixingViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *musicFileTableView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UISwitch *loopbackSwitch;
@property (weak, nonatomic) IBOutlet UITextField *loopTimesTextField;

@end

@implementation AudioMixingViewController
{
    NSString *_selectedMusicFileName;
    NSIndexPath *_selectedIndexPath;
    NSString *_documentsDirectory;
    NSMutableArray *_musicFileNames;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.delegate == nil) {
        if ([self.presentingViewController conformsToProtocol:@protocol(AudioMixingViewControllerDelegate)]) {
            self.delegate = (id<AudioMixingViewControllerDelegate>)self.presentingViewController;
        }
    }

    _selectedMusicFileName = [[NSUserDefaults standardUserDefaults] objectForKey:@"SelectedMusicFileName"];
    _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsDirectory = [directories firstObject];
    _musicFileNames = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *shortFileName in [fileManager enumeratorAtPath:_documentsDirectory]) {
        NSString *fileExtension = [[shortFileName pathExtension] lowercaseString];
        if ([fileExtension isEqualToString:@"mp3"]
            || [fileExtension isEqualToString:@"aac"]
            || [fileExtension isEqualToString:@"ogg"]
            || [fileExtension isEqualToString:@"wav"]
            || [fileExtension isEqualToString:@"flac"])
        {
            [_musicFileNames addObject:shortFileName];
            if ([_selectedMusicFileName hasSuffix:shortFileName]) {
                _selectedIndexPath = [NSIndexPath indexPathForRow:[_musicFileNames indexOfObject:shortFileName] inSection:0];
            }
        }
    }
    if (_musicFileNames.count > 0) {
        [self.musicFileTableView selectRowAtIndexPath:_selectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        self.infoLabel.text = [NSString stringWithFormat:@"“文稿”目录共有 %ld 个音乐文件可供播放", _musicFileNames.count];
    }
    else {
        self.infoLabel.text = @"请通过“iTunes”往“文稿”目录添加音乐文件！";
    }
    
    self.loopbackSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"AudioMixingLoopback"];
    self.loopTimesTextField.text = [NSString stringWithFormat:@"%ld",
        [[NSUserDefaults standardUserDefaults] integerForKey:@"AudioMixingLoopTimes"]];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _musicFileNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"musicFileCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = _musicFileNames[indexPath.row];
    
    if ((indexPath.row == _selectedIndexPath.row) && (_selectedMusicFileName != nil)) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (IBAction)playMusicFile:(id)sender {
    NSIndexPath *indexPath = [self.musicFileTableView indexPathForSelectedRow];
    if (indexPath == nil) {
        [Application showAlert:self message:@"请选择要播放的音乐文件！"];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playMusicFile:loopback:loopTimes:)]) {
        int loopTimes = [self.loopTimesTextField.text intValue];
        [[NSUserDefaults standardUserDefaults] setBool:self.loopbackSwitch.on forKey:@"AudioMixingLoopback"];
        [[NSUserDefaults standardUserDefaults] setInteger:loopTimes forKey:@"AudioMixingLoopTimes"];
        [self.delegate playMusicFile:[_documentsDirectory stringByAppendingPathComponent:_musicFileNames[indexPath.row]]
                            loopback:self.loopbackSwitch.on loopTimes:loopTimes];
    }
}

@end
