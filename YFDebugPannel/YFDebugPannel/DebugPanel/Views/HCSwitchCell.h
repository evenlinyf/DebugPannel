/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板开关 cell 声明。
#import <UIKit/UIKit.h>

@class HCCellItem;

typedef void (^HCSwitchCellValueChanged)(BOOL isOn);

@interface HCSwitchCell : UITableViewCell
@property (nonatomic, copy) HCSwitchCellValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item;
@end
