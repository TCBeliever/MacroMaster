# MacroMaster

**Proven macro patterns, your spells.**

[繁體中文](README.zhTW.md) · [CurseForge](https://www.curseforge.com/wow/addons/macromaster) · [Report a bug](https://github.com/TCBeliever/MacroMaster/issues) · [Changelog](CHANGELOG.md)

![CurseForge downloads](https://cf.way2muchnoise.eu/1690683.svg) ![Game version](https://cf.way2muchnoise.eu/versions/1690683.svg) ![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)

Stop hand-editing macros from guides. Pick a proven template (mouseover heal, focus interrupt, arena target, cancel aura, cast sequence), fill in your own spells, create. Turn any macro into a template and share it as a string.

![MacroMaster main window](https://media.forgecdn.net/attachments/1939/153/screenshot-20260911-222315-png.png)

## Why MacroMaster

- **Templates, not snippets.** A template is a macro with blanks, such as `/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}`. You fill in `{HEAL}`; the conditions stay correct.
- **Your spells, suggested.** Every blank has a picker, and a per-class spell table puts the likely candidates first: your kick, your dispel, your defensive. The tables only suggest, so a template keeps working when a patch renames or removes a spell.
- **Remembered per character.** Fill in your interrupt once and every template that uses `{INTERRUPT}` is filled on that character.
- **Any macro in, a template out.** *Save as template* under Blizzard's macro window turns the spell and item names of an existing macro into blanks.
- **Share as one string.** A `!MM1!...` string survives Discord, forums and websites. Importing merges it into your list, and anything that would run Lua is called out in red first.

## Install

- **CurseForge app**: search for *MacroMaster*, or install from the [project page](https://www.curseforge.com/wow/addons/macromaster).
- **Manual**: download the zip from [Releases](https://github.com/TCBeliever/MacroMaster/releases) or CurseForge and unzip it into `World of Warcraft/_retail_/Interface/AddOns/` so that `AddOns/MacroMaster/MacroMaster.toc` exists.
- Retail only (Interface 12.1). Not built for Classic.

Open the window with `/mmac`, or with *Open* on the bar under Blizzard's macro window.

## Quick start

1. **Pick a template** from the list on the left.
2. **Fill the placeholders.** Every `{NAME}` in the template gets a row: type a spell, drag one from the spell book onto the box, or click *Pick*. Placeholders with fixed choices (arena slot, raid marker, trinket slot) use a dropdown instead.
3. **Create.** Name the macro (16 characters at most), choose *Account* or *Character*, click *Create*. The macro lands on your cursor: drop it on an action bar.

Tips

- A placeholder marked *optional* can stay empty; its line is dropped from the macro.
- The preview shows the finished macro and its character count. Red means it is over Blizzard's 255.
- The icon button left of the macro name picks an icon one of your existing macros already uses; right-click returns to the question mark. With `#showtooltip` the game shows the spell's icon anyway.
- A macro with the same name is overwritten only after you confirm.
- *All* on the arena placeholder creates `Name1`, `Name2` and `Name3` in one click.
- Untick *Pick up after creating* and the macro window opens instead, so you can drag the macro from there.
- *Import* under the template list turns one of your existing macros into a template; so does *Save as template* under Blizzard's macro window. Spell and item names become `{INTERRUPT}`, `{HEAL}`, `{POTION}`... when the spell table knows them, `{SPELL}` or `{ITEM}` otherwise (`{SPELL_2}` for a second one).

## Built-in templates

25 templates ship with the addon. A fresh install starts with the set recommended for your class (about eight); the rest wait in *Settings → Default templates*, grouped by category, with what fits your class listed first. Your list is entirely yours: edit, delete, add. A built-in you never edited picks up improvements on update; one you edited is left alone.

Most bodies start with a `#showtooltip` line, omitted below. `·` separates macro lines.

### Core

| Template | What it does | Body |
|---|---|---|
| Interrupt | Interrupts your target; hold Shift for your focus. Stops casting first. | `/stopcasting` · `/cancelaura {CANCEL}` · `/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}` |
| Quick ground spell | Ground-targeted spell at the cursor, no reticle. | `/cancelaura {CANCEL}` · `/cast [@cursor] {GROUND}` |
| Mouseover damage | Hostile spell on mouseover, else target. | `/cast [@mouseover,harm,nodead][] {HARM}` |
| Stopcast + cast | Cancels the current cast, then casts. | `/stopcasting` · `/cancelaura {CANCEL}` · `/cast {SPELL}` |
| Trinket + spell | A trinket (slot 13 or 14) and a cooldown in one press. | `/use {TRINKET}` · `/cast {CD}` |
| Self-heal combo | Self-heal, then Healthstone, then potion; one step per press, restarts after combat. | `/stopcasting` · `/castsequence [@player] reset=combat {SELFHEAL}, {HEALTHSTONE}, {POTION}` |
| Modifier: 2-3 spells | One button, up to three spells; Ctrl and Shift each pick another. | `/cast [mod:ctrl] {CTRL}; [mod:shift] {SHIFT}; {SPELL}` |
| Self-cast | Casts on yourself whatever you target. | `/cast [@player] {SPELL}` |
| External to focus | Misdirection, Tricks or a blessing to your focus, else your target's target, else your target. | `/cast [@focus,help,nodead][@targettarget,help,nodead][] {EXTERNAL}` |
| In combat / out of combat | One spell in combat, another out of it (Rebirth / Revive). | `/cast [combat] {INCOMBAT}; {SPELL}` |

### Healing

| Template | What it does | Body |
|---|---|---|
| Mouseover heal | Friendly spell on mouseover, else target, else yourself. | `/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}` |
| Mouseover dispel | Friendly dispel with the same fallbacks. | `/cast [@mouseover,help,nodead][help,nodead][@player] {DISPEL}` |
| Mouseover external | External cooldown with the same fallbacks. | `/cast [@mouseover,help,nodead][help,nodead][@player] {EXTERNAL}` |
| Target's target | Hit what your tank or friend is fighting without retargeting. | `/cast [@targettarget,harm,nodead][] {HARM}` |

### PvP

| Template | What it does | Body |
|---|---|---|
| Arena target | Casts on a fixed arena slot without changing your target. *All* makes three macros. | `/cancelaura {CANCEL}` · `/cast [@{ARENA}] {CC}` |
| Mouseover purge | Offensive dispel on mouseover, else target. | `/cast [@mouseover,harm,nodead][] {PURGE}` |
| Mouseover, Alt = focus | Hostile spell on mouseover, else target; hold Alt for your focus. | `/cancelaura {CANCEL}` · `/cast [mod:alt,@focus,harm,nodead][@mouseover,harm,nodead][] {HARM}` |
| Cancel aura + cast | Drops an immunity or a channel (Ice Block, Aspect of the Turtle, Deep Breath...), then casts. | `/cancelaura {AURA}` · `/cast {SPELL}` |
| Set focus | Focus your target, mark it, announce it to the group once per focus. | `/focus` · `/tm [@focus] ~{MARK}` · `/mmfocus {MSG} {rt{MARK}}` |
| FrameSort interrupt | Interrupts your focus, else the frame [FrameSort](https://www.curseforge.com/wow/addons/framesort) resolves (enemy healer by default). | `#FrameSort X {FSENEMY}` · `/cancelaura {CANCEL}` · `/cast [@focus,harm,nodead][@none,harm,nodead] {INTERRUPT}` |
| FrameSort ally external | External on mouseover, else the ally FrameSort resolves (your healer by default). | `#FrameSort X {FS}` · `/cast [@mouseover,help,nodead][@none,help,nodead] {EXTERNAL}` |
| FrameSort ally dispel | Dispel with the same FrameSort fallback. | `#FrameSort X {FS}` · `/cast [@mouseover,help,nodead][@none,help,nodead] {DISPEL}` |

### Sequence and pet

| Template | What it does | Body |
|---|---|---|
| Spell sequence | Two or three spells in order, one per press; you choose when it restarts. | `/castsequence reset={RESET} {SPELL}, {SPELL_2}, {SPELL_3}` |
| Once per target | Casts once, then nothing on that target until you switch target or leave combat. | `/castsequence reset=target/combat {SPELL}, null` |
| Pet attack + spell | Sends the pet in and casts, in one press. | `/petattack` · `/cast {SPELL}` |

A `/castsequence` stalls on a step whose spell is on cooldown or whose item you no longer carry, until it resets. In the self-heal combo, leave slots you do not use empty.

## Placeholders and variables

Anything in braces is a placeholder: `{INTERRUPT}`, `{地板技能}`, any name you like. Edit a template body freely; the placeholder rows follow the text. Names the addon knows get a label, a hint and suggestions:

| Placeholder | Filled with |
|---|---|
| `{INTERRUPT}` | your kick (Quell, Mind Freeze, Disrupt, Skull Bash...) |
| `{CC}` | crowd control, a kick, anything to throw at that arena slot |
| `{HEAL}` `{HARM}` `{SPELL}` | any healing spell, any damage spell, any spell |
| `{GROUND}` | a ground-targeted spell (Death and Decay, Heroic Leap...) |
| `{CD}` `{DEFENSIVE}` `{MOVEMENT}` | an offensive cooldown, a defensive, a movement spell |
| `{DISPEL}` `{PURGE}` `{EXTERNAL}` | a friendly dispel, an offensive dispel, a cooldown you cast on someone else |
| `{SELFHEAL}` | an instant self-heal (Renewal, Exhilaration, Word of Glory...) |
| `{AURA}` `{CANCEL}` | an aura to `/cancelaura`: Ice Block, Aspect of the Turtle, Deep Breath, Ghost Wolf... |
| `{HEALTHSTONE}` `{POTION}` `{ITEM}` | items from your bags; a Healthstone and the strongest healing potion you carry are pre-filled |
| `{ARENA}` | arena1, arena2, arena3, or *All* for one macro per slot |
| `{MARK}` `{MSG}` | a raid marker; an announcement text (`%f` focus name, `%t` target name) |
| `{FS}` `{FSENEMY}` | the ally or enemy frame FrameSort should resolve (Healer, OtherDps, EnemyHealer...) |
| `{TRINKET}` `{RESET}` `{CTRL}` `{SHIFT}` `{INCOMBAT}` | trinket slot 13 or 14; a `castsequence` reset rule; the spells of the modifier and combat templates |

Aliases: `KICK` = INTERRUPT, `CD` = BURST, `DEF` = DEFENSIVE, `MOVE` = MOVEMENT, `AOE` = GROUND, `CLEANSE` = DISPEL, `EXT` = EXTERNAL, `AURA` / `CANCEL` = CANCELAURA, `HEALPOT` = POTION.

How empty placeholders behave: an *optional* one drops its whole line; one inside a comma list or a `;` clause disappears together with its separator (`{A}, {B}, {C}` with `{B}` empty becomes `{A}, {C}`); any other empty placeholder blocks *Create* until you fill it.

**Spell table** (button on the *Fill placeholders* row) edits the suggestion lists for your class. Entries are spell IDs resolved when the window opens: a spell this character cannot cast is greyed out, one removed from the game disappears, and templates are never affected. Add from the picker, remove with ✕, or reset a category to the shipped list. **Variables** (next to *Update template*) is the in-game version of the table above.

## Sharing templates

- **Share** on the editor gives the current template as one string, `!MM1!...`. *Settings → Export / Import → Export* gives all your templates as one string, handy as a backup.
- To import, paste a string (or an older plain-text export) into that window and press *Import*. The **Same id** choice decides what happens to a template you already have: *Replace* overwrites your copy (restoring a backup), *Add new* adds it next to yours (keeping your version).
- **Safety.** A macro line can run Lua (`/run`, `/script`, `/dump`, `/console`), and such a line from a stranger can do anything an addon can. MacroMaster flags such templates in red under the editor and in the preview, the import confirmation counts them, and creating the macro asks for a red confirmation that lists the code lines. Your own `/run` templates work as before. Import only from people you trust.

## Settings

The *Settings* tab (bottom of the window) holds:

- **Language**: auto, English or 繁體中文, applied after a UI reload. Built-in names and descriptions you never edited follow the language.
- **Default templates**: the read-only catalogue of shipped templates. *Add to my templates*, overwrite your copy with the default, or reset the whole list to your class's recommended set.
- **Export / Import**: see above.

Macro scope (account or character) and *Pick up after creating* are remembered. Templates, the values you filled in per character, chosen icons and spell-table edits live in `MacroMasterDB` (account-wide SavedVariables).

## Slash commands

| Command | Effect |
|---|---|
| `/mmac`, `/macromaster` | open or close the window |
| `/mmac help` | list the commands |
| `/mmfocus <text>` | announce your focus to the group, once per focus; `%f`, `%t` and `{rtN}` expand as in chat; silent when not grouped. Used by the *Set focus* template. |

## Limits and FAQ

- **Blizzard limits**: macro name 16 characters, body 255 characters, 120 account and 30 character macros (12.1). Macros cannot be created or edited in combat.
- **The preview count is red.** Shorten the macro: leave optional lines empty, drop the spell after `#showtooltip`, or trim conditions.
- **A spell is greyed out in the picker.** This character cannot cast it right now (other spec, missing talent). It stays in the table for when it can.
- **"Not in your spell book" when creating.** A warning only; the macro is still created. Check the spelling, or ignore it for pet spells and items.
- **The macro window still shows the old version number after an update.** WoW reads the addon's version at client start; `/reload` is not enough.

## Localization and contributing

- Languages: English and 繁體中文, in [Locales.lua](Locales.lua). To add one, copy the `zhTW` table, translate, and open a pull request.
- Bugs and ideas: [GitHub Issues](https://github.com/TCBeliever/MacroMaster/issues) or the CurseForge comments. Include the Lua error text if there is one.

## Development

```
MacroMaster/
├── MacroMaster.toc
├── Locales.lua        -- enUS defaults + zhTW
├── Templates.lua      -- built-in templates, DB, placeholder parsing and substitution, share strings, macro -> template
├── SpellPicker.lua    -- spell book / bag / icon pickers
├── Suggestions.lua    -- per-class spell tables and categories
├── Panels.lua         -- variables reference, defaults catalogue, export / import, spell table, settings page
├── UI.lua             -- main window and the create flow
├── Core.lua           -- events, slash commands, the bar under Blizzard's macro window
├── Libs/              -- LibStub, LibDeflate
├── .pkgmeta           -- CurseForge packager
├── .github/workflows  -- release on tag
└── deploy.bat         -- copy into the AddOns folder for local testing
```

- **Local testing**: set `DST` in `deploy.bat` to your AddOns folder, run it, `/reload` in game. A changed `.toc` needs a full client restart.
- **Release**: bump `## Version` in the toc, add a `## x.y.z (date)` section at the end of `CHANGELOG.md`, then `git tag vX.Y.Z && git push --tags`. GitHub Actions runs the BigWigs packager, uploads the zip to CurseForge with that version's notes and attaches it to a GitHub release.
- **Share string format**, for anyone who wants to decode it on a website: `!MM1!` followed by LibDeflate's `EncodeForPrint` of the raw-deflated plain text. The plain text is `MacroMaster templates 1`, then one `[template]` record per template with `id=`, `name=`, `desc=` and `body=` lines; backslash and newline inside a value are escaped as `\\` and `\n`.

## Credits and license

MIT, see [LICENSE](LICENSE). Bundled libraries: [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) by SafeteeWoW (zlib licence) and LibStub (public domain). The FrameSort templates target the `#FrameSort` directive of the [FrameSort](https://www.curseforge.com/wow/addons/framesort) addon.
