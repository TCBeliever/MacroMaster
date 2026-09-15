**Macros as easy as picking a spell.**

[繁體中文說明](https://github.com/TCBeliever/MacroMaster/blob/main/README.zhTW.md)

## Why MacroMaster

- **Templates, not snippets.** A template is a macro with blanks, such as `/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}`. You fill in `{HEAL}`; the conditions stay correct.
- **Your spells, suggested.** Every blank has a picker, and a per-class spell table puts the likely candidates first: your kick, your dispel, your defensive. The tables only suggest, so a template keeps working when a patch renames or removes a spell.
- **Remembered per character.** Fill in your interrupt once and every template that uses `{INTERRUPT}` is filled on that character.
- **Any macro in, a template out.** *Save as template* under Blizzard's macro window turns the spell and item names of an existing macro into blanks.
- **Share as one string.** A `!MM1!...` string survives Discord, forums and websites. Importing merges it into your list, and anything that would run Lua is called out in red first.

## Quick start

1. **Pick a template** from the list on the left.
2. **Fill the placeholders.** Every `{NAME}` in the template gets a row: type a spell, drag one from the spell book onto the box, or click *Pick*. Placeholders with fixed choices (arena slot, raid marker, trinket slot) use a dropdown instead. A placeholder marked *optional* can stay empty; its line is dropped.
3. **Create macro.** Name it, choose *Account* or *Character*, press *Create macro*. The macro lands on your cursor: drop it on an action bar. The preview above shows the finished macro and its character count.

`/mmac` opens the window; so does *Open* on the bar under Blizzard's macro window. *Save as template* on that bar turns the selected macro into a template.

## What's inside

26 templates. A fresh install starts with the eight or so recommended for your class; the rest sit in *Settings → Add more built-ins*, grouped as below.

**Core**

- **Interrupt**: interrupts your target, hold Shift for your focus. Stops your own cast first.
- **Cast at cursor**: ground spell where the mouse is, no reticle.
- **Mouseover damage**: mouseover first, then your target.
- **Stopcast and cast**: fires even mid-cast.
- **Cancel aura and cast**: act straight out of an immunity or a channel.
- **Trinket and burst**: trinket slot 13 or 14 and a cooldown in one press. On-use trinkets only.
- **Self-heal combo**: self-heal > Healthstone > potion, one step per press; restarts after combat.
- **Modifier switch**: one button, Ctrl and Shift each switch to another spell.
- **Self-cast**: casts on yourself and leaves your current target alone.
- **External to focus**: focus first, then your target's target, then your target.
- **Combat switch**: one spell in combat, another out of it; battle rez and normal rez on one slot, for example.
- **Cast together**: off-GCD cooldowns and a spell in one press.
- **Set focus**: focus, mark, tell the group; no repeat for the same focus.

**Healing**

- **Mouseover heal**: mouseover first, then your target, then yourself.
- **Mouseover dispel**: same order, for a friendly dispel.
- **Mouseover external**: same order, for an external cooldown.
- **Hit target's target**: with a tank or ally targeted, hits whatever they are fighting.

**PvP**

- **Arena target**: casts straight at arena1/2/3 without switching targets; *All* makes the three macros at once.
- **Mouseover purge**: mouseover first, then your target.
- **Mouseover with Alt focus**: mouseover first, then your target; hold Alt for your focus.
- **FrameSort interrupt**: focus first, then the frame FrameSort picks, enemy healer by default.
- **FrameSort external**: mouseover first, then the ally FrameSort picks, your healer by default.
- **FrameSort dispel**: same as the external, for a dispel.

The three FrameSort templates need the [FrameSort](https://www.curseforge.com/wow/addons/framesort) addon.

**Sequence and pet**

- **Spell sequence**: two or three spells in order, one per press; you choose when it restarts.
- **Once per target**: fires again only after a target switch or leaving combat.
- **Pet attack and cast**: the pet attacks your target while you cast.

Your list is entirely yours: edit, delete, add. A built-in you never edited picks up improvements on update; one you edited is left alone.

## Sharing templates

- **Share**, next to the template name, gives the current template as one string, selected and ready for Ctrl+C. *Settings → Export* gives your whole list as one string, handy as a backup.
- **Import** (*Settings → Import*): paste a string, press Import. A template you already have is either replaced or added as a copy; you choose.
- **Safety.** A macro line can run Lua (`/run`, `/script`), and such a line from a stranger can do anything an addon can. MacroMaster marks such templates in red in the editor and the preview, counts them in the import confirmation, and asks once more, in red, before creating the macro. Your own `/run` templates work as before.

Templates of your own are welcome in the comments here: paste the string.

## Slash commands

| Command | Effect |
|---|---|
| `/mmac`, `/macromaster` | open or close the window |
| `/mmfocus <text>` | announce your focus to the group, once per focus; `%f`, `%t` and `{rtN}` expand as in chat; silent when not grouped. Used by the *Set focus* template. |

## Limits and FAQ

- **Blizzard limits**: macro name 16 characters, body 255 characters, 120 account and 30 character macros. Macros cannot be created or edited in combat.
- **The preview count is red.** Shorten the macro: leave optional lines empty, drop the spell after `#showtooltip`, or trim conditions.
- **A spell is greyed out in the picker.** This character cannot cast it right now (other spec, missing talent). It stays in the table for when it can.
- **"Not in your spell book" when creating.** A warning only; the macro is still created. Check the spelling, or ignore it for pet spells and items.
- **The window still shows the old version after an update.** WoW reads the addon's version at client start; `/reload` is not enough.

## Links

- [Full documentation](https://github.com/TCBeliever/MacroMaster#readme): every placeholder and its category, the spell table, writing your own templates.
- [Bug reports and ideas](https://github.com/TCBeliever/MacroMaster/issues), or the comments here. Include the Lua error text if there is one.
- Translations welcome: English and 繁體中文 so far, see [Locales.lua](https://github.com/TCBeliever/MacroMaster/blob/main/Locales.lua).

Bundles [LibDeflate](https://github.com/SafeteeWoW/LibDeflate) (zlib licence) and LibStub (public domain).
