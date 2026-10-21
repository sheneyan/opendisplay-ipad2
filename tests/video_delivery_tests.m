#import <Foundation/Foundation.h>
#import "ODVideoDelivery.h"
#define CHECK(c,m) do { if(!(c)){fprintf(stderr,"FAIL: %s\n",m);return 1;} }while(0)
@interface RecordingRenderer : NSObject <ODVideoSink>
@property(nonatomic,copy) void (^requestKeyframe)(void);
@property(nonatomic,strong) NSMutableArray *frames;
@property(nonatomic) NSUInteger resets,cursors;
@property(nonatomic) BOOL wrongThread;
@end
@implementation RecordingRenderer
- (instancetype)init { if((self=[super init]))_frames=[NSMutableArray array]; return self; }
- (NSUInteger)submittedFrames { return _frames.count; }
- (NSUInteger)decodeErrors { return 0; }
- (NSString *)streamDescription { return @"recording"; }
- (void)consumeVideo:(NSData *)data { if(![NSThread isMainThread])_wrongThread=YES; [_frames addObject:data]; }
- (void)resetStream { if(![NSThread isMainThread])_wrongThread=YES; _resets++; }
- (void)applyCursorMessage:(NSDictionary *)message { if(![NSThread isMainThread])_wrongThread=YES; _cursors++; }
@end
static void drain(void) { [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.04]]; }
int main(void){@autoreleasepool{
 RecordingRenderer *sink=[RecordingRenderer new];ODVideoDelivery *delivery=[[ODVideoDelivery alloc] initWithRenderer:sink];
 __block NSUInteger requests=0;delivery.requestKeyframe=^{requests++;};
 NSData *frame=[@"frame" dataUsingEncoding:NSUTF8StringEncoding];
 for(int i=0;i<100;i++)[delivery consumeVideo:frame];
 CHECK(sink.frames.count==0,"delivery must never render inline on the caller");
 drain();
 CHECK(sink.frames.count==0 && sink.resets==1 && requests==1,"overflow must coalesce reset and discard dependent queued frames");
 [delivery consumeVideo:frame];drain();
 CHECK(sink.frames.count==1 && delivery.submittedFrames==1,"fresh data renders after bounded overflow recovery");
 [delivery consumeVideo:frame];[delivery applyCursorMessage:@{}];[delivery resetStream];
 NSData *fresh=[@"fresh" dataUsingEncoding:NSUTF8StringEncoding];[delivery consumeVideo:fresh];drain();
 CHECK(sink.frames.count==2 && [sink.frames.lastObject isEqual:fresh] && sink.cursors==0,"session reset rejects old video and cursor work");
 CHECK(sink.resets==2,"session reset must run exactly once");
 [delivery consumeVideo:[NSMutableData dataWithLength:8*1024*1024]];[delivery consumeVideo:frame];drain();
 CHECK(sink.frames.count==2 && sink.resets==3,"byte budget must also invalidate queued frames");
 for(int i=0;i<100;i++)[delivery applyCursorMessage:@{@"type":@"cursor",@"x":@(i)}];drain();
 CHECK(sink.cursors==1,"cursor backlog must coalesce while the UI queue is paused");
 CHECK(!sink.wrongThread,"all renderer methods must execute on the main thread");
 puts("PASS: bounded video delivery, overflow/keyframe recovery, session epochs and main-thread rendering");
}return 0;}
