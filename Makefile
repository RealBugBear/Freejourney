DEVICE_ID   ?= 00008140-000671E10AEB001C
SIM_ID      := 4D038F07-94D0-4E0C-8794-74CE91566CAB
ANDROID_ID  := R3CT50V8JVM
ENTRY       := lib/main_development.dart
ENTRY_PROD  := lib/main_production.dart
IOS_DEVICE_TIMEOUT ?= 1
IOS_RUN_ARGS ?=
APP_VERSION := $(shell sed -n 's/^version: \([0-9.]*\)+.*/\1/p' pubspec.yaml)
BUILD_NUMBER ?= $(shell date +%Y%m%d%H%M)
ANDROID_BUILD_NUMBER ?= $(shell date +%Y%m%d%H)
ANDROID_DIST_FLAVOR ?= production
ANDROID_DIST_ENTRY ?= lib/main_$(ANDROID_DIST_FLAVOR).dart
ANDROID_DIST_GROUPS ?= testers
ANDROID_DIST_APP_ID ?= $(shell jq -r '.flutter.platforms.android.default.appId' firebase.json)
ANDROID_DIST_APK := build/app/outputs/flutter-apk/app-$(ANDROID_DIST_FLAVOR)-release.apk
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo local)
GIT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo local)

.PHONY: run run-sim run-android release testflight android-testers clean

# NOTE: Profile mode is the ONLY stable mode on physical iPhone with iOS 26.2.1 beta.
# Debug mode fails to establish the Xcode debug proxy.
# Release mode fails to establish the launch connection.
# Profile mode (AOT-compiled, minimal VM overhead) launches reliably.
# Make sure iPhone is UNLOCKED and screen is ON before running.

## [DEFAULT] Run on physical iPhone in profile mode
## Quits Xcode first — Xcode being open causes "Timed out waiting for workspace" errors.
run:
	@osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
	@sleep 1
	flutter run --profile --flavor development --device-timeout $(IOS_DEVICE_TIMEOUT) -d $(DEVICE_ID) -t $(ENTRY) $(IOS_RUN_ARGS)

## Run on iOS 26 simulator in debug mode
run-sim:
	flutter run -d $(SIM_ID) --flavor development -t $(ENTRY)

## Run on Samsung Android in debug mode (flavor=development required — ohne das wird der alte app-debug.apk installiert!)
run-android:
	flutter run -d $(ANDROID_ID) --flavor development -t $(ENTRY)

## Build release IPA for TestFlight / App Store
## After this completes, open Xcode → Window → Organizer → distribute the archive.
release:
	@osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
	@sleep 1
	flutter build ipa --flavor production -t $(ENTRY_PROD) --release
	@echo ""
	@echo "✅ Build complete."
	@echo "   Open Xcode Organizer to upload:"
	@echo "   open build/ios/archive/Runner.xcarchive"

## Build current production IPA for TestFlight and open it in Apple Transporter
## Override build number if needed: make testflight BUILD_NUMBER=2026051801
testflight:
	@osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
	@sleep 1
	flutter build ipa --flavor production -t $(ENTRY_PROD) --release --build-name=$(APP_VERSION) --build-number=$(BUILD_NUMBER) --export-options-plist=ios/ExportOptions.plist
	@echo ""
	@echo "Build complete."
	@echo "Version: $(APP_VERSION) ($(BUILD_NUMBER))"
	@echo "Opening IPA in Transporter..."
	open -a /Applications/Transporter.app build/ios/ipa/*.ipa

## Build Android release APK and send it to Firebase App Distribution testers
## Override group/app/flavor if needed:
## make android-testers ANDROID_DIST_GROUPS=testers ANDROID_DIST_APP_ID=... ANDROID_DIST_FLAVOR=staging
android-testers:
	flutter build apk --flavor $(ANDROID_DIST_FLAVOR) -t $(ANDROID_DIST_ENTRY) --release --build-name=$(APP_VERSION) --build-number=$(ANDROID_BUILD_NUMBER)
	firebase appdistribution:distribute $(ANDROID_DIST_APK) --app $(ANDROID_DIST_APP_ID) --groups "$(ANDROID_DIST_GROUPS)" --release-notes "Reflex Journey Android $(ANDROID_DIST_FLAVOR) $(APP_VERSION) ($(ANDROID_BUILD_NUMBER)) | Branch: $(GIT_BRANCH) | Commit: $(GIT_SHA)"
	@echo ""
	@echo "Android build sent to Firebase App Distribution."
	@echo "Flavor: $(ANDROID_DIST_FLAVOR)"
	@echo "Version: $(APP_VERSION) ($(ANDROID_BUILD_NUMBER))"
	@echo "Groups: $(ANDROID_DIST_GROUPS)"

## Clean build artifacts and reinstall packages
clean:
	flutter clean && flutter pub get
