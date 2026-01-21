/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：调试面板轻量震动反馈封装。
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YFHapticFeedback : NSObject

+ (void)selectionChanged;
+ (void)impactLight;
+ (void)notificationSuccess;

@end

NS_ASSUME_NONNULL_END
