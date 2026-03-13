DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
SCHEME ?= CashbackCopilot
DESTINATION ?= platform=iOS Simulator,name=iPhone 16

.PHONY: generate build test lint

generate:
	DEVELOPER_DIR=$(DEVELOPER_DIR) xcodegen generate

build:
	DEVELOPER_DIR=$(DEVELOPER_DIR) xcodebuild \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		build \
		CODE_SIGNING_ALLOWED=NO

test:
	DEVELOPER_DIR=$(DEVELOPER_DIR) xcodebuild \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		test \
		CODE_SIGNING_ALLOWED=NO

lint:
	swiftlint

