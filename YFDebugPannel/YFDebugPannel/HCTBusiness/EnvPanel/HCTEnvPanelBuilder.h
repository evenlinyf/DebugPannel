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
FOUNDATION_EXPORT NSString *const YFEnvItemIdCustomHistory;
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
/// 传入旧版 baseURL 与 saasEnv 供环境配置初始化解析。
+ (void)prepareLegacyConfigWithBaseURL:(NSString *)baseURL saasEnv:(NSString *)saasEnv;
/// 建立 itemId -> item 的索引（跨 section）。
+ (NSDictionary<NSString *, YFCellItem *> *)indexItemsByIdFromSections:(NSArray<YFEnvSection *> *)sections;
/// 对所有区块执行 recompute 刷新。
+ (void)refreshSections:(NSArray<YFEnvSection *> *)sections;
@end
