/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板通用 cell 数据模型定义。
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HCCellItemType) {
    HCCellItemTypeSwitch,
    HCCellItemTypeString,
    HCCellItemTypeStepper,
    HCCellItemTypeAction,
    HCCellItemTypeSegment,
    HCCellItemTypePicker,
    HCCellItemTypeInfo,
    HCCellItemTypeEditableInfo
};

@class HCCellItem;

typedef void (^HCCellItemRecomputeBlock)(HCCellItem *item, NSDictionary<NSString *, HCCellItem *> *itemsById);
typedef NSString * _Nullable (^HCCellItemValidator)(NSString *input);
typedef void (^HCCellItemValueTransformer)(HCCellItem *item);
typedef void (^HCCellItemActionHandler)(HCCellItem *item);

@interface HCCellItem : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) NSString *autoValue;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, copy) NSString *disabledHint;

@property (nonatomic, assign) HCCellItemType type;
@property (nonatomic, strong) id value;

@property (nonatomic, assign) NSInteger stepperMin;
@property (nonatomic, assign) NSInteger stepperMax;

@property (nonatomic, copy) NSString *storeKey;
@property (nonatomic, strong) id defaultValue;

@property (nonatomic, copy) NSArray<NSString *> *options;
@property (nonatomic, copy) NSArray<NSString *> *dependsOn;
@property (nonatomic, copy) HCCellItemRecomputeBlock recomputeBlock;

@property (nonatomic, copy) HCCellItemValidator validator;
@property (nonatomic, copy) HCCellItemValueTransformer valueTransformer;
@property (nonatomic, copy) HCCellItemActionHandler actionHandler;

- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type;
+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type;

/// 创建 Switch 类型 item，并设置持久化 key / 默认值。
+ (instancetype)switchItemWithIdentifier:(NSString *)identifier
                                   title:(NSString *)title
                                storeKey:(nullable NSString *)storeKey
                            defaultValue:(nullable id)defaultValue;
/// 创建 String 类型 item，并设置持久化 key / 默认值。
+ (instancetype)stringItemWithIdentifier:(NSString *)identifier
                                   title:(NSString *)title
                                storeKey:(nullable NSString *)storeKey
                            defaultValue:(nullable id)defaultValue;
/// 创建 Stepper 类型 item，并设置持久化 key / 默认值 / 范围。
+ (instancetype)stepperItemWithIdentifier:(NSString *)identifier
                                    title:(NSString *)title
                                 storeKey:(nullable NSString *)storeKey
                             defaultValue:(nullable id)defaultValue
                               minimum:(NSInteger)minimum
                               maximum:(NSInteger)maximum;
/// 创建 Action 类型 item，并绑定点击回调。
+ (instancetype)actionItemWithIdentifier:(NSString *)identifier title:(NSString *)title handler:(nullable HCCellItemActionHandler)handler;
/// 创建 Segment 类型 item，并设置选项 / 默认值。
+ (instancetype)segmentItemWithIdentifier:(NSString *)identifier
                                    title:(NSString *)title
                                  options:(NSArray<NSString *> *)options
                             defaultValue:(nullable id)defaultValue;
/// 创建 Picker 类型 item，并设置持久化 key / 默认值 / 选项。
+ (instancetype)pickerItemWithIdentifier:(NSString *)identifier
                                   title:(NSString *)title
                                storeKey:(nullable NSString *)storeKey
                            defaultValue:(nullable id)defaultValue
                                 options:(NSArray<NSString *> *)options;
/// 创建 Info 类型 item，并设置展示 detail 文案。
+ (instancetype)infoItemWithIdentifier:(NSString *)identifier
                                 title:(NSString *)title
                                detail:(nullable NSString *)detail;
/// 创建可编辑 Info 类型 item，并设置持久化 key / 默认值。
+ (instancetype)editableInfoItemWithIdentifier:(NSString *)identifier
                                         title:(NSString *)title
                                      storeKey:(nullable NSString *)storeKey
                                  defaultValue:(nullable id)defaultValue;
@end


NS_ASSUME_NONNULL_END
