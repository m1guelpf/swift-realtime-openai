# A modern Swift SDK for OpenAI's Realtime API

[![Install Size](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fwww.emergetools.com%2Fapi%2Fv2%2Fpublic_new_build%3FexampleId%3Dswift-realtime-openai.OpenAI%26platform%3Dios%26badgeOption%3Dmax_install_size_only%26buildType%3Drelease&query=$.badgeMetadata&label=OpenAI&logo=apple)](https://www.emergetools.com/app/example/ios/swift-realtime-openai.OpenAI/release)
[![Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm1guelpf%2Fswift-realtime-openai%2Fbadge%3Ftype%3Dswift-versions&color=brightgreen)](https://swiftpackageindex.com/m1guelpf/swift-realtime-openai)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/m1guelpf/swift-realtime-openai/main/LICENSE)

This library provides a simple interface for implementing multi-modal conversations using OpenAI's new Realtime API.

It also gives you a transparent layer over the API for advanced use cases, and will soon include another layer that automatically handles recording the user's microphone and playing back the assistant's response.

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

You can build an iMessage-like app with built-in AI chat in less than 60 lines of code (UI included!):

```swift
import OpenAI
import SwiftUI

struct ContentView: View {
	@State private var newMessage: String = ""
	@State private var conversation = Conversation(authToken: OPENAI_KEY)

	var messages: [Item.Message] {
		conversation.entries.compactMap { switch $0 {
			case let .message(message): return message
			default: return nil
		} }
	}

	var body: some View {
		VStack(spacing: 0) {
			ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages, id: \.id) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
			}

			HStack(spacing: 12) {
				HStack {
					TextField("Chat", text: $newMessage, onCommit: { sendMessage() })
						.frame(height: 40)
						.submitLabel(.send)

					if newMessage != "" {
						Button(action: sendMessage) {
							Image(systemName: "arrow.up.circle.fill")
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 28, height: 28)
								.foregroundStyle(.white, .blue)
						}
					}
				}
				.padding(.leading)
				.padding(.trailing, 6)
				.overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))
			}
			.padding()
		}
		.navigationTitle("Chat")
		.navigationBarTitleDisplayMode(.inline)
		.onAppear { try! conversation.startHandlingVoice() }
	}

	func sendMessage() {
		guard newMessage != "" else { return }

		Task {
			try await conversation.send(from: .user, text: newMessage)
			newMessage = ""
		}
	}
}
```

Or, if you just want a simple app that lets the user talk and the AI respond:

```swift
import OpenAI
import SwiftUI

struct ContentView: View {
	@State private var conversation = Conversation(authToken: OPENAI_KEY)

	var body: some View {
		Text("Say something!")
			.onAppear { try! conversation.startListening() }
	}
}
```

## Features

-   [x] A simple interface for directly interacting with the API
-   [x] Wrap the API in an interface that manages the conversation for you
-   [x] Handle recording the mic and playing model responses for you
-   [ ] Handle playing model responses as they stream in
-   [ ] Handle interrupting the model

## Architecture

### RealtimeAPI

To interact with the API directly, create a new instance of `RealtimeAPI` providing a valid OpenAI API Key. The websocket connection will be automatically established. You can listen for new events through the `events` property, like so:

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
