//
//  Instruction.swift
//  
//
//  Created by Frankie on 28/03/2022.
//

import Foundation

enum Instruction: UInt8 {
    
    case moveSlide = 11
    case movePan = 12
    case moveTilt = 13

    case changePosition = 21

    var data: Data {
        self.rawValue.data
    }
}
