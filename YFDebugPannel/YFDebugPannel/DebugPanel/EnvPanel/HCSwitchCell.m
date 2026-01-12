/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板开关 cell 实现。
#import "HCSwitchCell.h"
#import "HCCellItem.h"
#import "HCValueHelpers.h"

@interface HCSwitchCell ()
@property (nonatomic, strong) UISwitch *toggle;
@end

@implementation HCSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _toggle = [[UISwitch alloc] init];
        [_toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _toggle;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(HCCellItem *)item {
    self.textLabel.text = item.title;
    self.detailTextLabel.text = item.detail;
    self.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    self.detailTextLabel.numberOfLines = 0;
    self.toggle.on = HCBoolValue(item.value);
    self.toggle.enabled = item.enabled;
}

- (void)switchChanged:(UISwitch *)sender {
    if (self.valueChanged) {
        self.valueChanged(sender.isOn);
    }
}

@end
