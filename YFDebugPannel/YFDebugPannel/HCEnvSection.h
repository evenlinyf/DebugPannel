#import <Foundation/Foundation.h>

@class HCCellItem;

NS_ASSUME_NONNULL_BEGIN

@interface HCEnvSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<HCCellItem *> *items;

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<HCCellItem *> *)items;

@end

NS_ASSUME_NONNULL_END
