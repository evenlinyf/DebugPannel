/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：封装 AlertController 创建与展示的工具类。
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YFAlertTextHandler)(NSString *input);
typedef void (^YFAlertOptionHandler)(NSString *option);

@interface YFAlertPresenter : NSObject

+ (UIAlertController *)textInputAlertWithTitle:(nullable NSString *)title
                                      message:(nullable NSString *)message
                                  initialText:(nullable NSString *)initialText
                               confirmHandler:(nullable YFAlertTextHandler)confirmHandler;

+ (UIAlertController *)actionSheetWithTitle:(nullable NSString *)title
                                    message:(nullable NSString *)message
                                    options:(NSArray<NSString *> *)options
                                 sourceView:(UIView *)sourceView
                           selectionHandler:(nullable YFAlertOptionHandler)selectionHandler;

+ (void)presentToastFrom:(UIViewController *)presenter
                 message:(nullable NSString *)message
                duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
