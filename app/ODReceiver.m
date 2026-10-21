#import "ODReceiver.h"
#import "ODProtocol.h"
#import "ODDisplaySettings.h"
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>

@interface ODReceiver ()
- (void)receivedBytes:(const uint8_t *)bytes size:(size_t)size;
@end
static void receivedFrame(void *context, const uint8_t *bytes, size_t size) {
    [(__bridge ODReceiver *)context receivedBytes:bytes size:size];
}
@implementation ODReceiver {
    id<ODVideoSink> _video;
    dispatch_queue_t _queue;
    dispatch_source_t _listenerSource, _readSource, _writeSource, _timer;
    int _listener, _client;
    NSUInteger _generation, _ticks;
    ODFrameReader _reader;
    NSMutableData *_outgoing;
    NSString *_installID, *_connectionText;
    NSTimeInterval _lastReceive;
    BOOL _wantsRunning;
}
- (instancetype)initWithVideoView:(id<ODVideoSink>)view {
    if ((self = [super init])) {
        _video = view; _listener = _client = -1;
        _queue = dispatch_queue_create("com.sheneyan.oldipad.receiver", DISPATCH_QUEUE_SERIAL);
        ODFrameReaderInit(&_reader, 8 * 1024 * 1024);
        _outgoing = [NSMutableData data];
        _installID = [[NSUserDefaults standardUserDefaults] stringForKey:@"receiverID"];
        if (!_installID) {
            _installID = [NSUUID UUID].UUIDString;
            [[NSUserDefaults standardUserDefaults] setObject:_installID forKey:@"receiverID"];
        }
        __weak ODReceiver *weakSelf = self;
        view.requestKeyframe = ^{ [weakSelf sendControl:@{@"type":@"kf"}]; };
    }
    return self;
}
- (void)dealloc { ODFrameReaderDestroy(&_reader); }
- (void)publish:(NSString *)text {
    void (^callback)(NSString *) = self.onStatus;
    if (callback) dispatch_async(dispatch_get_main_queue(), ^{ callback(text); });
}
- (void)start {
    dispatch_async(_queue, ^{
        self->_wantsRunning = YES;
        [self openListenerIfNeeded];
    });
}
- (void)openListenerIfNeeded {
    if (!_wantsRunning || _listenerSource) return;
    int fd = socket(AF_INET, SOCK_STREAM, 0), yes = 1;
    if (fd < 0) { [self publish:@"Cannot create TCP listener"]; return; }
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes);
    fcntl(fd, F_SETFL, O_NONBLOCK);
    /* Bind loopback only: usbmuxd reaches it without exposing the screen on Wi-Fi. */
    struct sockaddr_in address = {0};
    address.sin_len = sizeof address; address.sin_family = AF_INET;
    address.sin_port = htons(9000); address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(fd, (struct sockaddr *)&address, sizeof address) || listen(fd, 4)) {
        NSString *message = [NSString stringWithFormat:@"Listener error: %s", strerror(errno)];
        close(fd); [self publish:message]; return;
    }
    self->_listener = fd;
    self->_listenerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, self->_queue);
    __weak ODReceiver *weakSelf = self;
    dispatch_source_set_event_handler(self->_listenerSource, ^{ [weakSelf acceptClients]; });
    dispatch_source_set_cancel_handler(self->_listenerSource, ^{
        close(fd);
        ODReceiver *receiver = weakSelf;
        if (receiver) {
            receiver->_listenerSource = nil;
            /* A foreground start may have arrived while shutdown was pending. */
            [receiver openListenerIfNeeded];
        }
    });
    dispatch_resume(self->_listenerSource);
    self->_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self->_queue);
    dispatch_source_set_timer(self->_timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), NSEC_PER_SEC, NSEC_PER_SEC/10);
    dispatch_source_set_event_handler(self->_timer, ^{ [weakSelf tick]; });
    dispatch_resume(self->_timer);
    self->_connectionText = @"Listening over USB :9000";
    [self publish:self->_connectionText];
    NSLog(@"LegacyDisplay receiver listening on loopback :9000");
}
- (void)stop {
    dispatch_async(_queue, ^{
        self->_wantsRunning = NO;
        [self sendControl:@{@"type":@"sleeping"}];
        [self disconnect];
        if (self->_listenerSource) dispatch_source_cancel(self->_listenerSource);
        if (self->_timer) { dispatch_source_cancel(self->_timer); self->_timer = nil; }
        self->_listener = -1;
    });
}
- (void)disconnect {
    _generation++;
    if (_writeSource) { dispatch_source_cancel(_writeSource); _writeSource = nil; }
    if (_readSource) { dispatch_source_cancel(_readSource); _readSource = nil; }
    _client = -1;
    [_outgoing setLength:0];
    ODFrameReaderReset(&_reader);
    [_video resetStream];
    _connectionText = @"Listening over USB :9000";
    [self publish:_connectionText];
}
- (void)acceptClients {
    int fd;
    while ((fd = accept(_listener, NULL, NULL)) >= 0) {
        [self disconnect];
        _client = fd;
        fcntl(fd, F_SETFL, O_NONBLOCK);
        int yes = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &yes, sizeof yes);
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &yes, sizeof yes);
        NSUInteger generation = _generation;
        _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, _queue);
        __weak ODReceiver *weakSelf = self;
        dispatch_source_set_event_handler(_readSource, ^{
            ODReceiver *receiver = weakSelf;
            if (receiver && receiver->_generation == generation) [receiver readAvailable];
        });
        dispatch_source_set_cancel_handler(_readSource, ^{ close(fd); });
        dispatch_resume(_readSource);
        _lastReceive = [NSDate timeIntervalSinceReferenceDate];
        _ticks = 0;
        _connectionText = @"USB connected";
#if OD_RETINA_SETTINGS
        BOOL expanded = YES;
#else
        BOOL expanded = NO;
#endif
        NSMutableDictionary *hello = [ODDisplayFields(expanded, [NSUserDefaults standardUserDefaults]) mutableCopy];
        [hello addEntriesFromDictionary:@{@"type":@"hello", @"pv":@3, @"id":_installID, @"device":@"iPad"}];
        [self sendControl:hello];
        NSLog(@"LegacyDisplay USB accepted; hello pv3 sent");
    }
}
- (void)sendControl:(NSDictionary *)message {
    if (_client < 0) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:NULL];
    if (!data || _outgoing.length + data.length + 4 > 65536) return;
    uint32_t size = htonl((uint32_t)data.length);
    [_outgoing appendBytes:&size length:4]; [_outgoing appendData:data];
    [self flushOutput];
}
- (void)flushOutput {
    while (_outgoing.length && _client >= 0) {
        ssize_t n = send(_client, _outgoing.bytes, _outgoing.length, 0);
        if (n < 0 && errno == EINTR) continue;
        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            if (!_writeSource) {
                _writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, _client, 0, _queue);
                __weak ODReceiver *weakSelf = self;
                NSUInteger generation = _generation;
                dispatch_source_set_event_handler(_writeSource, ^{
                    ODReceiver *receiver = weakSelf;
                    if (receiver && receiver->_generation == generation) [receiver flushOutput];
                });
                dispatch_resume(_writeSource);
            }
            return;
        }
        if (n <= 0) { [self disconnect]; return; }
        [_outgoing replaceBytesInRange:NSMakeRange(0, (NSUInteger)n) withBytes:NULL length:0];
    }
    if (_writeSource) { dispatch_source_cancel(_writeSource); _writeSource = nil; }
}
- (void)readAvailable {
    uint8_t bytes[65536];
    for (int i = 0; i < 32 && _client >= 0; i++) {
        ssize_t n = recv(_client, bytes, sizeof bytes, 0);
        if (n < 0 && errno == EINTR) continue;
        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return;
        if (n <= 0) { [self disconnect]; return; }
        _lastReceive = [NSDate timeIntervalSinceReferenceDate];
        @autoreleasepool {
            if (ODFrameReaderFeed(&_reader, bytes, (size_t)n, receivedFrame, (__bridge void *)self)) {
                NSLog(@"LegacyDisplay invalid frame length"); [self disconnect]; return;
            }
        }
    }
}
- (void)receivedBytes:(const uint8_t *)bytes size:(size_t)size {
    NSData *data = [NSData dataWithBytes:bytes length:size];
    if (!ODIsControl(bytes, size)) { [_video consumeVideo:data]; return; }
    id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    if (![value isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *message = value;
    if ([message[@"type"] isEqual:@"cursor"] || [message[@"type"] isEqual:@"cursorImg"])
        [_video applyCursorMessage:message];
    else if ([message[@"type"] isEqual:@"welcome"])
        NSLog(@"LegacyDisplay sender welcome pv=%@ min=%@", message[@"pv"], message[@"min"]);
    else if ([message[@"type"] isEqual:@"updateRequired"])
        _connectionText = @"Sender requires a newer receiver protocol";
    else if ([message[@"type"] isEqual:@"streamConfig"] && ![message[@"codec"] isEqual:@"h264"])
        _connectionText = @"Unsupported codec: H.264 required";
}
- (void)tick {
    if (_client < 0) return;
    if ([NSDate timeIntervalSinceReferenceDate] - _lastReceive > 15) { [self disconnect]; return; }
    if ((_ticks++ % 2) == 0)
        [self sendControl:@{@"type":@"ping", @"t":@([NSDate date].timeIntervalSince1970 * 1000)}];
    [self publish:[NSString stringWithFormat:@"%@ | %@ | submitted %lu | errors %lu",
        _connectionText, _video.streamDescription, (unsigned long)_video.submittedFrames, (unsigned long)_video.decodeErrors]];
}
@end
