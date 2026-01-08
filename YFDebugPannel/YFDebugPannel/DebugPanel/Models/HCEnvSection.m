#import "HCEnvSection.h"

@implementation HCEnvSection

- (instancetype)initWithTitle:(NSString *)title items:(NSArray *)items {
    self = [super init];
    if (self) {
        _title = [title copy];
        _items = [items copy];
    }
    return self;
}

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray *)items {
    return [[HCEnvSection alloc] initWithTitle:title items:items];
}

@end
