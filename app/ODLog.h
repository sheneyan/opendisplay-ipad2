#import <Foundation/Foundation.h>

// Logging must never hold up input, rendering or the USB receiver.
@interface ODLogWriter : NSObject
- (instancetype)initWithSink:(void (^)(NSString *message))sink;
- (BOOL)submit:(NSString *)message;
@end

FOUNDATION_EXPORT void ODLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
