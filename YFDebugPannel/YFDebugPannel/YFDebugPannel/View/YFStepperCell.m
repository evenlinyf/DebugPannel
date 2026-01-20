/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板步进器 cell 实现。
#import "YFStepperCell.h"
#import "YFCellItem.h"
#import "YFValueHelpers.h"

@interface YFStepperCell ()
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UIStackView *stackView;
@end

@implementation YFStepperCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        _stepper = [[UIStepper alloc] init];
        [_stepper addTarget:self action:@selector(stepperChanged:) forControlEvents:UIControlEventValueChanged];
        _stepper.wraps = YES;

        self.accessoryView = _stepper;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(YFCellItem *)item minimum:(NSInteger)minimum maximum:(NSInteger)maximum {
    self.textLabel.text = item.title;
    self.detailTextLabel.text = item.detail;
    self.stepper.minimumValue = minimum;
    self.stepper.maximumValue = maximum;
    self.stepper.enabled = item.enabled;
    self.textLabel.textColor = item.enabled ? item.textColor : item.disabledTextColor;
    self.detailTextLabel.textColor = item.enabled ? item.detailTextColor : item.disabledDetailTextColor;
    self.backgroundColor = item.enabled ? item.backgroundColor : item.disabledBackgroundColor;
    NSInteger value = YFIntValue(item.value);
    self.stepper.value = value;
    self.stepper.enabled = item.enabled;
}

- (void)stepperChanged:(UIStepper *)sender {
    NSInteger value = (NSInteger)sender.value;
    if (self.valueChanged) {
        self.valueChanged(value);
    }
}

@end
