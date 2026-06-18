---
title: Languages
caption: Changing the nb-web interface language
processed: true
---

# Languages

nb-web's interface can be displayed in different languages. All buttons, labels, tooltips, and messages switch at once.

> **नमस्ते!** nb-web हिंदी में भी बोलता है।

## Switching language

Open `nb-settings.json` in the nb-web directory and set the `lang` key:

```json
{
  "lang": "hi"
}
```

Restart nb-web. The full interface — shot lists, sync dialogs, editor buttons, menus — will appear in the selected language.

## Available languages

| Code | Language |
|------|----------|
| `en` | English (default) |
| `hi` | हिंदी (Hindi) |

## Adding a language

Copy `locales/en.json` to `locales/<code>.json` and translate the values. The keys must stay in English — only the values change. Set `"_lang"` to your language code, `"_name"` to the language's own name, and `"_dir"` to `"rtl"` for right-to-left scripts.

Then set `"lang": "<code>"` in `nb-settings.json` and restart.

See [[dev-languages]] for the full developer reference.
