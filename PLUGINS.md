---
title: PLUGINS
caption: nbweb-plugins, customize and extend nb-web
draft:
toc: true
---

# PLUGINS

nb-web has a plugin system — `NbWeb` — that lets external JavaScript modules extend the UI without touching core files. Two plugins ship with nb-web: `NbWeb-quartz`, which wires nb-web to Quartz static site publishing, and `NbWeb-codeblocks`, which provides the live fenced code block widgets. They represent two distinct plugin shapes — one notebook-scoped, one global — and between them cover all the extension points the system currently offers.

---

## How plugins are loaded

Plugins are listed in `nb-settings.json`:

```json
{
  "plugins": [
    { "url": "/plugins/nbweb-quartz.js" },
    { "url": "/plugins/nbweb-shop.js", "enabled": false }
  ]
}
```

On startup, `NbWeb._loadPlugins()` fetches that list and injects each enabled plugin as a `<script>` tag. Each plugin file calls `NbWeb.registerModule()` at load time. After all plugins are loaded, `NbWeb._init()` runs each plugin's `detect()` function against the full notebook list to determine which notebooks it's active for.

---

## Registering a module

```javascript
NbWeb.registerModule('mymodule', {
    label:       'My Module',
    description: 'What it does',
    helpUrl:     '/plugins/mymodule.md',

    detect: (notebooks) => notebooks.filter(nb => nb.someCondition),

    // extension points declared here...
});
```

`detect()` receives the full array of notebook objects from `/api/nb/notebooks` and returns the subset this plugin cares about. The detected notebooks determine where toolbar buttons, notebook sections, and scoped templates appear.

**Global plugins** omit `detect` entirely. A plugin without `detect` is active for all notebooks and shows "all notebooks" in the Plugins panel — no per-notebook gating of any kind. `NbWeb-codeblocks` is the canonical example: it adds live codeblock rendering to every note in every notebook without needing to know anything about the notebook structure. Global plugins typically also omit `listDefaults` and `notebookSection` — there's nothing notebook-specific to configure.

---

## Extension points

### `listButtons`

Buttons injected into the List panel toolbar when the active notebook is one this plugin detected.

```javascript
listButtons: [
    {
        id:     'mymod-action',
        icon:   '🚀',
        title:  'Do the thing',
        action: (notebook, btn) => { /* ... */ },
    },
],
```

`action` receives the current notebook name and the button element. The quartz plugin uses this for Publish (🌐) and Open site (↗).

### `notebookSection`

A function that returns a section to append to the Notebooks detail panel for any notebook this plugin is active for. Return `null` to opt out for a particular notebook.

```javascript
notebookSection: (notebook) => {
    if (!notebook.website) return null;
    return {
        label: 'My Module',
        rows: [
            { key: 'URL',  value: notebook.website.url, link: notebook.website.url },
            { key: 'Path', value: notebook.website.quartz_path },
        ],
        actions: [
            {
                id:      'mymod-publish',
                icon:    '🚀',
                label:   'Publish',
                primary: true,
                fn:      (nb, btn) => doPublish(nb.name, btn),
            },
        ],
    };
},
```

The `rows` array renders as a small key/value grid. `actions` renders as buttons below it. Any template that has `singleton: true` in this plugin also appears in this section with live ✓ / `+ Create` status (see Templates below).

### `listDefaults`

Sets the default list type and sort order when one of this plugin's notebooks is selected. Useful when a plugin's notebooks always contain a particular content type.

```javascript
listDefaults: { listType: 'note', sortOrder: 'default' },
```

### `navButtons`

Global buttons injected into the main nav (the plugins slot), not scoped to a particular notebook. Useful for app-wide actions.

### `codeblockRenderers`

Registers handlers for fenced code block language tags. When nb-web renders a note, any fence whose language matches a registered renderer is handed off to that renderer instead of being shown as plain code.

```javascript
codeblockRenderers: [
    {
        lang:   'tw',
        html:   text => `<div class="nb-tw-block" data-query="${text.trim()}">
                    <span class="nb-spin">⟳</span>
                 </div>`,
        render: async container => {
            for (const el of container.querySelectorAll('.nb-tw-block'))
                await loadTwBlock(el);
        },
    },
],
```

Each entry declares:

- **`lang`** — the fenced code language tag (`tw`, `hledger`, `git`, …)
- **`html(text)`** — called synchronously during markdown parsing; returns a placeholder element with a spinner. Keep it minimal — this runs before any data is fetched.
- **`render(container)`** — called after the HTML is inserted into the DOM; does the async fetch and constructs the full widget. `container` is the note preview element.

The pattern is deliberate: `html()` stamps a skeleton, `render()` hydrates it. This keeps markdown parsing fast and lets all blocks on a page load in parallel.

`NbWeb-codeblocks` uses this to provide `tw`, `hledger`, `t`, `nb`, and `git` blocks — around 1100 lines of widget code that live entirely outside nb-web's core. These are nb-web's implementation of the [mkd-codeblocks](https://codeberg.org/linuxcaffe/mkd-codeblocks) collection, a set of independently distributable live-query widgets for markdown apps. The `hledger` block is already released as a standalone package; the others are planned for extraction.

### `previewRenderer`

A function `(note) => string | null`. Called during note preview rendering, before built-in type detection. Return an HTML string to take over rendering, or `null` to fall through to core.

```javascript
previewRenderer: (note) => {
    if (!note.selector || !/:items\//.test(note.selector)) return null;
    return _renderItem(note);   // only handles shop items; everything else falls through
},
```

`NbWeb-quartz` uses this to render shop item cards (image, price, status, fields) for notes inside `items/` folders — knowledge that previously lived as a hardcoded path check in nb-web core.

### `sortOptions`

Adds custom entries to the list sort dropdown (the ⇅ button) when the plugin's detected notebook is active. Each option supplies an `id`, a display `label`, and a `sort` function that receives and returns the notes array.

```javascript
sortOptions: [
    {
        id:    'lastname',
        label: 'Last name',
        sort:  (notes) => [...notes].sort((a, b) => {
            const ln = n => {
                const name = n.meta?.name || n.title || '';
                const parts = name.trim().split(/\s+/);
                return (parts.length > 1 ? parts[parts.length - 1] : parts[0]).toLowerCase();
            };
            return ln(a).localeCompare(ln(b));
        }),
    },
],
```

Plugin sort options appear below the built-in options (Default, A→Z, Z→A, Newest, Oldest) after a separator. If the plugin also declares `listDefaults`, the custom options appear in the plugin page's sort dropdown too.

`NbWeb-contacts` uses this to provide **Last name** sort for the contacts notebook.

### Planned: `listExcerpt`, `addFormExtras`

`listExcerpt` would let a plugin override the excerpt text shown under the title in list view. In practice, nb-web's backend already handles the common cases: notes with a `caption` frontmatter field use caption as their excerpt, and notes inside `items/` folders get `category · price · status`. A frontend hook would only be needed for cases the backend can't anticipate.

`addFormExtras` would add fields to the Add note form (category, status, price, image for shop items).

---

## Templates

This is where the plugin system does the most interesting work.

Plugins declare templates in their module spec. Those templates appear in the Add note template picker and, for scoped templates, participate in nb-web's existing folder-based auto-selection.

```javascript
templates: [
    {
        name:        'Page',
        description: 'Content page with Quartz frontmatter',
        scope:       'notebook',
        content:     '---\ntitle: \ncaption: \ntags: []\n---\n\n',
    },
    {
        name:        'Item',
        filename:    'item.md',
        description: 'Shop item listing',
        scope:       'folder:items',
        content: () => {
            const date = new Date().toISOString().slice(0, 10);
            return `---\ntitle: \nprice: \nstatus: available\ncategory: \nimage: \ncaption: \ntags: []\ndate: ${date}\n---\n\n`;
        },
    },
    {
        name:        '_meta.md',
        filename:    '_meta.md',
        description: 'Site-wide config note',
        singleton:   true,
        content:     (notebook) => `---\ntagline:\ncopyright: "${notebook.name}"\n---\n\n`,
    },
],
```

### `content`

Either a string or a function `(notebook) => string`. The function receives the full notebook object, so it can interpolate `notebook.website.url` or generate a date at creation time. For non-singleton templates the notebook passed is the current scope, not necessarily a plugin-active one — content functions should use optional chaining for any plugin-specific fields.

### `scope`

Declares where the template belongs. It does **not** hide the template elsewhere — any template is selectable anywhere in the Add form. Scope determines two things: where it shows as a default, and where it gets seeded to disk.

| scope | Seeded to | Default when |
|---|---|---|
| `'notebook'` | `notebook/.templates/filename` | browsing this notebook |
| `'folder:items'` | `notebook/items/.templates/filename` | adding a note inside `items/` |
| (none) | not seeded | never auto-selected |

### `singleton: true`

A file that should exist at most once per notebook, written directly to the notebook root rather than a `.templates/` subdirectory. The `_meta.md` config note is a singleton — it's a real note, not a template file. Requires `filename` to be set explicitly.

### The seeding mechanic

nb-web already has folder-based auto-selection: if a folder contains exactly one file in its `.templates/` directory, Add note pre-selects it silently. Plugin templates with a `scope` participate in this by being seeded to disk.

In the Notebooks detail panel, a plugin's section shows the status of its seedable templates:

```
_meta.md                     ✓
items/.templates/item.md     + Seed
```

Clicking `+ Seed` writes the template content to the target path, creates any missing directories, and commits to git. After that, the auto-selection mechanism takes over. Add note in `items/` → item template pre-selected, no further action needed. The plugin becomes invisible infrastructure.

Singletons show `+ Create` instead, and the file lands in the notebook root.

### Templates in the Add form

All plugin templates from all enabled plugins are always listed in the Add note template picker, grouped by module. A template from a plugin that isn't active for the current notebook still appears — scope is a default, not a gate. If a singleton already exists it shows greyed out with "✓ exists — edit in Notebooks".

---

## Plugin help text

The Plugins panel shows two pieces of text from a plugin's spec:

- **`description`** — a one-line summary shown as a subtitle directly below the plugin name. Plain text; no markup.
- **`helpUrl`** — a URL to a Markdown file. Its contents are fetched and rendered as the help section below the description. This is where you explain what the plugin does in full.

```javascript
NbWeb.registerModule('myplugin', {
    label:       'NbWeb-myplugin',
    description: 'One-line summary shown in the Plugins panel',
    helpUrl:     '/plugins/nbweb-myplugin.md',
    // ...
});
```

Both fields are optional. A plugin with neither shows only its name and status. The convention for nb-web's own plugins is to serve the markdown file from `plugins/nbweb-<name>.md` alongside the `.js` file.

---

## The NbWeb host API

Plugins access the host via the global `NbWeb` object:

| Method | Purpose |
|---|---|
| `NbWeb.registerModule(name, spec)` | Register a plugin |
| `NbWeb.notebooks()` | All notebook objects from the last load |
| `NbWeb.getListButtons(notebook)` | List toolbar buttons active for a notebook |
| `NbWeb.getSortOptions(notebook)` | Custom sort options from plugins active for this notebook |
| `NbWeb.getNavButtons()` | Global nav buttons from all enabled plugins |
| `NbWeb.getNotebookSections(notebookObj)` | Plugin sections for the Notebooks panel |
| `NbWeb.getTemplatesForNotebook(name)` | All plugin templates (scope is not a filter) |
| `NbWeb.getScopedTemplatesForNotebook(name)` | Scoped templates active for this notebook |
| `NbWeb.templateRelPath(template)` | Relative path a template writes to |
| `NbWeb.templateSeeded(notebookName, template)` | Whether a template has been seeded |
| `NbWeb.createFromTemplate(template, notebookObj)` | Seed or create a template file |
| `NbWeb.publishWebsite(notebook, btn)` | Shared publish + build-status poller |

---

## Writing a plugin

A plugin is a plain `.js` file that calls `NbWeb.registerModule()`. It runs in the browser after nb-web loads, has access to the full DOM and fetch API, and needs no build step.

Minimal skeleton:

```javascript
// NbWeb-myplugin — one-line description
// Any additional detail shown in the Plugins panel.
NbWeb.registerModule('myplugin', {

    label:       'NbWeb-myplugin',
    description: 'What this plugin does',
    helpUrl:     '/plugins/nbweb-myplugin.md',

    detect: (notebooks) => notebooks.filter(nb => nb.someField),

    notebookSection: (notebook) => ({
        label:   'My Plugin',
        rows:    [],
        actions: [],
    }),

    templates: [],

});
```

Serve it from nb-web's `plugins/` directory (or any URL the browser can reach), add it to `nb-settings.json`, and it appears in the Plugins panel on next load.

For a **global plugin** — no notebook detection, just app-wide behaviour — the shape is simpler. `NbWeb-codeblocks` is the model: an IIFE keeps internal functions private, `detect` is omitted, and `codeblockRenderers` does all the work.

```javascript
// NbWeb-myplugin — one-line description
(() => {

    // Internal helpers — not exposed globally
    async function _loadMyBlock(el) {
        // fetch data, build widget, replace el contents
    }

    NbWeb.registerModule('myplugin', {
        label:       'NbWeb-myplugin',
        description: 'What this plugin does',
        helpUrl:     '/plugins/nbweb-myplugin.md',

        codeblockRenderers: [
            {
                lang:   'mylang',
                html:   text => `<div class="nb-my-block" data-query="${text.trim()}">
                            <span class="nb-spin">⟳</span>
                         </div>`,
                render: async container => {
                    for (const el of container.querySelectorAll('.nb-my-block'))
                        await _loadMyBlock(el);
                },
            },
        ],
    });

})();
```

The IIFE is important for global plugins: without it, every helper function lands on `window`, which pollutes the namespace and risks collisions with nb-web internals or other plugins.

---

## Plugin page anatomy

The Plugins panel entry for each plugin is the primary communication surface between the plugin and the user. A well-populated entry has several sections, each conditional on the relevant spec fields being present.

```
🔌  NbWeb-contacts              ● active   contacts
    Contact card renderer, last-name sort, and VCF importer

    [help markdown rendered here — from helpUrl]

    ┌ List defaults ──────────────────────────────────────┐
    │  Sort   [Last name ▾]                               │
    │  Type   [note      ▾]          [Save defaults]      │
    └─────────────────────────────────────────────────────┘

    [Disable]  [Remove]
```

| Section | When shown | Source |
|---|---|---|
| Name + status + active notebooks | always | `label`, `enabled`, `activeNotebooks` (or "all notebooks") |
| Description | when `description` present | `description` — one plain-text line |
| Help content | when `helpUrl` resolves to a markdown file | rendered markdown fetched from `helpUrl` |
| List defaults | when `listDefaults` present | `listDefaults.sortOrder`, `listDefaults.listType`; custom sort labels from `sortOptions` |
| Enable/Disable + Remove | always | actions wired to `nb-settings.json` |

**What makes a healthy plugin page:**

- **`description`** — one sentence, action-oriented. Not "this plugin renders contacts" but "contact card renderer, last-name sort, and VCF importer for the contacts notebook."
- **`helpUrl`** — a markdown file at `plugins/nbweb-<name>.md`. Cover: what it does, what notebook/content it activates for, key fields or syntax, any configuration in `nb-settings.json`.
- **`listDefaults`** — declare sensible defaults so the user doesn't have to configure them; pair with `sortOptions` if the plugin offers a domain-specific sort.
- **`sortOptions`** — give domain sorts a clear label. "Last name" beats "lastname". The label is what appears in the sort dropdown too.

The help file is the right place for full documentation. The `description` is the hook that makes a user want to read it.

---

## Plugin development checklist

Use this when writing a new plugin or reviewing an existing one.

### Structure

- [ ] Wrapped in an IIFE — no helpers leak to `window`
- [ ] `registerModule` called with a unique name (no collisions with codeblocks, quartz, contacts)
- [ ] `label`, `description`, `helpUrl` all present
- [ ] `helpUrl` points to a real `.md` file that loads without 404 (test: open Plugins page and check help text renders)
- [ ] `description` is one action-oriented sentence, not a restatement of the label

### Safety

- [ ] Every piece of user-controlled or note-derived content passes through `_esc()` before being inserted into HTML
- [ ] No `innerHTML` set to raw note body — use `NbMain.renderMarkdown()` for body content
- [ ] `previewRenderer` returns `null` for non-matching notes (never returns `undefined` or `''` as a fallthrough)
- [ ] `sortOptions.sort()` returns a new array (`[...notes].sort(...)`) — never mutates the input

### Detection

- [ ] `detect()` returns notebook objects (from the array passed in), not name strings
- [ ] If `detect` is omitted (global plugin), confirm the plugin genuinely applies to all notebooks
- [ ] Verified that listButtons, sortOptions, and previewRenderer are absent (or return null/[]) for notebooks the plugin didn't detect

### Extension points used

- [ ] **previewRenderer** — tested with a matching note (renders correctly) and a non-matching note (falls through to core rendering)
- [ ] **listButtons** — button appears only when a detected notebook is active; action does the right thing; button disappears when switching away
- [ ] **sortOptions** — option appears in the ⇅ dropdown only for detected notebooks; sort produces the expected order; doesn't crash on notes missing the sorted field
- [ ] **listDefaults** — applied when switching to the notebook for the first time; shows correctly on the plugin page with custom sort labels if `sortOptions` also declared
- [ ] **notebookSection** — renders in Notebooks panel for active notebooks; returns `null` (not undefined) for non-applicable notebooks
- [ ] **codeblockRenderers** — `html()` is fast and synchronous; `render()` handles fetch errors gracefully; collapse state persists across reloads
- [ ] **templates** — appear in Add note picker; scope/folder auto-selection works; singleton create/seed shows correct status on plugin page

### Plugin page

- [ ] Plugin page shows name, status, active notebooks (or "all notebooks"), description, and help content
- [ ] Enable/Disable toggle works and persists across reload
- [ ] List defaults save correctly and take effect on next notebook switch
- [ ] No orphaned sections (e.g. empty "List defaults" block when `listDefaults` not declared)

### Integration

- [ ] No console errors on load or when switching to a detected notebook
- [ ] `NbMain.loadNotes()` called (not `loadNotes()` directly) wherever the plugin refreshes the list
- [ ] Plugin works with the notebook both empty and populated
- [ ] Plugin degrades gracefully when its notebook doesn't exist (detect returns `[]`, UI stays clean)
