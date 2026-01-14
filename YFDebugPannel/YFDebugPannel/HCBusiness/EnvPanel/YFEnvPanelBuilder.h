/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 Builder，对外提供快速构建能力。
#import <Foundation/Foundation.h>

#import "YFDebugPannelProtocol.h"

@class YFCellItem;
@class HCEnvConfig;
@class YFEnvSection;
@class UIViewController;
@class YFEnvPanelChangeSnapshot;

FOUNDATION_EXPORT NSString *const YFEnvItemIdSave;
FOUNDATION_EXPORT NSNotificationName const YFEnvPanelDidSaveNotification;

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：构建 DebugPannel 页面所需的区块与配置能力。
@interface YFEnvPanelBuilder : NSObject <YFDebugPannelProtocol>
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
/// 生成当前区块快照，用于判断是否有待保存的变更。
+ (YFEnvPanelChangeSnapshot *)changeSnapshotFromSections:(NSArray<YFEnvSection *> *)sections;
/// 判断当前区块与快照是否存在差异。
+ (BOOL)sections:(NSArray<YFEnvSection *> *)sections differFromSnapshot:(YFEnvPanelChangeSnapshot *)snapshot;
/// 绑定保存按钮行为并在保存后触发回调。
+ (void)configureSaveActionForSections:(NSArray<YFEnvSection *> *)sections onSave:(dispatch_block_t)onSave;
/// 更新保存按钮可见状态。
+ (void)updateSaveItemVisibilityInSections:(NSArray<YFEnvSection *> *)sections;
/// 捕获当前快照用于后续对比。
+ (void)captureBaselineForSections:(NSArray<YFEnvSection *> *)sections;
@end

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：记录面板配置的快照。
@interface YFEnvPanelChangeSnapshot : NSObject
@property (nonatomic, strong, readonly) HCEnvConfig *config;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *storeValues;
- (instancetype)initWithConfig:(HCEnvConfig *)config storeValues:(NSDictionary<NSString *, id> *)storeValues;
@end
