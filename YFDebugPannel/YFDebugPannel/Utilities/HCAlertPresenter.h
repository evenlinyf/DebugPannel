/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：封装 AlertController 创建与展示的工具类。
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HCAlertTextHandler)(NSString *input);
typedef void (^HCAlertOptionHandler)(NSString *option);

@interface HCAlertPresenter : NSObject

+ (UIAlertController *)textInputAlertWithTitle:(nullable NSString *)title
                                      message:(nullable NSString *)message
                                  initialText:(nullable NSString *)initialText
                               confirmHandler:(nullable HCAlertTextHandler)confirmHandler;

+ (UIAlertController *)actionSheetWithTitle:(nullable NSString *)title
                                    message:(nullable NSString *)message
                                    options:(NSArray<NSString *> *)options
                                 sourceView:(UIView *)sourceView
                           selectionHandler:(nullable HCAlertOptionHandler)selectionHandler;

+ (void)presentToastFrom:(UIViewController *)presenter
                 message:(nullable NSString *)message
                duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
