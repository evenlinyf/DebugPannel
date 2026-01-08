/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板 ViewModel 声明。
#import <Foundation/Foundation.h>

@class HCEnvSection;
@class HCCellItem;
@class HCPresentationRequest;

/// 创建时间：2026/01/08
/// 创建人：Codex
/// 用途：环境面板的 ViewModel，负责数据驱动与联动刷新。
@interface HCEnvPanelViewModel : NSObject
/// 当前面板包含的 section 列表（只读）。
@property (nonatomic, copy, readonly) NSArray<HCEnvSection *> *sections;

- (HCCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSIndexPath *> *)updateItem:(HCCellItem *)item value:(id)value;
- (HCPresentationRequest *)presentationForDisabledItem:(HCCellItem *)item;
@end
