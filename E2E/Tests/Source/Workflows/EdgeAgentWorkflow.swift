import Foundation
import Domain
import EdgeAgent
import XCTest
import PeerDID
import Combine
import SwiftHamcrest
import TestFramework

class EdgeAgentWorkflow {
    static func connectsThroughTheInvite(edgeAgent: Actor) async throws {
        let invitation: String = try await edgeAgent.recall(key: "invitation")
        let url = URL(string: invitation)!
        
        let oob = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "parses an OOB invitation"
        ).didcommAgent.parseOOBInvitation(url: url)
        
        try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "accepts an invitation"
        ).didcommAgent.acceptDIDCommInvitation(invitation: oob)
    }
    
    static func waitToReceiveCredentialsOffer(edgeAgent: Actor, numberOfCredentials: Int) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "credential offer count to be \(numberOfCredentials)"
        ) { ability in
            return ability.credentialOfferStack.count == numberOfCredentials
        }
    }
    
    static func hasIssuedJwtCredentials(edgeAgent: Actor, numberOfCredentialsIssued: Int, cloudAgent: Actor) async throws {
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentialsIssued {
            try await CloudAgentWorkflow.offersACredential(cloudAgent: cloudAgent)
            try await EdgeAgentWorkflow.waitToReceiveCredentialsOffer(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.acceptsTheCredentialOffer(edgeAgent: edgeAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            recordIdList.append(recordId)
            try await CloudAgentWorkflow.verifyCredentialState(cloudAgent: cloudAgent, recordId: recordId, expectedState: .CredentialSent)
            try await EdgeAgentWorkflow.waitToReceiveIssuedCredentials(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.processIssuedCredential(edgeAgent: edgeAgent, recordId: recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    static func hasIssuedSdJwtCredentials(edgeAgent: Actor, numberOfCredentialsIssued: Int, cloudAgent: Actor) async throws {
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentialsIssued {
            try await CloudAgentWorkflow.offersSdJwtCredentials(cloudAgent: cloudAgent)
            try await EdgeAgentWorkflow.waitToReceiveCredentialsOffer(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.acceptsTheCredentialOffer(edgeAgent: edgeAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            recordIdList.append(recordId)
            try await CloudAgentWorkflow.verifyCredentialState(cloudAgent: cloudAgent, recordId: recordId, expectedState: .CredentialSent)
            try await EdgeAgentWorkflow.waitToReceiveIssuedCredentials(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.processIssuedCredential(edgeAgent: edgeAgent, recordId: recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    static func hasIssuedAnonymousCredentials(edgeAgent: Actor, numberOfCredentialsIssued: Int, cloudAgent: Actor) async throws {
        var recordIdList: [String] = []
        for _ in 0..<numberOfCredentialsIssued {
            try await CloudAgentWorkflow.offersAnonymousCredential(cloudAgent: cloudAgent)
            try await EdgeAgentWorkflow.waitToReceiveCredentialsOffer(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.acceptsTheCredentialOffer(edgeAgent: edgeAgent)
            let recordId: String = try await cloudAgent.recall(key: "recordId")
            recordIdList.append(recordId)
            try await CloudAgentWorkflow.verifyCredentialState(cloudAgent: cloudAgent, recordId: recordId, expectedState: .CredentialSent)
            try await EdgeAgentWorkflow.waitToReceiveIssuedCredentials(edgeAgent: edgeAgent, numberOfCredentials: 1)
            try await EdgeAgentWorkflow.processIssuedCredential(edgeAgent: edgeAgent, recordId: recordId)
        }
        try await cloudAgent.remember(key: "recordIdList", value: recordIdList)
    }
    
    static func acceptsTheCredentialOffer(edgeAgent: Actor) async throws {
        let message: Message = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "gets the first credential offer"
        ).credentialOfferStack.first!
        
        try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "removes it from list"
        ).credentialOfferStack.removeFirst()
        
        let format = message.attachments[0].format
        let did: DID
        
        switch(format) {
        case "anoncreds/credential-offer@v1.0":
            did = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "create a new prism DID"
            ).didcommAgent.createNewPrismDID()
            break
        case "vc+sd-jwt":
            let privateKey = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "create a private key"
            ).didcommAgent.apollo.createPrivateKey(parameters: [
                KeyProperties.type.rawValue: "EC",
                KeyProperties.curve.rawValue: KnownKeyCurves.ed25519.rawValue
            ])
            
            did = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "create a new prism DID"
            ).didcommAgent.createNewPrismDID(
                keys: [(KeyPurpose.authentication, privateKey)]
            )
            break
        case "prism/jwt":
            let seed = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "get seed"
            ).didcommAgent.edgeAgent.seed
            
            let privateKey = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "create a private key"
            ).didcommAgent.apollo.createPrivateKey(parameters: [
                KeyProperties.type.rawValue: "EC",
                KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
                KeyProperties.seed.rawValue: seed.value.base64EncodedString(),
                KeyProperties.derivationPath.rawValue: DerivationPath().keyPathString()
            ])
            
            did = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "create a new prism DID"
            ).didcommAgent.createNewPrismDID(
                keys: [(KeyPurpose.authentication, privateKey)]
            )
            break
        default:
            throw ValidationError.error(message: "Format \(format!) not supported")
        }
        
        let acceptOfferMessage = try OfferCredential3_0(fromMessage: message)
        
        let requestCredential = try await edgeAgent
            .using(
                ability: DidcommAgentAbility.self,
                action: "request a credential"
            )
            .didcommAgent
            .prepareRequestCredentialWithIssuer(
                did: did,
                offer: acceptOfferMessage
            )!.makeMessage()
        
        _ = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "send a message"
        ).didcommAgent.sendMessage(message: requestCredential)
    }
    
    static func waitToReceiveIssuedCredentials(edgeAgent: Actor, numberOfCredentials: Int) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "wait for issued credentials to be \(numberOfCredentials)"
        ) { ability in
            return ability.issueCredentialStack.count == numberOfCredentials
        }
    }
    
    static func processIssuedCredential(edgeAgent: Actor, recordId: String) async throws {
        let message = try await edgeAgent
            .using(ability: DidcommAgentAbility.self, action: "get the issued credential message")
            .issueCredentialStack.removeFirst()
        let issuedCredential = try IssueCredential3_0(fromMessage: message)
        _ = try await edgeAgent
            .using(ability: DidcommAgentAbility.self, action: "process the credential")
            .didcommAgent.processIssuedCredentialMessage(message: issuedCredential)
        try await edgeAgent.remember(key: recordId, value: message.id)
    }
    
    static func waitForProofRequest(edgeAgent: Actor) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "wait for present proof request"
        ) { ability in
            return ability.proofOfRequestStack.count == 1
        }
    }
    
    static func presentProof(edgeAgent: Actor) async throws {
        let credentials = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "get a verifiable credential"
        ).didcommAgent.edgeAgent.verifiableCredentials()
        
        let credential = try await credentials.map { $0.first }.first().await()
        
        let message = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "get proof request"
        ).proofOfRequestStack.first!
        try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "remove it from list"
        ).proofOfRequestStack.removeFirst()
        let requestPresentationMessage = try RequestPresentation(fromMessage: message)
        let sendProofMessage = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "make message"
        ).didcommAgent.createPresentationForRequestProof(
            request: requestPresentationMessage,
            credential: credential!,
            options: [.disclosingClaims(claims: ["automation-required"])]
        ).makeMessage()
        _ = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "send message"
        ).didcommAgent.sendMessage(message: sendProofMessage)
    }
    
    static func tryToPresentVerificationRequestWithWrongAnoncred(edgeAgent: Actor) async throws {
        let credential = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "get a verifiable credential"
        ).didcommAgent.edgeAgent.verifiableCredentials().map { $0.first }.first().await()
        
        let message = try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "get proof request"
        ).proofOfRequestStack.first!
        try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "remove it from list"
        ).proofOfRequestStack.removeFirst()
        let requestPresentationMessage = try RequestPresentation(fromMessage: message)
        await assertThrows(try await edgeAgent.using(
            ability: DidcommAgentAbility.self,
            action: "make message"
        ).didcommAgent.createPresentationForRequestProof(request: requestPresentationMessage, credential: credential!).makeMessage())
    }
    
    static func shouldNotBeAbleToCreatePresentProof(edgeAgent: Actor) async throws {
        await assertThrows(try await presentProof(edgeAgent: edgeAgent))
    }
    
    static func createBackup(edgeAgent: Actor) async throws {
        let backup = try await edgeAgent
            .using(ability: DidcommAgentAbility.self, action: "creates a backup")
            .didcommAgent
            .edgeAgent
            .backupWallet()
        let seed = try await edgeAgent
            .using(ability: DidcommAgentAbility.self, action: "gets seed phrase")
            .didcommAgent
            .edgeAgent
            .seed
        try await edgeAgent.remember(key: "backup", value: backup)
        try await edgeAgent.remember(key: "seed", value: seed)
    }
    
    static func createNewWalletFromBackup(restoredAgent: Actor, edgeAgent: Actor) async throws {
        let backup: String = try await edgeAgent.recall(key: "backup")
        let seed: Seed = try await edgeAgent.recall(key: "seed")
        try await restoredAgent
            .whoCanUse(DidcommAgentAbility(seed: seed))
            .using(ability: DidcommAgentAbility.self, action: "recover wallet")
            .didcommAgent.edgeAgent.recoverWallet(encrypted: backup)
    }
    
    static func createNewWalletFromBackupWithWrongSeed(restoredAgent: Actor, edgeAgent: Actor) async throws {
        let backup: String = try await edgeAgent.recall(key: "backup")
        let seed = DidcommAgentAbility.wrongSeed
        
        do {
            try await restoredAgent
                .whoCanUse(DidcommAgentAbility(seed: seed))
                .using(ability: DidcommAgentAbility.self, action: "recover wallet")
                .didcommAgent.edgeAgent.recoverWallet(encrypted: backup)
            XCTFail("SDK should not be able to restore with wrong seed phrase.")
        } catch {
        }
    }
    
    static func createPeerDids(edgeAgent: Actor, numberOfDids: Int) async throws {
        for _ in 0..<numberOfDids {
            let did: DID = try await edgeAgent.using(ability: DidcommAgentAbility.self, action: "creates peer did")
                .didcommAgent.createNewPeerDID(updateMediator: true)
            try await edgeAgent.remember(key: "lastPeerDid", value: did)
        }
    }
    
    static func createPrismDids(edgeAgent: Actor, numberOfDids: Int) async throws {
        for _ in 0..<numberOfDids {
            _ = try await edgeAgent.using(ability: DidcommAgentAbility.self, action: "creates peer did").didcommAgent.createNewPrismDID()
        }
    }
    
    static func backupAndRestoreToNewAgent(newAgent: Actor, oldAgent: Actor) async throws {
        let backup: String = try await oldAgent.recall(key: "backup")
        try await newAgent
            .using(ability: DidcommAgentAbility.self, action: "recovers wallet")
            .didcommAgent.edgeAgent.recoverWallet(encrypted: backup)
    }
    
    static func newAgentShouldMatchOldAgent(newAgent: Actor, oldAgent: Actor) async throws {
        let expectedCredentials: [Credential] = try await oldAgent
            .using(ability: DidcommAgentAbility.self, action: "gets credentials")
            .didcommAgent
            .edgeAgent
            .verifiableCredentials().first().await()
        
        let expectedPeerDids: [PeerDID] = try await oldAgent
            .using(ability: DidcommAgentAbility.self, action: "gets peer dids")
            .didcommAgent
            .pluto.getAllPeerDIDs().first().await()
            .map { try PeerDID(didString: $0.did.string) }
        
        let expectedPrismDids: [DID] = try await oldAgent
            .using(ability: DidcommAgentAbility.self, action: "gets prism dids")
            .didcommAgent
            .pluto.getAllPrismDIDs().first().await()
            .map { try DID(string: $0.did.string) }
        
        let expectedDidPairs: [DIDPair] = try await oldAgent
            .using(ability: DidcommAgentAbility.self, action: "gets did pairs")
            .didcommAgent
            .pluto.getAllDidPairs().first().await()
        
        let actualCredentials: [Credential] = try await newAgent
            .using(ability: DidcommAgentAbility.self, action: "gets credentials")
            .didcommAgent.edgeAgent
            .verifiableCredentials().first().await()
        
        let actualPeerDids: [PeerDID] = try await newAgent
            .using(ability: DidcommAgentAbility.self, action: "gets peer dids")
            .didcommAgent
            .pluto.getAllPeerDIDs().first().await()
            .map { try PeerDID(didString: $0.did.string) }
        
        let actualPrismDids: [DID] = try await newAgent
            .using(ability: DidcommAgentAbility.self, action: "gets prism dids")
            .didcommAgent
            .pluto.getAllPrismDIDs().first().await()
            .map { try DID(string: $0.did.string) }
        
        let actualDidPairs: [DIDPair] = try await newAgent
            .using(ability: DidcommAgentAbility.self, action: "gets did pairs")
            .didcommAgent.pluto.getAllDidPairs().first().await()
        
        let previousPeerDids: Int = try await newAgent.recall(key: "currentPeerDids")
        let previousPrismDids: Int = try await newAgent.recall(key: "currentPrismDids")
        let previousCredentials: Int = try await newAgent.recall(key: "currentCredentials")
        let previousCurrentDidPairs: Int = try await newAgent.recall(key: "currentDidPairs")
        
        // adds any previous data from the old agent before restoring the backup
        assertThat(actualCredentials.count, equalTo(expectedCredentials.count + previousCredentials))
        assertThat(actualPeerDids.count, equalTo(expectedPeerDids.count + previousPeerDids))
        assertThat(actualPrismDids.count, equalTo(expectedPrismDids.count + previousPrismDids))
        assertThat(actualDidPairs.count, equalTo(expectedDidPairs.count + previousCurrentDidPairs))
        
        expectedCredentials.forEach { expectedCredential in
            assertThat(actualCredentials.contains(where: { $0.id == expectedCredential.id }), equalTo(true))
        }
        expectedPeerDids.forEach { expectedPeerDid in
            assertThat(actualPeerDids.contains(where: { $0.string == expectedPeerDid.string }), equalTo(true))
        }
        expectedPrismDids.forEach { expectedPrismDid in
            assertThat(actualPrismDids.contains(where: { $0.string == expectedPrismDid.string }), equalTo(true))
        }
        expectedDidPairs.forEach { expectedDidPair in
            assertThat(actualDidPairs.contains(where: { $0.name == expectedDidPair.name }), equalTo(true))
        }
        
        actualPeerDids.forEach { peerDid in
            let contain = expectedPeerDids.contains(where: { $0.string == peerDid.string })
            print("\(peerDid.string) is contained in expected? \(contain)")
        }
    }
    
    static func waitForCredentialRevocationMessage(edgeAgent: Actor, numberOfRevocation: Int) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "wait for revocation notification"
        ) { ability in
            return ability.revocationStack.count == numberOfRevocation
        }
    }
    
    static func waitUntilCredentialIsRevoked(edgeAgent: Actor, revokedRecordIdList: [String]) async throws {
        var revokedIdList: [String] = []
        for revokedRecordId in revokedRecordIdList {
            revokedIdList.append(try await edgeAgent.recall(key: revokedRecordId))
        }
        let credentials = try await edgeAgent
            .using(ability: DidcommAgentAbility.self, action: "")
            .didcommAgent.edgeAgent
            .verifiableCredentials().first().await()
        
        var revokedCredentials: [Credential] = []
        for credential in credentials {
            if ((try await credential.revocable?.isRevoked) != nil) {
                revokedCredentials.append(credential)
            }
        }
        assertThat(revokedRecordIdList.count, equalTo(revokedCredentials.count))
    }
    
    static func initiatePresentationRequest(
        edgeAgent: Actor,
        credentialType: CredentialType,
        toDid: DID,
        claims: [ClaimFilter]
    ) async throws {
        let hostDid: DID = try await edgeAgent.using(ability: DidcommAgentAbility.self, action: "creates peer did")
            .didcommAgent.createNewPeerDID(updateMediator: true)
        let request = try await edgeAgent.using(ability: DidcommAgentAbility.self, action: "creates verification request")
            .didcommAgent.initiatePresentationRequest(
                type: credentialType,
                fromDID: hostDid,
                toDID: toDid,
                claimFilters: claims
            )
        _ = try await edgeAgent.using(ability: DidcommAgentAbility.self, action: "sends verification request")
            .didcommAgent.sendMessage(message: request.makeMessage())
    }
    
    static func waitForPresentationMessage(edgeAgent: Actor, numberOfPresentations: Int = 1) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "waits for presentation message"
        ) { ability in
            return ability.presentationStack.count == numberOfPresentations
        }
    }
    
    static func verifyPresentation(edgeAgent: Actor, isRevoked: Bool = false) async throws {
        let presentation = try await edgeAgent.using(ability: DidcommAgentAbility.self, action: "retrieves presentation message")
            .presentationStack.removeFirst()
        do {
            let result = try await edgeAgent.using(
                ability: DidcommAgentAbility.self,
                action: "verify the presentation"
            ).didcommAgent.verifyPresentation(message: presentation)
            assertThat(isRevoked, equalTo(false))
        } catch let error as PolluxError {
            switch error {
            case .cannotVerifyCredential(let credential, let internalErrors):
                assertThat(internalErrors.count == 1)
                if internalErrors[0] is PolluxError {
                    switch internalErrors[0] as! PolluxError {
                    case .credentialIsRevoked:
                        assertThat(isRevoked, equalTo(true))
                    default:
                        throw internalErrors[0]
                    }
                } else {
                    throw internalErrors[0]
                }
            default:
                throw error
            }
        }
    }
}
