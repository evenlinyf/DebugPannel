#import <UIKit/UIKit.h>

@class HCCellItem;

NS_ASSUME_NONNULL_BEGIN

typedef void (^HCSegmentValueChanged)(NSInteger selectedIndex);

@interface HCSegmentCell : UITableViewCell

@property (nonatomic, copy, nullable) HCSegmentValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item;

@end

NS_ASSUME_NONNULL_END
