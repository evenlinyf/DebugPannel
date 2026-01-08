#import "HCEnvPanelViewModel.h"
#import "HCEnvBuilder.h"
#import "HCEnvKit.h"
#import "HCCellItem.h"
#import "HCEnvSection.h"
#import "HCPresentationRequest.h"
#import "DependencyEngine.h"
#import "HCValueHelpers.h"
#import <UIKit/UIKit.h>

/// 创建时间：2025/03/01
/// 创建人：Codex
/// 用途：环境面板 ViewModel 的私有状态。
@interface HCEnvPanelViewModel ()
/// 内部持有的 section 列表（可写）。
@property (nonatomic, copy) NSArray<HCEnvSection *> *sections;
/// 依赖引擎，用于触发联动刷新。
@property (nonatomic, strong) DependencyEngine *dependencyEngine;
/// itemId 到 indexPath 的缓存映射。
@property (nonatomic, copy) NSDictionary<NSString *, NSIndexPath *> *indexMap;
@end

@implementation HCEnvPanelViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        HCEnvSection *envSection = [HCEnvBuilder buildEnvSection];
        HCEnvSection *configSection = [HCEnvBuilder buildConfigSeciton];
        _sections = @[envSection, configSection];
        _dependencyEngine = [[DependencyEngine alloc] initWithItems:envSection.items];
        _indexMap = @{};
        [self loadPersistedValues];
        [self rebuildIndexMap];
        [self rebuildDependencyEngine];
        [self refreshAllItems];
    }
    return self;
}

- (HCCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    HCEnvSection *section = self.sections[indexPath.section];
    return section.items[indexPath.row];
}

- (NSArray<NSIndexPath *> *)updateItem:(HCCellItem *)item value:(id)value {
    item.value = value;
    if (item.type == HCCellItemTypeString || item.type == HCCellItemTypeStepper) {
        item.detail = value ? [NSString stringWithFormat:@"%@", value] : nil;
    }
    if (item.valueTransformer) {
        item.valueTransformer(item);
    }

    NSMutableSet<NSString *> *changed = [NSMutableSet set];
    if (item.identifier.length > 0) {
        [changed addObject:item.identifier];
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

- (HCPresentationRequest *)presentationForDisabledItem:(HCCellItem *)item {
    if (item.disabledHint.length > 0) {
        return [HCPresentationRequest toastWithMessage:item.disabledHint];
    }
    return [HCPresentationRequest toastWithMessage:@"当前不可用"];
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
                item.detail = item.value ? [NSString stringWithFormat:@"%@", item.value] : nil;
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
    [self.sections enumerateObjectsUsingBlock:^(HCEnvSection *section, NSUInteger sectionIndex, BOOL *stop) {
        [section.items enumerateObjectsUsingBlock:^(HCCellItem *item, NSUInteger rowIndex, BOOL *stopRow) {
            if (item.identifier.length > 0) {
                map[item.identifier] = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            }
        }];
    }];
    self.indexMap = [map copy];
}

- (void)persistIfNeededForItem:(HCCellItem *)item {
    if (item.storeKey.length == 0) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (item.value) {
        [defaults setObject:item.value forKey:item.storeKey];
    } else {
        [defaults removeObjectForKey:item.storeKey];
    }
    [defaults synchronize];
}

- (void)persistEnvConfig {
    NSDictionary<NSString *, HCCellItem *> *itemsById = self.dependencyEngine.itemsById;
    if (itemsById.count == 0) {
        return;
    }

    HCEnvConfig *config = [HCEnvBuilder configFromItems:itemsById];
    [HCEnvKit saveConfig:config];
}

@end
