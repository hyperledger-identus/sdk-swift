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
        
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "parses an OOB invitation"
        ) { sdk in
            let oob = try sdk.didcommAgent.parseOOBInvitation(url: url)
            try await sdk.didcommAgent.acceptDIDCommInvitation(invitation: oob)
        }
    }
    
    static func waitToReceiveCredentialsOffer(edgeAgent: Actor, numberOfCredentials: Int) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "credential offer count to be \(numberOfCredentials)"
        ) { sdk in
            return sdk.credentialOfferStack.count == numberOfCredentials
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
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "accepts the credential offer"
        ) { sdk in
            let message = sdk.credentialOfferStack.first!
            _ = sdk.credentialOfferStack.removeFirst()
            
            let format = message.attachments[0].format
            let did: DID
            
            switch(format) {
            case "anoncreds/credential-offer@v1.0":
                did = try await sdk.didcommAgent.createNewPrismDID()
                break
            case "vc+sd-jwt":
                let privateKey = try sdk.didcommAgent.apollo.createPrivateKey(parameters: [
                    KeyProperties.type.rawValue: "EC",
                    KeyProperties.curve.rawValue: KnownKeyCurves.ed25519.rawValue
                ])
                
                did = try await sdk.didcommAgent.createNewPrismDID(
                    keys: [(KeyPurpose.authentication, privateKey)]
                )
                break
            case "prism/jwt":
                let seed = sdk.didcommAgent.edgeAgent.seed
                let privateKey = try sdk.didcommAgent.apollo.createPrivateKey(parameters: [
                    KeyProperties.type.rawValue: "EC",
                    KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
                    KeyProperties.seed.rawValue: seed.value.base64EncodedString(),
                    KeyProperties.derivationPath.rawValue: DerivationPath().keyPathString()
                ])
                
                did = try await sdk.didcommAgent.createNewPrismDID(
                    keys: [(KeyPurpose.authentication, privateKey)]
                )
                break
            default:
                throw ValidationError.error(message: "Format \(format!) not supported")
            }
            
            let acceptOfferMessage = try OfferCredential3_0(fromMessage: message)
            let requestCredential = try await sdk.didcommAgent.prepareRequestCredentialWithIssuer(
                did: did,
                offer: acceptOfferMessage
            )!.makeMessage()
            _ = try await sdk.didcommAgent.sendMessage(message: requestCredential)
        }
        
    }
    
    static func waitToReceiveIssuedCredentials(edgeAgent: Actor, numberOfCredentials: Int) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "wait for issued credentials to be \(numberOfCredentials)"
        ) { sdk in
            return sdk.issueCredentialStack.count == numberOfCredentials
        }
    }
    
    static func processIssuedCredential(edgeAgent: Actor, recordId: String) async throws {
        _ = try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "process the issued credential"
        ) { sdk in
            let message = sdk.issueCredentialStack.removeFirst()
            let issuedCredential = try IssueCredential3_0(fromMessage: message)
            let credential = try await sdk.didcommAgent.processIssuedCredentialMessage(message: issuedCredential)
            try await edgeAgent.remember(key: recordId, value: message.id)
        }
    }
    
    static func waitForProofRequest(edgeAgent: Actor) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "wait for present proof request"
        ) { sdk in
            return sdk.proofOfRequestStack.count == 1
        }
    }
    
    static func presentProof(edgeAgent: Actor) async throws {
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "creates and send the proof"
        ) { sdk in
            let credentials = sdk.didcommAgent.edgeAgent.verifiableCredentials()
            let credential = try await credentials.map { $0.first }.first().await()
            
            guard let credential else {
                throw ValidationError.error(message: "No credential available to present")
            }
            
            let message = sdk.proofOfRequestStack.removeFirst()
            let requestPresentationMessage = try RequestPresentation(fromMessage: message)
            let sendProofMessage = try await sdk.didcommAgent.createPresentationForRequestProof(
                request: requestPresentationMessage,
                credential: credential,
                options: [.disclosingClaims(claims: ["automation-required"])]
            ).makeMessage()
            _ = try await sdk.didcommAgent.sendMessage(message: sendProofMessage)
        }
    }
    
    static func tryToPresentVerificationRequestWithWrongAnoncred(edgeAgent: Actor) async throws {
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "get a verifiable credential"
        ) { sdk in
            let credential = try await sdk.didcommAgent.edgeAgent.verifiableCredentials().map { $0.first }.first().await()
            let message = sdk.proofOfRequestStack.first!
            _ = sdk.proofOfRequestStack.removeFirst()
            let requestPresentationMessage = try RequestPresentation(fromMessage: message)
            await assertThrows(try await sdk.didcommAgent.createPresentationForRequestProof(request: requestPresentationMessage, credential: credential!).makeMessage())
        }
    }
    
    static func shouldNotBeAbleToCreatePresentProof(edgeAgent: Actor) async throws {
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "tries to create the proof"
        ) { sdk in
            let credentials = sdk.didcommAgent.edgeAgent.verifiableCredentials()
            let credential = try await credentials.map { $0.first }.first().await()
            let message = sdk.proofOfRequestStack.removeFirst()
            let requestPresentationMessage = try RequestPresentation(fromMessage: message)
            try await assertThrows(await sdk.didcommAgent.createPresentationForRequestProof(
                request: requestPresentationMessage,
                credential: credential!,
                options: [.disclosingClaims(claims: ["automation-required"])]
            ).makeMessage())
        }
    }
    
    static func createBackup(edgeAgent: Actor) async throws {
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "creates a backup"
        ) { sdk in
            let backup = try await sdk.didcommAgent.edgeAgent.backupWallet()
            let seed = sdk.didcommAgent.edgeAgent.seed
            try await edgeAgent.remember(key: "backup", value: backup)
            try await edgeAgent.remember(key: "seed", value: seed)
        }
    }
    
    static func createNewWalletFromBackup(restoredAgent: Actor, edgeAgent: Actor) async throws {
        let backup: String = try await edgeAgent.recall(key: "backup")
        let seed: Seed = try await edgeAgent.recall(key: "seed")
        try await restoredAgent.whoCanUse(DidcommAgentAbility(seed: seed)).perform(
            withAbility: DidcommAgentAbility.self,
            description: "recover wallet"
        ) { sdk in
            try await sdk.didcommAgent.edgeAgent.recoverWallet(encrypted: backup)
        }
    }
    
    static func createNewWalletFromBackupWithWrongSeed(restoredAgent: Actor, edgeAgent: Actor) async throws {
        let backup: String = try await edgeAgent.recall(key: "backup")
        let seed = DidcommAgentAbility.wrongSeed
        
        try await restoredAgent.whoCanUse(DidcommAgentAbility(seed: seed)).perform(
            withAbility: DidcommAgentAbility.self,
            description: "recover wallet"
        ) { sdk in
            do {
                try await sdk.didcommAgent.edgeAgent.recoverWallet(encrypted: backup)
                XCTFail("SDK should not be able to restore with wrong seed phrase.")
            } catch {
            }
        }
    }
    
    static func createPeerDids(edgeAgent: Actor, numberOfDids: Int) async throws {
        for _ in 0..<numberOfDids {
            let did: DID = try await edgeAgent.perform(
                withAbility: DidcommAgentAbility.self,
                description: "creates peer did"
            ){ sdk in
                try await sdk.didcommAgent.createNewPeerDID(updateMediator: true)
            }
            try await edgeAgent.remember(key: "lastPeerDid", value: did)
        }
    }
    
    static func createPrismDids(edgeAgent: Actor, numberOfDids: Int) async throws {
        for _ in 0..<numberOfDids {
            _ = try await edgeAgent.perform(
                withAbility: DidcommAgentAbility.self,
                description: "creates peer did"
            ){ sdk in
                try await sdk.didcommAgent.createNewPrismDID()
            }
        }
    }
    
    static func backupAndRestoreToNewAgent(newAgent: Actor, oldAgent: Actor) async throws {
        let backup: String = try await oldAgent.recall(key: "backup")
        try await newAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "recovers wallet"
        ){ sdk in
            try await sdk.didcommAgent.edgeAgent.recoverWallet(encrypted: backup)
        }
    }
    
    static func newAgentShouldMatchOldAgent(newAgent: Actor, oldAgent: Actor) async throws {
        let expectedCredentials: [Credential] = try await oldAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets credentials"
        ){ try await $0.didcommAgent.edgeAgent.verifiableCredentials().first().await() }
        
        let expectedPeerDids: [PeerDID] = try await oldAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets peer dids"
        ){ try await $0.didcommAgent.pluto.getAllPeerDIDs().first().await().map { try PeerDID(didString: $0.did.string) }}
        
        let expectedPrismDids: [DID] = try await oldAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets prism dids"
        ){ try await $0.didcommAgent.pluto.getAllPrismDIDs().first().await().map { try DID(string: $0.did.string) }}
        
        let expectedDidPairs: [DIDPair] = try await oldAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets did pairs"
        ){ try await $0.didcommAgent.pluto.getAllDidPairs().first().await() }
        
        let actualCredentials: [Credential] = try await newAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets credentials"
        ){ try await $0.didcommAgent.edgeAgent.verifiableCredentials().first().await() }
        
        let actualPeerDids: [PeerDID] = try await newAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets peer dids"
        ){ try await $0.didcommAgent.pluto.getAllPeerDIDs().first().await().map { try PeerDID(didString: $0.did.string) }}
        
        let actualPrismDids: [DID] = try await newAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets prism dids"
        ){ try await $0.didcommAgent.pluto.getAllPrismDIDs().first().await().map { try DID(string: $0.did.string) }}
        
        let actualDidPairs: [DIDPair] = try await newAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets did pairs"
        ){ try await $0.didcommAgent.pluto.getAllDidPairs().first().await() }
        
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
        ) { sdk in
            return sdk.revocationStack.count == numberOfRevocation
        }
    }
    
    static func waitUntilCredentialIsRevoked(edgeAgent: Actor, revokedRecordIdList: [String]) async throws {
        var revokedIdList: [String] = []
        for revokedRecordId in revokedRecordIdList {
            revokedIdList.append(try await edgeAgent.recall(key: revokedRecordId))
        }
        let credentials = try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "gets the latest credential"
        ){ sdk in
            try await sdk.didcommAgent.edgeAgent.verifiableCredentials().first().await()
        }
        
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
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "initiates presentation request"
        ) { sdk in
            let hostDid: DID = try await sdk.didcommAgent.createNewPeerDID(updateMediator: true)
            let request = try sdk.didcommAgent.initiatePresentationRequest(
                type: credentialType,
                fromDID: hostDid,
                toDID: toDid,
                claimFilters: claims
            )
            _ = try await sdk.didcommAgent.sendMessage(message: request.makeMessage())
        }
    }
    
    static func waitForPresentationMessage(edgeAgent: Actor, numberOfPresentations: Int = 1) async throws {
        try await edgeAgent.waitUsingAbility(
            ability: DidcommAgentAbility.self,
            action: "waits for presentation message"
        ) { sdk in
            return sdk.presentationStack.count == numberOfPresentations
        }
    }
    
    static func verifyPresentation(edgeAgent: Actor, isRevoked: Bool = false) async throws {
        try await edgeAgent.perform(
            withAbility: DidcommAgentAbility.self,
            description: "verify the presentation"
        ) { sdk in
            let presentation = sdk.presentationStack.removeFirst()
            do {
                _ = try await sdk.didcommAgent.verifyPresentation(message: presentation)
                assertThat(isRevoked, equalTo(false))
            } catch let error as PolluxError {
                switch error {
                case .cannotVerifyCredential(_, let internalErrors):
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
}
