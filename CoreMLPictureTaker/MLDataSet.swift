//  MLDataSet.swift
//  CoreMLPictureTaker
//
//  Copyright (c) 2019 Antoine Barrault. All rights reserved.

import SwiftUI
import Combine

final class Bla: ObservableObject {
    var didChange = PassthroughSubject<Void, Never>()
    var bli: Bli
    init() {
        self.bli = Bli()
        self.didChange = self.bli.didChange

    }

    func called() {
        print(called)
    }

}

final class Bli: ObservableObject {
    let didChange = PassthroughSubject<Void, Never>()
    func callback() {
        self.didChange.send()
    }
}

protocol FileRepresention {
    func fileData() -> Data
    func name() -> String
}

final class MLDataSet<D: FileRepresention>: ObservableObject {

    let didChange = PassthroughSubject<[DataSet<D>]?, Never>()
    var isLoaded: Bool = false
    var diskLoader: DataFromDiskLoader<D>
    var data: [DataSet<D>]? {
        didSet {
            isLoaded = true
            DispatchQueue.main.async {
                self.didChange.send(self.data)
            }
        }
    }

    init() {
        self.diskLoader = DataFromDiskLoader()
        loadFromDisk()

       let _ = self.diskLoader.didChange.eraseToAnyPublisher().sink { _ in
            self.loadFromDisk()
        }
    }

    func loadFromDisk() {
        self.data = self.diskLoader.loadFromDisk()

    }

}


protocol StructuredFolder {
    var name: String { get set }
    init(name: String)
}

struct DataSet<D>: StructuredFolder {
    var name: String
    var data: [D]?

    init(name: String) {
        self.name = name
    }

    func bla()-> [D]? {
        return self.data
    }


}

extension DataSet where D == String {
    func bla()-> [D]? {
        return self.data
    }

}

final class DataFromDiskLoader<D: FileRepresention> {
    typealias dataModelGeneric = DataSet<D>
    let didChange = PassthroughSubject<Void, Never>()

    func loadFromDisk() -> [dataModelGeneric]? {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {

            do {
                var datas: [dataModelGeneric] = [dataModelGeneric]()
                let items = try fileManager.contentsOfDirectory(atPath: tDocumentDirectory.path)

                for item in items {
                    var dataModel = dataModelGeneric.init(name: item)
                    dataModel.data = [D]()
                    datas.append(dataModel)
                }
                return datas

            } catch {
                // failed to read directory – bad permissions, perhaps?
            }
        }

        return nil
    }

    func add(_ object: D, in data: dataModelGeneric) {
        if let path = folderOrCreate(with: data.name) {
            create(file: object.fileData(), at: path + object.name())
        }
    }


    func create(file data: Data, at path: String) -> Bool {
        let fm = FileManager.default
        return fm.createFile(atPath: path, contents: data, attributes: nil)
    }


    func deleteFolder(at path: String) -> Bool {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(path)")

            do {
                try fileManager.removeItem(at: filePath)
                self.didChange.send()
                return true
            }
            catch {
                return false
            }
        }
        return false

    }


    
    func createNewData(_ data: dataModelGeneric) {
       let created =  createNewFolder(named: data.name)
        if created {
            self.didChange.send()
        }
    }

    func folderOrCreate(with name: String) -> String? {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(name)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                    return filePath.path

                } catch {
                    return nil
                }
            } else {
                return filePath.path
            }
        }
        return nil
    }

    private func createNewFolder(named name: String) -> Bool {
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("\(name)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                    return true
                } catch {
                    return false
                }
            }
            NSLog("Document directory is \(filePath)")
        }

        return false

    }

}
