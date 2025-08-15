# Cross-Platform Package Testing with Flox

This document describes how to use the included Makefile system to test packages across different platforms using Flox environments. The testing framework is modular, with package-specific tests in separate files.

## Prerequisites

- [Flox](https://flox.dev) installed and configured
- [Podman](https://podman.io) or [Docker](https://docker.com) for Linux container testing
- [Nix](https://nixos.org) with flakes enabled

## Quick Start

```bash
# Test all packages on all platforms
make test-all

# Test elasticsearch8 specifically
make elasticsearch8-test-all

# Test only on current Darwin system
make test-darwin  # or elasticsearch8-test-darwin

# Test only in Linux container
make test-linux   # or elasticsearch8-test-linux

# Check dependencies
make check-deps

# View all available commands
make help
```

## Available Commands

### Generic Commands

- **`make test-all`** - Run all package tests (currently elasticsearch8)
- **`make test-darwin`** - Alias for elasticsearch8 Darwin test
- **`make test-linux`** - Alias for elasticsearch8 Linux test
- **`make check-deps`** - Verify required dependencies are installed
- **`make setup-test-env`** - Create test directory structure
- **`make clean`** - Clean up all test environments
- **`make help`** - Show categorized help with all commands

### Elasticsearch8-Specific Commands

- **`make elasticsearch8-test-all`** - Test elasticsearch8 on Darwin, Linux ARM64, and verify x86_64 configuration
- **`make elasticsearch8-test-darwin`** - Test elasticsearch8 in Flox environment on Darwin
- **`make elasticsearch8-test-linux`** - Test elasticsearch8 in Linux ARM64 container environment
- **`make elasticsearch8-test-x86_64-config`** - Verify x86_64 Linux configuration without emulation
- **`make elasticsearch8-test-linux-x86_64`** - Test elasticsearch8 in x86_64 Linux container (experimental)
- **`make elasticsearch8-validate`** - Validate elasticsearch8 package integrity across platforms
- **`make elasticsearch8-clean`** - Clean up elasticsearch8 test environments
- **`make elasticsearch8-info`** - Show elasticsearch8 package information and status

### Utility Commands

- **`make check-deps`** - Verify required dependencies are installed
- **`make setup-test-env`** - Create test directory structure
- **`make validate-package`** - Validate package integrity and consistency
- **`make benchmark`** - Run build time performance benchmarks
- **`make clean`** - Remove all test environments and artifacts

### Development & Debugging

- **`make debug-darwin`** - Debug Darwin environment setup issues
- **`make debug-info`** - Show system and dependency information
- **`make dev-setup`** - Set up development environment
- **`make ci-test`** - Run tests suitable for CI environments

## How It Works

### Darwin Testing (`make test-darwin`)

1. Creates a new Flox environment in `tests/darwin-test/`
2. Installs elasticsearch8 from the local flake
3. Tests version command and binary availability
4. Validates proper Flox integration

### Linux Testing (`make test-linux`)

1. Uses Podman/Docker to run a NixOS ARM64 container
2. Builds the elasticsearch8 package inside the container
3. Tests binary availability and PATH integration
4. Simulates Flox-like environment activation

### x86_64 Configuration Testing (`make test-x86_64-config`)

1. Verifies x86_64-linux hash exists in configuration
2. Validates hash format (SHA512)
3. Confirms URL construction supports x86_64 architecture
4. No emulation required - pure configuration validation

### x86_64 Container Testing (`make test-linux-x86_64`) - Experimental

1. Attempts to run x86_64 Linux container with emulation
2. May have limitations on ARM64 hosts due to emulation constraints
3. Falls back to configuration verification if build fails
4. Useful for testing actual x86_64 builds when possible

### Package Validation

The validation process checks:
- ✅ Correct Elasticsearch version (8.17.3)
- ✅ All expected binaries are present
- ✅ Proper integration with Flox environments
- ✅ Cross-platform compatibility

## Test Output

All tests provide colored output:
- 🔵 **Blue**: Informational messages
- 🟡 **Yellow**: Progress indicators
- 🟢 **Green**: Success indicators
- 🔴 **Red**: Error messages

Example successful output:
```
✓ Dependencies check passed
✓ Package installed successfully
✓ Version check passed
✓ Darwin test completed successfully!
✓ Linux test passed
✓ All platform tests completed!
```

## Troubleshooting

### Common Issues

**Flox not found:**
```bash
make check-deps
# Install Flox from https://flox.dev
```

**Container runtime not found:**
```bash
# Install Podman or Docker
brew install podman  # macOS
```

**Permission issues with containers:**
```bash
# For Podman on macOS
podman machine init
podman machine start
```

### Debug Commands

Get system information:
```bash
make debug-info
```

Debug Darwin environment:
```bash
make debug-darwin
```

Clean and retry:
```bash
make clean
make test-all
```

## CI Integration

For continuous integration environments:

```bash
make ci-test
```

This command:
- Runs Darwin tests only on macOS systems
- Always runs Linux container tests
- Provides non-interactive output suitable for CI

## File Structure

```
tests/
├── elasticsearch8.mk                    # Elasticsearch8-specific test targets
├── elasticsearch8-darwin-test/          # Darwin Flox environment for elasticsearch8
│   ├── .flox/
│   │   ├── env.json
│   │   └── env/
│   │       └── manifest.toml
└── elasticsearch8-linux-test/           # Linux test artifacts (if needed)
```

The testing framework is modular:
- **`Makefile`** - Generic infrastructure and convenience aliases
- **`tests/elasticsearch8.mk`** - All elasticsearch8-specific testing logic
- **`tests/`** - Test environments and artifacts

## Performance Notes

- **Darwin tests**: ~30-60 seconds (depends on Flox environment setup)
- **Linux tests**: ~60-90 seconds (includes container startup and Nix build)
- **Full test suite**: ~90-150 seconds total

## Integration with Development Workflow

### Before committing changes:
```bash
make test-all
```

### During development:
```bash
make test-darwin  # Quick local test
```

### For release validation:
```bash
make validate-package
make benchmark
```

This testing framework ensures that the elasticsearch8 package works correctly across platforms and integrates properly with Flox environments.
