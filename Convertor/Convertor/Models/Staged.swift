//
//  Staged.swift
//  Convertor
//
//  Created by Александр Арсенюк on 15.12.2020.
//

import Foundation
import Cocoa
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
        return "Name: \(xml.xmlName) level: \(level)"
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
    
    var buttonImage: String? {
        get {
            if let color = self.xmlChildren.first(where: {$0.xmlName == "state"}),
               let imageName = color.xmlAttributes["image"] {
                return imageName
            } else {
                return nil
            }
        }
    }
    
    var color: NSColor? {
        get {
            if let color = self.xmlChildren.first(where: {$0.xmlName == "color"}),
               let red = Double(color.xmlAttributes["red"] ?? ""),
               let green = Double(color.xmlAttributes["green"] ?? ""),
               let blue = Double(color.xmlAttributes["blue"] ?? ""),
               let alpha = Double(color.xmlAttributes["alpha"] ?? "") {
                return NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
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
