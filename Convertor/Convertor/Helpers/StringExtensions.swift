//
//  StringExtensions.swift
//  Convertor
//
//  Created by Александр Арсенюк on 25.05.2021.
//

import Foundation

extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}
