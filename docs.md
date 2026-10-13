---
type: dashboard
draft: true
access: guest
pinned: true
date: 2026-07-15
nav: .
---
# docs Dashboard
{{nb: count docs:}} notes · {{date: %A %B %d}} - {{time}}
- The docs: notebook is the information station. 
- Click the NAV bar above to see a listing.
---

## Review

Every doc is in one of three states: 📘 `type: topic` (converted to the layered help format),
📃 `type: doc` (checked against the code, with a `reviewed:` date), or no type (not reviewed yet,
possibly out of date). Mark a doc `type: doc` and set `reviewed:` whenever you check one.

{{fm: count docs type:topic}} topics · {{fm: count docs type:doc}} docs · {{fm: count docs -type:topic -type:doc -type:dashboard -type:dotfile -type:reports}} not reviewed

```fm
docs -type:topic -type:doc -type:dashboard -type:dotfile -type:reports
```

Reviewed longest ago:

```fm
docs type:doc sort:reviewed
```

---

## Links

<!-- key notes, related notebooks -->
