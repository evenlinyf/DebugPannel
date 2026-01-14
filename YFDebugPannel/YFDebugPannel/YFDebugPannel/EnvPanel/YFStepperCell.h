/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板步进器 cell 声明。
#import <UIKit/UIKit.h>

@class YFCellItem;

typedef void (^YFStepperCellValueChanged)(NSInteger value);

@interface YFStepperCell : UITableViewCell
@property (nonatomic, copy) YFStepperCellValueChanged valueChanged;

- (void)configureWithItem:(YFCellItem *)item minimum:(NSInteger)minimum maximum:(NSInteger)maximum;
@end
