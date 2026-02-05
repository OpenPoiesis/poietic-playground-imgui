//
//  Command.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

struct CommandError: Error {
    let message: String
    // let canRetry: Bool
    // let severity: Severity
}

protocol Command {
    var name: String { get }
    func run(app: Application) throws (CommandError)
}
