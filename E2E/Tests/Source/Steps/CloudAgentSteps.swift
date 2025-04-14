import Foundation
import TestFramework

class CloudAgentSteps: Steps {
    @Step("{actor} offers '{int}' anonymous credentials")
    var cloudAgentOffersAnAnonymousCredential = { (cloudAgent: Actor, numberOfCredentials: Int) in
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentials {
            try await CloudAgentWorkflow.offersAnonymousCredential(cloudAgent: cloudAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            recordIdList.append(recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    @Step("{actor} offers '{int}' sd+jwt credentials")
    var cloudAgentOffersSdJwtCredentials = { (cloudAgent: Actor, numberOfCredentials: Int) in
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentials {
            try await CloudAgentWorkflow.offersSdJwtCredentials(cloudAgent: cloudAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            recordIdList.append(recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    @Step("{actor} asks for jwt present-proof")
    var cloudAgentAsksForJwtPresentProof = { (cloudAgent: Actor) in
        try await CloudAgentWorkflow.asksForJwtPresentProof(cloudAgent: cloudAgent)
    }
    
    @Step("{actor} asks for sdjwt present-proof")
    var cloudAgentAsksForSdJwtPresentProof = { (cloudAgent: Actor) in
        try await CloudAgentWorkflow.askForSdJwtPresentProof(cloudAgent: cloudAgent)
    }
    
    @Step("{actor} asks for anonymous present-proof")
    var cloudAgentAsksForAnonymousPresentProof = { (cloudAgent: Actor) in
        try await CloudAgentWorkflow.asksForAnonymousPresentProof(cloudAgent: cloudAgent)
    }
    
    @Step("{actor} asks for anonymous present-proof with unexpected attributes")
    var cloudAgentAsksForAnonymousPResentProofWithUnexpectedAttributes = { (cloudAgent: Actor) in
        try await CloudAgentWorkflow.asksForAnonymousPresentProofWithUnexpectedAttributes(cloudAgent: cloudAgent)
    }
    
    @Step("{actor} should see the present-proof is verified")
    var cloudAgentShouldSeeThePresentProofIsVerified = { (cloudAgent: Actor) in
        try await CloudAgentWorkflow.verifyPresentProof(cloudAgent: cloudAgent, expectedState: .PresentationVerified)
    }
    
    @Step("{actor} offers '{int}' jwt credentials")
    var cloudAgentOffersACredential = { (cloudAgent: Actor, numberOfCredentials: Int) in
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentials {
            try await CloudAgentWorkflow.offersACredential(cloudAgent: cloudAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            recordIdList.append(recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    @Step("{actor} should see all credentials were accepted")
    var cloudAgentSeeAllCredentialsWereAccepted = { (cloudAgent: Actor) in
        let recordIdList: [String] = try await cloudAgent.recall(key: "recordIdList")
        for recordId in recordIdList {
            try await CloudAgentWorkflow.verifyCredentialState(cloudAgent: cloudAgent, recordId: recordId, expectedState: .CredentialSent)
        }
    }
    
    @Step("{actor} is connected to {actor}")
    var cloudAgentIsConnectedToEdgeAgent = { (cloudAgent: Actor, edgeAgent: Actor) in
        try await CloudAgentWorkflow.isConnectedToEdgeAgent(cloudAgent: cloudAgent, edgeAgent: edgeAgent)
    }
    
    @Step("{actor} has a connection invitation with '{}', '{}' and '{}' parameters")
    var cloudAgentHasAConnectionInvitation = { (cloudAgent: Actor, label: String, goalCode: String, goal: String) in
        let label = label == "null" ? nil : label
        let goalCode = goalCode == "null" ? nil : goalCode
        let goal = goal == "null" ? nil : goal
        try await CloudAgentWorkflow.hasAConnectionInvitation(
            cloudAgent: cloudAgent,
            label: label,
            goalCode: goalCode,
            goal: goal
        )
    }
    
    @Step("{actor} shares invitation to {actor}")
    var cloudAgentSharesInvitationToEdgeAgent = { (cloudAgent: Actor, edgeAgent: Actor) in
        try await CloudAgentWorkflow.sharesInvitationToEdgeAgent(cloudAgent: cloudAgent, edgeAgent: edgeAgent)
    }
    
    @Step("{actor} should have the connection status updated to '{}'")
    var cloudAgentShouldHaveTheConnectionStatusUpdatedToConnectionResponseSent = { (cloudAgent: Actor, state: String) in
        try await CloudAgentWorkflow.shouldHaveTheConnectionStatusUpdated(cloudAgent: cloudAgent, expectedState: .ConnectionResponseSent)
    }
    
    @Step("{actor} revokes '{int}' credentials")
    var cloudAgentRevokesCredentials = { (cloudAgent: Actor, numberOfRevokedCredentials: Int) in
        try await CloudAgentWorkflow.revokeCredential(cloudAgent: cloudAgent, numberOfRevokedCredentials: numberOfRevokedCredentials)
    }
}
