//
//  ViewController.swift
//  Convertor
//
//  Created by Alexandr Arsenyuk on 26.10.2020.
//

import Cocoa
import XMLCoder
import SwiftyXML

enum ViewType {
    case storyboard
    case xib
}

class ViewController: NSViewController, DropViewDelegate {
    
    @IBOutlet weak var leftDropView: DropView!
    @IBOutlet weak var leftLabel: NSTextField!
    
    @IBOutlet weak var rightDropView: NSView!
    @IBOutlet weak var rightLabel: NSTextField!
    
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var chooseProjectButton: NSButton!
    
    private var fileText = ""
    private var sourceCode = ""
    private var fileURL: URL?
    private var parsedText = ""
    private var models: StagedModels = []
    private var filesInProjects: [URL] = []
    private var isProject = false
    private var projectSourceURL: URL?
    private var contentsFile: [String: String] = [:]
    
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
        if !isProject {
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
        } else {
           print("Saved")
        }
    }
    
    private func chooseProjectButtonPressed() {
        let dialog = NSOpenPanel();

        dialog.title = "Choose a file| Our Code World";
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) {
                projectSourceURL = result
                let savePanel = NSSavePanel()
                savePanel.canCreateDirectories = true
                savePanel.showsTagField = true
                savePanel.nameFieldStringValue = "SwiftUIProject"
                savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
                savePanel.begin { [self] (saveResult) in
                    if saveResult.rawValue == NSApplication.ModalResponse.OK.rawValue {
                        let filename = savePanel.url
                        do {
                            try FileManager.default.copyItem(atPath: projectSourceURL!.path, toPath: filename!.path)
                            
                        } catch let error {
                            print("error: \(error)")
                        }
                        let enumerator = FileManager.default.enumerator(at: filename!, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
                        for case let fileURL as URL in enumerator! {
                            do {
                                let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                                if fileAttributes.isRegularFile! {
                                    filesInProjects.append(fileURL)
                                }
                            } catch { print(error, fileURL) }
                        }
                        isProject = true
                        
                        filesInProjects
                            .filter {
                                ($0.lastPathComponent.contains(".xib")  || $0.lastPathComponent.contains(".storyboard"))
                                    && !$0.lastPathComponent.contains("LaunchScreen")
                            }
                            .forEach {
                                print($0.path)
                                handlePath(path: $0.path)
                            }
                        self.convertProject()
                    }
                }
            }
        } else {
            return
        }
    }
    
    private func convertProject() {
        let infoPlistPath = filesInProjects.filter {
            ($0.lastPathComponent.contains("Info.plist"))
        }.first!.path
        
        var dict = NSMutableDictionary(contentsOfFile: infoPlistPath)
        (((dict!["UIApplicationSceneManifest"] as! NSMutableDictionary)["UISceneConfigurations"] as! NSMutableDictionary)["UIWindowSceneSessionRoleApplication"] as! [NSMutableDictionary]).first!["UISceneStoryboardFile"] = nil
        dict!["UIMainStoryboardFile"] = nil
        dict?.write(toFile: infoPlistPath, atomically: true)
        
        let sceneDelagtePath = filesInProjects.filter {
            ($0.lastPathComponent.contains("SceneDelegate.swift"))
        }.first!.path
        
        let initialVCURL = filesInProjects.filter {
            ($0.lastPathComponent.contains(".storyboard") && !$0.lastPathComponent.contains("LaunchScreen"))
        }.first!
        try! ElementGenerator.shared.createSceneDelegate(nameOfFile: String(initialVCURL.lastPathComponent.dropLast(11)))
            .write(toFile: sceneDelagtePath, atomically: true, encoding: .utf8)
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
    
    @IBAction func chooseProjectButtonTapped(_ sender: Any) {
        chooseProjectButtonPressed()
    }
    
    var depth = 0
    var depthIndent: String {
        return [String](repeating: "  ", count: self.depth).joined()
    }
    
    func handlePath(path: String) {
        fileText = ""
        sourceCode = ""
        guard let url = URL(string: path) else { return }
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
            ElementGenerator.shared.generateHeader(
                fileName: String(url.lastPathComponent.dropLast(11))
            )
        )
        
        fileText.append(
            ElementGenerator.shared.generateTemplate(
                fileName: String(url.lastPathComponent.dropLast(11)), completion: {
                    return beginParsing()
                }
            )
        )
        contentsFile[path] = fileText
    }

    // MARK: - Драг'n'дроп делегат
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }
        handlePath(path: path)
        return true
    }
    
    private func beginParsing() -> String {
        let xml = XML(string: sourceCode, encoding: .utf8)
        let elementType: ViewType = xml.scenes.xml == nil ? .xib : .storyboard
        guard let soucrseXML = xml.scenes.xml ?? xml.objects.xml else { return "Error" }
        getXmlChildrens(for: soucrseXML, level: 0, rootId: nil)
        return
            generateSwiftUIStruct(with: 0, rootId: nil, elementType: elementType)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .filter{!$0.isEmpty}.joined(separator: "\n")
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
            } else if children.xmlName == "scene" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.objects.xml!, level: level + 1, rootId: id)
            } else if children.xmlName == "viewController" {
                let id = getInfoAboutXML(children, level: level, rootId: rootId)
                getXmlChildrens(for: children.view.subviews.xml!, level: level + 1, rootId: id)
            } else {
                getInfoAboutXML(children, level: level, rootId: rootId)
            }
        }
    }
    
    func getInfoAboutXML(_ xml: XML, level: Int, rootId: UUID?) -> UUID {
        let model = StagedModel(xml: xml, level: level, rootId: rootId)
        models.append(model)
        if xml.customClass != nil {
//            print(xml.customClass!)
        }
        return model.id
    }
    
    
    // MARK: - Рекурсивно пройтись по моделям и сгенировать SwiftUI структуру
    
    func generateSwiftUIStruct(with nestedIndex: Int, rootId: UUID?, elementType: ViewType) -> String {
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
                        insertingText: generateSwiftUIStruct(
                            with: nestedIndex + 1,
                            rootId: element.id,
                            elementType: elementType
                        ),
                        spaces: element.level,
                        elementType: elementType
                    )
                )
            })
            return result
        }
        return ""
    }
 
}
