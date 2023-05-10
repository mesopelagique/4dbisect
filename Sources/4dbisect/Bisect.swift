//
//  Bisect.swift
//  
//
//  Created by emarchand on 06/02/2021.
//

import Foundation
import ArgumentParser

struct Bisect: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "4dbisect",
        abstract: "Find when it failed."
    )

    @Option(name: [.customLong("min"), .customShort("m")], help: "The minimum version. (default: 0)")
    var min: Version?

    @Option(name: [.customLong("max"), .customShort("M")], help: "The maximum version. (default: integer max)")
    var max: Version?

    @Option(help: "Full path that contains versionned folder")
    var path: String?

    @Option(name: [.customLong("product")], help: "Compute path according to 4D product version: /Volumes/ENGINEERING/Products/Compiled/Build/<product>")
    var product: String?

    @Argument(help: "Path of script to launch the test.\nThe script well receive \n\t- the version to test\n\tthe path of all products\nSo <path>/<version> will contain the product.\n\nThe script must return:\n\t✅ 0 if ok \n\t🌀 125 if no product found to skip\n\t🛑 128 to stop all process\n\t❌ any other code if the test failed")
    var script: [String]
    
    // action to do
    private var test: Test? {
        if let scriptPath = script.first, !scriptPath.hasPrefix("-") {
            return .executeScript(script: scriptPath, args: Array(script.dropFirst()))
        } else {
            let projectURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true).appendingPathComponent("Project")
            if let files = try? FileManager.default.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants).filter({ $0.pathExtension == "4DProject" }) {
                if let base = files.first {
                    return .openBase(url: base, args: script)
                }
            }
        }
        return nil
    }
    private var finalPath: String?

    lazy var versionProvider: VersionProvider =  {
        if let path = self.path {
            self.finalPath = path
            return FileProvider(path: path)
        }
        if let product = product {
            if product == "main" {
                print("‼️ You must use Main")
            }
            self.finalPath  = "/Volumes/ENGINEERING/Products/Compiled/Build/\(product)"
            if !FileManager.default.fileExists(atPath: self.finalPath ?? "") {
                print("‼️ You must specify --path or check if this path exists \( self.finalPath ?? ""), ie. mount srv-4d")
            }
            return FileProvider(path: "/Volumes/ENGINEERING/Products/Compiled/Build/\(product)")
        }
        // return ListProvider(versions: [50, 78, 466, 799, 800])
        return AllMeanVersionProvider.instance
    }()

    mutating func validate() throws {
        if self.test == nil {
            throw ValidationError("You must provide a script as argument or be in 4d project folder")
        }
    }

    mutating func run() throws {
        let min = self.min ?? Version.zero
        let max = self.max ?? Version.max
        print("parameters: \(min) ➡ \(max)")

        guard var realMin = versionProvider.get(min, .equalsOrUpper) else {
            print("‼️ No available version for min \(min)")
            return
        }
        guard var realMax = versionProvider.get(max, .equalsOrLower) else {
            print("‼️ No available version for max \(max)")
            return
        }
        print("available: \(realMin) ➡ \(realMax)")

        guard let test = self.test else {
            print("‼️ No test to do")
            Darwin.exit(BisectResult.stop.code)
        }
   
        var minValue = test.run(version: realMin, path: finalPath)
        print(minValue.icon)
        while minValue == .skip && realMin < realMax {
            if let next = versionProvider.next(realMin) {
                realMin = next
                minValue = test.run(version: realMin, path: finalPath)
                print(minValue.icon)
            } else {
                realMin = .max
            }
        }
        if minValue == .stop {
            print("🛑 min \(realMin) request to stop")
            Darwin.exit(BisectResult.stop.code)
        }
        var maxValue = test.run(version: realMax, path: finalPath)
        print(maxValue.icon)
        while maxValue == .skip && realMin < realMax {
            if let previous = versionProvider.previous(realMin) {
                realMax = previous
                maxValue = test.run(version: realMax, path: finalPath)
                print(maxValue.icon)
            } else {
                realMax = -1
            }
        }
        if maxValue == .stop {
            print("🛑 max \(realMax) request to stop")
            Darwin.exit(BisectResult.stop.code)
        }

        if realMin == realMax {
            print("‼️ No version found. Last tested \(realMax)")
        } else if minValue == maxValue {
            print("‼️ Nothing change between \(realMin) ➡ \(realMax)")
        } else {
            print("available no skip: \(realMin) ➡ \(realMax)")
            let result = bisect(min: (realMin, minValue), max: (realMax, maxValue), test: test)
            print("result: \(result.0) ➡ \(result.1)")
        }
    }

    mutating func bisect(min: (Version, BisectResult), max: (Version, BisectResult), test: Test) -> (Version, Version) {
        switch (min.1, max.1) {
        case (.good, .good):
            return (min.0, max.0)
        case (.bad, .bad):
            return (min.0, max.0)
        default:
             break
        }

        guard let toTest = versionProvider.next(min: min.0, max: max.0) else {
            return (min.0, max.0) // no more things to test
        }

        // launch test
        let result = test.run(version: toTest, path: finalPath)
        print(result.icon)

        // check result
        switch (min.1, max.1, result) {
        case (.good, .bad, .good):
            return bisect(min: (toTest, result), max: max, test: test)
        case (.good, .bad, .bad):
            return bisect(min: min, max: (toTest, result), test: test)
        case (.bad, .good, .good):
            return bisect(min: min, max: (toTest, result), test: test)
        case (.bad, .good, .bad):
            return bisect(min: (toTest, result), max: max, test: test)
        case (_, _, .skip):
            versionProvider.remove(toTest)
            return bisect(min: min, max: max, test: test)
        default:
            assertionFailure("Not filtered error \(min.1), \(max.1), \(result)")
            return (Version.min, Version.min)
        }
    }
 
}
