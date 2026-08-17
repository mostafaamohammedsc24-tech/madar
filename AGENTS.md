# AGENTS.md

## Cursor Cloud specific instructions

This is **Madar** (`مدار`), a mobile-first Flutter real-estate app (Supabase backend, Google Maps, AI chat via an AWS Lambda proxy). Standard commands live in `README.md`; the notes below cover only cloud/dev caveats that are not obvious.

### Toolchain
- Flutter SDK is installed by the startup update script at `~/flutter` (stable, Dart >= 3.9) and symlinked into `/usr/local/bin`, so `flutter` / `dart` are on `PATH` in every shell. It is not part of the base image, so a fresh pod relies on the update script to (re)install it.
- Reinstalling packages: run `flutter pub get` (the update script already does this). `pubspec.lock` is gitignored.

### Running the app (headless VM → use the web target)
- The VM has no emulator/device, so run the app in Chrome via the web target. `web/` is **gitignored**; the update script generates it with `flutter create --platforms=web .` if missing.
- Dev run (hot reload): `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define-from-file=env.local.json` then open `http://localhost:8080` in `/usr/local/bin/google-chrome`. First web compile takes ~30–90s.
- `env.local.json` is gitignored and holds secrets (Supabase, Gemini/Qwen, Google Maps). It is optional: the app boots without it — `SupabaseService.initialize()` throws but is caught in `main.dart`, and `search_map_screen` falls back to `_loadMockData()`.

### Non-obvious gotchas
- **Auth works with no backend.** The onboarding flow (phone → OTP → Face ID → National ID) catches Supabase errors and still advances, landing on `/search-map-screen`. This is the quickest manual smoke test. There is no route guard, so you can deep-link any route via the hash, e.g. `http://localhost:8080/#/search-map-screen`.
- **Google Maps on web** needs the JS API `<script>` in `web/index.html` `<head>`, loaded **synchronously** (do NOT use `async`/`loading=async` with `google_maps_flutter_web` 0.6.x, it races map init and throws):
  `<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_KEY&libraries=drawing,marker"></script>`
  Because `web/` is regenerated, re-add this after regenerating `web/`. Without it the map area is blank but the rest of the app works. The key belongs in a secret, never committed.
- Lint: `flutter analyze` reports pre-existing warnings/infos but no errors. There is no `test/` directory, so `flutter test` finds no tests (a `test/widget_test.dart` created by `flutter create` is the default counter template and is not valid for this app — it is removed by the update script).
