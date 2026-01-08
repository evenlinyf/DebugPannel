/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板步进器 cell 声明。
#import <UIKit/UIKit.h>

@class HCCellItem;

typedef void (^HCStepperCellValueChanged)(NSInteger value);

@interface HCStepperCell : UITableViewCell
@property (nonatomic, copy) HCStepperCellValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item minimum:(NSInteger)minimum maximum:(NSInteger)maximum;
@end
