---
config: docs
type: dotfile
title: docs notebook config
date: 2026-06-19
#
# ── Access ───────────────────────────────────────────────────────────────────
# Who can see notes in this folder? Inherited from notebook if not set.
#
# access: guest    # anyone logged in (lowest — public-ish)
# access: user     # registered users  (system default when nothing is set)
# access: office   # office level and above
# access: admin    # admins only
#
# ── Pinned note ──────────────────────────────────────────────────────────────
# One note always sorted to the top of the list. Value = filename stem.
#
pinned: docs.md
#
# ── Tag colours ──────────────────────────────────────────────────────────────
# Map tag names to hex colours for display in the list.
# Important: hex values MUST be quoted — bare #hex is a YAML comment.
#
# tag_color:
#   bug:  '#e05252'
#   rfe:  '#5299e0'
#   done: '#52a86e'
#   wip:  '#d4a017'
#
# ── Date prefix ──────────────────────────────────────────────────────────────
# Whether new note filenames are prefixed with YYYYMMDD. Default: true.
#
# prepend_date: false
#
# ── Virtual tests ────────────────────────────────────────────────────────────
# Test-script family prefixes injected as Type 1 blocks at the top of every
# note preview in this folder. Silent on pass. Set "" to suppress inherited.
#
# checks: [nb-, hl-]
# checks: ""
---

<!-- NOTE: create this file via the ＋ button in a ```config block, not via Add —
     that ensures it's written as a dotfile (.name.md) and docs is the folder name. -->

<!-- docs — describe the purpose of this folder here -->
