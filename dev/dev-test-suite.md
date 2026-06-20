---
title: test suite
caption: "nb-web automated test strategy: hybrid pytest + .test/ scripts, synthetic fixtures, isolated repo"
toc: true
processed: true
---

# NB-WEB TEST SUITE — STRATEGY

> Developer documentation for nb-web. See [[docs:DEVELOPERS.md]] for the full index.
> Status: #planned — strategy approved, implementation pending

---

## Philosophy

The test suite extends the existing `.test/` script philosophy into a formal
automated layer, rather than replacing or duplicating it. Three layers, each with
a distinct job:

```
Layer 3 — .test/ blocks in dashboard notes    production monitoring (live data)
Layer 2 — pytest invoking .test/ scripts      script contract verification (synthetic data)
Layer 1 — pytest + Flask test client          backend logic (no server, no real data)
```

Layer 3 already exists and works. The suite adds Layers 1 and 2.

**Key principle:** tests are executable specifications. The dev docs describe what
`_can_access` promises and what `nb-check-front.sh` contracts. The test suite
makes those promises verifiable and regression-proof.

---

## Isolation

**Separate repo: `~/dev/nb-web-tests/`**

- Pins to nb-web via path (`sys.path.insert(0, '../nb-web')`) — no package needed
- Can test a specific nb-web commit without touching the running instance
- Tests are versioned independently — no test churn in the app repo
- CI-ready when the time comes, without touching the main repo
- Mirrors the undercarriage philosophy: test infrastructure travels separately

The repo is NOT a submodule. A simple path reference in `conftest.py` is enough.

---

## The Fixture Model

Every test gets a clean, synthetic nb world via a pytest fixture. No dependency
on `~/.nb/` real data — ever.

```
conftest.py
  tmp_nb(tmp_path) fixture:
    tmp_path/.nb/
      .nb.md              ← minimal global config (access: guest)
      .users/
        djp.md            ← level: tech
        guest.md          ← level: guest
        office.md         ← level: office
      home/
        .git/             ← bare init (enough for nb path resolution)
        .index            ← test-note.md
        test-note.md
      accts/
        .accts.md         ← access: office, tests: hl-health-day
        .index            ← report.md
        report.md         ← type: note
        shots/
          .shots.md       ← default_type: shot, constraints: (alias required, etc.)
          .index           ← valid-shot.md, bad-shot.md
          valid-shot.md   ← type: shot, alias: 4f, scene: 1, seq: 1, title: Wide
          bad-shot.md     ← type: shot (missing alias, scene has "~req" not int)
```

**NB_DIR patching:** `conftest.py` sets `app.NB_DIR = tmp_path / '.nb'` via
`monkeypatch.setattr` before each test. All backend functions that read `NB_DIR`
see the synthetic world.

**Session patching:** tests that exercise access control inject a session user:
```python
with client.session_transaction() as sess:
    sess['user'] = {'username': 'djp', 'level': 'tech'}
```

---

## What's In Scope

The boundary is: **Flask backend logic that is non-trivial, recently changed,
or security-critical.** Everything else waits.

| Priority | Area | Rationale |
|----------|------|-----------|
| P0 | Config chain (`_folder_config`, `_notebook_config`, `_merge_configs`) | Most complex new logic; subtle walk-up rules; central to everything |
| P0 | Access control (`_can_access`, `_effective_access`, username access) | Security-critical; tech bypass invariant must hold |
| P0 | Shell scripts as black boxes (`.test/*.sh` via subprocess) | Hybrid layer; validates the script contract with synthetic fixtures |
| P1 | Constraints (`_load_constraints`, `_normalize_constraint`) | Drives Changes panel; two input formats; dot-notation skipping |
| P1 | Settings migration (`_effective_setting`) | Just implemented; `.nb.md` wins, no fallback — must stay true |
| P1 | `/api/list` — pinning, tag_color, prepend_date, access filtering | Core list behaviour; several new fields just added |
| P2 | `/api/note` — effective_access, effective_tests fields | Authoritative fields that frontend trusts |
| P2 | Note creation — filename generation, template resolution | prepend_date logic, slug generation |

## What's Out of Scope (for now)

- **JS / frontend** — no headless browser; too much setup for the value
- **Rendering pipeline** — changes frequently, fragile to test at unit level
- **Git operations** — slow, stateful, integration-only
- **Plugin renderers** — belong in each plugin's own repo
- **PTY / WebSocket** — separate concern, separate testing strategy
- **hledger / cine plugin logic** — plugin repos own those tests

---

## File Structure

```
~/dev/nb-web-tests/
  conftest.py                 ← NB_DIR patch, Flask client, tmp_nb fixture, user helpers
  fixtures/
    nb_md.py                  ← factory: build synthetic .nb.md content
    notes.py                  ← factory: build note content with frontmatter
    configs.py                ← factory: build folder/notebook config content
  test_config_chain.py        ← _folder_config walk-up, _notebook_config, _merge_configs
  test_access.py              ← _can_access, _effective_access, username, tech bypass
  test_constraints.py         ← _load_constraints, _normalize_constraint, dot-notation
  test_settings.py            ← _effective_setting: .nb.md wins, correct defaults
  test_api_list.py            ← /api/list: pinning, tag_color, access filter, type filter
  test_api_note.py            ← /api/note: effective_access, effective_tests in response
  test_note_creation.py       ← prepend_date, slug, explicit filename, template vars
  test_shell_scripts.py       ← nb-check-front.sh, nb-dirty.sh via subprocess + env
```

---

## Layer 1: pytest + Flask Test Client

```python
# conftest.py (sketch)
import pytest, sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent.parent / 'nb-web'))
import app as nb_app

@pytest.fixture
def tmp_nb(tmp_path, monkeypatch):
    nb = tmp_path / '.nb'
    _build_fixture_world(nb)          # writes synthetic files
    monkeypatch.setattr(nb_app, 'NB_DIR', nb)
    return nb

@pytest.fixture
def client(tmp_nb):
    nb_app.app.config['TESTING'] = True
    with nb_app.app.test_client() as c:
        yield c

def as_user(client, level='tech', username='djp'):
    with client.session_transaction() as s:
        s['user'] = {'username': username, 'level': level}
```

```python
# test_config_chain.py (sketch)
def test_folder_config_walk_up(tmp_nb):
    """Inner folder config wins over notebook config over global."""
    note = tmp_nb / 'accts/shots/valid-shot.md'
    cfg = nb_app._folder_config('accts', note)
    assert cfg['access'] == 'office'        # from .accts.md
    assert 'alias' in cfg['constraints']    # from .shots.md

def test_prepend_date_false_suppresses_timestamp(client, tmp_nb):
    as_user(client)
    r = client.post('/api/notes', json={'notebook': 'home', 'title': 'My Note'})
    assert r.json['selector'].split(':')[1] == 'my_note.md'  # no timestamp

def test_prepend_date_default_adds_timestamp(client, tmp_nb):
    # home notebook has no prepend_date: false in config
    as_user(client)
    r = client.post('/api/notes', json={'notebook': 'home', 'title': 'My Note'})
    import re
    assert re.match(r'\d{14}_', r.json['selector'].split(':')[1])
```

---

## Layer 2: Shell Scripts as Black Boxes

The hybrid layer. pytest sets up synthetic fixtures, invokes `.test/*.sh` via
subprocess, and asserts on exit code and stdout patterns.

```python
# test_shell_scripts.py (sketch)
import subprocess, os

SCRIPTS = pathlib.Path.home() / '.nb/.test'

def run_script(name, note_path, nb_dir):
    env = {**os.environ,
           'NB_NOTE_PATH': str(note_path),
           'NB_DIR':       str(nb_dir),
           'NB_NOTEBOOK':  note_path.parts[-3],
           'NO_COLOR':     '1'}
    return subprocess.run(['bash', str(SCRIPTS / name)],
                          capture_output=True, text=True, env=env)

def test_check_front_clean_folder(tmp_nb):
    """Valid shots → silent pass."""
    r = run_script('nb-check-front.sh',
                   tmp_nb / 'accts/shots/valid-shot.md', tmp_nb)
    assert r.returncode == 0
    assert r.stdout == ''

def test_check_front_violation_detected(tmp_nb):
    """bad-shot.md missing alias, invalid scene → exit 1, named fields."""
    r = run_script('nb-check-front.sh',
                   tmp_nb / 'accts/shots/bad-shot.md', tmp_nb)
    assert r.returncode == 1
    assert 'missing **alias**' in r.stdout
    assert 'not an integer' in r.stdout

def test_check_front_no_default_type(tmp_nb):
    """Folder with no default_type → nothing to check, silent exit 0."""
    r = run_script('nb-check-front.sh',
                   tmp_nb / 'home/test-note.md', tmp_nb)
    assert r.returncode == 0
```

This is the bridge: the script's documented contract becomes an assertion.
When `nb-check-front.sh` changes, the test catches regressions. When a new
`.test/` script is added, a corresponding test block is added here.

---

## Access Control Test Matrix

Access control has enough edge cases to deserve explicit parametrization:

```python
@pytest.mark.parametrize('user_level,note_access,nb_access,expected', [
    ('guest',  None,     'guest',  True),   # guest note in guest notebook
    ('guest',  None,     'user',   False),  # guest can't read user notebook
    ('user',   None,     'user',   True),
    ('user',   'office', 'user',   False),  # note raises floor
    ('office', 'office', 'user',   True),
    ('tech',   'admin',  'admin',  True),   # tech bypasses everything
    ('guest',  'djp',    'guest',  False),  # username lock, wrong user
    ('user',   'djp',    'guest',  False),  # username lock, wrong user
    # djp with username match:
    # (requires patching session username to 'djp')
])
def test_can_access(user_level, note_access, nb_access, expected, ...):
    ...
```

---

## Running the Suite

```bash
cd ~/dev/nb-web-tests
pytest                          # all tests
pytest test_config_chain.py     # one file
pytest -k 'access'              # keyword filter
pytest -v --tb=short            # verbose, short tracebacks
pytest test_shell_scripts.py    # hybrid layer only
```

No server running. No real `~/.nb/` data touched. Clean run every time.

---

## Growth Path

| Phase | What gets added |
|-------|----------------|
| Now | conftest.py + test_config_chain + test_access + test_shell_scripts |
| Soon | test_constraints + test_settings + test_api_list |
| Later | test_api_note + test_note_creation |
| Eventually | CI via Codeberg Actions on push to nb-web main |
| Multi-user | Session/auth tests, per-user fixture variants |

The suite grows with the project. P0 tests land first — the riskiest logic gets
coverage before the easy paths. The hybrid layer grows in step with `.test/`: every
new shell script gets a corresponding test block in `test_shell_scripts.py`.

---

## What This Gives Us

- **Config chain regressions caught immediately** — the walk-up logic is complex enough to break silently
- **Security invariants enforced** — tech bypass, username lock, access floor — all specified as assertions
- **Shell script contracts formalised** — `nb-check-front.sh` behaviour is specified, not just described
- **Confidence to refactor** — `_folder_config` and `_effective_setting` can be changed knowing the tests will catch breaks
- **Living specification** — the tests ARE the spec; the dev docs describe intent, the tests verify it

---

> The suite isn't trying to test everything. It's trying to make the riskiest,
> most recently-changed, and hardest-to-eyeball logic verifiable with one command.
