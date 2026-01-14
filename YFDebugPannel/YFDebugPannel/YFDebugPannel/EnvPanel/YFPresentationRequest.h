/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板提示展示请求模型声明。
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YFPresentationType) {
    YFPresentationTypeAlert,
    YFPresentationTypeActionSheet,
    YFPresentationTypeToast
};

@interface YFPresentationAction : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *value;

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value;
+ (instancetype)actionWithTitle:(NSString *)title value:(NSString *)value;
@end

@interface YFPresentationRequest : NSObject
@property (nonatomic, assign) YFPresentationType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSArray<YFPresentationAction *> *actions;

+ (instancetype)toastWithMessage:(NSString *)message;
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<YFPresentationAction *> *)actions;
+ (instancetype)actionSheetWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<YFPresentationAction *> *)actions;
@end
