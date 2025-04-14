import Foundation
import Domain
import TestFramework

class EdgeAgentSteps: Steps {
    @Step("{actor} sends the present-proof")
    var edgeAgentSendsThePresentProof = { (edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.waitForProofRequest(edgeAgent: edgeAgent)
        try await EdgeAgentWorkflow.presentProof(edgeAgent: edgeAgent)
    }
    
    @Step("{actor} should receive an exception when trying to use a wrong anoncred credential")
    var edgeAgentShouldReceiveAnExceptionWhenTryingToUseAWrongAnoncredCredential = { (edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.waitForProofRequest(edgeAgent: edgeAgent)
        try await EdgeAgentWorkflow.tryToPresentVerificationRequestWithWrongAnoncred(edgeAgent: edgeAgent)
    }
    
    @Step("{actor} should not be able to create the present-proof")
    var edgeAgentShouldNotBeAbleToCreatePresentationProof = { (edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.waitForProofRequest(edgeAgent: edgeAgent)
        try await EdgeAgentWorkflow.shouldNotBeAbleToCreatePresentProof(edgeAgent: edgeAgent)
    }
    
    @Step("{actor} has '{int}' jwt credentials issued by {actor}")
    var edgeAgentHasJwtCredentialsIssuedByCloudAgent = { (edgeAgent: Actor, numberOfCredentials: Int, cloudAgent: Actor) async throws in
        try await EdgeAgentWorkflow.hasIssuedJwtCredentials(edgeAgent: edgeAgent, numberOfCredentialsIssued: numberOfCredentials, cloudAgent: cloudAgent)
    }

    @Step("{actor} has '{int}' sdjwt credentials issued by {actor}")
    var edgeAgentHasSdJwtCredentialsIssuedByCloudAgent = { (edgeAgent: Actor, numberOfCredentials: Int, cloudAgent: Actor) async throws in
        try await EdgeAgentWorkflow.hasIssuedSdJwtCredentials(edgeAgent: edgeAgent, numberOfCredentialsIssued: numberOfCredentials, cloudAgent: cloudAgent)
    }
    
    @Step("{actor} has '{int}' anonymous credentials issued by {actor}")
    var edgeAgentHasAnonymousCredentialsIssuedByCloudAgent = { (edgeAgent: Actor, numberOfCredentials: Int, cloudAgent: Actor) async throws in
        try await EdgeAgentWorkflow.hasIssuedAnonymousCredentials(edgeAgent: edgeAgent, numberOfCredentialsIssued: numberOfCredentials, cloudAgent: cloudAgent)
    }
    
    @Step("{actor} accepts {int} jwt credential offer sequentially from {actor}")
    var edgeAgentAcceptsCredentialsOfferSequentiallyFromCloudAgent = { (edgeAgent: Actor, numberOfCredentials: Int, cloudAgent: Actor) async throws in
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentials {
            try await CloudAgentWorkflow.offersACredential(cloudAgent: cloudAgent)
            try await EdgeAgentWorkflow.waitToReceiveCredentialsOffer(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.acceptsTheCredentialOffer(edgeAgent: edgeAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            try await CloudAgentWorkflow.verifyCredentialState(cloudAgent: cloudAgent, recordId: recordId, expectedState: .CredentialSent)
            recordIdList.append(recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    @Step("{actor} accepts {int} jwt credentials offer at once from {actor}")
    var edgeAgentAcceptsCredentialsOfferAtOnceFromCloudAgent = { (edgeAgent: Actor, numberOfCredentials: Int, cloudAgent: Actor) async throws in
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentials {
            try await CloudAgentWorkflow.offersACredential(cloudAgent: cloudAgent)
            recordIdList.append(try await cloudAgent.recall(key: "recordId"))
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
        
        try await EdgeAgentWorkflow.waitToReceiveCredentialsOffer(edgeAgent: edgeAgent, numberOfCredentials: 3)
        
        for _ in 0..<numberOfCredentials {
            try await EdgeAgentWorkflow.acceptsTheCredentialOffer(edgeAgent: edgeAgent)
        }
    }
    
    @Step("{actor} should receive the credentials offer from {actor}")
    var edgeAgentShouldReceiveTheCredential = { (edgeAgent: Actor, cloudAgent: Actor) async throws in
        let recordIdList: [String] = try await cloudAgent.recall(key: "recordIdList")
        try await EdgeAgentWorkflow.waitToReceiveCredentialsOffer(edgeAgent: edgeAgent, numberOfCredentials: recordIdList.count)
    }
    
    @Step("{actor} accepts the credentials offer from {actor}")
    var edgeAgentAcceptsTheCredential = { (edgeAgent: Actor, cloudAgent: Actor) async throws in
        let recordIdList: [String] = try await cloudAgent.recall(key: "recordIdList")
        for recordId in recordIdList {
            try  await EdgeAgentWorkflow.acceptsTheCredentialOffer(edgeAgent: edgeAgent)
        }
    }
    
    @Step("{actor} wait to receive {int} issued credentials")
    var edgeAgentWaitToReceiveIssuedCredentials = { (edgeAgent: Actor, numberOfCredentials: Int) async throws in
        try await EdgeAgentWorkflow.waitToReceiveIssuedCredentials(edgeAgent: edgeAgent, numberOfCredentials: numberOfCredentials)
    }
    
    @Step("{actor} process issued credentials from {actor}")
    var edgeAgentProcessIssuedCredentials = { (edgeAgent: Actor, cloudAgent: Actor) async throws in
        let recordIdList: [String] = try await cloudAgent.recall(key: "recordIdList")
        for recordId in recordIdList {
            try await EdgeAgentWorkflow.processIssuedCredential(edgeAgent: edgeAgent, recordId: recordId)
        }
    }
    
    @Step("{actor} connects through the invite")
    var edgeAgentConnectsThroughTheInvite = { (edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.connectsThroughTheInvite(edgeAgent: edgeAgent)
    }
    
    @Step("{actor} has created a backup")
    var edgeAgentHasCreatedABackup = { (edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createBackup(edgeAgent: edgeAgent)
    }
    
    @Step("a new {actor} can be restored from {actor}")
    var aNewSdkCanBeRestoredFromEdgeAgent = { (restoredAgent: Actor, edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createNewWalletFromBackup(restoredAgent: restoredAgent, edgeAgent: edgeAgent)
    }
    
    @Step("a new {actor} cannot be restored from {actor} with wrong seed")
    var aNewSdkCannotBeRestoredFromEdgeAgentWithWrongSeed = { (restoredAgent: Actor, edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createNewWalletFromBackupWithWrongSeed(restoredAgent: restoredAgent, edgeAgent: edgeAgent)
    }
    
    @Step("{actor} creates '{int}' peer DIDs")
    var edgeAgentCreatesPeerDids = { (edgeAgent: Actor, numberOfDids: Int) async throws in
        try await EdgeAgentWorkflow.createPeerDids(edgeAgent: edgeAgent, numberOfDids: numberOfDids)
    }
    
    @Step("{actor} creates '{int}' prism DIDs")
    var edgeAgentCreatesPrismDids = { (edgeAgent: Actor, numberOfDids: Int) async throws in
        try await EdgeAgentWorkflow.createPrismDids(edgeAgent: edgeAgent, numberOfDids: numberOfDids)
    }
    
    @Step("{actor} is created using {actor} seed")
    var newAgentIsCreatedUsingAgentSeed = { (newAgent: Actor, oldAgent: Actor) async throws in
        let seed: Seed = try await oldAgent.recall(key: "seed")
        _ = newAgent.whoCanUse(DidcommAgentAbility(seed: seed))
        let peerDids = try await newAgent.using(
            ability: DidcommAgentAbility.self,
            action: "gets peer dids"
        ).didcommAgent.pluto.getAllPeerDIDs()
        
        let prismDids = try await newAgent.using(
            ability: DidcommAgentAbility.self,
            action: "gets prism dids"
        ).didcommAgent.pluto.getAllPrismDIDs()
        
        let credentials = try await newAgent.using(
            ability: DidcommAgentAbility.self,
            action: "gets credentials"
        ).didcommAgent.pluto.getAllCredentials()
        
        
    }
    
    @Step("a new {actor} is restored from {actor}")
    var aNewAgentIsRestored = { (newAgent: Actor, oldAgent: Actor) async throws in
        try await EdgeAgentWorkflow.backupAndRestoreToNewAgent(newAgent: newAgent, oldAgent: oldAgent)
    }
    
    @Step("{actor} should have the expected values from {actor}")
    var newAgentShouldHaveTheExpectedValuesFromOldAgent = { (newAgent: Actor, oldAgent: Actor) async throws in
        try await EdgeAgentWorkflow.newAgentShouldMatchOldAgent(newAgent: newAgent, oldAgent: oldAgent)
    }
    
    @Step("{actor} waits to receive the revocation notifications from {actor}")
    var edgeAgentWaitsToReceiveTheRevocationNotificationFromCloudAgent = { (edgeAgent: Actor, cloudAgent: Actor) async throws in
        let revokedRecordIdList: [String] = try await cloudAgent.recall(key: "revokedRecordIdList")
        try await EdgeAgentWorkflow.waitForCredentialRevocationMessage(
            edgeAgent: edgeAgent,
            numberOfRevocation: revokedRecordIdList.count
        )
    }
    
    @Step("{actor} should see the credentials were revoked by {actor}")
    var edgeAgentShouldSeeTheCredentialsWereRevokedByCloudAgent = { (edgeAgent: Actor, cloudAgent: Actor) async throws in
        let revokedRecordIdList: [String] = try await cloudAgent.recall(key: "revokedRecordIdList")
        try await EdgeAgentWorkflow.waitUntilCredentialIsRevoked(
            edgeAgent: edgeAgent,
            revokedRecordIdList: revokedRecordIdList
        )
    }
    
    @Step("{actor} requests {actor} to verify the JWT credential")
    var verifierAgentRequestsEdgeAgentToVerifyTheJwtCredential = { (verifierAgent: Actor, holderAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createPeerDids(edgeAgent: holderAgent, numberOfDids: 1)
        let did: DID = try await holderAgent.recall(key: "lastPeerDid")
        let claims: [ClaimFilter] = [
            .init(paths: ["$.vc.credentialSubject.automation-required"], type: "string", pattern: "required value")
        ]

        try await EdgeAgentWorkflow.initiatePresentationRequest(
            edgeAgent: verifierAgent,
            credentialType: CredentialType.jwt,
            toDid: did,
            claims: claims
        )
    }
    
    @Step("{actor} requests the {actor} to verify the sdjwt credential")
    var verifierAgentRequestsHolderAgentToVerifySdJwtCredential = { (verifierAgent: Actor, holderAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createPeerDids(edgeAgent: holderAgent, numberOfDids: 1)
        let holderDid: DID = try await holderAgent.recall(key: "lastPeerDid")
        
        let claims: [ClaimFilter] = [
            .init(paths: [
                "$.vc.credentialSubject.automation-required",
                "$.vc.automation-required",
                "$.automation-required"
            ], type: "string", pattern: "required value")
        ]
        
        try await EdgeAgentWorkflow.initiatePresentationRequest(
            edgeAgent: verifierAgent,
            credentialType: CredentialType.jwt,
            toDid: holderDid,
            claims: claims
        )
        
//         await EdgeAgentWorkflow.initiatePresentationRequest(verifierEdgeAgent, SDK.Domain.CredentialType.jwt, holderDID, claims)
    }
    
    @Step("{actor} will request {actor} to verify the anonymous credential")
    var verifierAgentRequestsEdgeAgentToVerifyTheAnoncred = { (verifierAgent: Actor, holderAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createPeerDids(edgeAgent: holderAgent, numberOfDids: 1)
        let did: DID = try await holderAgent.recall(key: "lastPeerDid")
        
        let claims: [ClaimFilter] = [
            .init(paths: [], type: "name", const: "pu"),
            .init(paths: [], type: "age", const: "99", pattern: ">=")
        ]
        
        try await EdgeAgentWorkflow.initiatePresentationRequest(
            edgeAgent: verifierAgent,
            credentialType: CredentialType.anoncred,
            toDid: did,
            claims: claims
        )
    }
    
    @Step("{actor} will request {actor} to verify the anonymous credential for age greater than actual")
    var verifierAgentRequestsEdgeAgentToVerifyTheAnoncredForAgeGreaterThanActual = { (verifierEdgeAgent: Actor, edgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.createPeerDids(edgeAgent: edgeAgent, numberOfDids: 1)
        let did: DID = try await edgeAgent.recall(key: "lastPeerDid")
        
        let claims: [ClaimFilter] = [
            .init(paths: [], type: "age", const: "100", pattern: ">=")
        ]
        
        try await EdgeAgentWorkflow.initiatePresentationRequest(
            edgeAgent: verifierEdgeAgent,
            credentialType: CredentialType.anoncred,
            toDid: did,
            claims: claims
        )
    }

    @Step("{actor} should see the verification proof is verified")
    var verifierEdgeAgentShouldSeeTheVerificationProofIsVerified = { (verifierEdgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.waitForPresentationMessage(edgeAgent: verifierEdgeAgent)
        try await EdgeAgentWorkflow.verifyPresentation(edgeAgent: verifierEdgeAgent, isRevoked: false)
    }
    
    @Step("{actor} should see the verification proof is not verified")
    var verifierShouldSeeTheVerificationProofIsFalse = { (verifierEdgeAgent: Actor) async throws in
        try await EdgeAgentWorkflow.waitForPresentationMessage(edgeAgent: verifierEdgeAgent)
        try await EdgeAgentWorkflow.verifyPresentation(edgeAgent: verifierEdgeAgent, isRevoked: true)
    }
}
