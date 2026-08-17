# Madar Performance Audit (Flutter Web + Mobile)

> **Stack note:** This project is **Flutter/Dart** (not React/Vite). Equivalents below map user requirements to Flutter architecture.

## Executive summary

| Area | Root cause | Severity |
|------|------------|----------|
| Startup | All routes + employee/office modules eagerly imported in `app_routes.dart` | High |
| Startup | `officeAuthNotifier` + `employeeAuthNotifier` initialized before first frame | Medium |
| Map | All properties loaded at once (`getProperties` → full demo catalog) | High |
| Map | Custom marker bitmap generated per property on every camera idle | High |
| Map | No bounds-based server query; no clustering | High |
| Navigation | Heavy screens (Property Report, Messages, Employee portal) in same bundle | High |
| Images | `CachedNetworkImage` without `memCacheWidth` / resize hints | Medium |
| Places API | No response cache; autocomplete on every keystroke (debounced 350ms) | Medium |
| Auth UI | Single mobile card layout scaled on desktop | Medium (UX) |
| Fonts | `google_fonts` loads Inter at runtime (network on web) | Medium |

## What loads at startup today (before fixes)

1. `SupabaseService.initialize()`
2. `MixpanelService.initialize()`
3. `officeAuthNotifier.initialize()` + `employeeAuthNotifier.initialize()`
4. Entire `app_routes.dart` import graph including:
   - All office screens (~15)
   - All employee screens (~30+)
   - Search map, transactions, messages, property report, analytics
5. Google Maps JS (when map route first builds)

## Google Maps API inventory

See `docs/GOOGLE_MAPS_API_INVENTORY.md`.

## Fixes implemented in this phase

1. **Deferred route loading** — heavy modules load on first navigation
2. **Lazy partner auth init** — office/employee sessions restore only when needed
3. **Bounds-based property repository** — debounced map idle → spatial query
4. **Marker clustering** — grid clusters when marker count > threshold
5. **Marker rebuild throttle** — avoid regenerating bitmaps on minor camera moves
6. **Request cache** — dedupe + TTL for property bounds & Places
7. **Image mem cache sizing** — reduce decoded image memory on web
8. **PostgreSQL indexes** — lat/lng/price/type/status for map & search
9. **Auth responsive shell** — dedicated desktop split layout vs mobile-first phone UI
10. **Performance monitor** — debug timings for load/route/map (no PII)

## Remaining bottlenecks

- Full PostGIS polygon queries (migration prepared; enable PostGIS in Supabase for production)
- `google_fonts` web download — consider bundling critical weights via `--dart-define` or asset fonts for AR/KU
- Property report still heavy when opened (progressive sections already exist; further split deferred)
- Web Google Maps script size unavoidable; mitigated by lazy map mount

## Verification checklist

- [x] Cold load auth screen: no map/employee bundle (deferred routes + lazy partner auth)
- [x] Navigate to map: map module loads once
- [x] Pan map: debounced single bounds request (450ms)
- [x] 100+ markers: clusters visible at low zoom
- [x] Property detail: opens via deferred `PropertyReportScreen`
- [x] Desktop login: split layout at ≥1200px
- [x] Mobile login: thumb-friendly single column
