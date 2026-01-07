import Foundation

enum HCPresentationType: Int {
    case alert
    case actionSheet
    case toast
}

final class HCPresentationAction {
    var title: String
    var value: String?

    init(title: String, value: String?) {
        self.title = title
        self.value = value
    }

    static func action(title: String, value: String?) -> HCPresentationAction {
        HCPresentationAction(title: title, value: value)
    }
}

final class HCPresentationRequest {
    var type: HCPresentationType = .toast
    var title: String = ""
    var message: String?
    var actions: [HCPresentationAction] = []

    static func toast(message: String) -> HCPresentationRequest {
        let request = HCPresentationRequest()
        request.type = .toast
        request.title = message
        request.actions = []
        return request
    }

    static func alert(title: String, message: String, actions: [HCPresentationAction]) -> HCPresentationRequest {
        let request = HCPresentationRequest()
        request.type = .alert
        request.title = title
        request.message = message
        request.actions = actions
        return request
    }

    static func actionSheet(title: String, message: String?, actions: [HCPresentationAction]) -> HCPresentationRequest {
        let request = HCPresentationRequest()
        request.type = .actionSheet
        request.title = title
        request.message = message
        request.actions = actions
        return request
    }
}
