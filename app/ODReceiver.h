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
@property(nonatomic, copy) void (^onInputReset)(void);
@property(atomic, readonly) NSUInteger inputSession;
- (void)sendInput:(NSDictionary *)message session:(NSUInteger)session;
- (instancetype)initWithVideoView:(id<ODVideoSink>)view;
- (void)setPortrait:(BOOL)portrait;
- (void)start;
- (void)stop;
@end
