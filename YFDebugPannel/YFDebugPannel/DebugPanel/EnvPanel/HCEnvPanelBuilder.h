/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 Builder，对外提供快速构建能力。
#import <Foundation/Foundation.h>

@class HCCellItem;
@class HCEnvConfig;
@class HCEnvSection;
@class UIViewController;

FOUNDATION_EXPORT NSString *const HCEnvItemIdSave;

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：构建 DebugPannel 页面所需的区块与配置能力。
@interface HCEnvPanelBuilder : NSObject
/// 构建默认的面板区块（环境配置 + 配置区块）。
+ (NSArray<HCEnvSection *> *)buildSections;
/// 快速构建默认的 DebugPannel 页面控制器。
+ (UIViewController *)buildPanelViewController;
/// 建立 itemId -> item 的索引（跨 section）。
+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSections:(NSArray<HCEnvSection *> *)sections;
/// 对所有区块执行 recompute 刷新。
+ (void)refreshSections:(NSArray<HCEnvSection *> *)sections;
/// 根据区块配置构建环境配置模型。
+ (HCEnvConfig *)configFromSections:(NSArray<HCEnvSection *> *)sections;
@end
