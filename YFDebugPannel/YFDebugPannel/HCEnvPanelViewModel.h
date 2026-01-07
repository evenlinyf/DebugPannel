#import <Foundation/Foundation.h>

@class HCEnvSection;
@class HCCellItem;
@class HCPresentationRequest;

NS_ASSUME_NONNULL_BEGIN

@interface HCEnvPanelViewModel : NSObject

@property (nonatomic, copy, readonly) NSArray<HCEnvSection *> *sections;

- (HCCellItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSIndexPath *> *)updateItem:(HCCellItem *)item value:(id)value;
- (HCPresentationRequest *)presentationForDisabledItem:(HCCellItem *)item;

@end

NS_ASSUME_NONNULL_END
