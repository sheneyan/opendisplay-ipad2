#import <Foundation/Foundation.h>

NSArray<NSNumber *> *ODResolutionWidths(BOOL video);
NSDictionary *ODDisplayFields(BOOL expanded, NSUserDefaults *defaults);
NSDictionary *ODDisplayFieldsForOrientation(BOOL expanded, NSUserDefaults *defaults, BOOL portrait);

NSInteger ODRotationQuarterTurns(NSUserDefaults *defaults);
NSInteger ODRotateClockwise(NSUserDefaults *defaults);
