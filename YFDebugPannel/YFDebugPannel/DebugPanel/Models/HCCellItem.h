#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HCCellItemType) {
    HCCellItemTypeToggle,
    HCCellItemTypeString,
    HCCellItemTypeStepper,
    HCCellItemTypeAction,
    HCCellItemTypeSegment,
    HCCellItemTypePicker,
    HCCellItemTypeInfo
};

@class HCCellItem;

typedef void (^HCCellItemRecomputeBlock)(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById);
typedef NSString * _Nullable (^HCCellItemValidator)(NSString *input);
typedef void (^HCCellItemValueTransformer)(HCCellItem *item);

@interface HCCellItem : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy) NSString *disabledHint;

@property (nonatomic, assign) HCCellItemType type;
@property (nonatomic, strong) id value;

@property (nonatomic, copy) NSString *storeKey;
@property (nonatomic, strong) id defaultValue;

@property (nonatomic, copy) NSArray<NSString *> *options;
@property (nonatomic, copy) NSArray<NSString *> *dependsOn;
@property (nonatomic, copy) HCCellItemRecomputeBlock recomputeBlock;

@property (nonatomic, copy) HCCellItemValidator validator;
@property (nonatomic, copy) HCCellItemValueTransformer valueTransformer;

- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type;
+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type;
@end
