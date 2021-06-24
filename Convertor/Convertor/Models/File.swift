//
//  File.swift
//  Convertor
//
//  Created by Александр Арсенюк on 23.06.2021.
//

import Foundation
import SwiftyXML

class File {
    
    var path: String
    var fileURL: URL?
    var fileName: String = ""
    var content: String = ""
    var generatedContent: String = ""
    var models: StagedModels = []
    
    init(path: String) {
        self.path = path
        readContent()
    }
    
    private func readContent() {
        guard let url = URL(string: path) else { return }
        fileURL = url
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            while let line = aStreamReader.nextLine() {
                content.append(line + "\n")
            }
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
        generatedContent.append(
            ElementGenerator.shared.generateHeader(
                fileName: fileName
            )
        )
        
        generatedContent.append(
            ElementGenerator.shared.generateTemplate(
                fileName: fileName, completion: {
                    models = []
                    return beginParsing()
                }
            )
        )
    }
    
    private func beginParsing() -> String {
        let xml = XML(string: content, encoding: .utf8)
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
        if xml.customClass != nil { }
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
