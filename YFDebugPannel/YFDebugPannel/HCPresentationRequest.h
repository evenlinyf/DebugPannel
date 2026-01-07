#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HCPresentationType) {
    HCPresentationTypeAlert,
    HCPresentationTypeActionSheet,
    HCPresentationTypeToast
};

@interface HCPresentationAction : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *value;

+ (instancetype)actionWithTitle:(NSString *)title value:(nullable NSString *)value;

@end

@interface HCPresentationRequest : NSObject

@property (nonatomic, assign) HCPresentationType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, copy) NSArray<HCPresentationAction *> *actions;

+ (instancetype)toastWithMessage:(NSString *)message;
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<HCPresentationAction *> *)actions;
+ (instancetype)actionSheetWithTitle:(NSString *)title message:(nullable NSString *)message actions:(NSArray<HCPresentationAction *> *)actions;

@end

NS_ASSUME_NONNULL_END
