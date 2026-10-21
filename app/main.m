#import "ODLog.h"
#import <UIKit/UIKit.h>
#import "ODReceiver.h"
#import "ODVideoView.h"
#import "ODDisplaySettings.h"
#import "ODTouchView.h"
#include <math.h>

@interface LegacySettingsController : UITableViewController
@property(nonatomic, copy) void (^onConfigurationChanged)(void);
@property(nonatomic, copy) void (^onRotate)(void);
@property(nonatomic, copy) void (^onClose)(void);
@end
@implementation LegacySettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Display Settings";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
}
- (void)closeSettings { if (self.onClose) self.onClose(); }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#if OD_RETINA_SETTINGS
    return 3;
#else
    return 1;
#endif
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section==0 ? 1 : ODResolutionWidths(section==2).count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section==0 ? @"Orientation" : section==1 ? @"Desktop Size" : @"Video Quality";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section==0) return @"Rotate clockwise by 90°. The direction is saved and does not follow gravity. The display reconnects; recovery can take several seconds.";
    return section==1
        ? @"Tap a size to apply it. Larger desktops fit more content with smaller text. Sizes above 2048 × 1536 are experimental. Scroll down for Video Quality."
        : @"Higher video sizes send more detail. If playback fails, choose a lower value. Changes are saved and reconnect this display. Tap Done to return.";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"setting"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"setting"];
    cell.accessoryType=UITableViewCellAccessoryNone;
    if (indexPath.section==0) {
        cell.textLabel.text=@"Rotate 90°";
        return cell;
    }
    BOOL video=indexPath.section==2;
    NSInteger width=[ODResolutionWidths(video)[indexPath.row] integerValue];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSDictionary *fields=ODDisplayFields(YES,defaults);
    NSInteger selected=video ? [fields[@"maxEncodeWide"] integerValue] : [fields[@"pixelsWide"] integerValue]/2;
    BOOL portrait=ODRotationQuarterTurns(defaults)%2!=0;
    cell.textLabel.text=[NSString stringWithFormat:@"%ld × %ld%@",(long)(portrait ? width*3/4:width),(long)(portrait ? width:width*3/4),
        !video && width>2048 ? @" (experimental)" : @""];
    cell.accessoryType=width==selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) { if (self.onRotate) self.onRotate(); return; }
    BOOL video=indexPath.section==2;
    NSInteger width=[ODResolutionWidths(video)[indexPath.row] integerValue];
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setInteger:width forKey:video ? @"ODVideoWidth" : @"ODDesktopWidth"];
    [defaults synchronize];
    ODLog(@"LegacyDisplay selected %@ %ldx%ld",video ? @"video":@"desktop",(long)width,(long)(width*3/4));
    [tableView reloadData];
    if (self.onConfigurationChanged) self.onConfigurationChanged();
}
@end

@interface LegacyViewController : UIViewController
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, copy) void (^onConfigurationChanged)(void);
@property(nonatomic, copy) void (^onOrientationChanged)(BOOL portrait);
@property(nonatomic, copy) void (^onWillRotate)(void);
@end
@implementation LegacyViewController {
    NSInteger _quarterTurns;
    UINavigationController *_settings;
}
- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor=[UIColor blackColor];
    _contentView=[[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_contentView];
    _quarterTurns=ODRotationQuarterTurns([NSUserDefaults standardUserDefaults]);
    [self layoutContent];
}
- (UIView *)contentView {
    if (!_contentView) [self loadViewIfNeeded];
    return _contentView;
}
- (void)layoutContent {
    CGSize size=self.view.bounds.size;
    // All visible content and touch coordinates share this local canvas.
    // The UIKit interface stays landscape; sensors never change the canvas.
    _contentView.bounds=CGRectMake(0,0,_quarterTurns%2 ? size.height:size.width,_quarterTurns%2 ? size.width:size.height);
    _contentView.center=CGPointMake(CGRectGetMidX(self.view.bounds),CGRectGetMidY(self.view.bounds));
    _contentView.transform=CGAffineTransformMakeRotation(_quarterTurns*M_PI_2);
    _settings.view.frame=_contentView.bounds;
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; [self layoutContent]; }
- (void)closeSettings {
    if (!_settings) return;
    [_settings willMoveToParentViewController:nil];
    [_settings.view removeFromSuperview];
    [_settings removeFromParentViewController];
    _settings=nil;
}
- (void)rotateDisplay {
    if (self.onWillRotate) self.onWillRotate();
    [self closeSettings];
    _quarterTurns=ODRotateClockwise([NSUserDefaults standardUserDefaults]);
    [self layoutContent];
    if (self.onOrientationChanged) self.onOrientationChanged(_quarterTurns%2!=0);
    ODLog(@"LegacyDisplay manual rotation %ld degrees",(long)(_quarterTurns*90));
}
- (void)openSettings {
    if (_settings) return;
    LegacySettingsController *settings=[[LegacySettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    settings.onConfigurationChanged=self.onConfigurationChanged;
    __weak LegacyViewController *weakSelf=self;
    settings.onRotate=^{ [weakSelf rotateDisplay]; };
    settings.onClose=^{ [weakSelf closeSettings]; };
    _settings=[[UINavigationController alloc] initWithRootViewController:settings];
    [self addChildViewController:_settings];
    _settings.view.frame=_contentView.bounds;
    [_contentView addSubview:_settings.view];
    [_settings didMoveToParentViewController:self];
}
- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskLandscapeLeft; }
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation { return UIInterfaceOrientationLandscapeLeft; }
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
    ODVideoView *video = [[ODVideoView alloc] initWithFrame:controller.contentView.bounds];
    video.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [controller.contentView addSubview:video];
    self.touchView=[[ODTouchView alloc] initWithFrame:controller.contentView.bounds];
    self.touchView.autoresizingMask=UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [controller.contentView addSubview:self.touchView];
    __weak ODVideoView *weakVideo=video;
    __weak ODTouchView *weakTouch=self.touchView;
    self.touchView.videoSize=^{
        CGSize videoSize=weakVideo.videoPixelSize, bounds=weakTouch.bounds.size;
        // A frame from the previous orientation must not receive new touch input.
        if ((videoSize.height>videoSize.width) != (bounds.height>bounds.width)) return CGSizeZero;
        return videoSize;
    };
    video.onGeometryChanged=^{ [weakTouch refreshGeometry]; };
    __weak LegacyViewController *weakController=controller;
    self.touchView.onSettings=^{ [weakTouch cancelInput]; [weakController openSettings]; };
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0, controller.contentView.bounds.size.height-32,
                                                               controller.contentView.bounds.size.width, 32)];
    status.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    status.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    status.textColor = [UIColor whiteColor];
    status.textAlignment = NSTextAlignmentCenter;
    status.font = [UIFont systemFontOfSize:12];
    status.text = @"Legacy Display - starting USB receiver";
    status.hidden = YES;
    [controller.contentView addSubview:status];
    self.receiver = [[ODReceiver alloc] initWithVideoView:video];
    self.receiver.onStatus = ^(NSString *text) { status.text = text; };
    __weak ODReceiver *receiver = self.receiver;
    self.touchView.session=^{ return receiver.inputSession; };
    self.touchView.onMessage=^(NSDictionary *message, NSUInteger session) { [receiver sendInput:message session:session]; };
    self.receiver.onInputReset=^{ [weakTouch cancelInput]; };
    controller.onConfigurationChanged = ^{ [receiver stop]; [receiver start]; };
    controller.onWillRotate=^{ [weakTouch cancelInput]; };
    controller.onOrientationChanged=^(BOOL portrait) {
        [weakTouch cancelInput];
        [receiver setPortrait:portrait];
        [weakTouch refreshGeometry];
    };
    [self.receiver setPortrait:ODRotationQuarterTurns([NSUserDefaults standardUserDefaults])%2!=0];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    application.idleTimerDisabled = YES;
    ODLog(@"LegacyDisplay receiver build %@ launched; system=%@",
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
