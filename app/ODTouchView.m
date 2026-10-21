#import "ODTouchView.h"
#import "ODTouchInput.h"
@implementation ODTouchView {
    ODTouchInput *_input;
    NSMutableSet *_contacts;
    NSTimer *_holdTimer;
    NSUInteger _gestureSession;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        self.multipleTouchEnabled=YES;
        self.backgroundColor=[UIColor clearColor];
        _contacts=[NSMutableSet set];
        _input=[ODTouchInput new];
#if OD_RETINA_SETTINGS
        _input.settingsEnabled=YES;
#endif
        __weak ODTouchView *weakSelf=self;
        _input.onMessage=^(NSDictionary *message) {
            ODTouchView *view=weakSelf;
            if (view.onMessage) view.onMessage(message,view->_gestureSession);
        };
        _input.onSettings=^{ if (weakSelf.onSettings) weakSelf.onSettings(); };
    }
    return self;
}
- (void)dealloc { [_holdTimer invalidate]; }
- (void)layoutSubviews { [super layoutSubviews]; [self refreshGeometry]; }
- (void)refreshGeometry {
    CGSize size=self.videoSize ? self.videoSize() : CGSizeZero;
    [_input setViewWidth:self.bounds.size.width height:self.bounds.size.height videoWidth:size.width height:size.height];
}
- (void)cancelInput {
    [_holdTimer invalidate]; _holdTimer=nil;
    [_input cancel];
}
- (void)held:(NSTimer *)timer { _holdTimer=nil; [_input hold]; }
- (void)updateTouches:(NSSet *)changed beginning:(BOOL)beginning ending:(BOOL)ending {
    NSUInteger before=_contacts.count;
    if (beginning) [_contacts unionSet:changed];
    if (ending) [_contacts minusSet:changed];
    if (!before && _contacts.count) _gestureSession=self.session ? self.session() : 0;
    [self refreshGeometry];
    CGPoint point=CGPointZero;
    NSSet *locations=_contacts.count ? _contacts : changed;
    for (UITouch *touch in locations) {
        CGPoint location=[touch locationInView:self]; point.x+=location.x; point.y+=location.y;
    }
    if (locations.count) { point.x/=locations.count; point.y/=locations.count; }
    [_input updateCount:_contacts.count x:point.x y:point.y];
    if (_contacts.count != 1) { [_holdTimer invalidate]; _holdTimer=nil; }
#if OD_RETINA_SETTINGS
    if (!before && _contacts.count == 1) {
        _holdTimer=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(held:) userInfo:nil repeats:NO];
    }
#endif
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event { [self updateTouches:touches beginning:YES ending:NO]; }
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event { [self updateTouches:touches beginning:NO ending:NO]; }
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event { [self updateTouches:touches beginning:NO ending:YES]; }
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self cancelInput]; [self updateTouches:touches beginning:NO ending:YES];
}
@end
