//
//  Slider.swift
//  
//
//  Created by Frankie on 10/03/2022.
//

import Foundation
import UIKit

public protocol Slider {
    func move(_ value: Int16, axis: Axis)
    func changePosition(_ position: Position)
}

final class SliderImpl: Slider {

    let bleService: BLEService

    init(bleService: BLEService) {
        self.bleService = bleService
    }

    func move(_ value: Int16, axis: Axis) {
        let instruction: Instruction
        switch axis {
        case .slide:
            instruction = .moveSlide
        case .pan:
            instruction = .movePan
        case .tilt:
            instruction = .moveTilt
        }

        log(message: "Move \(axis): \(value)", type: .instruction)
        let data = instruction.data + value.data
        bleService.write(value: data)
    }

    func changePosition(_ position: Position) {
        let instruction: Instruction = .changePosition
        let data = instruction.data + position.slide.data + position.pan.data + position.tilt.data
        log(message: "Change position: \(position.description)", type: .instruction)
        bleService.write(value: data)
    }
}


