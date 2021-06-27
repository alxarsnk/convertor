//
//  ElementGenerator.swift
//  Convertor
//
//  Created by Александр Арсенюк on 27.12.2020.
//

import XMLCoder
import SwiftyXML

class ElementGenerator {
    
    private var isActivityViewAdded = false
    private var isPageCotnrolAdded = false
    private var isTextViewAdded = false
    private var isBodyExists = false
    private var isNavBarExist = false
    private var outletsAdded = false
    
    var isTabbarExist = false
    
    var outlets: Outlets = []
    
    private var customElements = ""
    
    init() { }
    
    func generateElement(from xml: XML, insertingText: String, spaces: Int, elementType: ViewType, isForOutlets: Bool = true) -> String {
        if !outlets.map { $0.id }.contains(xml.id) || !isForOutlets {
            guard let element = ElementType(rawValue: xml.xmlName) else { return skipElment(insertingText: insertingText, spaces: spaces, xml: xml) }
            switch element {
            case .tableView:
                return generateTableView(insertingText: insertingText, spaces: spaces, xml: xml)
            case .imageView:
                return generateImageView(insertingText: insertingText, spaces: spaces, xml: xml)
            case .label:
                return generateLabel(insertingText: insertingText, spaces: spaces, xml: xml)
            case .tableViewCell:
                return generateVStack(insertingText: insertingText, spaces: spaces, xml: xml)
            case .view:
                if elementType == .xib && spaces == 0 {
                    return generateRootView(insertingText: insertingText, spaces: spaces, xml: xml, isVc: false)
                } else if (xml.rect?.width ?? 0) / 2 <= xml.rect?.height ?? 0 {
                    return generateVStack(insertingText: insertingText, spaces: spaces, xml: xml)
                } else {
                    return generateHStack(insertingText: insertingText, spaces: spaces, xml: xml)
                }
            case .button:
                return generateButton(insertingText: insertingText, spaces: spaces, xml: xml)
            case .stackView:
                switch xml.xmlAttributes["axis"] {
                case "vertical":
                    return generateVStack(insertingText: insertingText, spaces: spaces, xml: xml)
                default:
                    return generateHStack(insertingText: insertingText, spaces: spaces, xml: xml)
                }
            case .activityIndicatorView:
                return generateActivityView(insertingText: insertingText, spaces: spaces, xml: xml)
            case .pageControl:
                return generatePageControl(insertingText: insertingText, spaces: spaces, xml: xml)
            case .switchControl:
                return generateSwitchControl(insertingText: insertingText, spaces: spaces, xml: xml)
            case .segmentedControl:
                return generateSegmentedControl(insertingText: insertingText, spaces: spaces, xml: xml)
            case .textView:
                return generateTextView(insertingText: insertingText, spaces: spaces, xml: xml)
            case .textField:
                return generateTextField(insertingText: insertingText,spaces: spaces, xml: xml)
            case .collectionView:
                return generateСollectionView(insertingText: insertingText, spaces: spaces, xml: xml)
            case .collectionViewCell:
                return generateHStack(insertingText: insertingText, spaces: spaces, xml: xml)
            case .viewController:
                return generateRootView(insertingText: insertingText, spaces: spaces, xml: xml, isVc: true)
            }
        } else {
            let spacesString = String(repeating: " ", count: spaces)
            return "\(spacesString) \(outlets.first(where: { $0.id == xml.id })!.name)"
        }
    }
    
    private func generateTableView(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)List(0..<10) { _ in
            \(insertingText)
            \(spacesString)}

            """
    }
    
    private func generateСollectionView(insertingText: String = "", spaces: Int, xml: XML) -> String {
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
    
    private func generateHStack(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)HStack() {
            \(insertingText)
            \(spacesString)}
            \(spacesString)\(generateColor(xml.color))

            """
    }
    
    private func generateVStack(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)VStack() {
            \(insertingText)
            \(spacesString)}
            \(spacesString)\(generateColor(xml.color))

            """
    }
    
    private func generateRootView(insertingText: String = "", spaces: Int, xml: XML, isVc: Bool) -> String {
        var headers: String = ""
        
        let navBarXML = xml.xmlChildren.first(where: {$0.xmlName == "navigationItem"})
        var navBarText = ""
        if navBarXML != nil {
            navBarText = """
                NavigationView {
                    \(insertingText)
                    .navigationBarTitle("\(navBarXML!.xmlAttributes["title"]!)")
                }
            """
        } else {
            navBarText = insertingText
        }
        
        var tabBarText = ""
        
        if isTabbarExist {
            tabBarText = """
            TabView {
                \(navBarText)
                .tabItem {
                    Text("Tab")
                }
            }
            """
        } else {
            tabBarText = navBarText
        }
        
        if isVc {
            headers = """
            \(tabBarText)
            """
        }
        
        let title = isBodyExists ? xml.xmlName : "body"
        let spacesString = String(repeating: " ", count: spaces)
        
        
        isBodyExists = true
        return isVc ?
            """
            \(spacesString)\(generateSwiftUIOutlets())
            \(spacesString)var \(title): some View {
            \(headers)
            \(spacesString)}

            """
            : """
            \(spacesString)var \(title): some View {
            \(insertingText)
            \(spacesString)}
            """
    }
    
    private func skipElment(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        return
            """
            \(spacesString)\(insertingText)
            """
    }
    
    private func generateLabel(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        var text = insertingText
        let textName = xml.xmlAttributes["text"] ?? ""
        text.append("\n\(spacesString).\(generateRect(xml.rect))")
        return
            """
            \(spacesString)Text("\(textName)")\(text)
            \(spacesString)Spacer(minLength: 20)
            
            """
    }
    
    private func generateImageView(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        var text = insertingText
        if let contentMode = xml.xmlAttributes["contentMode"] {
            text.append("\n\(spacesString).resizable()")
            if contentMode.contains("Fit") {
                text.append("\n\(spacesString).aspectRatio(contentMode: .fit)")
            } else {
                text.append("\n\(spacesString).aspectRatio(contentMode: .fill)")
            }
            text.append("\n\(spacesString).\(generateRect(xml.rect))")
            text.append("\n\(spacesString).cornerRadius(16)")
        }
        var imageInit = "uiImage: UIImage()"
        if let intial = xml.xmlAttributes["image"] {
            imageInit = "\"\(intial)\""
        }
        return
            """
            \(spacesString)Image(\(imageInit))\(text)

            """
    }
    
    private func generateButton(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        let imageInit = xml.buttonImage == nil ? "uiImage: UIImage()" : "\"\(xml.buttonImage!)\""
        return
            """
            \(spacesString)Button(action: {}) {
            \(spacesString) Image(\(imageInit))
            \(spacesString) .resizable()
            \(spacesString) .\(generateRect(xml.rect))
            \(text)
            \(spacesString)}

            """
    }
    
    private func generateTextField(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)TextField("", text: .constant(""))\(text)

            """
    }
    
    private func generateTextView(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        makeTextView()
        return
            """
            \(spacesString)TextView(text: .constant(""), textStyle: .constant())\(text)

            """
    }
    
    private func generateActivityView(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        makeActivityView()
        return
            """
            \(spacesString)ActivityIndicator(shouldAnimate: .constant(true))\(text)

            """
    }
    
    private func generateSwitchControl(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)Toggle("Toogle", isOn: .constant(true))\(text)

            """
    }
    
    private func generatePageControl(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        makePageControl()
        return
            """
            \(spacesString)PageControl(numberOfPages: 3, currentPage: .constant(0))\(text)

            """
    }
    
    private func generateSegmentedControl(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)Picker(selection: .constant(0), label: Text("SegmentedControl"), content: {})
                                .pickerStyle(SegmentedPickerStyle())\(text)

            """
    }
    
    func generateHeader(fileName: String) -> String {
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
    
    func generateTemplate(fileName: String, completion: (() -> String)) -> String {
        return """
            import SwiftUI

            struct \(fileName): View {
                \(completion())
            }

            struct \(fileName)_Previews: PreviewProvider {
                static var previews: some View {
                    \(fileName)()
                }
            }
            
            """
    }
    
    private func makeActivityView() {
        guard !isActivityViewAdded else { return }
        let activityView = """
        struct ActivityIndicator: UIViewRepresentable {
        @Binding var shouldAnimate: Bool
        
        func makeUIView(context: Context) -> UIActivityIndicatorView {
            return UIActivityIndicatorView()
        }

        func updateUIView(_ uiView: UIActivityIndicatorView,
                      context: Context) {
            if self.shouldAnimate {
                uiView.startAnimating()
            } else {
                uiView.stopAnimating()
            }
        }
        }
        
        """
        customElements.append(activityView)
    }
    
    private func makePageControl() {
        guard !isPageCotnrolAdded else { return }
        let pageControl = """
        struct PageControl: UIViewRepresentable {
            var numberOfPages: Int
            @Binding var currentPage: Int

            func makeCoordinator() -> Coordinator {
                Coordinator(self)
            }

            func makeUIView(context: Context) -> UIPageControl {
                let control = UIPageControl()
                control.numberOfPages = numberOfPages
                control.addTarget(
                    context.coordinator,
                    action: #selector(Coordinator.updateCurrentPage(sender:)),
                    for: .valueChanged)

                return control
            }

            func updateUIView(_ uiView: UIPageControl, context: Context) {
                uiView.currentPage = currentPage
            }

            class Coordinator: NSObject {
                var control: PageControl

                init(_ control: PageControl) {
                    self.control = control
                }

                @objc
                func updateCurrentPage(sender: UIPageControl) {
                    control.currentPage = sender.currentPage
                }
            }
        }
        
        """
        customElements.append(pageControl)
    }
    
    private func makeTextView() {
        guard !isTextViewAdded else { return }
        let textView = """
        struct TextView: UIViewRepresentable {
         
            @Binding var text: String
            @Binding var textStyle: UIFont.TextStyle
         
            func makeUIView(context: Context) -> UITextView {
                let textView = UITextView()
         
                textView.font = UIFont.preferredFont(forTextStyle: textStyle)
                textView.autocapitalizationType = .sentences
                textView.isSelectable = true
                textView.isUserInteractionEnabled = true
         
                return textView
            }
         
            func updateUIView(_ uiView: UITextView, context: Context) {
                uiView.text = text
                uiView.font = UIFont.preferredFont(forTextStyle: textStyle)
            }
        }
        
        """
        customElements.append(textView)
    }
    
    static func createSceneDelegate(nameOfFile: String) -> String {
        return """
                guard let windowScene = scene as? UIWindowScene else { return }
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIHostingController(rootView: \(nameOfFile)())
                self.window = window
                window.makeKeyAndVisible()
        """
    }
    
    func generateRect(_ rect: CGRect?) -> String {
        guard let rect = rect else { return "" }
        return "frame(width: \(rect.width), height: \(rect.height), alignment: .leading)"
    }
    
    func generateColor(_ color: NSColor?) -> String {
        guard let color = color else { return "" }
        return ".background(Color(red: \(color.redComponent), green: \(color.greenComponent), blue: \(color.blueComponent)))"
    }
    
    func generateSwiftUIOutlets() -> String {
        guard !outletsAdded else { return "" }
        var states: [String] = []
        for outlet in outlets {
            states
                .append(
                    """
                    var \(outlet.name): some View {
                    \(outlet.insertingText)
                    }
                    """
                )
        }
        outletsAdded = true
        return states.joined(separator: "\n")+"\n"
    }
    
}
