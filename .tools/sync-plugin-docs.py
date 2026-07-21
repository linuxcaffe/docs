#!/usr/bin/env python3
"""
sync-plugin-docs.py — materialize docs:plugins/<name>/ as real files fetched
from each plugin's public GitHub repo, replacing the ~/dev symlinks.

Why: docs:plugins/*.md used to be symlinks into ~/dev/nbweb-*/... -- this
only resolves on a host where ~/dev happens to be checked out at that exact
absolute path. Confirmed broken inside the nb-web container 2026-07-20 (the
container's mount is /home/nbweb/dev, but the symlink target was hardcoded
to /home/djp/dev -- dangling). This matches the stated direction of sourcing
plugins externally from GitHub rather than depending on a local dev checkout
at all -- the same "fetch the real artifact, don't trust local state"
approach the Containerfile already uses for the nb/hledger binaries.

These become real, static copies, not a live mirror -- they go stale
relative to the source repo until re-run. That's an accepted tradeoff for
removing the ~/dev dependency, not an oversight.

Run manually when a plugin's docs have materially changed:
    python3 docs/.tools/sync-plugin-docs.py            # all known plugins
    python3 docs/.tools/sync-plugin-docs.py hledger     # just one
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

DOCS_ROOT = Path(__file__).resolve().parent.parent / 'plugins'

# Coverage is partial by design (matches docs:plugins/'s existing scope,
# nb-web skill note "only these three plugins have docs mirrored so far") --
# not every nb-web plugin has docs mirrored into this notebook yet.
PLUGINS = {
    'cine': {
        'repo': 'https://github.com/linuxcaffe/nbweb-cine.git',
        'files': {
            'README.md': 'README.md',
            'docs/BUDGET.md': 'BUDGET.md',
            'docs/CONFIGURATION.md': 'CONFIGURATION.md',
            'docs/SCHEDULING.md': 'SCHEDULING.md',
            'docs/SCREENPLAY.md': 'SCREENPLAY.md',
            'docs/SHOTLISTING.md': 'SHOTLISTING.md',
            'docs/STORYLINES.md': 'STORYLINES.md',
        },
    },
    'claude': {
        'repo': 'https://github.com/linuxcaffe/nbweb-claude.git',
        'files': {'README.md': 'README.md'},
    },
    'hledger': {
        'repo': 'https://github.com/linuxcaffe/nbweb-hledger.git',
        'files': {'README.md': 'README.md', 'INVOICING.md': 'INVOICING.md'},
    },
}


def sync_plugin(name, cfg):
    dest_dir = DOCS_ROOT / name
    dest_dir.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(
            ['git', 'clone', '--depth', '1', cfg['repo'], tmp],
            check=True, capture_output=True, text=True,
        )
        for src_rel, dest_name in cfg['files'].items():
            src = Path(tmp) / src_rel
            dest = dest_dir / dest_name
            if not src.exists():
                print(f"  ! {name}: {src_rel} not found in repo, skipping")
                continue
            if dest.is_symlink() or dest.exists():
                dest.unlink()
            shutil.copy2(src, dest)
            print(f"  {name}/{dest_name}")


def main():
    wanted = sys.argv[1:] or list(PLUGINS)
    for name in wanted:
        if name not in PLUGINS:
            print(f"unknown plugin: {name} (known: {', '.join(PLUGINS)})")
            continue
        print(f"Syncing {name}...")
        try:
            sync_plugin(name, PLUGINS[name])
        except subprocess.CalledProcessError as e:
            print(f"  ! clone failed: {e.stderr.strip()}")


if __name__ == '__main__':
    main()
