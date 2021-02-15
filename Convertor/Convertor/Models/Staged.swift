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
    var id: UUID = UUID()
    var xml: XML
    var level: Int
    var rootId: UUID?
    
    init (xml: XML, level: Int, rootId: UUID?) {
        self.xml = xml
        self.level = level
        self.rootId = rootId
    }
    
    func getDescription() -> String {
        return "Name: \(xml.xmlName) level: \(level)"//, id: \(id), rootId: \(rootId)"
    }
}
