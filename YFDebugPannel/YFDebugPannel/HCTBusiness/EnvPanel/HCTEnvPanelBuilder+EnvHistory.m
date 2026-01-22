/// 创建时间：2026/01/22
/// 创建人：Codex
/// 用途：自定义环境历史记录解析与持久化。
#import "HCTEnvPanelBuilder+EnvConfig.h"

#import "HCTEnvKit.h"

static NSString *const kEnvItemStoreCustomHistory = @"HCTEnvKit.customHistory";
static NSString *const kCustomHistoryValueSeparator = @" | ";

NSString *const HCTEnvHistoryBaseURLKey = @"baseURL";
NSString *const HCTEnvHistorySaasKey = @"saas";

static NSString *customHistoryOptionValue(NSDictionary<NSString *, NSString *> *entry) {
    NSString *baseURL = entry[HCTEnvHistoryBaseURLKey] ?: @"";
    NSString *saas = entry[HCTEnvHistorySaasKey] ?: @"";
    if (saas.length > 0) {
        return [NSString stringWithFormat:@"%@%@%@", baseURL, kCustomHistoryValueSeparator, saas];
    }
    return baseURL;
}

static NSArray<NSDictionary<NSString *, NSString *> *> *defaultCustomHistoryEntries(void) {
    return @[
        @{
            HCTEnvHistoryBaseURLKey : @"https://custom-uat.example.com",
            HCTEnvHistorySaasKey : @"hpc-uat-1"
        },
        @{
            HCTEnvHistoryBaseURLKey : @"https://custom-dev.example.com",
            HCTEnvHistorySaasKey : @"hpc-uat-2"
        }
    ];
}

static NSArray<NSDictionary<NSString *, NSString *> *> *customHistoryEntriesInternal(void) {
    NSArray *stored = [[NSUserDefaults standardUserDefaults] arrayForKey:kEnvItemStoreCustomHistory];
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *normalized = [NSMutableArray array];
    NSArray *merged = stored ?: @[];
    NSMutableArray *candidates = [NSMutableArray arrayWithArray:defaultCustomHistoryEntries()];
    if ([merged isKindOfClass:[NSArray class]]) {
        [candidates addObjectsFromArray:merged];
    }
    for (id entry in candidates) {
        if (![entry isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *dict = (NSDictionary *)entry;
        NSString *baseURL = [dict[HCTEnvHistoryBaseURLKey] isKindOfClass:[NSString class]] ? dict[HCTEnvHistoryBaseURLKey] : @"";
        NSString *saas = [dict[HCTEnvHistorySaasKey] isKindOfClass:[NSString class]] ? dict[HCTEnvHistorySaasKey] : @"";
        if (baseURL.length == 0) {
            continue;
        }
        BOOL exists = [normalized indexOfObjectPassingTest:^BOOL(NSDictionary<NSString *, NSString *> *obj, NSUInteger idx, BOOL *stop) {
            BOOL sameBase = [obj[HCTEnvHistoryBaseURLKey] isEqualToString:baseURL];
            BOOL sameSaas = [obj[HCTEnvHistorySaasKey] ?: @"" isEqualToString:saas ?: @""];
            return sameBase && sameSaas;
        }] != NSNotFound;
        if (exists) {
            continue;
        }
        [normalized addObject:@{
            HCTEnvHistoryBaseURLKey : baseURL,
            HCTEnvHistorySaasKey : saas
        }];
    }
    return [normalized copy];
}

@implementation HCTEnvPanelBuilder (EnvHistory)

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)customHistoryEntries {
    return customHistoryEntriesInternal();
}

+ (NSArray<NSString *> *)customHistoryOptions {
    NSMutableArray<NSString *> *options = [NSMutableArray array];
    for (NSDictionary<NSString *, NSString *> *entry in customHistoryEntriesInternal()) {
        NSString *optionValue = customHistoryOptionValue(entry);
        if (optionValue.length > 0) {
            [options addObject:optionValue];
        }
    }
    return [options copy];
}

+ (NSDictionary<NSString *, NSString *> *)customHistoryComponentsFromValue:(NSString *)value {
    if (![value isKindOfClass:[NSString class]] || value.length == 0) {
        return @{
            HCTEnvHistoryBaseURLKey : @"",
            HCTEnvHistorySaasKey : @""
        };
    }
    NSRange separatorRange = [value rangeOfString:kCustomHistoryValueSeparator];
    if (separatorRange.location != NSNotFound) {
        NSString *baseURL = [value substringToIndex:separatorRange.location];
        NSString *saas = [value substringFromIndex:NSMaxRange(separatorRange)];
        return @{
            HCTEnvHistoryBaseURLKey : baseURL ?: @"",
            HCTEnvHistorySaasKey : saas ?: @""
        };
    }
    return @{
        HCTEnvHistoryBaseURLKey : value ?: @"",
        HCTEnvHistorySaasKey : @""
    };
}

+ (BOOL)customHistoryContainsConfig:(HCEnvConfig *)config {
    if (!config || config.envType != HCEnvTypeCustom) {
        return NO;
    }
    NSString *baseURL = [config.customBaseURL isKindOfClass:[NSString class]] ? config.customBaseURL : @"";
    if (baseURL.length == 0) {
        return NO;
    }
    NSString *saas = [config.saas isKindOfClass:[NSString class]] ? config.saas : @"";
    for (NSDictionary<NSString *, NSString *> *entry in customHistoryEntriesInternal()) {
        BOOL sameBase = [entry[HCTEnvHistoryBaseURLKey] isEqualToString:baseURL];
        BOOL sameSaas = [entry[HCTEnvHistorySaasKey] ?: @"" isEqualToString:saas ?: @""];
        if (sameBase && sameSaas) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)appendCustomHistoryFromConfig:(HCEnvConfig *)config {
    if (!config || config.envType != HCEnvTypeCustom) {
        return NO;
    }
    NSString *baseURL = [config.customBaseURL isKindOfClass:[NSString class]] ? config.customBaseURL : @"";
    if (baseURL.length == 0) {
        return NO;
    }
    NSString *saas = [config.saas isKindOfClass:[NSString class]] ? config.saas : @"";
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *history = [customHistoryEntriesInternal() mutableCopy];
    NSIndexSet *duplicated = [history indexesOfObjectsPassingTest:^BOOL(NSDictionary<NSString *, NSString *> *entry, NSUInteger idx, BOOL *stop) {
        BOOL sameBase = [entry[HCTEnvHistoryBaseURLKey] isEqualToString:baseURL];
        BOOL sameSaas = [entry[HCTEnvHistorySaasKey] ?: @"" isEqualToString:saas ?: @""];
        return sameBase && sameSaas;
    }];
    if (duplicated.count > 0) {
        [history removeObjectsAtIndexes:duplicated];
    }
    [history insertObject:@{
        HCTEnvHistoryBaseURLKey : baseURL,
        HCTEnvHistorySaasKey : saas ?: @""
    } atIndex:0];
    if (history.count > 20) {
        [history removeObjectsInRange:NSMakeRange(20, history.count - 20)];
    }
    [[NSUserDefaults standardUserDefaults] setObject:history forKey:kEnvItemStoreCustomHistory];
    return YES;
}

@end
