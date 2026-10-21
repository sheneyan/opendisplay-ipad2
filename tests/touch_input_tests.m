#import <Foundation/Foundation.h>
#import "ODTouchInput.h"
#include <math.h>
#include <stdlib.h>
#define CHECK(c, message) do { if (!(c)) { fprintf(stderr, "FAIL: %s\n", message); exit(1); } } while (0)
static BOOL near(NSNumber *value, double expected) { return fabs(value.doubleValue-expected) < 0.00001; }
int main(void) { @autoreleasepool {
    ODTouchInput *input = [ODTouchInput new];
    NSMutableArray *events = [NSMutableArray array];
    __block int settings = 0;
    input.onMessage = ^(NSDictionary *event) { [events addObject:event]; };
    input.onSettings = ^{ settings++; };
    [input setViewWidth:1024 height:768 videoWidth:2048 height:1536];
    [input updateCount:1 x:256 y:192];
    CHECK(events.count == 0, "finger down must not click before intent is known");
    [input updateCount:0 x:256 y:192];
    CHECK(events.count == 2, "tap must emit down and up");
    CHECK([events[0][@"phase"] isEqual:@"began"] && [events[1][@"phase"] isEqual:@"ended"], "tap phases");
    CHECK(near(events[0][@"x"],.25) && near(events[0][@"y"],.25), "normalized video coordinate");
    [events removeAllObjects];
    [input updateCount:1 x:100 y:100]; [input updateCount:1 x:103 y:104];
    CHECK(events.count == 0, "small finger jitter must not start dragging");
    [input updateCount:1 x:140 y:120];
    CHECK(events.count == 2 && [events[1][@"phase"] isEqual:@"moved"], "drag down plus move");
    CHECK(near(events[0][@"x"],100.0/1024), "drag starts at original contact");
    [input updateCount:0 x:150 y:130];
    CHECK([events.lastObject[@"phase"] isEqual:@"ended"], "drag release");
    [events removeAllObjects];
    input.settingsEnabled = YES;
    [input updateCount:1 x:100 y:100]; [input hold]; [input updateCount:0 x:100 y:100];
    CHECK(settings == 1 && events.count == 0, "mini settings hold must not click Mac");
    [input updateCount:1 x:100 y:100]; [input updateCount:1 x:120 y:100]; [input hold];
    CHECK(settings == 1, "drag must suppress settings hold");
    [input cancel];
    CHECK([events.lastObject[@"phase"] isEqual:@"cancelled"], "cancel must release active drag");
    [input updateCount:0 x:120 y:100]; [events removeAllObjects];
    [input updateCount:1 x:100 y:100]; [input updateCount:2 x:200 y:200];
    CHECK(events.count == 1 && [events[0][@"phase"] isEqual:@"moved"], "two fingers position cursor without clicking");
    [input updateCount:2 x:210 y:230];
    CHECK([events.lastObject[@"type"] isEqual:@"scroll"] && near(events.lastObject[@"dx"],20) && near(events.lastObject[@"dy"],60), "natural scroll delta in video pixels");
    NSUInteger before = events.count;
    [input updateCount:1 x:210 y:230]; [input updateCount:1 x:260 y:230]; [input updateCount:0 x:260 y:230];
    CHECK(events.count == before, "lifting one scrolling finger must not create click or drag");
    [events removeAllObjects];
    [input updateCount:1 x:100 y:100]; [input updateCount:1 x:130 y:100]; [input updateCount:2 x:150 y:100];
    CHECK([events[2][@"phase"] isEqual:@"cancelled"], "second finger cancels existing drag before scroll");
    [input updateCount:0 x:150 y:100]; [events removeAllObjects];
    [input setViewWidth:1000 height:1000 videoWidth:2000 height:1000];
    [input updateCount:1 x:500 y:100]; [input updateCount:0 x:500 y:100];
    CHECK(events.count == 0, "letterbox taps must not reach Mac");
    [input updateCount:1 x:250 y:375]; [input updateCount:0 x:250 y:375];
    CHECK(near(events[0][@"x"],.25) && near(events[0][@"y"],.25), "aspect-fit mapping subtracts letterbox");
    [events removeAllObjects];
    [input updateCount:1 x:500 y:500]; [input updateCount:1 x:1100 y:1100];
    CHECK(near(events.lastObject[@"x"],1) && near(events.lastObject[@"y"],1), "drag clamps at image bounds");
    [input setViewWidth:1024 height:768 videoWidth:1024 height:768];
    CHECK([events.lastObject[@"phase"] isEqual:@"cancelled"], "geometry change releases drag");
    before=events.count; [input updateCount:1 x:100 y:100]; [input updateCount:0 x:100 y:100];
    CHECK(events.count == before, "cancelled contacts stay suppressed until lifted");
    [events removeAllObjects];
    [input updateCount:1 x:100 y:100]; [input updateCount:3 x:120 y:120]; [input updateCount:0 x:120 y:120];
    CHECK(events.count == 0, "three-finger gesture must not click");
    [input setViewWidth:1024 height:768 videoWidth:0 height:0];
    [input updateCount:1 x:50 y:50]; [input hold]; [input updateCount:0 x:50 y:50];
    CHECK(settings == 2 && events.count == 0, "mini settings remains available without video");
    puts("PASS: tap, drag, natural two-finger scroll, settings hold, aspect-fit mapping and cancellation");
} }
