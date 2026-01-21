/// 创建时间：2026/01/21
/// 创建人：Codex
/// 用途：配置 Section 构建分类。
#import "HCTEnvPanelBuilder+ConfigSection.h"

#import "YFEnvSection.h"
#import "YFCellItem.h"

@implementation HCTEnvPanelBuilder (ConfigSection)

+ (YFEnvSection *)buildConfigSection {
    // ELB 开关：常规布尔持久化配置项。
    YFCellItem *elb = [YFCellItem switchItemWithIdentifier:YFEnvItemIdElb
                                                     title:@"Switch: ELB 开关"
                                                  storeKey:@"elbconfig"
                                              defaultValue:@(YES)];
    elb.detail = @"是否开启获取动态域名";

    YFCellItem *action = [YFCellItem actionItemWithIdentifier:@"config.action" title:@"Action" handler:^(YFCellItem * _Nonnull item) {
        NSLog(@"action handled");
    }];

    YFCellItem *ppurl = [YFCellItem stringItemWithIdentifier:@"config.ppurl" title:@"String" storeKey:@"config.string" defaultValue:@""];

    YFCellItem *pickerUrl = [YFCellItem pickerItemWithIdentifier:@"config.pickershd" title:@"Picker" storeKey:@"config.picker" defaultValue:@"" options:@[
        @"A", @"B", @"C"
    ]];

    YFCellItem *infoIt = [YFCellItem infoItemWithIdentifier:@"config.info" title:@"Information" detail:@"Hello world!"];

    NSArray<YFCellItem *> *items = @[elb, action, ppurl, pickerUrl, infoIt];
    return [YFEnvSection sectionWithTitle:@"配置" items:items];
}

@end
