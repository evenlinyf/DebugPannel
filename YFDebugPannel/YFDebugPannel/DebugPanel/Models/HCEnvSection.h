#import <Foundation/Foundation.h>

@class HCCellItem;

@interface HCEnvSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<HCCellItem *> *items;

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<HCCellItem *> *)items;
+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<HCCellItem *> *)items;
@end
