/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板分段选择 cell 声明。
#import <UIKit/UIKit.h>

@class HCCellItem;

typedef void (^HCSegmentCellValueChanged)(NSInteger selectedIndex);

@interface HCSegmentCell : UITableViewCell
@property (nonatomic, copy) HCSegmentCellValueChanged valueChanged;

- (void)configureWithItem:(HCCellItem *)item;
@end
