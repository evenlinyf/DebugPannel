#import <Foundation/Foundation.h>

@class HCEnvSection;
@class HCCellItem;
@class HCEnvConfig;

FOUNDATION_EXPORT NSString *const HCEnvItemIdEnvType;
FOUNDATION_EXPORT NSString *const HCEnvItemIdCluster;
FOUNDATION_EXPORT NSString *const HCEnvItemIdSaas;
FOUNDATION_EXPORT NSString *const HCEnvItemIdIsolation;
FOUNDATION_EXPORT NSString *const HCEnvItemIdVersion;
FOUNDATION_EXPORT NSString *const HCEnvItemIdResult;
FOUNDATION_EXPORT NSString *const HCEnvItemIdElb;

/// 创建时间：2025/03/01
/// 创建人：Codex
/// 用途：构建环境配置面板的 section 与 item。
@interface HCEnvBuilder : NSObject
/// 构建环境配置区块。
+ (HCEnvSection *)buildEnvSection;
/// 构建配置区块。
+ (HCEnvSection *)buildConfigSeciton;
/// 根据 section 建立 item 索引。
+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSection:(HCEnvSection *)section;
/// 根据 item 映射构建环境配置。
+ (HCEnvConfig *)configFromItems:(NSDictionary<NSString *, HCCellItem *> *)itemsById;
@end
