#import <Foundation/Foundation.h>
#import "ODReceiver.h"
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>
@interface PausedRenderer : NSObject <ODVideoSink>
@property(nonatomic,copy) void (^requestKeyframe)(void);
@property(nonatomic,strong) dispatch_semaphore_t resume;
@property(atomic) BOOL wrongThread;
@property(atomic) NSUInteger frames;
@end
@implementation PausedRenderer
- (NSUInteger)submittedFrames { return self.frames; }
- (NSUInteger)decodeErrors { return 0; }
- (NSString *)streamDescription { return @"paused renderer"; }
- (void)consumeVideo:(NSData *)data {
    if (![NSThread isMainThread]) self.wrongThread=YES;
    dispatch_semaphore_wait(self.resume,DISPATCH_TIME_FOREVER);
    self.frames++;
}
- (void)resetStream { if (![NSThread isMainThread]) self.wrongThread=YES; }
- (void)applyCursorMessage:(NSDictionary *)message { if (![NSThread isMainThread]) self.wrongThread=YES; }
@end
static BOOL exact(int fd,void *buf,size_t length) {
    size_t n=0; while(n<length) { ssize_t r=recv(fd,(char *)buf+n,length-n,0); if(r<=0)return NO; n+=r; } return YES;
}
static NSDictionary *control(int fd) {
    uint32_t n; if(!exact(fd,&n,4))return nil; n=ntohl(n); if(!n||n>65536)return nil;
    NSMutableData *data=[NSMutableData dataWithLength:n]; if(!exact(fd,data.mutableBytes,n))return nil;
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
}
int main(void) { @autoreleasepool {
    PausedRenderer *sink=[PausedRenderer new];sink.resume=dispatch_semaphore_create(0);
    ODReceiver *receiver=[[ODReceiver alloc] initWithVideoView:sink];[receiver start];
    // Deliberately leave the main/UI queue unpumped. A stalled renderer must
    // not prevent the independent transport from accepting or sending pings.
    usleep(100000);
    int fd=socket(AF_INET,SOCK_STREAM,0);struct timeval timeout={.tv_sec=3};
    setsockopt(fd,SOL_SOCKET,SO_RCVTIMEO,&timeout,sizeof timeout);
    struct sockaddr_in addr={.sin_len=sizeof addr,.sin_family=AF_INET,.sin_port=htons(9000)};addr.sin_addr.s_addr=htonl(INADDR_LOOPBACK);
    if(connect(fd,(struct sockaddr *)&addr,sizeof addr)||![control(fd)[@"type"] isEqual:@"hello"])return 2;
    // A video frame enters the actual receiver parser and paused video sink.
    const uint8_t frame[]={0,0,0,5,0,0,0,1,0x65};send(fd,frame,sizeof frame,0);
    NSDictionary *message=control(fd);
    BOOL alive=[message[@"type"] isEqual:@"ping"];
    dispatch_semaphore_signal(sink.resume);
    [receiver stop];close(fd);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    if(!alive){fprintf(stderr,"FAIL: paused rendering blocked the transport heartbeat\n");return 1;}
    if(sink.wrongThread){fprintf(stderr,"FAIL: video layer operation escaped the main thread\n");return 1;}
    puts("PASS: paused UI rendering does not block USB hello/heartbeat; sink operations stay on main");
 } return 0; }
