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

    @Option(name: [.customLong("min"), .customShort("m")], help: "The minimum version.")
    var min: Version?

    @Option(name: [.customLong("max"), .customShort("M")], help: "The maximum version.")
    var max: Version?

    @Option(help: "Path that contains versionned folder")
    var path: String?

    @Argument(help: "Path of base to test.")
    var script: String

    lazy var versionProvider: VersionProvider =  {
        if let path = self.path {
            return FileProvider(path: path)
        }
        // return ListProvider(versions: [50, 78, 466, 799, 800])
        return AllMeanVersionProvider.instance
    }()

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

        var minValue = test(realMin)
        print(minValue.icon)
        while minValue == .skip && realMin < realMax {
            if let next = versionProvider.next(realMin) {
                realMin = next
                minValue = test(realMin)
                print(minValue.icon)
            } else {
                realMin = .max
            }
        }
        if minValue == .stop {
            print("🛑 min \(realMin) request to stop")
            Darwin.exit(128)
        }

        var maxValue = test(realMax)
        print(maxValue.icon)
        while maxValue == .skip && realMin < realMax {
            if let previous = versionProvider.previous(realMin) {
                realMax = previous
                maxValue = test(realMax)
                print(maxValue.icon)
            } else {
                realMax = -1
            }
        }
        if maxValue == .stop {
            print("🛑 max \(realMax) request to stop")
            Darwin.exit(128)
        }

        if realMin == realMax {
            print("‼️ No version found. Last tested \(realMax)")
        } else if minValue == maxValue {
            print("‼️ Nothing change between \(realMin) ➡ \(realMax)")
        } else {
            print("available no skip: \(realMin) ➡ \(realMax)")
            let result = bisect(min: (realMin, minValue), max: (realMax, maxValue))
            print("result: \(result.0) ➡ \(result.1)")
        }
    }

    mutating func bisect(min: (Version, BisectResult), max: (Version, BisectResult)) -> (Version, Version) {
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
        let result = test(toTest)
        print(result.icon)

        // check result
        switch (min.1, max.1, result) {
        case (.good, .bad, .good):
            return bisect(min: (toTest, result), max: max)
        case (.good, .bad, .bad):
            return bisect(min: min, max: (toTest, result))
        case (.bad, .good, .good):
            return bisect(min: min, max: (toTest, result))
        case (.bad, .good, .bad):
            return bisect(min: (toTest, result), max: max)
        case (_, _, .skip):
            versionProvider.remove(toTest)
            return bisect(min: min, max: max)
        default:
            assertionFailure("Not filtered error \(min.1), \(max.1), \(result)")
            return (Version.min, Version.min)
        }
    }

    /// Do the test for specific version
    func test(_ value: Version) -> BisectResult {
        print("test: \(value) ", terminator: "")

        let code = shell(self.script, "\(value)", "\(path ?? "")")
        return BisectResult(code: code)
    }

}
