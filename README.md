# MacroMaster

Macro templates with spell placeholders. Pick a template, fill in **your own** spells from a picker (or drag them from the spell book), choose account or character scope, create the macro. Any existing macro can be turned into a template with one click.

MacroMaster never guesses which spell your class should use — it suggests structure, you supply the spell. That is why it needs no per-class tables and keeps working across patches.

## Workflow

1. **Template** — choose one from the left list (or *New*, or *Import* an existing macro).
2. **Fill placeholders** — every `{NAME}` in the template gets a row: type a spell, drag one from your spell book onto the box, or click *Pick* for a searchable icon grid. Fixed-choice placeholders (e.g. `arena1/2/3`) show quick buttons instead. Your choices are remembered per character, so your kick stays filled when you switch templates.
3. **Create** — name it (≤16 chars), choose *Account* or *Character*, click *Create*. The icon button left of the name picks an icon one of your existing macros already uses (right-click: back to the question mark); with `#showtooltip` the game shows the spell's icon regardless. The macro lands on your cursor so you can drop it on an action bar. If a macro with that name already exists you are asked before it is overwritten.

`ESC` closes the window; `/macromaster` or `/mmac` opens it. Blizzard's macro window gets two extra buttons: **MacroMaster** (open) and **Save as template** (turn the selected macro into a template). Spells and items in the macro become placeholders automatically: one the spell table knows becomes its variable (`{INTERRUPT}`, `{CC}`, `{HEAL}`, `{POTION}`, `{HEALTHSTONE}`...), anything else `{SPELL}` or `{ITEM}`, a second of the same kind `{SPELL_2}`; `spell:1234` / `item:1234` are resolved to names.

## Built-in templates

| Template | Body |
|---|---|
| Interrupt: focus, else target | `/stopcasting` · `/cancelaura {CANCEL}` · `/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}` |
| Arena: cast on arena1/2/3 | `/cast [@{ARENA}] {CC}` |
| Ground spell @cursor | `/cast [@cursor] {GROUND}` |
| Heal: mouseover > target > self | `/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}` |
| Damage: mouseover > target | `/cast [@mouseover,harm,nodead][] {HARM}` |
| Stopcasting + cast | `/stopcasting` · `/cast {SPELL}` |
| Trinket + spell | `/use 13` · `/cast {CD}` |
| Set focus | `/focus` · `/tm [@focus] ~{MARK}` · `/mmfocus {MSG} {rt{MARK}}` |
| Self-heal combo | `/stopcasting` · `/castsequence [@player] reset=combat {SELFHEAL}, {HEALTHSTONE}, {POTION}` |
| Modifier: 2-3 spells | `/cast [mod:ctrl] {CTRL}; [mod:shift] {SHIFT}; {SPELL}` |
| Self-cast | `/cast [@player] {SPELL}` |
| Cancel aura + cast | `/cancelaura {AURA}` · `/cast {SPELL}` |
| External to focus | `/cast [@focus,help,nodead][@targettarget,help,nodead][] {EXTERNAL}` |
| Mouseover, Alt = focus | `/cast [mod:alt,@focus,harm,nodead][@mouseover,harm,nodead][] {HARM}` |
| In combat / out of combat | `/cast [combat] {INCOMBAT}; {SPELL}` |
| Target's target | `/cast [@targettarget,harm,nodead][] {HARM}` |
| Pet attack + spell | `/petattack` · `/cast {SPELL}` |
| Spell sequence | `/castsequence reset={RESET} {SPELL}, {SPELL_2}, {SPELL_3}` |
| Once per target | `/castsequence reset=target/combat {SPELL}, null` |

A fresh install starts with the templates recommended for your class (about eight); the rest live in the catalogue (*Settings* -> *Default templates*), grouped by category, with what fits your class first. Categorised placeholders start filled with the first suggestion your character knows.

The self-heal combo is a plain `/castsequence`: a step whose spell is on cooldown or whose item you no longer carry stalls the sequence until it resets after combat, so leave slots you do not use empty.

Your list starts as a copy of these and is entirely yours: edit, delete, add. The *Settings* tab (bottom of the window) holds the language switch (auto / English / 繁體中文, applied after a UI reload) and two doors: *Default templates*, the read-only catalogue of shipped templates — add one back (or overwrite your copy with the default), or reset the whole list — and *Export / Import*, which turns all your templates into one share string (`!MM1!...`) you can copy out as a backup or paste anywhere, and imports such strings (or the older plain text) back (a template you already have either replaces your copy or is added next to it: the *Same id* choice in that window). *Share* on the editor gives the string for the current template alone. A template that runs Lua (`/run`, `/script`) is flagged in red under the editor and in the preview, the import confirmation counts such templates, and creating the macro asks for a red confirmation listing the code lines — a safeguard for strings that come from someone else.

## Variables and the spell table

*Variables* (bottom-left) lists every built-in placeholder and its meaning. Placeholders whose name matches a category — `INTERRUPT`, `CC`, `DEFENSIVE`, `BURST` (alias `CD`), `MOVEMENT`, `GROUND`, `HEAL` — get that category's spells suggested at the top of the picker.

`{HEALTHSTONE}` and `{POTION}` (alias `HEALPOT`) are *item* placeholders: *Pick* opens your bags instead of the spell book (suggested items first, then every usable item), you can drag an item from a bag onto the box, and a Healthstone / the strongest healing potion you carry is pre-filled. Values are item names, so any rank works. In a comma list such as a `/castsequence`, an empty item slot simply disappears together with its comma.

*Spell table* edits those suggestions for the current class. Entries are spell IDs resolved when the window opens: a spell this character cannot cast is greyed out, a spell removed from the game disappears, and templates are never affected. Add from the picker, remove with ✕, or reset a category to the shipped list.

## Writing templates

A placeholder is anything in braces: `{INTERRUPT}`, `{地板技能}`. Edit the body freely — the placeholder rows follow the text. Templates are account-wide (`MacroMasterDB`).

## Limits (Blizzard)

Macro name 16 characters, body 255 characters, 120 account macros, 30 character macros (12.1). Macros cannot be created or edited in combat.

---

# MacroMaster（繁體中文）

巨集模板 + 法術佔位符。選模板 → 用選擇器（或從法術書拖曳）填入**你自己的**技能 → 選共用或角色專屬 → 建立。任何現有巨集都能一鍵存成模板。

MacroMaster 不會替你猜職業該用哪個技能，它只提供結構，技能由你決定——所以不需要維護職業對照表，改版也不會壞。

## 流程

1. **模板**：左邊清單選一個（或「新增」、「匯入」現有巨集）。
2. **填入技能**：模板裡每個 `{名稱}` 一列：打字、從法術書拖到框裡、或按「選擇」開圖示格搜尋。固定選項的佔位符（如 arena1/2/3）直接給按鈕。填過的值按角色記住，換模板時斷法技能不用重填。
3. **建立**：取名（≤16 字）、選「共用」或「角色專屬」、按「建立」。巨集會放到游標上，直接丟到動作列。同名巨集會先問你要不要覆蓋。

`/macromaster` 或 `/mmac` 開視窗，`ESC` 關閉。暴雪巨集視窗右側多兩顆按鈕：**MacroMaster**（開啟）與**存成模板**（把選取的巨集轉成模板，法術名自動變佔位符）。

## 開發

```
MacroMaster/
├── MacroMaster.toc
├── Locales.lua      -- enUS 預設 + zhTW
├── Templates.lua    -- 內建模板、DB、佔位符解析/替換、巨集→模板
├── SpellPicker.lua  -- 法術書掃描、圖示選擇器
├── UI.lua           -- 主視窗、建立流程
├── Core.lua         -- 事件、slash、暴雪巨集視窗按鈕
├── .pkgmeta         -- CurseForge packager
└── deploy.bat       -- 複製到 AddOns 做本機測試
```

本機測試：執行 `deploy.bat` → 遊戲內 `/reload`。發佈：`git tag v1.0.1 && git push --tags`。

## License

MIT
