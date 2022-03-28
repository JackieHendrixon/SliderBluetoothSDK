//
//  Logger.swift
//  
//
//  Created by Frankie on 09/03/2022.
//

import Foundation
import Combine

func log(message: String, type: Logger.LogType) {
    Logger.log(message: message, type: type)
}

func log(error: Error) {
    Logger.log(message: error.localizedDescription, type: .error)
}

public class Logger {
    public static var loggerPublisher: AnyPublisher<String, Never> {
        loggerSubject.eraseToAnyPublisher()
    }
    private static let loggerSubject = PassthroughSubject<String, Never>()

    static var verbose = true

    static func log(message: String, type: LogType) {
        guard verbose || type == .success || type == .error else {
            return
        }
        var result = "\(type.icon) "
        result += "[SliderBLE] "
        result += message
        print(result)
        loggerSubject.send(result)
    }

}

extension Logger {

    enum LogType {
        case instruction
        case read
        case write
        case info
        case success
        case warning
        case error

        var icon: String {
            switch self {
            case .instruction:
                return "🚂"
            case .read:
                return "📥"
            case .write:
                return "📤"
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
