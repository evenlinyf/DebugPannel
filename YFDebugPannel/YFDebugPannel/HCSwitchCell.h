#import <UIKit/UIKit.h>

@class HCCellItem;

NS_ASSUME_NONNULL_BEGIN

typedef void (^HCSwitchValueChanged)(BOOL on);

@interface HCSwitchCell : UITableViewCell

@property (nonatomic, copy, nullable) HCSwitchValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item;

@end

NS_ASSUME_NONNULL_END
