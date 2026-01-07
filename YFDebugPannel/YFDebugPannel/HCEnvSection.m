#import "HCEnvSection.h"
#import "HCCellItem.h"

@implementation HCEnvSection

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<HCCellItem *> *)items {
    HCEnvSection *section = [[HCEnvSection alloc] init];
    section.title = title;
    section.items = items;
    return section;
}

@end
