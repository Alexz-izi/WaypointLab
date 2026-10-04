# Waypoint Lab — No-Mac iOS Cloud Build & SideStore Guide

Welcome to **Waypoint Lab**, a native iOS application built with Swift, SwiftUI, MapKit, and CoreLocation. This guide outlines the verified, practical end-to-end workflow to edit code on Windows 11, compile the iOS app in the cloud, export an IPA, and install it on an iPhone 14 Pro **without owning, borrowing, or operating a Mac**.

---

## 1. Executive Summary & Chosen Architecture

| Stage | Responsibility | Tool / Service | Cost |
|---|---|---|---|
| **Code Editing & Staging** | Windows 11 Workstation | Codex / VS Code / Git | Free ($0) |
| **Cloud Compilation** | Hosted arm64 macOS Runner | GitHub Actions (`macos-latest` / Xcode) | Free ($0) |
| **Packaging** | Automated Script | `xcodebuild` + zip -> `WaypointLab.ipa` | Free ($0) |
| **Distribution / Transfer** | Artifact Download | GitHub Actions Artifacts / Releases | Free ($0) |
| **Code Signing** | On-Device Personal Team Signer | SideStore + LocalDevVPN (Loopback) | Free ($0) |
| **Target Hardware** | Physical Device | iPhone 14 Pro (iOS 26.5 / iOS 17+) | User device |

### Why This Solution Was Selected
1. **Zero Mac Requirement:** No local Mac, virtual machine, or remote desktop (VNC/RDP) session is needed.
2. **True $0 Cost:** GitHub Actions provides free hosted macOS arm64 runners with pre-installed Xcode.
3. **Decoupled Signing:** Free Apple Accounts cannot export distribution signing keys to third-party CI runners without 2FA complications and frequent expiration. By compiling the native binary without code signing in GitHub Actions and allowing **SideStore** to sign the IPA on the physical iPhone, both security and automation are preserved.
4. **Wireless On-Device Refreshing:** SideStore uses a local WireGuard loopback VPN (`LocalDevVPN`) to self-sign and refresh installed apps over Wi-Fi before the 7-day free profile expires.

---

## 2. Project Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── build.yml               # GitHub Actions hosted macOS build workflow
├── RESEARCH.md                     # In-depth technical research & comparison report
├── README.md                       # Complete end-to-end user manual
├── build_ipa.sh                    # POSIX shell script to compile & package IPA
├── validate_project.ps1            # Windows PowerShell automated validator
├── validate_project.py             # Python validation script
├── WaypointLab.xcodeproj/
│   └── project.pbxproj             # Xcode project bundle configuration
└── WaypointLab/
    ├── WaypointLabApp.swift        # Application entry point & shared environment
    ├── Models/
    │   ├── Waypoint.swift          # Waypoint model, validation & coordinate formatting
    │   └── RoutePoint.swift        # Route point model & trajectory coordinates
    ├── Services/
    │   ├── LocationManager.swift   # CoreLocation authorization & device positioning
    │   ├── SearchService.swift     # MKLocalSearch & MKLocalSearchCompleter
    │   ├── RouteSimulationManager.swift # GPX parser & playback engine
    │   └── FavoritesManager.swift  # Persistent storage via UserDefaults / JSON
    ├── Views/
    │   ├── MainTabView.swift       # Tab coordinator & navigation root
    │   ├── MapView.swift           # Declarative Map with MapReader tap coordinates
    │   ├── ManualCoordinateView.swift # Coordinate entry, bounds check, presets & copy
    │   ├── SearchView.swift        # Place search & autocompletion sheet
    │   ├── RouteSimulationView.swift # GPX playback controls & file importer
    │   ├── FavoritesView.swift     # Saved locations list, edit & delete
    │   └── SettingsView.swift      # Map style, playback speed & disclosures
    └── Resources/
        ├── Info.plist              # Privacy descriptions & bundle settings
        └── SampleRoute.gpx         # Valid GPX track (Cupertino Innovation Loop)
```

---

## 3. Web Research Sources & Verification

All architectural decisions and service parameters were verified against official documentation:

1. **GitHub Actions Hosted Runners:**  
   - Official Docs: https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners  
   - Verified: October 2026. Hosted macOS arm64 images run on Apple hardware and include `xcodebuild` and Command Line Tools.
2. **SideStore Documentation (Unsigned IPA & Loopback Refreshing):**  
   - Official Docs: https://docs.sidestore.io/docs/intro  
   - Verified: October 2026. SideStore signs unsigned IPAs on-device using a personal Apple ID and refreshes certificates via LocalDevVPN over Wi-Fi.
3. **Apple Developer Code Signing with Free Accounts:**  
   - Documentation: https://developer.apple.com/support/code-signing/  
   - Free Personal Team accounts are subject to a 7-day expiration, a 3-app active limit, and a 10 App ID per week limit.
4. **Apple MapKit & CoreLocation Documentation:**  
   - Documentation: https://developer.apple.com/documentation/mapkit/map  
   - Modern SwiftUI declarative `Map` APIs are fully supported from iOS 17 through iOS 26+.

---

## 4. Required Accounts & Free-Tier Limits

1. **GitHub Account (Free):**
   - Unlimited hosted runner build minutes for public repositories; 2,000 minutes/month for private repositories.
2. **Apple Account / Apple ID (Free):**
   - Standard free consumer Apple ID (no $99/year developer membership required).
   - *Limitation:* Apps signed with a free account remain valid for **7 days** before requiring a refresh. SideStore automates this refresh over Wi-Fi.
   - *App Limit:* Up to **3 active apps** per device (SideStore counts as 1; Waypoint Lab counts as 2).

---

## 5. Step-by-Step Setup: From Windows to iPhone

### Step 1: Initialize Git Repository on Windows
Open PowerShell or your terminal in the project directory (`c:\Users\Administrator\Desktop\test'`):

```powershell
# 1. Initialize local repository
git init

# 2. Add all project files
git add .

# 3. Create initial commit
git commit -m "Initial commit of Waypoint Lab with GitHub Actions workflow"
```

### Step 2: Push to GitHub
1. Go to [GitHub.com](https://github.com) and click **New Repository**.
2. Name the repository `WaypointLab` (Public or Private).
3. Link and push your code from Windows:
   ```powershell
   git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/WaypointLab.git
   git branch -M main
   git push -u origin main
   ```

### Step 3: Trigger Cloud Build & Monitor Logs
1. Open your repository on GitHub in your web browser.
2. Click on the **Actions** tab at the top.
3. You will see the **Build Waypoint Lab iOS IPA** workflow running automatically from your push.
   - *(Optional manual trigger)*: Select **Build Waypoint Lab iOS IPA** on the left -> Click **Run workflow** -> Click the green **Run workflow** button.
4. Click on the active workflow run to watch real-time compiler output from `xcodebuild`.
5. The build completes in approximately 2 to 4 minutes.

### Step 4: Download the Compiled IPA
1. On the completed workflow run page, scroll down to the **Artifacts** section at the bottom.
2. Click on **WaypointLab-iOS-IPA**.
3. A zip file containing `WaypointLab.ipa` will download to your Windows PC (or you can open the same GitHub page on your iPhone via Safari and download it directly).
4. Extract `WaypointLab.ipa` from the downloaded zip file.

---

## 6. Installing on iPhone 14 Pro via SideStore

### Initial SideStore Setup (One-Time Only)
If you do not already have SideStore installed on your iPhone:
1. Download **SideServer** on Windows from [sidestore.io](https://sidestore.io).
2. Install iTunes and iCloud for Windows (direct Apple versions, not Microsoft Store versions).
3. Connect your iPhone 14 Pro via USB cable to Windows.
4. Run SideServer from the system tray -> Click **Install SideStore** -> Enter your Apple ID.
5. On your iPhone: Go to **Settings > General > VPN & Device Management** -> Tap your Apple ID -> Tap **Trust**.
6. On your iPhone: Go to **Settings > Privacy & Security** -> Scroll down to **Developer Mode** -> Toggle **ON** and reboot.

### Installing Waypoint Lab IPA
1. Transfer `WaypointLab.ipa` to your iPhone:
   - Send it via iCloud Drive, Google Drive, email, or download directly in Safari on the iPhone.
   - Save the file to the **Files** app.
2. Enable the **LocalDevVPN** (or SideStore WireGuard VPN) on your iPhone.
3. Open the **SideStore** app.
4. Navigate to the **My Apps** tab.
5. Tap the `+` icon in the upper-left corner.
6. Select `WaypointLab.ipa` from your Files app.
7. SideStore unpacks, signs with your free Apple ID certificate, and installs **Waypoint Lab** onto your home screen.

### Keeping the App Active (Wireless Refresh)
- While connected to Wi-Fi and with the LocalDevVPN active, SideStore will automatically refresh the app in the background.
- You can also open SideStore anytime and tap **Refresh All** to reset the 7-day timer without a computer.

---

## 7. Features & In-App Trajectory Simulation

- **Interactive Map:** Pan, zoom, tap to drop custom markers, and display coordinates.
- **Manual Coordinates:** Form input with rigorous bounding checks (-90° to 90° latitude, -180° to 180° longitude), formatted clipboard copying, and presets.
- **Place Search:** Real-time Apple Maps geocoding and autocomplete search for addresses and landmarks.
- **In-App Location Preview:** Visual coordinate testing inside the app.
- **Route Simulation:** GPX trajectory playback with adjustable speed (0.5x to 10x), play/pause/stop controls, progress bar, and bundled sample track (`SampleRoute.gpx`).
- **Favorites:** Persistent storage of saved locations.
- **System Boundaries Disclosure:** The app clearly documents that in-app route previews operate strictly within Waypoint Lab and do not alter the iPhone's system GPS location for third-party apps.

---

## 8. Making Code Changes from Windows

Whenever you want to modify the app:
1. Open the source code in Codex / your Windows editor.
2. Make your Swift / SwiftUI changes.
3. Run the local PowerShell validator to verify syntax and file integrity:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\validate_project.ps1
   ```
4. Commit and push your changes:
   ```powershell
   git add .
   git commit -m "Update map features"
   git push
   ```
5. GitHub Actions immediately builds the new IPA. Download and import it into SideStore.
