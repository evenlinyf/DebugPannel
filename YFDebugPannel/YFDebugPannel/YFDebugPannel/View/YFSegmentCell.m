/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板分段选择 cell 实现。
#import "YFSegmentCell.h"
#import "YFCellItem.h"
#import "YFValueHelpers.h"

@interface YFSegmentCell ()
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@end

@implementation YFSegmentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        [_segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _segmentedControl;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(YFCellItem *)item {
    self.textLabel.text = item.title;
    self.textLabel.textColor = item.enabled ? item.textColor : item.disabledTextColor;
    self.detailTextLabel.text = item.detail;
    self.detailTextLabel.textColor = item.enabled ? item.detailTextColor : item.disabledDetailTextColor;
    self.backgroundColor = item.enabled ? item.backgroundColor : item.disabledBackgroundColor;
    self.segmentedControl.enabled = item.enabled;
    self.segmentedControl.selectedSegmentTintColor = item.enabled ? item.accessoryTextColor : item.disabledAccessoryTextColor;
    UIColor *normalTitleColor = item.enabled ? item.textColor : item.disabledTextColor;
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: normalTitleColor}
                                         forState:UIControlStateNormal];
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor}
                                         forState:UIControlStateSelected];
    [self.segmentedControl removeAllSegments];
    NSArray<NSString *> *options = item.options ?: @[];
    [options enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        [self.segmentedControl insertSegmentWithTitle:title atIndex:idx animated:NO];
    }];
    NSInteger index = YFIntValue(item.value);
    if (index >= 0 && index < self.segmentedControl.numberOfSegments) {
        self.segmentedControl.selectedSegmentIndex = index;
    }
}

- (void)segmentChanged:(UISegmentedControl *)sender {
    if (self.valueChanged) {
        self.valueChanged(sender.selectedSegmentIndex);
    }
}

@end
