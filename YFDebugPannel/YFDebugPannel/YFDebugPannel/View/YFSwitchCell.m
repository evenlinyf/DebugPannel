/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板开关 cell 实现。
#import "YFSwitchCell.h"
#import "YFCellItem.h"
#import "YFValueHelpers.h"

@interface YFSwitchCell ()
@property (nonatomic, strong) UISwitch *toggle;
@end

@implementation YFSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _toggle = [[UISwitch alloc] init];
        [_toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _toggle;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(YFCellItem *)item {
    self.textLabel.text = item.title;
    self.textLabel.textColor = item.enabled ? item.textColor : item.disabledTextColor;
    self.backgroundColor = item.enabled ? item.backgroundColor : item.disabledBackgroundColor;
    self.toggle.on = YFBoolValue(item.value);
    self.toggle.enabled = item.enabled;
}

- (void)switchChanged:(UISwitch *)sender {
    if (self.valueChanged) {
        self.valueChanged(sender.isOn);
    }
}

@end
