#import <UIKit/UIKit.h>

@class HCCellItem;

NS_ASSUME_NONNULL_BEGIN

typedef void (^HCStepperValueChanged)(NSInteger value);

@interface HCStepperCell : UITableViewCell

@property (nonatomic, copy, nullable) HCStepperValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item minimum:(NSInteger)min maximum:(NSInteger)max;

@end

NS_ASSUME_NONNULL_END
