# CloudKit ops (CLIPVAL-CK-001)

## Why eng cannot one-click Prod schema
- TestFlight / App Store builds use **Production** CloudKit container `iCloud.com.clipval`
- Creating record types in Production requires **Apple Developer → CloudKit Dashboard** (or Management Token + `cktool`)
- ASC API key ≠ CloudKit Management Token

## Deploy checklist (CEO)
1. Xcode / Debug build on device with iCloud sync **on** → seeds **Development** schema  
2. CloudKit Dashboard → container `iCloud.com.clipval` → **Deploy Schema Changes…**  
3. Confirm Production has `ClipItem`, `Category`, `VaultMeta` (not 0 types)  
4. Optional: “立即同步” / fetch  
5. Re-test TF with Settings → **Check iCloud status**

## In-app
- Settings → iCloud → **Check iCloud status** (`diagnose`) maps:
  - `schema_production` → friendly copy + this doc  
  - `no_account` / `network`

## CLI (optional later)
Store Management Token in `~/.hermes/.env` only (never commit).  
`cktool` can automate schema inspect; **Dashboard Deploy** may still be required for Dev→Prod.
