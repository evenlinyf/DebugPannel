#import <XCTest/XCTest.h>

#import "HCTBusiness/EnvKit/HCTEnvKit.h"

@interface HCTEnvKitTests : XCTestCase
@end

@implementation HCTEnvKitTests {
    HCTEnvKitConfiguration *_originalConfiguration;
}

- (void)setUp {
    [super setUp];
    _originalConfiguration = [[HCTEnvKit configuration] copy];
}

- (void)tearDown {
    if (_originalConfiguration) {
        [HCTEnvKit setConfiguration:_originalConfiguration];
    }
    [super tearDown];
}

- (void)testConfigByParsingBaseURLMatchesConfiguredTemplates {
    HCTEnvKitConfiguration *configuration = [[HCTEnvKitConfiguration alloc] init];
    configuration.uatTemplate = @"https://uat-%ld-%@.example.net";
    configuration.uatTemplateNoVersion = @"https://uat-%ld.example.net";
    configuration.devTemplate = @"https://dev-%ld-%@.example.net";
    configuration.devTemplateNoVersion = @"https://dev-%ld.example.net";
    configuration.clusterMin = 1;
    configuration.clusterMax = 3;

    [HCTEnvKit setConfiguration:configuration];

    HCEnvConfig *uatConfig = [HCTEnvKit configByParsingBaseURL:@"https://uat-2-v1.example.net/api" saasEnv:@""];
    XCTAssertEqual(uatConfig.envType, HCEnvTypeUat);
    XCTAssertEqual(uatConfig.clusterIndex, 2);
    XCTAssertEqualObjects(uatConfig.version, @"v1");
    XCTAssertEqualObjects(uatConfig.customBaseURL, @"");

    HCEnvConfig *devConfig = [HCTEnvKit configByParsingBaseURL:@"https://dev-3.example.net" saasEnv:@""];
    XCTAssertEqual(devConfig.envType, HCEnvTypeDev);
    XCTAssertEqual(devConfig.clusterIndex, 3);
    XCTAssertEqualObjects(devConfig.version, @"");
    XCTAssertEqualObjects(devConfig.customBaseURL, @"");

    HCEnvConfig *outOfRange = [HCTEnvKit configByParsingBaseURL:@"https://uat-5.example.net" saasEnv:@""];
    XCTAssertEqual(outOfRange.envType, HCEnvTypeCustom);
    XCTAssertEqualObjects(outOfRange.customBaseURL, @"https://uat-5.example.net");
}

@end
