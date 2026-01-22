/// 创建时间：2026/01/22
/// 创建人：Codex
/// 用途：环境配置系统使用的基础配置项实现。
#import "HCTEnvKitConfiguration.h"

@implementation HCTEnvKitConfiguration

static NSArray<NSDictionary<NSString *, NSString *> *> *HCTEnvKitDefaultCustomHistoryEntries(void) {
    return @[
        @{
            @"baseURL" : @"https://custom-uat.example.com",
            @"saas" : @"hpc-uat-1"
        },
        @{
            @"baseURL" : @"https://custom-dev.example.com",
            @"saas" : @"hpc-uat-2"
        }
    ];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _releaseBaseURL = @"https://release.example.com";
        _uatTemplate = @"https://uat-%ld-%@.example.com";
        _uatTemplateNoVersion = @"https://uat-%ld.example.com";
        _devTemplate = @"https://dev-%ld-%@.example.com";
        _devTemplateNoVersion = @"https://dev-%ld.example.com";
        _clusterMin = 1;
        _clusterMax = 30;
        _saasPrefix = @"hpc-uat-";
        _defaultCustomHistoryEntries = HCTEnvKitDefaultCustomHistoryEntries();
        _customHistoryLimit = 20;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    HCTEnvKitConfiguration *copy = [[[self class] allocWithZone:zone] init];
    copy.releaseBaseURL = self.releaseBaseURL;
    copy.uatTemplate = self.uatTemplate;
    copy.uatTemplateNoVersion = self.uatTemplateNoVersion;
    copy.devTemplate = self.devTemplate;
    copy.devTemplateNoVersion = self.devTemplateNoVersion;
    copy.clusterMin = self.clusterMin;
    copy.clusterMax = self.clusterMax;
    copy.saasPrefix = self.saasPrefix;
    copy.defaultCustomHistoryEntries = self.defaultCustomHistoryEntries;
    copy.customHistoryLimit = self.customHistoryLimit;
    return copy;
}

@end
