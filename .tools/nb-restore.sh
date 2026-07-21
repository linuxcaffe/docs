#!/usr/bin/env bash
# nb-restore.sh — Bootstrap the nb ecosystem on a new machine.
# DANGEROUS: full-machine bootstrap. Code of last resort — only for a
# genuinely bare machine with nothing on it yet. NOT a repair tool: if
# ~/.nb or ~/dev/nb-web already exist, something more targeted is almost
# certainly the right fix, not this script.
#
# Idempotent: each phase checks "already done?" before acting — safe to
# re-run. But "individually safe" isn't the same as "safe to run without
# looking" — this script should never execute unattended or with a single
# unconfirmed click (nbweb-tui's Tools pane gates it on typed confirmation,
# added 2026-07-20; a leaked-config incident that day couldn't be pinned
# on this script specifically, since every phase already skip-guards, but
# the standing rule is: this class of tool is never one click away).
#
# **If Docker/Podman is available at all, rebuilding the nb-web container
# (see nb-web/Containerfile) is the preferred recovery path, not this
# script** — it reconstructs the running app from a known-good image in
# minutes, doesn't touch ~/.nb's git history, and is the path this
# ecosystem has actually been maintained through since Phase 2
# containerization (2026-07-19). This script remains for the one case that
# doesn't cover: a machine with no container runtime at all.
#
# Bootstrap on a fresh machine (before undercarriage is cloned):
#   curl -fsSL "https://codeberg.org/linuxcaffe/nb-notes/raw/branch/master/.tools/nb-restore.sh" | bash
# After cloning undercarriage manually, or to resume a partial run:
#   bash ~/.nb/.tools/nb-restore.sh
#
# Phases:
#   0  Pre-flight       — git, curl, SSH → Codeberg
#   1  nb binary        — install if missing
#   2  Undercarriage    — git clone nb-notes.git → ~/.nb
#   3  Notebooks        — restore each branch as a local notebook
#   4  Dev repos        — nb-web, nb-plugins, nbweb-cine, tw-web
#   5  nb plugins       — install *.nb-plugin from ~/dev/nb-plugins
#   6  nb-settings.json — copy from template; note machine-specific values
#   7  systemd          — nb-daily-init.timer (06:00 daily note)

set -uo pipefail  # no -e: accumulate failures and report at end

NB_REMOTE="git@codeberg.org:linuxcaffe/nb-notes.git"
NB_DIR="$HOME/.nb"

# ── Pre-flight abort: refuse to march through quietly on an intact machine ──
# Every phase below already skip-guards its own piece, so this isn't fixing
# an unsafe re-run — it's making the "nothing to do" case loud and stopping
# BEFORE touching anything, rather than silently walking all 7 phases'
# individual no-ops. Explicit --force required to proceed anyway.
if [[ -d "$NB_DIR/.git" ]] && [[ -d "$HOME/dev/nb-web/.git" ]]; then
  if [[ "${1:-}" != "--force" ]]; then
    echo "nb-restore.sh: this machine already looks fully bootstrapped" >&2
    echo "  (~/.nb and ~/dev/nb-web both exist with real git history)." >&2
    echo "" >&2
    echo "This is a full-machine bootstrap script, not a repair tool. If" >&2
    echo "something specific is broken, fix that directly instead. If" >&2
    echo "Docker/Podman is available, rebuilding the nb-web container is" >&2
    echo "also almost certainly what you actually want (see" >&2
    echo "nb-web/Containerfile) rather than re-running this." >&2
    echo "" >&2
    echo "If a full re-bootstrap is genuinely intended, re-run with --force." >&2
    exit 1
  fi
fi

# local-path|remote-url (pipe-delimited for bash 3 compat, no associative arrays)
DEV_REPOS=(
  "$HOME/dev/nb-web|git@codeberg.org:linuxcaffe/nb-web.git"
  "$HOME/dev/nb-plugins|git@github.com:linuxcaffe/nb-plugins.git"
  "$HOME/dev/nbweb-cine|git@github.com:linuxcaffe/nbweb-cine.git"
  "$HOME/dev/tw-web|git@codeberg.org:linuxcaffe/tw-web.git"
)

DONE=()
SKIPPED=()
FAILED=()
MANUAL=()

_ok()   { printf '  \033[32m✓\033[0m  %s\n' "$*"; DONE+=("$*"); }
_skip() { printf '  \033[2m·\033[0m  %s\n' "$*"; SKIPPED+=("$*"); }
_fail() { printf '  \033[31m✗\033[0m  %s\n' "$*"; FAILED+=("$*"); }
_note() { printf '  \033[33m▸\033[0m  %s\n' "$*"; MANUAL+=("$*"); }
_head() { printf '\n\033[1m── %s\033[0m\n' "$*"; }

# ── Phase 0: Pre-flight ───────────────────────────────────────────────────────

_head "Phase 0 — Pre-flight"

for cmd in git curl; do
  if command -v "$cmd" &>/dev/null; then
    _skip "$cmd  ($(command -v "$cmd"))"
  else
    _fail "$cmd not found — install it and re-run"
    exit 1
  fi
done

SSH_OUT=$(ssh -T -o ConnectTimeout=8 -o BatchMode=yes git@codeberg.org 2>&1 || true)
if echo "$SSH_OUT" | grep -qi "successfully authenticated"; then
  _ok "SSH → Codeberg"
else
  _fail "SSH → Codeberg failed"
  printf '       Run: ssh -T git@codeberg.org\n'
  printf '       Check ssh-agent, ~/.ssh/config, or add your key at codeberg.org/user/settings/keys\n'
  exit 1
fi

# GitHub SSH (non-fatal — only needed for nb-plugins and nbweb-cine)
GH_OUT=$(ssh -T -o ConnectTimeout=8 -o BatchMode=yes git@github.com 2>&1 || true)
if echo "$GH_OUT" | grep -qi "successfully authenticated\|Hi "; then
  _ok "SSH → GitHub"
else
  _note "SSH → GitHub failed — nb-plugins and nbweb-cine clones will fail (non-fatal)"
fi

# ── Phase 1: nb binary ───────────────────────────────────────────────────────

_head "Phase 1 — nb binary"

if command -v nb &>/dev/null; then
  _skip "nb installed  ($(nb version 2>/dev/null | head -1))"
else
  printf '  Downloading nb...\n'
  if curl -fsSL https://raw.github.com/xwmx/nb/master/nb -o /tmp/nb-install \
      && chmod +x /tmp/nb-install \
      && sudo mv /tmp/nb-install /usr/local/bin/nb; then
    _ok "nb installed → /usr/local/bin/nb"
  else
    _fail "nb install failed — see https://github.com/xwmx/nb for manual install"
  fi
fi

# ── Phase 2: Undercarriage ───────────────────────────────────────────────────

_head "Phase 2 — Undercarriage (~/.nb)"

if [[ -d "$NB_DIR/.git" ]]; then
  _skip "undercarriage already present"
elif [[ -d "$NB_DIR" ]]; then
  _fail "~/.nb exists but has no .git — manual intervention required"
  _note "If fresh install: rm -rf ~/.nb && re-run"
  _note "If existing nb: git -C ~/.nb init && git -C ~/.nb remote add origin $NB_REMOTE && git -C ~/.nb fetch && git -C ~/.nb checkout master"
  exit 1
else
  if git clone -q "$NB_REMOTE" "$NB_DIR"; then
    _ok "undercarriage cloned → $NB_DIR  (master branch = undercarriage)"
  else
    _fail "git clone $NB_REMOTE failed — cannot continue"
    exit 1
  fi
fi

# ── Phase 3: Notebooks ───────────────────────────────────────────────────────

_head "Phase 3 — Notebooks (branch per notebook on $NB_REMOTE)"

NOTEBOOKS=$(git -C "$NB_DIR" ls-remote --heads origin \
  | awk '{print $2}' \
  | sed 's|refs/heads/||' \
  | grep -v '^master$' \
  | sort 2>/dev/null) || NOTEBOOKS=""

if [[ -z "$NOTEBOOKS" ]]; then
  _fail "Could not list remote branches — skipping notebook restore"
else
  for name in $NOTEBOOKS; do
    dir="$NB_DIR/$name"
    if [[ -d "$dir/.git" ]]; then
      _skip "$name"
      continue
    fi
    mkdir -p "$dir"
    # init → force master branch name → remote → fetch → checkout FETCH_HEAD → wire tracking
    if git -C "$dir" init -q 2>/dev/null \
        && git -C "$dir" symbolic-ref HEAD refs/heads/master \
        && git -C "$dir" remote add origin "$NB_REMOTE" \
        && git -C "$dir" fetch -q origin "$name" \
        && git -C "$dir" checkout -b master FETCH_HEAD 2>/dev/null \
        && git -C "$dir" config branch.master.merge "refs/heads/$name" \
        && git -C "$dir" config branch.master.remote origin; then
      _ok "$name"
    else
      _fail "$name — git setup failed"
      rm -rf "$dir"
    fi
  done
fi

# ── Phase 4: Dev repos ───────────────────────────────────────────────────────

_head "Phase 4 — Dev repos"

mkdir -p "$HOME/dev"

for entry in "${DEV_REPOS[@]}"; do
  dir="${entry%%|*}"
  remote="${entry##*|}"
  name="$(basename "$dir")"
  if [[ -d "$dir/.git" ]]; then
    _skip "$name"
  elif git clone -q "$remote" "$dir" 2>/dev/null; then
    _ok "$name  → $dir"
  else
    _fail "$name  (clone from $remote failed)"
  fi
done

# ── Phase 5: nb plugins ──────────────────────────────────────────────────────

_head "Phase 5 — nb plugins"

PLUGINS_DIR="$HOME/dev/nb-plugins"

if [[ ! -d "$PLUGINS_DIR" ]]; then
  _note "nb-plugins not cloned (phase 4 may have failed) — skipping plugin install"
else
  INSTALLED=$(nb plugin 2>/dev/null || true)
  for plugin in "$PLUGINS_DIR"/*.nb-plugin; do
    [[ -e "$plugin" ]] || continue
    pname="$(basename "$plugin")"
    if echo "$INSTALLED" | grep -qF "$pname"; then
      _skip "plugin: $pname"
    elif nb plugin install "$plugin" &>/dev/null; then
      _ok "plugin: $pname"
    else
      _fail "plugin: $pname — install failed"
    fi
  done
fi

# ── Phase 6: nb-settings.json ────────────────────────────────────────────────

_head "Phase 6 — nb-settings.json"

SETTINGS_DST="$HOME/dev/nb-web/nb-settings.json"
SETTINGS_TPL="$NB_DIR/.tools/nb-settings-template.json"

if [[ -f "$SETTINGS_DST" ]]; then
  _skip "nb-settings.json already present"
elif [[ ! -d "$HOME/dev/nb-web" ]]; then
  _fail "~/dev/nb-web not cloned — cannot write nb-settings.json"
  _note "Re-run after phase 4 succeeds"
elif [[ -f "$SETTINGS_TPL" ]]; then
  cp "$SETTINGS_TPL" "$SETTINGS_DST"
  _ok "nb-settings.json created from template"
  _note "Edit $SETTINGS_DST — fill in: port, pty_height, tw_web_cmd, hledger_web_cmd"
else
  _fail "nb-settings-template.json missing from .tools/ — cannot create nb-settings.json"
  _note "Reference: docs:dev/dev-storage.md"
fi

# ── Phase 7: systemd — nb-daily-init ─────────────────────────────────────────

_head "Phase 7 — systemd: nb-daily-init"

SYSTEMD_DIR="$HOME/.config/systemd/user"
BIN_DIR="$HOME/.local/bin"
SCRIPT_SRC="$NB_DIR/.tools/nb-daily-init.sh"
SCRIPT_DST="$BIN_DIR/nb-daily-init.sh"

mkdir -p "$SYSTEMD_DIR" "$BIN_DIR"

# Script: symlink from .tools/ if present, else warn
if [[ -f "$SCRIPT_DST" ]] || [[ -L "$SCRIPT_DST" ]]; then
  _skip "nb-daily-init.sh already in ~/.local/bin/"
elif [[ -f "$SCRIPT_SRC" ]]; then
  chmod +x "$SCRIPT_SRC"
  ln -sf "$SCRIPT_SRC" "$SCRIPT_DST"
  _ok "nb-daily-init.sh  symlinked from .tools/"
else
  _fail "nb-daily-init.sh not found in .tools/ — systemd unit will fail"
  _note "Copy nb-daily-init.sh into ~/.nb/.tools/ and commit it to undercarriage"
fi

# .service unit
SERVICE="$SYSTEMD_DIR/nb-daily-init.service"
if [[ -f "$SERVICE" ]]; then
  _skip "nb-daily-init.service"
else
  cat > "$SERVICE" <<'EOF'
[Unit]
Description=Initialize today's nb daily note with weather and journal template

[Service]
Type=oneshot
ExecStart=%h/.local/bin/nb-daily-init.sh
EOF
  _ok "nb-daily-init.service written"
fi

# .timer unit
TIMER="$SYSTEMD_DIR/nb-daily-init.timer"
if [[ -f "$TIMER" ]]; then
  _skip "nb-daily-init.timer"
else
  cat > "$TIMER" <<'EOF'
[Unit]
Description=Run nb-daily-init at 06:00 daily

[Timer]
OnCalendar=*-*-* 06:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
  _ok "nb-daily-init.timer written"
fi

# Enable and start
if systemctl --user is-enabled nb-daily-init.timer &>/dev/null 2>&1; then
  _skip "nb-daily-init.timer already enabled"
else
  if systemctl --user daemon-reload 2>/dev/null \
      && systemctl --user enable --now nb-daily-init.timer 2>/dev/null; then
    _ok "nb-daily-init.timer enabled + started"
  else
    _fail "systemctl enable nb-daily-init.timer — try manually:"
    _note "systemctl --user daemon-reload && systemctl --user enable --now nb-daily-init.timer"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────

_head "Summary"

printf '  \033[32m✓\033[0m  %d succeeded\n'              "${#DONE[@]}"
printf '  \033[2m·\033[0m  %d skipped (already done)\n'  "${#SKIPPED[@]}"

if (( ${#FAILED[@]} > 0 )); then
  printf '  \033[31m✗\033[0m  %d failed:\n' "${#FAILED[@]}"
  printf '       – %s\n' "${FAILED[@]}"
fi
if (( ${#MANUAL[@]} > 0 )); then
  printf '  \033[33m▸\033[0m  %d manual steps remaining:\n' "${#MANUAL[@]}"
  printf '       – %s\n' "${MANUAL[@]}"
fi
printf '\n'
