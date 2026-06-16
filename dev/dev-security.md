---
title: security
caption: "Auth scheme: session login, user cards, access levels, notebook config, nb-auth.js frontend module, config repo"
toc: true
processed: true
---

# SECURITY

> Developer documentation for nb-web. See [[docs:DEVELOPERS.md]] for the full index.

nb-web's security scheme is intentionally minimal: Flask sessions, Markdown user cards, and level-based guards on both Flask routes and JS UI. No external auth libraries, no database, no tokens.

```
Browser → /login (POST credentials)
        → Flask checks ~/.nb/.users/<username>.md
        → password_hash compared via werkzeug.security
        → session['user'] = {username, name, level, notebooks}
        → all subsequent requests checked by before_request
        → per-request: notebook config + note frontmatter determine visibility
```

---

## I. Server

Flask handles login at `/login` (self-contained HTML, no external assets), sets a signed session cookie via `.flask_secret`, and gates every request through `_check_auth()` — unauthenticated `/api/*` returns `401 JSON`, page requests redirect to `/login`. The `/api/me` endpoint exposes the current user's public fields for frontend use. Dotfolder virtual notebooks (`.users`, `.tools`, etc.) are served via direct filesystem I/O for `admin`/`tech` users. The `~/.nb/` root git repo (config repo) tracks dotfolders and global templates; `settings.html` provides a commit/sync UI for it. `nb-auth.js` is the shared frontend module — see [Frontend auth](#frontend-auth-nb-authjs).

> Full detail for this section is planned — login flow, `_check_auth()`, `/api/me`, dotfolder CRUD, config repo API, `nb-auth.js`.

---

## II. Access Control

### Access levels

```
guest < user < office < admin < tech
```

| Level | Can do |
|-------|--------|
| `guest` | See only notes/notebooks with `access: guest` explicitly set |
| `user` | Read notes in their notebook list |
| `office` | Read + write notes in their notebook list |
| `admin` | Everything office can do + access dotfolder notebooks |
| `tech` | Full access; manages users and settings |

Checked by `_level_gte(have, need)` in `app.py` — compares index positions in `LEVELS = ['guest', 'user', 'office', 'admin', 'tech']`.

---

### User cards

Users are `.md` files in `~/.nb/.users/`. This is a **dotfolder** — not indexed by nb, not published by Quartz, not shown to regular users.

```
~/.nb/.users/
    djp.md
    lena.md
    guest.md
```

Each file is standard nb-web Markdown with YAML frontmatter:

```yaml
---
name: djp
level: tech
password_hash: scrypt:32768:8:1$...(werkzeug hash)...
notebooks: [home, docs, accts, hledger, work, friends]
---
```

**Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Display name shown in UI |
| `level` | yes | Access level — one of `guest`, `user`, `office`, `admin`, `tech` |
| `password_hash` | yes | werkzeug `generate_password_hash()` output |
| `notebooks` | no | List of notebooks this user may access (empty = all) |

**Creating a user:**

```python
from werkzeug.security import generate_password_hash
print(generate_password_hash('password'))
```

Paste the output into the `password_hash:` field. The username is the filename stem (e.g. `djp.md` → username `djp`).

---

### Access control resolution

Visibility of a note is determined by resolving an **effective access level** and comparing it to the current user's level. Most specific wins:

```
note frontmatter access:  → overrides everything (explicit)
note frontmatter user:    → inherits that user's level from their card
notebook config access:   → default for all notes in the notebook
system default:           → 'user'  (guests see nothing unless explicitly granted)
```

Implemented in `_effective_access(note_meta, nb_meta)`:

```python
def _effective_access(note_meta, nb_meta):
    if note_meta.get('access'):
        return str(note_meta['access'])
    if note_meta.get('user'):
        card = _load_user(str(note_meta['user']))
        if card:
            return card.get('level', 'user')
    return str(nb_meta.get('access') or 'user')
```

`access:` is a **floor** — `access: guest` means guest-and-above can see it; `access: admin` means admin/tech only. It is typically used as a downgrade (opening notes to lower levels) but can also restrict upward.

**`user:` shorthand** — instead of knowing or typing a level string, declare ownership: `user: djp` makes the note as private as djp's user card level. If djp is `tech`, the note requires tech. Useful for personal notes in shared notebooks. `access:` always wins if both are present; unknown `user:` values fall through gracefully to the notebook/system default.

Also a search field: `nb g "user: djp"` finds every note you've claimed.

**Where filtering is applied:**

| Location | Behaviour |
|----------|-----------|
| `_list_notes()` | Notebook config read once; each note's meta checked; inaccessible notes silently skipped |
| `GET /api/note` | 403 returned if user level < effective access |
| `GET /api/notebooks` | Notebooks filtered by config access before being returned |
| `GET /api/nb/notebooks` | Same |

---

### Notebook config file

Each notebook can have a hidden config file at its root:

```
~/.nb/home/.home.md
~/.nb/docs/.docs.md
~/.nb/accts/.accts.md
```

The naming convention is `.<notebook-name>.md`. The file is a dotfile so nb does not index or publish it. Edit it in nb-web via Menu → Notebooks → ⚙ Configure notebook.

**Example** — open a notebook to guest access:

```yaml
---
access: guest
---
```

**Example** — restrict a notebook to admin and above:

```yaml
---
access: admin
---
```

Without a config file (or without an `access:` field), the notebook defaults to `user` level — guests cannot see it.

Implemented in `_notebook_config(notebook)` which reads and parses frontmatter from the config file, returning `{}` if it doesn't exist.

> The notebook config file is set to become the home for much more than access control — themes, icons, list defaults, plugin config, UI flags. See [[docs:dev/dev-notebook-config.md]].

---

### Per-note `access:` frontmatter

Any note can declare its own access level, overriding the notebook default:

```yaml
---
title: Public announcement
access: guest
---
```

```yaml
---
title: Payroll records
access: admin
---
```

The note-level field always wins over the notebook config. This lets you open individual notes to guests within a `user`-level notebook, or lock down sensitive notes in an otherwise open one.

---

### Guest access pattern

A typical guest setup:

1. Create `~/.nb/.users/guest.md` with `level: guest` and a shared password
2. Create `~/.nb/home/.home.md` with `access: guest` to open the whole home notebook, **or**
3. Add `access: guest` to individual notes that guests should see

Guests logging in see only what's explicitly granted. Notebooks without a config file, and notes without `access:` frontmatter, are invisible to them.

---

## Frontend auth (`nb-auth.js`)

`nb-auth.js` is a shared module that gives every HTML page in nb-web user and level awareness without repeating auth logic. Load it once; use the `NbAuth` API and `data-min-level` attributes everywhere.

### How it works

The module is an async IIFE that runs immediately on load:

```
page load → <script src="/nb-auth.js">
           → IIFE runs
           → check sessionStorage for cached user
           → if not cached: fetch /api/me
               → 200 OK: cache user in sessionStorage, continue
               → 401:    redirect to /login immediately
           → window.NbUser  = { username, name, level, notebooks }
           → window.NbAuth  = { level, is, bust, applyVisibility }
           → document.dispatchEvent('nb-auth-ready')
```

The `nb-auth-ready` event fires when the API is ready. All page-specific code that needs auth should listen for it rather than running inline:

```javascript
document.addEventListener('nb-auth-ready', () => {
    NbAuth.applyVisibility();
    if (!NbAuth.is('admin')) return;
    // wire up admin-only UI...
});
```

### sessionStorage caching

`/api/me` is called **once per browser session**. The result is stored under the key `nb-auth-user` in `sessionStorage`. Subsequent page loads within the same tab session skip the network call entirely.

The cache is automatically invalidated when:
- The tab is closed (sessionStorage is per-tab)
- `NbAuth.bust()` is called (e.g. after a logout or user-level change)

### `window.NbUser`

The raw user object from `/api/me`:

```javascript
window.NbUser = {
    username:  'djp',
    name:      'djp',
    level:     'tech',
    notebooks: ['home', 'docs', 'accts']
}
```

If the fetch failed (network error, but not 401), `NbUser` is `{}` — level falls back to `'guest'`.

### `window.NbAuth` API

| Method | Returns | Description |
|--------|---------|-------------|
| `NbAuth.level()` | string | Current user's level, or `'guest'` if unknown |
| `NbAuth.is(lvl)` | boolean | True if current user's level ≥ `lvl` |
| `NbAuth.bust()` | void | Clears the sessionStorage cache |
| `NbAuth.applyVisibility()` | void | Shows/hides `[data-min-level]` elements |

`NbAuth.is()` uses index comparison against `['guest', 'user', 'office', 'admin', 'tech']` — same logic as `_level_gte()` on the backend.

---

### `data-min-level` pattern

Any HTML element can declare its minimum required access level:

```html
<section id="sec-config-repo" data-min-level="admin">
  <!-- only shown to admin and tech users -->
</section>

<button id="btn-user-mgmt" data-min-level="tech">
  Manage users
</button>
```

`NbAuth.applyVisibility()` queries all `[data-min-level]` elements and sets `el.hidden = !NbAuth.is(el.dataset.minLevel)`. Elements are hidden by default in HTML (`hidden` attribute); `applyVisibility()` unhides the ones the current user can see.

### Adding auth awareness to a new HTML page

Two steps:

**1. Load the module in `<head>`:**

```html
<script src="/nb-auth.js"></script>
```

**2. Gate your UI on `nb-auth-ready`:**

```html
<script>
document.addEventListener('nb-auth-ready', () => {
    NbAuth.applyVisibility();           // handles data-min-level attributes
    if (!NbAuth.is('office')) return;   // optional: bail early by level
    initMyPageUI();
});
</script>
```

Mark sections with `data-min-level` and add the initial `hidden` attribute:

```html
<section hidden data-min-level="admin">...</section>
```

---

## Config repo

All nb notebooks (`home`, `docs`, etc.) are separate git repos inside `~/.nb/`. The **dotfolders** and **global templates** are tracked by the `~/.nb/` root repo instead.

### What's tracked

```
~/.nb/
├── .git/                     ← the config repo
├── .gitignore                ← excludes notebook dirs
├── .users/
├── .tools/
├── .changes/
├── .images/
├── .rules/
└── .templates/
```

### `.gitignore` strategy

```gitignore
/[a-zA-Z]*/        ← all notebook dirs (each is its own repo)
/.cache/
/.current
/copy
/.plugins/
/.test/
/.web/
/.export.template.html
```

Push to a **private** remote — user cards contain password hashes. Configure via Settings → Config repo.

### API endpoints (admin+ only)

| Endpoint | Method | What it does |
|----------|--------|-------------|
| `/api/nb-config/status` | GET | Uncommitted files, remote, last commit, unpushed count |
| `/api/nb-config/commit` | POST | Stage dotfolders + templates, commit with message |
| `/api/nb-config/sync` | POST | `git pull --no-edit` then `git push origin HEAD:master` |
| `/api/nb-config/remote` | GET/POST | Read or set the origin URL |
| `/api/nb-config/log` | GET | Last 20 commits (`git log --oneline -20`) |

No auto-commit on dotfolder writes — commit from Settings → Config repo when ready.

---

## Planned

- `/setup` first-run route
- Backend notebook ACL enforcement for `notebooks:` user card field (currently frontend-only)
- User management UI in Settings menu (admin/tech only)
- CSRF token middleware
- Per-notebook write locks (separate from the existing `.nb-lock` read-only lock)
- `access:` enforcement on write endpoints (PUT/POST/DELETE)
- Expand Section I (Server) with full Flask session, login flow, dotfolder CRUD detail
