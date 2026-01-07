#import "HCEnvPanelViewController.h"
#import "HCEnvPanelViewModel.h"
#import "HCEnvSection.h"
#import "HCCellItem.h"
#import "HCSegmentCell.h"
#import "HCSwitchCell.h"
#import "HCStepperCell.h"
#import "HCPresentationRequest.h"

static NSString * const HCSegmentCellId = @"HCSegmentCell";
static NSString * const HCSwitchCellId = @"HCSwitchCell";
static NSString * const HCStepperCellId = @"HCStepperCell";
static NSString * const HCValueCellId = @"HCValueCell";
static NSString * const HCInfoCellId = @"HCInfoCell";

@interface HCEnvPanelViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) HCEnvPanelViewModel *viewModel;

@end

@implementation HCEnvPanelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"调试面板";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.viewModel = [[HCEnvPanelViewModel alloc] init];

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[HCSegmentCell class] forCellReuseIdentifier:HCSegmentCellId];
    [tableView registerClass:[HCSwitchCell class] forCellReuseIdentifier:HCSwitchCellId];
    [tableView registerClass:[HCStepperCell class] forCellReuseIdentifier:HCStepperCellId];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.viewModel.sections[section].title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HCCellItem *item = [self.viewModel itemAtIndexPath:indexPath];
    switch (item.type) {
        case HCCellItemTypeSegment: {
            HCSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:HCSegmentCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(NSInteger selectedIndex) {
                [weakSelf applyValue:@(selectedIndex) forItem:item];
            };
            [cell configureWithItem:item];
            return cell;
        }
        case HCCellItemTypeSwitch: {
            HCSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:HCSwitchCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(BOOL on) {
                [weakSelf applyValue:@(on) forItem:item];
            };
            [cell configureWithItem:item];
            return cell;
        }
        case HCCellItemTypeStepper: {
            HCStepperCell *cell = [tableView dequeueReusableCellWithIdentifier:HCStepperCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(NSInteger value) {
                [weakSelf applyValue:@(value) forItem:item];
            };
            [cell configureWithItem:item minimum:1 maximum:5];
            return cell;
        }
        case HCCellItemTypeInfo: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HCInfoCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:HCInfoCellId];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = item.title;
            cell.textLabel.textColor = [UIColor labelColor];
            cell.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            if (item.desc.length > 0) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", item.detail ?: @"", item.desc ?: @""];
                cell.detailTextLabel.numberOfLines = 0;
            } else {
                cell.detailTextLabel.text = item.detail;
                cell.detailTextLabel.numberOfLines = 1;
            }
            return cell;
        }
        default: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HCValueCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:HCValueCellId];
            }
            cell.textLabel.text = item.title;
            cell.detailTextLabel.text = item.detail;
            cell.textLabel.textColor = item.enabled ? [UIColor labelColor] : [UIColor secondaryLabelColor];
            cell.userInteractionEnabled = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    HCCellItem *item = [self.viewModel itemAtIndexPath:indexPath];
    if (!item.enabled) {
        [self presentRequest:[self.viewModel presentationForDisabledItem:item]];
        return;
    }
    switch (item.type) {
        case HCCellItemTypeString:
            [self presentStringInputForItem:item];
            break;
        case HCCellItemTypePicker:
            [self presentPickerForItem:item];
            break;
        case HCCellItemTypeAction:
            [self applyValue:item.value forItem:item];
            break;
        default:
            break;
    }
}

- (void)applyValue:(id)value forItem:(HCCellItem *)item {
    NSArray<NSIndexPath *> *paths = [self.viewModel updateItem:item value:value];
    if (paths.count == 0) {
        return;
    }
    [self.tableView reloadRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)presentStringInputForItem:(HCCellItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item.title message:item.desc preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [item.value description];
    }];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        if (item.validator) {
            NSString *message = nil;
            if (!item.validator(text, &message)) {
                [weakSelf presentRequest:[HCPresentationRequest toastWithMessage:message ?: @"输入不合法"]];
                return;
            }
        }
        [weakSelf applyValue:text forItem:item];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentPickerForItem:(HCCellItem *)item {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title message:item.desc preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSString *option in item.options ?: @[]) {
        [sheet addAction:[UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf applyValue:option forItem:item];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentRequest:(HCPresentationRequest *)request {
    if (request.type == HCPresentationTypeToast) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:request.title preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
        return;
    }
}

@end
