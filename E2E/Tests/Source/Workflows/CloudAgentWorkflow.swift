import Foundation
import SwiftHamcrest
import TestFramework

class CloudAgentWorkflow {
    static func isConnectedToEdgeAgent(cloudAgent: Actor, edgeAgent: Actor) async throws{
        try await hasAConnectionInvitation(cloudAgent: cloudAgent)
        try await sharesInvitationToEdgeAgent(cloudAgent: cloudAgent, edgeAgent: edgeAgent)
        try await EdgeAgentWorkflow.connectsThroughTheInvite(edgeAgent: edgeAgent)
        try await shouldHaveTheConnectionStatusUpdated(cloudAgent: cloudAgent, expectedState: .ConnectionResponseSent)
    }
    
    static func hasAConnectionInvitation(cloudAgent: Actor) async throws {
        let connection = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "create a connection"
        ).createConnection()
        try await cloudAgent.remember(key: "invitation", value: connection.invitation.invitationUrl)
        try await cloudAgent.remember(key: "connectionId", value: connection.connectionId)
    }
    
    static func sharesInvitationToEdgeAgent(cloudAgent: Actor, edgeAgent: Actor) async throws {
        let invitation: String = try await cloudAgent.recall(key: "invitation")
        try await edgeAgent.remember(key: "invitation", value: invitation)
    }
    
    static func shouldHaveTheConnectionStatusUpdated(cloudAgent: Actor, expectedState: Components.Schemas.Connection.statePayload) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        try await cloudAgent.waitUsingAbility(
            ability: CloudAgentAPI.self,
            action: "connection state to be \(expectedState.rawValue)"
        ) { ability in
            return try await ability.getConnection(connectionId).state == expectedState
        }
    }
    
    static func offersACredential(cloudAgent: Actor) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        let credentialOfferRecord = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "offers a credential to \(connectionId)"
        ).offerCredential(connectionId)
        try await cloudAgent.remember(key: "recordId", value: credentialOfferRecord.recordId)
    }
    
    static func offersAnonymousCredential(cloudAgent: Actor) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        let credentialOfferRecord = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "offers an anonymous credential to \(connectionId)"
        ).offerAnonymousCredential(connectionId)
        try await cloudAgent.remember(key: "recordId", value: credentialOfferRecord.recordId)
    }

    static func offersSdJwtCredentials(cloudAgent: Actor) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        let credentialOfferRecord = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "offers a sd+jwt credential to \(connectionId)"
        ).offerSdJwtCredential(connectionId)
        try await cloudAgent.remember(key: "recordId", value: credentialOfferRecord.recordId)
    }
    
    static func asksForPresentProof(cloudAgent: Actor) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        let presentation = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "ask a presentation proof to \(connectionId)"
        ).requestPresentProof(connectionId)
        try await cloudAgent.remember(key: "presentationId", value: presentation.presentationId)
    }
    
    static func asksForAnonymousPresentProof(cloudAgent: Actor) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        let presentation = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "ask an anonymous presentation proof to \(connectionId)"
        ).requestAnonymousPresentProof(connectionId)
        try await cloudAgent.remember(key: "presentationId", value: presentation.presentationId)
    }
    

    static func asksForAnonymousPresentProofWithUnexpectedAttributes(cloudAgent: Actor) async throws {
        let connectionId: String = try await cloudAgent.recall(key: "connectionId")
        let presentation = try await cloudAgent.using(
            ability: CloudAgentAPI.self,
            action: "ask an anonymous presentation proof with unexpected attributes to \(connectionId)"
        ).requestAnonymousPresentProofWithUnexpectedAttributes(connectionId)
        try await cloudAgent.remember(key: "presentationId", value: presentation.presentationId)
    }
    
    static func verifyCredentialState(cloudAgent: Actor, recordId: String, expectedState: Components.Schemas.IssueCredentialRecord.protocolStatePayload) async throws {
        try await cloudAgent.waitUsingAbility(
            ability: CloudAgentAPI.self,
            action: "credential state is \(expectedState.rawValue)"
        ) { ability in
            let credentialRecord = try await ability.getCredentialRecord(recordId)
            return credentialRecord.protocolState == expectedState
        }
    }
    
    static func verifyPresentProof(cloudAgent: Actor, expectedState: Components.Schemas.PresentationStatus.statusPayload) async throws {
        let presentationId: String = try await cloudAgent.recall(key: "presentationId")
        try await cloudAgent.waitUsingAbility(
            ability: CloudAgentAPI.self,
            action: "present proof state is \(expectedState.rawValue)"
        ) { ability in
            let presentationStatus = try await ability.getPresentation(presentationId)
            return presentationStatus.status == expectedState
        }
    }
    
    static func revokeCredential(cloudAgent: Actor, numberOfRevokedCredentials: Int) async throws {
        var revokedRecordIdList: [String] = []
        var recordIdList: [String] = try await cloudAgent.recall(key: "recordIdList")
        
        for _ in 0..<numberOfRevokedCredentials {
            let recordId = recordIdList.removeFirst()
            let httpStatus = try await cloudAgent
                .using(ability: CloudAgentAPI.self, action: "revokes \(recordId)")
                .revokeCredential(recordId)
            assertThat(httpStatus, equalTo(200))
            revokedRecordIdList.append(recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
        try await cloudAgent.remember(key: "revokedRecordIdList", value: revokedRecordIdList)
    }
}
