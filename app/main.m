#import <UIKit/UIKit.h>
#import "ODReceiver.h"
#import "ODVideoView.h"

@interface LegacyViewController : UIViewController
@end
@implementation LegacyViewController
- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)shouldAutorotate { return NO; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskLandscape; }
@end

@interface LegacyAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) ODReceiver *receiver;
@end

@implementation LegacyAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController *controller = [[LegacyViewController alloc] init];
    ODVideoView *video = [[ODVideoView alloc] initWithFrame:controller.view.bounds];
    video.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [controller.view addSubview:video];
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(0, controller.view.bounds.size.height-32,
                                                               controller.view.bounds.size.width, 32)];
    status.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    status.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    status.textColor = [UIColor whiteColor];
    status.textAlignment = NSTextAlignmentCenter;
    status.font = [UIFont systemFontOfSize:12];
    status.text = @"Legacy Display - starting USB receiver";
    [controller.view addSubview:status];
    self.receiver = [[ODReceiver alloc] initWithVideoView:video];
    self.receiver.onStatus = ^(NSString *text) { status.text = text; };
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    application.idleTimerDisabled = YES;
    NSLog(@"LegacyDisplay receiver build %@ launched; system=%@",
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], [UIDevice currentDevice].systemVersion);
    return YES;
}
- (void)applicationDidBecomeActive:(UIApplication *)application { [self.receiver start]; }
- (void)applicationDidEnterBackground:(UIApplication *)application { [self.receiver stop]; }
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([LegacyAppDelegate class]));
    }
}
