#import "ODVideoDelivery.h"
@interface ODVideoDelivery ()
@property(atomic) NSUInteger snapshotFrames;
@property(atomic) NSUInteger snapshotErrors;
@property(atomic, copy) NSString *snapshotDescription;
@end
@implementation ODVideoDelivery {
    id<ODVideoSink> _renderer;
    NSLock *_lock;
    NSUInteger _epoch, _queuedFrames, _queuedBytes;
    BOOL _needsReset, _cursorScheduled;
    NSDictionary *_cursorImage, *_cursorPosition;
}
- (instancetype)initWithRenderer:(id<ODVideoSink>)renderer {
    if ((self=[super init])) {
        _renderer=renderer;
        _lock=[NSLock new];
        _snapshotDescription=@"Waiting for H.264";
        __weak ODVideoDelivery *weakSelf=self;
        renderer.requestKeyframe=^{
            ODVideoDelivery *delivery=weakSelf;
            if (delivery.requestKeyframe) delivery.requestKeyframe();
        };
    }
    return self;
}
- (NSUInteger)submittedFrames { return self.snapshotFrames; }
- (NSUInteger)decodeErrors { return self.snapshotErrors; }
- (NSString *)streamDescription { return self.snapshotDescription; }
- (void)updateSnapshot {
    self.snapshotFrames=_renderer.submittedFrames;
    self.snapshotErrors=_renderer.decodeErrors;
    self.snapshotDescription=_renderer.streamDescription;
}
- (void)resetStream {
    [_lock lock];
    NSUInteger epoch=++_epoch;
    _needsReset=YES;
    _cursorImage=nil; _cursorPosition=nil;
    [_lock unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_lock lock];
        BOOL reset=epoch==self->_epoch && self->_needsReset;
        if (reset) self->_needsReset=NO;
        [self->_lock unlock];
        if (reset) { [self->_renderer resetStream]; [self updateSnapshot]; }
    });
}
- (void)consumeVideo:(NSData *)payload {
    [_lock lock];
    if (_queuedFrames>=3 || payload.length>8*1024*1024-_queuedBytes) {
        // Never retain a P-frame sequence after dropping one of its references.
        // Pending work remains counted until drained, so repeated overflow
        // cannot create an unbounded queue of resets or retained video data.
        _epoch++;
        _needsReset=YES;
        [_lock unlock];
        return;
    }
    NSUInteger epoch=_epoch;
    _queuedFrames++; _queuedBytes+=payload.length;
    [_lock unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_lock lock];
        self->_queuedFrames--; self->_queuedBytes-=payload.length;
        BOOL current=epoch==self->_epoch;
        BOOL reset=self->_needsReset;
        self->_needsReset=NO;
        [self->_lock unlock];
        if (reset) {
            [self->_renderer resetStream];
            if (self.requestKeyframe) self.requestKeyframe();
        }
        if (current) [self->_renderer consumeVideo:payload];
        [self updateSnapshot];
    });
}
- (void)applyCursorMessage:(NSDictionary *)message {
    [_lock lock];
    if ([message[@"type"] isEqual:@"cursorImg"]) _cursorImage=message;
    else _cursorPosition=message;
    if (_cursorScheduled) { [_lock unlock]; return; }
    _cursorScheduled=YES;
    [_lock unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_lock lock];
        NSDictionary *image=self->_cursorImage, *position=self->_cursorPosition;
        self->_cursorImage=nil; self->_cursorPosition=nil; self->_cursorScheduled=NO;
        [self->_lock unlock];
        if (image) [self->_renderer applyCursorMessage:image];
        if (position) [self->_renderer applyCursorMessage:position];
    });
}
@end
