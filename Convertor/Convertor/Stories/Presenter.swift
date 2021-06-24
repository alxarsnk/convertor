//
//  Presenter.swift
//  Convertor
//
//  Created by Александр Арсенюк on 22.06.2021.
//

import Foundation
import PathKit
import SwiftyXML

protocol ViewInput: AnyObject {
    
    func setupActivity(isAnimating: Bool)
    func setupFinishState(isProject: Bool, file: File?)
    
}

protocol ViewOutput {
    
    func choseProjectButtonPressed()
    func fileSetted(path: String)
    func saveButtonPressed()
    
}

// MARK: - Init
class Presenter {
    
    weak var view: ViewInput?
    
    private let panelManager = PanelWorker.shared
    
    private var filesInProjects: [URL] = []
    private var isProject = false
    private var contentsFile: [String: String] = [:]
    private var singleFile: File?
    
    init (delegate: ViewInput) {
        self.view = delegate
    }
}

// MARK: - Project integration
extension Presenter {
    
    private func copyItems() {
        do {
            try FileManager.default.copyItem(
                atPath: panelManager.originlProjectURL!.path,
                toPath: panelManager.saveProjectPathURL!.path)
            
        } catch let error {
            print("error: \(error)")
        }
    }
    
    
    private func enumerateFiles() {
        let enumerator = FileManager.default.enumerator(at: panelManager.saveProjectPathURL!, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants])
        for case let fileURL as URL in enumerator! {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    filesInProjects.append(fileURL)
                }
            } catch { print(error, fileURL) }
        }
    }
    
    private func chooseFilesAndConvert() {
        filesInProjects
            .filter {
                ($0.lastPathComponent.contains(".xib")  || $0.lastPathComponent.contains(".storyboard"))
                    && !$0.lastPathComponent.contains("LaunchScreen")
            }
            .forEach {
                print($0.path)
                let file = File(path: $0.path)
                contentsFile[$0.path] = file.generatedContent
            }
        self.convertProject()
        self.replaceFiles()
        self.view?.setupFinishState(isProject: isProject, file: nil)
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
        let files = Path(panelManager.saveProjectPathURL!.path)
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
    
}

extension Presenter: ViewOutput {
    
    func choseProjectButtonPressed() {
        panelManager.showChoseProjectPanel { [weak self] in
            guard let self = self  else { return }
            self.isProject = true
            self.view?.setupActivity(isAnimating: true)
            self.copyItems()
            self.enumerateFiles()
            self.chooseFilesAndConvert()
        }
    }
    
    func saveButtonPressed() {
        guard let file = singleFile else { return }
        panelManager.showSavePanel(file: file)
    }
    
    func fileSetted(path: String) {
        singleFile = File(path: path)
        view?.setupFinishState(isProject: false, file: singleFile)
    }
    
}
