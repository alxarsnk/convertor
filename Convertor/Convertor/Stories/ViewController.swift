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

class ViewController: NSViewController {
    
    @IBOutlet weak var leftDropView: DropView!
    @IBOutlet weak var leftLabel: NSTextField!
    @IBOutlet weak var leftImageView: NSImageView!
    @IBOutlet weak var rightImageView: NSImageView!
    
    @IBOutlet weak var activityView: NSProgressIndicator!
    @IBOutlet weak var rightDropView: NSView!
    @IBOutlet weak var rightLabel: NSTextField!
    
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var chooseProjectButton: NSButton!
    
    private var presenter: ViewOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = Presenter(delegate: self)
        setupLabels()
        setupDropViews()
        setupSaveButton()
        setupActivity(isAnimating: false)
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
    
    private func setupSaveButton() {
        saveButton.title = "Save"
        saveButton.isHidden = true
        saveButton.contentTintColor = .white
        saveButton.layer?.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        presenter?.saveButtonPressed()
    }
    
    @IBAction func chooseProjectButtonTapped(_ sender: Any) {
        presenter?.choseProjectButtonPressed()
    }
    
}

// MARK: - Драг'n'дроп делегат

extension ViewController: DropViewDelegate {
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }
        setupActivity(isAnimating: true)
        presenter?.fileSetted(path: path)
        return true
    }
    
}

extension ViewController: ViewInput {
    
    func setupActivity(isAnimating: Bool) {
        if isAnimating {
            activityView.isHidden = false
            activityView.startAnimation(self)
        } else {
            activityView.isHidden = true
            activityView.stopAnimation(self)
        }
    }
    
    func setupFinishState(isProject: Bool, file: File?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.activityView.stopAnimation(self)
            self?.activityView.isHidden = true
            self?.rightLabel.isHidden = true
            self?.rightImageView.image = isProject ? #imageLiteral(resourceName: "folderIcon") : #imageLiteral(resourceName: "swiftFIleIcon")
            self?.leftImageView.image = isProject ? #imageLiteral(resourceName: "folderIcon") : #imageLiteral(resourceName: "storyboardFileIcon")
            self?.leftImageView.imageAlignment = .alignCenter
            self?.rightImageView.imageAlignment = .alignCenter
            self?.saveButton.isHidden = isProject
            self?.rightLabel.isHidden = false
            self?.rightLabel.stringValue = isProject ? "SwiftUIApp" : file?.fileName ?? ""
        }
    }
    
}
