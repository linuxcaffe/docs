---
title: ADD NOTEBOOK
caption: Creating a new notebook — admin-only, seeds dashboard and config in one step
toc: true
processed: true
---

# Add Notebook

[[#How to Add a Notebook|How to Add a Notebook]] · [[#What Gets Created|What Gets Created]] · [[#After Creation|After Creation]]

---

Adding a notebook is an admin-only operation. It creates the notebook and seeds a ready-to-use dashboard/config pair in one step — no manual file setup needed.

---

## How to Add a Notebook

1. Click the **Add** button in the top toolbar
2. Select the **📒 Notebook** chip from the type row
3. Type the notebook name in the **Notebook name…** field
   - Use letters, numbers, and hyphens — spaces are replaced with underscores automatically
4. Press **Enter** or click **Save**

The new notebook appears immediately in the scope selector. nb-web navigates directly to the new notebook's dashboard note.

> **Admin only.** The Notebook chip in the scope selector is not rendered for non-admin users — it simply isn't there.

---

## What Gets Created

Three things are created in one step:

| Item | What it is |
|------|-----------|
| `{name}/` | The notebook directory, initialised as a git repo by nb |
| `{name}.md` | Dashboard note (`type: dashboard`) — visible, pinned front-of-house |
| `.{name}.md` | Config dotfile (`type: dotfile`) — hidden, carries access and constraints |

Both notes are seeded from global templates in `~/.nb/.templates/`:

| Template | Seeded as |
|----------|----------|
| `notebook-dashboard.md` | `{name}.md` |
| `notebook-config.md` | `.{name}.md` |

If a template file doesn't exist, that file is simply not seeded — the notebook is still created. The seeded files are indexed and committed to git automatically.

The dashboard and config are a matched pair — the dashboard links to the config, the config links back to the dashboard. See [[docs:TYPED-NOTES]] for what each header renders, and [[docs:FOLDER-CONFIG]] for the config schema.

---

## After Creation

Once the notebook exists, typical next steps:

**Wire to a remote** — open **Menu → Notebooks**, select the new notebook, and click **Wire remote** to connect it to a GitHub branch for sync. See [[docs:SYNC]].

**Set access** — edit the config dotfile (`.{name}.md`) and add an `access:` line to restrict who can see the notebook's notes. The config's `access:` value is the minimum level required.

**Add folder structure** — use the Add button with the 📂 Folder type to create subfolders. Each folder can have its own config dotfile for finer-grained control.

**Seed singleton templates** — in the Notebooks panel, the Configure Notebook section shows which singleton templates haven't been seeded yet. Click the seed button next to each one to initialise them.

**Customise the dashboard** — edit `{name}.md` to add `cfg: .` and `nav:` codeblocks, live queries, and links relevant to this notebook's purpose.
