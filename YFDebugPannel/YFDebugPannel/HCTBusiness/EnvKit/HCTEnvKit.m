/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境配置模型与工具类实现。
#import "HCTEnvKit.h"

NSNotificationName const HCTEnvKitConfigDidChangeNotification = @"HCTEnvKitConfigDidChangeNotification";

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
        _version = @"";
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

@implementation HCTEnvKit

static NSString *const kHCTEnvKitDefaultsKey = @"HCTEnvKit.config";
static HCTEnvKitConfiguration *HCTEnvKitSharedConfiguration = nil;

+ (HCTEnvKitConfiguration *)configuration {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HCTEnvKitSharedConfiguration = [[HCTEnvKitConfiguration alloc] init];
    });
    return HCTEnvKitSharedConfiguration;
}

+ (void)setConfiguration:(HCTEnvKitConfiguration *)configuration {
    if (!configuration) {
        return;
    }
    HCTEnvKitSharedConfiguration = [configuration copy];
}

+ (HCEnvConfig *)currentConfig {
    NSDictionary *stored = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kHCTEnvKitDefaultsKey];
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
            config.version = stored[@"version"] ?: @"";
        }
        config.customBaseURL = stored[@"customBaseURL"] ?: @"";
    }
    return config;
}

+ (BOOL)hasSavedConfig {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kHCTEnvKitDefaultsKey] != nil;
}

+ (HCEnvConfig *)configByParsingBaseURL:(NSString *)baseURL saasEnv:(NSString *)saasEnv {
    NSString *normalizedBaseURL = [HCNormalizedString(baseURL) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *normalizedSaas = [HCNormalizedString(saasEnv) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    HCTEnvKitConfiguration *configuration = [self configuration];
    NSInteger clusterMin = configuration.clusterMin > 0 ? configuration.clusterMin : 1;
    NSInteger clusterMax = configuration.clusterMax > 0 ? configuration.clusterMax : 30;
    if (normalizedBaseURL.length == 0 && normalizedSaas.length == 0) {
        return nil;
    }
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    config.saas = normalizedSaas;
    if (normalizedBaseURL.length == 0 && [normalizedSaas isEqualToString:@"customer/proxy"]) {
        config.envType = HCEnvTypeRelease;
        config.customBaseURL = @"";
        return config;
    }
    if (normalizedBaseURL.length == 0) {
        config.envType = HCEnvTypeCustom;
        config.customBaseURL = @"";
        return config;
    }
    NSString *host = normalizedBaseURL;
    NSRange schemeRange = [host rangeOfString:@"://"];
    if (schemeRange.location != NSNotFound) {
        host = [host substringFromIndex:NSMaxRange(schemeRange)];
    }
    NSRange slashRange = [host rangeOfString:@"/"];
    if (slashRange.location != NSNotFound) {
        host = [host substringToIndex:slashRange.location];
    }
    NSString *normalizedHost = host.length > 0 ? host : normalizedBaseURL;

    NSInteger matchedCluster = 0;
    NSString *matchedVersion = @"";
    HCEnvType matchedType = HCEnvTypeCustom;

    BOOL (^matchTemplate)(NSString *, BOOL, HCEnvType) = ^BOOL(NSString *templateURL, BOOL expectsVersion, HCEnvType envType) {
        if (templateURL.length == 0) {
            return NO;
        }
        NSString *templateHost = templateURL;
        NSRange templateSchemeRange = [templateHost rangeOfString:@"://"];
        if (templateSchemeRange.location != NSNotFound) {
            templateHost = [templateHost substringFromIndex:NSMaxRange(templateSchemeRange)];
        }
        NSRange templateSlashRange = [templateHost rangeOfString:@"/"];
        if (templateSlashRange.location != NSNotFound) {
            templateHost = [templateHost substringToIndex:templateSlashRange.location];
        }
        if (templateHost.length == 0) {
            return NO;
        }
        NSString *tokenizedTemplate = [[templateHost stringByReplacingOccurrencesOfString:@"%ld" withString:@"__CLUSTER__"]
                                       stringByReplacingOccurrencesOfString:@"%@" withString:@"__VERSION__"];
        NSString *escapedPattern = [NSRegularExpression escapedPatternForString:tokenizedTemplate];
        escapedPattern = [escapedPattern stringByReplacingOccurrencesOfString:@"__CLUSTER__" withString:@"(\\d+)"];
        escapedPattern = [escapedPattern stringByReplacingOccurrencesOfString:@"__VERSION__" withString:@"([0-9a-zA-Z.-]+)"];
        NSString *fullPattern = [NSString stringWithFormat:@"^%@$", escapedPattern];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:fullPattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:normalizedHost options:0 range:NSMakeRange(0, normalizedHost.length)];
        if (!match) {
            return NO;
        }
        NSRange clusterRange = [match rangeAtIndex:1];
        if (clusterRange.location == NSNotFound) {
            return NO;
        }
        NSInteger clusterValue = [[normalizedHost substringWithRange:clusterRange] integerValue];
        if (clusterValue < clusterMin || clusterValue > clusterMax) {
            return NO;
        }
        matchedCluster = clusterValue;
        matchedType = envType;
        if (expectsVersion && match.numberOfRanges > 2) {
            NSRange versionRange = [match rangeAtIndex:2];
            matchedVersion = (versionRange.location != NSNotFound)
                ? [normalizedHost substringWithRange:versionRange]
                : @"";
        } else {
            matchedVersion = @"";
        }
        return YES;
    };

    if (matchTemplate(configuration.uatTemplate, YES, HCEnvTypeUat)
        || matchTemplate(configuration.uatTemplateNoVersion, NO, HCEnvTypeUat)
        || matchTemplate(configuration.devTemplate, YES, HCEnvTypeDev)
        || matchTemplate(configuration.devTemplateNoVersion, NO, HCEnvTypeDev)) {
        config.envType = matchedType;
        config.clusterIndex = matchedCluster;
        config.version = matchedVersion ?: @"";
        config.customBaseURL = @"";
        return config;
    }

    config.envType = HCEnvTypeCustom;
    config.customBaseURL = normalizedBaseURL;
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
        payload[@"version"] = config.version ?: @"";
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:payload forKey:kHCTEnvKitDefaultsKey];
    HCEnvBuildResult *result = [self buildResult:config];
    NSLog(@"Current Env = %@， result = %@", payload, result.description);
    [[NSNotificationCenter defaultCenter] postNotificationName:HCTEnvKitConfigDidChangeNotification object:nil];
}

+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config {
    HCTEnvKitConfiguration *configuration = [self configuration];
    HCEnvBuildResult *result = [[HCEnvBuildResult alloc] init];
    result.isolation = config.isolation ?: @"";
    result.saas = config.saas ?: @"";
    HCEnvType effectiveType = (config.customBaseURL.length > 0) ? HCEnvTypeCustom : config.envType;
    NSString *version = config.version ?: @"";
    BOOL hasVersion = version.length > 0;
    switch (effectiveType) {
        case HCEnvTypeCustom:
            result.displayName = @"自定义";
            result.baseURL = config.customBaseURL ?: @"";
            break;
        case HCEnvTypeRelease:
            result.displayName = @"线上";
            result.baseURL = configuration.releaseBaseURL ?: @"";
            break;
        case HCEnvTypeUat:
            result.displayName = [NSString stringWithFormat:@"uat-%ld", (long)config.clusterIndex];
            result.baseURL = hasVersion
                ? [NSString stringWithFormat:configuration.uatTemplate ?: @"", (long)config.clusterIndex, version]
                : [NSString stringWithFormat:configuration.uatTemplateNoVersion ?: @"", (long)config.clusterIndex];
            break;
        case HCEnvTypeDev:
            result.displayName = [NSString stringWithFormat:@"dev-%ld", (long)config.clusterIndex];
            result.baseURL = hasVersion
                ? [NSString stringWithFormat:configuration.devTemplate ?: @"", (long)config.clusterIndex, version]
                : [NSString stringWithFormat:configuration.devTemplateNoVersion ?: @"", (long)config.clusterIndex];
            break;
    }
    return result;
}

@end
