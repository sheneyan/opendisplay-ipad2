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
    return ODDisplayFieldsForOrientation(expanded, defaults, NO);
}
NSDictionary *ODDisplayFieldsForOrientation(BOOL expanded, NSUserDefaults *defaults, BOOL portrait) {
    NSInteger desktop = expanded ? selectedWidth(defaults, @"ODDesktopWidth", NO) : 1280;
    NSInteger video = expanded ? selectedWidth(defaults, @"ODVideoWidth", YES) : 1024;
    NSInteger panel = expanded ? 2048 : 1024;
    return @{
        // OpenDisplay 1.19 divides the legacy dimensions by two for desktop points.
        @"pixelsWide":@(portrait ? desktop*3/2 : desktop*2), @"pixelsHigh":@(portrait ? desktop*2 : desktop*3/2), @"scale":@1,
        @"maxEncodeWide":@(portrait ? video*3/4 : video), @"maxEncodeHigh":@(portrait ? video : video*3/4),
        @"displayMaxFrameRate":@30,
        @"panel":@{@"pixelsWide":@(portrait ? panel*3/4 : panel), @"pixelsHigh":@(portrait ? panel : panel*3/4), @"scale":@(expanded ? 2 : 1)},
        @"videoCaps":@[@{@"codec":@"h264", @"maxWidth":@(portrait ? video*3/4 : video), @"maxHeight":@(portrait ? video : video*3/4), @"maxFrameRate":@30}]
    };
}

NSInteger ODRotationQuarterTurns(NSUserDefaults *defaults) {
    id value=[defaults objectForKey:@"ODRotationQuarterTurns"];
    if (![value isKindOfClass:[NSNumber class]]) return 0;
    NSInteger turns=[value integerValue];
    return turns>=0 && turns<4 && [value doubleValue]==(double)turns ? turns : 0;
}
NSInteger ODRotateClockwise(NSUserDefaults *defaults) {
    NSInteger turns=(ODRotationQuarterTurns(defaults)+1)%4;
    [defaults setInteger:turns forKey:@"ODRotationQuarterTurns"];
    [defaults synchronize];
    return turns;
}
