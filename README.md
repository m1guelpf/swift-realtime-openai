# A modern Swift SDK for OpenAI's Realtime API

[![Install Size](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fwww.emergetools.com%2Fapi%2Fv2%2Fpublic_new_build%3FexampleId%3Dswift-realtime-openai.OpenAI%26platform%3Dios%26badgeOption%3Dmax_install_size_only%26buildType%3Drelease&query=$.badgeMetadata&label=OpenAI&logo=apple)](https://www.emergetools.com/app/example/ios/swift-realtime-openai.OpenAI/release)
[![Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fm1guelpf%2Fswift-realtime-openai%2Fbadge%3Ftype%3Dswift-versions&color=brightgreen)](https://swiftpackageindex.com/m1guelpf/swift-realtime-openai)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/m1guelpf/swift-realtime-openai/main/LICENSE)

**[Update Feb 21, 2025 Added the WebRTC support. See the complete demo [here](https://github.com/jeffxtang/ios_realtime_api) on how to use both WebRTC and WebSocket.]**

This library provides a simple interface for implementing multi-modal conversations using OpenAI's new Realtime API.

It can handle automatically recording the user's microphone and playing back the assistant's response, and also gives you a transparent layer over the API for advanced use cases.

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
-   [x] Optionally handle recording the user's mic and sending it to the API
-   [x] Optionally handle playing model responses as they stream in
-   [x] Allow interrupting the model
-   [x] WebRTC support

## Architecture

### `Conversation`

The `Conversation` class provides a high-level interface for managing a conversation with the model. It wraps the `RealtimeAPI` class and handles the details of sending and receiving messages, as well as managing the conversation history. It can optionally also handle recording the user's mic and sending it to the API, as well as playing model responses as they stream in.

#### Reading messages

You can access the messages in the conversation through the `messages` property. Note that this won't include function calls and its responses, only the messages between the user and the model. To access the full conversation history, use the `entries` property. For example:

```swift
ScrollView {
    ScrollViewReader { scrollView in
        VStack(spacing: 12) {
            ForEach(conversation.messages, id: \.id) { message in
                MessageBubble(message: message).id(message.id)
            }
        }
        .onReceive(conversation.messages.publisher) { _ in
            withAnimation { scrollView.scrollTo(conversation.messages.last?.id, anchor: .center) }
        }
    }
}
```

#### Customizing the session

You can customize the current session using the `setSession(_: Session)` or `updateSession(withChanges: (inout Session) -> Void)` methods. Note that they requires that a session has already been established, so it's recommended you call them from a `whenConnected(_: @Sendable () async throws -> Void)` callback or await `waitForConnection()` first. For example:

```swift
try await conversation.whenConnected {
    try await conversation.updateSession { session in
        // update system prompt
        session.instructions = "You are a helpful assistant."

        // enable transcription of users' voice messages
        session.inputAudioTranscription = Session.InputAudioTranscription()

        // ...
    }
}
```

#### Handling voice conversations

The `Conversation` class can automatically handle 2-way voice conversations. Calling `startListening()` will start listening to the user's voice and sending it to the model, and playing back the model's responses. Calling `stopListening()` will stop listening, but continue playing back responses.

If you just want to play model responses, call `startHandlingVoice()`. To stop both listening and playing back responses, call `stopHandlingVoice()`.

#### Manually sending messages

To send a text message, call the `send(from: Item.ItemRole, text: String, response: Response.Config? = nil)` providing the role of the sender (`.user`, `.assistant`, or `.system`) and the contents of the message. You can optionally also provide a `Response.Config` object to customize the response, such as enabling or disabling function calls.

To manually send an audio message (or part of one), call the `send(audioDelta: Data, commit: Bool = false)` with a valid audio chunk. If `commit` is `true`, the model will consider the message finished and begin responding to it. Otherwise, it might wait for more audio depending on your `Session.turnDetection` settings.

#### Manually sending events

To manually send an event to the API, use the `send(event: RealtimeAPI.ClientEvent)` method. Note that this bypasses some of the logic in the `Conversation` class such as handling interrupts, so you should prefer to use other methods whenever possible.

### `RealtimeAPI`

To interact with the API directly, create a new instance of `RealtimeAPI` providing one of the available connectors. There are helper methods that let you create an instance from an apiKey or a `URLRequest`, like so:

```swift
let api = RealtimeAPI.webSocket(authToken: YOUR_OPENAI_API_KEY, model: String = "gpt-4o-realtime-preview") // or RealtimeAPI.webSocket(connectingTo: URLRequest)
let api = RealtimeAPI.webRTC(authToken: YOUR_OPENAI_API_KEY, model: String = "gpt-4o-realtime-preview") // or RealtimeAPI.webRTC(connectingTo: URLRequest)
```

You can listen for new events through the `events` property, like so:

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
