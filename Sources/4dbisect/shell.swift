//
//  shell.swift
//  
//
//  Created by emarchand on 06/02/2021.
//

import Foundation

func task(_ launchPath: String, _ args: [String]) -> Process {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = args
    task.launch()
    return task
}
func shell(_ launchPath: String, _ args: [String]) -> Int32 {
    let task = task(launchPath, args)
    task.waitUntilExit()
    return task.terminationStatus
}

