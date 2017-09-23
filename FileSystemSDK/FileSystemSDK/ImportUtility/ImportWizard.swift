//
//  ImportWizard.swift
//  DubaiArchive
//
//  Created by Towhid on 4/29/15.
//  Copyright (c) 2017 Next Generation Object Ltd. All rights reserved.
//

import UIKit

@available(iOS 8.0, *)
@objc(ImportWizardDelegate)
public protocol ImportWizardDelegate: NSObjectProtocol{
    func importWizardPresenterViewController(_ wizard: ImportWizard) -> UIViewController
    func importWizard(_ wizard: ImportWizard, didPickDocumentAtURL url: URL) -> Void
}

@available(iOS 8.0, *)
@objc(ImportWizard)
open class ImportWizard: NSObject, UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    
    var directory: Folder!
    fileprivate var documentMenuController: UIDocumentMenuViewController!
    var menuController: UIDocumentMenuViewController{
        return documentMenuController
    }
    fileprivate var documentPickerController: UIDocumentPickerViewController!
    var pickerController: UIDocumentPickerViewController{
        return documentPickerController
    }
    fileprivate weak var presenter: UIViewController?
    fileprivate weak var delegate: ImportWizardDelegate?
    
    init(directory: Folder, delegate: ImportWizardDelegate?) {
        super.init()
        self.directory = directory
        self.delegate = delegate
    }
    
    func showDocumentMenu(){
        documentMenuController = UIDocumentMenuViewController(documentTypes: [UTI.PDF, UTI.JPEG, UTI.AVI, UTI.MP3, UTI.MPEG, UTI.MPEG4, UTI.MSDoc, UTI.MSPpt, UTI.MSXls, UTI.PNG, UTI.Text, UTI.ZipArchive], in: UIDocumentPickerMode.import)
        documentMenuController.delegate = self
        self.presenter = self.delegate?.importWizardPresenterViewController(self)
        if let presenter = self.presenter{
            presenter.present(documentMenuController, animated: true) { () -> Void in
                print("Document Menu Presented.")
            }
        }
    }
    
    func showDocumentPicker(){
        documentPickerController = UIDocumentPickerViewController(documentTypes: [UTI.PDF, UTI.JPEG, UTI.AVI, UTI.MP3, UTI.MPEG, UTI.MPEG4, UTI.MSDoc, UTI.MSPpt, UTI.MSXls, UTI.PNG, UTI.Text, UTI.ZipArchive], in: UIDocumentPickerMode.import)
        documentPickerController.delegate = self
        self.presenter = self.delegate?.importWizardPresenterViewController(self)
        if let presenter = self.presenter{
            presenter.present(documentPickerController, animated: true) { () -> Void in
                print("Document Picker Presented.")
            }
        }
    }
    
    func importDocument(fromURL url: URL) -> URL?{
        let name = url.lastPathComponent
        let source = try? Data(contentsOf: url)
        let saved = importDocument(fromSource: source!, saveAs: name)
        return saved
    }
    
    func importDocument(fromSource source: Data, saveAs fileName: String) -> URL?{
        let name = directory.resolveChildName(name: fileName)
        let saved = directory.saveAs(name, data: source)
        return saved
    }
    
    //MARK: UIDocumentMenuDelegate
    
    open func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        if let presenter = self.presenter{
            presenter.present(documentPicker, animated: true) { () -> Void in
                print("Document Picker Presented.")
            }
        }
    }
    
    open func documentMenuWasCancelled(_ documentMenu: UIDocumentMenuViewController) {
        print("Document Menu Canceld")
    }
    
    //MARK: UIDocumentPickerDelegate
    
    open func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("Document Picker Delegate Called")
        self.delegate?.importWizard(self, didPickDocumentAtURL: url)
    }
    
    open func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document Picker Canceld")
    }
    
}
