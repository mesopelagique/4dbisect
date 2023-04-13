//
//  Test.swift
//  
//
//  Created by emarchand on 13/04/2023.
//

import Foundation

enum Test {
    case executeScript(script: String)
    case openBase(url: URL)

    func run(version: Version, path: String?) -> BisectResult {
        switch self {
        case .executeScript(let script):
            let code = shell(script, "\(version)", path ?? "")
            return BisectResult(code: code)
        case .openBase(_):
            print("‼️ Opening base without script is not implemented yet")
            return .stop // not implemented yet
        }
    }
}
