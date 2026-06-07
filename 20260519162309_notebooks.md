---
title: NOTEBOOKS
caption: Creating, managing, wiring, and removing notebooks
---

# Notebooks

[[#The Notebook Model|The Notebook Model]] · [[#Notebook List|Notebook List]] · [[#Notebook Detail|Notebook Detail]] · [[#Defaults|Defaults]] · [[#Sync and Git|Sync and Git]] · [[#Danger Zone|Danger Zone]]

---

## The Notebook Model

Each nb notebook is a plain directory under `~/.nb/` — its own self-contained git repo, with notes as Markdown files tracked by an `.index` file.

```
~/.nb/
  home/       ← default notebook
    .git/
    .index
    note1.md
    note2.md
  work/
    .git/
    .index
    …
```

Notes are real files. You can open, copy, edit, and script them directly from the terminal at any time — nb-web never locks them. Every edit (whether from nb-web or the CLI) is auto-committed by nb with a message like `[nb] Edit: filename.md`.

---

## Notebook List

**Menu → Notebooks** opens the notebook management view. The left pane lists all notebooks with:

- Note count
- Last-modified age
- Sync status badge: `synced` (green), `N unpushed` (yellow), `not wired`, or `no git`

Click any notebook to open its detail panel.

The list can be sorted: **active first** (default — current notebook at top) or **A→Z**. The sort button in the toolbar lights up when you've diverged from the default.

---

## Notebook Detail

Clicking a notebook opens a detail panel with everything you need to inspect and manage it.

### Info

| Field | What it shows |
|-------|--------------|
| Notes | Total note count |
| Path | Absolute path on disk (`~/.nb/<name>/`) |
| Branch | Current git branch (always `master` for nb notebooks) |
| Remote | Configured remote URL, or *not wired* |
| Last commit | Short hash · subject · age |
| Folders | Sub-folders that have an `.index` file |

### Actions

Two mutually exclusive action buttons appear depending on git state:

- **Wire remote** — appears when the notebook has a git repo but no remote configured. Opens the wire form (see [[#Sync and Git|Sync and Git]]).
- **Sync** — appears when a remote is already wired. Opens the sync dialog for this notebook.

### Plugin sections

Active plugins can contribute additional sections here. For example, **NbWeb-archive** adds an **Archive** section with a **↓ Archive notebook** button. See [[PLUGINS]] for details.

### Use this notebook

Sets this notebook as the active scope for the List, Add, Search, and other commands — equivalent to `nb use <name>` from the CLI.

---

## Defaults

Each notebook can have its own defaults for how notes are listed and created. These are saved to `nb-settings.json` and restored every time you switch to that notebook.

| Default | Options | Effect |
|---------|---------|--------|
| **Sort** | default, a→z, z→a, newest, oldest | Pre-selects the sort order for the note list |
| **Type** | all, note, bookmark, todo, contact, folder, image | Pre-filters the list to that note type |
| **Template** | any installed template | Pre-applies a template when adding a new note |

Plugins can contribute additional defaults rows to this panel (e.g., NbWeb-contacts adds a **List type** option when a contacts notebook is active).

Click **Save defaults** to persist. Changes take effect immediately on the next notebook switch.

> **Tip:** setting a notebook's template default to a single local template is the recommended way to give a notebook a fixed structure — see [[TEMPLATES]] for the folder-local template pattern.

---

## Sync and Git

nb-web uses a **one-repo, branch-per-notebook** model: all notebooks share one remote repository; each maps to a branch named after it.

### Wiring a notebook

A notebook that has a local git repo but no remote shows a **Wire remote** button. Clicking it reveals the wire form:

1. Paste a remote URL (SSH preferred), or leave blank to use the default from **Settings → Git**.
2. Click **Wire** — adds the remote, pushes the notebook's commits to a branch named after it, and configures git tracking.

If you don't yet have a remote repo, expand **Create a new separate GitHub repo instead…** and choose Private or Public, then **Create & Wire**. This requires a `gh` (GitHub CLI) token configured on the server.

**Wire all at once:** **☰ → Git → wire remotes** wires every notebook that lacks a remote in one operation, using the default remote URL from Settings.

### Syncing

Once wired, the **Sync** button opens the sync dialog:

- **Status** — lists uncommitted files and unpushed commit count; "Up to date" when nothing is pending
- **Commit message** — optional; creates a labelled commit before syncing (useful for annotating a batch of auto-commits)
- **Sync Now** — full two-way cycle: auto-commit pending changes → `git pull` (merge remote edits) → `git push` to the notebook's branch
- **Show Log** — shows the last 30 commits inline without closing the dialog

The **sync** menu item shows a live badge (updated every 60 s) so you can see pending changes at a glance without opening the dialog.

---

## Danger Zone

At the bottom of each notebook's detail panel. Two separate actions:

**Delete local notebook** — removes `~/.nb/<name>/` from this machine. Does not touch the remote. Type the notebook name to confirm. If there are unpushed commits, the count is shown as a warning — archive first if those commits matter.

**Delete remote branch** — removes the notebook's branch from the remote repository. Does not touch the local copy. Type the notebook name to confirm. Use this when you want to stop syncing a notebook without deleting local notes.

> Both actions are irreversible. Archive the notebook first (see [[Import / Export]]) if you might want it back.

---

## Creating a notebook

New notebooks can be created directly from nb-web: open the **Add** bar, select **📒 Notebook** from the type picker, type the name, and confirm. Equivalent to the CLI:

```bash
nb notebooks add <name>
```

The new notebook appears in the list immediately. Wire a remote from the detail panel if you want to sync it.
