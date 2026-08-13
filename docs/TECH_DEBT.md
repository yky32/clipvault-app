# Tech debt register (ClipVal)

Updated after `chore/tech-debt-sweep`.

## Closed (this sweep / prior)

| Item | Resolution |
|------|------------|
| Nearby plaintext / no auth | v2 PIN + AES-GCM |
| Nearby offer drop | Queue |
| Clipboard dismiss plaintext | SHA-256 fingerprint |
| CloudKit ops opacity | diagnose + CLOUDKIT_OPS.md |
| Silent `catch (_)` on hot paths | `AppLog.ignore` (vault/app/icloud/spotlight) |
| `print` iCloud/Nearby | `developer.log` |
| Thin unit tests | backup / clipboard suggest / nearby crypto |
| Vault nudge UI bloat | `vault_nudge_banners.dart` |
| Deploy cancel mid-TF | `cancel-in-progress: false` |

## Accepted / deferred

| Item | Why deferred |
|------|----------------|
| Settings God page full split | Large pure-UI refactor; low user value — extract incrementally |
| Full DI container | Overkill for app size; AppBootstrap statics OK |
| Android | Product full-lane, not debt |
| Remote feature flags | One-person ship; prefs enough |
| Widget App Group plaintext top-N | Documented tradeoff for offline widget copy |
| 100% catch(_) eradication | Many file-picker / UX paths intentionally soft |

## Rules going forward

1. Best-effort side effects → `AppLog.ignore`, never empty catch on new code  
2. Secrets never in Spotlight / logs / dismiss prefs  
3. Deploy must not cancel in-flight TestFlight  
4. New features ship with at least one unit test when logic is pure  
