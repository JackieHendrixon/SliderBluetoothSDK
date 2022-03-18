//
//  Slider.swift
//  
//
//  Created by Frankie on 10/03/2022.
//

import Foundation
import UIKit

public protocol Slider {
    func move(value: Int16, axis: Axis)
}

enum Instructions: UInt8 {
    case move = 0

    var data: Data {
        self.rawValue.data
    }
}

class SliderImpl: Slider {

    let bleManager: BLEManager

    init(bleManager: BLEManager) {
        self.bleManager = bleManager
    }

    func move(value: Int16, axis: Axis) {
        let instruction: Instructions = .move
        print(#function, value, axis)
        let data = instruction.data + value.data
        data.print()
        bleManager._testWrite(value: data)
    }
}

public enum Axis {
    case slide
    case pan
    case tilt
}

extension Int16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Self>.size)
    }
}

extension UInt8 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Self>.size)
    }
}

extension Data {
    func print() {
        forEach {
            Swift.print(String($0, radix: 2))
        }
    }
}

