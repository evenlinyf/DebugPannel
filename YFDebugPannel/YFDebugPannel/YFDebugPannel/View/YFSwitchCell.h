/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板开关 cell 声明。
#import <UIKit/UIKit.h>

@class YFCellItem;

typedef void (^YFSwitchCellValueChanged)(BOOL isOn);

@interface YFSwitchCell : UITableViewCell
@property (nonatomic, copy) YFSwitchCellValueChanged valueChanged;

- (void)configureWithItem:(YFCellItem *)item;
@end
