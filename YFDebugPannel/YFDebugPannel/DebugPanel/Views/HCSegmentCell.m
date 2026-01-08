#import "HCSegmentCell.h"
#import "HCCellItem.h"
#import "HCValueHelpers.h"

@interface HCSegmentCell ()
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@end

@implementation HCSegmentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
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
    NSArray<NSString *> *options = item.options ?: @[];
    [options enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        [self.segmentedControl insertSegmentWithTitle:title atIndex:idx animated:NO];
    }];
    NSInteger index = HCIntValue(item.value);
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
