#import "HCStepperCell.h"
#import "HCCellItem.h"

@interface HCStepperCell ()

@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UILabel *valueLabel;

@end

@implementation HCStepperCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        _stepper = [[UIStepper alloc] init];
        [_stepper addTarget:self action:@selector(stepperChanged:) forControlEvents:UIControlEventValueChanged];
        _valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 24)];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_valueLabel, _stepper]];
        stack.axis = UILayoutConstraintAxisHorizontal;
        stack.spacing = 8.0;
        self.accessoryView = stack;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(HCCellItem *)item minimum:(NSInteger)min maximum:(NSInteger)max {
    self.textLabel.text = item.title;
    self.detailTextLabel.text = item.desc;
    self.stepper.minimumValue = min;
    self.stepper.maximumValue = max;
    self.stepper.enabled = item.enabled;
    NSInteger value = [item.value integerValue];
    self.stepper.value = value;
    self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)value];
}

- (void)stepperChanged:(UIStepper *)sender {
    NSInteger value = (NSInteger)sender.value;
    self.valueLabel.text = [NSString stringWithFormat:@"%ld", (long)value];
    if (self.valueChanged) {
        self.valueChanged(value);
    }
}

@end
