#import "ODLog.h"
#include <stdarg.h>

@implementation ODLogWriter {
    void (^_sink)(NSString *);
    dispatch_queue_t _queue;
    NSLock *_lock;
    NSUInteger _pending;
}
- (instancetype)initWithSink:(void (^)(NSString *))sink {
    if ((self=[super init])) {
        _sink=[sink copy];
        _queue=dispatch_queue_create("com.sheneyan.oldipad.logging", DISPATCH_QUEUE_SERIAL);
        _lock=[NSLock new];
    }
    return self;
}
- (BOOL)submit:(NSString *)message {
    [_lock lock];
    if (_pending>=32) { [_lock unlock]; return NO; }
    _pending++;
    [_lock unlock];
    NSString *bounded=[message.length>2048 ? [message substringToIndex:2048] : message copy];
    dispatch_async(_queue, ^{
        @autoreleasepool { self->_sink(bounded); }
        [self->_lock lock];
        self->_pending--;
        [self->_lock unlock];
    });
    return YES;
}
@end

void ODLog(NSString *format, ...) {
    static ODLogWriter *writer;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ writer=[[ODLogWriter alloc] initWithSink:^(NSString *message) { NSLog(@"%@",message); }]; });
    va_list args;
    va_start(args,format);
    NSString *message=[[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [writer submit:message];
}
