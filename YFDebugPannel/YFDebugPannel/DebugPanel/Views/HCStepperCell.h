#import <UIKit/UIKit.h>

@class HCCellItem;

typedef void (^HCStepperCellValueChanged)(NSInteger value);

@interface HCStepperCell : UITableViewCell
@property (nonatomic, copy) HCStepperCellValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item minimum:(NSInteger)minimum maximum:(NSInteger)maximum;
@end
