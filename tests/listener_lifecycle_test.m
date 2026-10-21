#import <Foundation/Foundation.h>
#import "ODReceiver.h"
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

/* The real transport runs on the host; only the iOS hardware renderer is substituted. */
@interface TestSink : NSObject <ODVideoSink>
@property(nonatomic, copy) void (^requestKeyframe)(void);
@end
@implementation TestSink
- (NSUInteger)submittedFrames { return 0; }
- (NSUInteger)decodeErrors { return 0; }
- (NSString *)streamDescription { return @"test"; }
- (void)consumeVideo:(NSData *)data {}
- (void)resetStream {}
- (void)applyCursorMessage:(NSDictionary *)message {}
@end
static void pump(double duration) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:duration]];
}
static BOOL readExactly(int fd, void *buffer, size_t size) {
    size_t offset = 0;
    while (offset < size) {
        ssize_t n = recv(fd, (char *)buffer+offset, size-offset, 0);
        if (n <= 0) return NO;
        offset += (size_t)n;
    }
    return YES;
}
int main(void) {
    @autoreleasepool {
        TestSink *sink = [TestSink new];
        ODReceiver *receiver = [[ODReceiver alloc] initWithVideoView:sink];
        __block BOOL failed = NO;
        __block int listening = 0;
        receiver.onStatus = ^(NSString *status) {
            if ([status hasPrefix:@"Listener error"] || [status hasPrefix:@"Cannot create"]) {
                fprintf(stderr, "FAIL: %s\n", status.UTF8String); failed = YES;
            }
            if ([status isEqual:@"Listening over USB :9000"]) listening++;
        };
        [receiver start];
        for (int i=0; !listening && !failed && i<100; i++) pump(0.01);
        if (failed || !listening) return 1;
        for (int cycle=0; cycle<10; cycle++) {
            int before = listening;
            /* Queue the restart before cancellation completes: the reported race. */
            [receiver stop]; [receiver start];
            for (int i=0; listening < before+2 && !failed && i<100; i++) pump(0.01);
            if (failed || listening < before+2) return 1;
            int fd = socket(AF_INET, SOCK_STREAM, 0);
            struct timeval timeout = {.tv_sec=1};
            setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout);
            struct sockaddr_in address = {.sin_len=sizeof address, .sin_family=AF_INET, .sin_port=htons(9000)};
            address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
            if (connect(fd, (struct sockaddr *)&address, sizeof address)) { perror("connect"); close(fd); return 1; }
            uint32_t length;
            if (!readExactly(fd, &length, 4)) { close(fd); return 1; }
            length = ntohl(length);
            if (!length || length > 65536) { close(fd); return 1; }
            NSMutableData *data = [NSMutableData dataWithLength:length];
            if (!readExactly(fd, data.mutableBytes, length)) { close(fd); return 1; }
            NSDictionary *hello = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if (![hello[@"type"] isEqual:@"hello"] || ![hello[@"pv"] isEqual:@3]) { close(fd); return 1; }
            close(fd); pump(0.01);
        }
        [receiver stop]; pump(0.05);
        puts("PASS: 10 immediate stop/start cycles, real loopback socket and pv3 hello on every reconnect");
    }
}
