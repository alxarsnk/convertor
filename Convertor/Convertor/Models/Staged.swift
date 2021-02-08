//
//  Staged.swift
//  Convertor
//
//  Created by Александр Арсенюк on 15.12.2020.
//

import Foundation
import SwiftyXML

typealias StagedModels = [StagedModel]

class StagedModel {
    var xml: XML
    var level: Int
    
    init (xml: XML, level: Int) {
        self.xml = xml
        self.level = level
    }
}
