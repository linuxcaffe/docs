---
title: DEVELOPERS
caption: nb-web developer documentation index
toc: true
processed: true
---

# DEVELOPERS

Developer documentation for nb-web, organised by feature area. Each section below links to a dedicated file in `dev/`.

---

## Index

| File | Scope |
|------|-------|
| [[docs:dev/dev-architecture.md]] | Rendering stages, frontmatter keys, images, UUIDs, hashtags — non-feature-specific internals |
| [[docs:dev/dev-render-pipeline.md]] | Rendering architecture — pipeline stages, bottlenecks, redesign plan |
| [[docs:dev/dev-codeblocks.md]] | Writing, registering, and testing live codeblock widgets |
| [[docs:dev/dev-codeblock-authoring.md]] | Full authoring guide — anatomy, statusPill, headers, error handling, checklist |
| [[docs:dev/dev-plugins.md]] | Plugin system — writing plugins, dispatch, `listItemIcon`, toolbar hooks |
| [[docs:dev/dev-wikilinks.md]] | Wikilink resolution algorithm, `_wikilinkCache`, `term:` link handling |
| [[docs:dev/dev-templates.md]] | `_resolve_template_vars`, placeholder API, annotation templates |
| [[docs:dev/dev-sync.md]] | Pull-then-push flow, `git-wire` internals, status API |
| [[docs:dev/dev-storage.md]] | Git topology: undercarriage repo, branch-per-notebook, restore sequence |
| [[docs:dev/dev-testing.md]] | Writing and running nb-web test scripts via the `test` codeblock |
| [[docs:dev/dev-contributing.md]] | Reporting issues, submitting changes, running from source |
| [[docs:dev/dev-xref.md]] | Stemming algorithm, prefix matching, `/api/xref` reference, `forceAll()` book behavior |
| [[docs:dev/dev-security.md]] | Auth scheme — session login, user cards, dotfolder notebooks, level-based access |
| [[docs:dev/dev-notebook-config.md]] | `.<notebook>.md` config file — themes, icon, colour, plugin config, UI flags, vision doc |

