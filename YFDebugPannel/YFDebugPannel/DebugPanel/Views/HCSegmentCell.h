#import <UIKit/UIKit.h>

@class HCCellItem;

typedef void (^HCSegmentCellValueChanged)(NSInteger selectedIndex);

@interface HCSegmentCell : UITableViewCell
@property (nonatomic, copy) HCSegmentCellValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item;
@end
