//
//  ViewController.swift
//  Convertor
//
//  Created by Alexandr Arsenyuk on 26.10.2020.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var leftDropView: DropView!
    @IBOutlet weak var leftLabel: NSTextField!
    
    @IBOutlet weak var rightDropView: NSView!
    @IBOutlet weak var rightLabel: NSTextField!
   
    @IBOutlet weak var saveButton: NSButton!
    
    private var fileText = ""
    
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
}

extension ViewController: DropViewDelegate {
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }
        if let url = URL(string: path) {
            leftLabel.stringValue = url.lastPathComponent
            let imageView = NSImageView(frame: leftDropView.frame)
            imageView.image = #imageLiteral(resourceName: "storyboardFileIcon")
            imageView.imageAlignment = .alignCenter
            leftDropView.addSubview(imageView)
        }
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            while let line = aStreamReader.nextLine() {
                fileText.append(line + "\n")
            }
            setupCOnvertedReadyState()
        }
        return true
    }
}

