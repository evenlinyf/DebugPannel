/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板提示展示请求模型实现。
#import "HCPresentationRequest.h"

@implementation HCPresentationAction

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value {
    self = [super init];
    if (self) {
        _title = [title copy];
        _value = [value copy];
    }
    return self;
}

+ (instancetype)actionWithTitle:(NSString *)title value:(NSString *)value {
    return [[HCPresentationAction alloc] initWithTitle:title value:value];
}

@end

@implementation HCPresentationRequest

+ (instancetype)toastWithMessage:(NSString *)message {
    HCPresentationRequest *request = [[HCPresentationRequest alloc] init];
    request.type = HCPresentationTypeToast;
    request.title = message ?: @"";
    request.actions = @[];
    return request;
}

+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<HCPresentationAction *> *)actions {
    HCPresentationRequest *request = [[HCPresentationRequest alloc] init];
    request.type = HCPresentationTypeAlert;
    request.title = title ?: @"";
    request.message = message;
    request.actions = actions ?: @[];
    return request;
}

+ (instancetype)actionSheetWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<HCPresentationAction *> *)actions {
    HCPresentationRequest *request = [[HCPresentationRequest alloc] init];
    request.type = HCPresentationTypeActionSheet;
    request.title = title ?: @"";
    request.message = message;
    request.actions = actions ?: @[];
    return request;
}

@end
