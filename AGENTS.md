# Agent Guidelines for stable-diffusion.cpp

This document provides guidelines for AI agents working on the stable-diffusion.cpp codebase.

## Project Overview

stable-diffusion.cpp is a pure C/C++ implementation of diffusion models (SD, Flux, Wan, etc.) based on [ggml](https://github.com/ggml-org/ggml), similar to how llama.cpp works.

## Build Commands

### Basic Build (CPU only)
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

### Build with GPU Backend
```bash
# CUDA
mkdir build && cd build
cmake .. -DSD_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Metal (macOS)
cmake .. -DSD_METAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Vulkan
cmake .. -DSD_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# HIPBLAS (AMD GPU)
cmake .. -DSD_HIPBLAS=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# OpenCL
cmake .. -DSD_OPENCL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# SYCL (Intel GPU)
cmake .. -DSD_SYCL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

### Build Options
- `-DGGML_AVX2=ON` - Enable AVX2 optimizations
- `-DSD_BUILD_SHARED_LIBS=ON` - Build shared library
- `-DSD_BUILD_EXAMPLES=ON` - Build examples (default: ON)

### Running the CLI
```bash
./bin/sd-cli -m <model_path> -p "prompt"
```

### Testing Individual Features
The project uses integration testing via the CLI. Test specific features by:
1. Building with appropriate backend flags
2. Running the CLI with specific parameters
3. Checking output images for correctness

No unit test framework is currently integrated. The ggml library has tests in `ggml/tests/`.

## Code Style Guidelines

### Formatting
- **Format Tool**: Uses `.clang-format` based on Chromium style
- **Indentation**: 4 spaces (no tabs)
- **Column Limit**: 0 (unlimited line length)
- **Access Modifier Offset**: -4
- **Namespace Indentation**: All namespaces indented

Apply formatting with:
```bash
clang-format -i <file>
```

### Language Standards
- **C**: C11 (`-std=c11`)
- **C++**: C++17 (`-std=c++17`)

### File Organization
- **Public headers**: `include/stable-diffusion.h`
- **Source files**: `src/*.cpp`, `src/*.hpp`
- **Examples**: `examples/cli/main.cpp`, `examples/server/`
- **ggml submodule**: `ggml/` (do not modify directly, submit PRs to ggml)

### Naming Conventions
- **Types/Classes**: `CamelCase` (e.g., `SDContext`, `DiffusionModel`)
- **Functions**: `snake_case` (e.g., `sd_generate`, `load_model_weights`)
- **Variables**: `snake_case` (e.g., `output_path`, `num_threads`)
- **Constants/Enums**: `SCREAMING_SNAKE_CASE` (e.g., `SD_TYPE_F16`, `EULER_SAMPLE_METHOD`)
- **Private members**: Often prefixed with underscore (e.g., `_context`, `_model`)

### Include Order
1. Corresponding header (for .cpp files)
2. Project headers (`"model.h"`, `"stable-diffusion.h"`)
3. ggml headers (`"ggml.h"`, `"ggml-extend.hpp"`)
4. Third-party headers
5. Standard library headers

```cpp
#include "ggml_extend.hpp"
#include "model.h"
#include "rng.hpp"
#include "stable-diffusion.h"
#include "util.h"
#include "auto_encoder_kl.hpp"
#include "conditioner.hpp"
#include <vector>
#include <string>
```

### Error Handling
- Use structured error codes from `stable-diffusion.h` enums
- Log errors with appropriate levels: `LOG_DEBUG`, `LOG_INFO`, `LOG_WARN`, `LOG_ERROR`
- Throw `std::runtime_error` for exceptional/unrecoverable errors
- Return `nullptr` or error codes for function failures that can be handled by caller

```cpp
if (!model_loaded) {
    LOG_ERROR("Failed to load model from %s", model_path);
    return nullptr;
}
```

### Logging
Use the built-in logging system:
- `LOG_DEBUG` - Detailed debugging info
- `LOG_INFO` - General information
- `LOG_WARN` - Warning messages
- `LOG_ERROR` - Error messages

### Memory Management
- Use smart pointers where appropriate (`std::unique_ptr`, `std::shared_ptr`)
- Follow ggml's memory allocation patterns (ggml_tensor, ggml_alloc)
- Free resources in destructors or explicit cleanup functions

### GPU Backend Patterns
When adding backend-specific code:
1. Use preprocessor guards: `#ifdef SD_USE_CUDA`, `#ifdef SD_USE_VULKAN`, etc.
2. Follow existing patterns in `src/` for each backend
3. Keep backend-specific code isolated in separate files when possible

### API Design (Public API)
- Use C ABI for public API in `include/stable-diffusion.h`
- Use `SD_API` macro for cross-platform DLL export/import
- Wrap C++ internals in implementation detail files

```c
#ifdef __cplusplus
extern "C" {
#endif

SD_API struct sd_ctx* sd_new_from_file(const char* model_path, const struct sd_params* params);

#ifdef __cplusplus
}
#endif
```

### Documentation
- Document public API functions in headers with parameter descriptions
- Add comments for complex algorithms or non-obvious logic
- Keep comments concise and meaningful

### Common Patterns

#### Initialize and cleanup:
```cpp
struct sd_ctx* ctx = sd_new_from_file(model_path, params);
if (ctx == nullptr) {
    // handle error
}
sd_free(ctx);
```

#### Iteration patterns:
```cpp
for (int i = 0; i < timesteps; i++) {
    // process
}
```

#### Error checking:
```cpp
if (!condition) {
    LOG_WARN("Warning message");
    return;
}
```

## Important Files

- `include/stable-diffusion.h` - Public C API
- `src/stable-diffusion.cpp` - Main implementation (~4000 lines)
- `src/model.h` - Model definitions
- `examples/cli/main.cpp` - CLI implementation
- `CMakeLists.txt` - Build configuration

## Testing Approach

1. **Build verification**: Ensure code compiles with various backends
2. **CLI testing**: Test features via the command-line interface
3. **Model compatibility**: Test with different model formats (GGUF, safetensors, ckpt)
4. **Backend testing**: Test CUDA, Metal, Vulkan, CPU backends separately

## CI/CD

The project uses GitHub Actions (see `.github/workflows/build.yml`):
- Builds on Ubuntu, macOS, Windows
- Tests with multiple backends (CUDA, Vulkan, ROCm, SYCL)
- Uses CMake with Ninja on Windows, standard make on Unix

## Contributing

1. Follow the existing code style (match surrounding code)
2. Use the clang-format configuration
3. Test with multiple backends when adding backend-specific code
4. Update documentation if adding new features
5. Ensure cross-platform compatibility (Windows, Linux, macOS)
