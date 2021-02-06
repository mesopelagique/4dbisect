//
//  File.swift
//  
//
//  Created by emarchand on 06/02/2021.
//

import Foundation

typealias Version = Int

protocol VersionProvider {

    /// get an available version
    func get(_ value: Version, _ comp: BisectComparator) -> Version?

    /// return the next version to test according to min and max
    func next(min: Version, max: Version) -> Version?

    func next(_ value: Version) -> Version?
    func previous(_ value: Version) -> Version?
    func remove(_ value: Version)
}

// mock to test
struct AllMeanVersionProvider: VersionProvider {
    
    static let instance = AllMeanVersionProvider()

    func get(_ value: Version, _ comp: BisectComparator) -> Version? {
        return value // all
    }
    
    func next(min: Version, max: Version) -> Version? {
        if min == max {
            return nil
        }
        if min.advanced(by: 1) == max {
            return nil
        }
        return (min + max) / 2 //mean
    }

    func next(_ value: Version) -> Version? {
        return value + 1
    }
    func previous(_ value: Version) -> Version? {
        return value - 1
    }
    func remove(_ value: Version) {
    }
}

class ListProvider: VersionProvider {
    var versions: [Version]
    init(versions: [Version]) {
        self.versions = versions.sorted()
    }

    func get(_ value: Version, _ comp: BisectComparator) -> Version? {
        if versions.contains(value) {
            return value
        }
        switch comp {
        case .equalsOrLower:
            for version in versions.reversed() {
                if version < value {
                    return version
                }
            }
        case .equalsOrUpper:
            for version in versions {
                if version > value {
                    return version
                }
            }
        }
        return nil
    }
    
    func next(min: Version, max: Version) -> Version? {
        guard let minPos = versions.firstIndex(of: min),
              let maxPos = versions.firstIndex(of: max) else {
            return nil
        }
        let interval = Array(versions[minPos...maxPos])
        if interval.count <= 2 {
            return nil
        }
        let midPos = interval.count / 2

        if midPos >= interval.count {
            return nil
        }
        if midPos == minPos {
            return nil
        }
        if midPos == maxPos {
            return nil
        }
        return interval[midPos]
    }
    
    func next(_ value: Version) -> Version? {
        guard let pos = versions.firstIndex(of: value) else {
            return nil
        }
        let nextPos = pos.advanced(by: 1)
        if nextPos < versions.count {
            return versions[nextPos]
        }
        return nil
    }
    func previous(_ value: Version) -> Version? {
        guard let pos = versions.firstIndex(of: value) else {
            return nil
        }
        let nextPos = pos.advanced(by: -1)
        if nextPos >= 0 {
            return versions[nextPos]
        }
        return nil
    }
    func remove(_ value: Version) {
        if let pos = versions.firstIndex(of: value) {
            versions.remove(at: pos)
        }
    }
}

class FileProvider: ListProvider {
    init(path: String) {
        var versions: [Version] = []
        for child in ((try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []) {
            if FileProvider.directoryExists(at: path+"/"+child) {
                if let version = Version(child) {
                    versions.append(version)
                }
            }
        }
        super.init(versions: versions)
    }

    fileprivate static func directoryExists(at path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

