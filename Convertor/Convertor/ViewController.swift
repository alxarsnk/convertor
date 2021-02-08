//
//  ViewController.swift
//  Convertor
//
//  Created by Alexandr Arsenyuk on 26.10.2020.
//

import Cocoa
import XMLCoder
import SwiftyXML

class ViewController: NSViewController, DropViewDelegate {
    
    @IBOutlet weak var leftDropView: DropView!
    @IBOutlet weak var leftLabel: NSTextField!
    
    @IBOutlet weak var rightDropView: NSView!
    @IBOutlet weak var rightLabel: NSTextField!
    
    @IBOutlet weak var saveButton: NSButton!
    
    private var fileText = ""
    private var sourceCode = ""
    private var fileURL: URL?
    private var parsedText = ""
    private var models: StagedModels = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels()
        setupDropViews()
        saveButton.title = "Save"
        saveButton.contentTintColor = .white
        saveButton.layer?.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        saveButton.isHidden = true
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func setupLabels() {
        leftLabel.alignment = .center
        rightLabel.alignment = .center
    }
    
    private func setupDropViews() {
        rightDropView.wantsLayer = true
        rightDropView.layer?.backgroundColor = NSColor.gray.cgColor
        leftDropView.delegate = self
    }
    
    private func saveButtonPressed() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = true
        savePanel.allowedFileTypes = ["swift"]
        savePanel.allowsOtherFileTypes = false
        savePanel.nameFieldStringValue = "generated"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let filename = savePanel.url
                do {
                    try self.fileText.write(to: filename!, atomically: true, encoding: String.Encoding.utf8)
                } catch let error {
                    print("error: \(error)")
                }
            }
        }
    }
    
    private func setupCOnvertedReadyState() {
        rightLabel.isHidden = true
        saveButton.isHidden = false
        let imageView = NSImageView(frame: leftDropView.frame)
        imageView.image = #imageLiteral(resourceName: "swiftFIleIcon")
        imageView.imageAlignment = .alignCenter
        rightDropView.addSubview(imageView)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        saveButtonPressed()
    }
    
    var depth = 0
    var depthIndent: String {
        return [String](repeating: "  ", count: self.depth).joined()
    }
    var views: [String] = ["viewController", "view", "subviews", "tableView", "tableViewCell", "tableViewCellContentView", "imageView", "label", "rect", "color", "constraints"]

    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String,
              let url = URL(string: path)
        else { return false }
        fileURL = url
        leftLabel.stringValue = url.lastPathComponent
        let imageView = NSImageView(frame: leftDropView.frame)
        imageView.image = #imageLiteral(resourceName: "storyboardFileIcon")
        imageView.imageAlignment = .alignCenter
        leftDropView.addSubview(imageView)
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            while let line = aStreamReader.nextLine() {
                sourceCode.append(line + "\n")
            }
            setupCOnvertedReadyState()
        }
        fileText.append(
            generateHeader(
                fileName: String(url.lastPathComponent.dropLast(11))
            )
        )
        
        fileText.append(
            generateTemplate(
                fileName: String(url.lastPathComponent.dropLast(11))
            )
        )
        return true
    }
    
    private func generateHeader(fileName: String) -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return """
            //
            //  \(fileName).swift
            //
            //  Created by Convertor on \(formatter.string(from: date)).
            //  Copyright © 2020 Personal Team. All rights reserved.
            //\n
            """
    }
    
    private func generateTemplate(fileName: String) -> String {
        return """
            import SwiftUI

            struct \(fileName): View {
                var body: some View {
                    \(beginParsing())
                }
            }

            struct \(fileName)_Previews: PreviewProvider {
                static var previews: some View {
                    \(fileName)()
                }
            }
            """
    }
    
    private func beginParsing() -> String {
        let xml = XML(string: sourceCode, encoding: .utf8)
        getXmlChildrens(for: xml.scenes.scene.objects.viewController.view.subviews.xml!, level: 0)
        print(generateSwiftUIStruct(with: 0))
        return "Text(\"Parsing\")"
    }
    
    func getXmlChildrens(for xml: XML, level: Int) {
        for children in xml.xmlChildren {
            if children.xmlName == "tableView" {
                getInfoAboutXML(children, level: level)
                getXmlChildrens(for: children.prototypes.xml!, level: level)
            } else if children.xmlName == "tableViewCell" {
                let lvl = level + 1
                getInfoAboutXML(children, level: lvl)
                getXmlChildrens(for: children.tableViewCellContentView.subviews.xml!, level: lvl)
            } else {
                let lvl = level + 1
                getInfoAboutXML(children, level: lvl)
            }
        }
    }
    
    func getInfoAboutXML(_ xml: XML, level: Int) {
        models.append(StagedModel(xml: xml, level: level))
    }
    
    func generateSwiftUIStruct(with index: Int) -> String {
        while index <= models.count - 1 {
                return generateElement(
                    from: ElementType(rawValue: models[index].xml.xmlName)!,
                    insertingText: generateSwiftUIStruct(with: index + 1),
                    spaces: models[index].level
                )
        }
        return ""
    }
 
    private func generateElement(from element: ElementType, insertingText: String, spaces: Int) -> String {
        switch element {
        case .tableView:
            return generateTableView(insertingText: insertingText, spaces: spaces)
        case .imageView:
            return generateImageView(insertingText: insertingText, spaces: spaces)
        case .label:
            return generateLabel(insertingText: insertingText, spaces: spaces)
        case .tableViewCell:
            return generateVStack(insertingText: insertingText, spaces: spaces)
        }
    }
    
    private func generateTableView(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)List(0..<10) { _ in
            \(insertingText)
            \(spacesString)
            """
    }
    
    private func generateHStack(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)HStack() {
            \(insertingText)
            \(spacesString)}
            """
    }
    
    private func generateVStack(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)VStack() {
            \(insertingText)
            \(spacesString)}
            """
    }
    
    private func generateLabel(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText == "" ? insertingText : "\n"+insertingText
        return
            """
            \(spacesString)Text("")\(text)
            """
    }
    
    private func generateImageView(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText == "" ? insertingText : "\n"+insertingText
        return
            """
            \(spacesString)Image()\(text)
            """
    }
    
}
