---
title: README — footer
caption: installation, status, further reading, related projects
---
## Installation

### Requirements

- Python 3.10+
- [nb](https://github.com/xwmx/nb) installed and initialised (`nb` must be on `$PATH`)
- A modern browser (Firefox, Chrome, or Epiphany/GNOME Web for PWA mode)

Optional: `gh` CLI for Create & Wire (new GitHub repo from the UI), `rg` (ripgrep) for faster search.

### Quick start

```bash
git clone https://github.com/linuxcaffe/nb-web.git
cd nb-web
pip install -r requirements.txt
python3 app.py
```

Open `http://localhost:5001` and sign in; your existing nb notebooks appear immediately.

<!-- FIXME first account: /login redirects to /setup when ~/.nb/.users/ is empty, but no /setup route exists (found 2026-10-08). -->

### PWA install (Epiphany / GNOME Web)

[screenshot: Epiphany install-as-app dialog]

nb-web is a full PWA. In Epiphany, open `http://localhost:5001`, then **⋮ → Install as Web Application**. It launches in its own window with no browser chrome, indistinguishable from a native app.

A launcher script (`nb-web-launch.sh`) is included that starts the Flask server, opens Epiphany, and cleans up on exit. See [[docs:Install]] for setup details.

### Settings

Machine settings (port, terminal, plugins, git remote) live in `nb-settings.json`, written when you
first change one in **Menu → Settings**. Everything else is per notebook, in its config note.

→ [[docs:Install]]

---

## Project status

nb-web is active and stable at v2.x. The core note-browsing, editing, sync, and plugin system are solid. The archive/import round-trip, live codeblocks, and contacts plugin are new additions — well-tested but still accumulating real-world use. APIs may evolve between minor versions.

---

## Further reading

The full documentation lives in nb-web's own `docs` notebook; the pages linked here are copies of it in [docs/](docs/), also browsable at [linuxcaffe.github.io/docs-site](https://linuxcaffe.github.io/docs-site/).

| Doc | Contents |
|-----|---------|
| [[docs:Install]] | Dependencies, launch script, Epiphany setup |
| [[docs:QUICKSTART]] | Five-minute orientation |
| [[docs:NOTEBOOKS]] | Notebook management, wiring, defaults |
| [[docs:SYNC]] | Git model, sync dialog, troubleshooting |
| [[docs:TEMPLATES]] | Placeholder syntax, `typename.md` convention, per-notebook defaults |
| [[docs:THEMES]] | Theme files, config chain key, picker, dark/light, custom themes |
| [[docs:SYSADMIN]] | Dotfile vs dashboard split, `cfg: org`, admin templates |
| [[docs:WIKILINKS]] | Syntax, anchor links, backlinks |
| [[docs:CODEBLOCKS]] | All live block types and configuration |
| [[docs:PROJECT-REPORTS]] | Project diary pattern, timeframe selector, invoice generation |
| [[docs:SEARCH_TAGS]] | Search, tag filter, cross-notebook search |
| [[docs:CONTACTS]] | Contact notes, VCF import |
| [[docs:import-export]] | .nbz archive format, import workflow |
| [[docs:PLUGINS]] | Plugin architecture and development |
| [[docs:KEYBOARD]] | All keyboard shortcuts |

### Security

nb-web uses session-based login. Users are `.md` files in `~/.nb/.users/` with YAML frontmatter (`name`, `level`, `password_hash`, `notebooks`). Five access levels: `guest`, `user`, `office`, `admin`, `tech`. Admin and tech users also see the dotfolders (`.users`, `.tools`, `.changes`, `.images`, `.rules`, `.lib`, `.checks`) in the notebook selector. See [[docs:dev/dev-security.md]] for full details.

---

## Related projects

| Project | What it is |
|---------|-----------|
| [nb](https://github.com/xwmx/nb) | The CLI note-taking tool nb-web wraps |
| [nb-quartz](https://github.com/linuxcaffe/nb-quartz) | Convert a notebook to a static website with Quartz |
| [nb-plugins](https://github.com/linuxcaffe/nb-plugins) | Plugins for the nb CLI |
| [tw-web](https://github.com/linuxcaffe/tw-web) | Sister app: web interface for Taskwarrior; designed to run alongside nb-web |
| [hledger-codeblock](https://github.com/linuxcaffe/hledger-codeblock) | Standalone hledger live block; the same widget used in nb-web |
| [mkd-codeblocks](https://github.com/linuxcaffe/mkd-codeblocks) | The broader codeblock collection nb-web draws from |

---

## Metadata

- License: [AGPL v3](LICENSE)
- Language: Python (Flask) + Vanilla JavaScript
- Requires: Python 3.10+, nb 7+
- Platforms: Linux (primary), macOS (untested)
- Version: 2.x
