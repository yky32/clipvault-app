# ClipVal app icons (Triftly-style drop folder)

Drop your exported icons here. Structure mirrors **Triftly** `assets/icon/app-icons/`.

```
assets/icon/
├── app-icons/
│   ├── source/          ← master art (preferred start)
│   ├── ios/             ← all iOS App Store / home-screen sizes
│   ├── android/         ← Android launcher sizes
│   └── README.md        ← this file
└── usage-icons/         ← optional UI marks (not the app icon)
```

Generator (same as Triftly): https://appiconmaker.co/

---

## 1. Easiest path (recommended)

1. Design a **1024×1024** PNG (no transparency for App Store marketing icon).
2. Save it as:

   ```
   assets/icon/app-icons/source/app-icon-1024.png
   ```

3. Optionally also drop a transparent mark:

   ```
   assets/icon/app-icons/source/app-icon-removed-background.png
   ```

4. Generate full set at [appiconmaker.co](https://appiconmaker.co/) → export iOS + Android.
5. Put files into `ios/` and `android/` using the **exact names** below.
6. Tell the agent / run install: copy into `ios/Runner/Assets.xcassets/AppIcon.appiconset/` and Android `mipmap-*`.

---

## 2. iOS — put files in `ios/`

Match **exact** filenames (Flutter default AppIcon set):

| File | Pixels |
|------|--------|
| `Icon-App-20x20@1x.png` | 20×20 |
| `Icon-App-20x20@2x.png` | 40×40 |
| `Icon-App-20x20@3x.png` | 60×60 |
| `Icon-App-29x29@1x.png` | 29×29 |
| `Icon-App-29x29@2x.png` | 58×58 |
| `Icon-App-29x29@3x.png` | 87×87 |
| `Icon-App-40x40@1x.png` | 40×40 |
| `Icon-App-40x40@2x.png` | 80×80 |
| `Icon-App-40x40@3x.png` | 120×120 |
| `Icon-App-60x60@2x.png` | 120×120 |
| `Icon-App-60x60@3x.png` | 180×180 |
| `Icon-App-76x76@1x.png` | 76×76 |
| `Icon-App-76x76@2x.png` | 152×152 |
| `Icon-App-83.5x83.5@2x.png` | 167×167 |
| `Icon-App-1024x1024@1x.png` | **1024×1024** (App Store) |

**Rules**

- PNG, RGB, **no alpha** on the 1024 marketing icon (App Store rejects transparency).
- Square, no rounded corners (iOS applies the mask).

After upload, copy into:

```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

---

## 3. Android — put files in `android/`

| File | Pixels | → install as |
|------|--------|----------------|
| `Icon-36.png` | 36×36 | `mipmap-ldpi` / optional |
| `Icon-48.png` | 48×48 | `mipmap-mdpi/ic_launcher.png` |
| `Icon-72.png` | 72×72 | `mipmap-hdpi/ic_launcher.png` |
| `Icon-96.png` | 96×96 | `mipmap-xhdpi/ic_launcher.png` |
| `Icon-144.png` | 144×144 | `mipmap-xxhdpi/ic_launcher.png` |
| `Icon-192.png` | 192×192 | `mipmap-xxxhdpi/ic_launcher.png` |
| `Icon-512.png` | 512×512 | Play store / adaptive source |

---

## 4. Optional `usage-icons/`

Not the home-screen icon — small logos for in-app UI if needed later.

---

## 5. Checklist

- [ ] `source/app-icon-1024.png` present  
- [ ] `ios/` has all 15 `Icon-App-*.png` files  
- [ ] `android/` has Icon-48 … Icon-512  
- [ ] 1024 has **no transparency**  
- [ ] Message agent: **“install icons from assets/icon/app-icons”**
