/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板分组 section 模型实现。
#import "YFEnvSection.h"

@implementation YFEnvSection

- (instancetype)initWithTitle:(NSString *)title items:(NSArray *)items {
    self = [super init];
    if (self) {
        _title = [title copy];
        _items = [items copy];
    }
    return self;
}

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray *)items {
    return [[YFEnvSection alloc] initWithTitle:title items:items];
}

@end
