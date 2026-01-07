#import "HCSwitchCell.h"
#import "HCCellItem.h"

@interface HCSwitchCell ()

@property (nonatomic, strong) UISwitch *toggle;

@end

@implementation HCSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        _toggle = [[UISwitch alloc] init];
        [_toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _toggle;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(HCCellItem *)item {
    self.textLabel.text = item.title;
    self.toggle.on = [item.value boolValue];
    self.toggle.enabled = item.enabled;
}

- (void)switchChanged:(UISwitch *)sender {
    if (self.valueChanged) {
        self.valueChanged(sender.isOn);
    }
}

@end
