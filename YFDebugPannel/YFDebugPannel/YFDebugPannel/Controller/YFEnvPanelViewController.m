/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板主页面控制器实现。
#import "YFEnvPanelViewController.h"
#import "YFEnvPanelBuilder.h"
#import "YFCellItem.h"
#import "YFEnvSection.h"
#import "YFSegmentCell.h"
#import "YFSwitchCell.h"
#import "YFStepperCell.h"
#import "YFAlertPresenter.h"

@interface YFEnvPanelViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<YFEnvSection *> *sections;
@property (nonatomic, strong) id<YFDebugPannelProtocol> builder;
@end

@implementation YFEnvPanelViewController

static NSString *const kYFSegmentCellId = @"YFSegmentCell";
static NSString *const kYFSwitchCellId = @"YFSwitchCell";
static NSString *const kYFStepperCellId = @"YFStepperCell";
static NSString *const kYFValueCellId = @"YFValueCell";
static NSString *const kYFInfoCellId = @"YFInfoCell";
static NSString *const kYFEditableInfoCellId = @"YFEditableInfoCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"调试面板";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.sections = [self.builder buildSections];
    [self.builder refreshSections:self.sections];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60.0;
    [self.tableView registerClass:[YFSegmentCell class] forCellReuseIdentifier:kYFSegmentCellId];
    [self.tableView registerClass:[YFSwitchCell class] forCellReuseIdentifier:kYFSwitchCellId];
    [self.tableView registerClass:[YFStepperCell class] forCellReuseIdentifier:kYFStepperCellId];

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

- (instancetype)initWithBuilder:(id<YFDebugPannelProtocol>)builder {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _builder = builder ?: [[YFEnvPanelBuilder alloc] init];
    }
    return self;
}

- (instancetype)init {
    return [self initWithBuilder:[[YFEnvPanelBuilder alloc] init]];
}

- (void)applyValue:(id)value forItem:(YFCellItem *)item {
    item.value = value;
    if (item.type == YFCellItemTypeEditableInfo) {
        item.detail = value ? [NSString stringWithFormat:@"%@", value] : nil;
    }
    if (item.valueTransformer) {
        item.valueTransformer(item);
    }
    [self.builder refreshSections:self.sections];
    [self.tableView reloadData];
}

- (void)presentStringInputForItem:(YFCellItem *)item {
    __weak typeof(self) weakSelf = self;
    NSString *initialText = item.value ? [NSString stringWithFormat:@"%@", item.value] : @"";
    NSString *message = item.detail.length > 0 ? item.detail : nil;
    UIAlertController *alert = [YFAlertPresenter textInputAlertWithTitle:item.title
                                                                 message:message
                                                             initialText:initialText
                                                          confirmHandler:^(NSString *text) {
        if (item.validator) {
            NSString *errorMessage = item.validator(text);
            if (errorMessage.length > 0) {
                [YFAlertPresenter presentToastFrom:weakSelf message:errorMessage duration:1.0];
                return;
            }
        }
        [weakSelf applyValue:text forItem:item];
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentPickerForItem:(YFCellItem *)item {
    __weak typeof(self) weakSelf = self;
    NSString *message = item.detail.length > 0 ? item.detail : nil;
    UIAlertController *sheet = [YFAlertPresenter actionSheetWithTitle:item.title
                                                              message:message
                                                              options:item.options ?: @[]
                                                           sourceView:nil
                                                     selectionHandler:^(NSString *option) {
        [weakSelf applyValue:option forItem:item];
    }];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (YFCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    YFEnvSection *section = self.sections[indexPath.section];
    NSArray<YFCellItem *> *visibleItems = [self visibleItemsForSection:section];
    return visibleItems[indexPath.row];
}

- (NSArray<YFCellItem *> *)visibleItemsForSection:(YFEnvSection *)section {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(YFCellItem *item, NSDictionary *bindings) {
        return !item.hidden;
    }];
    return [section.items filteredArrayUsingPredicate:predicate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    YFEnvSection *sectionModel = self.sections[section];
    return [self visibleItemsForSection:sectionModel].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    YFEnvSection *sectionModel = self.sections[section];
    return sectionModel.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YFCellItem *item = [self itemAtIndexPath:indexPath];
    switch (item.type) {
        case YFCellItemTypeSegment: {
            YFSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:kYFSegmentCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(NSInteger selectedIndex) {
                [weakSelf applyValue:@(selectedIndex) forItem:item];
            };
            [cell configureWithItem:item];
            return cell;
        }
        case YFCellItemTypeSwitch: {
            YFSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:kYFSwitchCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(BOOL isOn) {
                [weakSelf applyValue:@(isOn) forItem:item];
            };
            [cell configureWithItem:item];
            return cell;
        }
        case YFCellItemTypeStepper: {
            YFStepperCell *cell = [tableView dequeueReusableCellWithIdentifier:kYFStepperCellId forIndexPath:indexPath];
            __weak typeof(self) weakSelf = self;
            cell.valueChanged = ^(NSInteger value) {
                [weakSelf applyValue:@(value) forItem:item];
            };
            [cell configureWithItem:item minimum:item.stepperMin maximum:item.stepperMax];
            return cell;
        }
        case YFCellItemTypeInfo: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kYFInfoCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kYFInfoCellId];
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
        case YFCellItemTypeEditableInfo: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kYFEditableInfoCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kYFEditableInfoCellId];
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
        case YFCellItemTypeString:
        case YFCellItemTypePicker:
        case YFCellItemTypeAction: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kYFValueCellId];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kYFValueCellId];
            }
            cell.textLabel.text = item.title;
            if (item.type == YFCellItemTypeAction) {
                cell.detailTextLabel.text = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
                UIColor *backgroundColor = item.enabled ? self.view.tintColor : UIColor.systemGray3Color;
                cell.backgroundColor = backgroundColor;
                cell.textLabel.textColor = UIColor.whiteColor;
                cell.detailTextLabel.textColor = UIColor.whiteColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            } else {
                cell.detailTextLabel.text = item.value ? [NSString stringWithFormat:@"%@", item.value] : nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.textAlignment = NSTextAlignmentNatural;
                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.backgroundColor = UIColor.systemBackgroundColor;
                cell.textLabel.textColor = item.enabled ? UIColor.labelColor : UIColor.secondaryLabelColor;
                cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
            cell.userInteractionEnabled = YES;
            return cell;
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YFCellItem *item = [self itemAtIndexPath:indexPath];
    if (!item.enabled) {
        NSString *message = item.disabledHint.length > 0 ? item.disabledHint : @"当前不可用";
        [YFAlertPresenter presentToastFrom:self message:message duration:1.0];
        return;
    }
    switch (item.type) {
        case YFCellItemTypeString:
        case YFCellItemTypeEditableInfo:
            [self presentStringInputForItem:item];
            break;
        case YFCellItemTypePicker:
            [self presentPickerForItem:item];
            break;
        case YFCellItemTypeAction:
            if (item.actionHandler) {
                item.actionHandler(item);
                [self.builder refreshSections:self.sections];
                [self.tableView reloadData];
            } else {
                [self applyValue:item.value forItem:item];
            }
            break;
        default:
            break;
    }
}

@end
