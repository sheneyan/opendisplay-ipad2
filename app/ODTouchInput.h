#import <Foundation/Foundation.h>

/* Main-thread gesture policy, independent of UIKit for deterministic tests. */
@interface ODTouchInput : NSObject
@property(nonatomic) BOOL settingsEnabled;
@property(nonatomic, copy) void (^onMessage)(NSDictionary *message);
@property(nonatomic, copy) void (^onSettings)(void);
- (void)setViewWidth:(double)width height:(double)height videoWidth:(double)videoWidth height:(double)videoHeight;
/* Point is the single contact, or the centroid of two contacts, in view points. */
- (void)updateCount:(NSUInteger)count x:(double)x y:(double)y;
- (void)hold;
- (void)cancel;
@end
