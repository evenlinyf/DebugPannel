/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板通用 cell 数据模型定义。
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YFCellItemType) {
    YFCellItemTypeSwitch,
    YFCellItemTypeString,
    YFCellItemTypeStepper,
    YFCellItemTypeAction,
    YFCellItemTypeSegment,
    YFCellItemTypePicker,
    YFCellItemTypeInfo,
    YFCellItemTypeEditableInfo
};

@class YFCellItem;

typedef void (^YFCellItemRecomputeBlock)(YFCellItem *item, NSDictionary<NSString *, YFCellItem *> *itemsById);
typedef NSString * _Nullable (^YFCellItemValidator)(NSString *input);
typedef void (^YFCellItemValueTransformer)(YFCellItem *item);
typedef void (^YFCellItemActionHandler)(YFCellItem *item);

@interface YFCellItem : NSObject
/// 唯一标识符，用于索引与持久化。
@property (nonatomic, copy, readonly) NSString *identifier;
/// 左侧主标题文案。
@property (nonatomic, copy) NSString *title;
/// 右侧详情文案（可选）。
@property (nonatomic, copy) NSString *detail;
/// 自动生成/展示的值字符串。
@property (nonatomic, copy) NSString *autoValue;
/// 是否可交互/可用。
@property (nonatomic, assign) BOOL enabled;
/// 是否隐藏该项。
@property (nonatomic, assign) BOOL hidden;
/// 不可用时的提示文案。
@property (nonatomic, copy) NSString *disabledHint;
/// 背景色。
@property (nonatomic, strong) UIColor *backgroundColor;
/// 不可用时背景色。
@property (nonatomic, strong) UIColor *disabledBackgroundColor;
/// 主文案颜色。
@property (nonatomic, strong) UIColor *textColor;
/// 不可用时主文案颜色。
@property (nonatomic, strong) UIColor *disabledTextColor;
/// 详情文案颜色。
@property (nonatomic, strong) UIColor *detailTextColor;
/// 不可用时详情文案颜色。
@property (nonatomic, strong) UIColor *disabledDetailTextColor;
/// 辅助视图文案颜色（如右侧“编辑”）。
@property (nonatomic, strong) UIColor *accessoryTextColor;
/// 不可用时辅助视图文案颜色。
@property (nonatomic, strong) UIColor *disabledAccessoryTextColor;

/// Cell 的展示类型。
@property (nonatomic, assign) YFCellItemType type;
/// 当前值（类型随 cell 类型变化）。
@property (nonatomic, strong) id value;

/// Stepper 最小值。
@property (nonatomic, assign) NSInteger stepperMin;
/// Stepper 最大值。
@property (nonatomic, assign) NSInteger stepperMax;

/// 本地持久化存储 key。
@property (nonatomic, copy) NSString *storeKey;
/// 默认值（未持久化时使用）。
@property (nonatomic, strong) id defaultValue;
/// 是否在加载时优先使用持久化值。
@property (nonatomic, assign) BOOL usesStoredValueOnLoad;

/// Segment/Picker 等可选项列表。
@property (nonatomic, copy) NSArray<NSString *> *options;
/// 依赖的其他 item 标识符列表。
@property (nonatomic, copy) NSArray<NSString *> *dependsOn;
/// 依赖变更时触发的重新计算回调。
@property (nonatomic, copy) YFCellItemRecomputeBlock recomputeBlock;

/// 输入校验器（返回错误信息或 nil）。
@property (nonatomic, copy) YFCellItemValidator validator;
/// 值转换器（用于展示/持久化前处理）。
@property (nonatomic, copy) YFCellItemValueTransformer valueTransformer;
/// 点击/操作触发的回调。
@property (nonatomic, copy) YFCellItemActionHandler actionHandler;

- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title type:(YFCellItemType)type;
+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title type:(YFCellItemType)type;

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
+ (instancetype)actionItemWithIdentifier:(NSString *)identifier title:(NSString *)title handler:(nullable YFCellItemActionHandler)handler;
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
