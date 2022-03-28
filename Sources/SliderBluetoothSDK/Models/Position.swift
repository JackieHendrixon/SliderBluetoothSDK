//
//  Position.swift
//  
//
//  Created by Frankie on 28/03/2022.
//

import Foundation

public struct Position {
    let slide: UInt16
    let pan: UInt16
    let tilt: UInt16

    public init(slide: UInt16,
                pan: UInt16,
                tilt: UInt16) {
        self.slide = slide
        self.pan = pan
        self.tilt = tilt
    }

    var description: String {
        return "slide: \(slide), pan: \(pan), tilt: \(tilt)"
    }
}
