---
title: security
caption: "Auth scheme: session login, user cards, dotfolder notebooks, level-based access"
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
```

Every request (including `/api/*` and static files) passes through `_check_auth()`. Unauthenticated API calls get `401 JSON`; unauthenticated page requests redirect to `/login`.

---

## User cards

Users are `.md` files in `~/.nb/.users/`. This is a **dotfolder** — not indexed by nb, not published by Quartz, not shown to regular users.

```
~/.nb/.users/
    djp.md
    lena.md
    alice.md
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
| `level` | yes | Access level: `user`, `office`, `admin`, `tech` |
| `password_hash` | yes | werkzeug `generate_password_hash()` output |
| `notebooks` | no | List of notebooks this user may access (empty = all) |

**Creating a user:**

```python
from werkzeug.security import generate_password_hash
print(generate_password_hash('password'))
```

Paste the output into the `password_hash:` field. The username is the filename stem (e.g. `djp.md` → username `djp`).

---

## Access levels

```
user < office < admin < tech
```

| Level | Can do |
|-------|--------|
| `user` | Read notes in their notebook list; no write |
| `office` | Read + write notes in their notebook list |
| `admin` | Everything office can do + access dotfolder notebooks |
| `tech` | Full access; manages users and settings |

Checked by `_level_gte(have, need)` in `app.py` — compares index positions in `LEVELS = ['user', 'office', 'admin', 'tech']`.

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
- **Notebook ACL** (`notebooks:` field) is enforced on the frontend via `/api/me` — backend route-level enforcement is planned but not yet implemented for regular notebooks. Dotfolder access is enforced server-side.
- **WebSocket (`/ws`)** paths return 401 JSON when unauthenticated; the PTY terminal respects this.
- **No CSRF protection** yet — all mutating endpoints accept JSON bodies; browser same-origin policy provides partial coverage. CSRF tokens are on the roadmap for multi-user production deployments.

---

## Planned

- `/setup` first-run route
- Backend notebook ACL enforcement (currently frontend-only)
- User management UI in Settings menu (admin/tech only)
- CSRF token middleware
- Per-notebook write locks (separate from the existing `.nb-lock` read-only lock)
