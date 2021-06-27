//
//  Outlet.swift
//  Convertor
//
//  Created by Александр Арсенюк on 25.06.2021.
//

import Foundation

typealias Outlets = [Outlet]

class Outlet {
    
    var style: String
    var description: String
    var name: String
    var type: String
    var elements: [String]
    var fullString: String
    var id: String = ""
    var insertingText: String = ""
    
    init(string: String) {
        fullString = string
        elements = string
            .split(separator: " ")
            .map{ String($0) }
        style = elements
            .first(where: {$0.contains("@")})?
            .replacingOccurrences(of: "@", with: "") ?? ""
        description = elements
            .filter( { !$0.contains("@") && !$0.contains("!") && !$0.contains(":") } )
            .joined(separator: " ")
        name = elements
            .first(where: {$0.contains(":")})?
            .replacingOccurrences(of: ":", with: "") ?? ""
        type = elements
            .first(where: {$0.contains("!")})?
            .replacingOccurrences(of: "!", with: "") ?? ""
    }
    
    var elementType: String? {
        get {
            ElementType
                .allCases
                .filter({
                    $0.rawValue.lowercased() == type
                        .lowercased()
                        .replacingOccurrences(of: "ui", with: "")
                    
                })
                .first?
                .rawValue
        }
    }
    
}
