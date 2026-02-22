//
//  Command.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

struct CommandError: Error {
    enum Severity {
        case error
        case fatal // User should contact developers
    }
    let message: String
    let severity: Severity
    let underlyingError: (any Error)?
    // let canRetry: Bool
    
    init(_ message: String, severity: Severity = .error, underlyingError: (any Error)? = nil) {
        self.message = message
        self.severity = severity
        self.underlyingError = underlyingError
    }
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
/// - Note: Commands operating on "current frame" should use the world frame, as that is the frame
///         that user sees.
/// - Remark: In the future, the scriptability of the application can be build around `Command`.
///
@MainActor
protocol Command {
    var name: String { get }
    func run(_ context: CommandContext) throws (CommandError)
}
