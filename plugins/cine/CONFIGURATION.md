# CONFIGURATION.md

*Frontmatter field reference, .nb-cine.json, access levels — [NbWeb-cine](../README.md)*

---

*Coming soon — full frontmatter schemas for every note type, `.nb-cine.json` options, access
level configuration, and per-notebook settings. Content migrated from the previous README.*

## The production note (`type: production`)

One per notebook, at the notebook root (e.g. `production.md`). A hand-filled source for
company/ATL info — production company name, address, phone/email, copyright, and the six ATL
role fields (`director`, `exec_producer`, `producer`, `line_producer`, `dp`, `writer`).

This note is deliberately just data — fill in what you know, leave the rest blank. It's not a
dashboard or a rollup of the rest of your production (that's what your notebook's own
`type: dashboard` note is for); nothing here is pulled from elsewhere, and nothing elsewhere is
pulled *into* it automatically either. An ATL field left blank renders as a small
"— required —" placeholder on the note's own card, with a tooltip pointing you at the Changes
panel (the ✎ button in the note's toolbar) to fill it in.

### Marking your own fields as required

The production note's six ATL roles come pre-marked required via a `constraints_add:` block in
its own frontmatter:

```yaml
constraints_add:
  director: {required: true}
  producer: {required: true}
```

`constraints_add:` only *adds* — it won't touch a field your notebook's own root config
(`.{notebook}.md`) already declares in its `constraints:` block. If you want a note's own field
to instead *replace* whatever the notebook-level config says for that same key, use plain
`constraints:` on the note instead of `constraints_add:`.

Embedding the production card elsewhere: `{{inline: card production.md}}` (see the main
nb-web docs for `{{inline:}}` generally) drops the full rendered card — not just the note's
body text — into any other note (your notebook's dashboard, for instance). An embedded card
has no Changes panel of its own to edit through, so the whole card is a click-through link back
to `production.md` — click anywhere on it (that isn't already a link, like the phone/email
rows) to open the real note and make changes there.
