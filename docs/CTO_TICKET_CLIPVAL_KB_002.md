# CTO Ticket — ClipVal Keyboard “Open app” button no-op

**ID:** CLIPVAL-KB-002  
**Status:** Done (PR open-app + brand mark)  
**Desk:** CTO · WY  
**Product:** clipval.app — Custom Keyboard extension  
**Severity:** Medium (UX dead control; vault insert still works)  
**Created:** 2026-08-11  
**From:** CEO screenshot (WhatsApp + ClipVal keyboard)

---

## What is this button?

| | |
|--|--|
| **UI** | ClipVal **custom keyboard** header (not WhatsApp chrome) |
| **Icon** | SF Symbol `arrow.up.forward.app` (square with arrow up-right) |
| **Position** | Top-right of ClipVal panel, left of grid-layout · search |
| **a11y** | `"Open ClipVal"` |
| **Intent** | Leave keyboard → open main app at `clipval://vault` |

Screenshot context: WhatsApp chat composer; ClipVal keyboard open showing tiles (TGT en, 八達通手仔, …). Red circle = this control.

---

## Code
`ios/ClipValKeyboard/KeyboardViewController.swift`

```swift
// header
appBtn.setImage(UIImage(systemName: "arrow.up.forward.app"), for: .normal)
appBtn.accessibilityLabel = "Open ClipVal"
appBtn.addTarget(self, action: #selector(tapOpenApp), for: .touchUpInside)

@objc private func tapOpenApp() {
  UIImpactFeedbackGenerator(style: .light).impactOccurred()
  if mode == .needsFullAccess {
    flash("Enable Full Access first")
    return
  }
  openURL(URL(string: "clipval://vault")!) { ok in
    if !ok { self.flash("Open ClipVal from Home") }
  }
}

private func openURL(_ url: URL, completion: ((Bool) -> Void)? = nil) {
  var responder: UIResponder? = self
  let selOpen = sel_registerName("openURL:")  // legacy selector walk
  while let r = responder {
    if r.responds(to: selOpen) {
      r.perform(selOpen, with: url)
      completion?(true)  // ⚠️ assumes success — may be silent no-op
      return
    }
    responder = r.next
  }
  if let ctx = extensionContext {
    ctx.open(url) { ok in DispatchQueue.main.async { completion?(ok) } }
    return
  }
  completion?(false)
}
```

Same `openURL` used by primary CTA when not in “retry” tag mode.

---

## Why “click → no reaction” (likely)

1. **Keyboard extension openURL is flaky on modern iOS**  
   - Responder-chain `openURL:` is deprecated / often doesn’t actually open host app.  
   - Code still calls `completion?(true)` after `perform`, so **no toast** even when nothing happened.

2. **Full Access**  
   - If `.needsFullAccess`, should flash “Enable Full Access first”.  
   - CEO saw **no reaction** → either not in that mode, or flash/haptics too easy to miss, or hit path that fakes success.

3. **URL scheme / host app**  
   - Must handle `clipval://vault` in main app. If scheme missing in some build flavor, open fails.

4. **iOS policy**  
   - Opening host app from keyboard may require Full Access + valid `extensionContext.open`.

---

## Repro
1. WhatsApp (or any app) → switch keyboard to ClipVal  
2. Tap header **arrow.up.forward.app**  
3. Expected: ClipVal app opens vault  
4. Actual: nothing (CEO report)

---

## Fix direction (CTO)
- [x] Prefer `extensionContext?.open(url)` first; don’t trust legacy `openURL:` success  
- [x] Only `completion(true)` when completion handler reports true  
- [x] Always user-visible feedback: toast on fail **and** on ambiguous  
- [x] Verify `clipval` URL scheme + Flutter/iOS deep link to vault  
- [ ] Document: Full Access required to open app from keyboard (if still true)  
- [ ] Optional: if open unsupported, hide button or show “Open ClipVal from Home” permanently  

## Related
- Share extension also opens URL (`ClipValShare/ShareViewController.swift`) — audit same pattern  
- CLIPVAL-CK-001 iCloud resolved (separate)

## Done when
- Tap Open app from keyboard reliably opens ClipVal **or** clear flash why not  
- No silent success path
