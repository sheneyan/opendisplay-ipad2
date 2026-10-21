#import <Foundation/Foundation.h>
@protocol ODVideoSink <NSObject>
@property(nonatomic, copy) void (^requestKeyframe)(void);
@property(nonatomic, readonly) NSUInteger submittedFrames;
@property(nonatomic, readonly) NSUInteger decodeErrors;
@property(nonatomic, readonly) NSString *streamDescription;
- (void)consumeVideo:(NSData *)payload;
- (void)resetStream;
- (void)applyCursorMessage:(NSDictionary *)message;
@end
@interface ODReceiver : NSObject
@property(nonatomic, copy) void (^onStatus)(NSString *);
- (instancetype)initWithVideoView:(id<ODVideoSink>)view;
- (void)start;
- (void)stop;
@end
