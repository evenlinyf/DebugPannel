#import "DebugPanelInfo.h"

@interface DebugPanelInfo ()
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *buildNumber;
@end

@implementation DebugPanelInfo

- (instancetype)initWithAppName:(NSString *)appName buildNumber:(NSString *)buildNumber {
    self = [super init];
    if (self) {
        _appName = [appName copy];
        _buildNumber = [buildNumber copy];
    }
    return self;
}

- (NSString *)displayText {
    return [NSString stringWithFormat:@"%@ (Build %@)", self.appName, self.buildNumber];
}

+ (instancetype)current {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?: @"YFDebugPannel";
    NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"1";
    return [[DebugPanelInfo alloc] initWithAppName:appName buildNumber:buildNumber];
}

@end
