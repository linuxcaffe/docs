---
title: plugins
caption: Plugin system internals — writing plugins, extension points, NbWeb host API
toc: true
---

# PLUGINS (dev)

Developer reference for the NbWeb plugin system. For user-facing plugin docs see [[docs:PLUGINS]].

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

**Global plugins** omit `detect` entirely. A plugin without `detect` is active for all notebooks and shows "all notebooks" in the Plugins panel. `NbWeb-codeblocks` is the canonical example: it adds live codeblock rendering to every note in every notebook. Global plugins typically also omit `listDefaults` and `notebookSection`.

---

## How plugins are loaded

On startup, `NbWeb._loadPlugins()` fetches the plugins list from `nb-settings.json` and injects each enabled plugin as a `<script>` tag. Each plugin file calls `NbWeb.registerModule()` at load time. After all plugins are loaded, `NbWeb._init()` runs each plugin's `detect()` function against the full notebook list to determine which notebooks it's active for.

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

`rows` renders as a key/value grid. `actions` renders as buttons below it. Any template with `singleton: true` also appears here with live ✓ / `+ Create` status.

### `listDefaults`

Sets the default list type and sort order when one of this plugin's notebooks is selected.

```javascript
listDefaults: { listType: 'note', sortOrder: 'default' },
```

### `navButtons`

Global buttons injected into the main nav (the plugins slot), not scoped to a particular notebook.

### `codeblockRenderers`

Registers handlers for fenced code block language tags.

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

- **`lang`** — the fenced code language tag
- **`html(text)`** — called synchronously during markdown parsing; returns a placeholder with a spinner. Keep it minimal — this runs before any data is fetched.
- **`render(container)`** — called after the HTML is in the DOM; does the async fetch and builds the widget.

The skeleton/hydrate pattern keeps markdown parsing fast and lets all blocks load in parallel.

`NbWeb-codeblocks` uses this for `tw`, `hledger`, `t`, `nb`, `git`, `cine`, and `chart` — around 1100 lines of widget code that live entirely outside nb-web core. These are nb-web's implementation of the [mkd-codeblocks](https://codeberg.org/linuxcaffe/mkd-codeblocks) collection.

### `previewRenderer`

`(note) => string | null`. Called during note preview rendering, before built-in type detection. Return an HTML string to take over rendering, or `null` to fall through to the next module or to core.

```javascript
previewRenderer: (note) => {
    if (!note.selector || !/:items\//.test(note.selector)) return null;
    return _renderItem(note);
},
```

`NbWeb-quartz` uses this to render shop item cards for notes inside `items/` folders.

**Declare `previewRendererDetect` to participate in unified rendering.** `getPreviewRenderers()` collects renderers from all active modules in plugin-load order — both `previewRenderers[]` arrays and single-renderer modules that declare `previewRendererDetect`. The first source to match wins the note; all matched renderers appear in the toolbar toggle when there are multiple.

```javascript
previewRendererDetect: note => note.type === 'contact',   // cheap predicate
previewRenderer: note => { ... },                          // the actual render fn
```

Modules without `previewRendererDetect` are excluded from `getPreviewRenderers` and fall back to a chain walk via `getPreviewRenderer()` instead. **Always return `null` (not `''` or `undefined`) for note types you don't own** — returning a falsy non-null value stops the chain.

### `previewRenderers` (multi-renderer array)

The richer API for plugins that provide multiple view modes for their note types (e.g. cine: screenplay / story view / script view / card view). Each entry is `{ id, icon, label, types, detect, render }`.

When a notebook has a multi-renderer module active, `getPreviewRenderers()` returns the matching renderers and the toolbar shows toggle buttons. The single `previewRenderer` fallback runs *after* the multi-renderer array when no array entry claims the note — this is how specialty headers appear on cine notes whose type isn't scene/shot/storyline.

### `sortOptions`

Adds custom entries to the sort dropdown (⇅) when the plugin's notebook is active.

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

Plugin sort options appear below the built-in options after a separator. `NbWeb-contacts` uses this for **Last name** sort.

### Planned: `listExcerpt`, `addFormExtras`

`listExcerpt` — override the excerpt shown in list view. In practice the backend already handles the common cases (`caption` frontmatter, `items/` folder pricing). A frontend hook would only be needed for cases the backend can't anticipate.

`addFormExtras` — add fields to the Add note form (category, status, price, image for shop items).

---

## Templates

Plugins declare templates in their module spec. Those templates appear in the Add note picker and, for scoped templates, participate in nb-web's folder-based auto-selection.

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

String or `(notebook) => string`. The function receives the full notebook object. Use optional chaining for plugin-specific fields — content functions may be called for non-plugin-active notebooks.

### `scope`

Declares where the template belongs. Does **not** hide it elsewhere — any template is selectable anywhere in the Add form. Scope determines seeding and default selection.

| scope | Seeded to | Default when |
|---|---|---|
| `'notebook'` | `notebook/.templates/filename` | browsing this notebook |
| `'folder:items'` | `notebook/items/.templates/filename` | adding a note inside `items/` |
| (none) | not seeded | never auto-selected |

### `singleton: true`

A file that should exist at most once per notebook, written directly to the notebook root rather than `.templates/`. Requires `filename` to be set explicitly. Shows `+ Create` in the notebook section instead of `+ Seed`.

### The seeding mechanic

nb-web's folder-based auto-selection: if a folder contains exactly one file in `.templates/`, Add note pre-selects it silently. Plugin templates with a `scope` participate by being seeded to disk. The notebook section shows seed status:

```
_meta.md                     ✓
items/.templates/item.md     + Seed
```

Clicking `+ Seed` writes the template content, creates missing directories, and commits to git. After seeding, auto-selection takes over — the plugin becomes invisible infrastructure.

---

## Plugin help text

```javascript
NbWeb.registerModule('myplugin', {
    label:       'NbWeb-myplugin',
    description: 'One-line summary shown in the Plugins panel',
    helpUrl:     '/plugins/nbweb-myplugin.md',
});
```

- **`description`** — one-line summary, plain text, shown directly below the plugin name
- **`helpUrl`** — URL to a Markdown file; fetched and rendered as the help section. Convention: serve from `plugins/nbweb-<name>.md` alongside the `.js` file.

---

## The NbWeb host API

| Method | Purpose |
|---|---|
| `NbWeb.registerModule(name, spec)` | Register a plugin |
| `NbWeb.notebooks()` | All notebook objects from the last load |
| `NbWeb.getListButtons(notebook)` | List toolbar buttons active for a notebook |
| `NbWeb.getSortOptions(notebook)` | Custom sort options for this notebook |
| `NbWeb.getNavButtons()` | Global nav buttons from all enabled plugins |
| `NbWeb.getNotebookSections(notebookObj)` | Plugin sections for the Notebooks panel |
| `NbWeb.getTemplatesForNotebook(name)` | All plugin templates (scope is not a filter) |
| `NbWeb.getScopedTemplatesForNotebook(name)` | Scoped templates active for this notebook |
| `NbWeb.templateRelPath(template)` | Relative path a template writes to |
| `NbWeb.templateSeeded(notebookName, template)` | Whether a template has been seeded |
| `NbWeb.createFromTemplate(template, notebookObj)` | Seed or create a template file |
| `NbWeb.publishWebsite(notebook, btn)` | Shared publish + build-status poller |
| `NbWeb.statusPill` | Render progress pill — `.add(n)`, `.tick()`, `.registerForce(fn)` |

---

## Writing a plugin

A plugin is a plain `.js` file that calls `NbWeb.registerModule()`. It runs in the browser after nb-web loads, has full DOM + fetch access, and needs no build step.

### Notebook-scoped plugin

```javascript
// NbWeb-myplugin — one-line description
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

### Global plugin (IIFE)

For plugins with no notebook detection — just app-wide behaviour. `NbWeb-codeblocks` is the model.

```javascript
// NbWeb-myplugin — one-line description
(() => {

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

The IIFE is critical for global plugins: without it, every helper function lands on `window`, polluting the namespace and risking collisions with nb-web internals or other plugins.

Serve the file from nb-web's `plugins/` directory (or any URL the browser can reach), add it to `nb-settings.json`, and it appears in the Plugins panel on next load.

---

## Plugin page anatomy

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
| Name + status + active notebooks | always | `label`, `enabled`, detected notebooks (or "all notebooks") |
| Description | when `description` present | one plain-text line |
| Help content | when `helpUrl` resolves | rendered markdown |
| List defaults | when `listDefaults` present | `sortOrder`, `listType`; custom sort labels from `sortOptions` |
| Enable/Disable + Remove | always | wired to `nb-settings.json` |

**What makes a healthy plugin page:** `description` is one action-oriented sentence. `helpUrl` covers what it does, what it activates for, key syntax, any `nb-settings.json` config. `listDefaults` paired with `sortOptions` so the user doesn't have to configure defaults manually.

---

## Plugin development checklist

### Structure
- [ ] Wrapped in an IIFE (global plugins) — no helpers leak to `window`
- [ ] `registerModule` called with a unique name
- [ ] `label`, `description`, `helpUrl` all present
- [ ] `helpUrl` points to a real `.md` file (test: open Plugins page, confirm help text renders)
- [ ] `description` is one action-oriented sentence

### Safety
- [ ] Every piece of user-controlled or note-derived content passes through `_esc()` before insertion into HTML
- [ ] No `innerHTML` set to raw note body — use `NbMain.renderMarkdown()` for body content
- [ ] `previewRenderer` returns `null` for non-matching notes (never `undefined` or `''`)
- [ ] `sortOptions.sort()` returns a new array (`[...notes].sort(...)`) — never mutates the input

### Detection
- [ ] `detect()` returns notebook objects (from the array passed in), not name strings
- [ ] If `detect` omitted (global plugin), plugin genuinely applies to all notebooks
- [ ] `listButtons`, `sortOptions`, `previewRenderer` are absent or return null/[] for undetected notebooks

### Extension points
- [ ] **previewRenderer** — tested with matching note (renders correctly) and non-matching note (falls through)
- [ ] **listButtons** — appears only for detected notebooks; disappears when switching away
- [ ] **sortOptions** — appears only for detected notebooks; doesn't crash on notes missing the sorted field
- [ ] **listDefaults** — applied on first switch to notebook; correct labels from `sortOptions` on plugin page
- [ ] **notebookSection** — renders for active notebooks; returns `null` (not undefined) for non-applicable
- [ ] **codeblockRenderers** — `html()` is fast and synchronous; `render()` handles fetch errors gracefully; collapse state persists
- [ ] **templates** — appear in Add picker; scope auto-selection works; singleton shows correct status

### Plugin page
- [ ] Shows name, status, active notebooks (or "all notebooks"), description, help content
- [ ] Enable/Disable toggle persists across reload
- [ ] List defaults save and take effect on next notebook switch
- [ ] No orphaned sections (empty "List defaults" when `listDefaults` not declared)

### Integration
- [ ] No console errors on load or when switching to a detected notebook
- [ ] `NbMain.loadNotes()` called (not `loadNotes()` directly) wherever the plugin refreshes the list
- [ ] Plugin works with the notebook both empty and populated
- [ ] Plugin degrades gracefully when its notebook doesn't exist (`detect` returns `[]`, UI stays clean)
