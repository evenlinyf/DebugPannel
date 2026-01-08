#import "HCEnvPanelViewController.h"
#import "HCEnvPanelViewModel.h"
#import "HCCellItem.h"
#import "HCEnvSection.h"
#import "HCPresentationRequest.h"
#import "HCSegmentCell.h"
#import "HCSwitchCell.h"
#import "HCStepperCell.h"

@interface HCEnvPanelViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) HCEnvPanelViewModel *viewModel;
@end

@implementation HCEnvPanelViewController

static NSString *const kHCSegmentCellId = @"HCSegmentCell";
static NSString *const kHCSwitchCellId = @"HCSwitchCell";
static NSString *const kHCStepperCellId = @"HCStepperCell";
static NSString *const kHCValueCellId = @"HCValueCell";
static NSString *const kHCInfoCellId = @"HCInfoCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"调试面板";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.viewModel = [[HCEnvPanelViewModel alloc] init];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[HCSegmentCell class] forCellReuseIdentifier:kHCSegmentCellId];
    [self.tableView registerClass:[HCSwitchCell class] forCellReuseIdentifier:kHCSwitchCellId];
    [self.tableView registerClass:[HCStepperCell class] forCellReuseIdentifier:kHCStepperCellId];

    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    if (self.presentingViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeTapped)];
    }
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        if (item.value) {
            textField.text = [NSString stringWithFormat:@"%@", item.value];
        }
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        if (item.validator) {
            NSString *errorMessage = item.validator(text);
            if (errorMessage.length > 0) {
                [weakSelf presentRequest:[HCPresentationRequest toastWithMessage:errorMessage]];
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
        [sheet addAction:[UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [weakSelf applyValue:option forItem:item];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentRequest:(HCPresentationRequest *)request {
    if (request.type != HCPresentationTypeToast) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:request.title preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    HCEnvSection *sectionModel = self.viewModel.sections[section];
    return sectionModel.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    HCEnvSection *sectionModel = self.viewModel.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HCCellItem *item = [self.viewModel itemAtIndexPath:indexPath];
    switch (item.type) {
        case HCCellItemTypeSegment: {
            HCSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCSegmentCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(NSInteger selectedIndex) {
                [weakSelf applyValue:@(selectedIndex) forItem:item];
            };
            [cell configureWithItem:item];
            return cell;
        }
        case HCCellItemTypeToggle: {
            HCSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCSwitchCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(BOOL isOn) {
                [weakSelf applyValue:@(isOn) forItem:item];
            };
            [cell configureWithItem:item];
            return cell;
        }
        case HCCellItemTypeStepper: {
            HCStepperCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCStepperCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(NSInteger value) {
                [weakSelf applyValue:@(value) forItem:item];
            };
            [cell configureWithItem:item minimum:item.stepperMin maximum:item.stepperMax];
            return cell;
        }
        case HCCellItemTypeInfo: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCInfoCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kHCInfoCellId];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = item.title;
            cell.textLabel.textColor = UIColor.labelColor;
            cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
            cell.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
            if (item.desc.length > 0) {
                NSString *detail = item.detail ?: @"";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@", detail, item.desc];
                cell.detailTextLabel.numberOfLines = 0;
            } else {
                cell.detailTextLabel.text = item.detail;
                cell.detailTextLabel.numberOfLines = 1;
            }
            return cell;
        }
        case HCCellItemTypeString:
        case HCCellItemTypePicker:
        case HCCellItemTypeAction: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCValueCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kHCValueCellId];
            }
            cell.textLabel.text = item.title;
            cell.detailTextLabel.text = item.detail;
            cell.textLabel.textColor = item.enabled ? UIColor.labelColor : UIColor.secondaryLabelColor;
            cell.userInteractionEnabled = YES;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            return cell;
        }
    }
}

#pragma mark - UITableViewDelegate

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

@end
