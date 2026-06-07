---
title: TEMPLATES
caption: Creating, using, and managing note templates in nb-web
---

# Templates

[[#Storage|Storage]] · [[#Placeholders|Placeholders]] · [[#Using Templates|Using Templates]] · [[#Saving a Note as a Template|Saving a Note as a Template]] · [[#Default Template per Notebook|Default Template per Notebook]]

---

## Storage

Templates are plain Markdown files stored in `.templates/` directories. nb-web merges both scopes and shows them in the **Template** picker in the Add bar.

| Location | Scope |
|----------|-------|
| `~/.nb/.templates/` | Global — available in all notebooks |
| `~/.nb/<notebook>/.templates/` | Local — that notebook only; overrides a global template of the same name |

---

## Placeholders

Templates use `{{placeholder}}` syntax, substituted at note-creation time.

| Placeholder | Resolves to |
|-------------|-------------|
| `{{title}}` | Note title (from the Title field) |
| `{{tags}}` | Hashtag list (from the Tags field) |
| `{{content}}` | Body text (from the Content field) |
| `{{date}}` | `YYYY-MM-DD` |
| `{{day}}` | `Saturday, May 9, 2026` |
| `{{time}}` | `HH:MM` |
| `{{weather}}` | wttr.in one-liner (fetched lazily, cached 1 h) |
| `$(command)` | Any shell command substitution |

Templates are processed as Bash strings with `eval` — arbitrary shell expressions are valid. Keep template files trusted; don't use templates from untrusted sources.

### Starter template: `dated-note`

`~/.nb/.templates/dated-note.md` ships as a ready-to-use global template:

```markdown
# {{title}}

**Date:** {{date}}
**Tags:** {{tags}}

---

{{content}}
```

---

## Using Templates

The **Template** picker appears in the Add opts bar when the note type is *note* or *todo*. Select a template to load a read-only preview of its raw content in the preview pane — confirming you have the right one before committing.

Once selected, the 📋 button lights up in the opts bar. Click it to browse all templates or revert to a blank note.

---

## Saving a Note as a Template

Open any note → **☰** (note menu) → **Save as template…**

A bar appears below the toolbar where you name the template and choose scope:

- **Notebook** — saves to `~/.nb/<current-notebook>/.templates/`
- **Global** — saves to `~/.nb/.templates/`

The note's raw Markdown is saved as-is, including any existing placeholders, so you can iterate on a template by editing it in nb-web and re-saving.

---

## Default Template per Notebook

If a notebook's local `.templates/` directory contains **exactly one** template, nb-web treats it as that notebook's default and pre-applies it automatically whenever you open **Add** while that notebook is active.

When two or more local templates exist, auto-apply is suppressed and you pick manually.

### Setting a default from the Templates view

Open **Menu → Templates**, select any template, then use the notebook selector and **📌 Set default** button in the preview footer. This copies the template into `~/.nb/<notebook>/.templates/`, making it the auto-default (or one of the picker options if others already exist there).

### Example: contacts notebook

Place a single contact template at `~/.nb/contacts/.templates/contact.md`. Every time you open **Add** while the contacts notebook is active, nb-web silently pre-applies it — just type the contact's name and press Save.

See [[NOTEBOOKS]] → Defaults for how template defaults interact with per-notebook sort and list-type settings.
