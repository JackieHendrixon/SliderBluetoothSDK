//
//  Log.swift
//  
//
//  Created by Frankie on 09/03/2022.
//

import Foundation

func log(message: String, type: Logger.LogType) {
    Logger.log(message: message, type: type)
}

func log(error: Error) {
    Logger.log(message: error.localizedDescription, type: .error)
}

final class Logger {

    static var verbose = true

    static func log(message: String, type: LogType) {
        guard verbose || type == .success || type == .error else {
            return
        }
        var result = "\(type.icon) "
        result += "[SliderBLE] "
        result += message
        print(result)
    }
}

extension Logger {

    enum LogType {
        case info
        case success
        case warning
        case error

        var icon: String {
            switch self {
            case .info:
                return "⚪️"
            case .success:
                return "🟢"
            case .warning:
                return "🟡"
            case .error:
                return "🔴"
            }
        }
    }

}
