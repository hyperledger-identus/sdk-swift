import Foundation
import Domain
import Core
import OpenAPIRuntime
import OpenAPIURLSession
import Castor

class PrismShortFormResolver: DIDResolverDomain {
    let method: Domain.DIDMethod = "prism"
    
    func convertServiceEndpoints(from container: OpenAPIValueContainer) throws -> [DIDDocument.Service.ServiceEndpoint] {
        guard let arrayValue = container.value as? [[String: (any Sendable)?]] else {
            return []
        }
        
        return try arrayValue.compactMap { dictionary in
            guard let uri = dictionary["uri"] as? String else { throw ValidationError.error(message: "unable to get uri") }
            let accept = (dictionary["accept"] as? [String]) ?? []
            let routingKeys = (dictionary["routingKeys"] as? [String]) ?? []
            
            return DIDDocument.Service.ServiceEndpoint(uri: uri, accept: accept, routingKeys: routingKeys)
        }
    }
    
    func extractServicesProperty(_ incomingDidDocument: Components.Schemas.DIDDocument?) throws -> DIDDocument.Services {
        return DIDDocument.Services(
            values: try incomingDidDocument?.service?.map { service in
                let type: [String]
                switch (service._type) {
                case .case1(let arr):
                    type = arr
                    break
                case .case2(let str):
                    type = [str]
                    break
                }
                return DIDDocument.Service(
                    id: service.id,
                    type: type,
                    serviceEndpoint: try convertServiceEndpoints(from: service.serviceEndpoint)
                )
            } ?? []
        )
    }
    
    func extractVerificationMethodsProperty(_ incomingDidDocument: Components.Schemas.DIDDocument?) throws -> DIDDocument.VerificationMethods {
        return DIDDocument.VerificationMethods(
            values: try incomingDidDocument?.verificationMethod?.map { verificationMethod in
                return DIDDocument.VerificationMethod(
                    id: try DIDUrl(string: verificationMethod.id),
                    controller: try DID(string: verificationMethod.controller),
                    type: verificationMethod._type,
                    publicKeyJwk: convertPublicKeyJwkToDictionary(verificationMethod.publicKeyJwk)
                )
            } ?? []
        )
    }
    
    func convertPublicKeyJwkToDictionary(_ publicKeyJwk: Components.Schemas.PublicKeyJwk) -> [String: String] {
        var dictionary: [String: String] = [:]
        
        if let crv = publicKeyJwk.crv {
            dictionary["crv"] = crv
        }
        if let x = publicKeyJwk.x {
            dictionary["x"] = x
        }
        if let y = publicKeyJwk.y {
            dictionary["y"] = y
        }
        dictionary["kty"] = publicKeyJwk.kty
        
        return dictionary
    }
    
    func resolve(did: Domain.DID) async throws -> Domain.DIDDocument {
        if (did.string.split(separator: ":").count > 3) {
            throw ValidationError.error(message: "did is in long form did")
        }
        
        guard let url = URL(string: "\(Config.agentUrl)/dids/\(did.string)") else {
            throw ValidationError.error(message: "Invalid URL \(did.string)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ValidationError.http(message: "Unexpected response in prism short form resolver")
        }
        
        if (httpResponse.statusCode != 200) {
            throw ValidationError.http(message: "Failed resolving \(did) prism short form")
        }
        
        guard let contentType = httpResponse.allHeaderFields["Content-Type"] as? String else {
            throw ValidationError.http(message: "Content-Type header missing")
        }
        
        let decoder = JSONDecoder()
        
        if (contentType == "application/ld+json; profile=https://w3id.org/did-resolution"){
            do {
                let resolutionResult = try decoder.decode(Components.Schemas.DIDResolutionResult.self, from: data)
                let incomingDidDocument = resolutionResult.didDocument
                
                let servicesProperty = try extractServicesProperty(incomingDidDocument)
                let verificationMethodsProperty = try extractVerificationMethodsProperty(incomingDidDocument)
                
                var authentications: [DIDDocument.Authentication] = []
                var assertionMethods: [DIDDocument.AssertionMethod] = []
                
                incomingDidDocument?.verificationMethod?.forEach { verification in
                    let assertion: [String] = incomingDidDocument?.assertionMethod?.filter { assertionMethod in
                        return assertionMethod == verification.id
                    } ?? []
                    if (!assertion.isEmpty) {
                        assertionMethods.append(
                            DIDDocument.AssertionMethod(
                                urls: assertion,
                                verificationMethods: verificationMethodsProperty.values.filter { verificationMethod in
                                    verification.id == verificationMethod.id.string
                                }
                            )
                        )
                    }
                    
                    let authentication = incomingDidDocument?.authentication?.filter { authentication in
                        return authentication == verification.id
                    } ?? []
                    if (!authentication.isEmpty) {
                        authentications.append(
                            DIDDocument.Authentication(
                                urls: assertion,
                                verificationMethods: verificationMethodsProperty.values.filter { verificationMethod in
                                    verification.id == verificationMethod.id.string
                                }
                            )
                        )
                    }
                }

                var coreProperties: [DIDDocumentCoreProperty] = []
                coreProperties.append(contentsOf: authentications)
                coreProperties.append(contentsOf: assertionMethods)
                coreProperties.append(servicesProperty)
                coreProperties.append(verificationMethodsProperty)
                
                let didDocument = DIDDocument(
                    id: did,
                    coreProperties: coreProperties
                )
                return didDocument
            } catch {
                throw ValidationError.http(message: "Failed to decode DIDResolutionResult: \(error)")
            }
        }
        
        if (contentType == "application/did+ld+json") {
            do {
                let didDocument = try decoder.decode(Components.Schemas.DIDDocument.self, from: data)
            } catch {
                throw ValidationError.http(message: "Failed to decode DIDDocument: \(error)")
            }
        } else {
            throw ValidationError.http(message: "Unsupported Content-Type: \(contentType)")
        }
        
        throw ValidationError.error(message: "Unexpected error in prism short form resolver")
    }
}
