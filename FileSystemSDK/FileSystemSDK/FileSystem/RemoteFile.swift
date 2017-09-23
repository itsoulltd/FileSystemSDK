//
//  RemoteFile.swift
//  NGToolKitProject
//
//  Created by Towhid Islam on 3/4/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import Foundation
import CoreDataStack
import CoreNetworkStack


@objc(RemoteFileDelegate)
public protocol RemoteFileDelegate{
    func didFinishSynch(_ request: HttpWebRequest, file: IFile) -> Void
}

open class RemoteFile: NGObject{
    
    var request: HttpWebRequest!
    var localFile: File!
    weak var delegate: RemoteFileDelegate?
    
    //MARK: Initializer and Private Funcs
    
    init(request: HttpWebRequest, file: IFile, delegate: RemoteFileDelegate? = nil) {
        super.init(info: ["request":request, "localFile":file])
        self.delegate = delegate
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit{
        print("deinit \(NSStringFromClass(type(of: self)))")
    }
    
    func synchLocal(_ progress: ContentDelegate, reSynch: Bool = false){
        if (reSynch || localFile.fileExist() == false){
            RemoteSession.default().downloadContent(request, progressDelegate: progress, onCompletion: { (xurl, response, error) in
                if let url = xurl{
                    let downloadedFile = File(url: url)
                    self.localFile.writeAsynchFrom(downloadedFile, bufferSize: 2048, progress: nil, completionHandler: { [weak self] (done) in
                        self?.delegate?.didFinishSynch((self?.request)!, file: (self?.localFile)!)
                    })
                }
            })
        }
    }
    
    //MARK: DNObject Protocol
    
    open override func updateValue(_ value: Any!, forKey key: String!) {
        if key == "request"{
            if value is NSDictionary{
                let info: NSDictionary = (value as! NSDictionary)
                let allKeys = info.allKeys as NSArray
                if allKeys.contains("localFileURL"){
                    request = HttpFileRequest(info: info as! [AnyHashable: Any])
                }else{
                    request = HttpWebRequest(info: info as! [AnyHashable: Any])
                }
            }else{
                super.updateValue(value, forKey: key)
            }
        }
        else{
            super.updateValue(value, forKey: key)
        }
    }
    
    open override func serializeValue(_ value: Any!, forKey key: String!) -> Any! {
        return super.serializeValue(value, forKey: key) as AnyObject!
    }
    
}

