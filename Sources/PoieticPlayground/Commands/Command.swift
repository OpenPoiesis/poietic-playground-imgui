//
//  Command.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

struct CommandError: Error {
    let message: String
    // let canRetry: Bool
    // let severity: Severity
}

struct CommandContext {
    let app: Application
    let session: Session
    
    var design: Design { session.design }
    var world: World { session.world }
}

/// Protocol for application commands.
///
/// Commands are representations of user actions.
///
/// For typical command execution the commands queued in the application
/// session ``Application/session`` through ``Session/queueCommand(_:)``.  They are run
/// at the end of the application main loop after all updates using the ``Application/runCommand(_:)`.
///
/// Commands can use and append a transaction ``Session/transaction``. The transaction,
/// if contains changes, is committed in the application frame update after the command queue is
/// run.
///
/// - Remark: In the future, the scriptability of the application can be build around `Command`.
///
protocol Command {
    var name: String { get }
    func run(_ context: CommandContext) throws (CommandError)
}
