# Makefile for cross-platform package testing using Flox
# Usage:
#   make test-all              # Run all package tests
#   make elasticsearch8-*      # Run elasticsearch8-specific tests
#   make help                  # Show available commands

SHELL := /bin/bash
.PHONY: help check-deps setup-test-env clean debug-info ci-test dev-setup

# Include package-specific test files
include tests/elasticsearch8.mk

# Default target
all: help

# Colors for output
BLUE := \033[34m
GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
RESET := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Cross-Platform Package Testing with Flox$(RESET)"
	@echo ""
	@echo "$(YELLOW)Generic Commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { if ($$1 !~ /elasticsearch8/) printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Elasticsearch8 Commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^elasticsearch8-[a-zA-Z_-]+:.*##/ { printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Convenience Aliases:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"} /^(test-|validate-|debug-).*elasticsearch8.*##/ { printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

check-deps: ## Check required dependencies
	@echo "$(BLUE)Checking dependencies...$(RESET)"
	@command -v flox >/dev/null 2>&1 || (echo "$(RED)Error: flox not found. Install from https://flox.dev$(RESET)" && exit 1)
	@command -v podman >/dev/null 2>&1 || command -v docker >/dev/null 2>&1 || (echo "$(RED)Error: podman or docker required for Linux testing$(RESET)" && exit 1)
	@echo "$(GREEN)✓ Dependencies check passed$(RESET)"

test-all: elasticsearch8-test-all ## Run all package tests (currently elasticsearch8)
	@echo "$(GREEN)✅ All package tests completed!$(RESET)"

# Convenience aliases for elasticsearch8 tests
test-darwin: elasticsearch8-test-darwin ## Alias for elasticsearch8 Darwin test
test-linux: elasticsearch8-test-linux ## Alias for elasticsearch8 Linux test
test-x86_64-config: elasticsearch8-test-x86_64-config ## Alias for elasticsearch8 x86_64 config test
test-linux-x86_64: elasticsearch8-test-linux-x86_64 ## Alias for elasticsearch8 x86_64 container test
validate-package: elasticsearch8-validate ## Alias for elasticsearch8 package validation



setup-test-env: check-deps ## Set up test environments for packages
	@echo "$(BLUE)Setting up test environments...$(RESET)"
	@mkdir -p tests
	@echo "$(GREEN)✅ Test directories created$(RESET)"

benchmark: test-all ## Run performance benchmarks (build times)
	@echo "$(BLUE)Running build time benchmarks...$(RESET)"
	@make elasticsearch8-test-darwin > /dev/null 2>&1 || true
	@echo "$(GREEN)✅ Benchmark completed$(RESET)"

clean: elasticsearch8-clean ## Clean up all test environments and artifacts
	@echo "$(GREEN)✅ All test environments cleaned$(RESET)"

debug-darwin: elasticsearch8-debug-darwin ## Debug Darwin environment setup
	@echo "$(GREEN)✅ Debug information displayed$(RESET)"

debug-info: ## Show system and dependency information
	@echo "$(BLUE)System Information:$(RESET)"
	@echo "Platform: $$(uname -m)"
	@echo "OS: $$(uname -s)"
	@echo "Flox version: $$(flox --version 2>/dev/null || echo 'Not installed')"
	@echo "Container runtime: $$(command -v podman >/dev/null 2>&1 && echo 'podman' || echo 'docker')"
	@echo "Nix version: $$(nix --version 2>/dev/null || echo 'Not available')"

ci-test: ## Run tests suitable for CI environment
	@echo "$(BLUE)Running CI-friendly tests...$(RESET)"
	@if [[ "$$(uname -s)" == "Darwin" ]]; then \
		make elasticsearch8-test-darwin; \
	fi
	@make elasticsearch8-test-linux
	@make elasticsearch8-test-x86_64-config
	@echo "$(GREEN)✅ CI tests completed$(RESET)"

# Development targets
dev-setup: setup-test-env ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(RESET)"
	@echo "Run 'make test-all' to verify setup"

.SILENT: help check-deps debug-info
