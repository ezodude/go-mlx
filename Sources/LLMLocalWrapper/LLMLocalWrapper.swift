import Foundation
import LLMLocal

class LLMLocalWrapper : @unchecked Sendable {
    private var llmLocal: LLMLocal

    init(configuration: LLMLocal.Configuration) {
        self.llmLocal = LLMLocal(configuration: configuration)
    }

    func loadModel() async throws {
        _ = try await llmLocal.loadModel()
    }

    func generateText(prompt: String) async throws -> String {
        return try await llmLocal.generateText(prompt: prompt)
    }
}

@_cdecl("initialize_llm")
public func initialize_llm() -> UnsafeMutableRawPointer {
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
        cacheSize: 4096,
        memorySize: 8192
    )
    let wrapper = LLMLocalWrapper(configuration: configuration)
    return Unmanaged.passRetained(wrapper).toOpaque()
}

@_cdecl("load_model")
public func load_model(_ wrapperPointer: UnsafeMutableRawPointer) -> Bool {
    let wrapper = Unmanaged<LLMLocalWrapper>.fromOpaque(wrapperPointer).takeUnretainedValue()
    let semaphore = DispatchSemaphore(value: 0)
    let resultPointer = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
    resultPointer.initialize(to: false)

    Task {
        do {
            try await wrapper.loadModel()
            resultPointer.pointee = true
        } catch {
            print("Error loading model: \(error)")
        }
        semaphore.signal()
    }

    semaphore.wait()
    let success = resultPointer.pointee
    resultPointer.deallocate()
    return success
}

@_cdecl("generate_text")
public func generate_text(_ wrapperPointer: UnsafeMutableRawPointer, _ prompt: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    let wrapper = Unmanaged<LLMLocalWrapper>.fromOpaque(wrapperPointer).takeUnretainedValue()
    let swiftPrompt = String(cString: prompt)
    let semaphore = DispatchSemaphore(value: 0)
    let resultPointer = UnsafeMutablePointer<Optional<String>>.allocate(capacity: 1)
    resultPointer.initialize(to: nil)

    Task {
        do {
            let generatedText = try await wrapper.generateText(prompt: swiftPrompt)
            resultPointer.pointee = generatedText
        } catch {
            print("An error occurred: \(error)")
        }
        semaphore.signal()
    }

    semaphore.wait()
    let result = resultPointer.pointee
    resultPointer.deallocate()
    return result.map { strdup($0) }
}

@_cdecl("free_llm")
public func free_llm(_ wrapperPointer: UnsafeMutableRawPointer) {
    Unmanaged<LLMLocalWrapper>.fromOpaque(wrapperPointer).release()
}

@_cdecl("free_text")
public func free_text(_ text: UnsafeMutablePointer<CChar>?) {
    if let text = text {
        free(text)
    }
}
