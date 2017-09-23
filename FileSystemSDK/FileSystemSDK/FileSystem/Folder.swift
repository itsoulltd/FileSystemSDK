//
//  BaseWizard.swift
//  DubaiArchive
//
//  Created by Towhid on 4/29/15.
//  Copyright (c) 2017 Next Generation Object Ltd. All rights reserved.
//

import Foundation

@objc(IFolder)
public protocol IFolder: NSObjectProtocol{
    var metadata: IDocumentMetadata {get}
    var name: String {get}
    var URL: Foundation.URL {get}
    var sizeInBytes: Double {get}
    var sizeInKBytes: Double {get}
    var sizeInMBytes: Double {get}
    var sizeInGBytes: Double {get}
    func calculateSize() -> Double
    func calculateFilesSize() -> Double
    func path() -> NSString?
    func isFolder() -> Bool
    func exist() -> Bool
    func addSubfolder(_ name: String) -> IFolder
    func subfolder(_ name: String) -> IFolder
    func rename(_ name: String) -> Bool
    func delete() -> Bool
    func moveTo(_ folder: IFolder) -> IFolder?
    func copyFrom(_ folder: IFolder) -> Bool
    func searchfolders(_ folderName: String?) -> [IFolder]
    func searchfiles(_ extention: String?) -> [IFile]
    func moveIn(_ file: IFile, replace: Bool) -> Bool
    func copyOf(_ file: IFile, replace: Bool) -> Bool
}

@objc(Folder)
open class Folder: NSObject, FileManagerDelegate, IFolder {
    
    fileprivate var defaultName = "untitled folder"
    fileprivate var _metadata: IDocumentMetadata!
    fileprivate let fileManager = FileManager.default
    fileprivate lazy var privateFileManager = FileManager()
    fileprivate var searchDirectoryType: FileManager.SearchPathDirectory!
    
    public init(name: String? = nil, searchDirectoryType: FileManager.SearchPathDirectory = FileManager.SearchPathDirectory.documentDirectory) {
        super.init()
        self.searchDirectoryType = searchDirectoryType
        if let root = name{
            if root.characters.count >= 1{
                defaultName = root
            }
        }
        createIfNotExist()
    }
    
    fileprivate func createIfNotExist(){
        //
        let currentPath = path()
        if fileManager.fileExists(atPath: currentPath! as String) == false{
            do{
                try fileManager.createDirectory(atPath: currentPath as! String, withIntermediateDirectories: true, attributes: nil)
                messageLogger("createRootDirectoryIfNotExist", message: "\(defaultName) is created")
            } catch let error as NSError{
                errorLogger("createRootDirectoryIfNotExist", error: error)
            }
        }
        else{
            messageLogger("createRootDirectoryIfNotExist", message: "\(defaultName) already exist")
        }
        _metadata = DocumentMetadata(url: Foundation.URL(fileURLWithPath: currentPath! as String))
    }
    
    fileprivate func getUserDirectoryPath() -> NSString?{
        //
        let directories = fileManager.urls(for: searchDirectoryType, in: FileManager.SearchPathDomainMask.userDomainMask) as NSArray
        let directoryPath = (directories.lastObject as! Foundation.URL).path
        return directoryPath as NSString?
    }
    
    //MARK: IFolder Impl
    
    open var metadata: IDocumentMetadata { return _metadata}
    
    open func path() -> NSString?{
        //
        let directoryPath = getUserDirectoryPath()
        let finalPath = directoryPath?.appendingPathComponent(defaultName)
        return finalPath as NSString?
    }
    
    deinit{
        //remove notifications
        print("deinit \(NSStringFromClass(type(of: self)))")
    }
    
    open func isFolder() -> Bool{
        //
        if let type = self.metadata.documentType(){
            return type as FileAttributeType == FileAttributeType.typeDirectory
        }
        return false
    }
    
    open var name: String{
        return defaultName
    }
    
    open var URL: Foundation.URL{
        return self.metadata.documentUrl as URL
    }
    
    fileprivate var isFolderExist = false
    
    open func exist() -> Bool{
        //
        if isFolderExist == false{
            isFolderExist = fileManager.fileExists(atPath: URL.path)
        }
        return isFolderExist
    }
    
    open func addSubfolder(_ name: String) -> IFolder{
        //
        if !exist(){
            createIfNotExist()
        }
        let resolvedName = resolveChildName(name: name)
        let newFolder = subfolder(resolvedName)
        return newFolder
    }
    
    open func rename(_ name: String) -> Bool{
        //
        if !exist(){
            return false
        }
        if let srcPath = path(){
            if let destPath = getUserDirectoryPath()?.appendingPathComponent(name){
                if (fileManager.fileExists(atPath: destPath) == false){
                    do{
                       try fileManager.moveItem(atPath: srcPath as String, toPath: destPath)
                        self.defaultName = name
                        messageLogger("rename", message: "Rename to \(name) is successfull.")
                        return true
                    } catch let error as NSError{
                        errorLogger("rename", error: error)
                    }
                }
            }
        }
        return false
    }
    
    open func delete() -> Bool{
        //
        if !exist(){
            return false
        }
        if let path = path(){
            do{
               try fileManager.removeItem(atPath: path as String)
                messageLogger("delete", message: "Delete \(self.name) is successfull.")
                self.isFolderExist = false
                return true
            } catch let error as NSError{
                errorLogger("delete", error: error)
            }
        }
        return false
    }
    
    open func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, movingItemAtPath srcPath: String, toPath dstPath: String) -> Bool {
        //
        messageLogger("fileManager -> shouldProceedAfterError", message: "Error -> moving Item from path :: \(srcPath)")
        return true
    }
    
    open func moveTo(_ folder: IFolder) -> IFolder?{
        //
        if !exist(){
            return nil
        }
        let lastPathComponent = (self.name as NSString).lastPathComponent
        let subFolder = folder.subfolder(lastPathComponent)
        if subFolder.copyFrom(self){
            return subFolder
        }
        return nil
    }
    
    open func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool {
        //
        messageLogger("fileManager -> shouldProceedAfterError", message: "Error -> copying Item from path :: \(srcPath)")
        return true
    }
    
    open func copyFrom(_ folder: IFolder) -> Bool{
        //
        if !exist(){
            return false
        }
        if let srcPath = folder.path(){
            if let destPath = self.path(){
                do{
                    self.privateFileManager.delegate = self
                    try privateFileManager.copyItem(atPath: srcPath as String, toPath: destPath as String)
                    self.privateFileManager.delegate = nil
                    messageLogger("copy", message: "Copy From \(folder.name) is successfull.")
                    return true
                } catch let error as NSError{
                    errorLogger("copy", error: error)
                    self.privateFileManager.delegate = nil
                }
            }
        }
        return false
        //
    }
    
    open func subfolder(_ name: String) -> IFolder{
        let relativeToParent = "\(self.name)/\(name)"
        let newFolder = Folder(name: relativeToParent, searchDirectoryType: searchDirectoryType)
        return newFolder
    }
    
    open func searchfolders(_ folderName: String? = nil) -> [IFolder]{
        //
        var folders = [IFolder]()
        //var keys: [String] = [NSURLAddedToDirectoryDateKey,NSURLCreationDateKey,NSURLContentAccessDateKey,NSURLContentModificationDateKey,NSURLIsDirectoryKey,NSURLIsHiddenKey,NSURLThumbnailDictionaryKey,NSURLTypeIdentifierKey]
        if let fromDirectoryPath = path(){
            do{
                if let listOfFolders = try fileManager.contentsOfDirectory(atPath: fromDirectoryPath as String) as NSArray?{
                    if let suffex = folderName{
                        let predicate = NSPredicate(format: "SELF CONTAINS[c] '\(suffex)'")
                        let filteredList = listOfFolders.filtered(using: predicate) as NSArray
                        folders = getFolders(filteredList as! [String])
                    }
                    else{
                        folders = getFolders(listOfFolders as! [String])
                    }
                }
            } catch let error as NSError{
                print("Error \(error.debugDescription)")
            }
        }
        return folders
    }
    
    open func searchfiles(_ extention: String? = nil) -> [IFile]{
        //
        var documents = [IFile]()
        if let fromDirectoryPath = path(){
            do{
                if let listOfFiles = try fileManager.contentsOfDirectory(atPath: fromDirectoryPath as String) as NSArray?{
                    if let suffex = extention{
                        let predicate = NSPredicate(format: "SELF CONTAINS[c] '\(suffex)'")
                        let filteredList = listOfFiles.filtered(using: predicate) as NSArray
                        documents = getFiles(filteredList as! [String])
                    }
                    else{
                        documents = getFiles(listOfFiles as! [String])
                    }
                }
            } catch let error as NSError{
                print("Error \(error.debugDescription)")
            }
        }
        return documents
    }
    
    //MARK: Public pretty operations
    
    final func errorLogger(_ funcName: String, error: NSError? = nil){
        if let err = error{
            print("\(NSStringFromClass(type(of: self))) -> (\(funcName)) :: \(err.debugDescription)")
        }
        else{
            messageLogger(funcName, message: "NSError is nil")
        }
    }
    
    final func messageLogger(_ funcName: String, message: String){
        print("\(NSStringFromClass(type(of: self))) -> (\(funcName)) :: \(message)")
    }
    
    public final func resolveChildName(name oldName: String) -> String{
        //
        let onlyName = (oldName as NSString).deletingPathExtension
        let extention = (oldName as NSString).pathExtension
        if (extention.characters.count > 0){
            var newName = recursivelyResolveChildName(name: onlyName, newName: onlyName, extention: extention)
            newName = "\(newName).\(extention)"
            return newName
        }
        else{
            let newName = recursivelyResolveChildName(name: onlyName, newName: onlyName)
            return newName
        }
    }
    
    fileprivate func contains(_ name: String?) -> (Bool, NSString?){
        if let content = name{
            if let filePath = contentPath(content: content){
                let isTrue = fileManager.fileExists(atPath: filePath as String)
                return (isTrue, filePath)
            }
        }
        return (false, nil)
    }
    
    fileprivate func allContentsSearchBy(_ name: String? = nil) -> (folders: [IFolder], files: [IFile]){
        let _files = searchfiles(name) //files(searchBy: name)
        let _folders = searchfolders(name) //subfolders(searchBy: name)
        return (_folders, _files)
    }
    
    //MARK: some unnecessary file operation
    
    open func saveAs(_ fileName: String, data: Data, replace: Bool = true) -> (Foundation.URL?){
        //
        if !exist(){
            return (nil)
        }
        if (replace){
            if removeBy(fileName){
                messageLogger("saveAs", message: "\(fileName) has removed")
            }
        }
        let finalName = resolveChildName(name: fileName)
        let path = contentPath(content: finalName)
        let url = Foundation.URL(fileURLWithPath: path! as String)
        let saveAsFile = File(url: url)
        let _ = saveAsFile.write(data)
        return (url)
    }
    
    open func pasteContent(_ file: IFile, replace: Bool = true) -> (Foundation.URL?){
        //
        if (exist() == false && file.fileExist() == false && file.isFile() == false){
            return (nil)
        }
        if (replace){
            if removeBy(file.name){
                messageLogger("paste", message: "\(file.name) has removed")
            }
        }
        let finalName = resolveChildName(name: file.name)
        let path = contentPath(content: finalName)
        let url = Foundation.URL(fileURLWithPath: path! as String)
        let pastedFile = File(url: url)
        if let writable = file.read(){
            let _ = pastedFile.write(writable)
            return (url)
        }
        return (nil)
    }
    
    open func moveIn(_ file: IFile, replace: Bool = true) -> Bool{
        if (exist() == false && file.fileExist() == false && file.isFile() == false){
            return false
        }
        if (replace){
            if removeBy(file.name){
                messageLogger("MoveContent", message: "\(file.name) has removed")
            }
        }
        do{
            let sourcePath = file.URL.path
            let destPath = self.path()?.appendingPathComponent(file.name)
            try FileManager.default.moveItem(atPath: sourcePath, toPath: destPath!)
            messageLogger("MoveContent", message: "Move From is successfull.")
            return true
        }catch let error as NSError{
            errorLogger("MoveContent", error: error)
        }
        return false
    }
    
    open func copyOf(_ file: IFile, replace: Bool = true) -> Bool{
        if (exist() == false && file.fileExist() == false && file.isFile() == false){
            return false
        }
        if (replace){
            if removeBy(file.name){
                messageLogger("CopyContent", message: "\(file.name) has removed")
            }
        }
        do{
            let sourcePath = file.URL.path
            let destPath = self.path()?.appendingPathComponent(file.name)
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destPath!)
            messageLogger("CopyContent", message: "copy From is successfull.")
            return true
        }catch let error as NSError{
            errorLogger("CopyContent", error: error)
        }
        return false
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if object is IFolder {
            if let target: IFolder = object as? IFolder{
                let equal = self.path()!.isEqual(to: (target.path() as? String)!)
                return equal
            }
        }
        return false
    }
    
    open func deleteContentByName(_ name: String) -> Bool{
        return removeBy(name)
    }
    
    open func deleteContent(_ file: IFile) -> Bool{
        return removeBy(file.name)
    }
    
    //MARK: Folder Content Size IN
    
    fileprivate var size: NSNumber = 0.0
    
    open func calculateSize() -> Double{
        var mutable: Double = self.calculateFilesSize()
        let folders = searchfolders(nil)
        for folder in folders {
            mutable = mutable + folder.calculateSize()
        }
        return mutable
    }
    
    open func calculateFilesSize() -> Double{
        var mutable: Double = 0.0
        let files = searchfiles(nil)
        for file in files {
            mutable = mutable + file.sizeInBytes
        }
        return mutable
    }
    
    open func calculateSize(_ onCompletion:@escaping ((_ sizeInBytes: NSNumber) -> Void)){
        DispatchQueue.global().async {
            var mutable: Double = self.calculateFilesSize()
            let folders = self.searchfolders(nil)
            for folder in folders {
                mutable = mutable + folder.calculateSize()
            }
            DispatchQueue.main.async(execute: { 
                onCompletion(NSNumber(value: mutable as Double))
            })
        }
    }
    
    open var sizeInBytes: Double{
        size = NSNumber(value: calculateSize())
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
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    fileprivate func recursivelyResolveChildName(name oldName: String, newName: String, extention: String? = nil, count: Int = 2) -> String{
        //
        let isExist: (exist: Bool, path: NSString?) = (extention == nil) ? contains(newName) : contains("\(newName).\(extention!)")
        if isExist.exist == false{
            return newName
        }
        else{
            let newName = "\(oldName) \(count)"
            let xCount = count + 1
            return recursivelyResolveChildName(name: oldName, newName: newName, extention: extention, count: xCount)
        }
    }
    
    fileprivate func getFolders(_ listOfFolders: [String]) -> [IFolder]{
        //
        var folders = [IFolder]()
        for folderName in listOfFolders{
            let folder = subfolder(folderName)
            if folder.isFolder(){
                folders.append(folder)
            }
        }
        return folders
    }
    
    fileprivate func getFiles(_ listOfFiles: [String]) -> [IFile]{
        //
        var documents = [IFile]()
        for fileName in listOfFiles{
            let url = Foundation.URL(fileURLWithPath: contentPath(content: fileName)! as String)
            let file = File(url: url)
            if file.isFile(){
                documents.append(file)
            }
        }
        return documents
    }
    
    fileprivate func contentPath(content fileName: String) -> NSString?{
        //
        let rootPath = path()
        let finalPath = rootPath?.appendingPathComponent(fileName)
        return finalPath as NSString?
    }
    
    fileprivate func removeFrom(_ filePath: String) -> Bool{
        //
        let url = Foundation.URL(fileURLWithPath: filePath)
        let isRemoved: Bool
        do {
            try fileManager.removeItem(at: url)
            isRemoved = true
        } catch let error as NSError {
            isRemoved = false
            errorLogger("removeFrom", error: error)
        }
        return isRemoved
    }
    
    fileprivate func removeBy(_ fileName: String?) -> Bool{
        //
        let isExist: (exist: Bool, path: NSString?) = contains(fileName)
        if isExist.exist{
            let isRemoved = removeFrom(isExist.path! as String)
            if isRemoved{
                messageLogger("delete", message: "\(fileName) deleted")
            }
            return isRemoved
        }
        return isExist.exist
    }
}
