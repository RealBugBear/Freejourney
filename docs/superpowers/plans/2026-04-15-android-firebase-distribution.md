# Android Firebase App Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Android app deployable for beta testing via Firebase App Distribution (staging) and Google Play Internal Testing (production), mirroring the iOS TestFlight workflow.

**Architecture:** Two-track distribution pipeline — staging flavor goes to Firebase App Distribution (fast, no store required, testers install APK directly), production flavor goes to Google Play Internal Testing track (store-based, mirrors TestFlight). CI is already wired in `.github/workflows/`; the main gaps are missing Android product flavors in Gradle, an unconfigured release keystore, and unset GitHub Secrets.

**Tech Stack:** Flutter 3.24.x, Gradle Kotlin DSL, GitHub Actions, Firebase App Distribution (`wzieba/Firebase-Distribution-Github-Action@v1`), Google Play (`r0adkll/upload-google-play@v1`), `keytool` (JDK), Firebase Console, Google Play Console.

---

## Current State — What's Broken

Before starting, understand what blocks the pipeline today:

| Problem | File | Effect |
|---|---|---|
| No `productFlavors` in Gradle | `android/app/build.gradle.kts` | `flutter build apk --flavor staging` fails immediately |
| Hardcoded app label | `android/app/src/main/AndroidManifest.xml` | Per-flavor app names silently ignored |
| Placeholder `key.properties` | `android/key.properties` | Local release builds unsigned; CI release signing impossible |
| Missing GitHub Secrets | Repository Settings → Secrets | Firebase and Play Store CI steps fail |
| No keystore-decode step in CI | `.github/workflows/deploy_staging.yml` + `deploy_production.yml` | Release-signed builds impossible in CI |

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `android/app/build.gradle.kts` | Modify | Add product flavors (development / staging / production) with app ID suffixes and per-flavor app names via `resValue` |
| `android/app/src/main/AndroidManifest.xml` | Modify | Change `android:label` from hardcoded string to `@string/app_name` |
| `android/key.properties` | Modify (local only, git-ignored) | Real keystore credentials for local + CI signing |
| `.github/workflows/deploy_staging.yml` | Modify | Add keystore-decode step before build so release signing works in CI |
| `.github/workflows/deploy_production.yml` | Modify | Add keystore-decode step before Android build |

**No new files required.** All infrastructure already exists.

---

## Phase 1: Firebase App Distribution (Staging = TestFlight Equivalent)

---

### Task 1: Add product flavors to `android/app/build.gradle.kts`

**Files:**
- Modify: `android/app/build.gradle.kts`

The CI workflows call `flutter build apk --flavor staging` and `--flavor production` but Gradle has no `productFlavors` block. These commands will error with `Flavor 'staging' not found` until this is fixed.

- [ ] **Step 1: Open the file and read the current `android {}` block**

  Read `android/app/build.gradle.kts`. The current `android {}` block ends after `buildTypes {}`. You will insert the new `flavorDimensions` and `productFlavors` blocks **inside** `android {}`, directly after `buildTypes {}`.

- [ ] **Step 2: Add `flavorDimensions` and `productFlavors` inside the `android {}` block**

  The complete `android {}` block after editing (replace the entire block — everything from `android {` to its closing `}`):

  ```kotlin
  android {
      namespace = "com.alexandermessinger.corejourney"
      compileSdk = flutter.compileSdkVersion
      ndkVersion = flutter.ndkVersion

      compileOptions {
          sourceCompatibility = JavaVersion.VERSION_17
          targetCompatibility = JavaVersion.VERSION_17
          isCoreLibraryDesugaringEnabled = true
      }

      kotlinOptions {
          jvmTarget = JavaVersion.VERSION_17.toString()
      }

      defaultConfig {
          applicationId = "com.alexandermessinger.corejourney"
          minSdk = flutter.minSdkVersion
          targetSdk = flutter.targetSdkVersion
          versionCode = flutter.versionCode
          versionName = flutter.versionName
      }

      signingConfigs {
          create("release") {
              if (keystorePropertiesFile.exists()) {
                  keyAlias = keystoreProperties["keyAlias"] as String
                  keyPassword = keystoreProperties["keyPassword"] as String
                  storeFile = file(keystoreProperties["storeFile"] as String)
                  storePassword = keystoreProperties["storePassword"] as String
              }
          }
      }

      buildTypes {
          release {
              if (keystorePropertiesFile.exists()) {
                  signingConfig = signingConfigs.getByName("release")
              }
          }
      }

      flavorDimensions += "environment"

      productFlavors {
          create("development") {
              dimension = "environment"
              applicationIdSuffix = ".dev"
              versionNameSuffix = "-dev"
              resValue("string", "app_name", "CoreJourney DEV")
          }
          create("staging") {
              dimension = "environment"
              applicationIdSuffix = ".staging"
              versionNameSuffix = "-staging"
              resValue("string", "app_name", "CoreJourney STAGING")
          }
          create("production") {
              dimension = "environment"
              resValue("string", "app_name", "CoreJourney")
          }
      }
  }
  ```

- [ ] **Step 3: Update `AndroidManifest.xml` to use `@string/app_name`**

  In `android/app/src/main/AndroidManifest.xml`, change:
  ```xml
  android:label="corejourney"
  ```
  to:
  ```xml
  android:label="@string/app_name"
  ```

- [ ] **Step 4: Verify the debug build works for staging flavor**

  Run from the project root (`claudvibes/reflexjourney/`):
  ```bash
  flutter build apk --flavor staging -t lib/main_staging.dart --debug
  ```

  Expected output (last lines):
  ```
  ✓  Built build/app/outputs/flutter-apk/app-staging-debug.apk (XX.XMB).
  ```

  If you see `Flavor 'staging' not found` → the `productFlavors` block was not saved correctly. Re-read the file and verify.

- [ ] **Step 5: Verify the production flavor also builds**

  ```bash
  flutter build apk --flavor production -t lib/main_production.dart --debug
  ```

  Expected:
  ```
  ✓  Built build/app/outputs/flutter-apk/app-production-debug.apk (XX.XMB).
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml
  git commit -m "feat(android): add development/staging/production product flavors

  Adds flavorDimensions and productFlavors to build.gradle.kts so that
  flutter build --flavor staging/production commands work. Updates
  AndroidManifest to use @string/app_name for per-flavor app labels."
  ```

---

### Task 2: Generate the release keystore

**Files:**
- Modify: `android/key.properties` (local only — already git-ignored)

You need a release keystore to sign APKs. This file stays on your machine only. **Never commit it.**

- [ ] **Step 1: Generate the keystore**

  Run in your home directory (not inside the project):
  ```bash
  keytool -genkey -v \
    -keystore ~/corejourney-release.keystore \
    -alias corejourney \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
  ```

  Answer the prompts:
  - First/Last name: `Alexander Messinger`
  - Organization: `CoreJourney`
  - City: your city
  - Country code: `DE`
  - Password: choose a strong password — **save it in your password manager now**

  Expected final line: `[Storing /Users/alexandermessinger/corejourney-release.keystore]`

- [ ] **Step 2: Update `android/key.properties` with real values**

  Edit `android/key.properties`:
  ```properties
  storePassword=<YOUR_STORE_PASSWORD>
  keyPassword=<YOUR_KEY_PASSWORD>
  keyAlias=corejourney
  storeFile=/Users/alexandermessinger/corejourney-release.keystore
  ```

  Replace `<YOUR_STORE_PASSWORD>` and `<YOUR_KEY_PASSWORD>` with the password you chose in Step 1 (they are the same password if you used the same for both during keytool prompts).

- [ ] **Step 3: Verify a local release build signs correctly**

  ```bash
  flutter build apk --flavor staging -t lib/main_staging.dart --release
  ```

  Expected:
  ```
  ✓  Built build/app/outputs/flutter-apk/app-staging-release.apk (XX.XMB).
  ```

  Verify it is release-signed (not debug-signed):
  ```bash
  apksigner verify --print-certs build/app/outputs/flutter-apk/app-staging-release.apk | head -5
  ```

  Expected: shows your certificate details (not "Android Debug").
  If `apksigner` is not in PATH, find it at: `~/Library/Android/sdk/build-tools/<version>/apksigner`

- [ ] **Step 4: Encode the keystore as base64 for GitHub Secrets (save output)**

  ```bash
  base64 -i ~/corejourney-release.keystore | pbcopy
  ```

  This copies the base64-encoded keystore to your clipboard. **Paste it into a temporary note in your password manager** — you'll add it to GitHub Secrets in Task 4.

  No commit for this task — `key.properties` is git-ignored.

---

### Task 3: Set up Firebase App Distribution (manual step in Firebase Console)

**Files:** None — this is a Firebase Console + GitHub Secrets configuration task.

Firebase App Distribution is the Android equivalent of TestFlight: testers receive an invite link, install the Firebase App Tester app, and get APK updates over-the-air.

- [ ] **Step 1: Go to Firebase Console**

  Open [https://console.firebase.google.com](https://console.firebase.google.com). Sign in with the Google account that owns the project.

  You should see an existing Firebase project for CoreJourney (the `google-services.json` at `android/app/google-services.json` tells you which project — open that file and look at `"project_id"`).

  ```bash
  python3 -c "import json; d=json.load(open('android/app/google-services.json')); print(d['project_info']['project_id'])"
  ```

- [ ] **Step 2: Register the Android staging app in Firebase**

  In Firebase Console → your project → Project Settings → "Your apps" → Add app → Android icon.

  - Android package name: `com.alexandermessinger.corejourney.staging`
  - App nickname: `CoreJourney Staging`
  - Skip the SHA-1 step for now (not needed for App Distribution)

  Click "Register app". **Do NOT re-download `google-services.json`** — the existing one covers the base package and App Distribution doesn't need package-specific config in the file.

- [ ] **Step 3: Copy the Firebase App ID for the staging app**

  After registering, go to Project Settings → Your apps. Find "CoreJourney Staging". The App ID looks like:
  ```
  1:123456789012:android:abcdef1234567890
  ```

  Save this — you'll add it as `FIREBASE_APP_ID_STAGING` in GitHub Secrets.

- [ ] **Step 4: Enable Firebase App Distribution in the console**

  In Firebase Console → left sidebar → Release & Monitor → App Distribution.

  Click "Get started" if prompted. This activates the service for the project.

- [ ] **Step 5: Create a service account for CI**

  In Firebase Console → Project Settings → Service accounts tab → "Manage service account permissions" link (opens Google Cloud Console).

  In Google Cloud Console:
  - IAM & Admin → Service Accounts → Create Service Account
  - Name: `github-actions-ci`
  - Description: `GitHub Actions CI/CD for Firebase App Distribution`
  - Click Create and Continue
  - Role: search for "Firebase App Distribution Admin" → select it
  - Click Done

  Then: click the new service account → Keys tab → Add Key → Create new key → JSON → Create.

  A JSON file downloads to your machine. Its contents go into the `FIREBASE_SERVICE_ACCOUNT` GitHub Secret.

- [ ] **Step 6: Create a tester group in App Distribution**

  In Firebase Console → App Distribution → Testers & Groups → Add group.
  - Group alias: `testers`
  - Add your own email address as a tester

  The CI workflow uploads to the `testers` group. You can add more emails later.

---

### Task 4: Add GitHub Secrets for Firebase and Android signing

**Files:** None — GitHub repository settings.

- [ ] **Step 1: Navigate to GitHub Secrets**

  Go to your repository on GitHub → Settings → Secrets and variables → Actions → "New repository secret".

- [ ] **Step 2: Add `FIREBASE_APP_ID_STAGING`**

  Name: `FIREBASE_APP_ID_STAGING`
  Value: the App ID from Task 3, Step 3 (format: `1:123456789012:android:abcdef1234567890`)

- [ ] **Step 3: Add `FIREBASE_SERVICE_ACCOUNT`**

  Name: `FIREBASE_SERVICE_ACCOUNT`
  Value: the **entire contents** of the service account JSON file downloaded in Task 3, Step 5.

  Open the JSON file in a text editor, select all, copy and paste it as the secret value.

- [ ] **Step 4: Add Android signing secrets**

  Add these four secrets (you collected the values in Task 2):

  | Secret Name | Value |
  |---|---|
  | `ANDROID_KEYSTORE_BASE64` | The base64 keystore string you copied in Task 2, Step 4 |
  | `ANDROID_KEY_ALIAS` | `corejourney` |
  | `ANDROID_KEY_PASSWORD` | Your key password |
  | `ANDROID_STORE_PASSWORD` | Your store password |

---

### Task 5: Update `deploy_staging.yml` to decode the keystore in CI

**Files:**
- Modify: `.github/workflows/deploy_staging.yml`

Currently the staging workflow builds a `--release` APK without setting up the keystore. Adding a decode step makes the CI release-signed (important for testing in-app features that behave differently under debug signing, like certificate pinning).

- [ ] **Step 1: Add the keystore-decode step to `deploy_staging.yml`**

  Replace the entire `.github/workflows/deploy_staging.yml` with:

  ```yaml
  name: Deploy to Staging

  on:
    push:
      branches:
        - develop

  jobs:
    deploy-staging:
      runs-on: ubuntu-latest

      steps:
        - name: Checkout code
          uses: actions/checkout@v4

        - name: Setup Flutter
          uses: subosito/flutter-action@v2
          with:
            flutter-version: '3.24.x'
            channel: 'stable'
            cache: true

        - name: Setup Java
          uses: actions/setup-java@v4
          with:
            distribution: 'zulu'
            java-version: '17'

        - name: Install dependencies
          run: flutter pub get

        - name: Decode keystore
          env:
            ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          run: |
            echo $ANDROID_KEYSTORE_BASE64 | base64 --decode > android/app/keystore.jks

        - name: Write key.properties
          env:
            ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
            ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
            ANDROID_STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          run: |
            cat > android/key.properties << EOF
            storePassword=$ANDROID_STORE_PASSWORD
            keyPassword=$ANDROID_KEY_PASSWORD
            keyAlias=$ANDROID_KEY_ALIAS
            storeFile=$(pwd)/android/app/keystore.jks
            EOF

        - name: Build Android APK (Staging)
          run: flutter build apk --flavor staging -t lib/main_staging.dart --release

        - name: Upload to Firebase App Distribution
          uses: wzieba/Firebase-Distribution-Github-Action@v1
          with:
            appId: ${{ secrets.FIREBASE_APP_ID_STAGING }}
            serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
            groups: testers
            file: build/app/outputs/flutter-apk/app-staging-release.apk
            releaseNotes: |
              Staging build from commit: ${{ github.sha }}
              Branch: ${{ github.ref_name }}

              Changes:
              ${{ github.event.head_commit.message }}

        - name: Notify on success
          if: success()
          run: |
            echo "✅ Staging build deployed to Firebase App Distribution!"
            echo "Build number: ${{ github.run_number }}"
            echo "Commit: ${{ github.sha }}"

        - name: Notify on failure
          if: failure()
          run: |
            echo "❌ Staging deployment failed!"
            echo "Check the logs for details."
  ```

- [ ] **Step 2: Commit**

  ```bash
  git add .github/workflows/deploy_staging.yml
  git commit -m "feat(ci): add keystore decode step to staging workflow

  Decodes base64 keystore from GitHub Secrets and writes key.properties
  before the release build so the APK is properly release-signed."
  ```

---

### Task 6: Trigger the staging pipeline and verify end-to-end

**Files:** None — this is a verification task.

- [ ] **Step 1: Push to the `develop` branch**

  ```bash
  git checkout develop  # or create it if it doesn't exist: git checkout -b develop
  git push origin develop
  ```

- [ ] **Step 2: Watch the workflow run**

  Go to your repository on GitHub → Actions tab → "Deploy to Staging" workflow.

  The workflow should:
  1. Set up Flutter ✓
  2. Install dependencies ✓
  3. Decode keystore ✓
  4. Build APK — staging flavor ✓
  5. Upload to Firebase App Distribution ✓

  Expected total runtime: ~8–12 minutes.

- [ ] **Step 3: Verify the APK appears in Firebase App Distribution**

  In Firebase Console → App Distribution → select the CoreJourney Staging app.

  You should see a release with:
  - Version name matching `pubspec.yaml` version + `-staging` suffix
  - Release notes from the commit message
  - Status: "Active"

- [ ] **Step 4: Accept the tester invite and install on an Android device**

  Check the email address you added as a tester in Task 3 Step 6. You will receive an invite email from Firebase.

  On an Android device:
  1. Open the invite email → click the link
  2. Install "Firebase App Tester" from Play Store when prompted
  3. Sign in with your Google account
  4. Download and install the CoreJourney Staging APK

  The app icon should show "CoreJourney STAGING" label (from the `resValue` you added in Task 1).

  If the install is blocked: Android Settings → Security → enable "Install from unknown sources" for Firebase App Tester.

---

## Phase 2: Google Play Internal Testing (Production)

This mirrors TestFlight's "pre-release to internal testers via the store" flow. Requires a Google Play Console developer account ($25 one-time fee) and release-signed AAB.

---

### Task 7: Create the app on Google Play Console

**Files:** None — Google Play Console configuration.

- [ ] **Step 1: Log in to Google Play Console**

  Go to [https://play.google.com/console](https://play.google.com/console). Sign in with the Google account you want to publish under.

  If you don't have a developer account, register at that URL ($25 one-time registration fee).

- [ ] **Step 2: Create a new app**

  Click "Create app":
  - App name: `CoreJourney`
  - Default language: `German (Germany)` (or your preference)
  - App or game: App
  - Free or paid: Free
  - Accept the declarations → "Create app"

- [ ] **Step 3: Note the package name**

  In the app's dashboard, the package name will be `com.alexandermessinger.corejourney`. This must exactly match the `applicationId` in `android/app/build.gradle.kts`.

- [ ] **Step 4: Build a release-signed AAB locally to do the first upload manually**

  The Play Store requires the **first upload** to be done manually through the console (you can't use the API for a brand new app).

  ```bash
  flutter build appbundle --flavor production -t lib/main_production.dart --release
  ```

  Expected:
  ```
  ✓  Built build/app/outputs/bundle/productionRelease/app-production-release.aab (XX.XMB).
  ```

- [ ] **Step 5: Upload the AAB to Internal Testing track manually**

  In Play Console → your app → Release → Testing → Internal testing → Create new release.

  - Click "Upload" → select `build/app/outputs/bundle/productionRelease/app-production-release.aab`
  - Add release notes (any text)
  - Click "Save" → "Review release" → "Start rollout to Internal testing"

  This first manual upload also triggers Google Play to use App Signing (Google manages the signing key for distribution; your upload keystore is just used to verify authenticity).

- [ ] **Step 6: Add internal testers**

  Internal Testing → Testers tab → Create email list → add your email addresses → Save.

  Testers will receive a Play Store link to install the app.

---

### Task 8: Create a Google Play service account for CI

**Files:** None — Google Cloud / Play Console configuration.

- [ ] **Step 1: Open Google Play Console → Setup → API access**

  Click "Link to a Google Cloud project" and follow the prompts to link your Play Console to a Google Cloud project (create one if prompted).

- [ ] **Step 2: Create a service account**

  On the API access page, click "Create new service account" → follow the link to Google Cloud Console.

  In Google Cloud Console:
  - IAM & Admin → Service Accounts → Create Service Account
  - Name: `play-store-ci`
  - Click Create and Continue
  - Role: `Service Account User` (the Play permissions are granted in Play Console separately)
  - Click Done

  Then: click the service account → Keys tab → Add Key → Create new key → JSON → Create. Save the downloaded JSON.

- [ ] **Step 3: Grant the service account Play Store permissions**

  Back in Play Console → Setup → API access → find your new service account → click "Grant access".

  - Account permissions: no account-level permissions needed
  - App permissions: add your app → Role: "Release manager"
  - Click "Invite user" → "Send invitation"

- [ ] **Step 4: Add `PLAY_STORE_SERVICE_ACCOUNT` GitHub Secret**

  GitHub → Settings → Secrets → New repository secret:
  - Name: `PLAY_STORE_SERVICE_ACCOUNT`
  - Value: the entire contents of the JSON key file downloaded in Step 2

---

### Task 9: Update `deploy_production.yml` to decode keystore in CI

**Files:**
- Modify: `.github/workflows/deploy_production.yml`

Same pattern as `deploy_staging.yml` — add the keystore-decode steps before the Android build.

- [ ] **Step 1: Add keystore decode to the `deploy-production` job**

  In `.github/workflows/deploy_production.yml`, in the `deploy-production` job, add these two steps **between** "Install dependencies" and "Build Android AAB (Production)":

  ```yaml
        - name: Decode keystore
          env:
            ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          run: |
            echo $ANDROID_KEYSTORE_BASE64 | base64 --decode > android/app/keystore.jks

        - name: Write key.properties
          env:
            ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
            ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
            ANDROID_STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
          run: |
            cat > android/key.properties << EOF
            storePassword=$ANDROID_STORE_PASSWORD
            keyPassword=$ANDROID_KEY_PASSWORD
            keyAlias=$ANDROID_KEY_ALIAS
            storeFile=$(pwd)/android/app/keystore.jks
            EOF
  ```

  The complete updated `deploy-production` job steps order:
  1. Checkout code
  2. Get version from tag
  3. Setup Flutter
  4. Setup Java
  5. Install dependencies
  6. **Decode keystore** ← new
  7. **Write key.properties** ← new
  8. Build Android AAB (Production)
  9. Build Android APK (Production)
  10. Upload to Play Store (Internal Track)
  11. Create GitHub Release
  12. Notify on success/failure

- [ ] **Step 2: Commit**

  ```bash
  git add .github/workflows/deploy_production.yml
  git commit -m "feat(ci): add keystore decode step to production workflow

  Mirrors the staging workflow pattern — decodes base64 keystore from
  GitHub Secrets before building the release AAB for Play Store upload."
  ```

---

### Task 10: Trigger the production pipeline and verify end-to-end

**Files:** None — verification only.

- [ ] **Step 1: Create and push a version tag**

  Bump the version in `pubspec.yaml` if needed (currently `1.0.0+2026041401`), then:

  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```

- [ ] **Step 2: Watch the `deploy-production` workflow run**

  GitHub → Actions → "Deploy to Production".

  Expected steps to pass:
  1. Checkout ✓
  2. Get version from tag ✓
  3. Setup Flutter ✓
  4. Setup Java ✓
  5. Install dependencies ✓
  6. Decode keystore ✓
  7. Write key.properties ✓
  8. Build Android AAB ✓
  9. Build Android APK ✓
  10. Upload to Play Store Internal Track ✓
  11. Create GitHub Release ✓

- [ ] **Step 3: Verify the AAB appears in Play Console**

  Play Console → your app → Internal Testing → should show a new release.

  Testers you added in Task 7 Step 6 will receive a Play Store link to install the app.

---

## Summary — Trigger Conditions

| Distribution Channel | How to trigger |
|---|---|
| Firebase App Distribution (staging) | Push any commit to the `develop` branch |
| Google Play Internal Testing (production) | Push a git tag matching `v*.*.*` (e.g. `git tag v1.0.1 && git push origin v1.0.1`) |

## Tester Flow (Android = TestFlight equivalent)

**Staging (Firebase App Distribution):**
1. Tester receives email invite from Firebase
2. Installs "Firebase App Tester" from Play Store
3. Signs in → downloads the latest APK automatically
4. No need to re-install for future updates — Firebase App Tester handles OTA updates

**Production (Google Play Internal Testing):**
1. Tester receives a Play Store link (opt-in URL)
2. Installs directly from Play Store
3. Updates arrive automatically via Play Store

---

*Plan written 2026-04-15. Implementation uses existing CI infrastructure — no new workflows or third-party services beyond Firebase and Google Play Console.*
