#import "HCEnvBuilder.h"
#import "HCEnvSection.h"
#import "HCCellItem.h"
#import "HCEnvKit.h"

NSString * const HCEnvItemIdEnvType = @"env.type";
NSString * const HCEnvItemIdCluster = @"env.cluster";
NSString * const HCEnvItemIdIsolation = @"env.isolation";
NSString * const HCEnvItemIdVersion = @"env.version";
NSString * const HCEnvItemIdResult = @"env.result";

static NSString * const HCEnvItemStoreIsolation = @"HCEnvKit.isolation";
static NSString * const HCEnvItemStoreVersion = @"HCEnvKit.version";
static NSString * const HCEnvItemStoreCluster = @"HCEnvKit.cluster";
static NSInteger const HCEnvClusterMin = 1;
static NSInteger const HCEnvClusterMax = 5;

static HCEnvConfig *HCConfigFromItems(NSDictionary<NSString *, HCCellItem *> *itemsById) {
    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
    HCCellItem *clusterItem = itemsById[HCEnvItemIdCluster];
    HCCellItem *isolationItem = itemsById[HCEnvItemIdIsolation];
    HCCellItem *versionItem = itemsById[HCEnvItemIdVersion];
    config.envType = (HCEnvType)[envItem.value integerValue];
    config.clusterIndex = MAX(HCEnvClusterMin, [clusterItem.value integerValue]);
    config.isolation = isolationItem.value ?: @"";
    config.version = versionItem.value ?: @"v1";
    return config;
}

@implementation HCEnvBuilder

+ (HCEnvSection *)buildEnvSection {
    HCEnvConfig *config = [HCEnvKit currentConfig];

    HCCellItem *envType = [HCCellItem itemWithIdentifier:HCEnvItemIdEnvType title:@"环境类型" type:HCCellItemTypeSegment];
    envType.options = @[@"线上", @"uat", @"dev"];
    envType.value = @(config.envType);

    HCCellItem *cluster = [HCCellItem itemWithIdentifier:HCEnvItemIdCluster title:@"环境编号" type:HCCellItemTypeStepper];
    cluster.storeKey = HCEnvItemStoreCluster;
    cluster.defaultValue = @(1);
    cluster.value = @(MAX(HCEnvClusterMin, config.clusterIndex));
    cluster.detail = [NSString stringWithFormat:@"%ld", (long)[cluster.value integerValue]];
    cluster.disabledHint = @"仅 uat/dev 可用";
    cluster.dependsOn = @[HCEnvItemIdEnvType];
    cluster.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *,HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = (HCEnvType)[envItem.value integerValue];
        item.enabled = envTypeValue != HCEnvTypeRelease;
        NSInteger current = MAX(HCEnvClusterMin, [item.value integerValue]);
        current = MIN(HCEnvClusterMax, current);
        item.value = @(current);
        item.detail = [NSString stringWithFormat:@"%ld", (long)current];
    };

    HCCellItem *isolation = [HCCellItem itemWithIdentifier:HCEnvItemIdIsolation title:@"隔离参数" type:HCCellItemTypeString];
    isolation.storeKey = HCEnvItemStoreIsolation;
    isolation.defaultValue = @"";
    isolation.value = config.isolation ?: @"";
    isolation.detail = isolation.value;
    isolation.disabledHint = @"仅 uat/dev 可用";
    isolation.dependsOn = @[HCEnvItemIdEnvType];
    isolation.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *,HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = (HCEnvType)[envItem.value integerValue];
        item.enabled = envTypeValue != HCEnvTypeRelease;
        item.detail = item.value;
    };

    HCCellItem *version = [HCCellItem itemWithIdentifier:HCEnvItemIdVersion title:@"版本号" type:HCCellItemTypeString];
    version.storeKey = HCEnvItemStoreVersion;
    version.defaultValue = @"v1";
    version.value = config.version ?: @"v1";
    version.detail = version.value;
    version.disabledHint = @"仅 uat/dev 可用";
    version.dependsOn = @[HCEnvItemIdEnvType];
    version.validator = ^BOOL(NSString *input, NSString *__autoreleasing  _Nullable * _Nullable errorMessage) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^v\\d+$" options:0 error:nil];
        NSUInteger matches = [regex numberOfMatchesInString:input options:0 range:NSMakeRange(0, input.length)];
        if (matches == 0) {
            if (errorMessage) {
                *errorMessage = @"版本号格式必须为 v+数字";
            }
            return NO;
        }
        return YES;
    };
    version.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *,HCCellItem *> *itemsById) {
        HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
        HCEnvType envTypeValue = (HCEnvType)[envItem.value integerValue];
        item.enabled = envTypeValue != HCEnvTypeRelease;
        item.detail = item.value;
    };

    HCCellItem *result = [HCCellItem itemWithIdentifier:HCEnvItemIdResult title:@"生效结果" type:HCCellItemTypeInfo];
    result.desc = @"";
    result.detail = @"";
    result.dependsOn = @[HCEnvItemIdEnvType, HCEnvItemIdCluster, HCEnvItemIdVersion, HCEnvItemIdIsolation];
    result.recomputeBlock = ^(HCCellItem *item, NSDictionary<NSString *,HCCellItem *> *itemsById) {
        HCEnvConfig *config = HCConfigFromItems(itemsById);
        HCEnvBuildResult *build = [HCEnvKit buildResult:config];
        item.detail = build.displayName;
        item.desc = build.baseURL;
    };

    NSArray<HCCellItem *> *items = @[envType, cluster, isolation, version, result];
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

@end
