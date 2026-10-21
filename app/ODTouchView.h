#import <UIKit/UIKit.h>
@interface ODTouchView : UIView
@property(nonatomic, copy) CGSize (^videoSize)(void);
@property(nonatomic, copy) NSUInteger (^session)(void);
@property(nonatomic, copy) void (^onMessage)(NSDictionary *, NSUInteger);
@property(nonatomic, copy) void (^onSettings)(void);
- (void)refreshGeometry;
- (void)cancelInput;
@end
