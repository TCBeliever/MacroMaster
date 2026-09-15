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
- **Defaults** replaces *Restore built-ins*: a read-only catalogue of the shipped templates with a preview, *Add to my templates* (overwrite confirmation when you already have it) and *Reset all to defaults*.
- **Export / Import**: all templates as plain text in a box (copy it out to back up or share; paste and import to merge — same id replaces, the rest are added).
- Importing a macro (*Save as template* / *Import*) maps spells and items to the variables the addon knows — `{INTERRUPT}`, `{CC}`, `{HEAL}`, `{SELFHEAL}`, `{POTION}`, `{HEALTHSTONE}`... (current class first, then every class's table) — instead of a key made from the spell name; unknown ones become `{SPELL}` / `{ITEM}` (`_2`, `_3` for repeats), and `spell:1234` / `item:1234` are resolved to names. `{ITEM}` is a new generic item placeholder (bag picker, no suggestions).
- **Set focus** announces "Focus {rt2}" by default — message first, marker after, no enemy name. A character still holding the old default message ("Focus: %f") is switched to the new one; an edited message is kept.
- **Set focus** no longer uses mouseover (too easy to hit by accident): `/focus` on your target, `/tm [@focus] ~N` so the marker is not taken away from another unit.
- Left-pane buttons regrouped: list actions (New / Import / Delete) under the list, the library (Defaults, Export / Import) as a separate row below; *Variables* moved next to *Update template*, *Spell table* onto the *Fill placeholders* row, where each is used.
- **Macro icon**: the button left of the macro name picks an icon one of your existing macros already uses (hover shows which macros), so a hand-picked icon can be reused without digging through Blizzard's list. Right-click returns to the question mark. Remembered per template; overwriting an existing macro keeps its icon unless you picked one.
- Importing a macro also converts `/cancelaura` lines: the aura becomes `{AURA}` (`{AURA_2}`...) regardless of its category.
- *Import from macro* no longer opens empty the first time (the list is filled on a frame that was never hidden); reopening it while open re-reads the macro list.
- Shorter descriptions on every built-in template (a copy you never edited picks up the new text).
- Self-heal suggestions only list active heals now (Evoker: Verdant Embrace, Emerald Blossom, Living Flame; Death Knight: Death Strike; Paladin adds Holy Shock; Shaman adds Riptide and Healing Wave; Warlock: Drain Life...).

## 1.4.0 (2026-09-11)

- Ten more built-in templates, from the patterns every macro guide teaches: modifier (2-3 spells on one button), self-cast, cancel aura + cast, external to focus, mouseover with Alt = focus, in combat / out of combat, target's target, pet attack + spell, spell sequence (with a choice of reset), once per target. *Trinket + spell* lets you pick slot 13 or 14.
- **Class recommendations**: a fresh install starts with the set recommended for your class (about eight templates) instead of everything; *Default templates* opens on that set, has category filters (core / healing / PvP / sequence / pet), lists what fits your class first (derived from the spell tables), marks templates you have not seen as new and offers *Add all recommended*. New built-ins no longer sneak into your list on upgrade. Placeholders with a category start filled with the first suggestion your character knows.
- Interrupt, Stopcast + cast, Arena target, Quick ground spell and Mouseover/Alt = focus gain an optional `/cancelaura {CANCEL}` line (gone when empty), so the press goes through Deep Breath, Ice Block, Aspect of the Turtle and the like. `{AURA}` and `{CANCEL}` get their own **Cancel aura** category: per class, the auras that stop you from acting (Deep Breath, Ice Block, Aspect of the Turtle, Divine Shield, Bladestorm, Ghost Wolf...), not defensives. Optional placeholders are never pre-filled.
- An empty placeholder in a `;` list takes its whole `[conditions] {X};` clause with it, like the comma rule.
- **Settings** is the second tab of the window (bottom tabs: Editor / Settings) with a language switch — auto / English / 繁體中文, applied after a UI reload; shipped template names and descriptions you never edited follow the language — and the doors to *Default templates* and *Export / Import*, which moved there from the left pane. Raid marker names and the set-focus default message follow the addon language too, and buttons grow to fit their label.
- Switching template no longer shows the previous template's name on the preview's per-variant headers (the default macro name is settled before the preview is built).
- The CurseForge file changelog now carries only that version's notes instead of the whole history.

## 1.5.0 (2026-09-14)

- **Share strings**: *Export* now produces one line (`!MM1!...`: the template text deflated with LibDeflate and written in a chat-safe alphabet) instead of multi-line text, so it survives Discord, forums and websites unchanged. *Import* takes the string or the old plain text. A *Share* button on the editor gives the string for the current template alone.
- The Export / Import window has a *Same id* choice: *Replace* overwrites your copy of a template you already have (restoring a backup), *Add new* adds it next to yours with a fresh id (keeping your version); the confirmation says which will happen. Fresh ids are checked against the list, so a batch import cannot collide.
- **Code warnings**: a template whose body runs Lua (`/run`, `/script`, `/dump`, `/console`) is flagged in red under the editor and in the preview, the import confirmation says how many such templates the text contains, and creating such a macro asks for a red confirmation that lists the code lines. Your own `/run` templates work as before; the warning is there for strings that come from someone else.
- Imported names and descriptions have UI escape sequences neutralised (`|` becomes `||`), oversized strings are refused before decoding, and bodies longer than the editor allows are skipped.
- Bundles LibStub and LibDeflate (zlib licence) under `Libs/`; `deploy.bat` copies subfolders.

## 1.5.1 (2026-09-15)

- Pop-up windows (built-in templates, export / import, variables, spell table) open centred on the screen and come back where you last dragged them, instead of hanging off the right edge of the main window.
- Settings: the *Default templates* button is now *Add more built-ins* and opens a window titled *Built-in templates*. Its buttons are *Add* (the selected template) and *Add all* (everything on the current tab you do not have yet, not only the recommended set), both with tooltips.
- Shorter, situation-based intro texts on the Settings page and in the built-in templates and export / import windows.
- The *Spell table* button sat far outside the window (its anchor was measured from the wrong corner); it is back on the *Fill placeholders* row.
- *Share* moved next to the template name and opens its own small window, SimulationCraft style: the template's string, already selected for Ctrl+C, a *Close after copy* option and nothing else. Its tooltip is one line.
- *Export / Import* is now two windows: *Export* is the same copy window with the whole list, *Import* is a paste box with the *Same id* choice and an Import button, and it closes itself after a successful import.
- Built-in template names and descriptions rewritten for people who already use macros: names are short, action-first and usable as macro names (no punctuation, no counts, no (PvP) tags); a description says only what the name leaves out, such as the fallback order, a gotcha or a dependency. A copy you never edited picks up the new wording.
- New built-in **Cast together**: off-GCD cooldowns and a spell in one press (`/cast {CD}` · `/cast {CD_2}` · `/cast {SPELL}`, second cooldown optional).
- *Set focus* moved from PvP to Core (a Mythic+ staple); *Cancel buff and cast* likewise. The Sequence category is 順序施放 in 繁體中文.
- A fresh install now defaults to character macros; *Pick up after creating* stays on.
