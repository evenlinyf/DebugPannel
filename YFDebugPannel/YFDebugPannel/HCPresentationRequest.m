#import "HCPresentationRequest.h"

@implementation HCPresentationAction

+ (instancetype)actionWithTitle:(NSString *)title value:(nullable NSString *)value {
    HCPresentationAction *action = [[HCPresentationAction alloc] init];
    action.title = title;
    action.value = value;
    return action;
}

@end

@implementation HCPresentationRequest

+ (instancetype)toastWithMessage:(NSString *)message {
    HCPresentationRequest *request = [[HCPresentationRequest alloc] init];
    request.type = HCPresentationTypeToast;
    request.title = message;
    request.actions = @[];
    return request;
}

+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<HCPresentationAction *> *)actions {
    HCPresentationRequest *request = [[HCPresentationRequest alloc] init];
    request.type = HCPresentationTypeAlert;
    request.title = title;
    request.message = message;
    request.actions = actions ?: @[];
    return request;
}

+ (instancetype)actionSheetWithTitle:(NSString *)title message:(nullable NSString *)message actions:(NSArray<HCPresentationAction *> *)actions {
    HCPresentationRequest *request = [[HCPresentationRequest alloc] init];
    request.type = HCPresentationTypeActionSheet;
    request.title = title;
    request.message = message;
    request.actions = actions ?: @[];
    return request;
}

@end
