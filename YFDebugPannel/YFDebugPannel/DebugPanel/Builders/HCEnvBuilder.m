#import "HCEnvBuilder.h"
#import "HCEnvKit.h"
#import "HCCellItem.h"
#import "HCEnvSection.h"
#import "HCValueHelpers.h"

NSString *const HCEnvItemIdEnvType = @"env.type";
NSString *const HCEnvItemIdCluster = @"env.cluster";
NSString *const HCEnvItemIdSaas = @"env.saas";
NSString *const HCEnvItemIdIsolation = @"env.isolation";
NSString *const HCEnvItemIdVersion = @"env.version";
NSString *const HCEnvItemIdResult = @"env.result";
NSString *const HCEnvItemIdElb = @"config.elb";

static NSString *const kEnvItemStoreIsolation = @"HCEnvKit.isolation";
static NSString *const kEnvItemStoreVersion = @"HCEnvKit.version";
static NSString *const kEnvItemStoreCluster = @"HCEnvKit.cluster";
static NSString *const kEnvItemStoreSaas = @"HCEnvKit.saas";
static NSInteger const kEnvClusterMin = 1;
static NSInteger const kEnvClusterMax = 20;
static NSString *const kEnvSaasPrefix = @"hpc-uat-";

static HCEnvConfig *configFromItems(NSDictionary<NSString *, HCCellItem *> *itemsById) {
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
    HCCellItem *clusterItem = itemsById[HCEnvItemIdCluster];
    HCCellItem *isolationItem = itemsById[HCEnvItemIdIsolation];
    HCCellItem *versionItem = itemsById[HCEnvItemIdVersion];
    config.envType = HCIntValue(envItem.value);
    config.clusterIndex = MAX(kEnvClusterMin, HCIntValue(clusterItem.value));
    config.isolation = [isolationItem.value isKindOfClass:[NSString class]] ? isolationItem.value : @"";
    config.version = [versionItem.value isKindOfClass:[NSString class]] ? versionItem.value : @"v1";
    return config;
}

@implementation HCEnvBuilder

+ (HCEnvSection *)buildEnvSection {
    HCEnvConfig *config = [HCEnvKit currentConfig];

    HCCellItem *envType = [HCCellItem itemWithIdentifier:HCEnvItemIdEnvType title:@"环境类型" type:HCCellItemTypeSegment];
    envType.options = @[@"线上", @"uat", @"dev"];
    envType.value = @(config.envType);

    HCCellItem *cluster = [HCCellItem itemWithIdentifier:HCEnvItemIdCluster title:@"环境编号" type:HCCellItemTypeStepper];
    cluster.storeKey = kEnvItemStoreCluster;
    cluster.defaultValue = @(1);
    NSInteger initialCluster = MAX(kEnvClusterMin, config.clusterIndex);
    cluster.value = @(initialCluster);
    cluster.detail = [NSString stringWithFormat:@"%ld", (long)initialCluster];
    cluster.disabledHint = @"仅 uat/dev 可用";
    cluster.dependsOn = @[HCEnvItemIdEnvType];
    cluster.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        NSInteger current = MAX(kEnvClusterMin, HCIntValue(item.value));
        current = MIN(kEnvClusterMax, current);
        item.value = @(current);
        item.detail = [NSString stringWithFormat:@"%ld", (long)current];
    };

    HCCellItem *saas = [HCCellItem itemWithIdentifier:HCEnvItemIdSaas title:@"Saas 环境" type:HCCellItemTypeString];
    saas.storeKey = kEnvItemStoreSaas;
    saas.value = [NSString stringWithFormat:@"%@%ld", kEnvSaasPrefix, (long)initialCluster];
    saas.detail = saas.value;
    saas.disabledHint = @"仅 uat/dev 可用";
    saas.dependsOn = @[HCEnvItemIdEnvType, HCEnvItemIdCluster];
    saas.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
        item.enabled = (envTypeValue != HCEnvTypeRelease);
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
        item.detail = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
    };

    HCCellItem *isolation = [HCCellItem itemWithIdentifier:HCEnvItemIdIsolation title:@"隔离参数" type:HCCellItemTypeString];
    isolation.storeKey = kEnvItemStoreIsolation;
    isolation.defaultValue = @"";
    isolation.value = config.isolation;
    isolation.detail = config.isolation;
    isolation.disabledHint = @"仅 uat/dev 可用";
    isolation.dependsOn = @[HCEnvItemIdEnvType];
    isolation.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.detail = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
    };

    HCCellItem *version = [HCCellItem itemWithIdentifier:HCEnvItemIdVersion title:@"版本号" type:HCCellItemTypeString];
    version.storeKey = kEnvItemStoreVersion;
    version.defaultValue = @"v1";
    version.value = config.version;
    version.detail = config.version;
    version.disabledHint = @"仅 uat/dev 可用";
    version.dependsOn = @[HCEnvItemIdEnvType];
    version.validator = ^NSString *(NSString *input) {
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^v\\d+$" options:0 error:nil];
        NSInteger matches = [regex numberOfMatchesInString:input options:0 range:NSMakeRange(0, input.length)];
        return matches == 0 ? @"版本号格式必须为 v+数字" : nil;
    };
    version.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = HCIntValue(envItem.value);
        item.enabled = (envTypeValue != HCEnvTypeRelease);
        item.detail = [item.value isKindOfClass:[NSString class]] ? item.value : @"";
    };

    HCCellItem *result = [HCCellItem itemWithIdentifier:HCEnvItemIdResult title:@"生效结果" type:HCCellItemTypeInfo];
    result.desc = @"";
    result.detail = @"";
    result.dependsOn = @[HCEnvItemIdEnvType, HCEnvItemIdCluster, HCEnvItemIdVersion, HCEnvItemIdIsolation];
    result.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById) {
        HCEnvConfig *config = configFromItems(itemsById);
        HCEnvBuildResult *build = [HCEnvKit buildResult:config];
        item.detail = build.displayName;
        item.desc = build.baseURL;
    };

    NSArray<HCCellItem *> *items = @[envType, cluster, saas, isolation, version, result];
    HCEnvSection *section = [HCEnvSection sectionWithTitle:@"环境配置" items:items];

    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSection:section];
    for (HCCellItem *item in items) {
        if (item.recomputeBlock) {
            item.recomputeBlock(item, itemsById);
        }
    }

    return section;
}

+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSection:(HCEnvSection *)section {
    NSMutableDictionary<NSString *, HCCellItem *> *itemsById = [NSMutableDictionary dictionary];
    for (HCCellItem *item in section.items) {
        if (item.identifier.length > 0) {
            itemsById[item.identifier] = item;
        }
    }
    return [itemsById copy];
}

+ (HCEnvSection *)buildConfigSeciton {
    HCCellItem *elb = [HCCellItem itemWithIdentifier:HCEnvItemIdElb title:@"ELB 开关" type:HCCellItemTypeToggle];
    elb.storeKey = @"elbconfig";
    elb.defaultValue = @(YES);
    elb.detail = @"如果不需要获取动态域名， 请关闭开关";

    NSArray<HCCellItem *> *items = @[elb];
    return [HCEnvSection sectionWithTitle:@"配置" items:items];
}

@end
