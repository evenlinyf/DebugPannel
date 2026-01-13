/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 Builder 实现。
#import "HCEnvPanelBuilder.h"

#import "HCEnvKit.h"
#import "HCEnvPanelViewController.h"
#import "HCEnvSection.h"
#import "HCCellItem.h"
#import "HCValueHelpers.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NSString *const HCEnvItemIdEnvType = @"env.type";
NSString *const HCEnvItemIdCluster = @"env.cluster";
NSString *const HCEnvItemIdSaas = @"env.saas";
NSString *const HCEnvItemIdIsolation = @"env.isolation";
NSString *const HCEnvItemIdVersion = @"env.version";
NSString *const HCEnvItemIdResult = @"env.result";
NSString *const HCEnvItemIdElb = @"config.elb";
NSString *const HCEnvItemIdSave = @"env.save";
NSNotificationName const HCEnvPanelDidSaveNotification = @"HCEnvPanelDidSaveNotification";

static NSString *const kEnvItemStoreIsolation = @"HCEnvKit.isolation";
static NSString *const kEnvItemStoreVersion = @"HCEnvKit.version";
static NSString *const kEnvItemStoreCluster = @"HCEnvKit.cluster";
static NSString *const kEnvItemStoreSaas = @"HCEnvKit.saas";
static NSString *const kEnvItemStoreResult = @"HCEnvKit.result";
static NSInteger const kEnvClusterMin = 1;
static NSInteger const kEnvClusterMax = 20;
static NSString *const kEnvSaasPrefix = @"hpc-uat-";
static const void *kHCEnvPanelExitObserverKey = &kHCEnvPanelExitObserverKey;
static const void *kHCEnvPanelSnapshotKey = &kHCEnvPanelSnapshotKey;

@interface HCEnvPanelChangeSnapshot ()
@property (nonatomic, strong) HCEnvConfig *config;
@property (nonatomic, copy) NSDictionary<NSString *, id> *storeValues;
@end

@implementation HCEnvPanelChangeSnapshot

- (instancetype)initWithConfig:(HCEnvConfig *)config storeValues:(NSDictionary<NSString *, id> *)storeValues {
    self = [super init];
    if (self) {
        _config = [config copy];
        _storeValues = [storeValues copy];
    }
    return self;
}

@end

static UIWindow *activeWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    for (UIScene *scene in application.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (scene.activationState != UISceneActivationStateForegroundActive) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    if (application.keyWindow) {
        return application.keyWindow;
    }
    return application.windows.firstObject;
}

static UIViewController *topViewController(void) {
    UIWindow *window = activeWindow();
    UIViewController *top = window.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

@interface HCEnvPanelExitObserver : NSObject
@property (nonatomic, strong) HCEnvConfig *initialConfig;
@end

@implementation HCEnvPanelExitObserver

- (instancetype)initWithInitialConfig:(HCEnvConfig *)initialConfig {
    self = [super init];
    if (self) {
        _initialConfig = [initialConfig copy];
    }
    return self;
}

- (void)dealloc {
    HCEnvConfig *currentConfig = [HCEnvKit currentConfig];
    if ([self.initialConfig isEqual:currentConfig]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = topViewController();
        if (!presenter) {
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                       message:@"环境已变更，重启 App 后生效"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

@end

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

static BOOL isEnvConfigIdentifier(NSString *identifier) {
    if (identifier.length == 0) {
        return NO;
    }
    static NSSet<NSString *> *envConfigIdentifiers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        envConfigIdentifiers = [NSSet setWithArray:@[
            HCEnvItemIdEnvType,
            HCEnvItemIdCluster,
            HCEnvItemIdIsolation,
            HCEnvItemIdVersion,
            HCEnvItemIdResult
        ]];
    });
    return [envConfigIdentifiers containsObject:identifier];
}

static HCCellItem *saveItemFromSections(NSArray<HCEnvSection *> *sections) {
    NSDictionary<NSString *, HCCellItem *> *itemsById = [HCEnvPanelBuilder indexItemsByIdFromSections:sections];
    return itemsById[HCEnvItemIdSave];
}

static HCEnvPanelChangeSnapshot *snapshotForSections(NSArray<HCEnvSection *> *sections) {
    return objc_getAssociatedObject(sections, kHCEnvPanelSnapshotKey);
}

static void setSnapshotForSections(NSArray<HCEnvSection *> *sections, HCEnvPanelChangeSnapshot *snapshot) {
    objc_setAssociatedObject(sections, kHCEnvPanelSnapshotKey, snapshot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void persistAllItemsInSections(NSArray<HCEnvSection *> *sections) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (HCEnvSection *section in sections) {
        for (HCCellItem *item in section.items) {
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

@implementation HCEnvPanelBuilder

+ (NSArray<HCEnvSection *> *)buildSections {
    HCEnvSection *envSection = [self buildEnvSection];
    HCEnvSection *configSection = [self buildConfigSection];
    return @[envSection, configSection];
}

+ (UIViewController *)buildPanelViewController {
    HCEnvPanelViewController *controller = [[HCEnvPanelViewController alloc] init];
    HCEnvPanelExitObserver *observer = [[HCEnvPanelExitObserver alloc] initWithInitialConfig:[HCEnvKit currentConfig]];
    objc_setAssociatedObject(controller, kHCEnvPanelExitObserverKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return controller;
}

+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSections:(NSArray<HCEnvSection *> *)sections {
    NSMutableDictionary<NSString *, HCCellItem *> *itemsById = [NSMutableDictionary dictionary];
    for (HCEnvSection *section in sections) {
        for (HCCellItem *item in section.items) {
            if (item.identifier.length > 0) {
                itemsById[item.identifier] = item;
            }
        }
    }
    return [itemsById copy];
}

+ (void)refreshSections:(NSArray<HCEnvSection *> *)sections {
    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    for (HCEnvSection *section in sections) {
        for (HCCellItem *item in section.items) {
            if (item.recomputeBlock) {
                item.recomputeBlock(item, itemsById);
            }
        }
    }
}

+ (HCEnvConfig *)configFromSections:(NSArray<HCEnvSection *> *)sections {
    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    return [self configFromItems:itemsById];
}

+ (HCEnvPanelChangeSnapshot *)changeSnapshotFromSections:(NSArray<HCEnvSection *> *)sections {
    HCEnvConfig *config = [self configFromSections:sections];
    NSMutableDictionary<NSString *, id> *values = [NSMutableDictionary dictionary];
    for (HCEnvSection *section in sections) {
        for (HCCellItem *item in section.items) {
            if (item.storeKey.length == 0 || isEnvConfigIdentifier(item.identifier)) {
                continue;
            }
            if (item.identifier.length == 0) {
                continue;
            }
            values[item.identifier] = item.value ?: [NSNull null];
        }
    }
    return [[HCEnvPanelChangeSnapshot alloc] initWithConfig:config storeValues:values];
}

+ (BOOL)sections:(NSArray<HCEnvSection *> *)sections differFromSnapshot:(HCEnvPanelChangeSnapshot *)snapshot {
    if (!snapshot) {
        return NO;
    }
    HCEnvConfig *currentConfig = [self configFromSections:sections];
    if (![currentConfig isEqual:snapshot.config]) {
        return YES;
    }
    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    for (NSString *identifier in snapshot.storeValues) {
        HCCellItem *item = itemsById[identifier];
        if (!item) {
            continue;
        }
        id baseline = snapshot.storeValues[identifier] ?: [NSNull null];
        id current = item.value ?: [NSNull null];
        if (![baseline isEqual:current]) {
            return YES;
        }
    }
    return NO;
}

+ (void)configureSaveActionForSections:(NSArray<HCEnvSection *> *)sections onSave:(dispatch_block_t)onSave {
    HCCellItem *saveItem = saveItemFromSections(sections);
    if (!saveItem) {
        return;
    }
    __weak NSArray<HCEnvSection *> *weakSections = sections;
    saveItem.actionHandler = ^(HCCellItem *item) {
        NSArray<HCEnvSection *> *strongSections = weakSections;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:HCEnvPanelDidSaveNotification object:nil];
    };
}

+ (void)updateSaveItemVisibilityInSections:(NSArray<HCEnvSection *> *)sections {
    HCCellItem *saveItem = saveItemFromSections(sections);
    if (!saveItem) {
        return;
    }
    BOOL pending = [self sections:sections differFromSnapshot:snapshotForSections(sections)];
    saveItem.hidden = !pending;
    saveItem.enabled = pending;
}

+ (void)captureBaselineForSections:(NSArray<HCEnvSection *> *)sections {
    HCEnvPanelChangeSnapshot *snapshot = [self changeSnapshotFromSections:sections];
    setSnapshotForSections(sections, snapshot);
}

/// 如何新增配置项（重要）：
/// 1. 在本文件顶部新增常量标识（如 HCEnvItemIdXXX）与持久化 key（如 kEnvItemStoreXXX）。
/// 2. 在 buildEnvSection 中创建 HCCellItem，补充 title、type、storeKey/defaultValue、dependsOn 和 recomputeBlock。
/// 3. 在 configFromItems 中读取新字段，映射到 HCEnvConfig 属性，并在 HCEnvKit 中持久化该属性。
/// 4. 如需影响联动显示，确保将新项加入 result 的 dependsOn 列表，并在 recomputeBlock 中刷新 detail/title。
+ (HCEnvSection *)buildEnvSection {
    HCEnvConfig *config = [HCEnvKit currentConfig];

    // 环境类型：用 segment 统一管理。
    NSArray<NSString *> *envOptions = @[@"线上", @"uat", @"dev", @"自定义"];
    HCCellItem *envType = [HCCellItem segmentItemWithIdentifier:HCEnvItemIdEnvType
                                                          title:@"环境类型"
                                                        options:envOptions
                                                   defaultValue:@(config.envType)];
    envType.value = @(config.envType);

    // 环境编号：需要根据 envType 切换持久化 key。
    HCCellItem *cluster = [HCCellItem stepperItemWithIdentifier:HCEnvItemIdCluster title:@"环境编号" storeKey:storeKeyForEnvType(kEnvItemStoreCluster, config.envType) defaultValue:[NSString stringWithFormat:@"%ld", (long)kEnvClusterMin] minimum:1 maximum:20];
    NSInteger initialCluster = MAX(kEnvClusterMin, config.clusterIndex);
    cluster.value = [NSString stringWithFormat:@"%ld", (long)initialCluster];
    cluster.disabledHint = @"仅 uat/dev 可用";
    cluster.dependsOn = @[HCEnvItemIdEnvType];
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
    cluster.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreCluster, envTypeValue);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            item.value = stored ?: item.defaultValue;
        }
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.hidden = (envTypeValue == HCEnvTypeRelease || envTypeValue == HCEnvTypeCustom);
        NSInteger current = MAX(kEnvClusterMin, HCIntValue(item.value));
        current = MIN(kEnvClusterMax, current);
        item.value = [NSString stringWithFormat:@"%ld", (long)current];
        item.detail = item.value;
    };

    // Saas 环境：根据 cluster 自动生成默认值，仍允许手动编辑。
    HCCellItem *saas = [HCCellItem stringItemWithIdentifier:HCEnvItemIdSaas
                                                      title:@"Saas 环境"
                                                   storeKey:storeKeyForEnvType(kEnvItemStoreSaas, config.envType)
                                               defaultValue:nil];
    saas.value = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)initialCluster];
    saas.disabledHint = @"仅 uat/dev 可用";
    saas.dependsOn = @[HCEnvItemIdEnvType, HCEnvItemIdCluster];
    saas.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
        NSString *newStoreKey = storeKeyForEnvType(kEnvItemStoreSaas, envTypeValue);
        BOOL storeKeyChanged = ![item.storeKey isEqualToString:newStoreKey];
        item.storeKey = newStoreKey;
        if (storeKeyChanged) {
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:newStoreKey];
            if (stored) {
                item.value = stored;
            } else {
                NSInteger clusterValue = MAX(kEnvClusterMin, HCIntValue(itemsById[HCEnvItemIdCluster].value));
                item.value = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)clusterValue];
            }
        }
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.hidden = (envTypeValue == HCEnvTypeRelease);
        NSInteger clusterValue = MAX(kEnvClusterMin, HCIntValue(itemsById[HCEnvItemIdCluster].value));
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
    HCCellItem *isolation = [HCCellItem stringItemWithIdentifier:HCEnvItemIdIsolation
                                                           title:@"隔离参数"
                                                        storeKey:storeKeyForEnvType(kEnvItemStoreIsolation, config.envType)
                                                    defaultValue:@""];
    isolation.value = config.isolation;
    isolation.disabledHint = @"仅 uat/dev 可用";
    isolation.dependsOn = @[HCEnvItemIdEnvType];
    isolation.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
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
    HCCellItem *version = [HCCellItem stringItemWithIdentifier:HCEnvItemIdVersion
                                                         title:@"版本号"
                                                      storeKey:storeKeyForEnvType(kEnvItemStoreVersion, config.envType)
                                                  defaultValue:@"v1"];
    version.value = config.version;
    version.disabledHint = @"仅 uat/dev 可用";
    version.dependsOn = @[HCEnvItemIdEnvType];
    version.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
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
    HCCellItem *result = [HCCellItem editableInfoItemWithIdentifier:HCEnvItemIdResult
                                                               title:@"Final URL"
                                                            storeKey:storeKeyForEnvType(kEnvItemStoreResult, config.envType)
                                                        defaultValue:@""];
    result.value = config.customBaseURL.length > 0 ? config.customBaseURL : @"";
    result.detail = [result.value isKindOfClass:[NSString class]] ? result.value : @"";
    result.dependsOn = @[HCEnvItemIdEnvType, HCEnvItemIdCluster, HCEnvItemIdVersion, HCEnvItemIdIsolation];
    result.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
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
        item.title = @"Final URL";
        item.hidden = isRelease;
        item.detail = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
    };

    HCCellItem *save = [HCCellItem actionItemWithIdentifier:HCEnvItemIdSave title:@"保存" handler:nil];
    save.hidden = YES;
    save.dependsOn = @[HCEnvItemIdEnvType, HCEnvItemIdCluster, HCEnvItemIdIsolation, HCEnvItemIdVersion, HCEnvItemIdResult];

    NSArray<HCCellItem *> *items = @[envType, cluster, saas, isolation, version, result, save];
    HCEnvSection *section = [HCEnvSection sectionWithTitle:@"环境配置" items:items];

    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSections:@[section]];
    for (HCCellItem *item in items) {
        if (item.recomputeBlock) {
            item.recomputeBlock(item, itemsById);
        }
    }

    return section;
}

+ (HCEnvSection *)buildConfigSection {
    // ELB 开关：常规布尔持久化配置项。
    HCCellItem *elb = [HCCellItem switchItemWithIdentifier:HCEnvItemIdElb
                                                     title:@"ELB 开关"
                                                  storeKey:@"elbconfig"
                                              defaultValue:@(YES)];
    elb.detail = @"如果不需要获取动态域名， 请关闭开关";

    NSArray<HCCellItem *> *items = @[elb];
    return [HCEnvSection sectionWithTitle:@"配置" items:items];
}

+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, HCCellItem *> *)itemsById {
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
    HCCellItem *clusterItem = itemsById[HCEnvItemIdCluster];
    HCCellItem *isolationItem = itemsById[HCEnvItemIdIsolation];
    HCCellItem *versionItem = itemsById[HCEnvItemIdVersion];
    HCCellItem *resultItem = itemsById[HCEnvItemIdResult];
    config.envType = HCIntValue(envItem.value);
    NSInteger clusterValue = MAX(kEnvClusterMin, HCIntValue(clusterItem.value));
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
