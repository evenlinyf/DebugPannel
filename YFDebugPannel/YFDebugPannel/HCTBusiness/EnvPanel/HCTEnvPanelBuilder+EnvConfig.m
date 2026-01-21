/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：环境配置 Section 构建与配置映射分类。
#import "HCTEnvPanelBuilder+EnvConfig.h"

#import "HCTEnvKit.h"
#import "YFEnvSection.h"
#import "YFCellItem.h"
#import "YFValueHelpers.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface HCTEnvPanelBuilder (SaveHelpers)
+ (NSDictionary<NSString *, id> *)saveComparisonValuesFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById;
+ (const void *)saveBaselineKey;
@end

static const void *kHCTEnvPanelSaveBaselineKey = &kHCTEnvPanelSaveBaselineKey;

static YFCellItem *saveItemFromSections(NSArray<YFEnvSection *> *sections) {
    NSDictionary<NSString *, YFCellItem *> *itemsById = [HCTEnvPanelBuilder indexItemsByIdFromSections:sections];
    return itemsById[YFEnvItemIdSave];
}

static void persistAllItemsInSections(NSArray<YFEnvSection *> *sections) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.storeKey.length == 0) {
                continue;
            }
            if (item.value) {
                [defaults setObject:item.value forKey:item.storeKey];
            } else {
                [defaults removeObjectForKey:item.storeKey];
            }
        }
    }
}

static NSString *const kEnvItemStoreIsolation = @"HCTEnvKit.isolation";
static NSString *const kEnvItemStoreVersion = @"HCTEnvKit.version";
static NSString *const kEnvItemStoreCluster = @"HCTEnvKit.cluster";
static NSString *const kEnvItemStoreSaas = @"HCTEnvKit.saas";
static NSString *const kEnvItemStoreResult = @"HCTEnvKit.result";
static NSInteger const kEnvClusterMin = 1;
static NSInteger const kEnvClusterMax = 30;
static NSString *const kEnvSaasPrefix = @"hpc-uat-";

// 环境配置需要按环境类型隔离持久化 key。
static NSString *storeKeyForEnvType(NSString *baseKey, HCEnvType envType) {
    return [NSString stringWithFormat:@"%@.%ld", baseKey, (long)envType];
}

static NSString *autoBaseURLForConfig(HCEnvConfig *config) {
    switch (config.envType) {
        case HCEnvTypeCustom:
            return config.customBaseURL ?: @"";
        case HCEnvTypeRelease:
        case HCEnvTypeUat:
        case HCEnvTypeDev:
            break;
    }
    HCEnvConfig *autoConfig = [[HCEnvConfig alloc] init];
    autoConfig.envType = config.envType;
    autoConfig.clusterIndex = config.clusterIndex;
    autoConfig.isolation = config.isolation;
    autoConfig.version = config.version;
    autoConfig.customBaseURL = @"";
    HCEnvBuildResult *build = [HCTEnvKit buildResult:autoConfig];
    return build.baseURL ?: @"";
}

static NSString *envDisplayLabel(HCEnvType envType, NSInteger clusterValue) {
    switch (envType) {
        case HCEnvTypeRelease:
            return @"线上环境";
        case HCEnvTypeCustom:
            return @"自定义";
        case HCEnvTypeUat:
            return [NSString stringWithFormat:@"uat-%ld", (long)clusterValue];
        case HCEnvTypeDev:
            return [NSString stringWithFormat:@"dev-%ld", (long)clusterValue];
    }
    return @"";
}

@implementation HCTEnvPanelBuilder (EnvConfig)

/// 如何新增配置项（重要）：
/// 1. 在本文件顶部新增常量标识（如 YFEnvItemIdXXX）与持久化 key（如 kEnvItemStoreXXX）。
/// 2. 在 buildEnvSection 中创建 YFCellItem，补充 title、type、storeKey/defaultValue、dependsOn 和 recomputeBlock。
/// 3. 在 configFromItems 中读取新字段，映射到 HCEnvConfig 属性，并在 HCTEnvKit 中持久化该属性。
/// 4. 如需影响联动显示，确保将新项加入 result 的 dependsOn 列表，并在 recomputeBlock 中刷新 detail/title。
+ (YFEnvSection *)buildEnvSection {
    HCEnvConfig *config = [HCTEnvKit currentConfig];

    // 环境类型：用 segment 统一管理。
    NSArray<NSString *> *envOptions = @[@"线上", @"uat", @"dev", @"自定义"];
    YFCellItem *envType = [YFCellItem segmentItemWithIdentifier:YFEnvItemIdEnvType
                                                          title:@"环境类型"
                                                        options:envOptions
                                                   defaultValue:@(config.envType)];
    envType.value = @(config.envType);

    // 环境编号：需要根据 envType 切换持久化 key。
    NSInteger initialCluster = MAX(kEnvClusterMin, config.clusterIndex);
    YFCellItem *cluster = [YFCellItem stepperItemWithIdentifier:YFEnvItemIdCluster
                                                          title:@"环境编号"
                                                       storeKey:storeKeyForEnvType(kEnvItemStoreCluster, config.envType)
                                                   defaultValue:[NSString stringWithFormat:@"%ld", (long)initialCluster]
                                                        minimum:kEnvClusterMin
                                                        maximum:kEnvClusterMax];
    cluster.usesStoredValueOnLoad = NO;
    cluster.disabledHint = @"仅 uat/dev 可用";
    cluster.detailTextColor = [UIColor redColor];
    cluster.dependsOn = @[YFEnvItemIdEnvType];
    cluster.validator = ^NSString *(NSString *input) {
        if (input.length == 0) {
            return @"环境编号不能为空";
        }
        NSScanner *scanner = [NSScanner scannerWithString:input];
        NSInteger number = 0;
        BOOL isNumber = [scanner scanInteger:&number] && scanner.isAtEnd;
        if (!isNumber) {
            return @"环境编号需要为数字";
        }
        if (number < kEnvClusterMin || number > kEnvClusterMax) {
            return [NSString stringWithFormat:@"环境编号范围为 %ld-%ld", (long)kEnvClusterMin, (long)kEnvClusterMax];
        }
        return nil;
    };
    cluster.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = @"";
        switch (envTypeValue) {
            case HCEnvTypeRelease:
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                newStoreKey = storeKeyForEnvType(kEnvItemStoreCluster, envTypeValue);
                break;
            case HCEnvTypeCustom:
                newStoreKey = @"";
                break;
        }
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            if (newStoreKey.length > 0) {
                id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
                item.value = stored ?: item.defaultValue;
            } else {
                item.value = item.defaultValue;
            }
        }
        switch (envTypeValue) {
            case HCEnvTypeRelease:
                item.enabled = NO;
                item.hidden = YES;
                break;
            case HCEnvTypeCustom:
                item.enabled = YES;
                item.hidden = YES;
                break;
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                item.enabled = YES;
                item.hidden = NO;
                break;
        }
        NSInteger current = MAX(kEnvClusterMin, YFIntValue(item.value));
        current = MIN(kEnvClusterMax, current);
        item.value = [NSString stringWithFormat:@"%ld", (long)current];
        item.detail = item.value;
    };

    // Saas 环境：根据 cluster 自动生成默认值，仍允许手动编辑。
    YFCellItem *saas = [YFCellItem stringItemWithIdentifier:YFEnvItemIdSaas
                                                      title:@"Saas 环境"
                                                   storeKey:storeKeyForEnvType(kEnvItemStoreSaas, config.envType)
                                               defaultValue:[NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)initialCluster]];
    saas.usesStoredValueOnLoad = NO;
    saas.disabledHint = @"仅 uat/dev 可用";
    saas.detail = @"随环境编号自动变化";
    saas.dependsOn = @[YFEnvItemIdEnvType, YFEnvItemIdCluster];
    saas.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreSaas, envTypeValue);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            if (stored) {
                item.value = stored;
            } else {
                NSInteger clusterValue = MAX(kEnvClusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
                item.value = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)clusterValue];
            }
        }
        switch (envTypeValue) {
            case HCEnvTypeRelease:
                item.enabled = NO;
                item.hidden = YES;
                item.autoValue = nil;
                break;
            case HCEnvTypeCustom: {
                item.enabled = YES;
                item.hidden = NO;
                if (![item.value isKindOfClass:[NSString class]] || [(NSString *)item.value length] == 0) {
                    id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
                    if (stored) {
                        item.value = stored;
                    }
                }
                item.autoValue = nil;
                break;
            }
            case HCEnvTypeUat:
            case HCEnvTypeDev: {
                item.enabled = YES;
                item.hidden = NO;
                NSInteger clusterValue = MAX(kEnvClusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
                NSString *autoValue = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)clusterValue];
                NSString *previousAuto = [item.autoValue isKindOfClass:[NSString class]] ? item.autoValue : @"";
                BOOL autoValueChanged = ![previousAuto isEqualToString:autoValue];
                if (![item.value isKindOfClass:[NSString class]]) {
                    item.value = autoValue;
                } else {
                    NSString *current = item.value;
                    BOOL shouldResetToAuto = (current.length == 0 || [current isEqualToString:previousAuto]);
                    if (autoValueChanged || shouldResetToAuto) {
                        item.value = autoValue;
                    }
                }
                item.autoValue = autoValue;
                break;
            }
        }
    };

    // 隔离参数：全局持久化，切到线上并保存时清空。
    YFCellItem *isolation = [YFCellItem stringItemWithIdentifier:YFEnvItemIdIsolation
                                                           title:@"隔离参数"
                                                        storeKey:kEnvItemStoreIsolation
                                                    defaultValue:config.isolation];
    isolation.usesStoredValueOnLoad = NO;
    isolation.disabledHint = @"仅 uat/dev 可用";
    isolation.dependsOn = @[YFEnvItemIdEnvType];
    isolation.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        if (item.storeKey.length == 0) {
            item.storeKey = kEnvItemStoreIsolation;
        }
        switch (envTypeValue) {
            case HCEnvTypeRelease:
                item.value = nil;
                item.enabled = NO;
                item.hidden = YES;
                break;
            case HCEnvTypeCustom:
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                if (![item.value isKindOfClass:[NSString class]] || [(NSString *)item.value length] == 0) {
                    id stored = [[NSUserDefaults standardUserDefaults] objectForKey:item.storeKey];
                    item.value = stored ?: item.defaultValue;
                }
                item.enabled = YES;
                item.hidden = NO;
                break;
        }
    };

    // 版本号：不同环境类型各自持久化。
    YFCellItem *version = [YFCellItem stringItemWithIdentifier:YFEnvItemIdVersion
                                                         title:@"版本号"
                                                      storeKey:storeKeyForEnvType(kEnvItemStoreVersion, config.envType)
                                                  defaultValue:config.version];
    version.detail = @"版本号会赋值到 uat-* 后面， 比如 uat 3, 版本号设置 v3, url 就会变成 uat3-v3";
    version.usesStoredValueOnLoad = NO;
    version.disabledHint = @"仅 uat/dev 可用";
    version.dependsOn = @[YFEnvItemIdEnvType];
    version.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = @"";
        switch (envTypeValue) {
            case HCEnvTypeRelease:
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                newStoreKey = storeKeyForEnvType(kEnvItemStoreVersion, envTypeValue);
                break;
            case HCEnvTypeCustom:
                newStoreKey = @"";
                break;
        }
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            if (newStoreKey.length > 0) {
                id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
                item.value = stored ?: item.defaultValue;
            } else {
                item.value = item.defaultValue;
            }
        }
        switch (envTypeValue) {
            case HCEnvTypeRelease:
                item.enabled = NO;
                item.hidden = YES;
                break;
            case HCEnvTypeCustom:
                item.enabled = YES;
                item.hidden = YES;
                break;
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                item.enabled = YES;
                item.hidden = NO;
                break;
        }
    };

    // Final URL：自定义环境可编辑，其余环境根据配置自动生成。
    NSString *resultValue = config.customBaseURL.length > 0 ? config.customBaseURL : @"";
    YFCellItem *result = [YFCellItem editableInfoItemWithIdentifier:YFEnvItemIdResult
                                                               title:@"环境"
                                                            storeKey:storeKeyForEnvType(kEnvItemStoreResult, config.envType)
                                                        defaultValue:resultValue];
    result.usesStoredValueOnLoad = NO;
    NSInteger displayCluster = MAX(kEnvClusterMin, YFIntValue(cluster.value));
    displayCluster = MIN(kEnvClusterMax, displayCluster);
    NSString *displayLabel = envDisplayLabel(config.envType, displayCluster);
    result.title = [NSString stringWithFormat:@"环境：%@", displayLabel];
    result.detail = autoBaseURLForConfig(config);
    result.dependsOn = @[YFEnvItemIdEnvType, YFEnvItemIdCluster, YFEnvItemIdVersion, YFEnvItemIdIsolation];
    result.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        HCEnvConfig *config = [self configFromItems:itemsById];
        NSString *autoBaseURL = autoBaseURLForConfig(config);
        BOOL isCustom = (config.envType == HCEnvTypeCustom);
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreResult, config.envType);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            if (stored) {
                item.value = stored;
            } else if (isCustom) {
                item.value = item.defaultValue;
            } else {
                item.value = autoBaseURL;
            }
        }
        NSString *current = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
        switch (config.envType) {
            case HCEnvTypeRelease:
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                item.value = autoBaseURL;
                item.enabled = NO;
                break;
            case HCEnvTypeCustom: {
                item.enabled = YES;
                NSString *previousAuto = [item.autoValue isKindOfClass:[NSString class]] ? item.autoValue : @"";
                if (current.length == 0 || [current isEqualToString:previousAuto]) {
                    item.value = autoBaseURL;
                }
                break;
            }
        }
        item.autoValue = autoBaseURL;
        NSInteger displayCluster = MAX(kEnvClusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
        displayCluster = MIN(kEnvClusterMax, displayCluster);
        NSString *displayLabel = envDisplayLabel(config.envType, displayCluster);
        item.title = [NSString stringWithFormat:@"环境：%@", displayLabel];
        switch (config.envType) {
            case HCEnvTypeRelease:
                item.hidden = YES;
                break;
            case HCEnvTypeUat:
            case HCEnvTypeDev:
            case HCEnvTypeCustom:
                item.hidden = NO;
                break;
        }
        item.detail = ((NSString *)item.value).length > 0 ? item.value : autoBaseURL;
    };

    YFCellItem *save = [YFCellItem actionItemWithIdentifier:YFEnvItemIdSave title:@"保存" handler:nil];
    save.hidden = YES;
    save.dependsOn = @[YFEnvItemIdEnvType, YFEnvItemIdCluster, YFEnvItemIdSaas, YFEnvItemIdIsolation, YFEnvItemIdVersion, YFEnvItemIdResult];
    save.backgroundColor = UIColor.systemBlueColor;
    save.disabledBackgroundColor = UIColor.systemGray3Color;
    save.textColor = UIColor.whiteColor;
    save.disabledTextColor = UIColor.whiteColor;
    save.detailTextColor = UIColor.whiteColor;
    save.disabledDetailTextColor = UIColor.whiteColor;
    save.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        NSDictionary<NSString *, id> *baseline = objc_getAssociatedObject(item, [HCTEnvPanelBuilder saveBaselineKey]);
        if (!baseline) {
            item.hidden = YES;
            item.enabled = NO;
            return;
        }
        NSDictionary<NSString *, id> *current = [HCTEnvPanelBuilder saveComparisonValuesFromItems:itemsById];
        BOOL pending = ![baseline isEqualToDictionary:current];
        item.hidden = !pending;
        item.enabled = pending;
    };

    NSArray<YFCellItem *> *items = @[envType, cluster, version, saas, isolation, result, save];
    YFEnvSection *section = [YFEnvSection sectionWithTitle:@"环境配置" items:items];

    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:@[section]];
    for (YFCellItem *item in items) {
        if (item.recomputeBlock) {
            item.recomputeBlock(item, itemsById);
        }
    }

    return section;
}

+ (void)configureSaveActionForSections:(NSArray<YFEnvSection *> *)sections onSave:(dispatch_block_t)onSave {
    YFCellItem *saveItem = saveItemFromSections(sections);
    if (!saveItem) {
        return;
    }
    __weak NSArray<YFEnvSection *> *weakSections = sections;
    saveItem.actionHandler = ^(YFCellItem *item) {
        NSArray<YFEnvSection *> *strongSections = weakSections;
        if (!strongSections) {
            return;
        }
        persistAllItemsInSections(strongSections);
        HCEnvConfig *config = [self configFromSections:strongSections];
        [HCTEnvKit saveConfig:config];
        [self captureBaselineForSections:strongSections];
        [self updateSaveItemVisibilityInSections:strongSections];
        if (onSave) {
            onSave();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:HCTEnvPanelDidSaveNotification object:nil];
    };
}

+ (void)updateSaveItemVisibilityInSections:(NSArray<YFEnvSection *> *)sections {
    YFCellItem *saveItem = saveItemFromSections(sections);
    if (!saveItem) {
        return;
    }
    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    if (saveItem.recomputeBlock) {
        saveItem.recomputeBlock(saveItem, itemsById);
    }
}

+ (void)captureBaselineForSections:(NSArray<YFEnvSection *> *)sections {
    YFCellItem *saveItem = saveItemFromSections(sections);
    if (!saveItem) {
        return;
    }
    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    NSDictionary<NSString *, id> *baseline = [self saveComparisonValuesFromItems:itemsById];
    objc_setAssociatedObject(saveItem, kHCTEnvPanelSaveBaselineKey, baseline, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (HCEnvConfig *)configFromSections:(NSArray<YFEnvSection *> *)sections {
    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    return [self configFromItems:itemsById];
}

+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById {
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
    YFCellItem *clusterItem = itemsById[YFEnvItemIdCluster];
    YFCellItem *saasItem = itemsById[YFEnvItemIdSaas];
    YFCellItem *isolationItem = itemsById[YFEnvItemIdIsolation];
    YFCellItem *versionItem = itemsById[YFEnvItemIdVersion];
    YFCellItem *resultItem = itemsById[YFEnvItemIdResult];

    config.envType = YFIntValue(envItem.value);
    NSInteger clusterValue = MAX(kEnvClusterMin, YFIntValue(clusterItem.value));
    clusterValue = MIN(kEnvClusterMax, clusterValue);
    config.clusterIndex = clusterValue;
    config.isolation = [isolationItem.value isKindOfClass:[NSString class]] ? isolationItem.value : @"";
    config.saas = [saasItem.value isKindOfClass:[NSString class]] ? saasItem.value : @"";
    config.version = [versionItem.value isKindOfClass:[NSString class]] ? versionItem.value : @"v1";
    NSString *resultValue = [resultItem.value isKindOfClass:[NSString class]] ? resultItem.value : @"";
    NSString *autoBaseURL = autoBaseURLForConfig(config);
    switch (config.envType) {
        case HCEnvTypeRelease:
            config.customBaseURL = @"";
            break;
        case HCEnvTypeUat:
        case HCEnvTypeDev:
        case HCEnvTypeCustom:
            if (resultValue.length > 0 && ![resultValue isEqualToString:autoBaseURL]) {
                config.customBaseURL = resultValue;
            } else {
                config.customBaseURL = @"";
            }
            break;
    }
    return config;
}

+ (NSDictionary<NSString *, id> *)saveComparisonValuesFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById {
    YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
    YFCellItem *clusterItem = itemsById[YFEnvItemIdCluster];
    YFCellItem *saasItem = itemsById[YFEnvItemIdSaas];
    YFCellItem *isolationItem = itemsById[YFEnvItemIdIsolation];
    YFCellItem *versionItem = itemsById[YFEnvItemIdVersion];
    YFCellItem *resultItem = itemsById[YFEnvItemIdResult];
    return @{
        YFEnvItemIdEnvType : envItem.value ?: [NSNull null],
        YFEnvItemIdCluster : clusterItem.value ?: [NSNull null],
        YFEnvItemIdSaas : saasItem.value ?: [NSNull null],
        YFEnvItemIdIsolation : isolationItem.value ?: [NSNull null],
        YFEnvItemIdVersion : versionItem.value ?: [NSNull null],
        YFEnvItemIdResult : resultItem.value ?: [NSNull null]
    };
}

+ (const void *)saveBaselineKey {
    return kHCTEnvPanelSaveBaselineKey;
}

@end
