/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 Builder，对外提供快速构建能力。
#import <Foundation/Foundation.h>

#import "YFDebugPannelProtocol.h"

@class YFCellItem;
@class HCEnvConfig;
@class YFEnvSection;
@class UIViewController;

FOUNDATION_EXPORT NSString *const YFEnvItemIdEnvType;
FOUNDATION_EXPORT NSString *const YFEnvItemIdCluster;
FOUNDATION_EXPORT NSString *const YFEnvItemIdSaas;
FOUNDATION_EXPORT NSString *const YFEnvItemIdIsolation;
FOUNDATION_EXPORT NSString *const YFEnvItemIdVersion;
FOUNDATION_EXPORT NSString *const YFEnvItemIdResult;
FOUNDATION_EXPORT NSString *const YFEnvItemIdElb;
FOUNDATION_EXPORT NSString *const YFEnvItemIdSave;
FOUNDATION_EXPORT NSNotificationName const HCTEnvPanelDidSaveNotification;

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：构建 DebugPannel 页面所需的区块与配置能力。
@interface HCTEnvPanelBuilder : NSObject <YFDebugPannelProtocol>
/// 构建默认的面板区块（环境配置 + 配置区块）。
+ (NSArray<YFEnvSection *> *)buildSections;
/// 快速构建默认的 DebugPannel 页面控制器。
+ (UIViewController *)buildPanelViewController;
/// 建立 itemId -> item 的索引（跨 section）。
+ (NSDictionary<NSString *, YFCellItem *> *)indexItemsByIdFromSections:(NSArray<YFEnvSection *> *)sections;
/// 对所有区块执行 recompute 刷新。
+ (void)refreshSections:(NSArray<YFEnvSection *> *)sections;
/// 根据区块配置构建环境配置模型。
+ (HCEnvConfig *)configFromSections:(NSArray<YFEnvSection *> *)sections;
/// 绑定保存按钮行为并在保存后触发回调。
+ (void)configureSaveActionForSections:(NSArray<YFEnvSection *> *)sections onSave:(dispatch_block_t)onSave;
/// 更新保存按钮可见状态。
+ (void)updateSaveItemVisibilityInSections:(NSArray<YFEnvSection *> *)sections;
/// 捕获当前状态用于后续对比。
+ (void)captureBaselineForSections:(NSArray<YFEnvSection *> *)sections;
@end
