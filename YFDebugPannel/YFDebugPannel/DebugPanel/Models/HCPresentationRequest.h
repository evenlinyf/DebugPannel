#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HCPresentationType) {
    HCPresentationTypeAlert,
    HCPresentationTypeActionSheet,
    HCPresentationTypeToast
};

@interface HCPresentationAction : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *value;

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value;
+ (instancetype)actionWithTitle:(NSString *)title value:(NSString *)value;
@end

@interface HCPresentationRequest : NSObject
@property (nonatomic, assign) HCPresentationType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSArray<HCPresentationAction *> *actions;

+ (instancetype)toastWithMessage:(NSString *)message;
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<HCPresentationAction *> *)actions;
+ (instancetype)actionSheetWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<HCPresentationAction *> *)actions;
@end
