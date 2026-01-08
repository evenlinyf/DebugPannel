/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 Builder 实现。
#import "HCEnvPanelBuilder.h"

#import "HCEnvBuilder.h"
#import "HCCellItem.h"
#import "HCEnvKit.h"
#import "HCEnvPanelViewController.h"
#import "HCEnvSection.h"

@implementation HCEnvPanelBuilder

+ (NSArray<HCEnvSection *> *)buildSections {
    HCEnvSection *envSection = [HCEnvBuilder buildEnvSection];
    HCEnvSection *configSection = [HCEnvBuilder buildConfigSeciton];
    return @[envSection, configSection];
}

+ (UIViewController *)buildPanelViewController {
    return [[HCEnvPanelViewController alloc] init];
}

+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSections:(NSArray<HCEnvSection *> *)sections {
    NSMutableDictionary<NSString *, HCCellItem *> *itemsById = [NSMutableDictionary dictionary];
    for (HCEnvSection *section in sections) {
        NSDictionary<NSString *, HCCellItem *> *index = [HCEnvBuilder indexItemsByIdFromSection:section];
        [itemsById addEntriesFromDictionary:index];
    }
    return [itemsById copy];
}

+ (void)refreshSections:(NSArray<HCEnvSection *> *)sections {
    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    for (HCEnvSection *section in sections) {
        for (HCCellItem *item in section.items) {
            if (item.recomputeBlock) {
                item.recomputeBlock(item, itemsById);
            }
        }
    }
}

+ (HCEnvConfig *)configFromSections:(NSArray<HCEnvSection *> *)sections {
    NSDictionary<NSString *, HCCellItem *> *itemsById = [self indexItemsByIdFromSections:sections];
    return [HCEnvBuilder configFromItems:itemsById];
}

@end
