/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：环境配置 Section 构建与配置映射分类。
#import "HCTEnvPanelBuilder+EnvConfig.h"

#import "HCTEnvKit.h"
#import "YFEnvSection.h"
#import "YFCellItem.h"
#import "YFValueHelpers.h"
#import "YFAlertPresenter.h"
#import "YFHapticFeedback.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface HCTEnvPanelBuilder (SaveHelpers)
+ (NSDictionary<NSString *, id> *)saveComparisonValuesFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById;
+ (const void *)saveBaselineKey;
@end

@interface HCTEnvPanelBuilder (LegacyConfig)
+ (NSString *)legacyBaseURL;
+ (NSString *)legacySaasEnv;
@end

@interface HCTEnvPanelBuilder (EnvHistoryPrivate)
+ (NSArray<NSString *> *)customHistoryOptions;
+ (NSDictionary<NSString *, NSString *> *)customHistoryComponentsFromValue:(NSString *)value;
+ (BOOL)customHistoryContainsConfig:(HCEnvConfig *)config;
@end

#pragma mark - Constants

static const void *kHCTEnvPanelSaveBaselineKey = &kHCTEnvPanelSaveBaselineKey;

#pragma mark - Section Helpers

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

static HCTEnvKitConfiguration *envConfiguration(void) {
    return [HCTEnvKit configuration];
}

static NSInteger envClusterMin(void) {
    NSInteger minValue = envConfiguration().clusterMin;
    return (minValue > 0) ? minValue : 1;
}

static NSInteger envClusterMax(void) {
    NSInteger maxValue = envConfiguration().clusterMax;
    return (maxValue > 0) ? maxValue : 30;
}

static NSString *envSaasPrefixForType(HCEnvType envType) {
    switch (envType) {
        case HCEnvTypeDev:
            return @"hpc-dev-";
        case HCEnvTypeUat:
            return @"hpc-uat-";
        case HCEnvTypeRelease:
        case HCEnvTypeCustom:
            return @"hpc-uat-";
    }
    return @"hpc-uat-";
}

// 环境配置需要按环境类型隔离持久化 key。
#pragma mark - Env Formatting

static NSString *storeKeyForEnvType(NSString *baseKey, HCEnvType envType) {
    return [NSString stringWithFormat:@"%@.%ld", baseKey, (long)envType];
}

static HCEnvConfig *initialConfigForEnvSection(void) {
    HCEnvConfig *config = [HCTEnvKit currentConfig];
    if ([HCTEnvKit hasSavedConfig]) {
        return config;
    }
    NSString *legacyBaseURL = [HCTEnvPanelBuilder legacyBaseURL];
    NSString *legacySaasEnv = [HCTEnvPanelBuilder legacySaasEnv];
    HCEnvConfig *legacyConfig = [HCTEnvKit configByParsingBaseURL:legacyBaseURL saasEnv:legacySaasEnv];
    if (!legacyConfig) {
        return config;
    }
    [HCTEnvKit saveConfig:legacyConfig];
    return legacyConfig;
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

#pragma mark - UI Helpers

static UIViewController *currentTopController(void) {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    if (!window) {
        for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
    }
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController *)controller).topViewController ?: controller;
    }
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return ((UITabBarController *)controller).selectedViewController ?: controller;
    }
    return controller;
}

static void presentCustomHistorySavePrompt(HCEnvConfig *config, NSArray<YFEnvSection *> *sections) {
    UIViewController *presenter = currentTopController();
    if (!presenter || config.envType != HCEnvTypeCustom) {
        return;
    }
    if ([HCTEnvPanelBuilder customHistoryContainsConfig:config]) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存历史记录"
                                                                   message:@"是否保存到历史记录？"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak UIViewController *weakPresenter = presenter;
    __weak NSArray<YFEnvSection *> *weakSections = sections;
    [alert addAction:[UIAlertAction actionWithTitle:@"不保存" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        BOOL saved = [HCTEnvPanelBuilder appendCustomHistoryFromConfig:config];
        UIViewController *strongPresenter = weakPresenter;
        NSArray<YFEnvSection *> *strongSections = weakSections;
        if (!saved && strongPresenter) {
            [YFAlertPresenter presentToastFrom:strongPresenter message:@"自定义环境地址为空，未保存" duration:1.0];
            return;
        }
        if (strongSections) {
            [HCTEnvPanelBuilder refreshSections:strongSections];
            [[NSNotificationCenter defaultCenter] postNotificationName:HCTEnvPanelDidSaveNotification object:nil];
        }
    }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

@implementation HCTEnvPanelBuilder (EnvConfig)

#pragma mark - Section Builders

/// 如何新增配置项（重要）：
/// 1. 在本文件顶部新增常量标识（如 YFEnvItemIdXXX）与持久化 key（如 kEnvItemStoreXXX）。
/// 2. 在 buildEnvSection 中创建 YFCellItem，补充 title、type、storeKey/defaultValue、dependsOn 和 recomputeBlock。
/// 3. 在 configFromItems 中读取新字段，映射到 HCEnvConfig 属性，并在 HCTEnvKit 中持久化该属性。
/// 4. 如需影响联动显示，确保将新项加入 result 的 dependsOn 列表，并在 recomputeBlock 中刷新 detail/title。
+ (YFEnvSection *)buildEnvSection {
    HCEnvConfig *config = initialConfigForEnvSection();

    // 环境类型：用 segment 统一管理。
    NSArray<NSString *> *envOptions = @[@"线上", @"uat", @"dev", @"自定义"];
    YFCellItem *envType = [YFCellItem segmentItemWithIdentifier:YFEnvItemIdEnvType
                                                          title:@"环境类型"
                                                        options:envOptions
                                                   defaultValue:@(config.envType)];
    envType.value = @(config.envType);
    envType.icon = [UIImage systemImageNamed:@"slider.horizontal.3"];

    YFCellItem *history = [YFCellItem pickerItemWithIdentifier:YFEnvItemIdCustomHistory
                                                         title:@"历史记录"
                                                      storeKey:@""
                                                  defaultValue:@""
                                                       options:[self customHistoryOptions]];
    history.usesStoredValueOnLoad = NO;
    history.detail = @"选择后自动填充自定义环境";
    history.disabledHint = @"仅自定义环境可用";
    history.icon = [UIImage systemImageNamed:@"clock.arrow.circlepath"];
    history.dependsOn = @[YFEnvItemIdEnvType];
    history.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSArray<NSString *> *options = [self customHistoryOptions];
        item.options = options;
        BOOL hasOptions = options.count > 0;
        item.enabled = (envTypeValue == HCEnvTypeCustom) && hasOptions;
        item.hidden = (envTypeValue != HCEnvTypeCustom) || !hasOptions;
        if (envTypeValue != HCEnvTypeCustom) {
            item.value = nil;
            item.autoValue = nil;
            return;
        }
        NSString *currentValue = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
        NSString *appliedValue = [item.autoValue isKindOfClass:[NSString class]] ? item.autoValue : @"";
        if (currentValue.length == 0 || [currentValue isEqualToString:appliedValue]) {
            return;
        }
        NSDictionary<NSString *, NSString *> *selectedComponents = [self customHistoryComponentsFromValue:currentValue];
        NSDictionary<NSString *, NSString *> *selectedEntry = nil;
        for (NSDictionary<NSString *, NSString *> *entry in [self customHistoryEntries]) {
            BOOL sameBase = [entry[HCTEnvHistoryBaseURLKey] isEqualToString:selectedComponents[HCTEnvHistoryBaseURLKey]];
            NSString *selectedSaas = selectedComponents[HCTEnvHistorySaasKey] ?: @"";
            if (selectedSaas.length > 0) {
                BOOL sameSaas = [entry[HCTEnvHistorySaasKey] ?: @"" isEqualToString:selectedSaas];
                if (sameBase && sameSaas) {
                    selectedEntry = entry;
                    break;
                }
            } else if (sameBase) {
                selectedEntry = entry;
                break;
            }
        }
        if (!selectedEntry) {
            return;
        }
        item.autoValue = currentValue;
        YFCellItem *saasItem = itemsById[YFEnvItemIdSaas];
        YFCellItem *resultItem = itemsById[YFEnvItemIdResult];
        NSString *saasValue = selectedEntry[HCTEnvHistorySaasKey] ?: @"";
        NSString *baseURLValue = selectedEntry[HCTEnvHistoryBaseURLKey] ?: @"";
        if (saasItem) {
            saasItem.value = saasValue;
        }
        if (resultItem) {
            resultItem.value = baseURLValue;
        }
    };

    // 环境编号：需要根据 envType 切换持久化 key。
    NSInteger clusterMin = envClusterMin();
    NSInteger clusterMax = envClusterMax();
    NSInteger initialCluster = MAX(clusterMin, config.clusterIndex);
    YFCellItem *cluster = [YFCellItem stepperItemWithIdentifier:YFEnvItemIdCluster
                                                          title:@"环境编号"
                                                       storeKey:storeKeyForEnvType(kEnvItemStoreCluster, config.envType)
                                                   defaultValue:[NSString stringWithFormat:@"%ld", (long)initialCluster]
                                                        minimum:clusterMin
                                                        maximum:clusterMax];
    cluster.usesStoredValueOnLoad = NO;
    cluster.disabledHint = @"仅 uat/dev 可用";
    cluster.detailTextColor = [UIColor redColor];
    cluster.icon = [UIImage systemImageNamed:@"number.circle"];
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
        if (number < clusterMin || number > clusterMax) {
            return [NSString stringWithFormat:@"环境编号范围为 %ld-%ld", (long)clusterMin, (long)clusterMax];
        }
        return nil;
    };
    cluster.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = @"";
        switch (envTypeValue) {
            case HCEnvTypeRelease:
                newStoreKey = storeKeyForEnvType(kEnvItemStoreCluster, envTypeValue);
                item.enabled = NO;
                item.hidden = YES;
                break;
            case HCEnvTypeCustom:
                newStoreKey = @"";
                item.enabled = YES;
                item.hidden = YES;
                break;
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                newStoreKey = storeKeyForEnvType(kEnvItemStoreCluster, envTypeValue);
                item.enabled = YES;
                item.hidden = NO;
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
        NSInteger current = MAX(clusterMin, YFIntValue(item.value));
        current = MIN(clusterMax, current);
        item.value = [NSString stringWithFormat:@"%ld", (long)current];
        item.detail = item.value;
    };

    // Saas 环境：根据 cluster 自动生成默认值，仍允许手动编辑。
    YFCellItem *saas = [YFCellItem stringItemWithIdentifier:YFEnvItemIdSaas
                                                      title:@"Saas 环境"
                                                   storeKey:storeKeyForEnvType(kEnvItemStoreSaas, config.envType)
                                               defaultValue:[NSString stringWithFormat:@"%@%ld", envSaasPrefixForType(config.envType), (long)initialCluster]];
    saas.usesStoredValueOnLoad = NO;
    saas.disabledHint = @"仅 uat/dev 可用";
    saas.detail = @"随环境编号自动变化";
    saas.icon = [UIImage systemImageNamed:@"shippingbox"];
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
                NSInteger clusterValue = MAX(clusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
                item.value = [NSString stringWithFormat:@"%@%ld", envSaasPrefixForType(envTypeValue), (long)clusterValue];
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
                NSInteger clusterValue = MAX(clusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
                NSString *autoValue = [NSString stringWithFormat:@"%@%ld", envSaasPrefixForType(envTypeValue), (long)clusterValue];
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
    isolation.icon = [UIImage systemImageNamed:@"shield"];
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
    version.icon = [UIImage systemImageNamed:@"tag"];
    version.dependsOn = @[YFEnvItemIdEnvType];
    version.recomputeBlock = ^(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById) {
        YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
        HCEnvType envTypeValue = YFIntValue(envItem.value);
        NSString *newStoreKey = @"";
        switch (envTypeValue) {
            case HCEnvTypeRelease:
                newStoreKey = storeKeyForEnvType(kEnvItemStoreVersion, envTypeValue);
                item.enabled = NO;
                item.hidden = YES;
                break;
            case HCEnvTypeCustom:
                newStoreKey = @"";
                item.enabled = YES;
                item.hidden = YES;
                break;
            case HCEnvTypeUat:
            case HCEnvTypeDev:
                newStoreKey = storeKeyForEnvType(kEnvItemStoreVersion, envTypeValue);
                item.enabled = YES;
                item.hidden = NO;
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
    };

    // Final URL：自定义环境可编辑，其余环境根据配置自动生成。
    NSString *resultValue = config.customBaseURL.length > 0 ? config.customBaseURL : @"";
    YFCellItem *result = [YFCellItem editableInfoItemWithIdentifier:YFEnvItemIdResult
                                                               title:@"环境"
                                                            storeKey:storeKeyForEnvType(kEnvItemStoreResult, config.envType)
                                                        defaultValue:resultValue];
    result.usesStoredValueOnLoad = NO;
    result.icon = [UIImage systemImageNamed:@"globe"];
    NSInteger displayCluster = MAX(clusterMin, YFIntValue(cluster.value));
    displayCluster = MIN(clusterMax, displayCluster);
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
        NSInteger displayCluster = MAX(clusterMin, YFIntValue(itemsById[YFEnvItemIdCluster].value));
        displayCluster = MIN(clusterMax, displayCluster);
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
    save.icon = [UIImage systemImageNamed:@"square.and.arrow.down"];
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

    NSArray<YFCellItem *> *items = @[envType, history, cluster, saas, version, isolation, result, save];
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
        presentCustomHistorySavePrompt(config, strongSections);
        [YFHapticFeedback notificationSuccess];
        [[NSNotificationCenter defaultCenter] postNotificationName:HCTEnvPanelDidSaveNotification object:nil];
    };
}

#pragma mark - Save State Helpers

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

#pragma mark - Config Mapping

+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById {
    NSInteger clusterMin = envClusterMin();
    NSInteger clusterMax = envClusterMax();
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    YFCellItem *envItem = itemsById[YFEnvItemIdEnvType];
    YFCellItem *clusterItem = itemsById[YFEnvItemIdCluster];
    YFCellItem *saasItem = itemsById[YFEnvItemIdSaas];
    YFCellItem *isolationItem = itemsById[YFEnvItemIdIsolation];
    YFCellItem *versionItem = itemsById[YFEnvItemIdVersion];
    YFCellItem *resultItem = itemsById[YFEnvItemIdResult];

    config.envType = YFIntValue(envItem.value);
    NSInteger clusterValue = MAX(clusterMin, YFIntValue(clusterItem.value));
    clusterValue = MIN(clusterMax, clusterValue);
    config.clusterIndex = clusterValue;
    config.isolation = [isolationItem.value isKindOfClass:[NSString class]] ? isolationItem.value : @"";
    config.saas = [saasItem.value isKindOfClass:[NSString class]] ? saasItem.value : @"";
    config.version = [versionItem.value isKindOfClass:[NSString class]] ? versionItem.value : @"";
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
