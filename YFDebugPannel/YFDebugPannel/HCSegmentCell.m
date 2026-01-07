#import "HCSegmentCell.h"
#import "HCCellItem.h"

@interface HCSegmentCell ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation HCSegmentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        [_segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _segmentedControl;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)configureWithItem:(HCCellItem *)item {
    self.textLabel.text = item.title;
    self.segmentedControl.enabled = item.enabled;
    [self.segmentedControl removeAllSegments];
    [item.options enumerateObjectsUsingBlock:^(NSString * _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.segmentedControl insertSegmentWithTitle:title atIndex:idx animated:NO];
    }];
    NSInteger index = [item.value integerValue];
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
