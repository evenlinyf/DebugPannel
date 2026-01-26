/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板构建协议声明。
#import <Foundation/Foundation.h>

@class UIViewController;

@class YFEnvSection;

@protocol YFDebugPannelProtocol <NSObject>
- (NSArray<YFEnvSection *> *)buildSections;
- (void)refreshSections:(NSArray<YFEnvSection *> *)sections;
@optional
@property (nonatomic, weak) UIViewController *panelViewController;
@end
