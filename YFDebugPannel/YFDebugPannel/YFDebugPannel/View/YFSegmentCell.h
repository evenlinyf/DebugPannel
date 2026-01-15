/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板分段选择 cell 声明。
#import <UIKit/UIKit.h>

@class YFCellItem;

typedef void (^YFSegmentCellValueChanged)(NSInteger selectedIndex);

@interface YFSegmentCell : UITableViewCell
@property (nonatomic, copy) YFSegmentCellValueChanged valueChanged;

- (void)configureWithItem:(YFCellItem *)item;
@end
