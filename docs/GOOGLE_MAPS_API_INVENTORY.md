# Google Maps Platform — API Inventory (Madar)

| API / Service | Purpose | Where used | Frequency | Caching | Cost risk | Perf risk |
|---------------|---------|------------|-----------|---------|-----------|-----------|
| **Maps JavaScript API** (via `google_maps_flutter` web) | Interactive map, markers, polygons, camera | `PropertyMapWidget`, `PropertyMapSection`, `OfficeHomeScreen` | Every map session | N/A (client) | Medium | High initial load |
| **Places Autocomplete** | Search bar area/landmark suggestions | `PlacesService.suggest` | Per debounced keystroke (350ms) | In-memory TTL cache (added) | Medium | Medium |
| **Place Details** | Resolve suggestion → lat/lng/viewport | `PlacesService.resolveArea/resolveLandmark` | On suggestion select | Cached by place_id | Low–Medium | Low |
| **Places Nearby Search** | Schools, hospitals, etc. near property | `PlacesService.nearbyLandmarks` | **Property details only** (not list) | Cached by lat+ category | High if misused | High if misused |
| **Geocoding** (via `geocoding` package) | Region detection from GPS | `RegionDetectionService` | Once per auth location step | Session cache | Low | Low |
| **Static map URLs** | Chat location links | `chat_bubble.dart` | On user tap | Browser cache | Very low | None |

## Architecture rules (enforced)

1. **Properties come from Supabase** — never from Google as listing source
2. **Nearby Places** — only on property detail / explicit user action
3. **No duplicate Places clients** — single `PlacesService`
4. **Bounds queries** — `PropertyMapRepository` → Supabase, not client-side full fetch
5. **Debounce map moves** — 450ms after camera idle before fetch
6. **Respect Google ToS** — autocomplete/details cache is in-memory session-only with TTL

## Configuration required

### Google Cloud Console
- Enable: Maps JavaScript API, Places API, Geocoding API
- Restrict API key: HTTP referrers (web) + app bundle IDs (mobile)
- Set quota alerts

### Environment
```json
{
  "GOOGLE_MAPS_API_KEY": "your-key"
}
```
Pass via `--dart-define-from-file=env.local.json`

### Supabase
- Apply migration `011_property_spatial_indexes.sql`
- Optional: enable PostGIS extension for polygon search
