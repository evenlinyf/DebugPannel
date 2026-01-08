#import "HCStepperCell.h"
#import "HCCellItem.h"
#import "HCValueHelpers.h"

@interface HCStepperCell ()
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIStackView *stackView;
@end

@implementation HCStepperCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _stepper = [[UIStepper alloc] init];
        [_stepper addTarget:self action:@selector(stepperChanged:) forControlEvents:UIControlEventValueChanged];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.textColor = UIColor.redColor;
        [_valueLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_valueLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_valueLabel, _stepper]];
        _stackView.frame = CGRectMake(0, 0, 200, 44);
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.spacing = 8;
        _stackView.alignment = UIStackViewAlignmentFill;
        [_valueLabel.widthAnchor constraintEqualToConstant:40].active = YES;

        self.accessoryView = _stackView;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(HCCellItem *)item minimum:(NSInteger)minimum maximum:(NSInteger)maximum {
    self.textLabel.text = item.title;
    self.detailTextLabel.text = item.desc;
    self.stepper.minimumValue = minimum;
    self.stepper.maximumValue = maximum;
    self.stepper.enabled = item.enabled;
    NSInteger value = HCIntValue(item.value);
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
