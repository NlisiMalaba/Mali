.PHONY: run test build-apk build-ipa gen

FLUTTER ?= flutter
BUILD_RUNNER ?= dart run build_runner build --delete-conflicting-outputs

run:
	$(FLUTTER) run

test:
	$(FLUTTER) test

build-apk:
	$(FLUTTER) build apk

build-ipa:
	$(FLUTTER) build ipa

gen:
	$(BUILD_RUNNER)

