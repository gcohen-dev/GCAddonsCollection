//
//  File.swift
//  
//
//  Created by Guy Cohen on 19/06/2020.
//

import Foundation

/// Use this class to save and read files from disk by Data, Archive or Decode.
/// Bare in mind these caching folders are going to be deleted when enviroment is changing
/// Choose carefully the directory you want to save your files whether it's documents or cache.

public protocol GCFileCaching {

    /// Initialize this class with a unique folder name
    /// Please use the name of the class as a prefix for the folder
    ///
    /// - Parameters:
    ///   - cacheFolder: The subfolder in `rootfolder`
    ///   - directory: The directory for our cacheFolder
    init(_ cacheFolder:String, in directory:GCFileCache.Directory)
    
    
    /// Represent the cacheFolder URL
    var subRootCacheFolder: URL { get }
    
    /// Will try to get the data
    ///
    /// - Parameters:
    ///   - filename: File name to try to read from
    ///   - isArchived: is file archived
    /// - Returns: will try to return the correct data
    func getData(filename:String) -> Data?
    
    /// Will try to unarchive data
    ///
    /// - Parameter filename: the file name
    /// - Returns: return the object if success
    func unarchiveData(filename:String) -> Any?
    
    /// Will return codable object
    ///
    /// - Parameters:
    ///   - filename: the file name
    ///   - type: the class type
    /// - Returns: codable object
    func decode<T: Decodable>(_ filename:String, type:T.Type) -> T?
    
    /// Will save data into disk
    ///
    /// - Parameters:
    ///   - filename: represent the file name
    ///   - data: the data to save
    ///   - isAsynchronous: true for asynchronous false for synchronous save.
    func save(data:Data, filename:String, isAsynchronous:Bool, completion: (() -> Void)?)
    
    /// will archive data to disk
    ///
    /// - Parameters:
    ///   - archivedData: the archived data
    ///   - filename: the file name
    func archive(archivedData:Any, filename:String, completion: (() -> Void)?)
    
    /// Will save any codable type to disk
    ///
    /// - Parameters:
    ///   - encodableObject: the codable object
    ///   - filename: the file name
    func encode<T: Encodable>(encodableObject:T, filename:String, completion: (() -> Void)?)
    
    /// Will delete file from disk if exists
    ///
    /// - Parameter filename: the file name
    func delete(filename: String)
    
    /// Will remove file if exists
    ///
    /// - Parameter file: The given file
    func removeIfFileExists(_ file:URL?)
    
    /// Determines if the file at the specified path exists.
    ///
    /// - Parameter filePath: The file path of the file to check.
    /// - Returns: True if the file exists, or false if the file does not exist.
    func fileExists(atFilePath filePath: URL) -> Bool
    
    /// Will remove the given folder content
    ///
    /// - Parameter folderUrl: the given folder
    func removeFolderContent(_ folderUrl:URL?)
    
    /// Will return the full path
    ///
    /// - Parameter fileName: Represent the file name
    /// - Returns: the full path to the file
    func getFilePath(fileName:String) -> URL
}

/// Extension for SFGBaseFileCaching to provide a default implemation
public extension GCFileCaching {
    func save(data:Data, filename:String) {
        self.save(data: data, filename: filename, isAsynchronous: true, completion: nil)
    }
    func archive(archivedData:Any, filename:String) {
        self.archive(archivedData: archivedData, filename: filename, completion: nil)
    }
    func encode<T: Encodable>(encodableObject:T, filename:String) {
        self.encode(encodableObject: encodableObject, filename: filename, completion: nil)
    }
}

open class GCFileCache: GCFileCaching {
    
    // rootfolder should not be changed since it's the root folder of all the cache folders we have created.
    public static let rootFolder = "rootfolder"
    private let queue = DispatchQueue.global(qos: .background)

    public enum Directory {
        
        case document
        case cache
        
        func path() -> FileManager.SearchPathDirectory{
            switch self {
                /// should be stored in the <Application_Home>/Documents directory and will be automatically backed up by iCloud.
            case .document:
                return .documentDirectory
                /// data that can be downloaded again or regenerated should be stored in the <Application_Home>/Library/Caches directory.
            case .cache:
                return .cachesDirectory
            }
        }
    }
    
    let cacheFolder:String
    let directory:Directory
    
    public var subRootCacheFolder: URL {
        return FileManager.default.urls(for: directory.path(), in: .userDomainMask).first!.appendingPathComponent(GCFileCache.rootFolder).appendingPathComponent(cacheFolder)
    }
    
    public required init(_ cacheFolder:String, in directory:Directory) {
        self.cacheFolder = cacheFolder
        self.directory = directory
//        super.init()
        createDirectory()
    }
    
    public func getData(filename:String) -> Data? {
        let path = self.getFilePath(fileName: filename)
        if !FileManager.default.fileExists(atPath: path.path){
            return nil
        }
        return try? Data(contentsOf: path)
    }
    
    public func unarchiveData(filename:String) -> Any? {
        let path = self.getFilePath(fileName: filename)
        if !FileManager.default.fileExists(atPath: path.path){
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(withFile: path.path)
    }
    
    public func decode<T: Decodable>(_ filename:String, type:T.Type) -> T? {
        let urlPath = self.getFilePath(fileName: filename)
        if !FileManager.default.fileExists(atPath: urlPath.path){
            return nil
        }
        if let data = FileManager.default.contents(atPath: urlPath.path){
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                print("SFGBaseFileCache decode error:\(error)")
            }
        }
        return nil
    }
    
    public func save(data:Data, filename:String, isAsynchronous:Bool = true, completion: (() -> Void)? = nil) {
        if isAsynchronous {
            queue.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.saveOperation(data: data, filename: filename)
                completion?()
            }
        } else {
            self.saveOperation(data:data, filename:filename)
            completion?()
        }
    }
    
    private func saveOperation(data:Data, filename:String){
        let file = self.getFilePath(fileName: filename)
        self.removeIfFileExists(file)
        self.writeData(path: file, data: data)
    }

    public func archive(archivedData:Any, filename:String, completion: (() -> Void)? = nil) {
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            let file = strongSelf.getFilePath(fileName: filename)
            strongSelf.removeIfFileExists(file)
            let dataToSave = NSKeyedArchiver.archivedData(withRootObject: archivedData)
            strongSelf.writeData(path: file, data: dataToSave)
            completion?()
        }
    }
    
    public func encode<T: Encodable>(encodableObject:T, filename:String, completion: (() -> Void)? = nil) {
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            let file = strongSelf.getFilePath(fileName: filename)
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(encodableObject)
                strongSelf.removeIfFileExists(file)
                strongSelf.writeData(path: file, data: data)
            } catch {
                print("SFGBaseFileCache save encodable failed \(error)")
            }
            completion?()
        }
    }

    public func delete(filename: String) {
        let file = self.getFilePath(fileName: filename)
        self.removeIfFileExists(file)
    }
    
    /// Will write data to disk
    ///
    /// - Parameters:
    ///   - path: the full path
    ///   - data: data to write
    private func writeData(path:URL?, data:Data) {
        guard let path = path else { return }
        do {
            try data.write(to: path, options: .atomic)
        } catch {
            print("SFGBaseFileCache Error in saving: \(error) into path:\(path) ")
        }
    }
    
   public func removeFolderContent(_ folderUrl:URL?){
        guard let folderUrl = folderUrl else { return }
        
        guard let filePaths = try? FileManager.default.contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            try? FileManager.default.removeItem(at: filePath)
        }
    }
    
    public func removeIfFileExists(_ file:URL?){
        guard let file = file else { return }
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("SFGBaseFileCache error in removing file: \(error) in path:\(file.path)")
        }
    }
    
    public func fileExists(atFilePath filePath: URL) -> Bool {
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    public func getFilePath(fileName:String) -> URL {
        return subRootCacheFolder.appendingPathComponent(fileName)
    }
    
    /// Create cache directoty if needed
    private func createDirectory(){
        if (FileManager.default.fileExists(atPath: subRootCacheFolder.path) == false){
            do {
                try FileManager.default.createDirectory(at: self.subRootCacheFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("SFGBaseFileCache \(error)")
            }
        }
    }
}
