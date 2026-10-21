#import "ODReceiver.h"

/* Serial network calls are delivered asynchronously to the main/UI thread.
   At most three video frames / 8 MiB wait for rendering. Overflow invalidates
   dependent frames and resets decoding before accepting another sequence. */
@interface ODVideoDelivery : NSObject <ODVideoSink>
@property(nonatomic, copy) void (^requestKeyframe)(void);
@property(nonatomic, readonly) NSUInteger submittedFrames;
@property(nonatomic, readonly) NSUInteger decodeErrors;
@property(nonatomic, readonly) NSString *streamDescription;
- (instancetype)initWithRenderer:(id<ODVideoSink>)renderer;
@end
