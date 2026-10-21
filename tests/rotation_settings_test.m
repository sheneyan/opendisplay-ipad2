#import <Foundation/Foundation.h>
#import "ODDisplaySettings.h"
extern NSInteger ODRotationQuarterTurns(NSUserDefaults *defaults);
extern NSInteger ODRotateClockwise(NSUserDefaults *defaults);
#define CHECK(c, message) do { if (!(c)) { fprintf(stderr,"FAIL: %s\n",message); return 1; } } while (0)
int main(void) {
    @autoreleasepool {
        NSString *suite=[@"rotation-test-" stringByAppendingString:[NSUUID UUID].UUIDString];
        NSUserDefaults *defaults=[[NSUserDefaults alloc] initWithSuiteName:suite];
        CHECK(ODRotationQuarterTurns(defaults)==0,"default direction must be landscape");
        [defaults setInteger:1600 forKey:@"ODDesktopWidth"];
        [defaults setInteger:2048 forKey:@"ODVideoWidth"];
        for (NSInteger turn=1;turn<=4;turn++) {
            CHECK(ODRotateClockwise(defaults)==turn%4,"Rotate must advance exactly 90 degrees and wrap");
            NSUserDefaults *reopened=[[NSUserDefaults alloc] initWithSuiteName:suite];
            NSInteger saved=ODRotationQuarterTurns(reopened);
            CHECK(saved==turn%4,"direction must survive reopening preferences");
            NSDictionary *f=ODDisplayFieldsForOrientation(YES,reopened,saved%2!=0);
            CHECK([f[@"pixelsWide"] integerValue]==(saved%2 ? 2400:3200),"desktop follows saved direction");
            CHECK([f[@"maxEncodeWide"] integerValue]==(saved%2 ? 1536:2048),"video ceiling follows saved direction");
            CHECK([defaults integerForKey:@"ODDesktopWidth"]==1600 && [defaults integerForKey:@"ODVideoWidth"]==2048,"rotation preserves independent presets");
        }
        for (id bad in @[@(-1),@4,@100,@"bad",@1.5]) {
            [defaults setObject:bad forKey:@"ODRotationQuarterTurns"];
            CHECK(ODRotationQuarterTurns(defaults)==0,"invalid direction falls back to landscape");
        }
        [defaults removePersistentDomainForName:suite];
        puts("PASS: manual direction cycle, persistence, preset isolation and invalid preferences");
    }
    return 0;
}
