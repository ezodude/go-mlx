import Foundation
import LLMLocal

// Create a configuration
let configuration = LLMLocal.Configuration(
    model: "mlx-community/Phi-3-mini-4k-instruct-4bit",
    maxTokens: 2048,
    temperature: 0,
    topP: 0.9,
    repetitionPenalty: 1.1,
    repetitionContextSize: 64,
    seed: 42,
    quiet: true,
    memoryStats: true,
    cacheSize: 4096,  // 4GB cache
    memorySize: 8192  // 8GB memory limit
)


// Create an instance of LLMLocal
var llmLocal = LLMLocal(configuration: configuration)

print("Loading model...")
do {
    let (_, modelConfiguration) = try await llmLocal.loadModel()
    print("Model loaded successfully.")
    print("Model ID: \(modelConfiguration.id)")

    // Define a prompt
    let prompt = "<|user|>\nDescribe the best features of the Go programming language in a single 250 character tweet.<|end|>\n<|assistant|>"

    print("\nGenerating text for prompt: \"\(prompt)\"")
    print("------")

    // Generate text
    let generatedText = try await llmLocal.generateText(prompt: prompt)

    print("\nFull generated text:")
    print("------")
    print(generatedText)
    print("------")

    print("\nText generation complete.")
} catch {
    print("An error occurred: \(error)")
}
