#import "HCEnvKit.h"

NSNotificationName const HCEnvKitConfigDidChangeNotification = @"HCEnvKitConfigDidChangeNotification";

static NSString * const HCEnvKitDefaultsKey = @"HCEnvKit.config";
static NSString * const HCEnvKitReleaseBaseURL = @"https://release.example.com";
static NSString * const HCEnvKitUATTemplate = @"https://uat-%ld-%@.example.com"; // TODO: replace with real template
static NSString * const HCEnvKitDevTemplate = @"https://dev-%ld-%@.example.com"; // TODO: replace with real template

@implementation HCEnvConfig

@end

@implementation HCEnvBuildResult

@end

@implementation HCEnvKit

+ (HCEnvConfig *)currentConfig {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:HCEnvKitDefaultsKey];
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    if (stored) {
        config.envType = [stored[@"envType"] integerValue];
        config.clusterIndex = [stored[@"clusterIndex"] integerValue];
        config.isolation = stored[@"isolation"] ?: @"";
        config.version = stored[@"version"] ?: @"v1";
    } else {
        config.envType = HCEnvTypeRelease;
        config.clusterIndex = 1;
        config.isolation = @"";
        config.version = @"v1";
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
    [[NSUserDefaults standardUserDefaults] setObject:payload forKey:HCEnvKitDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:HCEnvKitConfigDidChangeNotification object:nil];
}

+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config {
    HCEnvBuildResult *result = [[HCEnvBuildResult alloc] init];
    result.isolation = config.isolation ?: @"";
    if (config.envType == HCEnvTypeRelease) {
        result.displayName = @"线上";
        result.baseURL = HCEnvKitReleaseBaseURL;
        return result;
    }
    NSString *version = config.version.length > 0 ? config.version : @"v1";
    if (config.envType == HCEnvTypeUAT) {
        result.displayName = [NSString stringWithFormat:@"uat-%ld", (long)config.clusterIndex];
        result.baseURL = [NSString stringWithFormat:HCEnvKitUATTemplate, (long)config.clusterIndex, version];
    } else {
        result.displayName = [NSString stringWithFormat:@"dev-%ld", (long)config.clusterIndex];
        result.baseURL = [NSString stringWithFormat:HCEnvKitDevTemplate, (long)config.clusterIndex, version];
    }
    return result;
}

@end
