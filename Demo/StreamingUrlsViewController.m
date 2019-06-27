#import "StreamingUrlsViewController.h"
#import "StreamingPlayerViewController.h"

@interface StreamingUrlsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *urlsTableView;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@end

@implementation StreamingUrlsViewController
{
    NSMutableArray *_streamingUrls;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *urlsArray = [userDefaults objectForKey:@"StreamingUrls"];
    if (urlsArray.count > 0) {
        _streamingUrls = [NSMutableArray arrayWithArray:urlsArray];
    }
    else {
        _streamingUrls = [NSMutableArray arrayWithObjects:@"rtmp://live.hkstv.hk.lxdns.com/live/hks", nil];
    }
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

/**
 保存流媒体地址
 */
- (void)saveStreamingUrls {
    NSArray *urlsArray = [NSArray arrayWithArray:_streamingUrls];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:urlsArray forKey:@"StreamingUrls"];
}

/**
 播放流媒体
 
 @param urlString 流媒体地址
 */
- (void)playStreaming:(NSString *)urlString {
    if ([_streamingUrls containsObject:urlString]) {
        NSInteger urlIndex = [_streamingUrls indexOfObject:urlString];
        if (urlIndex > 0) {
            [_streamingUrls removeObjectAtIndex:urlIndex];
            [_streamingUrls insertObject:urlString atIndex:0];
        }
    }
    else {
        [_streamingUrls insertObject:urlString atIndex:0];
    }
    [self saveStreamingUrls];
    [self.urlsTableView reloadData];
    
    StreamingPlayerViewController *spvc = [self.storyboard instantiateViewControllerWithIdentifier:@"StreamingPlayer"];
    spvc.url = [NSURL URLWithString:urlString];
    spvc.streamingUrls = _streamingUrls;
    [self presentViewController:spvc animated:NO completion:nil];
}

/**
 点击“播放”
 */
- (IBAction)onClickPlayButton:(id)sender {
    NSString *streamingUrl = [self.urlTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (streamingUrl.length == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"请输入流媒体地址！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    NSString *scheme = [[url scheme] lowercaseString];
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] && ![scheme isEqualToString:@"rtmp"]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"流媒体地址格式不正确！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
        
    }
    
    if (self.urlsTableView.editing) {
        [self.urlsTableView setEditing:NO animated:YES];
    }
    [self playStreaming:streamingUrl];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _streamingUrls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"urlCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = _streamingUrls[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *streamingUrl = _streamingUrls[indexPath.row];
    self.urlTextField.text = streamingUrl;
    [self playStreaming:streamingUrl];
}

- (IBAction)onEditUrlsTableView:(id)sender {
    [self.urlsTableView setEditing:!self.urlsTableView.editing animated:YES];
    if (self.urlsTableView.editing) {
        self.editButton.title = @"完成";
    }
    else {
        self.editButton.title = @"编辑";
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_streamingUrls removeObjectAtIndex:indexPath.row];
        [self saveStreamingUrls];
        [self.urlsTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    [_streamingUrls exchangeObjectAtIndex:destinationIndexPath.row withObjectAtIndex:sourceIndexPath.row];
    [self saveStreamingUrls];
}

@end
