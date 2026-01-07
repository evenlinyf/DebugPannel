#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HCCellItemType) {
    HCCellItemTypeSwitch,
    HCCellItemTypeString,
    HCCellItemTypeStepper,
    HCCellItemTypeAction,
    HCCellItemTypeSegment,
    HCCellItemTypePicker,
    HCCellItemTypeInfo
};

@class HCCellItem;

typedef void (^HCCellItemRecomputeBlock)(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById);

typedef BOOL (^HCCellItemValidator)(NSString *input, NSString * _Nullable *errorMessage);

typedef void (^HCCellItemValueTransformer)(HCCellItem *item);

@interface HCCellItem : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *desc;
@property (nonatomic, copy, nullable) NSString *detail;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy, nullable) NSString *disabledHint;

@property (nonatomic, assign) HCCellItemType type;
@property (nonatomic, strong, nullable) id value;

@property (nonatomic, copy, nullable) NSString *storeKey;
@property (nonatomic, strong, nullable) id defaultValue;

@property (nonatomic, copy, nullable) NSArray<NSString *> *options;
@property (nonatomic, copy, nullable) NSArray<NSString *> *dependsOn;
@property (nonatomic, copy, nullable) HCCellItemRecomputeBlock recomputeBlock;

@property (nonatomic, copy, nullable) HCCellItemValidator validator;
@property (nonatomic, copy, nullable) HCCellItemValueTransformer valueTransformer;

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                              title:(NSString *)title
                               type:(HCCellItemType)type;

@end

NS_ASSUME_NONNULL_END
