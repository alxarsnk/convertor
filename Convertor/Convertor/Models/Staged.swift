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

extension XML {
    
    var rect: CGRect? {
        get {
            if let rect = self.xmlChildren.first(where: {$0.xmlName == "rect"}),
               let x = Double(rect.xmlAttributes["x"] ?? ""),
               let y = Double(rect.xmlAttributes["y"] ?? ""),
               let width = Double(rect.xmlAttributes["width"] ?? ""),
               let height = Double(rect.xmlAttributes["height"] ?? "") {
                return CGRect(x: x, y: y, width: width, height: height)
            } else {
                return nil
            }
        }
    }
    
    var customClass: String? {
        get {
            if let customClass = self.xmlAttributes.first(where: {$0.key == "customClass"}) {
                return customClass.value
            } else {
                return nil
            }
        }
    }
    
}
