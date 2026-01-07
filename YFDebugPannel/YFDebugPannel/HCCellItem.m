#import "HCCellItem.h"

@implementation HCCellItem

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                              title:(NSString *)title
                               type:(HCCellItemType)type {
    HCCellItem *item = [[HCCellItem alloc] init];
    item.identifier = identifier;
    item.title = title;
    item.type = type;
    item.enabled = YES;
    return item;
}

@end
