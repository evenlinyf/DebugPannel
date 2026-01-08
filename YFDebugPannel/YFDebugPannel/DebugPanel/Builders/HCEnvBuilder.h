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

@interface HCEnvBuilder : NSObject
+ (HCEnvSection *)buildEnvSection;
+ (HCEnvSection *)buildConfigSeciton;
+ (NSDictionary<NSString *, HCCellItem *> *)indexItemsByIdFromSection:(HCEnvSection *)section;
@end
