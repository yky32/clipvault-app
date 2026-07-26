# clipVauLt – Product Requirements Document (PRD)

**Version:** 1.2  
**Date:** 2026-07-26  
**Status:** Ready for development  
**Platform:** iOS + Android (Flutter)

---

## ONE-PURPOSE MANDATE (CRITICAL)

**This is a strict one-purpose app.**

clipVauLt has exactly **one job**:

> Let the user store any value and copy it to the clipboard with a single tap.

**Hard rules for development:**
- Do NOT add extra features beyond what is listed in this PRD.
- Do NOT turn this into a password manager, notes app, or productivity tool.
- Do NOT add accounts, social features, complex organization, or cloud sync in MVP.
- Every screen, button, and line of code must serve the single purpose above.
- If a feature does not directly improve “store → one-tap copy”, it is out of scope.

Any deviation from this one-purpose focus is considered a failure.

---

## 1. Product Overview

**Product Name:** clipVauLt

**One-liner:**  
A private, one-tap vault for storing any value and instantly copying it to the clipboard.

**Vision:**  
Replace the messy habit of storing passwords, codes, addresses, templates, and other frequently copied values in Notes, Notion, or random text files with a fast, secure, and intentional tool.

**Core Promise:**  
Store once → Tap once → Paste anywhere.

---

## 2. Problem Statement

People constantly need to copy the same pieces of text:
- Passwords & 2FA backup codes
- Bank account numbers / FPS IDs
- Shipping addresses
- Promo / referral codes
- API keys / tokens
- Template messages
- Wi-Fi passwords
- etc.

Current solutions (Notes, Notion, password managers, screenshots) are either too slow, too heavy, or not designed for rapid one-tap access. clipVauLt solves this with extreme simplicity and speed while remaining private and secure.

---

## 3. Goals

### Primary Goal
Make copying any stored value take ≤ 1 second from opening the app.

### Secondary Goals
- Feel faster and cleaner than Notes / Notion for this specific use case
- Be private by default (local-only, encrypted)
- Look and feel premium and trustworthy

### Success Metrics (MVP)
- Time from app open → successful copy < 1.5 seconds
- User can create and copy an item in under 10 seconds on first use
- High retention of users who store ≥ 5 items

---

## 4. Target Users

- Developers & technical people (API keys, tokens, configs)
- Freelancers / agency workers (client info, codes, templates)
- Sales / customer support (referral codes, scripts)
- Everyday power users who hate digging through Notes
- Anyone who currently stores sensitive or frequently copied text in plain notes

---

## 5. Core Features – MVP (v1.0)

### 5.1 Item Management
- Create item with:
  - Title (key / label)
  - Value (the text to copy)
  - Optional category / tag
  - Optional pin (appears at top)
- Edit item
- Delete item (with confirmation)
- Search items by title
- Filter by category
- Toggle between Grid and List view

### 5.2 One-Tap Copy
- Tapping any item immediately copies its **value** to the system clipboard
- Visual feedback (toast / haptic / brief highlight)
- Optional: show “Copied!” with the title

### 5.3 Security (Critical)
- App lock with Face ID / Touch ID / Device PIN
- All values encrypted at rest (AES-256)
- Local storage only (no cloud in MVP)
- Optional: auto-clear clipboard after X seconds (user setting)

### 5.4 Basic Organization
- Categories (user-created)
- Pinned items section
- Recently copied section (last 5–10)

### 5.5 Settings
- Biometric lock on/off
- Default view (Grid / List)
- Clipboard auto-clear timeout
- App theme (System / Light / Dark)
- Export all data (encrypted or plain text)

---

## 6. Privacy & Sync Strategy

**Core Principle:**  
Users must never feel that their passwords or private values are being sent to *our* servers.

### Phase 1 – MVP
- 100% local storage
- All values encrypted on device (AES-256)
- No accounts, no cloud, no sync
- Highest possible trust

### Phase 2 – Optional iCloud Sync
- Toggle: “Sync with iCloud”
- Use Apple CloudKit (private database)
- Data stays inside the user’s own iCloud account
- clipVauLt never sees the values
- Clear messaging: “Your data only goes to *your* iCloud account, never to us.”

### Phase 3 – Future
- Optional zero-knowledge encrypted sync for Android users

**Rejected:**
- Plain backend sync without client-side encryption
- Forcing account creation just to sync

---

## 7. User Flows (MVP)

### First Launch
1. Onboarding (2–3 screens max)
2. Optional biometric setup
3. Empty state with clear CTA: “Add your first item”

### Create Item
1. Tap + button
2. Enter Title + Value
3. Optional category
4. Save → back to main screen

### Copy Value
1. Open app (biometric if enabled)
2. Tap any item
3. Instant copy + feedback

### Edit / Delete
- Long press or swipe, or detail view

---

## 8. Non-Functional Requirements

| Area              | Requirement                                      |
|-------------------|--------------------------------------------------|
| Platform          | iOS + Android (Flutter)                          |
| Offline           | Fully offline                                    |
| Performance       | App open → ready to tap < 800ms                  |
| Security          | AES-256 encryption at rest, biometric lock       |
| Privacy           | No analytics that send values, no accounts       |
| Accessibility     | Dynamic type, VoiceOver / TalkBack support       |
| Localization     | English + Traditional Chinese (zh-Hant)          |

---

## 9. UI / UX Principles

- Extremely clean and minimal
- High contrast and readable
- Large tap targets
- Immediate feedback on every action
- Helpful empty states
- Zero visual clutter

**Visual Direction**
- Strong dark mode support
- Soft rounded cards
- Trustworthy accent color (deep blue / teal / soft purple)

---

## 10. Technical Recommendations

**Stack**
- Flutter
- Local DB: `hive` or `isar` + encryption
- Secure key storage: `flutter_secure_storage`
- Biometrics: `local_auth`
- Clipboard: `clipboard` or `super_clipboard`
- State management: Riverpod or Bloc

**Data Model**

```dart
class ClipItem {
  String id;
  String title;
  String value;          // encrypted
  String? categoryId;
  bool isPinned;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastCopiedAt;
}
