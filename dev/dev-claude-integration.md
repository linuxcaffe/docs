---
title: claude integration
caption: nbweb-claude internals — MCP tool wrapper, tier gating, barblock rendering, session/token tracking
toc: true
---

# CLAUDE INTEGRATION (dev)

How the `nbweb-claude` plugin actually works. For *why* it's built this way, see the design doc (`claude:nbweb-claude — Plugin Design v2`) and its 2026-07-10 addendum; for the AI-tooling policy this code follows, see [[.rules/mcp-tools.md]] and [[.rules/agent.md]]. This page is mechanism only.

---

## The `claude:` cascade + badge

`_effective_claude(note_meta, nb_meta)` in `app.py` mirrors `_effective_access` exactly: note-level `claude:` override wins, else notebook config, else `''` (unset — badge doesn't render). `main.js`'s `_injectClaudeBadge` runs from `_finishRendered`, right next to `_injectAccessBadge`. Resolved value (`sonnet`/`opus`/`haiku`/`fable`) becomes the `--model` flag for `/api/claude/ask` — see `_resolve_claude_model_flag`.

---

## `/api/claude/ask` and the MCP wrapper

Shells out to the host's own authenticated `claude` CLI, headless (`-p --output-format json`), never a stored API key. `cwd` is the note's notebook directory, so `.rules`/`CLAUDE.md` auto-load for free.

**Tool access** is a temporary MCP server, spawned fresh per call: `mcp_server.py` (in the `nbweb-claude` repo), pointed to via a per-request `--mcp-config` JSON file (`--strict-mcp-config`, so *only* this server's tools are available — no ambient Bash/Read/Grep). Auth flows through the `env` block of that config:

```json
{"mcpServers": {"nbweb": {
    "command": "python3", "args": ["mcp_server.py"],
    "env": {
        "NBWEB_MCP_TOKEN": "<scoped, 300s TTL>",
        "NBWEB_MCP_BASE":  "http://127.0.0.1:5001",
        "NBWEB_MCP_TIER":  "haiku | dev"
    }
}}}
```

`NBWEB_MCP_TOKEN` is minted by `_mint_mcp_token`, resolved by `_resolve_mcp_token` — an in-memory dict (`_MCP_TOKENS`), not a database. `mcp_server.py` authenticates every REST call it makes with `X-Nbweb-Mcp-Token`, which `app.py`'s `_check_auth` (`before_request`) treats as an ordinary session login for that one request.

**Tier gating happens at import time, not per-call.** `mcp_server.py` reads `NBWEB_MCP_TIER` once at module load and wraps `append_to_note`'s `@mcp.tool()` registration in `if TIER != 'haiku':` — a haiku-tier session's `claude` process genuinely has no tool capable of writing arbitrary content; it isn't hidden behind a policy check that could be reasoned around, it isn't in the tool list the model ever sees.

**Tool inventory** (all thin wrappers over real `/api/*` endpoints — see [[.rules/mcp-tools.md]] for why that's a hard requirement, not a style preference):

| Tool | Wraps | Tier |
|---|---|---|
| `list_notes` | `GET /api/notes` | both |
| `get_note` | `GET /api/note` | both |
| `search_backlinks` | `GET /api/nb/backlinks` | both |
| `get_notebook_config` | `GET /api/nb/notebook-config` | both |
| `list_templates` | `GET /api/templates` (filtered to note-creation templates) | both |
| `create_note` | `POST /api/notes` | both |
| `toggle_todo` | `POST /api/todo` | both |
| `set_annotation` | `POST /api/note/annotate` | both |
| `reload_note` | `POST /api/claude/mark-reload` | both |
| `append_to_note` | `PUT /api/note` (append) | dev only |

---

## Barblock rendering — `claude_ask:` and `claude_code:`

Both are registered codeblock langs (`NbWeb.registerModule('claude', {codeblockRenderers: [...]})`, in `nbweb-claude.js` and `nbweb-codeblocks.js` respectively) that double as frontmatter keys via `main.js`'s `_buildFmBlocks` — any FM key matching a registered lang name renders that lang's `html()`/`render()` pair into `#nb-fm-blocks` instead of the note body. This is the same mechanism `nav:`/`toc:`/`access:` already use, not something built new for Claude.

`claude_ask` specifically (`nbweb-claude.js`) is one HTML builder (`_askBlockHtml(sessionId)`) and one wire function (`_wireAskBlock(block)`) backing three call sites:

1. **FM-rendered** — `claude_ask: <session_id>` already in the note's frontmatter; `_buildFmBlocks`'s generic loop calls `html()`/`render()`.
2. **Badge, fresh start** — no `claude_ask:` FM key yet; `_openOrFocusAskBlock()` inserts a block directly into `#nb-fm-blocks`, bypassing `_buildFmBlocks` (there's nothing in FM to trigger it yet).
3. **Badge, existing conversation** — finds the already-rendered block, force-expands it (`nb-collapsed` removed regardless of prior state), focuses the input.

Collapse behavior uses the plain `.nb-collapsed` CSS convention (`styles.css`: `.nb-collapsed > *:not([class*="-header"]) { display: none; }`, `[class*="-header"]` gets the pointer cursor) — **not** `tui`/`claude_code`'s bespoke JS-driven collapse (`_tuiWire`'s own `.nb-tui-collapsed` class, explicit `wrap.style.display` toggling). That mechanism exists for PTY-specific reasons (xterm fit/resize, WebSocket connect/disconnect tied to expand state) that don't apply to a chat UI — `claude_ask` doesn't need it.

**Session continuity**: `sessionId` starts from `block.dataset.sessionId` (seeded from the FM value when present). Each successful `/api/claude/ask` response's `session_id` gets sent as `resume` on the *next* call from that block. The note's own `claude_ask:` FM field is written server-side (see below), which is what makes continuity survive a page reload — previously it only lived in a browser-tab JS variable.

**Scope limit**: only the session id persists, not the rendered message transcript. Reopening after a reload shows an empty chat with real `--resume` continuity server-side, not a replayed conversation.

---

## Session/token tracking

Three things happen in the same `api_claude_ask` request, right after the `claude -p` JSON response is parsed — one combined operation, not three independent ones:

```python
tokens, cost, hours = _extract_usage(payload)          # duration_ms, usage.*_tokens, total_cost_usd
_log_agent_session(model, notebook, selector, session_id, tokens, cost, hours)
_update_note_ai_stats(selector, tokens, session_id)     # if selector
```

`_extract_usage` is the single source both writers read from — the ledger entry and the note's own cumulative total can never disagree, because they're computed once.

**`_log_agent_session`** appends one `​```timedot` entry to `claude:accounting/agent_sessions.md` (machine-authored — contrast with the hand-curated `claude:accounting/dev_timelog.md`, which is the *interactive CLI session* log, not this plugin's). Pure append, own scoped git commit per call. Account `claude-modal:<model>`; comment carries `session:`/`notebook:`/`selector:`/`tokens:`/`cost:` as plain `;`-comments (not real timedot quantities — hledger's own parsing stays clean, a future reader/aggregator greps the comment text).

**`_update_note_ai_stats`** does one read → `_patch_fm_fields` → write → scoped commit on the note the call actually concerned: `tokens:` (cumulative — reads the note's current value, adds this call's delta), `status: initiated` (a deliberately minimal floor marker, not a lifecycle state), and `claude_ask: <session_id>` (when known). `_patch_fm_fields` is the same in-place FM-field-patcher used elsewhere in `app.py` (e.g. the `lock:` toggle) — updates named keys, preserves everything else, no `--overwrite`-shaped corruption risk.

**List display**: `_list_notes` includes `tokens` in a note's list-item dict only when nonzero (`int(meta.get('tokens', 0) or 0)`). `main.js`'s list renderer shows it in place of the numeric ID badge when present (`note.tokens` truthy → tokens; else → `note.id`, unchanged).

---

## Module checkout/locking

`nb-web/.tools/agent-lock.py` — a standalone script, not wired into any request path yet. Per-repo state in `.agent-locks.json` (gitignored — coordination state, not history). `checkout(repo, files, holder, ttl_minutes)` is all-or-nothing across the given file list; `release`/`status` round out the CLI. See [[.rules/agent.md]]'s "Dispatch sequence" for the intended manual-today usage pattern (checkout before editing, release on todo close, TTL as a crash safety net only).

---

## Cross-references

| Topic | Where |
|---|---|
| Design decisions and why | `claude:nbweb-claude — Plugin Design v2`, `.rules/mcp-tools.md` |
| Agent-todo tags, checkout usage, dispatch sketch | [[.rules/agent.md]] |
| Assistant-mode (haiku) behavior rules | [[.rules/haiku.md]] |
| Build narratives | `claude:nbweb-claude — build session 2026-07-09` / `-10` |
