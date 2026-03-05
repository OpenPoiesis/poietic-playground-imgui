//
//  Document+Transaction.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import PoieticCore

extension Session {
    /// Creates a new transaction or reuses the existing one.
    ///
    /// The transaction is automatically accepted at the end of the update cycle.
    ///
    /// Transaction is non-cancellable. Canvas Tools must create a transaction only when their operation
    /// is concluded successfully.
    ///
    /// - ToDo:  Known issue: If there are multiple commands using the transaction, any of them can
    ///   discard and others in the queue will get a new one. At this stage of development it is
    ///   unlikely to happen, but it is important to acknowledge it.
    ///
    func createOrReuseTransaction() -> TransientFrame {
        if let transaction {
            return transaction
        }
        else {
            let transaction = design.createFrame(deriving: world.frame)
            self.transaction = transaction
            return transaction
        }
    }
    
    /// Commands call this when they fail to successfully complete the transaction.
    ///
    /// See note about discarding in ``createOrReuseTransaction()``
    ///
    func discardTransaction() {
        guard let transaction else { return }
        design.discard(transaction)
        self.transaction = nil
    }
    
    /// Accept transaction
    func consumeAndAcceptTransaction() throws (FrameValidationError) {
        guard let transaction else { return }
        defer {
            if design.isPending(transaction) {
                design.discard(transaction)
            }
            self.transaction = nil
        }
        
        guard transaction.hasChanges else { return }
        try design.accept(transaction, appendHistory: true)
        self.log("Transaction accepted. Current frame: \(transaction.id), frame count: \(design.frames.count)")

        self.updateWorld()
    }
}
