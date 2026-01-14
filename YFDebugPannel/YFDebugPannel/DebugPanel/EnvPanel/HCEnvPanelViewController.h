/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板主页面控制器声明。
#import <UIKit/UIKit.h>

@protocol HCEnvPanelBuilding;

@interface HCEnvPanelViewController : UIViewController
- (instancetype)initWithBuilder:(id<HCEnvPanelBuilding>)builder;
@end
