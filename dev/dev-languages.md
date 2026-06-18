---
title: i18n — Language Support
caption: NbWeb.t() locale system — adding and switching UI languages
processed: true
toc: true
---

# Internationalization (i18n)

nb-web ships with a lightweight locale system that translates all UI chrome — buttons, tooltips, placeholders, status messages, dialog labels — without a build step or framework.

> **नमस्ते!** nb-web अब हिंदी में भी बोलता है। `lang: hi` सेट करें और पूरा इंटरफ़ेस हिंदी में आ जाएगा — शॉट लिस्ट से लेकर सिंक बटन तक।

---

## Architecture

Three pieces work together:

| Component | File | Role |
|-----------|------|------|
| `NbWeb.loadLocale()` | `nbweb.js` | Fetches locale JSON, caches in module-level `_locale` |
| `NbWeb.t(key)` | `nbweb.js` | Looks up `_locale[key] ?? key` — safe fallback to key |
| `NbWeb.applyI18n(root?)` | `nbweb.js` | Scans DOM for `data-i18n` / `data-i18n-title`, applies strings |
| `GET /api/locale` | `app.py` | Reads `lang:` from `nb-settings.json`, serves `locales/<lang>.json` |
| `locales/en.json` | `locales/` | English strings (source of truth) |
| `locales/hi.json` | `locales/` | Hindi translations |

---

## Load sequence

```javascript
// DOMContentLoaded in main.js — locale loads FIRST, before plugins or UI
await NbWeb.loadLocale();   // fetches /api/locale → populates _locale
NbWeb.applyI18n();          // translates all [data-i18n] elements in index.html
await NbWeb._loadPlugins();
await NbWeb._init();
NbMain.init();
```

Because `loadLocale()` is awaited before any rendering, strings are always in the active language on first paint. No flicker, no placeholder → translation swap.

---

## Using `_t()` in JS

Every IIFE that needs translated strings aliases `NbWeb.t` locally:

```javascript
const _t = (key) => NbWeb.t(key);

// Then use like any string:
saveBtn.textContent = _t('btn_save');
sb.textContent      = _t('status_saving');
err.textContent     = _t('msg_wrong_pw');
```

This is a getter-style alias (not `const _t = NbWeb.t`) so it always reads the live `_locale` object — safe even if called early in init before the locale fetch resolves (falls back to the key string).

---

## Marking static HTML

Elements in `index.html` use `data-i18n` attributes. `applyI18n()` translates them on load:

```html
<!-- Text content -->
<button data-i18n="btn_save">Save</button>

<!-- Placeholder (input/textarea) -->
<input data-i18n="input_search" placeholder="search…">

<!-- Title/tooltip -->
<button data-i18n-title="tip_extras" title="Show/hide extras…">◉</button>

<!-- Both text and title -->
<button data-i18n="btn_changes" data-i18n-title="tip_changes">Changes</button>
```

The English text in the HTML is the hard-coded fallback — visible if JS hasn't run yet.

---

## Locale file format

`locales/en.json` is the source of truth. Every key must exist in `en.json`; other languages only need to cover what they translate (missing keys fall back to the key string itself, but in practice all 86 keys are present).

```json
{
  "_lang": "en",
  "_name": "English",
  "_dir": "ltr",

  "btn_save":         "Save",
  "btn_cancel":       "Cancel",
  "status_saving":    "Saving…",
  "msg_no_items":     "No items found.",
  "tip_extras":       "Show/hide extras — press . to toggle"
}
```

**Key naming conventions:**

| Prefix | Used for |
|--------|---------|
| `btn_` | Button labels (`btn_save`, `btn_done`, `btn_sync_now`) |
| `status_` | Transient state text (`status_saving`, `status_loading`) |
| `label_` | Form/section labels (`label_history`, `label_folders`) |
| `msg_` | Messages, empty states, confirmations |
| `input_` | Placeholder text for inputs |
| `tip_` | Tooltip / title attribute strings |

---

## Switching language

**Via `nb-settings.json`** (admin, persistent):

```json
{ "lang": "hi" }
```

Reload the page — the new locale is fetched fresh on every load.

**Via API** (can be wired to a settings UI):

```bash
curl -X PATCH http://localhost:5001/api/nb-settings \
     -H 'Content-Type: application/json' \
     -d '{"lang": "hi"}'
```

`lang` is validated and coerced by `_SETTINGS_SCHEMA`. Unknown language codes fall back to `en.json`.

---

## Adding a new language

1. Copy `locales/en.json` → `locales/<code>.json` (BCP 47 code: `fr`, `es`, `pt-BR`, `ur`, …)
2. Update `_lang`, `_name`, `_dir` metadata fields
3. Translate all 86 string values
4. Set `"lang": "<code>"` in `nb-settings.json`

For RTL languages (Arabic `ar`, Urdu `ur`): set `"_dir": "rtl"` — `applyI18n()` sets `document.documentElement.dir` automatically. CSS layout may need review for RTL flow.

---

## Coverage (86 keys)

All user-visible chrome is covered:

- **Static HTML** — all buttons and inputs in `index.html` via `data-i18n`
- **main.js** — 52 `_t()` calls: editor save/cancel, history panel, commit picker, annotation editor, template empty state, notebook list, lock/unlock buttons, status dots
- **nav.js** — 21 `_t()` calls: add-note form save/cancel, sync dialog (Sync Now, Retry, Connecting…, status messages), daily "today" label, grep run button
- **nbweb-codeblocks.js** — front-changes codeblock save/cancel

Error messages embedded in `alert()` calls and server-returned text are **not** translated (server errors are in English; translating alert strings is deferred).

---

## Files

```
locales/
  en.json        ← source of truth (86 keys)
  hi.json        ← हिन्दी (86 keys)
nbweb.js         ← NbWeb.t / loadLocale / applyI18n
app.py           ← GET /api/locale + lang in _SETTINGS_SCHEMA
index.html       ← data-i18n / data-i18n-title attributes
main.js          ← _t() alias + 52 usages
nav.js           ← _t() alias + 21 usages
plugins/nbweb-codeblocks.js  ← _t() in front-changes form
```
