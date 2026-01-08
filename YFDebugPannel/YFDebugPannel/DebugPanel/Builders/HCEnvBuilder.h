/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境配置区块构建器声明。
#import <Foundation/Foundation.h>

@class HCEnvSection;
@class HCCellItem;

FOUNDATION_EXPORT NSString *const HCEnvItemIdEnvType;
FOUNDATION_EXPORT NSString *const HCEnvItemIdCluster;
FOUNDATION_EXPORT NSString *const HCEnvItemIdSaas;
FOUNDATION_EXPORT NSString *const HCEnvItemIdIsolation;
FOUNDATION_EXPORT NSString *const HCEnvItemIdVersion;
FOUNDATION_EXPORT NSString *const HCEnvItemIdResult;
FOUNDATION_EXPORT NSString *const HCEnvItemIdElb;

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：构建环境配置面板的 section 与 item。
@interface HCEnvBuilder : NSObject
/// 构建环境配置区块。
+ (HCEnvSection *)buildEnvSection;
/// 构建配置区块。
+ (HCEnvSection *)buildConfigSeciton;
/// 根据 section 建立 item 索引。
+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSection:(HCEnvSection *)section;
@end
