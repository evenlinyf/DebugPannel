/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：封装 AlertController 创建与展示的工具类。
#import "YFAlertPresenter.h"

@implementation YFAlertPresenter

+ (UIAlertController *)textInputAlertWithTitle:(NSString *)title
                                      message:(NSString *)message
                                  initialText:(NSString *)initialText
                               confirmHandler:(YFAlertTextHandler)confirmHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        if (initialText.length > 0) {
            textField.text = initialText;
        }
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        if (confirmHandler) {
            confirmHandler(text);
        }
    }]];
    return alert;
}

+ (UIAlertController *)actionSheetWithTitle:(NSString *)title
                                    message:(NSString *)message
                                    options:(NSArray<NSString *> *)options
                                 sourceView:(UIView *)sourceView
                           selectionHandler:(YFAlertOptionHandler)selectionHandler {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *option in options ?: @[]) {
        [sheet addAction:[UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            if (selectionHandler) {
                selectionHandler(option);
            }
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = sourceView;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(sourceView.bounds), CGRectGetMidY(sourceView.bounds), 1, 1);
    }
    return sheet;
}

+ (void)presentToastFrom:(UIViewController *)presenter
                 message:(NSString *)message
                duration:(NSTimeInterval)duration {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [presenter presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

@end
