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
## Screenshorts
![WhatsApp Image 2025-06-20 at 15 22 13_1fa68be7](https://github.com/user-attachments/assets/4645fa10-b814-4a9c-b483-c496a1a06deb)
![WhatsApp Image 2025-06-20 at 15 22 14_09620f63](https://github.com/user-attachments/assets/7e586141-6c02-4631-b9ee-d05056f7e5f8)
![WhatsApp Image 2025-06-20 at 15 22 14_476b68b4](https://github.com/user-attachments/assets/4ef9108a-ce17-439e-8873-2cfbd1d61243)
![WhatsApp Image 2025-08-01 at 14 03 01_9908ed1f](https://github.com/user-attachments/assets/86b55364-1218-4364-9f3d-f23a32c12be9)
![WhatsApp Image 2025-08-01 at 14 02 59_fca11882](https://github.com/user-attachments/assets/d538de06-bbb7-4258-8251-249eeeb2bcb7)
![WhatsApp Image 2025-08-01 at 14 03 00_5bf8c986](https://github.com/user-attachments/assets/edfedbef-6e94-4394-8d39-60a7e0940de5)

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
