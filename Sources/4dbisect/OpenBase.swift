//
//  OpenBase.swift
//  
//
//  Created by emarchand on 10/05/2023.
//

import Foundation

class OpenBase {
    static let onStatupCode = """
//%attributes = {}
    ON ERR CALL:C155(\"onBisectError\")
    test
    If (Not:C34(Shift down:C543))
      QUIT 4D:C291()
    End if
"""

    static let onErrorCode = """
//%attributes = {}
$folder:=Folder:C1567(fk resources folder:K87:11)
If (Not:C34($folder.exists))
    $folder.create()
End if
$folder.file("error").setText("")
"""

    static func checkDatabaseMethod(_ base: URL) -> Bool {
        let onStartup: URL
        let rootBase = base.deletingLastPathComponent().deletingLastPathComponent()
        if #available(macOS 13.0, *) {
            onStartup = rootBase.appending(path: "Project/Sources/DatabaseMethods/onStartup.4dm")
        } else {
            onStartup = rootBase.appendingPathComponent("Project/Sources/DatabaseMethods/onStartup.4dm")
        }

        if (!FileManager.default.fileExists(atPath: onStartup.path)) {

            if fileExists(rootBase.appendingPathComponent("Project/Sources/Methods/test.4dm").path) {
                print("⚠️ No startup method defined in base. One will be created to launch test method")
                try? onStatupCode.write(to: onStartup, atomically: true, encoding: .utf8)

                let onError: URL
                if #available(macOS 13.0, *) {
                    onError = rootBase.appending(path: "Project/Sources/Methods/onBisectError.4dm")
                } else {
                    onError = rootBase.appendingPathComponent("Project/Sources/Methods/onBisectError.4dm")
                }
                try? onErrorCode.write(to: onError, atomically: true, encoding: .utf8)

            } else {
                print("‼️ No startup method defined in base.\n Expected path \(onStartup.path)")
                return false
            }
        }
        return true
    }

    static func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    static func run(url: URL, version: Version, path p: String?, args: [String]) throws -> BisectResult {
        let root = p ?? ""
        let path = "\(root)/\(version.description)/release/INTL/mac_INTL_64/4D_INTL_x86_64.zip"

        let product = URL(string: root)?.lastPathComponent ?? "Main"
        
        let myBase=url.path
        if !checkDatabaseMethod(url) {
            print("Process will stop")
            return .stop
        }

        if !fileExists(path) {
            return .skip
        }

        let unzipPath: String

        if #available(macOS 13.0, *) {
            unzipPath=FileManager.default.temporaryDirectory.appending(path: "4dbisect\(UUID().uuidString)/").path
        } else {
            unzipPath=FileManager.default.temporaryDirectory.appendingPathComponent("4dbisect\(UUID().uuidString)", isDirectory: true).path
        }

        let cachePath = "/Applications/4D/Cache/\(product)/"
        if !fileExists(cachePath) {
            try FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
        }

        let appPath = "\(cachePath)/4D-\(version.description).app"
        var binPath = "\(appPath)/Contents/MacOS/4D"

        var cpProcess: Process?
        if !fileExists(appPath) && fileExists(path) {
            _ = shell("/usr/bin/unzip", ["-q", path, "-d", unzipPath])

            if (!fileExists("\(unzipPath)/4D/4D.app/Contents/MacOS/4D")) { // zip failed or do not contains 4D (CLEAN: maybe check status)
                try FileManager.default.removeItem(atPath: unzipPath)
                print("‼️ No 4D command in zip \(path)")
                return .skip
            }

            binPath = "\(unzipPath)/4D/4D.app/Contents/MacOS/4D" // to speed up we work on zip
            cpProcess = task("/bin/cp", ["-R", "\(unzipPath)/4D/4D.app", appPath]) // and do not wait copy before launch test
        }

        defer {
            if let task = cpProcess {
                task.waitUntilExit()
            }
            if fileExists(unzipPath) {
                try? FileManager.default.removeItem(atPath: unzipPath)
            }
        }

        if (!fileExists(binPath)) {
            print("‼️ No 4D command in zip \(path)")
            return .skip
        }

        let status = shell(binPath, ["--headless", "--dataless", "-s", myBase])  // run onStart of this project, must auto QUIT

        // failed if a file has been created in resources (for install an error handler and create the file if an assert occurs)
        // if 4D return error code, it will be better, just return its code with $?
        if (fileExists("\(myBase)/Resources/error") ) {
            try FileManager.default.removeItem(atPath: "\(myBase)/Resources/error")
            return .bad
        } else if (status != 0) { // crash?
            print("💣 \(version.description) status \(status)")
            return .bad
        } else {
            return .good
        }
    }
}
