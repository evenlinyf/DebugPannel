/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境配置模型与工具类实现。
#import "HCEnvKit.h"

NSNotificationName const HCEnvKitConfigDidChangeNotification = @"HCEnvKitConfigDidChangeNotification";

@implementation HCEnvConfig

static NSString *HCNormalizedString(NSString *value) {
    if (![value isKindOfClass:[NSString class]]) {
        return @"";
    }
    return value ?: @"";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _envType = HCEnvTypeRelease;
        _clusterIndex = 1;
        _isolation = @"";
        _version = @"v1";
        _customBaseURL = @"";
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    HCEnvConfig *copy = [[[self class] allocWithZone:zone] init];
    copy.envType = self.envType;
    copy.clusterIndex = self.clusterIndex;
    copy.isolation = HCNormalizedString(self.isolation);
    copy.version = HCNormalizedString(self.version);
    copy.customBaseURL = HCNormalizedString(self.customBaseURL);
    return copy;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[HCEnvConfig class]]) {
        return NO;
    }
    HCEnvConfig *other = (HCEnvConfig *)object;
    BOOL envTypeEqual = (self.envType == other.envType);
    BOOL clusterEqual = (self.clusterIndex == other.clusterIndex);
    BOOL isolationEqual = [HCNormalizedString(self.isolation) isEqualToString:HCNormalizedString(other.isolation)];
    BOOL versionEqual = [HCNormalizedString(self.version) isEqualToString:HCNormalizedString(other.version)];
    BOOL baseURLEqual = [HCNormalizedString(self.customBaseURL) isEqualToString:HCNormalizedString(other.customBaseURL)];
    return envTypeEqual && clusterEqual && isolationEqual && versionEqual && baseURLEqual;
}

- (NSUInteger)hash {
    NSUInteger hashValue = 0;
    hashValue ^= (NSUInteger)self.envType;
    hashValue ^= (NSUInteger)self.clusterIndex;
    hashValue ^= HCNormalizedString(self.isolation).hash;
    hashValue ^= HCNormalizedString(self.version).hash;
    hashValue ^= HCNormalizedString(self.customBaseURL).hash;
    return hashValue;
}

@end

@implementation HCEnvBuildResult
@end

@implementation HCEnvKit

static NSString *const kHCEnvKitDefaultsKey = @"HCEnvKit.config";
static NSString *const kHCEnvKitReleaseBaseURL = @"https://release.example.com";
static NSString *const kHCEnvKitUatTemplate = @"https://uat-%ld-%@.example.com";
static NSString *const kHCEnvKitUatTemplateNoVersion = @"https://uat-%ld.example.com";
static NSString *const kHCEnvKitDevTemplate = @"https://dev-%ld-%@.example.com";
static NSString *const kHCEnvKitDevTemplateNoVersion = @"https://dev-%ld.example.com";

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
        config.customBaseURL = stored[@"customBaseURL"] ?: @"";
    }
    return config;
}

+ (void)saveConfig:(HCEnvConfig *)config {
    NSDictionary *payload = @{
        @"envType": @(config.envType),
        @"clusterIndex": @(config.clusterIndex),
        @"isolation": config.isolation ?: @"",
        @"version": config.version ?: @"v1",
        @"customBaseURL": config.customBaseURL ?: @""
    };
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:payload forKey:kHCEnvKitDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:HCEnvKitConfigDidChangeNotification object:nil];
}

+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config {
    HCEnvBuildResult *result = [[HCEnvBuildResult alloc] init];
    result.isolation = config.isolation ?: @"";
    if (config.customBaseURL.length > 0) {
        result.displayName = @"自定义";
        result.baseURL = config.customBaseURL;
        return result;
    }

    if (config.envType == HCEnvTypeRelease) {
        result.displayName = @"线上";
        result.baseURL = kHCEnvKitReleaseBaseURL;
        return result;
    }

    NSString *version = config.version ?: @"";
    BOOL hasVersion = version.length > 0;
    if (config.envType == HCEnvTypeUat) {
        result.displayName = [NSString stringWithFormat:@"uat-%ld", (long)config.clusterIndex];
        if (hasVersion) {
            result.baseURL = [NSString stringWithFormat:kHCEnvKitUatTemplate, (long)config.clusterIndex, version];
        } else {
            result.baseURL = [NSString stringWithFormat:kHCEnvKitUatTemplateNoVersion, (long)config.clusterIndex];
        }
    } else {
        result.displayName = [NSString stringWithFormat:@"dev-%ld", (long)config.clusterIndex];
        if (hasVersion) {
            result.baseURL = [NSString stringWithFormat:kHCEnvKitDevTemplate, (long)config.clusterIndex, version];
        } else {
            result.baseURL = [NSString stringWithFormat:kHCEnvKitDevTemplateNoVersion, (long)config.clusterIndex];
        }
    }
    return result;
}

@end
