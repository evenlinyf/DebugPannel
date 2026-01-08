#import "HCValueHelpers.h"

NSInteger HCIntValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value integerValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return 0;
}

BOOL HCBoolValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [(NSString *)value boolValue];
    }
    return NO;
}
