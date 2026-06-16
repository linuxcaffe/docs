---
title: security
caption: "Auth scheme: session login, user cards, access levels, notebook config, nb-auth.js frontend module, config repo"
toc: true
processed: true
---

# SECURITY

> Developer documentation for nb-web. See [[docs:DEVELOPERS]] for the full index.

nb-web's security scheme is intentionally minimal: Flask sessions, Markdown user cards, and level-based guards on both Flask routes and JS UI. No external auth libraries, no database, no tokens.

---

## Overview

```
Browser → /login (POST credentials)
        → Flask checks ~/.nb/.users/<username>.md
        → password_hash compared via werkzeug.security
        → session['user'] = {username, name, level, notebooks}
        → all subsequent requests checked by before_request
        → per-request: notebook config + note frontmatter determine visibility
```

Every request (including `/api/*` and static files) passes through `_check_auth()`. Unauthenticated API calls get `401 JSON`; unauthenticated page requests redirect to `/login`.

---

## Access levels

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

## User cards

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

## Access control resolution

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

**Where filtering is applied:**

| Location | Behaviour |
|----------|-----------|
| `_list_notes()` | Notebook config read once; each note's meta checked; inaccessible notes silently skipped |
| `GET /api/note` | 403 returned if user level < effective access |
| `GET /api/notebooks` | Notebooks filtered by config access before being returned |
| `GET /api/nb/notebooks` | Same |

---

## Notebook config file

Each notebook can have a hidden config file at its root:

```
~/.nb/home/.home.md
~/.nb/docs/.docs.md
~/.nb/accts/.accts.md
```

The naming convention is `.<notebook-name>.md`. The file is a dotfile so nb does not index or publish it.

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

---

## Per-note `access:` frontmatter

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

## Guest access pattern

A typical guest setup:

1. Create `~/.nb/.users/guest.md` with `level: guest` and a shared password
2. Create `~/.nb/home/.home.md` with `access: guest` to open the whole home notebook, **or**
3. Add `access: guest` to individual notes that guests should see

Guests logging in see only what's explicitly granted. Notebooks without a config file, and notes without `access:` frontmatter, are invisible to them.

---

## Flask session

`app.secret_key` is loaded from `.flask_secret` (alongside `app.py`), auto-generated with `secrets.token_hex(32)` on first run, `chmod 600`. Sessions are server-signed cookies — no session store needed.

`_check_auth()` is registered via `@app.before_request`. Exempt paths: `/login`, `/logout`, `/setup`.

```python
@app.before_request
def _check_auth():
    if request.path in ('/login', '/logout', '/setup'):
        return
    if not session.get('user'):
        if request.path.startswith('/api/') or request.path.startswith('/ws'):
            return jsonify(error='Authentication required'), 401
        return redirect('/login')
```

---

## `/api/me`

Returns the current session user's public fields. Called by JS on load to gate UI elements.

```json
{
  "username": "djp",
  "name": "djp",
  "level": "tech",
  "notebooks": ["home", "docs", "accts"]
}
```

JS uses this to show/hide edit buttons, write forms, the Settings menu, and dotfolder notebooks in the scope selector.

---

## Dotfolder notebooks

`DOTFOLDERS = ['.users', '.tools', '.changes', '.images', '.rules']`

These are real directories at `~/.nb/` root, not nb notebooks (no `.git`, no `.index`). For `admin`/`tech` users they appear as virtual notebooks in the scope selector and are fully browsable and editable via nb-web.

**How they're exposed:**

| Endpoint | Behaviour |
|----------|-----------|
| `GET /api/notebooks` | Appends dotfolder names for admin+ users |
| `GET /api/nb/notebooks` | Appends dotfolder entries with `virtual: true, dot: true` |
| `GET /api/notes?notebook=.users` | `_list_dotfolder_notes()` — direct filesystem scan |
| `GET /api/note?selector=.users:djp.md` | Reads file directly, no nb CLI |
| `PUT /api/note` | Resolves `.users:djp.md` → absolute path, direct write |
| `POST /api/notes` | Creates file directly in dotfolder |
| `DELETE /api/note` | `unlink()` directly |

**Selector format:** `.users:filename.md` — dotfolder name + `:` + bare filename (no subfolders, no dotfiles).

**Path safety:** `_dot_selector_to_path()` validates: notebook must be in `DOTFOLDERS`, filename must not contain `/` or start with `.`.

No git commits are made on dotfolder writes — these folders have no `.git`.

---

## Login form

`/login` serves a self-contained HTML string (`_LOGIN_HTML` in `app.py`) with all styles inline — no external assets required, so it works before the session is established.

- GET → renders form (redirects to `/setup` if `.users/` has no `.md` files)
- POST → validates credentials, sets `session['user']`, redirects to `/`
- Failed login → 401 with error message inline in form

---

## First-run setup

`/setup` (not yet implemented) — intended for fresh installs with no users. Redirected to automatically from `/login` when `~/.nb/.users/` is empty. Will allow creating the first `tech`-level user without needing CLI access.

---

## Security notes

- **Passwords** are hashed with werkzeug's `generate_password_hash()` (scrypt by default in recent versions). Never stored in plaintext.
- **`.flask_secret`** is `chmod 600` and lives alongside `app.py` — not in `~/.nb/` and not committed to nb's git repos.
- **`.users/`** permissions: currently `755`. Consider tightening to `700` (Flask process user only) on multi-user installs.
- **Notebook ACL** (`notebooks:` field in user card) is enforced on the frontend via `/api/me` — backend route-level enforcement is planned. Dotfolder access and `access:` frontmatter filtering are enforced server-side.
- **WebSocket (`/ws`)** paths return 401 JSON when unauthenticated; the PTY terminal respects this.
- **No CSRF protection** yet — all mutating endpoints accept JSON bodies; browser same-origin policy provides partial coverage. CSRF tokens are on the roadmap for multi-user production deployments.

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

## `data-min-level` pattern

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

**Pattern for gating sections:**

```html
<!-- in <head> -->
<script src="/nb-auth.js"></script>

<!-- in <body> — hidden until auth resolves -->
<section id="sec-admin" hidden data-min-level="admin">
  ...admin-only content...
</section>

<!-- at end of <body> or in a module script -->
<script>
document.addEventListener('nb-auth-ready', () => {
    NbAuth.applyVisibility();
    // any further level checks here
});
</script>
```

If the user's level doesn't meet the section's `data-min-level`, the section stays hidden. No flash of visible content.

---

## Adding auth awareness to a new HTML page

Two steps:

**1. Load the module in `<head>`:**

```html
<script src="/nb-auth.js"></script>
```

This fires automatically — no `defer` or `async` needed (it's already async internally). It will redirect to `/login` if the session is not valid.

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

That's it. The page self-gates without any additional fetch calls.

---

## Config repo — git strategy for dotfolders

All nb notebooks (`home`, `docs`, etc.) are separate git repos inside `~/.nb/`. The **dotfolders** (`.users`, `.tools`, `.changes`, `.images`, `.rules`) and **global templates** (`~/.nb/.templates/`) are not part of any notebook repo and would otherwise be unversioned.

The solution: **the `~/.nb/` root itself is a git repo** that tracks only the non-notebook content.

### What's tracked

```
~/.nb/
├── .git/                     ← the config repo
├── .gitignore                ← excludes notebook dirs
├── .users/
│   ├── djp.md
│   └── guest.md
├── .tools/
├── .changes/
├── .images/
├── .rules/
└── .templates/
    └── daily-template.md
```

### `.gitignore` strategy

```gitignore
# Notebook directories — each is its own git repo
/[a-zA-Z]*/

# nb transient state
/.cache/
/.current
/copy

# nb internals not worth versioning
/.plugins/
/.test/
/.web/
/.export.template.html
```

The `/[a-zA-Z]*/` pattern excludes all notebook subdirectories (which start with a letter) while leaving dotfolders (`.users`, `.tools`, etc.) tracked. New notebooks added in future are excluded automatically.

### Pushing to a private remote

The config repo should push to a **private** remote (user cards contain password hashes). Set the remote URL in the admin Settings page and use the Commit/Sync controls there.

---

## Config repo API

Four endpoints, all require `admin` or `tech` level. Implemented in `app.py` using `_nb_config_git()` (a thin wrapper around `subprocess.run(['git', ...], cwd=NB_DIR)`).

### `GET /api/nb-config/status`

Returns the current state of the config repo:

```json
{
  "files":       [{"status": "M", "path": ".users/djp.md"}],
  "remote":      "git@github.com:djp/nb-config-private.git",
  "last_commit": "abc1234 Update djp user card",
  "unpushed":    2
}
```

`files` comes from `git status --porcelain`. `unpushed` is the count of commits ahead of `origin/master`.

### `POST /api/nb-config/commit`

Stages dotfolders and `.templates/`, then commits:

```json
{ "message": "Add guest user card" }
```

Internally runs:

```bash
git add .users .tools .changes .images .rules .templates .gitignore
git commit -m "<message>"
```

Returns `{ "ok": true, "output": "..." }` or `{ "error": "..." }`.

### `POST /api/nb-config/sync`

Pull-then-push to the private remote:

```bash
git pull --no-edit origin master
git push origin HEAD:master
```

Returns combined output. If `no_remote` is true in the status, this returns a helpful message instead.

### `GET/POST /api/nb-config/remote`

**GET** — returns `{ "remote": "<url or empty string>" }`.

**POST** — sets or updates the `origin` remote:

```json
{ "remote": "git@github.com:djp/nb-config-private.git" }
```

If a remote already exists, it's updated with `git remote set-url origin <url>`. If not, it's added with `git remote add origin <url>`.

### `GET /api/nb-config/log`

Returns the last 20 commits as plain text (`git log --oneline -20`):

```json
{ "log": "abc1234 Add guest user card\ndef5678 Initial commit\n..." }
```

---

## Admin Settings page — Config repo section

`settings.html` has a `sec-config-repo` section, visible only to `admin`/`tech` users, that provides a GUI for the four endpoints above.

**Layout:**

```
Remote URL: [git@github.com:djp/nb-config-private.git] [Save]

Commit message: [___________________________]
[Commit]  [Sync]

Status: 2 uncommitted files, 1 unpushed commit
  M  .users/djp.md
  A  .users/guest.md

[Show log ▾]
<pre>abc1234 Add guest user card
...</pre>
```

The section wires up on `nb-auth-ready`. If `NbAuth.is('admin')` is false (e.g. the page is loaded by an `office` user), the section stays `hidden` via `data-min-level="admin"` and none of the endpoint calls are made.

---

## Planned

- `/setup` first-run route
- Backend notebook ACL enforcement for `notebooks:` user card field (currently frontend-only)
- User management UI in Settings menu (admin/tech only)
- CSRF token middleware
- Per-notebook write locks (separate from the existing `.nb-lock` read-only lock)
- `access:` enforcement on write endpoints (PUT/POST/DELETE)
