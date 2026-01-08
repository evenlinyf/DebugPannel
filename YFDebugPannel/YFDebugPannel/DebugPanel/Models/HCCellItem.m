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
        _stepperMin = 0;
        _stepperMax = 100;
    }
    return self;
}

+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title type:(HCCellItemType)type {
    return [[HCCellItem alloc] initWithIdentifier:identifier title:title type:type];
}

@end
