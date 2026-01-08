#import "DependencyEngine.h"
#import "HCCellItem.h"

@interface DependencyEngine ()
@property (nonatomic, copy) NSDictionary<NSString *, HCCellItem *> *itemsById;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *reverseDeps;
@end

@implementation DependencyEngine

- (instancetype)initWithItems:(NSArray<HCCellItem *> *)items {
    self = [super init];
    if (self) {
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
        _itemsById = [itemsById copy];
        NSMutableDictionary<NSString *, NSArray<NSString *> *> *finalReverse = [NSMutableDictionary dictionary];
        [reverseDeps enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray<NSString *> *obj, BOOL *stop) {
            finalReverse[key] = [obj copy];
        }];
        _reverseDeps = [finalReverse copy];
    }
    return self;
}

- (NSSet<NSString *> *)propagateFromItemId:(NSString *)itemId {
    NSMutableSet<NSString *> *changed = [NSMutableSet set];
    NSMutableArray<NSString *> *queue = [NSMutableArray arrayWithArray:self.reverseDeps[itemId] ?: @[]];

    while (queue.count > 0) {
        NSString *currentId = queue.firstObject;
        [queue removeObjectAtIndex:0];

        HCCellItem *item = self.itemsById[currentId];
        if (!item || !item.recomputeBlock) {
            continue;
        }
        BOOL oldEnabled = item.enabled;
        NSString *oldDetail = item.detail;
        id oldValue = item.value;
        NSString *oldDesc = item.desc;
        item.recomputeBlock(item, self.itemsById);
        BOOL valueChanged = (oldEnabled != item.enabled)
            || ![self valueEqual:oldDetail rhs:item.detail]
            || ![self valueEqual:oldValue rhs:item.value]
            || ![self valueEqual:oldDesc rhs:item.desc];
        if (valueChanged) {
            [changed addObject:currentId];
            NSArray<NSString *> *next = self.reverseDeps[currentId] ?: @[];
            [queue addObjectsFromArray:next];
        }
    }

    return [changed copy];
}

- (BOOL)valueEqual:(id)lhs rhs:(id)rhs {
    if (!lhs && !rhs) {
        return YES;
    }
    if ([lhs isKindOfClass:[NSObject class]] && [rhs isKindOfClass:[NSObject class]]) {
        return [lhs isEqual:rhs];
    }
    return NO;
}

@end
