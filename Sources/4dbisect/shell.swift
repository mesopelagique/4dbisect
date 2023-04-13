//
//  shell.swift
//  
//
//  Created by emarchand on 06/02/2021.
//

import Foundation

func shell(_ launchPath: String, _ args: [String]) -> Int32 {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
