/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板 cell 数据模型实现。
#import "HCCellItem.h"

@interface HCCellItem ()
@property (nonatomic, copy) NSString *identifier;
@end

@implementation HCCellItem

- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _title = [title copy];
        _type = type;
        _enabled = YES;
        _hidden = NO;
        _stepperMin = 0;
        _stepperMax = 100;
    }
    return self;
}

+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type {
    return [[HCCellItem alloc] initWithIdentifier:identifier title:title type:type];
}

// 工厂方法负责填充可持久化字段，避免调用方重复配置。
+ (instancetype)switchItemWithIdentifier:(NSString *)identifier
                                   title:(NSString *)title
                                storeKey:(NSString *)storeKey
                            defaultValue:(id)defaultValue {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeSwitch];
    item.storeKey = storeKey ?: @"";
    item.defaultValue = defaultValue;
    return item;
}

// String item 默认需要持久化配置。
+ (instancetype)stringItemWithIdentifier:(NSString *)identifier
                                   title:(NSString *)title
                                storeKey:(NSString *)storeKey
                            defaultValue:(id)defaultValue {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeString];
    item.storeKey = storeKey ?: @"";
    item.defaultValue = defaultValue;
    return item;
}

// Stepper item 需要默认范围。
+ (instancetype)stepperItemWithIdentifier:(NSString *)identifier
                                    title:(NSString *)title
                                 storeKey:(NSString *)storeKey
                             defaultValue:(id)defaultValue
                                  minimum:(NSInteger)minimum
                                  maximum:(NSInteger)maximum {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeStepper];
    item.storeKey = storeKey ?: @"";
    item.defaultValue = defaultValue;
    item.stepperMin = minimum;
    item.stepperMax = maximum;
    return item;
}

+ (instancetype)actionItemWithIdentifier:(NSString *)identifier title:(NSString *)title handler:(HCCellItemActionHandler)handler {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeAction];
    item.actionHandler = handler;
    return item;
}

// Segment item 通过 options 和 defaultValue 初始化。
+ (instancetype)segmentItemWithIdentifier:(NSString *)identifier
                                    title:(NSString *)title
                                  options:(NSArray<NSString *> *)options
                             defaultValue:(id)defaultValue {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeSegment];
    item.options = options;
    item.defaultValue = defaultValue;
    if (defaultValue) {
        item.value = defaultValue;
    }
    return item;
}

// Picker item 需要 options 配置以及持久化信息。
+ (instancetype)pickerItemWithIdentifier:(NSString *)identifier
                                   title:(NSString *)title
                                storeKey:(NSString *)storeKey
                            defaultValue:(id)defaultValue
                                 options:(NSArray<NSString *> *)options {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypePicker];
    item.storeKey = storeKey ?: @"";
    item.defaultValue = defaultValue;
    item.options = options;
    return item;
}

+ (instancetype)infoItemWithIdentifier:(NSString *)identifier
                                 title:(NSString *)title
                                detail:(NSString *)detail {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeInfo];
    item.detail = detail;
    return item;
}

// 可编辑 Info 依赖 storeKey/默认值以便持久化。
+ (instancetype)editableInfoItemWithIdentifier:(NSString *)identifier
                                         title:(NSString *)title
                                      storeKey:(NSString *)storeKey
                                  defaultValue:(id)defaultValue {
    HCCellItem *item = [self itemWithIdentifier:identifier title:title type:HCCellItemTypeEditableInfo];
    item.storeKey = storeKey ?: @"";
    item.defaultValue = defaultValue;
    return item;
}

@end
