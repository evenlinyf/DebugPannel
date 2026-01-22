/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：环境配置 Section 构建与配置映射分类。
#import "HCTEnvPanelBuilder.h"

@interface HCTEnvPanelBuilder (EnvConfig)
FOUNDATION_EXPORT NSString *const HCTEnvHistoryBaseURLKey;
FOUNDATION_EXPORT NSString *const HCTEnvHistorySaasKey;

+ (YFEnvSection *)buildEnvSection;
+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById;
/// 绑定保存按钮行为并在保存后触发回调。
+ (void)configureSaveActionForSections:(NSArray<YFEnvSection *> *)sections onSave:(dispatch_block_t)onSave;
/// 更新保存按钮可见状态。
+ (void)updateSaveItemVisibilityInSections:(NSArray<YFEnvSection *> *)sections;
/// 捕获当前状态用于后续对比。
+ (void)captureBaselineForSections:(NSArray<YFEnvSection *> *)sections;
/// 根据区块配置构建环境配置模型。
+ (HCEnvConfig *)configFromSections:(NSArray<YFEnvSection *> *)sections;
/// 获取自定义环境历史记录。
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)customHistoryEntries;
/// 保存当前自定义环境到历史记录。
+ (BOOL)appendCustomHistoryFromConfig:(HCEnvConfig *)config;

@end
