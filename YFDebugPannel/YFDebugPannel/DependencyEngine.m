#import "DependencyEngine.h"
#import "HCCellItem.h"

@interface DependencyEngine ()

@property (nonatomic, strong) NSDictionary<NSString *, HCCellItem *> *itemsById;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSString *> *> *reverseDeps;

@end

@implementation DependencyEngine

- (instancetype)initWithItems:(NSArray<HCCellItem *> *)items {
    if (self = [super init]) {
        NSMutableDictionary<NSString *, HCCellItem *> *itemsById = [NSMutableDictionary dictionary];
        NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *reverseDeps = [NSMutableDictionary dictionary];
        for (HCCellItem *item in items) {
            if (item.identifier.length > 0) {
                itemsById[item.identifier] = item;
            }
        }
        for (HCCellItem *item in items) {
            for (NSString *depId in item.dependsOn ?: @[]) {
                NSMutableArray<NSString *> *list = reverseDeps[depId];
                if (!list) {
                    list = [NSMutableArray array];
                    reverseDeps[depId] = list;
                }
                [list addObject:item.identifier];
            }
        }
        NSMutableDictionary<NSString *, NSArray<NSString *> *> *finalReverse = [NSMutableDictionary dictionary];
        [reverseDeps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<NSString *> * _Nonnull obj, BOOL * _Nonnull stop) {
            finalReverse[key] = [obj copy];
        }];
        _itemsById = [itemsById copy];
        _reverseDeps = [finalReverse copy];
    }
    return self;
}

static BOOL HCValueEqual(id lhs, id rhs) {
    if (lhs == rhs) {
        return YES;
    }
    if (!lhs || !rhs) {
        return NO;
    }
    return [lhs isEqual:rhs];
}

- (NSSet<NSString *> *)propagateFromItemId:(NSString *)itemId {
    NSMutableSet<NSString *> *changed = [NSMutableSet set];
    NSMutableArray<NSString *> *queue = [NSMutableArray array];
    NSArray<NSString *> *initial = self.reverseDeps[itemId] ?: @[];
    [queue addObjectsFromArray:initial];

    while (queue.count > 0) {
        NSString *currentId = queue.firstObject;
        [queue removeObjectAtIndex:0];
        HCCellItem *item = self.itemsById[currentId];
        if (!item || !item.recomputeBlock) {
            continue;
        }
        BOOL oldEnabled = item.enabled;
        id oldDetail = item.detail;
        id oldValue = item.value;
        item.recomputeBlock(item, self.itemsById);
        BOOL valueChanged = (oldEnabled != item.enabled)
            || !HCValueEqual(oldDetail, item.detail)
            || !HCValueEqual(oldValue, item.value);
        if (valueChanged) {
            [changed addObject:currentId];
            NSArray<NSString *> *next = self.reverseDeps[currentId] ?: @[];
            [queue addObjectsFromArray:next];
        }
    }

    return [changed copy];
}

@end
