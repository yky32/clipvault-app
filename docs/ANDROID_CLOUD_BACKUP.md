# Android cloud backup (parity with iOS iCloud *idea*)

| Platform | Mechanism | Settings section |
|----------|-----------|------------------|
| iOS | Private CloudKit | **iCloud** (existing) |
| Android | Encrypted `.clipval` → Google Drive / Files | **Cloud backup** |

## Hard rules
- No ClipVal account / no ClipVal vault server
- Android UI must **never** say iCloud
- Opt-in, default off

## V1 (shipped UI)
- Toggle Cloud backup + Back up now / Restore → existing secure `.clipval` export/import
- User saves file to Drive via system share sheet
- How-it-works copy explains iPhone vs Android

## V2 (next)
- Google Drive App Data automatic upload/download + backup passphrase wrap
- See product design: CloudBackupProvider abstraction

## Cross-platform
Same `.clipval` file restores on iOS or Android.
