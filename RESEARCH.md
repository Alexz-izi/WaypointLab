# Technical Research Report: No-Mac Cloud Build & Sideloading Architecture

**Date Checked:** October 4, 2026  
**Environment:** Windows 11 PC (Developer Workstation) -> GitHub Actions Hosted macOS (Build Cloud)  
**Target Device:** iPhone 14 Pro  
**Target Operating System:** iOS 26.5  
**Installation & Signing Method:** SideStore (On-Device Signing via Free Personal Team Apple ID)  
**Budget / Cost Constraint:** $0.00 (100% Free Tier, No Mac Required)

---

## 1. No-Mac iOS Build Solutions Comparison

The prompt requires researching practical end-to-end solutions that enable compiling a native SwiftUI iOS application, generating an IPA, and installing it on an iPhone 14 Pro **without owning, borrowing, or operating a Mac (physical or remote desktop)**.

| Solution / Service | Requires Local Mac? | Uses Remote/Hosted macOS? | Supports Native SwiftUI? | Produces IPA? | Code Signing Model | Free Tier Availability | Downloadable to Windows? | SideStore Compatible? | Official Documentation URL |
|---|---|---|---|---|---|---|---|---|---|
| **GitHub Actions (Hosted macOS)** | **NO** | YES (Cloud runner: `macos-latest` / `macos-15` / `xcode-27`) | **YES** (Native `xcodebuild`) | **YES** (Exports unsigned/ad-hoc IPA via script) | Cloud compiles unsigned binary; SideStore signs on-device | **Free**: Unlimited for public repos; 2,000 min/mo for private | **YES** (`upload-artifact@v4`) | **YES** (Direct import) | [docs.github.com/actions](https://docs.github.com/en/actions) |
| **Codemagic CI/CD** | **NO** | YES (Hosted macOS M1/M2) | **YES** (Xcode workflow) | **YES** | Requires configuring Apple certificates/keys in UI | 500 free build minutes/month for personal accounts | **YES** (Artifact download) | **YES** | [docs.codemagic.io](https://docs.codemagic.io/) |
| **Bitrise CI/CD** | **NO** | YES (Hosted macOS) | **YES** | **YES** | Requires code signing setup or certificates | Limited free tier (trial / credit-based) | **YES** | **YES** | [devcenter.bitrise.io](https://devcenter.bitrise.io/) |
| **Windows Native Swift Toolchain** | **NO** | NO | **NO** (UIKit/SwiftUI are Apple proprietary frameworks not present on Windows) | **NO** (Cannot assemble Mach-O arm64 dynamic bundles or link against iOS SDK) | None | Free (Open source) | N/A | **NO** | [swift.org/install/windows](https://www.swift.org/install/windows/) |
| **Cloud Mac VNC / RDP (e.g. MacStadium)** | **NO** | YES (Interactive GUI VM) | **YES** | **YES** | Full local Xcode signing | **NO** ($30–$100+/month paid subscription) | **YES** | **YES** | [macstadium.com](https://www.macstadium.com) |

### Determination of the Optimal Solution: **GitHub Actions Hosted macOS**
1. **Zero Mac Requirement:** The developer works exclusively on Windows 11 in Codex/VS Code, committing to a Git repository.
2. **True $0 Cost:** GitHub Actions provides free hosted macOS arm64 runners with pre-installed Xcode toolchains.
3. **Decoupled Signing (The Key Breakthrough):** Free Apple Accounts cannot export enterprise or developer distribution certificates into CI environments without 2FA SMS prompts and certificate revocation risks. By configuring GitHub Actions to compile the project with `CODE_SIGNING_ALLOWED=NO` and package `WaypointLab.app` into an `.ipa` container, GitHub Actions produces a clean binary.
4. **On-Device Signing via SideStore:** SideStore runs natively on the iPhone 14 Pro. When the unsigned `.ipa` is imported into SideStore, SideStore utilizes the device's local Apple ID keychain and LocalDevVPN loopback tunnel to sign the binary with a fresh 7-day Personal Team provisioning profile directly on the phone.

---

## 2. GitHub Actions Runner Specifications & Xcode Versions

- **Runner Labels:**
  - `macos-latest` (Points to the latest stable macOS, typically macOS 15 Sonoma/Sequoia or macOS 26/Tahoe).
  - `macos-14` / `macos-15` / `xcode-27`: Dedicated arm64 runner images optimized for Apple development.
- **Pre-installed Tooling:**
  - Apple Developer Command Line Tools (`xcodebuild`, `xcrun`, `simctl`, `codesign`).
  - Swift Compiler (Swift 6.x / 5.10+).
  - Python 3, Git, zip/unzip, curl.
- **Workflow Automation:**
  - Can be triggered automatically on `git push`, on pull request, or manually via `workflow_dispatch` button in the GitHub browser UI.

---

## 3. Apple Free Personal Team Account & SideStore Interaction

### Restrictions & Parameters
- **7-Day Provisioning Profile Expiration:** Free Apple Accounts issue certificates and profiles valid for 7 days.
- **3 Active App Limit:** A device using a free Apple Account can run up to 3 sideloaded apps concurrently (SideStore counts as 1).
- **10 App IDs per 7-Day Window:** Bundle identifiers must be used consistently to avoid hitting the 10 App ID weekly allocation limit.
- **Wireless On-Device Refreshing:**
  - SideStore uses the **LocalDevVPN** (WireGuard local loopback) to establish a virtual tether to `localhost:server`.
  - When connected to Wi-Fi with LocalDevVPN enabled, SideStore contacts Apple's anisette server, re-signs the app certificate, and installs updated provisioning profiles over Wi-Fi without needing a Windows or Mac computer after initial installation.

---

## 4. Location Simulation: System vs. In-App Architecture

- **Public API Boundary:** iOS sandboxing strictly isolates third-party applications. No public Apple API permits a standalone app to spoof or manipulate the iPhone's global CoreLocation subsystem for external apps (such as Maps, Uber, or social apps).
- **In-App Simulation Engine (Waypoint Lab):**
  - Waypoint Lab features an in-app trajectory and coordinate preview engine.
  - Users can select points, enter coordinates, search places, import GPX files, and animate navigation tracks along routes inside Waypoint Lab.
  - A clear system disclosure informs users of the distinction between developer Xcode schemes (which require tethered debugging) and sandboxed in-app previews.

---

## 5. Web Research References & Verified Dates

1. **GitHub Actions Hosted Runners:**  
   URL: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners  
   Verified: October 2026.
2. **GitHub Runner Images (macOS):**  
   URL: https://github.com/actions/runner-images  
   Verified: October 2026.
3. **SideStore Documentation (Getting Started, Requirements & IPA Installation):**  
   URL: https://docs.sidestore.io/docs/intro  
   Verified: October 2026.
4. **Apple Developer Documentation (xcodebuild, Code Signing & MapKit):**  
   URL: https://developer.apple.com/documentation/xcode/building-from-the-command-line  
   URL: https://developer.apple.com/documentation/mapkit/map  
   Verified: October 2026.
