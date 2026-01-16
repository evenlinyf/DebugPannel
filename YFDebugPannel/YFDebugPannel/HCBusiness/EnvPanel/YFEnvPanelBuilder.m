/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 Builder 实现。
#import "YFEnvPanelBuilder.h"

#import "HCEnvKit.h"
#import "YFEnvPanelViewController.h"
#import "YFEnvSection.h"
#import "YFCellItem.h"
#import "YFValueHelpers.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NSString *const YFEnvItemIdEnvType = @"env.type";
NSString *const YFEnvItemIdCluster = @"env.cluster";
NSString *const YFEnvItemIdSaas = @"env.saas";
NSString *const YFEnvItemIdIsolation = @"env.isolation";
NSString *const YFEnvItemIdVersion = @"env.version";
NSString *const YFEnvItemIdResult = @"env.result";
NSString *const YFEnvItemIdElb = @"config.elb";
NSString *const YFEnvItemIdSave = @"env.save";
NSNotificationName const YFEnvPanelDidSaveNotification = @"YFEnvPanelDidSaveNotification";

static NSString *const kEnvItemStoreIsolation = @"HCEnvKit.isolation";
static NSString *const kEnvItemStoreVersion = @"HCEnvKit.version";
static NSString *const kEnvItemStoreCluster = @"HCEnvKit.cluster";
static NSString *const kEnvItemStoreSaas = @"HCEnvKit.saas";
static NSString *const kEnvItemStoreResult = @"HCEnvKit.result";
static NSInteger const kEnvClusterMin = 1;
static NSInteger const kEnvClusterMax = 20;
static NSString *const kEnvSaasPrefix = @"hpc-uat-";
static const void *kYFEnvPanelSaveBaselineKey = &kYFEnvPanelSaveBaselineKey;

// 环境配置需要按环境类型隔离持久化 key。
static NSString *storeKeyForEnvType(NSString *baseKey, HCEnvType envType) {
    return [NSString stringWithFormat:@"%@.%ld", baseKey, (long)envType];
}

static NSString *autoBaseURLForConfig(HCEnvConfig *config) {
    HCEnvConfig *autoConfig = [[HCEnvConfig alloc] init];
    autoConfig.envType = config.envType;
    autoConfig.clusterIndex = config.clusterIndex;
    autoConfig.isolation = config.isolation;
    autoConfig.version = config.version;
    autoConfig.customBaseURL = @"";
    HCEnvBuildResult *build = [HCEnvKit buildResult:autoConfig];
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

static NSDictionary<NSString *, id> *saveComparisonValuesFromItems(NSDictionary<NSString *, YFCellItem *> *itemsById) {
    YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
    YFCellItem *clusterItem = itemsById[YFEnvItemIdCluster];
    YFCellItem *saasItem = itemsById[YFEnvItemIdSaas];
    YFCellItem *isolationItem = itemsById[YFEnvItemIdIsolation];
    YFCellItem *versionItem = itemsById[YFEnvItemIdVersion];
    return @{
        YFEnvItemIdEnvType : envItem.value ?: [NSNull null],
        YFEnvItemIdCluster : clusterItem.value ?: [NSNull null],
        YFEnvItemIdSaas : saasItem.value ?: [NSNull null],
        YFEnvItemIdIsolation : isolationItem.value ?: [NSNull null],
        YFEnvItemIdVersion : versionItem.value ?: [NSNull null]
    };
}

static YFCellItem *saveItemFromSections(NSArray<YFEnvSection *> *sections) {
    NSDictionary<NSString *, YFCellItem *> *itemsById = [YFEnvPanelBuilder indexItemsByIdFromSections:sections];
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

@implementation YFEnvPanelBuilder

- (NSArray<YFEnvSection *> *)buildSections {
    NSArray<YFEnvSection *> *sections = [[self class] buildSections];
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.storeKey.length == 0) {
                continue;
            }
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:item.storeKey];
            if (stored) {
                item.value = stored;
            } else if (item.defaultValue) {
                item.value = item.defaultValue;
            }
            if (item.type == YFCellItemTypeEditableInfo) {
                item.detail = item.value ? [NSString stringWithFormat:@"%@", item.value] : nil;
            }
        }
    }
    [[self class] refreshSections:sections];
    [[self class] configureSaveActionForSections:sections onSave:nil];
    [[self class] captureBaselineForSections:sections];
    [[self class] updateSaveItemVisibilityInSections:sections];
    return sections;
}

- (void)refreshSections:(NSArray<YFEnvSection *> *)sections {
    [[self class] refreshSections:sections];
    [[self class] updateSaveItemVisibilityInSections:sections];
}

+ (NSArray<YFEnvSection *> *)buildSections {
    YFEnvSection *envSection = [self buildEnvSection];
    YFEnvSection *configSection = [self buildConfigSection];
    return @[envSection, configSection];
}

+ (UIViewController *)buildPanelViewController {
    YFEnvPanelViewController *controller = [[YFEnvPanelViewController alloc] initWithBuilder:[[YFEnvPanelBuilder alloc] init]];
    return controller;
}

+ (NSDictionary<NSString *, YFCellItem *> *)indexItemsByIdFromSections:(NSArray<YFEnvSection *> *)sections {
    NSMutableDictionary<NSString *, YFCellItem *> *itemsById = [NSMutableDictionary dictionary];
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.identifier.length > 0) {
                itemsById[item.identifier] = item;
            }
        }
    }
    return [itemsById copy];
}

+ (void)refreshSections:(NSArray<YFEnvSection *> *)sections {
    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.recomputeBlock) {
                item.recomputeBlock(item, itemsById);
            }
        }
    }
}

+ (HCEnvConfig *)configFromSections:(NSArray<YFEnvSection *> *)sections {
    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    return [self configFromItems:itemsById];
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
        [HCEnvKit saveConfig:config];
        [self captureBaselineForSections:strongSections];
        [self updateSaveItemVisibilityInSections:strongSections];
        if (onSave) {
            onSave();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:YFEnvPanelDidSaveNotification object:nil];
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
    NSDictionary<NSString *, id> *baseline = saveComparisonValuesFromItems(itemsById);
    objc_setAssociatedObject(saveItem, kYFEnvPanelSaveBaselineKey, baseline, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// 如何新增配置项（重要）：
/// 1. 在本文件顶部新增常量标识（如 YFEnvItemIdXXX）与持久化 key（如 kEnvItemStoreXXX）。
/// 2. 在 buildEnvSection 中创建 YFCellItem，补充 title、type、storeKey/defaultValue、dependsOn 和 recomputeBlock。
/// 3. 在 configFromItems 中读取新字段，映射到 HCEnvConfig 属性，并在 HCEnvKit 中持久化该属性。
/// 4. 如需影响联动显示，确保将新项加入 result 的 dependsOn 列表，并在 recomputeBlock 中刷新 detail/title。
+ (YFEnvSection *)buildEnvSection {
    HCEnvConfig *config = [HCEnvKit currentConfig];

    // 环境类型：用 segment 统一管理。
    NSArray<NSString *> *envOptions = @[@"线上", @"uat", @"dev", @"自定义"];
    YFCellItem *envType = [YFCellItem segmentItemWithIdentifier:YFEnvItemIdEnvType
                                                          title:@"环境类型"
                                                        options:envOptions
                                                   defaultValue:@(config.envType)];
    envType.value = @(config.envType);

    // 环境编号：需要根据 envType 切换持久化 key。
    YFCellItem *cluster = [YFCellItem stepperItemWithIdentifier:YFEnvItemIdCluster title:@"环境编号" storeKey:storeKeyForEnvType(kEnvItemStoreCluster, config.envType) defaultValue:[NSString stringWithFormat:@"%ld", (long)kEnvClusterMin] minimum:1 maximum:20];
    NSInteger initialCluster = MAX(kEnvClusterMin, config.clusterIndex);
    cluster.value = [NSString stringWithFormat:@"%ld", (long)initialCluster];
    cluster.disabledHint = @"仅 uat/dev 可用";
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
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreCluster, envTypeValue);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            item.value = stored ?: item.defaultValue;
        }
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.hidden = (envTypeValue == HCEnvTypeRelease || envTypeValue == HCEnvTypeCustom);
        NSInteger current = MAX(kEnvClusterMin, YFIntValue(item.value));
        current = MIN(kEnvClusterMax, current);
        item.value = [NSString stringWithFormat:@"%ld", (long)current];
        item.detail = item.value;
    };

    // Saas 环境：根据 cluster 自动生成默认值，仍允许手动编辑。
    YFCellItem *saas = [YFCellItem stringItemWithIdentifier:YFEnvItemIdSaas
                                                      title:@"Saas 环境"
                                                   storeKey:storeKeyForEnvType(kEnvItemStoreSaas, config.envType)
                                               defaultValue:nil];
    saas.value = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)initialCluster];
    saas.disabledHint = @"仅 uat/dev 可用";
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
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.hidden = (envTypeValue == HCEnvTypeRelease);
        NSInteger clusterValue = MAX(kEnvClusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
        NSString *autoValue = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)clusterValue];
        if ([item.value isKindOfClass:[NSString class]]) {
            NSString *current = item.value;
            BOOL matchesAuto = [current hasPrefix:kEnvSaasPrefix];
            NSString *suffix = [current stringByReplacingOccurrencesOfString:kEnvSaasPrefix withString:@""];
            NSScanner *scanner = [NSScanner scannerWithString:suffix];
            NSInteger number = 0;
            BOOL isNumber = [scanner scanInteger:&number] && scanner.isAtEnd;
            if (matchesAuto && isNumber) {
                item.value = autoValue;
            }
        } else {
            item.value = autoValue;
        }
    };

    // 隔离参数：不同环境类型各自持久化。
    YFCellItem *isolation = [YFCellItem stringItemWithIdentifier:YFEnvItemIdIsolation
                                                           title:@"隔离参数"
                                                        storeKey:storeKeyForEnvType(kEnvItemStoreIsolation, config.envType)
                                                    defaultValue:@""];
    isolation.value = config.isolation;
    isolation.disabledHint = @"仅 uat/dev 可用";
    isolation.dependsOn = @[YFEnvItemIdEnvType];
    isolation.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreIsolation, envTypeValue);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            item.value = stored ?: item.defaultValue;
        }
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.hidden = (envTypeValue == HCEnvTypeRelease);
    };

    // 版本号：不同环境类型各自持久化。
    YFCellItem *version = [YFCellItem stringItemWithIdentifier:YFEnvItemIdVersion
                                                         title:@"版本号"
                                                      storeKey:storeKeyForEnvType(kEnvItemStoreVersion, config.envType)
                                                  defaultValue:@"v1"];
    version.value = config.version;
    version.disabledHint = @"仅 uat/dev 可用";
    version.dependsOn = @[YFEnvItemIdEnvType];
    version.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreVersion, envTypeValue);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            item.value = stored ?: item.defaultValue;
        }
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.hidden = (envTypeValue == HCEnvTypeRelease || envTypeValue == HCEnvTypeCustom);
    };

    // Final URL：自定义环境可编辑，其余环境根据配置自动生成。
    YFCellItem *result = [YFCellItem editableInfoItemWithIdentifier:YFEnvItemIdResult
                                                               title:@"环境"
                                                            storeKey:storeKeyForEnvType(kEnvItemStoreResult, config.envType)
                                                        defaultValue:@""];
    result.value = config.customBaseURL.length > 0 ? config.customBaseURL : @"";
    NSInteger displayCluster = MAX(kEnvClusterMin, YFIntValue(cluster.value));
    displayCluster = MIN(kEnvClusterMax, displayCluster);
    NSString *displayLabel = envDisplayLabel(config.envType, displayCluster);
    result.title = [NSString stringWithFormat:@"环境：%@", displayLabel];
    result.detail = autoBaseURLForConfig(config);
    result.dependsOn = @[YFEnvItemIdEnvType, YFEnvItemIdCluster, YFEnvItemIdVersion, YFEnvItemIdIsolation];
    result.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        HCEnvConfig *config = [self configFromItems:itemsById];
        NSString *autoBaseURL = autoBaseURLForConfig(config);
        NSString *current = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
        NSString *previousAuto = [item.autoValue isKindOfClass:[NSString class]] ? item.autoValue : @"";
        BOOL isCustom = (config.envType == HCEnvTypeCustom);
        BOOL isRelease = config.envType == HCEnvTypeRelease;
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreResult, config.envType);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            item.value = stored ?: item.defaultValue;
            current = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
        }
        item.enabled = isCustom;
        if (isRelease || current.length == 0 || [current isEqualToString:previousAuto]) {
            item.value = autoBaseURL;
        }
        item.autoValue = autoBaseURL;
        NSInteger displayCluster = MAX(kEnvClusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
        displayCluster = MIN(kEnvClusterMax, displayCluster);
        NSString *displayLabel = envDisplayLabel(config.envType, displayCluster);
        item.title = [NSString stringWithFormat:@"环境：%@", displayLabel];
        item.hidden = isRelease;
        item.detail = item.value.length > 0 ? item.value : autoBaseURL;
    };

    YFCellItem *save = [YFCellItem actionItemWithIdentifier:YFEnvItemIdSave title:@"保存" handler:nil];
    save.hidden = YES;
    save.dependsOn = @[YFEnvItemIdEnvType, YFEnvItemIdCluster, YFEnvItemIdSaas, YFEnvItemIdIsolation, YFEnvItemIdVersion];
    save.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        NSDictionary<NSString *, id> *baseline = objc_getAssociatedObject(item, kYFEnvPanelSaveBaselineKey);
        if (!baseline) {
            item.hidden = YES;
            item.enabled = NO;
            return;
        }
        NSDictionary<NSString *, id> *current = saveComparisonValuesFromItems(itemsById);
        BOOL pending = ![baseline isEqualToDictionary:current];
        item.hidden = !pending;
        item.enabled = pending;
    };

    NSArray<YFCellItem *> *items = @[envType, cluster, saas, isolation, version, result, save];
    YFEnvSection *section = [YFEnvSection sectionWithTitle:@"环境配置" items:items];

    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:@[section]];
    for (YFCellItem *item in items) {
        if (item.recomputeBlock) {
            item.recomputeBlock(item, itemsById);
        }
    }

    return section;
}

+ (YFEnvSection *)buildConfigSection {
    // ELB 开关：常规布尔持久化配置项。
    YFCellItem *elb = [YFCellItem switchItemWithIdentifier:YFEnvItemIdElb
                                                     title:@"ELB 开关"
                                                  storeKey:@"elbconfig"
                                              defaultValue:@(YES)];
    elb.detail = @"如果不需要获取动态域名， 请关闭开关";

    NSArray<YFCellItem *> *items = @[elb];
    return [YFEnvSection sectionWithTitle:@"配置" items:items];
}

+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById {
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
    YFCellItem *clusterItem = itemsById[YFEnvItemIdCluster];
    YFCellItem *isolationItem = itemsById[YFEnvItemIdIsolation];
    YFCellItem *versionItem = itemsById[YFEnvItemIdVersion];
    YFCellItem *resultItem = itemsById[YFEnvItemIdResult];
    config.envType = YFIntValue(envItem.value);
    NSInteger clusterValue = MAX(kEnvClusterMin, YFIntValue(clusterItem.value));
    clusterValue = MIN(kEnvClusterMax, clusterValue);
    config.clusterIndex = clusterValue;
    config.isolation = [isolationItem.value isKindOfClass:[NSString class]] ? isolationItem.value : @"";
    config.version = [versionItem.value isKindOfClass:[NSString class]] ? versionItem.value : @"v1";
    NSString *resultValue = [resultItem.value isKindOfClass:[NSString class]] ? resultItem.value : @"";
    NSString *autoBaseURL = autoBaseURLForConfig(config);
    if (config.envType == HCEnvTypeRelease) {
        config.customBaseURL = @"";
    } else if (resultValue.length > 0 && ![resultValue isEqualToString:autoBaseURL]) {
        config.customBaseURL = resultValue;
    } else {
        config.customBaseURL = @"";
    }
    return config;
}

@end
