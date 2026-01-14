/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：调试面板分组 section 模型声明。
#import <Foundation/Foundation.h>

@class YFCellItem;

@interface YFEnvSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<YFCellItem *> *items;

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<YFCellItem *> *)items;
+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<YFCellItem *> *)items;
@end
