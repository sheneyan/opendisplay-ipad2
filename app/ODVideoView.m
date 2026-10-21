#import "ODVideoView.h"
#import "ODProtocol.h"
#import <CoreMedia/CoreMedia.h>
#include <arpa/inet.h>

static void collectNALU(void *context, const uint8_t *bytes, size_t size) {
    [(__bridge NSMutableArray *)context addObject:[NSData dataWithBytes:bytes length:size]];
}
@implementation ODVideoView {
    AVSampleBufferDisplayLayer *_videoLayer;
    UIImageView *_cursorView;
    NSData *_sps, *_pps;
    CMVideoFormatDescriptionRef _format;
    BOOL _waitingForIDR;
    NSTimeInterval _lastKeyframeRequest;
    NSUInteger _submittedFrames, _decodeErrors;
    NSString *_streamDescription;
    CGSize _videoSize;
    CGPoint _cursorPosition, _cursorAnchor;
    CGSize _cursorNormalizedSize;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor blackColor];
        _videoLayer = [AVSampleBufferDisplayLayer layer];
        _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:_videoLayer];
        _cursorView = [[UIImageView alloc] init];
        _cursorView.hidden = YES;
        [self addSubview:_cursorView];
        _waitingForIDR = YES;
        _streamDescription = @"Waiting for H.264";
    }
    return self;
}
- (void)dealloc { if (_format) CFRelease(_format); }
- (void)layoutSubviews { [super layoutSubviews]; _videoLayer.frame = self.bounds; [self positionCursor]; }
- (NSUInteger)submittedFrames { return _submittedFrames; }
- (NSUInteger)decodeErrors { return _decodeErrors; }
- (NSString *)streamDescription { return _streamDescription; }
- (void)resetStream {
    if (_format) { CFRelease(_format); _format = NULL; }
    _sps = nil; _pps = nil; _waitingForIDR = YES;
    _submittedFrames = _decodeErrors = 0; _lastKeyframeRequest = 0;
    [_videoLayer flushAndRemoveImage];
    _streamDescription = @"Waiting for H.264";
    dispatch_async(dispatch_get_main_queue(), ^{ self->_cursorView.hidden = YES; });
}
- (void)askForKeyframe {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - _lastKeyframeRequest >= 1.0) {
        _lastKeyframeRequest = now;
        if (self.requestKeyframe) self.requestKeyframe();
    }
}
- (void)consumeVideo:(NSData *)payload {
    NSMutableArray *nalus = [NSMutableArray array];
    ODVisitNALUs(payload.bytes, payload.length, collectNALU, (__bridge void *)nalus);
    BOOL idr = NO, changed = NO;
    NSMutableData *avcc = [NSMutableData data];
    for (NSData *nalu in nalus) {
        unsigned type = ((const uint8_t *)nalu.bytes)[0] & 31;
        if (type == 7) { if (![_sps isEqualToData:nalu]) { _sps = nalu; changed = YES; } }
        else if (type == 8) { if (![_pps isEqualToData:nalu]) { _pps = nalu; changed = YES; } }
        else if (type == 1 || type == 5) {
            idr |= type == 5;
            uint32_t length = htonl((uint32_t)nalu.length);
            [avcc appendBytes:&length length:4];
            [avcc appendData:nalu];
        }
    }
    if (changed && _format) { CFRelease(_format); _format = NULL; _waitingForIDR = YES; }
    if (!_format && _sps && _pps) {
        const uint8_t *parameters[] = {_sps.bytes, _pps.bytes};
        size_t sizes[] = {_sps.length, _pps.length};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                            2, parameters, sizes, 4, &_format);
        [_videoLayer flushAndRemoveImage];
        if (status) {
            _decodeErrors++; _streamDescription = [NSString stringWithFormat:@"H.264 format error %d", (int)status];
            NSLog(@"LegacyDisplay %@", _streamDescription);
        } else {
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(_format);
            const uint8_t *sps = _sps.bytes;
            _streamDescription = [NSString stringWithFormat:@"H.264 %dx%d profile %u level %.1f",
                (int)dimensions.width, (int)dimensions.height, _sps.length > 1 ? sps[1] : 0,
                _sps.length > 3 ? sps[3]/10.0 : 0];
            NSLog(@"LegacyDisplay %@", _streamDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_videoSize = CGSizeMake(dimensions.width, dimensions.height);
                [self positionCursor];
            });
        }
    }
    if (!avcc.length) return;
    if (_videoLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        _decodeErrors++; _waitingForIDR = YES;
        NSLog(@"LegacyDisplay decode error: %@", _videoLayer.error);
        _streamDescription = [NSString stringWithFormat:@"Decoder failed: %@", _videoLayer.error.localizedDescription];
        [_videoLayer flush];
    }
    if (!_format || (_waitingForIDR && !idr)) { [self askForKeyframe]; return; }
    if (!_videoLayer.readyForMoreMediaData) {
        /* Never continue from an arbitrary dropped P-frame. Resume at an IDR. */
        _waitingForIDR = YES; [self askForKeyframe]; return;
    }
    _waitingForIDR = NO;
    CMBlockBufferRef block = NULL;
    CMSampleBufferRef sample = NULL;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, NULL, avcc.length,
        kCFAllocatorDefault, NULL, 0, avcc.length, 0, &block);
    if (!status) status = CMBlockBufferReplaceDataBytes(avcc.bytes, block, 0, avcc.length);
    size_t sampleSize = avcc.length;
    if (!status) status = CMSampleBufferCreateReady(kCFAllocatorDefault, block, _format, 1,
        0, NULL, 1, &sampleSize, &sample);
    if (!status && sample) {
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sample, true);
        if (attachments && CFArrayGetCount(attachments)) {
            CFMutableDictionaryRef values = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
            CFDictionarySetValue(values, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        }
        [_videoLayer enqueueSampleBuffer:sample];
        _submittedFrames++;
    } else { _decodeErrors++; _waitingForIDR = YES; [self askForKeyframe]; }
    if (sample) CFRelease(sample);
    if (block) CFRelease(block);
}
- (void)applyCursorMessage:(NSDictionary *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([message[@"type"] isEqual:@"cursorImg"]) {
            if (![message[@"png"] isKindOfClass:[NSString class]]) return;
            NSData *data = [[NSData alloc] initWithBase64EncodedString:message[@"png"] options:0];
            self->_cursorView.image = [UIImage imageWithData:data];
            self->_cursorNormalizedSize = CGSizeMake([message[@"nw"] doubleValue], [message[@"nh"] doubleValue]);
            self->_cursorAnchor = CGPointMake([message[@"ax"] doubleValue], [message[@"ay"] doubleValue]);
        } else {
            self->_cursorView.hidden = ![message[@"v"] boolValue];
            if (message[@"x"] && message[@"y"])
                self->_cursorPosition = CGPointMake([message[@"x"] doubleValue], [message[@"y"] doubleValue]);
        }
        [self positionCursor];
    });
}
- (void)positionCursor {
    if (_videoSize.width <= 0 || _videoSize.height <= 0) return;
    CGFloat factor = MIN(self.bounds.size.width/_videoSize.width, self.bounds.size.height/_videoSize.height);
    CGSize video = CGSizeMake(_videoSize.width*factor, _videoSize.height*factor);
    CGSize cursor = CGSizeMake(video.width*_cursorNormalizedSize.width, video.height*_cursorNormalizedSize.height);
    _cursorView.frame = CGRectMake((self.bounds.size.width-video.width)/2 + _cursorPosition.x*video.width-_cursorAnchor.x*cursor.width,
        (self.bounds.size.height-video.height)/2 + _cursorPosition.y*video.height-_cursorAnchor.y*cursor.height,
        cursor.width, cursor.height);
}
@end
