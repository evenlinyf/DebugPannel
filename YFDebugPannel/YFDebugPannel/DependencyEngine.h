#import <Foundation/Foundation.h>

@class HCCellItem;

NS_ASSUME_NONNULL_BEGIN

@interface DependencyEngine : NSObject

@property (nonatomic, strong, readonly) NSDictionary<NSString *, HCCellItem *> *itemsById;

- (instancetype)initWithItems:(NSArray<HCCellItem *> *)items;

- (NSSet<NSString *> *)propagateFromItemId:(NSString *)itemId;

@end

NS_ASSUME_NONNULL_END
