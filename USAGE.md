# OpenAI Realtime API Swift Library Usage Guide

This guide provides comprehensive documentation and code examples for using the OpenAI Realtime API Swift library in your iOS, macOS, tvOS, watchOS, and visionOS applications.

## Table of Contents
1. [Installation](#installation)
2. [Basic Setup](#basic-setup)
3. [Connection Management](#connection-management)
4. [Basic Messaging](#basic-messaging)
5. [Function Calls](#function-calls)
6. [Audio Handling](#audio-handling)
7. [SwiftUI Integration](#swiftui-integration)
8. [Advanced Configuration](#advanced-configuration)
9. [Error Handling](#error-handling)

## Installation

### Swift Package Manager

Add the OpenAI Realtime library to your project using Swift Package Manager:

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter the repository URL: `https://github.com/your-repo/swift-realtime-openai`
3. Select the version and add to your target

Or add it manually to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/swift-realtime-openai", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["OpenAIRealtime"]
    )
]
```

### Platform Requirements

- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- watchOS 10.0+
- visionOS 1.0+
- Mac Catalyst 17.0+

## Basic Setup

Import the library in your Swift files:

```swift
import OpenAIRealtime
```

## Connection Management

### WebSocket Connection with API Token

The simplest way to connect using your OpenAI API token:

```swift
import OpenAIRealtime

class ChatManager: ObservableObject {
    private var conversation: Conversation?

    func connect() async throws {
        conversation = Conversation(
            authToken: "your-openai-api-key",
            model: "gpt-4o-realtime-preview"
        )

        // Wait for connection to be established
        await conversation?.waitForConnection()
        print("Connected to OpenAI Realtime API")
    }

    func disconnect() {
        conversation = nil
    }
}
```

### Custom URLRequest Connection

For more advanced configuration:

```swift
func connectWithCustomRequest() async throws {
    var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime")!)
    request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
    request.setValue("Bearer your-api-key", forHTTPHeaderField: "Authorization")

    conversation = Conversation(connectingTo: request)
    await conversation?.waitForConnection()
}
```

### WebRTC Connection (Experimental)

For lower-latency connections using WebRTC:

```swift
func connectWebRTC() async throws {
    let api = try await RealtimeAPI.webRTC(
        authToken: "your-api-key",
        model: "gpt-4o-realtime-preview"
    )
    conversation = Conversation(client: api)
}
```

### Connection State Monitoring

```swift
// Monitor connection state
Task {
    for await error in conversation.errors {
        print("Connection error: \(error)")
        // Handle reconnection logic here
    }
}

// Check connection status
if await conversation.connected {
    print("Connected and ready")
}
```

## Basic Messaging

### Sending Text Messages

```swift
// Send a user message
try await conversation.send(from: .user, text: "Hello, how are you today?")

// Send a system message
try await conversation.send(from: .system, text: "You are a helpful assistant.")

// Send an assistant message (useful for conversation context)
try await conversation.send(from: .assistant, text: "I'm doing well, thank you!")
```

### Accessing Messages

```swift
// Get all messages in the conversation
let messages = await conversation.messages
for message in messages {
    print("\(message.role): \(message.content.first?.text ?? "")")
}

// Get all entries (includes function calls and other items)
let entries = await conversation.entries
```

### Message History Management

```swift
// Access conversation ID
let conversationId = await conversation.id

// Check if there are any messages
if await !conversation.messages.isEmpty {
    print("Conversation has \(await conversation.messages.count) messages")
}
```

## Function Calls

### Defining Functions

Define functions that the AI can call using JSON Schema:

```swift
// Define a weather function
let weatherFunction = Session.Tool(
    name: "get_weather",
    description: "Get the current weather for a location",
    parameters: Session.Tool.FunctionParameters(
        type: .object,
        properties: [
            "location": Session.Tool.FunctionParameters.Property(
                type: .string,
                description: "The city and state, e.g. San Francisco, CA"
            ),
            "unit": Session.Tool.FunctionParameters.Property(
                type: .string,
                description: "Temperature unit (celsius or fahrenheit)",
                enum: ["celsius", "fahrenheit"]
            )
        ],
        required: ["location"]
    )
)
```

### Registering Functions in Session

```swift
func setupSessionWithFunctions() async throws {
    await conversation.whenConnected {
        try await conversation.updateSession { session in
            session.tools = [weatherFunction]
            session.toolChoice = .auto
            session.instructions = "You are a helpful assistant that can check the weather."
        }
    }
}
```

### Handling Function Calls

Monitor for function call requests and respond appropriately:

```swift
class FunctionHandler: ObservableObject {
    let conversation: Conversation

    init(conversation: Conversation) {
        self.conversation = conversation
        startMonitoringFunctions()
    }

    private func startMonitoringFunctions() {
        Task {
            while !Task.isCancelled {
                // Check for function calls in conversation entries
                let entries = await conversation.entries

                for entry in entries {
                    if case let .functionCall(functionCall) = entry,
                       functionCall.status == .in_progress {
                        await handleFunctionCall(functionCall)
                    }
                }

                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    @MainActor
    private func handleFunctionCall(_ functionCall: Item.FunctionCall) async {
        switch functionCall.name {
        case "get_weather":
            await handleWeatherFunction(functionCall)
        default:
            print("Unknown function: \(functionCall.name)")
        }
    }

    private func handleWeatherFunction(_ functionCall: Item.FunctionCall) async {
        // Parse function arguments
        let arguments = functionCall.arguments

        // Simulate weather API call
        let weatherData = await fetchWeather(
            location: arguments["location"] as? String ?? "Unknown",
            unit: arguments["unit"] as? String ?? "celsius"
        )

        // Send function response back to the conversation
        let output = Item.FunctionCallOutput(
            callId: functionCall.callId,
            output: weatherData
        )

        try? await conversation.send(result: output)
    }

    private func fetchWeather(location: String, unit: String) async -> String {
        // Simulate API call
        try? await Task.sleep(for: .seconds(1))

        let temperature = unit == "celsius" ? "22°C" : "72°F"
        return "The weather in \(location) is sunny with a temperature of \(temperature)"
    }
}
```

## Audio Handling

### Setting Up Voice Conversations

```swift
@MainActor
class VoiceManager: ObservableObject {
    let conversation: Conversation

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    func startVoiceConversation() throws {
        // Enable audio handling and start listening
        try conversation.startHandlingVoice()
        try conversation.startListening()
        print("Voice conversation started")
    }

    func stopVoiceConversation() {
        conversation.stopListening()
        conversation.stopHandlingVoice()
        print("Voice conversation stopped")
    }

    func toggleListening() throws {
        if conversation.isListening {
            conversation.stopListening()
        } else {
            try conversation.startListening()
        }
    }
}
```

### Voice Configuration

Configure voice settings in your session:

```swift
func configureVoiceSession() async throws {
    await conversation.whenConnected {
        try await conversation.updateSession { session in
            session.voice = .alloy  // Available: alloy, echo, shimmer, ash, ballad, coral, sage, verse, fable, onyx, nova
            session.inputAudioFormat = .pcm16
            session.outputAudioFormat = .pcm16
            session.modalities = [.text, .audio]

            // Configure turn detection (voice activity detection)
            session.turnDetection = .serverVad(
                threshold: 0.5,
                interruptResponse: true,
                prefixPaddingMs: 300,
                silenceDurationMs: 500
            )
        }
    }
}
```

### Audio Transcription

Enable input audio transcription:

```swift
func enableTranscription() async throws {
    await conversation.whenConnected {
        try await conversation.updateSession { session in
            session.inputAudioTranscription = Session.InputAudioTranscription(
                model: .whisper
            )
        }
    }
}
```

### Monitoring Voice State

```swift
// Check if user is speaking (server VAD)
if await conversation.isUserSpeaking {
    print("User is currently speaking")
}

// Check if model is playing audio
if await conversation.isPlaying {
    print("Model is currently speaking")
}

// Check if actively listening to microphone
if await conversation.isListening {
    print("Listening to microphone")
}
```

### Manual Audio Handling

For custom audio handling:

```swift
func sendCustomAudio(_ audioData: Data) async throws {
    // Send audio data manually
    try await conversation.send(audioDelta: audioData, commit: false)

    // Commit to trigger model response
    try await conversation.send(audioDelta: Data(), commit: true)
}
```

## SwiftUI Integration

### Basic Chat Interface

```swift
import SwiftUI
import OpenAIRealtime

struct ChatView: View {
    @State private var conversation: Conversation?
    @State private var messageText = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                // Messages list
                if let conversation = conversation {
                    MessagesList(conversation: conversation)
                } else {
                    Text("Not connected")
                        .foregroundColor(.secondary)
                }

                // Input area
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Send") {
                        Task { await sendMessage() }
                    }
                    .disabled(messageText.isEmpty || conversation == nil)
                }
                .padding()
            }
            .navigationTitle("OpenAI Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(conversation == nil ? "Connect" : "Disconnect") {
                        Task { await toggleConnection() }
                    }
                    .disabled(isConnecting)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func toggleConnection() async {
        if conversation != nil {
            conversation = nil
        } else {
            await connect()
        }
    }

    @MainActor
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }

        do {
            conversation = Conversation(
                authToken: "your-api-key",
                model: "gpt-4o-realtime-preview"
            )

            await conversation?.waitForConnection()

            // Configure session
            await conversation?.whenConnected {
                try await conversation?.updateSession { session in
                    session.instructions = "You are a helpful assistant."
                }
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func sendMessage() async {
        guard let conversation = conversation, !messageText.isEmpty else { return }

        let text = messageText
        messageText = ""

        do {
            try await conversation.send(from: .user, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MessagesList: View {
    let conversation: Conversation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: conversation.messages.count) {
                if let lastMessage = conversation.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Item.Message

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.role.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(message.content.first?.text ?? "")
                    .padding(12)
                    .background(
                        message.role == .user ? Color.blue : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(
                        message.role == .user ? .white : .primary
                    )
                    .cornerRadius(16)
            }

            if message.role != .user {
                Spacer()
            }
        }
    }
}
```

### Voice Chat Interface

```swift
struct VoiceChatView: View {
    @State private var conversation: Conversation?
    @State private var voiceManager: VoiceManager?
    @State private var isListening = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            // Connection status
            if let conversation = conversation {
                HStack {
                    Circle()
                        .fill(conversation.connected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(conversation.connected ? "Connected" : "Disconnected")
                    Spacer()
                }
                .padding()

                // Voice status indicators
                VStack(spacing: 16) {
                    HStack {
                        Text("User Speaking:")
                        Circle()
                            .fill(conversation.isUserSpeaking ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }

                    HStack {
                        Text("Assistant Speaking:")
                        Circle()
                            .fill(conversation.isPlaying ? Color.blue : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding()

                // Messages
                MessagesList(conversation: conversation)

                // Voice controls
                VStack {
                    Button(action: toggleListening) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 32))
                            .foregroundColor(isListening ? .red : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(isListening ? "Listening..." : "Tap to speak")
                        .font(.caption)
                }
                .padding()
            } else {
                Text("Not connected")

                Button("Connect with Voice") {
                    Task { await connectWithVoice() }
                }
                .padding()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @MainActor
    private func connectWithVoice() async {
        do {
            conversation = Conversation(
                authToken: "your-api-key",
                model: "gpt-4o-realtime-preview"
            )

            await conversation?.waitForConnection()

            // Configure for voice
            await conversation?.whenConnected {
                try await conversation?.updateSession { session in
                    session.modalities = [.text, .audio]
                    session.voice = .alloy
                    session.turnDetection = .serverVad()
                    session.instructions = "You are a helpful voice assistant. Keep responses concise and natural."
                }
            }

            if let conversation = conversation {
                voiceManager = VoiceManager(conversation: conversation)
                try voiceManager?.startVoiceConversation()
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func toggleListening() {
        guard let voiceManager = voiceManager else { return }

        do {
            try voiceManager.toggleListening()
            isListening = conversation?.isListening ?? false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

## Advanced Configuration

### Session Configuration

```swift
func configureAdvancedSession() async throws {
    await conversation.whenConnected {
        try await conversation.updateSession { session in
            // Model configuration
            session.model = "gpt-4o-realtime-preview"
            session.temperature = 0.7
            session.maxOutputTokens = 4096

            // System instructions
            session.instructions = """
                You are an AI assistant that specializes in technical questions.
                Keep responses accurate and concise. Use examples when helpful.
            """

            // Voice configuration
            session.voice = .nova
            session.modalities = [.text, .audio]

            // Audio formats
            session.inputAudioFormat = .pcm16
            session.outputAudioFormat = .pcm16

            // Turn detection
            session.turnDetection = Session.TurnDetection.semanticVad(
                eagerness: .medium
            )

            // Function calling
            session.toolChoice = .required
            session.tools = [weatherFunction, calculatorFunction]
        }
    }
}
```

### Response Configuration

```swift
// Custom response configuration
let responseConfig = Response.Config(
    modalities: [.text],
    temperature: 0.8,
    maxOutputTokens: 1000
)

try await conversation.send(
    from: .user,
    text: "Explain quantum computing",
    response: responseConfig
)
```

### Audio Noise Reduction

```swift
func configureNoiseReduction() async throws {
    await conversation.whenConnected {
        try await conversation.updateSession { session in
            session.inputAudioNoiseReduction = Session.InputAudioNoiseReduction(
                type: .nearField  // or .farField for conference room mics
            )
        }
    }
}
```

## Error Handling

### Comprehensive Error Handling

```swift
class RobustConversationManager: ObservableObject {
    @Published var conversation: Conversation?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: ConversationError?

    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
    }

    func connect() async {
        connectionState = .connecting

        do {
            conversation = Conversation(
                authToken: "your-api-key",
                model: "gpt-4o-realtime-preview"
            )

            // Monitor errors
            Task {
                guard let conversation = conversation else { return }
                for await error in conversation.errors {
                    await handleError(error)
                }
            }

            await conversation?.waitForConnection()
            connectionState = .connected

        } catch {
            lastError = error as? ConversationError
            connectionState = .disconnected
        }
    }

    @MainActor
    private func handleError(_ error: ServerError) async {
        switch error.type {
        case "rate_limit_exceeded":
            // Handle rate limiting
            if let retryAfter = error.retryAfter {
                print("Rate limited. Retrying after \(retryAfter) seconds")
                try? await Task.sleep(for: .seconds(retryAfter))
                await reconnect()
            }

        case "session_expired":
            // Handle session expiration
            await reconnect()

        case "connection_error":
            // Handle connection issues
            connectionState = .reconnecting
            await reconnect()

        default:
            print("Unhandled error: \(error)")
            lastError = .invalidResponse(error.message ?? "Unknown error")
        }
    }

    @MainActor
    private func reconnect() async {
        connectionState = .reconnecting
        conversation = nil

        // Wait before reconnecting
        try? await Task.sleep(for: .seconds(2))

        await connect()
    }

    func sendMessageSafely(text: String) async -> Bool {
        guard let conversation = conversation else { return false }

        do {
            try await conversation.send(from: .user, text: text)
            return true
        } catch let error as ConversationError {
            lastError = error
            return false
        } catch {
            lastError = .streamingError(error)
            return false
        }
    }
}
```

### Error Types and Recovery

```swift
func handleSpecificErrors(_ error: ConversationError) {
    switch error {
    case .sessionNotFound:
        // Create a new session
        print("Session not found - creating new session")

    case .converterInitializationFailed:
        // Check audio permissions and format
        print("Audio converter failed - check permissions")

    case .connectionLost(let underlyingError):
        // Attempt reconnection
        print("Connection lost: \(underlyingError)")

    case .authenticationFailed:
        // Check API key
        print("Authentication failed - verify API key")

    case .rateLimitExceeded(let retryAfter):
        // Wait and retry
        if let retryAfter = retryAfter {
            print("Rate limited - retry after \(retryAfter)s")
        }

    case .audioProcessingError(let error):
        // Handle audio issues
        print("Audio error: \(error)")

    case .networkUnavailable:
        // Check network connectivity
        print("Network unavailable")

    default:
        print("Other error: \(error.localizedDescription)")
    }
}
```

## Best Practices

1. **Always handle connection state**: Monitor the `connected` property and error stream
2. **Use `whenConnected`**: Ensure operations happen after connection is established
3. **Handle audio permissions**: Request microphone access before starting voice features
4. **Implement retry logic**: Handle rate limits and network issues gracefully
5. **Clean up resources**: Properly dispose of conversation instances to avoid memory leaks
6. **Monitor function calls**: Actively check for and respond to function call requests
7. **Configure sessions appropriately**: Set up proper instructions and parameters for your use case

## Troubleshooting

### Common Issues

- **Authentication fails**: Verify your API key is correct and has Realtime API access
- **Audio not working**: Check microphone permissions and audio session configuration
- **Connection drops**: Implement retry logic and monitor network connectivity
- **Function calls not working**: Ensure tools are properly registered in the session
- **High latency**: Consider using WebRTC connection for better performance

For more detailed information, refer to the OpenAI Realtime API documentation and the library source code.