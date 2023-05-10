//
//  Test.swift
//  
//
//  Created by emarchand on 13/04/2023.
//

import Foundation

enum Test {
    case executeScript(script: String, args: [String])
    case openBase(url: URL, args: [String])

    func run(version: Version, path: String?) -> BisectResult {
        switch self {
        case .executeScript(let script, let args):
            let code = shell(script, ["\(version)", path ?? ""] + args)
            return BisectResult(code: code)
        case .openBase(let url, let args):
            do {
                return try OpenBase.run(url: url, version: version, path: path, args: args)
            } catch {
                print("💥 \(error)")
                return .stop
            }
        }
    }
}
