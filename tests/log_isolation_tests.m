#import <Foundation/Foundation.h>
#import "ODLog.h"
#include <assert.h>

int main(void) { @autoreleasepool {
    dispatch_semaphore_t entered=dispatch_semaphore_create(0);
    dispatch_semaphore_t release=dispatch_semaphore_create(0);
    dispatch_semaphore_t returned=dispatch_semaphore_create(0);
    dispatch_semaphore_t drained=dispatch_semaphore_create(0);
    __block NSUInteger count=0;
    ODLogWriter *writer=[[ODLogWriter alloc] initWithSink:^(NSString *message) {
        assert([message hasPrefix:@"message"]);
        if (++count==1) {
            dispatch_semaphore_signal(entered);
            dispatch_semaphore_wait(release, DISPATCH_TIME_FOREVER);
        }
        if (count==32) dispatch_semaphore_signal(drained);
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        assert([writer submit:@"message 0"]);
        dispatch_semaphore_signal(returned);
    });
    assert(dispatch_semaphore_wait(entered,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC))==0);
    if (dispatch_semaphore_wait(returned,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC))) {
        fprintf(stderr,"FAIL: stalled log sink blocked its caller\n"); return 1;
    }
    for (NSUInteger i=1;i<32;i++) assert(([writer submit:[NSString stringWithFormat:@"message %lu",(unsigned long)i]]));
    for (NSUInteger i=0;i<10000;i++) assert(![writer submit:@"message overflow"]);
    dispatch_semaphore_signal(release);
    assert(dispatch_semaphore_wait(drained,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC))==0);
    puts("PASS: stalled logging is isolated and limited to 32 messages");
} return 0; }
