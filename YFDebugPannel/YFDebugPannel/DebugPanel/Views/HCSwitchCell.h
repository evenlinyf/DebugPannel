#import <UIKit/UIKit.h>

@class HCCellItem;

typedef void (^HCSwitchCellValueChanged)(BOOL isOn);

@interface HCSwitchCell : UITableViewCell
@property (nonatomic, copy) HCSwitchCellValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item;
@end
