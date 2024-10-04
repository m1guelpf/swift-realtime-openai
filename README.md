# A modern Swift SDK for OpenAI's Realtime API

[![Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm1guelpf%2Fswift-realtime-openai%2Fbadge%3Ftype%3Dswift-versions&color=brightgreen)](http://swift.org)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/m1guelpf/swift-realtime-openai/main/LICENSE)

This library provides a transparent interface for interacting with OpenAI's new Realtime API.

It will soon also provide an abstraction over itself that manages the conversation for you, and another layer that automatically handles voice conversations soon after.

## Installation

### Swift Package Manager

The Swift Package Manager allows for developers to easily integrate packages into their Xcode projects and packages; and is also fully integrated into the swift compiler.

### SPM Through XCode Project

-   File > Swift Packages > Add Package Dependency
-   Add https://github.com/m1guelpf/swift-realtime-openai.git
-   Select "Branch" with "main"

### SPM Through Xcode Package

Once you have your Swift package set up, add the Git link within the dependencies value of your Package.swift file.

```swift
dependencies: [
    .package(url: "https://github.com/m1guelpf/swift-realtime-openai.git", .branch("main"))
]
```

## Getting started 🚀

```swift
import OpenAI
import SwiftUI

public struct ContentView: View {
	@State private var api = RealtimeAPI(auth_token: OPENAI_KEY)

	public var body: some View {
		VStack {
			Button("Send Message") { self.sendMessage("Hi!") }
		}
        .task {
			do {
				for try await event in api.events {
					print(event)
				}
			} catch {}
		}
	}

    func sendMessage(_ message: String) {
        Task {
            try! await api.send(event: .createConversationItem(Item(message: .init(id: "msg-1", from: .user, content: [.input_text(message)]))))
            try! await api.send(event: .createResponse())
        }
    }
}
```

## Features

-   [x] A simple interface for directly interacting with the API
-   [ ] Wrap the API in an interface that manages the conversation for you
-   [ ] Handle recording the mic and playing model responses for you

## Architecture

### RealtimeAPI

To connect to the API, create a new instance of `RealtimeAPI` providing a valid OpenAI API Key. The websocket connection will be automatically established. You can listen for new events through the `events` property, like so:

```swift
for try await event in api.events {
    switch event {
        case let .sessionCreated(event):
            print(event.session.id)
    }
}
```

To send an event to the API, call the `send` method with a `ClientEvent` instance:

```swift
try await api.send(event: .updateSession(session))
try await api.send(event: .appendInputAudioBuffer(encoding: audioData))
try await api.send(event: .createResponse())
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
