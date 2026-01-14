/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板提示展示请求模型实现。
#import "YFPresentationRequest.h"

@implementation YFPresentationAction

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value {
    self = [super init];
    if (self) {
        _title = [title copy];
        _value = [value copy];
    }
    return self;
}

+ (instancetype)actionWithTitle:(NSString *)title value:(NSString *)value {
    return [[YFPresentationAction alloc] initWithTitle:title value:value];
}

@end

@implementation YFPresentationRequest

+ (instancetype)toastWithMessage:(NSString *)message {
    YFPresentationRequest *request = [[YFPresentationRequest alloc] init];
    request.type = YFPresentationTypeToast;
    request.title = message ?: @"";
    request.actions = @[];
    return request;
}

+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<YFPresentationAction *> *)actions {
    YFPresentationRequest *request = [[YFPresentationRequest alloc] init];
    request.type = YFPresentationTypeAlert;
    request.title = title ?: @"";
    request.message = message;
    request.actions = actions ?: @[];
    return request;
}

+ (instancetype)actionSheetWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<YFPresentationAction *> *)actions {
    YFPresentationRequest *request = [[YFPresentationRequest alloc] init];
    request.type = YFPresentationTypeActionSheet;
    request.title = title ?: @"";
    request.message = message;
    request.actions = actions ?: @[];
    return request;
}

@end
