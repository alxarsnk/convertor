//
//  PanelWorker.swift
//  Convertor
//
//  Created by Александр Арсенюк on 23.06.2021.
//

import Foundation
import Cocoa

class PanelWorker {
    
    var originlProjectURL: URL?
    var saveProjectPathURL: URL?
    
    static let shared = PanelWorker()
    
    private init() { }
    
    func showSavePanel(file: File) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = true
        savePanel.allowedFileTypes = ["swift"]
        savePanel.allowsOtherFileTypes = false
        savePanel.nameFieldStringValue = file.fileName
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let filename = savePanel.url
                do {
                    try file.generatedContent.write(to: filename!, atomically: true, encoding: String.Encoding.utf8)
                } catch let error {
                    print("error: \(error)")
                }
            }
        }
    }
    
    func showChoseProjectPanel(completion: @escaping (()->Void)) {
        let dialog = NSOpenPanel();
        
        dialog.title = "Choose a file or project";
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        
        guard (dialog.runModal() ==  NSApplication.ModalResponse.OK) else { return }
        let result = dialog.url
        guard result != nil else { return }
        originlProjectURL = result
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = true
        savePanel.nameFieldStringValue = "SwiftUIProject"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        savePanel.begin { [weak self] (saveResult) in
            guard saveResult.rawValue == NSApplication.ModalResponse.OK.rawValue else { return }
            self?.saveProjectPathURL = savePanel.url
            completion()
        }
    }
    
}
