//
//  Document+Commands.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 25/03/2026.
//

import PoieticFlows
import PoieticCore

public enum AutoCorrectParametersSchedule: ScheduleLabel {}

extension Document {
    func autoConnectParameters() {
        let system = ParameterConnectionProposalSystem(world)
        
        // We can just run it, as this method is called when the world is populated. If it is not,
        // we are fine too - just do nothing. This is an optional utility, not to be put in a
        // critical path.
        // It is a non-throwing system, we run it gracefully
        try? system.update(self.world)

        guard let proposal: ParameterProposal = world.singleton(),
              !proposal.isEmpty
        else {
            self.queueAlert(title: "Auto-Connect Parameters",
                            message: "Nothing automatically proposed for parameter connections")
            return
        }
        
        let trans = self.createOrReuseTransaction()

        for id in proposal.toRemove {
            trans.removeCascading(id)
        }
        for edgeProposal in proposal.toAdd {
            trans.createEdge(.Parameter, origin: edgeProposal.origin, target: edgeProposal.target)
        }

        self.queueAlert(title: "Auto-Connect Parameters",
                        message: "Removed \(proposal.toRemove.count), created \(proposal.toAdd.count) connections.")

    }

}
