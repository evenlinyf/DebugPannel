/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板主页面控制器实现。
#import "HCEnvPanelViewController.h"
#import "HCEnvPanelBuilder.h"
#import "HCCellItem.h"
#import "HCEnvKit.h"
#import "HCEnvSection.h"
#import "HCPresentationRequest.h"
#import "HCSegmentCell.h"
#import "HCSwitchCell.h"
#import "HCStepperCell.h"
#import "HCAlertPresenter.h"

@interface HCEnvPanelViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<HCEnvSection *> *sections;
@end

@implementation HCEnvPanelViewController

static NSString *const kHCSegmentCellId = @"HCSegmentCell";
static NSString *const kHCSwitchCellId = @"HCSwitchCell";
static NSString *const kHCStepperCellId = @"HCStepperCell";
static NSString *const kHCValueCellId = @"HCValueCell";
static NSString *const kHCInfoCellId = @"HCInfoCell";
static NSString *const kHCEditableInfoCellId = @"HCEditableInfoCell";
static NSString *const kHCActionCellId = @"HCActionCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"调试面板";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.sections = [HCEnvPanelBuilder buildSections];
    [self loadPersistedValues];
    [HCEnvPanelBuilder refreshSections:self.sections];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60.0;
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
    item.value = value;
    if (item.type == HCCellItemTypeEditableInfo) {
        item.detail = value ? [NSString stringWithFormat:@"%@", value] : nil;
    }
    if (item.valueTransformer) {
        item.valueTransformer(item);
    }
    [self persistIfNeededForItem:item];
    [HCEnvPanelBuilder refreshSections:self.sections];
    [self.tableView reloadData];
}

- (void)presentStringInputForItem:(HCCellItem *)item {
    __weak typeof(self) weakSelf = self;
    NSString *initialText = item.value ? [NSString stringWithFormat:@"%@", item.value] : @"";
    NSString *message = item.detail.length > 0 ? item.detail : nil;
    UIAlertController *alert = [HCAlertPresenter textInputAlertWithTitle:item.title
                                                                 message:message
                                                             initialText:initialText
                                                          confirmHandler:^(NSString *text) {
        if (item.validator) {
            NSString *errorMessage = item.validator(text);
            if (errorMessage.length > 0) {
                [weakSelf presentRequest:[HCPresentationRequest toastWithMessage:errorMessage]];
                return;
            }
        }
        [weakSelf applyValue:text forItem:item];
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentPickerForItem:(HCCellItem *)item {
    __weak typeof(self) weakSelf = self;
    NSString *message = item.detail.length > 0 ? item.detail : nil;
    UIAlertController *sheet = [HCAlertPresenter actionSheetWithTitle:item.title
                                                              message:message
                                                              options:item.options ?: @[]
                                                           sourceView:self.view
                                                     selectionHandler:^(NSString *option) {
        [weakSelf applyValue:option forItem:item];
    }];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentRequest:(HCPresentationRequest *)request {
    if (request.type != HCPresentationTypeToast) {
        return;
    }
    [HCAlertPresenter presentToastFrom:self message:request.title duration:1.0];
}

- (void)loadPersistedValues {
    for (HCEnvSection *section in self.sections) {
        for (HCCellItem *item in section.items) {
            if (item.storeKey.length == 0) {
                continue;
            }
            id stored = [[NSUserDefaults standardUserDefaults] objectForKey:item.storeKey];
            if (stored) {
                item.value = stored;
            } else if (item.defaultValue) {
                item.value = item.defaultValue;
            }
            if (item.type == HCCellItemTypeEditableInfo) {
                item.detail = item.value ? [NSString stringWithFormat:@"%@", item.value] : nil;
            }
        }
    }
}

- (void)persistIfNeededForItem:(HCCellItem *)item {
    if (item.storeKey.length == 0) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (item.value) {
        [defaults setObject:item.value forKey:item.storeKey];
    } else {
        [defaults removeObjectForKey:item.storeKey];
    }
}

- (void)persistEnvConfig {
    HCEnvConfig *config = [HCEnvPanelBuilder configFromSections:self.sections];
    [HCEnvKit saveConfig:config];
}

- (HCCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    HCEnvSection *section = self.sections[indexPath.section];
    NSArray<HCCellItem *> *visibleItems = [self visibleItemsForSection:section];
    return visibleItems[indexPath.row];
}

- (NSArray<HCCellItem *> *)visibleItemsForSection:(HCEnvSection *)section {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(HCCellItem *item, NSDictionary *bindings) {
        return !item.hidden;
    }];
    return [section.items filteredArrayUsingPredicate:predicate];
}

- (UIView *)valueAccessoryViewWithText:(NSString *)text enabled:(BOOL)enabled {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = enabled ? UIColor.secondaryLabelColor : UIColor.tertiaryLabelColor;
    label.textAlignment = NSTextAlignmentRight;
    [label sizeToFit];

    UIImage *chevronImage = [UIImage systemImageNamed:@"chevron.right"];
    UIImageView *chevron = [[UIImageView alloc] initWithImage:chevronImage];
    chevron.tintColor = UIColor.tertiaryLabelColor;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[label, chevron]];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 6.0;
    return stack;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    HCEnvSection *sectionModel = self.sections[section];
    return [self visibleItemsForSection:sectionModel].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    HCEnvSection *sectionModel = self.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HCCellItem *item = [self itemAtIndexPath:indexPath];
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
        case HCCellItemTypeSwitch: {
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
            cell.detailTextLabel.text = item.detail;
            cell.detailTextLabel.numberOfLines = 1;
            return cell;
        }
        case HCCellItemTypeEditableInfo: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCEditableInfoCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kHCEditableInfoCellId];
            }
            UILabel *accessoryLabel = [[UILabel alloc] init];
            accessoryLabel.text = @"编辑";
            accessoryLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
            accessoryLabel.textColor = item.enabled ? self.view.tintColor : UIColor.secondaryLabelColor;
            [accessoryLabel sizeToFit];
            cell.accessoryView = accessoryLabel;
            cell.textLabel.text = item.title;
            cell.textLabel.textColor = item.enabled ? UIColor.labelColor : UIColor.secondaryLabelColor;
            cell.detailTextLabel.text = item.detail;
            cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.userInteractionEnabled = YES;
            return cell;
        }
        case HCCellItemTypeString:
        case HCCellItemTypePicker:
        case HCCellItemTypeAction: {
            if (item.type == HCCellItemTypeAction) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCActionCellId];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kHCActionCellId];
                }
                cell.textLabel.text = item.title;
                cell.detailTextLabel.text = nil;
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
                UIColor *backgroundColor = item.enabled ? self.view.tintColor : UIColor.systemGray3Color;
                cell.backgroundColor = backgroundColor;
                cell.textLabel.textColor = UIColor.whiteColor;
                cell.detailTextLabel.textColor = UIColor.whiteColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.userInteractionEnabled = YES;
                return cell;
            } else {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kHCValueCellId];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kHCValueCellId];
                }
                cell.textLabel.text = item.title;
                cell.detailTextLabel.text = item.detail.length > 0 ? item.detail : nil;
                cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
                cell.detailTextLabel.numberOfLines = 0;
                NSString *valueText = item.value ? [NSString stringWithFormat:@"%@", item.value] : @"";
                cell.accessoryView = [self valueAccessoryViewWithText:valueText enabled:item.enabled];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textAlignment = NSTextAlignmentNatural;
                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.backgroundColor = UIColor.systemBackgroundColor;
                cell.textLabel.textColor = item.enabled ? UIColor.labelColor : UIColor.secondaryLabelColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.userInteractionEnabled = YES;
                return cell;
            }
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    HCCellItem *item = [self itemAtIndexPath:indexPath];
    if (!item.enabled) {
        NSString *message = item.disabledHint.length > 0 ? item.disabledHint : @"当前不可用";
        [self presentRequest:[HCPresentationRequest toastWithMessage:message]];
        return;
    }
    switch (item.type) {
        case HCCellItemTypeString:
        case HCCellItemTypeEditableInfo:
            [self presentStringInputForItem:item];
            break;
        case HCCellItemTypePicker:
            [self presentPickerForItem:item];
            break;
        case HCCellItemTypeAction:
            if ([item.identifier isEqualToString:HCEnvItemIdSave]) {
                [self persistEnvConfig];
                [self presentRequest:[HCPresentationRequest toastWithMessage:@"环境已保存"]];
                [HCEnvPanelBuilder refreshSections:self.sections];
                [self.tableView reloadData];
            } else if (item.actionHandler) {
                item.actionHandler(item);
            } else {
                [self applyValue:item.value forItem:item];
            }
            break;
        default:
            break;
    }
}

@end
