.PHONY: build install clean test

# Binary name
BINARY_NAME=scriptctl
INSTALL_PATH=$(HOME)/.local/bin

# Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@go build -o $(BINARY_NAME) ./cmd/scriptctl
	@echo "Build complete: ./$(BINARY_NAME)"

# Install the binary to ~/.local/bin
install: build
	@echo "Installing $(BINARY_NAME) to $(INSTALL_PATH)..."
	@mkdir -p $(INSTALL_PATH)
	@cp $(BINARY_NAME) $(INSTALL_PATH)/
	@echo "Installation complete!"
	@echo ""
	@echo "Make sure $(INSTALL_PATH) is in your PATH:"
	@echo "  export PATH=\"\$$HOME/.local/bin:\$$PATH\""
	@echo ""
	@echo "Then you can run: scriptctl list"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -f $(BINARY_NAME)
	@echo "Clean complete"

# Run tests
test:
	@echo "Running tests..."
	@go test ./...

# Run with example
run-example: build
	@echo "Running example..."
	@./$(BINARY_NAME) list
