# MacroMaster

**巨集，像選技能一樣簡單。**

[English](README.md) · [CurseForge](https://www.curseforge.com/wow/addons/macromaster) · [回報問題](https://github.com/TCBeliever/MacroMaster/issues) · [更新記錄](CHANGELOG.md)

寫巨集變得像選技能一樣簡單。選一個驗證過的模板（滑鼠指向治療、焦點斷法、競技場目標、取消光環、施法序列），填入自己的技能，建立。任何巨集都能存成模板，模板可以用一串字分享。

![MacroMaster 主視窗](https://media.forgecdn.net/attachments/1939/153/screenshot-20260911-222315-png.png)

## 為什麼用 MacroMaster

- **模板，不是片段。** 模板就是留了空格的巨集，例如 `/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}`。你只填 `{HEAL}`，條件式不會填錯。
- **技能由你決定，插件負責建議。** 每個空格都有選擇器，各職業的技能表把最可能的候選排在前面：你的斷法、你的驅散、你的保命技。技能表只負責建議，改版技能改名或移除，模板照樣能用。
- **按角色記住。** 斷法技能填一次，這隻角色所有用到 `{INTERRUPT}` 的模板都已填好。
- **任何巨集都能變模板。** 暴雪巨集視窗下方的「存成模板」會把現有巨集裡的技能與物品名稱自動變成空格。
- **一串字就能分享。** `!MM1!...` 字串貼到 Discord、論壇、網站都不會壞。匯入時併進你的清單，會執行 Lua 的內容先用紅字提醒。

## 安裝

- **CurseForge App**：搜尋 *MacroMaster*，或從[專案頁](https://www.curseforge.com/wow/addons/macromaster)安裝。
- **手動**：從 [Releases](https://github.com/TCBeliever/MacroMaster/releases) 或 CurseForge 下載 zip，解壓到 `World of Warcraft/_retail_/Interface/AddOns/`，確認有 `AddOns/MacroMaster/MacroMaster.toc`。
- 只支援正式服（Interface 12.1），沒有做 Classic。

輸入 `/mmac` 開視窗，或按暴雪巨集視窗下方工具列的「開啟」。

## 快速上手

1. **選模板**：左邊清單選一個。
2. **填入技能**：模板裡每個 `{名稱}` 一列。打字、從法術書拖到框裡、或按「選擇」開圖示格搜尋。固定選項的佔位符（競技場欄位、團隊標記、飾品欄位）改用下拉選單。
3. **建立**：取巨集名稱（最多 16 字）、選「共用」或「角色專屬」、按「建立巨集」。巨集會放到游標上，直接丟到動作列。

小技巧

- 標示「（選填）」的佔位符可以留空，那一行會從巨集裡拿掉。
- 預覽區顯示完成後的巨集和字數，紅色代表超過暴雪的 255 字上限。
- 巨集名稱左邊的圖示按鈕可以選一個你現有巨集已在用的圖示，右鍵還原成問號。有 `#showtooltip` 時遊戲本來就會顯示技能圖示。
- 同名巨集會先問你，確認後才覆蓋。
- 競技場佔位符選「全部」會一次建立 `名稱1`、`名稱2`、`名稱3`。
- 取消「建立後拾取到游標」時會改開巨集視窗，讓你自己拖。
- 清單下方的「匯入」能把你現有的巨集轉成模板；暴雪巨集視窗下方的「存成模板」也一樣。技能與物品名稱會依技能表變成 `{INTERRUPT}`、`{HEAL}`、`{POTION}`…，不認得的變成 `{SPELL}` 或 `{ITEM}`（第二個是 `{SPELL_2}`）。

## 內建模板

內附 26 個模板。全新安裝時清單只有你這個職業的推薦組（約八個），其餘在「設定 → 加入其他內建模板」依分類列出，適合你職業的排前面。清單完全是你的：改、刪、加都可以。沒改過的內建模板更新時會自動跟上新版，改過的不動。

大多數模板第一行是 `#showtooltip`，下表省略；`·` 分隔巨集的行。

### 核心

| 模板 | 用途 | 內容 |
|---|---|---|
| 斷法 | 打斷目標；按住 Shift 改打斷焦點。施放前先停止施法。 | `/stopcasting` · `/cancelaura {CANCEL}` · `/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}` |
| 游標地板技 | 地板技能直接放在游標位置，不出準星。 | `/cancelaura {CANCEL}` · `/cast [@cursor] {GROUND}` |
| 滑鼠指向傷害 | 敵對技能：滑鼠指向 > 目標。 | `/cast [@mouseover,harm,nodead][] {HARM}` |
| 停讀條施放 | 取消當前讀條後立刻施放。 | `/stopcasting` · `/cancelaura {CANCEL}` · `/cast {SPELL}` |
| 取消 buff 後施放 | 先取消免疫或引導（寒冰屏障、巨龜守護、深層吐息…）再施放。 | `/cancelaura {AURA}` · `/cast {SPELL}` |
| 飾品加爆發 | 一鍵使用飾品（13 或 14 格）並施放爆發。 | `/use {TRINKET}` · `/cast {CD}` |
| 自救序列 | 自療 → 治療石 → 藥水，每按一次一步，脫戰後重來。 | `/stopcasting` · `/castsequence [@player] reset=combat {SELFHEAL}, {HEALTHSTONE}, {POTION}` |
| 多技能切換 | 一顆鍵最多三個技能，Ctrl、Shift 各放另一個。 | `/cast [mod:ctrl] {CTRL}; [mod:shift] {SHIFT}; {SPELL}` |
| 自我施放 | 不管選著誰，都放在自己身上。 | `/cast [@player] {SPELL}` |
| 外援給焦點 | 誤導、嫁禍或祝福給焦點；沒焦點就給目標的目標，再沒有就給目標。 | `/cast [@focus,help,nodead][@targettarget,help,nodead][] {EXTERNAL}` |
| 戰鬥內外切換 | 戰鬥中放一個、戰鬥外放另一個（復生／甦醒）。 | `/cast [combat] {INCOMBAT}; {SPELL}` |
| 同時施放 | 不吃公共冷卻的爆發技和主技能一鍵放出。 | `/cast {CD}` · `/cast {CD_2}` · `/cast {SPELL}` |
| 設定焦點 | 把目標設為焦點，上標記，並在隊伍裡喊話（每次換焦點只喊一次）。 | `/focus` · `/tm [@focus] ~{MARK}` · `/mmfocus {MSG} {rt{MARK}}` |

### 治療

| 模板 | 用途 | 內容 |
|---|---|---|
| 滑鼠指向治療 | 友方技能：滑鼠指向 > 目標 > 自己。 | `/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}` |
| 滑鼠指向驅散 | 友方驅散，同樣的順序。 | `/cast [@mouseover,help,nodead][help,nodead][@player] {DISPEL}` |
| 滑鼠指向外援 | 外援技能，同樣的順序。 | `/cast [@mouseover,help,nodead][help,nodead][@player] {EXTERNAL}` |
| 打目標的目標 | 選著坦克或隊友就能打他正在打的怪，不用換目標。 | `/cast [@targettarget,harm,nodead][] {HARM}` |

### PvP

| 模板 | 用途 | 內容 |
|---|---|---|
| 競技場目標 | 不切目標，直接對固定的競技場欄位施放；選「全部」一次做三個。 | `/cancelaura {CANCEL}` · `/cast [@{ARENA}] {CC}` |
| 滑鼠指向進攻驅散 | 進攻驅散：滑鼠指向 > 目標。 | `/cast [@mouseover,harm,nodead][] {PURGE}` |
| 滑鼠指向 Alt 焦點 | 敵對技能打滑鼠指向，沒有就打目標；按住 Alt 改打焦點。 | `/cancelaura {CANCEL}` · `/cast [mod:alt,@focus,harm,nodead][@mouseover,harm,nodead][] {HARM}` |
| FrameSort 斷法 | 打斷焦點，沒有就打斷 [FrameSort](https://www.curseforge.com/wow/addons/framesort) 解析的框架（預設敵方補師）。 | `#FrameSort X {FSENEMY}` · `/cancelaura {CANCEL}` · `/cast [@focus,harm,nodead][@none,harm,nodead] {INTERRUPT}` |
| FrameSort 外援 | 外援給滑鼠指向，沒有就給 FrameSort 解析的隊友（預設補師）。 | `#FrameSort X {FS}` · `/cast [@mouseover,help,nodead][@none,help,nodead] {EXTERNAL}` |
| FrameSort 驅散 | 驅散，同樣的 FrameSort 後備順序。 | `#FrameSort X {FS}` · `/cast [@mouseover,help,nodead][@none,help,nodead] {DISPEL}` |

### 順序施放與寵物

| 模板 | 用途 | 內容 |
|---|---|---|
| 技能序列 | 兩到三個技能照順序放，每按一次一個；可選重置時機。 | `/castsequence reset={RESET} {SPELL}, {SPELL_2}, {SPELL_3}` |
| 每目標放一次 | 對同一個目標只放一次，換目標或脫戰後才會再放。 | `/castsequence reset=target/combat {SPELL}, null` |
| 寵物一起攻擊 | 寵物上去打的同時施放技能。 | `/petattack` · `/cast {SPELL}` |

`/castsequence` 遇到某一步技能在冷卻或物品不在身上，會停在那一步直到重置。自救序列用不到的欄位請留空。

## 佔位符與變數

大括號裡的任何東西都是佔位符：`{INTERRUPT}`、`{地板技能}`，名字隨你取。模板內容可以自由編輯，下面的填入列會跟著變。插件認得的名字會有標籤、提示和建議：

| 佔位符 | 填什麼 |
|---|---|
| `{INTERRUPT}` | 你的斷法（沉默、心靈冰凍、瓦解、顱骨重擊…） |
| `{CC}` | 控場、斷法，任何要丟給那個競技場欄位的技能 |
| `{HEAL}` `{HARM}` `{SPELL}` | 任何治療技能、任何傷害技能、任何技能 |
| `{GROUND}` | 地板技能（死亡凋零、英勇跳躍…） |
| `{CD}` `{DEFENSIVE}` `{MOVEMENT}` | 爆發技、保命技、位移技 |
| `{DISPEL}` `{PURGE}` `{EXTERNAL}` | 友方驅散、進攻驅散、給別人的保命技 |
| `{SELFHEAL}` | 瞬發自療（復甦、振奮、榮耀聖言…） |
| `{AURA}` `{CANCEL}` | 要 `/cancelaura` 的光環：寒冰屏障、巨龜守護、深層吐息、幽魂之狼… |
| `{HEALTHSTONE}` `{POTION}` `{ITEM}` | 背包裡的物品；治療石和身上最強的治療藥水會自動填好 |
| `{ARENA}` | arena1、arena2、arena3，或「全部」一個欄位一個巨集 |
| `{MARK}` `{MSG}` | 團隊標記；喊話文字（`%f` 焦點名、`%t` 目標名） |
| `{FS}` `{FSENEMY}` | FrameSort 要解析的隊友或敵方框架（Healer、OtherDps、EnemyHealer…） |
| `{TRINKET}` `{RESET}` `{CTRL}` `{SHIFT}` `{INCOMBAT}` | 飾品 13 或 14 格；`castsequence` 的重置條件；修飾鍵與戰鬥模板裡的技能 |

別名：`KICK` = INTERRUPT、`CD` = BURST、`DEF` = DEFENSIVE、`MOVE` = MOVEMENT、`AOE` = GROUND、`CLEANSE` = DISPEL、`EXT` = EXTERNAL、`AURA`／`CANCEL` = CANCELAURA、`HEALPOT` = POTION。

留空的行為：「選填」的佔位符整行拿掉；逗號清單或 `;` 子句裡的佔位符連同分隔符號一起消失（`{A}, {B}, {C}` 的 `{B}` 留空變成 `{A}, {C}`）；其他佔位符留空時「建立」會擋下來，要你填完。

**技能表**（「填入技能」那一列的按鈕）編輯你這個職業的建議清單。存的是法術 ID，開視窗時才解析：這隻角色現在不會的技能變灰，遊戲裡已移除的直接消失，模板本身不受影響。可從選擇器新增、按 ✕ 移除、或把某個分類還原成內建清單。**變數說明**（「更新模板」旁邊）就是上面這張表的遊戲內版本。

## 分享模板

- 模板名稱旁的「分享」會把目前的模板變成一串 `!MM1!...` 字串，已反白，直接 Ctrl+C。「設定 → 匯出」則是所有模板一串，適合備份。
- 「設定 → 匯入」：把字串（或舊版的純文字）貼進去按「匯入」。「同 id」決定遇到你已經有的模板怎麼辦：「取代」覆蓋你的那份（還原備份用），「另外新增」並排加一份（保留你的）。
- **安全。** 巨集可以執行 Lua（`/run`、`/script`、`/dump`、`/console`），陌生人給的這種行能做到插件能做的任何事。MacroMaster 會在編輯區下方和預覽裡用紅字標出這種模板，匯入確認視窗會算有幾個，建立巨集時會再跳紅字確認並列出那些行。你自己寫的 `/run` 模板照常能用。只匯入你信任的人給的東西。

## 設定

視窗底部的「設定」分頁：

- **語言**：自動、English、繁體中文，重新載入介面後生效。沒改過的內建模板名稱與說明會跟著語言走。
- **加入其他內建模板**：內附模板的目錄。「加入」放進選取的那一個，「全部加入」拿走這個分頁裡你還沒有的，已經有的可以用預設覆蓋，「全部還原成預設」回到職業推薦組。
- **匯出**、**匯入**：見上一節。

巨集範圍（共用或角色專屬）和「建立後拾取到游標」會記住。模板、每隻角色填過的值、選的圖示、技能表的修改都存在 `MacroMasterDB`（帳號共用的 SavedVariables）。

## 斜線指令

| 指令 | 效果 |
|---|---|
| `/mmac`、`/macromaster` | 開關視窗 |
| `/mmac help` | 列出指令 |
| `/mmfocus <文字>` | 在隊伍裡喊出焦點，每次換焦點只喊一次；`%f`、`%t`、`{rtN}` 和聊天一樣會展開；不在隊伍裡就不喊。「設定焦點」模板用的就是它。 |

## 限制與常見問題

- **暴雪限制**：巨集名稱 16 字、內容 255 字、帳號共用 120 個、角色專屬 30 個（12.1）。戰鬥中不能建立或修改巨集。
- **預覽字數變紅**：把巨集縮短。選填的行留空、拿掉 `#showtooltip` 後面的技能名、或精簡條件式。
- **選擇器裡技能是灰的**：這隻角色現在不會這個技能（別的專精、沒點天賦）。它會留在表裡，等你會了再用。
- **建立時說「不在法術書裡」**：只是提醒，巨集照樣建立。檢查拼字，寵物技能和物品可以無視。
- **更新後視窗標題還是舊版號**：WoW 只在客戶端啟動時讀插件版本，`/reload` 不會更新。

## 語言與貢獻

- 語言：English、繁體中文，都在 [Locales.lua](Locales.lua)。要加新語言，複製 `zhTW` 那張表翻譯後開 pull request。
- 問題與建議：[GitHub Issues](https://github.com/TCBeliever/MacroMaster/issues) 或 CurseForge 留言。有 Lua 錯誤請附上錯誤文字。
- 專案結構、本機測試與發版流程見英文 README 的 [Development](README.md#development) 一節。

## 授權

MIT，見 [LICENSE](LICENSE)。內附函式庫：[LibDeflate](https://github.com/SafeteeWoW/LibDeflate)（zlib 授權）與 LibStub（公有領域）。FrameSort 系列模板使用 [FrameSort](https://www.curseforge.com/wow/addons/framesort) 插件的 `#FrameSort` 指令。
