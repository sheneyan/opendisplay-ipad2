#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ODReceiver.h"
@interface ODVideoView : UIView <ODVideoSink>
@property(nonatomic, copy) void (^requestKeyframe)(void);
@property(nonatomic, readonly) NSUInteger submittedFrames;
@property(nonatomic, readonly) NSUInteger decodeErrors;
@property(nonatomic, readonly) NSString *streamDescription;
/* consume/reset are called only on the receiver's serial queue. */
- (void)consumeVideo:(NSData *)payload;
- (void)resetStream;
- (void)applyCursorMessage:(NSDictionary *)message;
@end
