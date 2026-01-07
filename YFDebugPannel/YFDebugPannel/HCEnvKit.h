#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HCEnvType) {
    HCEnvTypeRelease,
    HCEnvTypeUAT,
    HCEnvTypeDev
};

FOUNDATION_EXPORT NSNotificationName const HCEnvKitConfigDidChangeNotification;

@interface HCEnvConfig : NSObject

@property (nonatomic, assign) HCEnvType envType;
@property (nonatomic, assign) NSInteger clusterIndex;
@property (nonatomic, copy) NSString *isolation;
@property (nonatomic, copy) NSString *version;

@end

@interface HCEnvBuildResult : NSObject

@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *isolation;

@end

@interface HCEnvKit : NSObject

+ (HCEnvConfig *)currentConfig;
+ (void)saveConfig:(HCEnvConfig *)config;
+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config;

@end

NS_ASSUME_NONNULL_END
