/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：环境配置 Section 构建与配置映射分类。
#import "HCTEnvPanelBuilder.h"

@interface HCTEnvPanelBuilder (EnvConfig)
+ (YFEnvSection *)buildEnvSection;
+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, YFCellItem *> *)itemsById;
@end
