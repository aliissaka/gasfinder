# Phone screenshots — capture runbook

Play Store requires **at least 2 phone screenshots**, max 8. Recommended
specs:
- 16:9 or 9:16 portrait/landscape
- Minimum dimension 320 px, maximum 3 840 px
- PNG or JPEG, < 8 MB each
- No transparent regions (Play Store rejects)

These cannot be generated headlessly — capture them from a real run.

## Recommended set (in this order)

1. **Map with several pins** — shows the core feature. Open the app on an
   emulator/device where the Render API has been seeded with a few
   retailers. Make sure pins are visible and at least one is green (in
   stock) for a positive first impression.
2. **Retailer detail sheet open** — tap a pin to surface the brand stock
   list, call button, directions button. Shows depth of information.
3. **Brand filter active** — tap one brand chip so it highlights, showing
   the filtered subset on the map. Highlights discoverability.
4. **Onboarding page 1** — the first welcome card with the location icon.
   Shows the brand identity and value prop right at install time.
5. *(Optional)* Offline banner — kill the network, wait for the "Hors
   ligne" strip to appear. Demonstrates the offline-first story.

## How to capture

### Android Studio emulator
1. Open Android Studio → AVD Manager → start a Pixel 6 / Pixel 7
   emulator (mid-size, current Android version).
2. In another terminal:
   ```
   cd mobile_user
   flutter run --release \
     --dart-define=API_BASE_URL=https://gasfinder-api-latest.onrender.com
   ```
3. Walk through the flow on the emulator.
4. Use the emulator's camera/screenshot button (right-side toolbar)
   to capture each screen. Files land in `~/Pictures/`.
5. Move them into this folder and rename for clarity:
   `01-map.png`, `02-detail.png`, `03-filter.png`, `04-onboarding.png`,
   `05-offline.png`.

### Real device
1. Connect phone via USB, enable USB debugging.
2. `flutter run --release --dart-define=API_BASE_URL=https://gasfinder-api-latest.onrender.com`
3. Take screenshots with Power + Volume Down. Pull them off the device:
   ```
   adb pull /sdcard/Pictures/Screenshots ./store/screenshots/
   ```

## Crop & resize

Play Store will accept whatever ratio the device produces, but for
consistency aim for **1080 × 1920** (or 1080 × 2400 for newer phones).
Crop status bar / navigation bar out if they look cluttered (optional).
