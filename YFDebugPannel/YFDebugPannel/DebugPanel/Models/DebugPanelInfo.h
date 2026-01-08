#import <Foundation/Foundation.h>

@interface DebugPanelInfo : NSObject
@property (nonatomic, copy, readonly) NSString *appName;
@property (nonatomic, copy, readonly) NSString *buildNumber;
@property (nonatomic, copy, readonly) NSString *displayText;

- (instancetype)initWithAppName:(NSString *)appName buildNumber:(NSString *)buildNumber;
+ (instancetype)current;
@end
