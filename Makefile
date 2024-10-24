NAME=bruin
BUILD_DIR ?= bin
BUILD_SRC=.
CURDIR=$(shell pwd)
NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m

.PHONY: all clean test build tools format pre-commit tools-update
all: clean deps test build

deps: tools
	@printf "$(OK_COLOR)==> Installing dependencies$(NO_COLOR)\n"
	@go mod tidy

build: build-darwin build-linux build-windows

build-darwin: build-darwin-amd build-darwin-arm

build-darwin-amd:
	@echo "$(OK_COLOR)==> Building the application for Darwin...$(NO_COLOR)"
	docker run -it --rm -e VERSION=0.0.1  -v $(CURDIR):/src -w /src goreleaser/goreleaser-cross:v1.22 build --snapshot --clean  --id  bruin-darwin-amd --output /src/bin  --verbose
	cp dist/bruin-darwin-amd_darwin_amd64_v1/bruin bin/bruin

build-darwin-arm:
	@echo "$(OK_COLOR)==> Building the application for Darwin...$(NO_COLOR)"
	docker run -it --rm -e VERSION=0.0.1  -v $(CURDIR):/src -w /src goreleaser/goreleaser-cross:v1.22 build --snapshot --clean  --id  bruin-darwin-arm --output /src/bin  --verbose
	cp dist/bruin-darwin-arm_darwin_arm64_v1/bruin bruin


build-linux: build-linux-amd build-linux-arm

build-linux-amd:
	@echo "$(OK_COLOR)==> Building the application for Linux...$(NO_COLOR)"
	@docker run -it --rm -e VERSION=0.0.1  -v $(CURDIR):/src goreleaser/goreleaser-cross:v1.22 build  --snapshot --clean  --id  bruin-linux-amd64 --output /src/bin  --verbose
	cp dist/bruin-linux-amd_linux_amd64_v1/bruin bruin

build-linux-arm:
	@echo "$(OK_COLOR)==> Building the application for Linux...$(NO_COLOR)"
	@docker run -it --rm -e VERSION=0.0.1  -v $(CURDIR):/src goreleaser/goreleaser-cross:v1.22 build  --snapshot --clean  --id  bruin-linux-arm64 --output /src/bin  --verbose
	cp dist/bruin-linux-arm_linux_arm64/bruin bruin

build-windows:
	@echo "$(OK_COLOR)==> Building the application for Windows...$(NO_COLOR)"
	@docker run -it --rm -e VERSION=0.0.1  -v $(CURDIR):/src goreleaser/goreleaser-cross:v1.22 build  --snapshot --clean  --id  bruin-windows-amd64 --output /src/bin  --verbose
	cp dist/bruin-windows-amd_windows_amd64_v1/bruin bruin

goreleaser:
	@echo "$(OK_COLOR)==> Building the application for Windows...$(NO_COLOR)"
	@docker run -it --rm -e VERSION=0.0.1  -v $(CURDIR):/src goreleaser/goreleaser-cross:v1.22 release  --snapshot --clean 


clean:
	@rm -rf ./bin

test: test-unit

test-unit:
	@echo "$(OK_COLOR)==> Running the unit tests$(NO_COLOR)"
	@go test -race -cover -timeout 60s ./...

format: tools
	@echo "$(OK_COLOR)>> [go vet] running$(NO_COLOR)" & \
	go vet ./... &

	@echo "$(OK_COLOR)>> [gci] running$(NO_COLOR)" & \
	gci write cmd pkg main.go &

	@echo "$(OK_COLOR)>> [gofumpt] running$(NO_COLOR)" & \
	gofumpt -w cmd pkg &

	@echo "$(OK_COLOR)>> [golangci-lint] running$(NO_COLOR)" & \
	golangci-lint run & \
	wait

tools:
	@if ! command -v gci > /dev/null ; then \
		echo ">> [$@]: gci not found: installing"; \
		go install github.com/daixiang0/gci@latest; \
	fi

	@if ! command -v gofumpt > /dev/null ; then \
		echo ">> [$@]: gofumpt not found: installing"; \
		go install mvdan.cc/gofumpt@latest; \
	fi

	@if ! command -v golangci-lint > /dev/null ; then \
		echo ">> [$@]: golangci-lint not found: installing"; \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest; \
	fi

	@if ! command -v goreleaser > /dev/null ; then \
		echo ">> [$@]: goreleaser not found: installing"; \
		go install github.com/goreleaser/goreleaser/v2@latest; \
	fi

tools-update:
	go install github.com/daixiang0/gci@latest; \
	go install mvdan.cc/gofumpt@latest; \
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest;
	go install github.com/goreleaser/goreleaser/v2@latest
