/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：环境面板 Builder 实现。
#import "HCTEnvPanelBuilder.h"

#import "HCTEnvPanelBuilder+ConfigSection.h"
#import "HCTEnvPanelBuilder+EnvConfig.h"
#import "YFEnvPanelViewController.h"
#import "YFEnvSection.h"
#import "YFCellItem.h"
#import "YFSFSymbolsViewController.h"

NSString *const YFEnvItemIdEnvType = @"env.type";
NSString *const YFEnvItemIdCluster = @"env.cluster";
NSString *const YFEnvItemIdSaas = @"env.saas";
NSString *const YFEnvItemIdIsolation = @"env.isolation";
NSString *const YFEnvItemIdVersion = @"env.version";
NSString *const YFEnvItemIdResult = @"env.result";
NSString *const YFEnvItemIdCustomHistory = @"env.custom.history";
NSString *const YFEnvItemIdElb = @"config.elb";
NSString *const YFEnvItemIdSave = @"env.save";
NSString *const YFEnvItemIdSFSymbols = @"config.sfsymbols";
NSNotificationName const HCTEnvPanelDidSaveNotification = @"HCTEnvPanelDidSaveNotification";

@implementation HCTEnvPanelBuilder

static NSString *sLegacyBaseURL = nil;
static NSString *sLegacySaasEnv = nil;

- (NSArray<YFEnvSection *> *)buildSections {
    NSArray<YFEnvSection *> *sections = [[self class] buildSections];
    NSDictionary<NSString *, YFCellItem *> *itemsById = [[self class] indexItemsByIdFromSections:sections];
    YFCellItem *symbolsItem = itemsById[YFEnvItemIdSFSymbols];
    if (symbolsItem) {
        __weak typeof(self) weakSelf = self;
        symbolsItem.actionHandler = ^(YFCellItem *item) {
            UIViewController *panelController = weakSelf.panelViewController;
            if (!panelController) {
                return;
            }
            YFSFSymbolsViewController *controller = [[YFSFSymbolsViewController alloc] init];
            if (panelController.navigationController) {
                [panelController.navigationController pushViewController:controller animated:YES];
            } else {
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
                [panelController presentViewController:nav animated:YES completion:nil];
            }
        };
    }
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.storeKey.length > 0 && item.usesStoredValueOnLoad) {
                id stored = [[NSUserDefaults standardUserDefaults] objectForKey:item.storeKey];
                if (stored) {
                    item.defaultValue = stored;
                }
            }
            if (!item.value && item.defaultValue) {
                item.value = item.defaultValue;
            }
            if (item.type == YFCellItemTypeEditableInfo) {
                item.detail = item.value ? [NSString stringWithFormat:@"%@", item.value] : nil;
            }
        }
    }
    [[self class] refreshSections:sections];
    [[self class] configureSaveActionForSections:sections onSave:nil];
    [[self class] captureBaselineForSections:sections];
    [[self class] updateSaveItemVisibilityInSections:sections];
    return sections;
}

- (void)refreshSections:(NSArray<YFEnvSection *> *)sections {
    [[self class] refreshSections:sections];
    [[self class] updateSaveItemVisibilityInSections:sections];
}

+ (NSArray<YFEnvSection *> *)buildSections {
    YFEnvSection *envSection = [self buildEnvSection];
    YFEnvSection *configSection = [self buildConfigSection];
    return @[envSection, configSection];
}

+ (UIViewController *)buildPanelViewController {
    YFEnvPanelViewController *controller = [[YFEnvPanelViewController alloc] initWithBuilder:[[HCTEnvPanelBuilder alloc] init]];
    return controller;
}

+ (void)prepareLegacyConfigWithBaseURL:(NSString *)baseURL saasEnv:(NSString *)saasEnv {
    sLegacyBaseURL = [baseURL isKindOfClass:[NSString class]] ? [baseURL copy] : @"";
    sLegacySaasEnv = [saasEnv isKindOfClass:[NSString class]] ? [saasEnv copy] : @"";
}

+ (NSString *)legacyBaseURL {
    return sLegacyBaseURL ?: @"";
}

+ (NSString *)legacySaasEnv {
    return sLegacySaasEnv ?: @"";
}

+ (NSDictionary<NSString *, YFCellItem *> *)indexItemsByIdFromSections:(NSArray<YFEnvSection *> *)sections {
    NSMutableDictionary<NSString *, YFCellItem *> *itemsById = [NSMutableDictionary dictionary];
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.identifier.length > 0) {
                itemsById[item.identifier] = item;
            }
        }
    }
    return [itemsById copy];
}

+ (void)refreshSections:(NSArray<YFEnvSection *> *)sections {
    NSDictionary<NSString *, YFCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    for (YFEnvSection *section in sections) {
        for (YFCellItem *item in section.items) {
            if (item.recomputeBlock) {
                item.recomputeBlock(item, itemsById);
            }
        }
    }
}

@end
