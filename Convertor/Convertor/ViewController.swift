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
    
    // MARK: - Настройить UI
    
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
    var views: [String] = [
        "viewController",
        "view",
        "subviews",
        "tableView",
        "tableViewCell",
        "tableViewCellContentView",
        "imageView",
        "label",
        "rect",
        "color",
        "constraints",
        "button",
        "contentMode",
        "segmentedControl",
        "switch",
        "textField",
        "textView",
        "activityIndicatorView",
        "pageControl",
        "collectionView",
        "collectionViewCell",
        "stackView"
    ]

    // MARK: - Драг'n'дроп делегат
    
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
    
    private func beginParsing() -> String {
        let xml = XML(string: sourceCode, encoding: .utf8)
        getXmlChildrens(for: xml.scenes.scene.objects.viewController.view.subviews.xml!, level: 0, rootId: nil)
        print(
            generateSwiftUIStruct(with: 0, rootId: nil)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .filter{!$0.isEmpty}.joined(separator: "\n")
        )
        return "Text(\"Parsing\")"
    }
    
    // MARK: - Рекрурсивно пройтись по XML файлу и сгенирировать промежутчоные модели
    
    func getXmlChildrens(for xml: XML, level: Int, rootId: UUID?) {
        for children in xml.xmlChildren {
            if children.xmlName == "tableView" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.prototypes.xml!, level: level + 1, rootId: id)
            } else if children.xmlName == "tableViewCell" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.tableViewCellContentView.subviews.xml!, level: level + 1, rootId: id)
            } else if children.xmlName == "collectionViewCell" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.collectionViewCellContentView.subviews.xml!, level: level + 1, rootId: id)
            } else if children.xmlName == "collectionView" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.cells.xml!, level: level + 1, rootId: id)
            } else if children.xmlName == "view" || children.xmlName == "stackView" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.subviews.xml!, level: level + 1, rootId: id)
            } else {
                getInfoAboutXML(children, level: level, rootId: rootId)
            }
        }
    }
    
    func getInfoAboutXML(_ xml: XML, level: Int, rootId: UUID?) -> UUID {
        let model = StagedModel(xml: xml, level: level, rootId: rootId)
        models.append(model)
        return model.id
    }
    
    
    // MARK: - Рекурсивно пройтись по моделям и сгенировать SwiftUI структуру
    
    func generateSwiftUIStruct(with nestedIndex: Int, rootId: UUID?) -> String {
        while nestedIndex <= models.count - 1 {
            var result = ""
            var filteredArray = StagedModels()
            if nestedIndex == 0 {
                filteredArray = models.filter({$0.level == nestedIndex})
            } else {
                filteredArray = models.filter({$0.level == nestedIndex && $0.rootId == rootId})
            }
            filteredArray.forEach({ element in
                result.append(
                    ElementGenerator.shared.generateElement(
                        from: element.xml,
                        insertingText: generateSwiftUIStruct(with: nestedIndex + 1, rootId: element.id),
                        spaces: element.level
                    )
                )
            })
            return result
        }
        return ""
    }
 
    // MARK: - Методы вспомогательные для генерации
    
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
}
