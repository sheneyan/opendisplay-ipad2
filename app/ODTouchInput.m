#import "ODTouchInput.h"
#include <math.h>

typedef NS_ENUM(NSUInteger, ODGestureState) { ODIdle, ODPending, ODDragging, ODScrolling, ODBlocked };
@implementation ODTouchInput {
    ODGestureState _state;
    NSUInteger _count;
    double _left, _top, _width, _height, _pixelsPerPoint;
    double _startX, _startY, _lastX, _lastY;
    BOOL _inside;
}
- (void)setViewWidth:(double)width height:(double)height videoWidth:(double)videoWidth height:(double)videoHeight {
    double scale = width > 0 && height > 0 && videoWidth > 0 && videoHeight > 0
        ? MIN(width/videoWidth, height/videoHeight) : 0;
    double w = videoWidth*scale, h = videoHeight*scale;
    double left = (width-w)/2, top = (height-h)/2;
    if (w != _width || h != _height || left != _left || top != _top || (scale > 0 ? 1/scale : 0) != _pixelsPerPoint)
        [self cancel];
    _width=w; _height=h; _left=left; _top=top; _pixelsPerPoint=scale > 0 ? 1/scale : 0;
}
- (void)touch:(NSString *)phase x:(double)x y:(double)y {
    if (_width <= 0 || _height <= 0) return;
    if (self.onMessage) self.onMessage(@{@"type":@"touch", @"phase":phase,
        @"x":@(MAX(0,MIN(1,(x-_left)/_width))), @"y":@(MAX(0,MIN(1,(y-_top)/_height)))});
}
- (void)cancel {
    if (_state == ODDragging) [self touch:@"cancelled" x:_lastX y:_lastY];
    _state = _count ? ODBlocked : ODIdle;
}
- (void)hold {
    if (!self.settingsEnabled || _state != ODPending || _count != 1) return;
    _state = ODBlocked;
    if (self.onSettings) self.onSettings();
}
- (void)updateCount:(NSUInteger)count x:(double)x y:(double)y {
    if (!isfinite(x) || !isfinite(y)) { [self cancel]; return; }
    NSUInteger previousCount = _count;
    _count=count;
    if (!count) {
        if (_state == ODPending && _inside) {
            [self touch:@"began" x:_startX y:_startY];
            [self touch:@"ended" x:x y:y];
        } else if (_state == ODDragging) [self touch:@"ended" x:x y:y];
        _state=ODIdle;
        return;
    }
    if (_state == ODBlocked) return;
    if (count > 2) { [self cancel]; return; }
    if (previousCount == 2 && count == 1) { _state=ODBlocked; return; }
    if (_state == ODIdle) {
        _startX=_lastX=x; _startY=_lastY=y;
        _inside = _width > 0 && _height > 0 && x >= _left && x <= _left+_width && y >= _top && y <= _top+_height;
        _state=ODPending;
    }
    if (count == 2) {
        if (_state != ODScrolling) {
            if (_state == ODDragging) [self touch:@"cancelled" x:_lastX y:_lastY];
            if (!_inside) { _state=ODBlocked; return; }
            _state=ODScrolling;
            [self touch:@"moved" x:x y:y]; // Position the wheel target without pressing.
        } else {
            double dx=(x-_lastX)*_pixelsPerPoint, dy=(y-_lastY)*_pixelsPerPoint;
            if ((dx || dy) && self.onMessage) self.onMessage(@{@"type":@"scroll", @"dx":@(dx), @"dy":@(dy)});
        }
    } else if (_state == ODPending && hypot(x-_startX,y-_startY) >= 8) {
        if (!_inside) { _state=ODBlocked; return; }
        _state=ODDragging;
        [self touch:@"began" x:_startX y:_startY];
        [self touch:@"moved" x:x y:y];
    } else if (_state == ODDragging) {
        [self touch:@"moved" x:x y:y];
    }
    _lastX=x; _lastY=y;
}
@end
