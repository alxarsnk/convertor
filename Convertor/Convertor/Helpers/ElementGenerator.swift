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
    
    private var isActivityViewAdded = false
    private var isPageCotnrolAdded = false
    private var isTextViewAdded = false
    private var isBodyExists = false
    
    func clearData() {
        isActivityViewAdded = false
        isPageCotnrolAdded = false
        isTextViewAdded = false
        isBodyExists = false
    }
    
    private var customElements = ""
    
    private init() { }
    
    func generateElement(from xml: XML, insertingText: String, spaces: Int, elementType: ViewType) -> String {
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
                return generateRootView(insertingText: insertingText, spaces: spaces, xml: xml)
            } else {
                return generateVStack(insertingText: insertingText, spaces: spaces, xml: xml)
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
            return generateRootView(insertingText: insertingText, spaces: spaces, xml: xml)
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
            \(spacesString).\(generateColor(xml.color))

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
    
    private func generateRootView(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let title = isBodyExists ? xml.xmlName : "body"
        let spacesString = String(repeating: " ", count: spaces)
        isBodyExists = true
        return
            """
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
        let text = insertingText
        return
            """
            \(spacesString)Text("Text")\(text)

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
            text.append("\n\(spacesString).border(Color.black, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)")
            text.append("\n\(spacesString).\(generateRect(xml.rect))")
        }
        return
            """
            \(spacesString)Image(uiImage: UIImage())\(text)

            """
    }
    
    private func generateButton(insertingText: String = "", spaces: Int, xml: XML) -> String {
        let spacesString = String(repeating: " ", count: spaces)
        let text = insertingText
        return
            """
            \(spacesString)Button(action: {}) {
            \(spacesString) Text("Button")
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
    
    func createSceneDelegate(nameOfFile: String) -> String {
        return """
        import UIKit
        import SwiftUI
        
        class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        
            var window: UIWindow?
        
        
            func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)         {
        
                guard let windowScene = scene as? UIWindowScene else { return }
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIHostingController(rootView: \(nameOfFile)())
                self.window = window
                window.makeKeyAndVisible()
            }
        
            func sceneDidDisconnect(_ scene: UIScene) {
                // Called as the scene is being released by the system.
                // This occurs shortly after the scene enters the background, or when its session is discarded.
                // Release any resources associated with this scene that can be re-created the next time the scene connects.
                // The scene may re-connect later, as its session was not necessarily discarded (see         `application:didDiscardSceneSessions` instead).
            }
        
            func sceneDidBecomeActive(_ scene: UIScene) {
                // Called when the scene has moved from an inactive state to an active state.
                // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
            }
        
            func sceneWillResignActive(_ scene: UIScene) {
                // Called when the scene will move from an active state to an inactive state.
                // This may occur due to temporary interruptions (ex. an incoming phone call).
            }
        
            func sceneWillEnterForeground(_ scene: UIScene) {
                // Called as the scene transitions from the background to the foreground.
                // Use this method to undo the changes made on entering the background.
            }
        
            func sceneDidEnterBackground(_ scene: UIScene) {
                // Called as the scene transitions from the foreground to the background.
                // Use this method to save data, release shared resources, and store enough scene-specific state information
                // to restore the scene back to its current state.
            }
        
        }
        """
    }
    
    func createDebugFile(name: String) -> String {
        var res = ""
        res.append(generateHeader(fileName: name))
        res.append(generateTemplate(fileName: name, completion: { () -> String in
            return """
            let dataSource: [User] = Array.init(repeating: User(), count: 15)
            
            @State private var text = Text("Name")
            
            var body: some View {
                TabView {
                    NavigationView {
                        List(dataSource) { model in
                            VStack(alignment: .leading) {
                                Image(uiImage: model.postImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .cornerRadius(8)
                                Spacer().frame(width: 0, height: 12, alignment: .bottom)
                                HStack {
                                    Image(uiImage: model.avatarImage)
                                        .resizable()
                                        .frame(width: 48, height: 48, alignment: .leading)
                                        .cornerRadius(24)
                                        .aspectRatio(contentMode: .fill)
                                    text
                                    Spacer(minLength: 20)
                                    Button(action: {
                                        model.isLiked = !model.isLiked
                                    }) {
                                        Image(model.isLiked ? "isLiked" : "notLiked")
                                            .resizable()
                                            .frame(width: 24, height: 24, alignment: .trailing)
                                    }
                                    Image("arrow")
                                        .resizable()
                                        .frame(width: 24, height: 24, alignment: .leading)
                                }
                            }
                            .background(Color(red: 0.9, green: 0.9, blue: 0.9))
                            .cornerRadius(12)
                            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                        }
                        .navigationBarTitle("News")
                    }.tabItem {
                        Image(systemName: "star.fill")
                        Text("Favourite")
                    }
                    Text("The content of the second view")
                        .tabItem {
                            Image(systemName: "clock.fill")
                            Text("History")
                        }
                }
            }
            """
        }))
        return res
    }
    
    func generateRect(_ rect: CGRect?) -> String {
        guard let rect = rect else { return "" }
        return "frame(width: \(rect.width), height: \(rect.height), alignment: .leading)"
    }
    
    func generateColor(_ color: NSColor?) -> String {
        guard let color = color else { return "" }
        return ".background(Color(red: \(color.redComponent), green: \(color.greenComponent), blue: \(color.blueComponent)))"
    }
    
}
