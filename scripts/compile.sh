#!/bin/bash
set -e

rm -rf .build
swift package update
swift build

# build the LLMLocalExample executable
xcodebuild \
  -skipPackagePluginValidation \
  -scheme LLMLocalExample \
  -destination 'platform=macOS,arch=arm64,id=00006000-001844D21A89801E,name=My Mac' \
  -configuration Release \
  build

# build the LLMLocal dynamic library
RELEASE_BUILD="$(pwd)/.build/release"

mkdir -p "${RELEASE_BUILD}"
xcodebuild \
  -skipPackagePluginValidation \
  -scheme LLMLocalWrapper \
  -destination 'platform=macOS,arch=arm64,id=00006000-001844D21A89801E,name=My Mac' \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="${RELEASE_BUILD}" \
  build \
  -verbose

export DYLD_FRAMEWORK_PATH=/full/path/to/PackageFrameworks
export DYLD_LIBRARY_PATH=/full/path/to/PackageFrameworks

# having issues with this
#./llm-local
#libc++abi: terminating due to uncaught exception of type std::runtime_error: library not found
#Failed to load device library from <default.metallib> or </path/to/PackageFrameworks/LLMLocalWrapper.framework/Versions/A/mlx.metallib>.
#zsh: abort      ./llm-local
