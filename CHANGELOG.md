# Changelog

## 1.0.0 (2026-09-10)

- Initial release.
- Template list with 8 built-ins (focus interrupt, arena1/2/3, @cursor, mouseover heal/damage, stopcasting, trinket+spell, set focus).
- Placeholder rows: type, drag from spell book, or pick from a searchable icon grid; per-character memory of filled values.
- Live preview with 255-character counter; create as account or character macro; overwrite confirmation; pick-up after create.
- Import any existing macro as a template (spell names → placeholders), from the window or from a button on Blizzard's macro frame.
- Locales: enUS, zhTW.

## 1.0.1 (2026-09-10)

- Version shown in the window title.
- Opaque window backgrounds (game UI no longer bleeds through).
- Placeholder section shrinks to the rows in use; preview takes the remaining space.
- "Save template" renamed to "Update template" and moved to the editor's label row; hint text is single-line.
- Focus-interrupt template no longer includes `/stopcasting`; unedited built-ins are refreshed automatically.
- Macro name defaults are truncated by character (UTF-8 safe), not by byte.
- Shorter built-in template names (old names are migrated automatically).

## 1.0.2 (2026-09-10)

- Placeholders with fixed choices (arena1/2/3) use a dropdown instead of inline buttons.
- "All (arena1/arena2/arena3)" creates three macros in one click, named `<name>1/2/3`; the preview shows every variant and one confirmation covers any overwrites.
- Built-in placeholder metadata is refreshed on load, so existing databases pick up the new options.

## 1.1.0 (2026-09-10)

- **Variables** window: reference of every built-in placeholder (INTERRUPT, CC, HEAL, HARM, GROUND, CD, DEFENSIVE, MOVEMENT, SPELL, ARENA), what it means, its fixed choices and which suggestion category it maps to.
- **Spell table**: per-class suggestion lists by category (interrupt, CC, defensive, burst, movement, ground, heal). Stored as spell IDs and resolved at runtime — unknown spells are greyed, removed spells vanish, nothing breaks. Editable in-game (add from the picker, remove, reset to shipped); shipped lists for Evoker, DK, DH, Druid, Priest, Rogue, Paladin.
- Spell picker shows the matching category's suggestions above the full list when the placeholder name (or an alias: KICK, CD, DEF, MOVE, AOE) matches a category.

## 1.1.1 (2026-09-10)

- Spell picker splits the full list into **Class spells** and **General spells** (suggestions stay on top).
- Arena template defaults to "All" (three macros at once). Pick-up is disabled for batch creation; whenever nothing is picked up, the macro window opens after creating so you can drag.
- Blizzard's macro window gets a MacroMaster bar underneath it (Open / Save as template) instead of side buttons.
- Spell table now ships lists for all 13 classes.

## 1.2.0 (2026-09-10)

- New built-in **FrameSort interrupt (PvP)**: `#FrameSort X {FS}` — kicks the focus if it is a live enemy, otherwise the frame FrameSort resolves (dropdown, default EnemyHealer). Optional `{CANCEL}` line drops an immunity first; leave it empty and the line disappears.
- Placeholder metadata gains `optional` (unfilled → line removed), `default` (pre-filled), `category` (suggestion list override).
- Built-ins added in later releases are added to existing databases once; ones you deleted stay deleted.

## 1.2.1 (2026-09-10)

- Description is a three-line box; window is 50px taller.
- New built-ins: **Mouseover dispel** (`{DISPEL}`), **Mouseover purge** (`{PURGE}`), **Mouseover external** (`{EXTERNAL}`), each with its own suggestion category and shipped spells for all classes.
- Spell table has 10 categories in two rows of tabs; aliases CLEANSE/DECURSE = DISPEL, OFFDISPEL = PURGE, EXT/SAVE = EXTERNAL.
- FrameSort template description no longer mentions the addon requirement.

## 1.2.2 (2026-09-10)

- Template list can be sorted by name or by creation order (button above the list; remembered).
- Interrupt template is now `/stopcasting` + `/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}` — Shift kicks the focus, plain press kicks the target. Unedited copies are upgraded automatically.

## 1.2.3 (2026-09-10)

- Sort button was anchored off-screen; fixed.
- New built-ins **FrameSort ally external (PvP)** and **FrameSort ally dispel (PvP)**: mouseover if friendly, otherwise `#FrameSort X {FST}` (Healer by default; OtherDPS, Tank, DPS, Frame1-5).

## 1.2.4 (2026-09-10)

- **Set focus** now also marks the focus (`/tm [@focus] {MARK}`, picked from a dropdown showing the raid icons, default circle) and announces it (`/p {MSG}`, default `Focus: %f`; clear it to drop the line).
- Option dropdowns can show icons and friendly labels; the chosen icon is shown next to the row.
- Defaults are applied only to never-set values, so a cleared optional field stays cleared.

## 1.2.5 (2026-09-10)

- FrameSort placeholders renamed: `{FS}` is now the **ally** selector (Healer, OtherDps, Tank, DPS, Frame1-5), `{FSENEMY}` the **enemy** selector (EnemyHealer, ...). Unedited templates and remembered values are migrated.
- `OtherDPS` → `OtherDps`.

## 1.2.6 (2026-09-10)

- `{FSENEMY}` lists enemy selectors only (EnemyHealer / EnemyTank / EnemyDPS / EnemyFrame1-3); ally selectors were left over from the old combined list.

## 1.2.7 (2026-09-10)

- **Set focus** announces with the chosen marker icon in front (`{rt2}` etc.) via the new `/mmfocus` command, which speaks only when the focus actually changed and stays silent outside a group (party / raid / instance chat picked automatically).
- Substitution resolves placeholders nested inside another one (`{rt{MARK}}`).

## 1.2.8 (2026-09-10)

- `/mmfocus` no longer errors when the client hands it a secret GUID/name (12.x secret values in PvP): comparison is skipped and a 5-second throttle prevents spam instead; secret names are left as `%f` for the chat system.
- Macro name default skips text placeholders (no more `Focus: %f` as a macro name).

## 1.3.0 (2026-09-11)

- New built-in **Self-heal combo**: `/castsequence [@player] reset=combat {SELFHEAL}, {HEALTHSTONE}, {POTION}` — one button that steps through a self-heal, a Healthstone and a healing potion (the structure the Auto Potion addon generates, without an addon rewriting the macro behind your back).
- Item placeholders: `{HEALTHSTONE}` and `{POTION}` (alias `HEALPOT`) are filled from your bags. *Pick* opens a bag picker (suggested items first, then every usable item), items can be dragged from the bags onto the box, and a Healthstone / the strongest healing potion you carry is pre-filled. Values are item names, so any rank of a potion works.
- Placeholders in a comma list can be left empty: the unfilled one disappears together with its comma instead of blocking the macro (`token` placeholders).
- New spell category **Self-heal** with per-class suggestions (Renewal, Exhilaration, Desperate Prayer, Crimson Vial, Word of Glory, Expel Harm, Bitter Immunity, Gift of the Naaru...). The spell table window is a little wider to fit the eleventh tab.
- Creating a macro warns when an item placeholder names something not in your bags; text placeholders no longer trigger the "not in your spell book" warning.
