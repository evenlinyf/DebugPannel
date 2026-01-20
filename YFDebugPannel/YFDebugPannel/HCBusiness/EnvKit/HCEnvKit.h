/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境配置模型与工具类声明。
#import <Foundation/Foundation.h>

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境类型枚举，用于区分线上、UAT、DEV 配置。
typedef NS_ENUM(NSInteger, HCEnvType) {
    /// 线上环境。
    HCEnvTypeRelease,
    /// UAT 环境。
    HCEnvTypeUat,
    /// DEV 环境。
    HCEnvTypeDev,
    /// 自定义环境
    HCEnvTypeCustom,
};

FOUNDATION_EXPORT NSNotificationName const HCEnvKitConfigDidChangeNotification;

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：保存环境配置的实体，供构建生效结果与持久化使用。
@interface HCEnvConfig : NSObject <NSCopying>
/// 当前环境类型（线上、UAT、DEV）。
@property (nonatomic, assign) HCEnvType envType;
/// 环境编号（集群编号），用于拼接 UAT/DEV 域名。
@property (nonatomic, assign) NSInteger clusterIndex;
/// 隔离参数，用于灰度或隔离请求。
@property (nonatomic, copy) NSString *isolation;
/// Saas 环境标识，用于外部切换 Saas 相关配置。
@property (nonatomic, copy) NSString *saas;
/// 版本号，可为空；为空时域名不拼接版本号。
@property (nonatomic, copy) NSString *version;
/// 自定义生效域名，设置后覆盖自动拼接的结果。
@property (nonatomic, copy) NSString *customBaseURL;
@end

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：根据配置计算后的展示结果，用于 UI 展示与生效域名输出。
@interface HCEnvBuildResult : NSObject
/// 生效的域名地址（可为自定义覆盖值）。
@property (nonatomic, copy) NSString *baseURL;
/// 显示名称（如 uat-1 / dev-2 / 线上）。
@property (nonatomic, copy) NSString *displayName;
/// 隔离参数回显。
@property (nonatomic, copy) NSString *isolation;
/// Saas 环境回显。
@property (nonatomic, copy) NSString *saas;
@end

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境配置读取、保存与结果构建的工具类。
@interface HCEnvKit : NSObject
/// 读取当前已保存的环境配置。
+ (HCEnvConfig *)currentConfig;
/// 保存环境配置并广播变更通知。
+ (void)saveConfig:(HCEnvConfig *)config;
/// 根据配置构建生效结果。
+ (HCEnvBuildResult *)buildResult:(HCEnvConfig *)config;
@end
