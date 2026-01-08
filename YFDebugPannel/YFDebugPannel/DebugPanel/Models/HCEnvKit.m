#import "HCEnvKit.h"

NSNotificationName const HCEnvKitConfigDidChangeNotification = @"HCEnvKitConfigDidChangeNotification";

@implementation HCEnvConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _envType = HCEnvTypeRelease;
        _clusterIndex = 1;
        _isolation = @"";
        _version = @"v1";
    }
    return self;
}

@end

@implementation HCEnvBuildResult
@end

@implementation HCEnvKit

static NSString *const kHCEnvKitDefaultsKey = @"HCEnvKit.config";
static NSString *const kHCEnvKitReleaseBaseURL = @"https://release.example.com";
static NSString *const kHCEnvKitUatTemplate = @"https://uat-%ld-%@.example.com";
static NSString *const kHCEnvKitDevTemplate = @"https://dev-%ld-%@.example.com";

+ (HCEnvConfig *)currentConfig {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kHCEnvKitDefaultsKey];
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    if (stored) {
        NSNumber *envType = stored[@"envType"];
        if (envType) {
            config.envType = envType.integerValue;
        }
        NSNumber *clusterIndex = stored[@"clusterIndex"];
        if (clusterIndex) {
            config.clusterIndex = clusterIndex.integerValue;
        }
        config.isolation = stored[@"isolation"] ?: @"";
        config.version = stored[@"version"] ?: @"v1";
    }
    return config;
}

+ (void)saveConfig:(HCEnvConfig *)config {
    NSDictionary *payload = @{
        @"envType": @(config.envType),
        @"clusterIndex": @(config.clusterIndex),
        @"isolation": config.isolation ?: @"",
        @"version": config.version ?: @"v1"
    };
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:payload forKey:kHCEnvKitDefaultsKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:HCEnvKitConfigDidChangeNotification object:nil];
}

+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config {
    HCEnvBuildResult *result = [[HCEnvBuildResult alloc] init];
    result.isolation = config.isolation ?: @"";
    if (config.envType == HCEnvTypeRelease) {
        result.displayName = @"线上";
        result.baseURL = kHCEnvKitReleaseBaseURL;
        return result;
    }

    NSString *version = config.version.length > 0 ? config.version : @"v1";
    if (config.envType == HCEnvTypeUat) {
        result.displayName = [NSString stringWithFormat:@"uat-%ld", (long)config.clusterIndex];
        result.baseURL = [NSString stringWithFormat:kHCEnvKitUatTemplate, (long)config.clusterIndex, version];
    } else {
        result.displayName = [NSString stringWithFormat:@"dev-%ld", (long)config.clusterIndex];
        result.baseURL = [NSString stringWithFormat:kHCEnvKitDevTemplate, (long)config.clusterIndex, version];
    }
    return result;
}

@end
