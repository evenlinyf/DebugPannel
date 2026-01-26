/// 创建时间：2026/01/22
/// 创建人：Codex
/// 用途：环境配置系统使用的基础配置项集合。
#import <Foundation/Foundation.h>

@interface HCTEnvKitConfiguration : NSObject <NSCopying>
/// 线上环境基准 URL。
@property (nonatomic, copy) NSString *releaseBaseURL;
/// UAT URL 模板（带版本号）。
@property (nonatomic, copy) NSString *uatTemplate;
/// UAT URL 模板（不带版本号）。
@property (nonatomic, copy) NSString *uatTemplateNoVersion;
/// DEV URL 模板（带版本号）。
@property (nonatomic, copy) NSString *devTemplate;
/// DEV URL 模板（不带版本号）。
@property (nonatomic, copy) NSString *devTemplateNoVersion;
/// 集群编号最小值。
@property (nonatomic, assign) NSInteger clusterMin;
/// 集群编号最大值。
@property (nonatomic, assign) NSInteger clusterMax;
/// 默认自定义环境历史记录。
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *defaultCustomHistoryEntries;
/// 自定义历史记录最大保留数量。
@property (nonatomic, assign) NSInteger customHistoryLimit;
@end
