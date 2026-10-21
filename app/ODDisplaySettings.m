#import "ODDisplaySettings.h"

NSArray<NSNumber *> *ODResolutionWidths(BOOL video) {
    return video ? @[@1024, @1280, @1440, @1600, @1920, @2048]
                 : @[@1024, @1280, @1440, @1600, @1920, @2048, @2560, @3072, @4096];
}
static NSInteger selectedWidth(NSUserDefaults *defaults, NSString *key, BOOL video) {
    NSInteger width = [defaults integerForKey:key];
    return [ODResolutionWidths(video) containsObject:@(width)] ? width : (video ? 2048 : 1280);
}
NSDictionary *ODDisplayFields(BOOL expanded, NSUserDefaults *defaults) {
    NSInteger desktop = expanded ? selectedWidth(defaults, @"ODDesktopWidth", NO) : 1280;
    NSInteger video = expanded ? selectedWidth(defaults, @"ODVideoWidth", YES) : 1024;
    NSInteger panel = expanded ? 2048 : 1024;
    return @{
        // OpenDisplay 1.19 divides the legacy dimensions by two for desktop points.
        @"pixelsWide":@(desktop*2), @"pixelsHigh":@(desktop*3/2), @"scale":@1,
        @"maxEncodeWide":@(video), @"maxEncodeHigh":@(video*3/4),
        @"displayMaxFrameRate":@30,
        @"panel":@{@"pixelsWide":@(panel), @"pixelsHigh":@(panel*3/4), @"scale":@(expanded ? 2 : 1)},
        @"videoCaps":@[@{@"codec":@"h264", @"maxWidth":@(video), @"maxHeight":@(video*3/4), @"maxFrameRate":@30}]
    };
}
