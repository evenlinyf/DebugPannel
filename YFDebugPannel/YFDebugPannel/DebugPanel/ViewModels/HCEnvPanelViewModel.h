#import <Foundation/Foundation.h>

@class HCEnvSection;
@class HCCellItem;
@class HCPresentationRequest;

@interface HCEnvPanelViewModel : NSObject
@property (nonatomic, copy, readonly) NSArray<HCEnvSection *> *sections;

- (HCCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSIndexPath *> *)updateItem:(HCCellItem *)item value:(id)value;
- (HCPresentationRequest *)presentationForDisabledItem:(HCCellItem *)item;
@end
