#import <UIKit/UIKit.h>
#import "ODReceiver.h"
#import "ODVideoView.h"
#import "ODDisplaySettings.h"
#import "ODTouchView.h"

#if OD_RETINA_SETTINGS
@interface LegacySettingsController : UITableViewController
@property(nonatomic, copy) void (^onConfigurationChanged)(void);
@end
@implementation LegacySettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Display Settings";
    self.preferredContentSize = CGSizeMake(560, 620);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
}
- (void)closeSettings { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ODResolutionWidths(section == 1).count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Desktop Size" : @"Video Quality";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 0
        ? @"Tap a size to apply it. Larger desktops fit more content with smaller text. Sizes above 2048 × 1536 are experimental. Scroll down for Video Quality."
        : @"Higher video sizes send more detail. If playback fails, choose a lower value. Changes are saved and reconnect this display. Tap Done to return.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"resolution"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"resolution"];
    BOOL video = indexPath.section == 1;
    NSInteger width = [ODResolutionWidths(video)[indexPath.row] integerValue];
    NSDictionary *fields = ODDisplayFields(YES, [NSUserDefaults standardUserDefaults]);
    NSInteger selected = video ? [fields[@"maxEncodeWide"] integerValue] : [fields[@"pixelsWide"] integerValue]/2;
    cell.textLabel.text = [NSString stringWithFormat:@"%ld × %ld%@", (long)width, (long)(width*3/4),
        !video && width > 2048 ? @" (experimental)" : @""];
    cell.accessoryType = width == selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL video = indexPath.section == 1;
    NSInteger width = [ODResolutionWidths(video)[indexPath.row] integerValue];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:width forKey:video ? @"ODVideoWidth" : @"ODDesktopWidth"];
    [defaults synchronize];
    NSLog(@"LegacyDisplay selected %@ %ldx%ld", video ? @"video" : @"desktop", (long)width, (long)(width*3/4));
    [tableView reloadData];
    if (self.onConfigurationChanged) self.onConfigurationChanged();
}
@end
#endif

@interface LegacyViewController : UIViewController
@property(nonatomic, copy) void (^onConfigurationChanged)(void);
@end
@implementation LegacyViewController
#if OD_RETINA_SETTINGS
- (void)openSettings {
    if (self.presentedViewController) return;
    LegacySettingsController *settings = [[LegacySettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    settings.onConfigurationChanged = self.onConfigurationChanged;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
    navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    navigation.preferredContentSize = CGSizeMake(560, 620);
    [self presentViewController:navigation animated:YES completion:nil];
}
#endif
- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskLandscape; }
@end

@interface LegacyAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) ODReceiver *receiver;
@property(nonatomic, strong) ODTouchView *touchView;
@end

@implementation LegacyAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    LegacyViewController *controller = [[LegacyViewController alloc] init];
    ODVideoView *video = [[ODVideoView alloc] initWithFrame:controller.view.bounds];
    video.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [controller.view addSubview:video];
    self.touchView=[[ODTouchView alloc] initWithFrame:controller.view.bounds];
    self.touchView.autoresizingMask=UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [controller.view addSubview:self.touchView];
    __weak ODVideoView *weakVideo=video;
    __weak ODTouchView *weakTouch=self.touchView;
    self.touchView.videoSize=^{ return weakVideo.videoPixelSize; };
    video.onGeometryChanged=^{ [weakTouch refreshGeometry]; };
#if OD_RETINA_SETTINGS
    __weak LegacyViewController *weakController=controller;
    self.touchView.onSettings=^{ [weakTouch cancelInput]; [weakController openSettings]; };
#endif
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0, controller.view.bounds.size.height-32,
                                                               controller.view.bounds.size.width, 32)];
    status.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    status.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    status.textColor = [UIColor whiteColor];
    status.textAlignment = NSTextAlignmentCenter;
    status.font = [UIFont systemFontOfSize:12];
    status.text = @"Legacy Display - starting USB receiver";
    status.hidden = YES;
    [controller.view addSubview:status];
    self.receiver = [[ODReceiver alloc] initWithVideoView:video];
    self.receiver.onStatus = ^(NSString *text) { status.text = text; };
    __weak ODReceiver *receiver = self.receiver;
    self.touchView.session=^{ return receiver.inputSession; };
    self.touchView.onMessage=^(NSDictionary *message, NSUInteger session) { [receiver sendInput:message session:session]; };
    self.receiver.onInputReset=^{ [weakTouch cancelInput]; };
    controller.onConfigurationChanged = ^{ [receiver stop]; [receiver start]; };
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    application.idleTimerDisabled = YES;
    NSLog(@"LegacyDisplay receiver build %@ launched; system=%@",
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], [UIDevice currentDevice].systemVersion);
    return YES;
}
- (void)applicationDidBecomeActive:(UIApplication *)application { [self.receiver start]; }
- (void)applicationWillResignActive:(UIApplication *)application { [self.touchView cancelInput]; }
- (void)applicationDidEnterBackground:(UIApplication *)application { [self.receiver stop]; }
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([LegacyAppDelegate class]));
    }
}
