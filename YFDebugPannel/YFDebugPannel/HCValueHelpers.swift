import Foundation

func intValue(_ value: Any?) -> Int {
    if let value = value as? Int {
        return value
    }
    if let value = value as? NSNumber {
        return value.intValue
    }
    if let value = value as? String, let number = Int(value) {
        return number
    }
    return 0
}

func boolValue(_ value: Any?) -> Bool {
    if let value = value as? Bool {
        return value
    }
    if let value = value as? NSNumber {
        return value.boolValue
    }
    if let value = value as? String {
        return (value as NSString).boolValue
    }
    return false
}
