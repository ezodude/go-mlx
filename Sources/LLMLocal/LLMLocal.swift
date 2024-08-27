import Foundation
import LLM
import MLX
import MLXRandom
import Tokenizers

public struct LLMLocal {
    public struct Configuration {
        public var model: String
        public var maxTokens: Int
        public var temperature: Float
        public var topP: Float
        public var repetitionPenalty: Float?
        public var repetitionContextSize: Int
        public var seed: UInt64
        public var quiet: Bool
        public var memoryStats: Bool
        public var cacheSize: Int?
        public var memorySize: Int?

        public init(
            model: String = "mlx-community/Mistral-7B-v0.1-hf-4bit-mlx",
            maxTokens: Int = 100,
            temperature: Float = 0.6,
            topP: Float = 1.0,
            repetitionPenalty: Float? = nil,
            repetitionContextSize: Int = 20,
            seed: UInt64 = 0,
            quiet: Bool = false,
            memoryStats: Bool = false,
            cacheSize: Int? = nil,
            memorySize: Int? = nil
        ) {
            self.model = model
            self.maxTokens = maxTokens
            self.temperature = temperature
            self.topP = topP
            self.repetitionPenalty = repetitionPenalty
            self.repetitionContextSize = repetitionContextSize
            self.seed = seed
            self.quiet = quiet
            self.memoryStats = memoryStats
            self.cacheSize = cacheSize
            self.memorySize = memorySize
        }
    }

    private let configuration: Configuration
    private var modelContainer: ModelContainer?
    private var modelConfiguration: ModelConfiguration?
    private var startMemory: GPU.Snapshot?

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public mutating func loadModel() async throws -> (ModelContainer, ModelConfiguration) {
        if let cacheSize = configuration.cacheSize {
            GPU.set(cacheLimit: cacheSize * 1024 * 1024)
        }

        if let memorySize = configuration.memorySize {
            GPU.set(memoryLimit: memorySize * 1024 * 1024)
        }

        let modelConfiguration: ModelConfiguration

        if configuration.model.hasPrefix("/") {
            modelConfiguration = ModelConfiguration(directory: URL(filePath: configuration.model))
        } else {
            modelConfiguration = await ModelConfiguration.configuration(id: configuration.model)
        }

        let modelContainer = try await LLM.loadModelContainer(configuration: modelConfiguration)
        self.modelContainer = modelContainer
        self.modelConfiguration = modelConfiguration
        self.startMemory = GPU.snapshot()

        return (modelContainer, modelConfiguration)
    }

    public func generateText(prompt: String) async throws -> String {
        guard let modelContainer = modelContainer, let modelConfiguration = modelConfiguration else {
            throw LLMLocalError.modelNotLoaded
        }

        let generateParameters = GenerateParameters(
            temperature: configuration.temperature,
            topP: configuration.topP,
            repetitionPenalty: configuration.repetitionPenalty,
            repetitionContextSize: configuration.repetitionContextSize
        )

        MLXRandom.seed(configuration.seed)

        let preparedPrompt = modelConfiguration.prepare(prompt: prompt)
        let promptTokens = await modelContainer.perform { _, tokenizer in
            tokenizer.encode(text: preparedPrompt)
        }

        if !configuration.quiet {
            print("Starting generation ...")
            print(preparedPrompt, terminator: "")
        }

        let result = await modelContainer.perform { [configuration] model, tokenizer in
            LLM.generate(
                promptTokens: promptTokens,
                parameters: generateParameters,
                model: model,
                tokenizer: tokenizer,
                extraEOSTokens: modelConfiguration.extraEOSTokens
            ) { tokens in
                let fullOutput = tokenizer.decode(tokens: tokens)

                if !configuration.quiet {
                    print(fullOutput, terminator: "")
                    fflush(stdout)
                }

                if tokens.count >= configuration.maxTokens {
                    return .stop
                } else {
                    return .more
                }
            }
        }

        let generatedText = await modelContainer.perform { _, tokenizer in
            tokenizer.decode(tokens: result.tokens)
        }

        if !configuration.quiet {
            print("\n------")
            print(result.summary())
        }

        reportMemoryStatistics()

        return generatedText
    }

    private func reportMemoryStatistics() {
        if configuration.memoryStats, let startMemory = startMemory {
            let endMemory = GPU.snapshot()

            print("=======")
            print("Memory size: \(GPU.memoryLimit / 1024)K")
            print("Cache size:  \(GPU.cacheLimit / 1024)K")

            print("\n=======")
            print("Starting memory")
            print(startMemory.description)

            print("\n=======")
            print("Ending memory")
            print(endMemory.description)

            print("\n=======")
            print("Growth")
            print(startMemory.delta(endMemory).description)
        }
    }
}

public enum LLMLocalError: Error {
    case modelNotLoaded
}
