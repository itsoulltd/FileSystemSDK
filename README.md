# FileSystemSDK

### IFolder api:
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
    
### IFile api:
    var name: String {get}
    var URL: Foundation.URL{get}
    func isFile() -> Bool
    func fileExist() -> Bool
    func mimeType() -> NSString
    func read() -> Data?
    func write(_ data: Data) -> Bool
    func writeFrom(_ readfile: IFile, bufferSize: Int, progress: IFileProgress?) -> Bool
    func writeAsynchFrom(_ readfile: IFile, bufferSize: Int, progress: IFileProgress?, completionHandler: ((Bool) -> Void)?) -> Void
    func writeAsynchTo(_ file: IFile, bufferSize: Int, progress: IFileProgress?, completionHandler: ((Bool) -> Void)?) -> Void
    func delete() -> Bool
    func rename(_ rename: String) -> Bool
    
### Read a pdf file from app-bundle and save securly into app sandbox directory:
    //Example:
    //Read a file from app-bundle:
    let readUrl = Bundle.main.url(forResource: "books", withExtension: "pdf")
    let readFile = File(url: readUrl!)
    
    //Create a Folder to save a encrypted version of that pdf.
    let myFolder = Folder(name: "CryptoBooks"
          , searchDirectoryType: FileManager.SearchPathDirectory.documentDirectory)
    let writePath = (myFolder.path())?.appendingPathComponent("crypto-books.pdf")
    
    //Read chunk by chunk from books.pdf and write into crypto-books.pdf, 
    //each time encrypt readed bites using password.
    let cryptoFile = CryptoFile(url: URL(fileURLWithPath: writePath!))
    cryptoFile?.encrypt(from: readFile
        , bufferSize: 2048
        , password: "123456"
        , progress: nil
        , completionHandler: { (done) in
            print("Successfull \(done)")
        }
    )
    