[![Coverage Status](https://coveralls.io/repos/github/hyperledger/identus-edge-agent-sdk-swift/badge.svg?branch=main)](https://coveralls.io/github/hyperledger/identus-edge-agent-sdk-swift?branch=main)

# Welcome to Identus Swift SDK

The following will explain how to use the SDK in your project, how to prepare your development environment if you wish to contribute and some basic considerations around the project.

This SDK provides a library and documentation for developers to build Apple connected SSI applications with Atala PRISM.

## Basic considerations

### Identus

Identus is a self-sovereign identity (SSI) platform and service suite for verifiable data and digital identity. Built on Cardano, it offers the core infrastructure for issuing DIDs (Decentralized identifiers) and verifiable credentials alongside tools and frameworks to help expand your ecosystem.
The complete platform is separated into multiple repositories:

* [sdk-swift](https://github.com/hyperledger-identus/sdk-swift/) - Repo that implements Edge Agent for Apple platforms in Swift.
* [sdk-ts](https://github.com/hyperledger-identus/sdk-ts/) - Repo that implements Edge Agent for Browser and NodeJS platforms in Typescript.
* [sdk-kmp](https://github.com/hyperledger-identus/sdk-kmp/) - Repo that implements Edge Agent for Android and JVM platforms in Kotlin Multi-Platform.
* [cloud-agent](https://github.com/hyperledger-identus/cloud-agent/) - Repo that contains the platform Building Blocks.
* [mediator](https://github.com/hyperledger-identus/mediator/) - Repo for DIDComm V2 Mediator

### Modules / APIs

Identus Swift SDK provides the following building blocks to create, manage and resolve decentralized identifiers; issue, manage and verify verifiable credentials; establish and manage trusted, peer-to-peer connections and interactions between DIDs; and store, manage, and recover verifiable data linked to DIDs.

* __Apollo__: Building block that provides a suite of cryptographic operations.
* __Castor__: Building block that provides a suite of DID operations in a user-controlled manner.
* __Pollux__: Building block that provides a suite of credential operations in a privacy-preserving manner.
* __Mercury__: Building block that provides a set of secure, standards-based communications protocols in a transport-agnostic and interoperable manner.
* __Pluto__: Building block that provides an interface for storage operations in a portable, storage-agnostic manner.
* __EdgeAgent__: EdgeAgent, using all the building blocks, provides an agent that can provide a set of high-level DID functionalities.

## Getting Started

### Setup

To get started with the Identus Swift SDK, you can set up the SDK and create a new project or integrate the SDK into an existing project. Before you start, make sure you have the following installed on your development machine:

- Xcode 13.4 or later
- MacOS 12 or later
- iOS 15 or later

### Integrating the SDK in an existing project

To integrate the SDK into an existing project, you can use the Swift Package Manager, distributed with Xcode.

1. Open your project in Xcode and select **File > Swift Packages > Add Package Dependency**.
2. Enter the URL for the SDK for Swift Package Manager GitHub repo (`https://github.com/hyperledger-identus/sdk-swift/`) into the search bar and click **Next**.
3. You'll see the repository rules for which version of the SDK you want Swift Package Manager to install. Choose the first rule, **Version**, and select **Up to Next Minor** as it will use the latest compatible version of the dependency that can be detected from the `main` branch, then click **Next**.

### Swift Package Manager

The Swift Package Manager is a tool for managing the distribution of Swift code. It's integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.
