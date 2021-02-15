//
//  ElementGenerator.swift
//  Convertor
//
//  Created by Александр Арсенюк on 27.12.2020.
//

import XMLCoder
import SwiftyXML

class ElementGenerator {
    
    static var shared = ElementGenerator()
    
    private init() { }
    
    func generateElement(from xml: XML, insertingText: String, spaces: Int) -> String {
        let element = ElementType(rawValue: xml.xmlName)!
        switch element {
        case .tableView:
            return generateTableView(insertingText: insertingText, spaces: spaces)
        case .imageView:
            return generateImageView(insertingText: insertingText, spaces: spaces, attributes: xml.xmlAttributes)
        case .label:
            return generateLabel(insertingText: insertingText, spaces: spaces)
        case .tableViewCell:
            return generateVStack(insertingText: insertingText, spaces: spaces)
        case .view:
            return generateVStack(insertingText: insertingText, spaces: spaces)
        case .button:
            return generateButton(insertingText: insertingText, spaces: spaces)
        case .stackView:
            switch xml.xmlAttributes["axis"] {
            case "vertical":
                return generateVStack(insertingText: insertingText, spaces: spaces)
            default:
                return generateHStack(insertingText: insertingText, spaces: spaces)
            }
        case .activityIndicatorView:
            return generateActivityView(insertingText: insertingText, spaces: spaces)
        case .pageControl:
            return generatePageControl(insertingText: insertingText, spaces: spaces)
        case .switchControl:
            return generateSwitchControl(insertingText: insertingText, spaces: spaces)
        case .segmentedControl:
            return generateSegmentedControl(insertingText: insertingText, spaces: spaces)
        case .textView:
            return generateTextView(insertingText: insertingText, spaces: spaces)
        case .textField:
            return generateTextField(insertingText: insertingText,spaces: spaces)
        case .collectionView:
            return generateСollectionView(insertingText: insertingText, spaces: spaces)
        case .collectionViewCell:
            return generateHStack(insertingText: insertingText, spaces: spaces)
        }
        
    }
    
    private func generateTableView(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)List(0..<10) { _ in
            \(insertingText)
            \(spacesString)}

            """
    }
    
    private func generateСollectionView(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)ScrollView(.horizontal) {
            \(spacesString)HStack {
            \(spacesString)ForEach(0..<10) { _ in
            \(insertingText)
            \(spacesString)}
            \(spacesString)}
            \(spacesString)}

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
        let text = insertingText
        return
            """
            \(spacesString)Text("")\(text)

            """
    }
    
    private func generateImageView(insertingText: String = "", spaces: Int, attributes: [String: String]) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        var text = insertingText
        if let contentMode = attributes["contentMode"] {
            if contentMode.contains("Fit") {
                text.append("\n\(spacesString).aspectRatio(contentMode: .fit)")
            } else {
                text.append("\n.aspectRatio(contentMode: .fill)")
            }
        }
        return
            """
            \(spacesString)Image()\(text)

            """
    }
    
    private func generateButton(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)Button()\(text)

            """
    }
    
    private func generateTextField(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)TextField("", text: .constant(""))\(text)

            """
    }
    
    private func generateTextView(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)TextView(text: .constant(""), textStyle: .constant())\(text)

            """
    }
    
    private func generateActivityView(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)ActivityIndicator(shouldAnimate: .constant(true))\(text)

            """
    }
    
    private func generateSwitchControl(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)Toggle("Toogle", isOn: .constant(true))\(text)

            """
    }
    
    private func generatePageControl(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)PageControl(numberOfPages: 3, currentPage: .constant(0))\(text)

            """
    }
    
    private func generateSegmentedControl(insertingText: String = "", spaces: Int) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)Picker(selection: .constant(0), label: Text("SegmentedControl"), content: {})
                                .pickerStyle(SegmentedPickerStyle())\(text)

            """
    }
    
}
