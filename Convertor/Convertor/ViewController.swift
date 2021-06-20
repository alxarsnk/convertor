//
//  ViewController.swift
//  Convertor
//
//  Created by Alexandr Arsenyuk on 26.10.2020.
//

import Cocoa
import XMLCoder
import SwiftyXML
import XcodeProj
import PathKit

enum ViewType {
    case storyboard
    case xib
}

class ViewController: NSViewController, DropViewDelegate {
    
    @IBOutlet weak var leftDropView: DropView!
    @IBOutlet weak var leftLabel: NSTextField!
    @IBOutlet weak var leftImageView: NSImageView!
    @IBOutlet weak var rightImageView: NSImageView!
    
    @IBOutlet weak var activityView: NSProgressIndicator!
    @IBOutlet weak var rightDropView: NSView!
    @IBOutlet weak var rightLabel: NSTextField!
    
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var chooseProjectButton: NSButton!
    
    private var fileText = ""
    private var fileName = ""
    private var sourceCode = ""
    private var fileURL: URL?
    private var models: StagedModels = []
    private var filesInProjects: [URL] = []
    private var isProject = false
    private var projectSourceURL: URL?
    private var contentsFile: [String: String] = [:]
    private var newPath: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels()
        setupDropViews()
        saveButton.title = "Save"
        saveButton.isHidden = true
        saveButton.contentTintColor = .white
        saveButton.layer?.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        saveButton.isHidden = true
        activityView.isHidden = true
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
        leftDropView.layer?.backgroundColor = .clear
        rightDropView.layer?.backgroundColor = .clear
        leftDropView.delegate = self
        rightDropView.layer?.cornerRadius = 16
        leftDropView.layer?.cornerRadius = 16
        rightDropView.layer?.borderWidth = 1
        leftDropView.layer?.borderWidth = 1
        rightDropView.layer?.borderColor = NSColor.lightGray.cgColor
        leftDropView.layer?.borderColor = NSColor.lightGray.cgColor
    }
    
    private func saveButtonPressed() {
        if !isProject {
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = true
            savePanel.allowedFileTypes = ["swift"]
            savePanel.allowsOtherFileTypes = false
            savePanel.nameFieldStringValue = fileName
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

        dialog.title = "Choose a file or project";
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
                        newPath = savePanel.url?.path ?? ""
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
                        self.replaceFiles()
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
        var fileName = String(
            String(
                initialVCURL.lastPathComponent.reversed()
            )
            .drop(while: {$0 != "."})
            .reversed()
            .dropLast())
        fileName = "New"+fileName
        try! ElementGenerator.shared.createSceneDelegate(nameOfFile: fileName)
            .write(toFile: sceneDelagtePath, atomically: true, encoding: .utf8)
    }
    
    private func replaceFiles() {
        let files = Path(newPath)
        let project = try? files.children().first(where: {$0.string.contains("xcodeproj")})
        let projFilePath = project?.string.appending("/project.pbxproj") ?? ""
        var projectText: String = ""
        if let aStreamReader = StreamReader(path: projFilePath) {
            defer {
                aStreamReader.close()
            }
            while let line = aStreamReader.nextLine() {
                projectText.append(line + "\n")
            }
        }
        
        contentsFile.forEach {
            var url = URL(string: $0.key)!
            var newURL = URL(string: $0.key)!
            newURL.deletePathExtension()
            newURL = newURL.appendingPathExtension("swift")
            let currFileName = url.lastPathComponent
            
            projectText = projectText.replacingOccurrences(
                of: "\(currFileName) in Resources",
                with: "\(newURL.lastPathComponent) in Sources"
            )
            
            projectText = projectText.replacingOccurrences(
                of: "\(currFileName)",
                with: "\(newURL.lastPathComponent)"
            )
            
            projectText = projectText.replacingOccurrences(
                of: "\(newURL.lastPathComponent) */ = {isa = PBXFileReference; lastKnownFileType = file.\(url.pathExtension);",
                with: "\(newURL.lastPathComponent) */ = {isa = PBXFileReference; lastKnownFileType = file.swift;"
            )
            
            projectText = projectText.replacingOccurrences(
                of: "/* Base */ = {isa = PBXFileReference; lastKnownFileType = file.\(url.pathExtension); name = Base; path = Base.lproj/\(newURL.lastPathComponent);",
                with: "/* Base */ = {isa = PBXFileReference; lastKnownFileType = file.swift; name = Base; path = Base.lproj/\(newURL.lastPathComponent);"
            )
            
            // MARK: - Делим текст на строки
            var lines = projectText.components(separatedBy: "\n")
            let lineInResource = lines.enumerated().first(where: { $0.element.contains("\(newURL.lastPathComponent) in Sources */,") })
            lines.remove(at: lineInResource?.offset ?? -1)
            
            let insertBaseOffset = lines.enumerated().first(where: { $0.element.contains("/* End PBXSourcesBuildPhase section */")})?.offset ?? -1
            lines.insert(lineInResource?.element ?? "", at: insertBaseOffset - 4)
            projectText = lines.joined(separator: "\n")
            
            try! $0.value.write(toFile: newURL.path, atomically: true, encoding: .utf8)
            try! FileManager.default.removeItem(at: URL(fileURLWithPath:  $0.key))
        }
        try! projectText.write(toFile: projFilePath, atomically: true, encoding: .utf8)
    }
    
    private func setupCOnvertedReadyState() {
        leftImageView.image = #imageLiteral(resourceName: "storyboardFileIcon")
        leftImageView.imageAlignment = .alignCenter
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
        ElementGenerator.shared.clearData()
        fileText = ""
        sourceCode = ""
        guard let url = URL(string: path) else { return }
        fileURL = url
        leftLabel.stringValue = url.lastPathComponent
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            while let line = aStreamReader.nextLine() {
                sourceCode.append(line + "\n")
            }
            setupCOnvertedReadyState()
        }
        var fileName = String(
            String(
                url.lastPathComponent.reversed()
            )
            .drop(while: {$0 != "."})
            .reversed()
            .dropLast())
        fileName = "New"+fileName
        self.fileName = fileName + ".swift"
//        if fileName.contains("Main") {
//            fileText.append(
//                ElementGenerator.shared.createDebugFile(name: fileName)
//            )
//        } else {
            fileText.append(
                ElementGenerator.shared.generateHeader(
                    fileName: fileName
                )
            )
            
            fileText.append(
                ElementGenerator.shared.generateTemplate(
                    fileName: fileName, completion: {
                        models = []
                        return beginParsing()
                    }
                )
            )
//        }
        contentsFile[path] = fileText
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.activityView.stopAnimation(self)
            self?.activityView.isHidden = true
            self?.rightLabel.isHidden = true
            self?.rightImageView.image = #imageLiteral(resourceName: "swiftFIleIcon")
            self?.rightImageView.imageAlignment = .alignCenter
            self?.saveButton.isHidden = false
            self?.rightLabel.isHidden = false
            self?.rightLabel.stringValue = self?.fileName ?? ""
        }
    }

    // MARK: - Драг'n'дроп делегат
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }
        activityView.isHidden = false
        activityView.startAnimation(self)
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
