#import <Foundation/Foundation.h>

@class HCCellItem;

@interface DependencyEngine : NSObject
@property (nonatomic, copy, readonly) NSDictionary<NSString *, HCCellItem *> *itemsById;

- (instancetype)initWithItems:(NSArray<HCCellItem *> *)items;
- (NSSet<NSString *> *)propagateFromItemId:(NSString *)itemId;
@end
