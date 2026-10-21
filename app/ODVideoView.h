#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ODReceiver.h"
@interface ODVideoView : UIView <ODVideoSink>
@property(nonatomic, copy) void (^requestKeyframe)(void);
@property(nonatomic, readonly) NSUInteger submittedFrames;
@property(nonatomic, readonly) NSUInteger decodeErrors;
@property(nonatomic, readonly) NSString *streamDescription;
@property(nonatomic, readonly) CGSize videoPixelSize;
@property(nonatomic, copy) void (^onGeometryChanged)(void);
/* All renderer operations run on the main thread via ODVideoDelivery. */
- (void)consumeVideo:(NSData *)payload;
- (void)resetStream;
- (void)applyCursorMessage:(NSDictionary *)message;
@end
