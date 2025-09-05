# CodePulse

A simple Flutter app for coding puzzles and quick 1-vs-1 coding battles — a student project, clean and easy to run.

---

## Overview

CodePulse provides:

* Single-player puzzles with an in-app editor and test/check flow.
* Realtime 1v1 rooms (works with a simple backend or Firestore).
* Optional Firebase for authentication and persistent data.

This README is short and focused so other students can run and extend the app quickly.

---

## Quick start

1. Clone the repo

```bash
git clone https://github.com/Dnaresh252/Code_pulse.git
cd Code_pulse
```

2. Install dependencies

```bash
flutter pub get
```

3. Run on device or emulator

```bash
flutter run
```

4. Build a release APK (Android)

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project layout (important files)

```
lib/         # app source (main.dart, screens, widgets, services)
assets/      # icons, puzzles, images (add here)
pubspec.yaml
test/
README.md
```

---

## Puzzles (how to add)

Puzzles can be local JSON files in `assets/puzzles/` or stored in Firestore.

Example `assets/puzzles/p01_sum.json`:

```json
{
  "id": "p01",
  "title": "Sum Two Numbers",
  "description": "Return the sum of two integers.",
  "starter_code": "int solve(int a, int b) { return 0; }",
  "tests": [
    {"input": [1,2], "output": 3},
    {"input": [5,7], "output": 12}
  ],
  "time_limit": 120
}
```

If using local puzzles, add `assets/puzzles/` to `pubspec.yaml` under `flutter.assets:`.

---

## Firebase 

To enable auth and Firestore:

* Add `google-services.json` → `android/app/`
* Add `GoogleService-Info.plist` → `ios/Runner/`
* Enable Authentication providers and create collections like `puzzles`, `rooms`, `users`.

Keep server keys and secrets out of the client.

---

## Contributing

1. Fork → branch (`feature/your-feature`).
2. Make focused changes and add tests if possible.
3. Open a pull request with a short description.

For big files (video/screenshots), prefer external hosting and link in the README.

---

## License (student terms)

Use and modify for **personal, educational, or research** purposes. If you publish work that uses this repo, please credit the source. For commercial use, open an issue to discuss.

---

## Contact

Open an issue on GitHub for bugs, suggestions, or to share a demo link. Include steps to reproduce and any logs/screenshots.
