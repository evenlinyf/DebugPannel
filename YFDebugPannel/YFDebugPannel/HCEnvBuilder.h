#import <Foundation/Foundation.h>

@class HCEnvSection;
@class HCCellItem;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const HCEnvItemIdEnvType;
FOUNDATION_EXPORT NSString * const HCEnvItemIdCluster;
FOUNDATION_EXPORT NSString * const HCEnvItemIdIsolation;
FOUNDATION_EXPORT NSString * const HCEnvItemIdVersion;
FOUNDATION_EXPORT NSString * const HCEnvItemIdResult;

@interface HCEnvBuilder : NSObject

+ (HCEnvSection *)buildEnvSection;
+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSection:(HCEnvSection *)section;

@end

NS_ASSUME_NONNULL_END
