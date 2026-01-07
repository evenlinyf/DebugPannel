#import "HCEnvPanelViewModel.h"
#import "HCEnvSection.h"
#import "HCCellItem.h"
#import "HCEnvKit.h"
#import "HCEnvBuilder.h"
#import "DependencyEngine.h"
#import "HCPresentationRequest.h"

@interface HCEnvPanelViewModel ()

@property (nonatomic, copy) NSArray<HCEnvSection *> *sections;
@property (nonatomic, strong) DependencyEngine *dependencyEngine;
@property (nonatomic, strong) NSDictionary<NSString *, NSIndexPath *> *indexMap;

@end

@implementation HCEnvPanelViewModel

- (instancetype)init {
    if (self = [super init]) {
        HCEnvSection *envSection = [HCEnvBuilder buildEnvSection];
        _sections = @[envSection];
        [self loadPersistedValues];
        [self rebuildIndexMap];
        [self rebuildDependencyEngine];
        [self refreshAllItems];
    }
    return self;
}

- (void)loadPersistedValues {
    for (HCEnvSection *section in self.sections) {
        for (HCCellItem *item in section.items) {
            if (item.storeKey.length == 0) {
                continue;
            }
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:item.storeKey];
            if (stored) {
                item.value = stored;
            } else if (item.defaultValue) {
                item.value = item.defaultValue;
            }
            if (item.type == HCCellItemTypeString || item.type == HCCellItemTypeStepper) {
                item.detail = [item.value description];
            }
        }
    }
}

- (void)rebuildDependencyEngine {
    NSMutableArray<HCCellItem *> *items = [NSMutableArray array];
    for (HCEnvSection *section in self.sections) {
        [items addObjectsFromArray:section.items];
    }
    self.dependencyEngine = [[DependencyEngine alloc] initWithItems:items];
}

- (void)refreshAllItems {
    NSDictionary<NSString *, HCCellItem *> *itemsById = self.dependencyEngine.itemsById;
    for (HCEnvSection *section in self.sections) {
        for (HCCellItem *item in section.items) {
            if (item.recomputeBlock) {
                item.recomputeBlock(item, itemsById);
            }
        }
    }
}

- (void)rebuildIndexMap {
    NSMutableDictionary<NSString *, NSIndexPath *> *map = [NSMutableDictionary dictionary];
    [self.sections enumerateObjectsUsingBlock:^(HCEnvSection * _Nonnull section, NSUInteger sectionIndex, BOOL * _Nonnull stop) {
        [section.items enumerateObjectsUsingBlock:^(HCCellItem * _Nonnull item, NSUInteger rowIndex, BOOL * _Nonnull stopRow) {
            if (item.identifier.length > 0) {
                map[item.identifier] = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            }
        }];
    }];
    self.indexMap = [map copy];
}

- (HCCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    HCEnvSection *section = self.sections[indexPath.section];
    return section.items[indexPath.row];
}

- (NSArray<NSIndexPath *> *)updateItem:(HCCellItem *)item value:(id)value {
    if (!item) {
        return @[];
    }
    item.value = value;
    if (item.type == HCCellItemTypeString || item.type == HCCellItemTypeStepper) {
        item.detail = [value description];
    }
    if (item.valueTransformer) {
        item.valueTransformer(item);
    }

    NSMutableSet<NSString *> *changed = [NSMutableSet setWithObject:item.identifier];
    if (item.identifier.length > 0) {
        NSSet<NSString *> *propagated = [self.dependencyEngine propagateFromItemId:item.identifier];
        [changed unionSet:propagated];
    }

    [self persistIfNeededForItem:item];
    [self persistEnvConfig];

    NSMutableArray<NSIndexPath *> *paths = [NSMutableArray array];
    for (NSString *itemId in changed) {
        NSIndexPath *indexPath = self.indexMap[itemId];
        if (indexPath) {
            [paths addObject:indexPath];
        }
    }
    return [paths copy];
}

- (void)persistIfNeededForItem:(HCCellItem *)item {
    if (item.storeKey.length == 0) {
        return;
    }
    if (!item.value) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:item.storeKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:item.value forKey:item.storeKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)persistEnvConfig {
    NSDictionary<NSString *, HCCellItem *> *itemsById = self.dependencyEngine.itemsById;
    HCCellItem *envItem = itemsById[HCEnvItemIdEnvType];
    HCCellItem *clusterItem = itemsById[HCEnvItemIdCluster];
    HCCellItem *isolationItem = itemsById[HCEnvItemIdIsolation];
    HCCellItem *versionItem = itemsById[HCEnvItemIdVersion];
    if (!envItem || !clusterItem || !isolationItem || !versionItem) {
        return;
    }

    HCEnvConfig *config = [[HCEnvConfig alloc] init];
    config.envType = (HCEnvType)[envItem.value integerValue];
    config.clusterIndex = [clusterItem.value integerValue];
    config.isolation = isolationItem.value ?: @"";
    config.version = versionItem.value ?: @"v1";
    [HCEnvKit saveConfig:config];
}

- (HCPresentationRequest *)presentationForDisabledItem:(HCCellItem *)item {
    if (item.disabledHint.length == 0) {
        return [HCPresentationRequest toastWithMessage:@"当前不可用"];
    }
    return [HCPresentationRequest toastWithMessage:item.disabledHint];
}

@end
