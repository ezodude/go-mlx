// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "llm-local",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        .library(name: "LLMLocal", targets: ["LLMLocal"]),
        .library(name: "LLMLocalWrapper", type: .dynamic, targets: ["LLMLocalWrapper"]),
        .executable(name: "LLMLocalExample", targets: ["LLMLocalExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.16.1"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.9"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "LLM",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "MLXFast", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Transformers", package: "swift-transformers")
            ],
            path: "Libraries/LLM",
            exclude: ["README.md", "LLM.h"]
        ),
        .target(
            name: "LLMLocal",
            dependencies: [
                "LLM",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/LLMLocal"
        ),
        .target(
	        name: "LLMLocalWrapper",
	        dependencies: ["LLMLocal"],
	        path: "Sources/LLMLocalWrapper",
	        swiftSettings: [
	          .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
	        ]
        ),
        .executableTarget(
            name: "LLMLocalExample",
            dependencies: ["LLMLocal"],
            path: "Sources/LLMLocalExample"
        )
    ]
)
