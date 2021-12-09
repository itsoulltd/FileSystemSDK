//
//  FileItem.swift
//  DubaiArchive
//
//  Created by Towhid on 4/29/15.
//  Copyright (c) 2017 Next Generation Object Ltd. All rights reserved.
//

import Foundation
import CoreDataStack
import MobileCoreServices

@objc(IDocumentMetadata)
public protocol IDocumentMetadata: NSObjectProtocol{
    var documentUrl: URL {get}
    var documentName: String {get}
    func getAttributes() -> NSDictionary?
    func modifiedDate() -> Date?
    func creationDate() -> Date?
    func documentType() -> NSString?
}

@objc(DocumentMetadata)
@objcMembers
open class DocumentMetadata: NGObject, IDocumentMetadata{
    
    var URL: Foundation.URL!
    
    open var documentUrl: Foundation.URL{
        return URL
    }
    
    open var documentName: String{
        return URL.lastPathComponent
    }
    
    init(url: Foundation.URL) {
        super.init(info: ["URL":url])
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit{
        //println("deinit \(NSStringFromClass(self.dynamicType))")
    }
    
    open func getAttributes() -> NSDictionary?{
        var attributes: NSDictionary? = nil
        do{
            attributes = try FileManager.default.attributesOfItem(atPath: URL.path) as NSDictionary
        } catch let error as NSError{
            print("getAttributes -> \(error.debugDescription)")
        } catch{
            print("Error in \(#function) at line \(#line)")
        }
        return attributes
    }
    
    open func modifiedDate() -> Date? {
        //
        if let attributes = getAttributes(){
            return attributes.fileModificationDate()
        }
        return nil
    }
    
    open func creationDate() -> Date? {
        //
        if let attributes = getAttributes(){
            return attributes.fileCreationDate()
        }
        return nil
    }
    
    open func documentType() -> NSString? {
        //
        if let attributes = getAttributes(){
            return attributes.fileType() as NSString?
        }
        return nil
    }
    
    //MARK: DNObject Protocol
    
    open override func updateValue(_ value: Any!, forKey key: String!) {
        if key == "URL"{
            if value is String{
                URL = Foundation.URL(fileURLWithPath: (value as! String))
            }
            else{
                super.updateValue(value, forKey: key)
            }
        }
        else{
            super.updateValue(value, forKey: key)
        }
    }
    
    open override func serializeValue(_ value: Any!, forKey key: String!) -> Any! {
        if key == "URL"{
            return URL.path as AnyObject?
        }
        else {
            return super.serializeValue(value, forKey: key) as AnyObject?
        }
    }
}

@objc(IFile)
public protocol IFile: NSObjectProtocol{
    var metadata: IDocumentMetadata {get}
    var name: String {get}
    var URL: Foundation.URL{get}
    func isFile() -> Bool
    func fileExist() -> Bool
    func mimeType() -> NSString
    var sizeInBytes: Double {get}
    var sizeInKBytes: Double {get}
    var sizeInMBytes: Double {get}
    var sizeInGBytes: Double {get}
    func read() -> Data?
    func write(_ data: Data) -> Bool
    func writeFrom(_ readfile: IFile, bufferSize: Int, progress: IFileProgress?) -> Bool
    func writeAsynchFrom(_ readfile: IFile, bufferSize: Int, progress: IFileProgress?, completionHandler: ((Bool) -> Void)?) -> Void
    func writeAsynchTo(_ file: IFile, bufferSize: Int, progress: IFileProgress?, completionHandler: ((Bool) -> Void)?) -> Void
    func delete() -> Bool
    func rename(_ rename: String) -> Bool
}

@objc(IFileProgress)
public protocol IFileProgress: NSObjectProtocol{
    func readWriteProgress(_ progress: Double) -> Void
}

@objc(File)
@objcMembers
open class File: NGObject, IFile {
    
    //MARK: Properties
    open var URL: Foundation.URL{
        get{
            return _metadata.documentUrl
        }
    }
    
    open var name: String{
        return metadata.documentName
    }
    
    var size: NSNumber = 0.0
    
    open var sizeInBytes: Double{
        return size.doubleValue
    }
    open var sizeInKBytes: Double{
        return sizeInBytes/1024 //in KB
    }
    open var sizeInMBytes: Double{
        return sizeInKBytes/1024 //in MB
    }
    open var sizeInGBytes: Double{
        return sizeInMBytes/1024 //in GB
    }
    
    fileprivate var _metadata: IDocumentMetadata!
    
    open var metadata: IDocumentMetadata{
        return _metadata
    }
    
    //MARK: Initializer and Private Funcs
    
    public init(url: Foundation.URL) {
        super.init()
        _metadata = DocumentMetadata(url: url)
        calculateSize()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        calculateSize()
    }
    
    fileprivate func calculateSize(){
        //
        if fileExist() == false{
            print("FileSize Cal Error -> File Does not exist")
            return
        }
        var fileSize: AnyObject?
        do {
            try (URL as NSURL).getResourceValue(&fileSize, forKey: URLResourceKey.fileSizeKey)
            if let fSize = fileSize as? NSNumber{
                size = NSNumber(value: fSize.doubleValue as Double)
            }
        } catch let error1 as NSError {
            print("FileSize Cal Error -> \(error1.debugDescription)")
        }
        catch{
            print("FileSize Cal Error -> Unknown!?!")
        }
    }
    
    //MARK: Public Function
    
    open func fileExist() -> Bool{
        //
        if URL.isFileURL == false{
            return false
        }
        let exist = FileManager.default.fileExists(atPath: URL.path)
        return exist
    }
    
    open func isFile() -> Bool{
        //
        if let type = documentType(){
            return type as FileAttributeType == FileAttributeType.typeRegular
        }
        return false
    }
    
    func modifiedDate() -> Date? {
        //
        if fileExist() == false{
            print("File Error -> File:(\(name)) Does not exist")
            return nil
        }
        return metadata.modifiedDate()
    }
    
    func creationDate() -> Date? {
        //
        if fileExist() == false{
            print("File Error -> File:(\(name)) Does not exist")
            return nil
        }
        return metadata.creationDate()
    }
    
    func documentType() -> NSString? {
        //
        if fileExist() == false{
            print("File Error -> File:(\(name)) Does not exist")
            return nil
        }
        return metadata.documentType()
    }
    
    open func mimeType() -> NSString{
        //
        if fileExist() == false{
            print("File Error -> File:(\(name)) Does not exist")
            return "--"
        }
        //taking help from StackOverFlow
        let fileName = name as NSString
        let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileName.pathExtension as CFString, nil)
        let mimeType = UTTypeCopyPreferredTagWithClass(UTI!.takeUnretainedValue(), kUTTagClassMIMEType)
        let mime = mimeType!.takeUnretainedValue() as NSString
        return mime
    }
    
    //MARK: operations
    
    open func read() -> Data?{
        if fileExist() == false{
            print("File Error -> File:(\(name)) Does not exist")
            return nil
        }
        let data = try? Data(contentsOf: URL)
        return data
    }
    
    open func write(_ data: Data) -> Bool{
        let isDone = (try? data.write(to: URL, options: [.atomic])) != nil
        calculateSize()
        return isDone
    }
    
    public final func calculateProgress(totalReadWrite rwBytes: Int, totalDataLength tdlBytes: Double, progress: IFileProgress?){
        if let delegate = progress{
            let calc = (Double(100 * rwBytes) / tdlBytes)
            DispatchQueue.main.async(execute: { () -> Void in
                delegate.readWriteProgress(calc)
            })
        }
    }
    
    fileprivate func write(from readfile: IFile, bufferSize: Int = 1024, progress: IFileProgress? = nil, encrypt: ((Data) -> Data)) -> Bool{
        var endResult = false
        if (readfile.fileExist() == false){
            print("File Error -> File:(\(readfile.name)) Does not exist")
            endResult = false
        }
        var readError: NSError?
        var writeError: NSError?
        do {
            let readHandler = try FileHandle(forReadingFrom: readfile.URL)
            readHandler.seek(toFileOffset: 0)
            if (readError != nil){
                print("File Error -> \(readError?.debugDescription)")
                endResult = false
            }
            
            let _ = delete()
            if (FileManager.default.createFile(atPath: URL.path, contents: nil, attributes: nil)){
                do {
                    let writeHandler = try FileHandle(forWritingTo: self.URL)
                    writeHandler.seek(toFileOffset: 0)
                    if (writeError != nil){
                        print("File Error -> \(writeError?.debugDescription)")
                        endResult = false
                    }
                    var buffer = readHandler.readData(ofLength: bufferSize)
                    var totalWritenLength: Int = 0
                    let readFileTotalBytes = readfile.sizeInBytes
                    while(buffer.count > 0){
                        totalWritenLength += buffer.count
                        let decoded = encrypt(buffer)
                        writeHandler.write(decoded)
                        calculateProgress(totalReadWrite: totalWritenLength, totalDataLength: readFileTotalBytes, progress: progress)
                        buffer = readHandler.readData(ofLength: bufferSize)
                        if buffer.count == 0{
                            let _ = encrypt(buffer)
                        }
                    }
                    print("Total bytes to read \(readfile.sizeInBytes) from \(readfile.name)")//
                    print("Total bytes writen \(totalWritenLength) to \(name)")//
                    writeHandler.synchronizeFile()
                    writeHandler.closeFile()
                    endResult = true
                } catch let error as NSError {
                    writeError = error
                } catch{
                    print("Error in \(#function) at line \(#line)")
                }
            }
            readHandler.closeFile()
        } catch let error as NSError {
            readError = error
        } catch{
            print("Error in \(#function) at line \(#line)")
        }
        return endResult
    }
    
    open func writeFrom(_ readfile: IFile, bufferSize: Int = 1024, progress: IFileProgress? = nil) -> Bool{
        let endResult = self.write(from: readfile, bufferSize: bufferSize, progress: progress) { (unEncrypted) -> Data in
            return unEncrypted
        }
        return endResult
    }
    
    open func writeAsynchFrom(_ readfile: IFile, bufferSize: Int = 1024, progress: IFileProgress? = nil, completionHandler: ((Bool) -> Void)? = nil){
        DispatchQueue.global().async { 
            let result = self.writeFrom(readfile, bufferSize: bufferSize, progress: progress)
            if let completion = completionHandler{
                completion(result)
            }
        }
    }
    
    open func writeAsynchTo(_ file: IFile, bufferSize: Int = 1024, progress: IFileProgress? = nil, completionHandler: ((Bool) -> Void)? = nil){
        DispatchQueue.global().async(execute: { () -> Void in
            let result = file.writeFrom(self, bufferSize: bufferSize, progress: progress)
            if let completion = completionHandler{
                completion(result)
            }
        })
    }
    
    open func delete() -> Bool{
        if fileExist(){
            var error: NSError?
            var result: Bool = false
            do {
                try FileManager.default.removeItem(at: URL)
                result = true
            } catch let error1 as NSError {
                error = error1
                result = false
                (error != nil) ? print("file delete -> \(error?.debugDescription)") : print("\(name) deleted")
            } catch{
                print("Error in \(#function) at line \(#line)")
            }
            return result
        }
        return false
    }
    
    open func rename(_ rename: String) -> Bool {
        if fileExist(){
            let sourcePath = URL.path
            let oldName = name
            let dirPath = (sourcePath as NSString).deletingLastPathComponent
            let destinationPath = (dirPath as NSString).appendingPathComponent(rename)
            var error: NSError?
            var result: Bool = false
            do {
                try FileManager.default.moveItem(atPath: sourcePath, toPath: destinationPath)
                result = true
            } catch let error1 as NSError {
                error = error1
                result = false
                (error != nil) ? print("file delete -> \(error?.debugDescription)") : print("\(oldName) rename to \(name)")
            } catch{
                print("Error in \(#function) at line \(#line)")
            }
            if result{
                let fileUrl = Foundation.URL(fileURLWithPath: destinationPath)
                _metadata = DocumentMetadata(url: fileUrl)
                calculateSize()
            }
            return result
        }
        return false
    }
    
    //MARK: DNObject Protocol
    
    open override func updateValue(_ value: Any!, forKey key: String!) {
        if key == "_metadata"{
            if value is NSDictionary{
                let path = (value as! NSDictionary).object(forKey: "URL") as! String
                let url = Foundation.URL(fileURLWithPath: path)
                _metadata = DocumentMetadata(url: url)
            }
            else{
                super.updateValue(value, forKey: key)
            }
        }
        else{
            super.updateValue(value, forKey: key)
        }
    }
    
    open override func serializeValue(_ value: Any!, forKey key: String!) -> Any! {
        return super.serializeValue(value, forKey: key) as AnyObject?
    }
    
    override open func updateDate(_ dateStr: String!) -> Date! {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.full
        return formatter.date(from: dateStr)
    }
    
    override open func serializeDate(_ date: Date!) -> String! {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.full
        return formatter.string(from: date)
    }
    
}

@objc(ISecureFile)
public protocol ISecureFile: NSObjectProtocol{
    func decrypted(bufferSize size: Int, progress: IFileProgress?, decrypt: ((Data) -> Data)?, completionHandler: @escaping (Data) -> Void ) -> Void
    func encrypted(bufferSize size: Int, progress: IFileProgress?, encrypt: ((Data) -> Data)?, completionHandler: @escaping (Data) -> Void ) -> Void
    func secureWriteFrom(_ readfile: IFile, bufferSize: Int, progress: IFileProgress?, encrypt: ((Data) -> Data)?, completionHandler: ((Bool) -> Void)? )
    func secureWriteTo(_ file: IFile, bufferSize: Int, progress: IFileProgress?, encrypt: ((Data) -> Data)?, completionHandler: ((Bool) -> Void)? )
}

extension File: ISecureFile{
    
    fileprivate func read(bufferSize size: Int = 1024, progress: IFileProgress?, crypto: ((Data)->Data)) -> Data{
        let endResult: NSMutableData = NSMutableData()
        var readError: NSError?
        do {
            let readHandler = try FileHandle(forReadingFrom: URL)
            readHandler.seek(toFileOffset: 0)
            if (readError != nil){
                print("File Error -> \(readError?.debugDescription)")
                return endResult as Data
            }
            var buffer = readHandler.readData(ofLength: size)
            var totalWritenLength: Int = 0
            while(buffer.count > 0){
                totalWritenLength += buffer.count
                let decoded = crypto(buffer)
                endResult.append(decoded)
                calculateProgress(totalReadWrite: totalWritenLength, totalDataLength: sizeInBytes, progress: progress)
                buffer = readHandler.readData(ofLength: size)
                if buffer.count == 0{
                    let _ = crypto(buffer)
                }
            }
            print("Total bytes to read \(sizeInBytes) from \(name)")//
            readHandler.closeFile()
        } catch let error as NSError {
            readError = error
        } catch{
            print("Error in \(#function) at line \(#line)")
        }
        return endResult as Data
    }
    
    @objc public func decrypted(bufferSize size: Int = 1024, progress: IFileProgress?, decrypt: ((Data) -> Data)?, completionHandler: @escaping (Data) -> Void) {
        DispatchQueue.global().async(execute: { () -> Void in
            var data: Data!
            if let crypto = decrypt{
                data = self.read(bufferSize: size, progress: progress, crypto: crypto)
            }
            else{
                data = self.read(bufferSize: size, progress: progress, crypto: { (unEncrypted) -> Data in
                    return unEncrypted
                })
            }
            completionHandler(data)
        })
    }
    
    @objc public func encrypted(bufferSize size: Int = 1024, progress: IFileProgress? = nil, encrypt: ((Data) -> Data)?, completionHandler: @escaping (Data) -> Void) {
        decrypted(bufferSize: size, progress: progress, decrypt: encrypt, completionHandler: completionHandler)
    }
    
    @objc public func secureWriteTo(_ file: IFile, bufferSize: Int, progress: IFileProgress?, encrypt: ((Data) -> Data)?, completionHandler: ((Bool) -> Void)? = nil) {
        (file as! ISecureFile).secureWriteFrom(self, bufferSize: bufferSize, progress: progress, encrypt: encrypt, completionHandler: completionHandler)
    }
    
    @objc public func secureWriteFrom( _ readfile: IFile, bufferSize: Int = 1024, progress: IFileProgress? = nil, encrypt: ((Data) -> Data)?, completionHandler: ((Bool) -> Void)? = nil) {
        DispatchQueue.global().async(execute: { () -> Void in
            var result = false
            if let crypto = encrypt{
                result = self.write(from: readfile, bufferSize: bufferSize, progress: progress, encrypt: crypto)
            }
            else{
                result = self.write(from: readfile, bufferSize: bufferSize, progress: progress, encrypt: { (unEncrypetd) -> Data in
                    return unEncrypetd
                })
            }
            if let completion = completionHandler{
                completion(result)
            }
        })
    }
    
}

