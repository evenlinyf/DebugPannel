/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板基础信息模型声明。
#import <Foundation/Foundation.h>

@interface DebugPanelInfo : NSObject
@property (nonatomic, copy, readonly) NSString *appName;
@property (nonatomic, copy, readonly) NSString *buildNumber;
@property (nonatomic, copy, readonly) NSString *displayText;

- (instancetype)initWithAppName:(NSString *)appName buildNumber:(NSString *)buildNumber;
+ (instancetype)current;
@end
