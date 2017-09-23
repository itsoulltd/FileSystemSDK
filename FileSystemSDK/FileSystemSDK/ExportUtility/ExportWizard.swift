//
//  ExportWizard.swift
//  DubaiArchive
//
//  Created by Towhid on 4/29/15.
//  Copyright (c) 2017 Next Generation Object Ltd. All rights reserved.
//

import UIKit

@objc
public protocol ExportProtocol: NSObjectProtocol{
    func handleDocumentExport(_ documentUrl: URL, docUTI: String, presentOnView: UIView) -> Void
}

@objc(ExportWizard)
open class ExportWizard: NSObject, UIDocumentInteractionControllerDelegate, ExportProtocol{
    
    var documentController: UIDocumentInteractionController?
    var directory: Folder?
    
    //MARK: ExportProtocol
    
    open func handleDocumentExport(_ documentUrl: URL, docUTI: String, presentOnView: UIView) {
        //
        documentController = UIDocumentInteractionController(url: documentUrl)
        documentController?.delegate = self
        documentController?.uti = docUTI
        documentController?.presentOpenInMenu(from: CGRect.zero, in: presentOnView, animated: true)
    }
    
    //MARK: UIDocumentInteractionControllerDelegate
    
    open func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        //
        print("DidDismissOpenInMenu")
    }
    
    open func documentInteractionController(_ controller: UIDocumentInteractionController, willBeginSendingToApplication application: String?) {
        //
        print("WillBeginSending \(application)")
    }
    
    open func documentInteractionController(_ controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        //
        print("DidEndSending \(application)")
    }
}
