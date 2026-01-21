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

static NSString *HCEnvTypeDescription(HCEnvType envType) {
    switch (envType) {
        case HCEnvTypeRelease:
            return @"release";
        case HCEnvTypeUat:
            return @"uat";
        case HCEnvTypeDev:
            return @"dev";
        case HCEnvTypeCustom:
            return @"custom";
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _envType = HCEnvTypeRelease;
        _clusterIndex = 1;
        _isolation = @"";
        _saas = @"";
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
    copy.saas = HCNormalizedString(self.saas);
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
    BOOL saasEqual = [HCNormalizedString(self.saas) isEqualToString:HCNormalizedString(other.saas)];
    BOOL versionEqual = [HCNormalizedString(self.version) isEqualToString:HCNormalizedString(other.version)];
    BOOL baseURLEqual = [HCNormalizedString(self.customBaseURL) isEqualToString:HCNormalizedString(other.customBaseURL)];
    return envTypeEqual && clusterEqual && isolationEqual && saasEqual && versionEqual && baseURLEqual;
}

- (NSUInteger)hash {
    NSUInteger hashValue = 0;
    hashValue ^= (NSUInteger)self.envType;
    hashValue ^= (NSUInteger)self.clusterIndex;
    hashValue ^= HCNormalizedString(self.isolation).hash;
    hashValue ^= HCNormalizedString(self.saas).hash;
    hashValue ^= HCNormalizedString(self.version).hash;
    hashValue ^= HCNormalizedString(self.customBaseURL).hash;
    return hashValue;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; envType=%@; clusterIndex=%ld; isolation=%@; saas=%@; version=%@; customBaseURL=%@>",
            NSStringFromClass([self class]),
            self,
            HCEnvTypeDescription(self.envType),
            (long)self.clusterIndex,
            HCNormalizedString(self.isolation),
            HCNormalizedString(self.saas),
            HCNormalizedString(self.version),
            HCNormalizedString(self.customBaseURL)];
}

@end

@implementation HCEnvBuildResult

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; baseURL=%@; displayName=%@; isolation=%@; saas=%@>",
            NSStringFromClass([self class]),
            self,
            HCNormalizedString(self.baseURL),
            HCNormalizedString(self.displayName),
            HCNormalizedString(self.isolation),
            HCNormalizedString(self.saas)];
}

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
        if (config.envType != HCEnvTypeCustom) {
            NSNumber *clusterIndex = stored[@"clusterIndex"];
            if (clusterIndex) {
                config.clusterIndex = clusterIndex.integerValue;
            }
        }
        config.isolation = stored[@"isolation"] ?: @"";
        config.saas = stored[@"saas"] ?: @"";
        if (config.envType != HCEnvTypeCustom) {
            config.version = stored[@"version"] ?: @"v1";
        }
        config.customBaseURL = stored[@"customBaseURL"] ?: @"";
    }
    return config;
}

+ (void)saveConfig:(HCEnvConfig *)config {
    NSMutableDictionary *payload = [@{
        @"envType": @(config.envType),
        @"isolation": config.isolation ?: @"",
        @"saas": config.saas ?: @"",
        @"customBaseURL": config.customBaseURL ?: @""
    } mutableCopy];
    if (config.envType != HCEnvTypeCustom) {
        payload[@"clusterIndex"] = @(config.clusterIndex);
        payload[@"version"] = config.version ?: @"v1";
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:payload forKey:kHCEnvKitDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:HCEnvKitConfigDidChangeNotification object:nil];
}

+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config {
    HCEnvBuildResult *result = [[HCEnvBuildResult alloc] init];
    result.isolation = config.isolation ?: @"";
    result.saas = config.saas ?: @"";
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
