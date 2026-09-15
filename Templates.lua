local ADDON, ns = ...
local L = ns.L

-- ---------------------------------------------------------------------------
-- Template model
--
--   template = {
--     id      = "focus_interrupt",   -- stable key (built-ins) or "user_<time>"
--     name    = "...",
--     desc    = "...",
--     body    = "#showtooltip\n/cast [@focus,harm,nodead][] {INTERRUPT}",
--     meta    = { INTERRUPT = { label=..., hint=..., options={...} } },  -- optional, per placeholder
--     builtin = true|nil,
--   }
--
-- Placeholders are simply {NAME} tokens in the body. Anything the user types
-- in that form becomes a placeholder; `meta` only adds a friendly label,
-- a hint, and (for non-spell placeholders) quick-pick option buttons.
-- ---------------------------------------------------------------------------

local PH_PATTERN = "{([^{}%%s]+)}"
ns.PH_PATTERN = PH_PATTERN

local DB_VERSION = 3

-- Names, descriptions, labels and hints are locale keys resolved through L;
-- the keys are kept so ns.RelocalizeBuiltins can resolve them again after
-- the saved language is applied.
local function B(id, name, desc, body, meta)
	return { id = id, nameKey = name, descKey = desc, name = L[name], desc = L[desc], body = body, meta = meta, builtin = true }
end

local function P(label, hint, options, multi, suffixes)
	-- options : fixed choices shown in a dropdown instead of the spell picker
	-- multi   : the dropdown also offers "All" -> one macro per option
	-- suffixes: appended to the macro name per option (defaults to the option)
	return { labelKey = label, hintKey = hint, label = L[label], hint = L[hint], options = options, multi = multi, suffixes = suffixes }
end

-- Same, with extra fields: optional (unfilled -> its line is dropped),
-- default (pre-filled value) or defaultKey (localized default),
-- category (suggestion list to show).
local function PX(label, hint, extra)
	local m = P(label, hint, extra.options)
	for k, v in pairs(extra) do m[k] = v end
	if m.defaultKey then m.default = L[m.defaultKey] end
	if m.labelKeys then
		m.labels = {}
		for i, k in ipairs(m.labelKeys) do m.labels[i] = L[k] end
	end
	return m
end

function ns.RelocalizeBuiltins()
	for _, b in ipairs(ns.builtinTemplates) do
		b.name, b.desc = L[b.nameKey], L[b.descKey]
		for _, m in pairs(b.meta or {}) do
			if m.labelKey then m.label, m.hint = L[m.labelKey], L[m.hintKey] end
			if m.defaultKey then m.default = L[m.defaultKey] end
			if m.labelKeys then
				m.labels = {}
				for i, k in ipairs(m.labelKeys) do m.labels[i] = L[k] end
			end
		end
	end
end

local FRAMESORT_ENEMY = { "EnemyHealer", "EnemyTank", "EnemyDPS", "EnemyFrame1", "EnemyFrame2", "EnemyFrame3" }
-- raid target markers 1-8 (star ... skull): value, icon, name in the addon's language
local MARK_OPTIONS, MARK_ICONS, MARK_LABELS, MARK_LABEL_KEYS = {}, {}, {}, {}
for i = 1, 8 do
	MARK_OPTIONS[i]    = tostring(i)
	MARK_ICONS[i]      = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i
	MARK_LABEL_KEYS[i] = "MARK_" .. i
	MARK_LABELS[i]     = L[MARK_LABEL_KEYS[i]]
end

local FRAMESORT_FRIENDLY = { "Healer", "OtherDps", "Tank", "DPS", "Frame1", "Frame2", "Frame3", "Frame4", "Frame5" }

ns.builtinTemplates = {
	-- {CANCEL} (optional, dropped with its line when empty) lets the press go
	-- through an immunity or a channel: Deep Breath, Ice Block, Turtle...
	B("focus_interrupt", "T_FOCUS_INTERRUPT", "T_FOCUS_INTERRUPT_D",
		"#showtooltip {INTERRUPT}\n/stopcasting\n/cancelaura {CANCEL}\n/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}",
		{
			INTERRUPT = P("P_INTERRUPT", "P_INTERRUPT_H"),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true }),
		}),

	B("arena_cc", "T_ARENA_CC", "T_ARENA_CC_D",
		"#showtooltip {CC}\n/cancelaura {CANCEL}\n/cast [@{ARENA}] {CC}",
		{
			CC        = P("P_CC", "P_CC_H"),
			ARENA     = P("P_ARENA", "P_ARENA_H", { "arena1", "arena2", "arena3" }, true, { "1", "2", "3" }),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true }),
		}),

	B("cursor", "T_CURSOR", "T_CURSOR_D",
		"#showtooltip {GROUND}\n/cancelaura {CANCEL}\n/cast [@cursor] {GROUND}",
		{
			GROUND    = P("P_GROUND", "P_GROUND_H"),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true }),
		}),

	B("mouseover_help", "T_MOUSEOVER_HELP", "T_MOUSEOVER_HELP_D",
		"#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {HEAL}",
		{ HEAL = P("P_HEAL", "P_HEAL_H") }),

	B("mouseover_harm", "T_MOUSEOVER_HARM", "T_MOUSEOVER_HARM_D",
		"#showtooltip\n/cast [@mouseover,harm,nodead][] {HARM}",
		{ HARM = P("P_HARM", "P_HARM_H") }),

	B("mouseover_dispel", "T_MOUSEOVER_DISPEL", "T_MOUSEOVER_DISPEL_D",
		"#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {DISPEL}",
		{ DISPEL = P("P_DISPEL", "P_DISPEL_H") }),

	B("mouseover_purge", "T_MOUSEOVER_PURGE", "T_MOUSEOVER_PURGE_D",
		"#showtooltip\n/cast [@mouseover,harm,nodead][] {PURGE}",
		{ PURGE = P("P_PURGE", "P_PURGE_H") }),

	B("mouseover_external", "T_MOUSEOVER_EXTERNAL", "T_MOUSEOVER_EXTERNAL_D",
		"#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {EXTERNAL}",
		{ EXTERNAL = P("P_EXTERNAL", "P_EXTERNAL_H") }),

	B("stopcast", "T_STOPCAST", "T_STOPCAST_D",
		"#showtooltip {SPELL}\n/stopcasting\n/cancelaura {CANCEL}\n/cast {SPELL}",
		{
			SPELL     = P("P_SPELL", "P_SPELL_H"),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true }),
		}),

	B("trinket_spell", "T_TRINKET_SPELL", "T_TRINKET_SPELL_D",
		"#showtooltip {CD}\n/use {TRINKET}\n/cast {CD}",
		{
			CD      = P("P_CD", "P_CD_H"),
			TRINKET = PX("P_TRINKET", "P_TRINKET_H", { options = { "13", "14" }, labelKeys = { "TRINKET_13", "TRINKET_14" }, default = "13" }),
		}),

	B("set_focus", "T_SET_FOCUS", "T_SET_FOCUS_D",
		"/focus\n/tm [@focus] ~{MARK}\n/mmfocus {MSG} {rt{MARK}}",
		{
			MARK = PX("P_MARK", "P_MARK_H", { options = MARK_OPTIONS, icons = MARK_ICONS, labels = MARK_LABELS, labelKeys = MARK_LABEL_KEYS, default = "2" }),
			MSG  = PX("P_MSG", "P_MSG_H", { text = true, optional = true, defaultKey = "MSG_FOCUS_DEFAULT" }),
		}),

	-- Requires the FrameSort addon: "#FrameSort X <selector>" rewrites the
	-- second @ (the @none) to the chosen frame; X leaves the first @ alone.
	B("framesort_kick", "T_FRAMESORT_KICK", "T_FRAMESORT_KICK_D",
		"#showtooltip {INTERRUPT}\n#FrameSort X {FSENEMY}\n/cancelaura {CANCEL}\n/cast [@focus,harm,nodead][@none,harm,nodead] {INTERRUPT}",
		{
			INTERRUPT = P("P_INTERRUPT", "P_INTERRUPT_H"),
			FSENEMY   = PX("P_FSENEMY", "P_FSENEMY_H", { options = FRAMESORT_ENEMY, default = "EnemyHealer" }),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true }),
		}),

	B("framesort_external", "T_FRAMESORT_EXTERNAL", "T_FRAMESORT_EXTERNAL_D",
		"#showtooltip {EXTERNAL}\n#FrameSort X {FS}\n/cast [@mouseover,help,nodead][@none,help,nodead] {EXTERNAL}",
		{
			EXTERNAL = P("P_EXTERNAL", "P_EXTERNAL_H"),
			FS       = PX("P_FS", "P_FS_H", { options = FRAMESORT_FRIENDLY, default = "Healer" }),
		}),

	B("framesort_dispel", "T_FRAMESORT_DISPEL", "T_FRAMESORT_DISPEL_D",
		"#showtooltip {DISPEL}\n#FrameSort X {FS}\n/cast [@mouseover,help,nodead][@none,help,nodead] {DISPEL}",
		{
			DISPEL = P("P_DISPEL", "P_DISPEL_H"),
			FS     = PX("P_FS", "P_FS_H", { options = FRAMESORT_FRIENDLY, default = "Healer" }),
		}),

	-- Every press does the next step; the sequence restarts when combat ends.
	-- Items go in by name so any rank works. An empty slot vanishes with its
	-- comma (token); SELFHEAL does not name the macro (noname).
	B("selfheal", "T_SELFHEAL", "T_SELFHEAL_D",
		"#showtooltip\n/stopcasting\n/castsequence [@player] reset=combat {SELFHEAL}, {HEALTHSTONE}, {POTION}",
		{
			SELFHEAL    = PX("P_SELFHEAL", "P_SELFHEAL_H", { optional = true, token = true, noname = true }),
			HEALTHSTONE = PX("P_HEALTHSTONE", "P_HEALTHSTONE_H", { optional = true, token = true }),
			POTION      = PX("P_POTION", "P_POTION_H", { optional = true, token = true }),
		}),

	-- Modifier clauses are tokens too: an empty {CTRL} takes its "[mod:ctrl] ...;"
	-- clause away, so the same template serves two or three spells.
	B("mod2", "T_MOD2", "T_MOD2_D",
		"#showtooltip\n/cast [mod:ctrl] {CTRL}; [mod:shift] {SHIFT}; {SPELL}",
		{
			CTRL  = PX("P_CTRL", "P_CTRL_H", { optional = true, token = true, noname = true }),
			SHIFT = PX("P_SHIFT", "P_SHIFT_H", { optional = true, token = true, noname = true }),
			SPELL = P("P_SPELL", "P_SPELL_H"),
		}),

	B("selfcast", "T_SELFCAST", "T_SELFCAST_D",
		"#showtooltip\n/cast [@player] {SPELL}",
		{ SPELL = P("P_SPELL", "P_SPELL_H") }),

	B("cancel_cast", "T_CANCEL_CAST", "T_CANCEL_CAST_D",
		"#showtooltip {SPELL}\n/cancelaura {AURA}\n/cast {SPELL}",
		{ SPELL = P("P_SPELL", "P_SPELL_H"), AURA = P("P_AURA", "P_AURA_H") }),

	B("focus_external", "T_FOCUS_EXTERNAL", "T_FOCUS_EXTERNAL_D",
		"#showtooltip\n/cast [@focus,help,nodead][@targettarget,help,nodead][] {EXTERNAL}",
		{ EXTERNAL = P("P_EXTERNAL", "P_EXTERNAL_H") }),

	B("mouseover_altfocus", "T_MOUSEOVER_ALTFOCUS", "T_MOUSEOVER_ALTFOCUS_D",
		"#showtooltip {HARM}\n/cancelaura {CANCEL}\n/cast [mod:alt,@focus,harm,nodead][@mouseover,harm,nodead][] {HARM}",
		{
			HARM      = P("P_HARM", "P_HARM_H"),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true }),
		}),

	B("combat_switch", "T_COMBAT_SWITCH", "T_COMBAT_SWITCH_D",
		"#showtooltip\n/cast [combat] {INCOMBAT}; {SPELL}",
		{ INCOMBAT = PX("P_INCOMBAT", "P_INCOMBAT_H", { noname = true }), SPELL = P("P_SPELL", "P_SPELL_H") }),

	B("targettarget", "T_TARGETTARGET", "T_TARGETTARGET_D",
		"#showtooltip\n/cast [@targettarget,harm,nodead][] {HARM}",
		{ HARM = P("P_HARM", "P_HARM_H") }),

	B("petattack", "T_PETATTACK", "T_PETATTACK_D",
		"#showtooltip {SPELL}\n/petattack\n/cast {SPELL}",
		{ SPELL = P("P_SPELL", "P_SPELL_H") }),

	B("sequence", "T_SEQUENCE", "T_SEQUENCE_D",
		"#showtooltip\n/castsequence reset={RESET} {SPELL}, {SPELL_2}, {SPELL_3}",
		{
			RESET   = PX("P_RESET", "P_RESET_H", { options = { "target/combat", "combat/10", "combat", "10" }, labelKeys = { "RESET_1", "RESET_2", "RESET_3", "RESET_4" }, default = "target/combat" }),
			SPELL   = P("P_SPELL", "P_SPELL_H"),
			SPELL_2 = P("P_SPELL2", "P_SPELL2_H"),
			SPELL_3 = PX("P_SPELL3", "P_SPELL3_H", { optional = true, token = true }),
		}),

	B("once_per_target", "T_ONCE_PER_TARGET", "T_ONCE_PER_TARGET_D",
		"#showtooltip {SPELL}\n/castsequence reset=target/combat {SPELL}, null",
		{ SPELL = P("P_SPELL", "P_SPELL_H") }),
}

-- ---------------------------------------------------------------------------
-- Catalogue metadata: a category per built-in, which classes a template is
-- for (only where the spell tables cannot tell), and the per-class
-- recommended set that seeds a fresh install.
-- ---------------------------------------------------------------------------

ns.templateCategories = { "CORE", "HEAL", "PVP", "SEQ", "PET" }

local CATEGORY = {
	focus_interrupt = "CORE", cursor = "CORE", mouseover_harm = "CORE", stopcast = "CORE", trinket_spell = "CORE",
	selfheal = "CORE", mod2 = "CORE", selfcast = "CORE", focus_external = "CORE", combat_switch = "CORE", cancel_cast = "CORE",
	mouseover_help = "HEAL", mouseover_dispel = "HEAL", mouseover_external = "HEAL", targettarget = "HEAL",
	arena_cc = "PVP", mouseover_purge = "PVP", set_focus = "PVP", framesort_kick = "PVP", framesort_external = "PVP",
	framesort_dispel = "PVP", mouseover_altfocus = "PVP",
	sequence = "SEQ", once_per_target = "SEQ",
	petattack = "PET",
}
for _, b in ipairs(ns.builtinTemplates) do b.cat = CATEGORY[b.id] or "CORE" end

ns.builtinClasses = {
	petattack = { HUNTER = true, WARLOCK = true, DEATHKNIGHT = true, MAGE = true },
}

ns.classRecommended = {
	DEATHKNIGHT = { "focus_interrupt", "mouseover_harm", "cursor", "petattack", "mod2", "selfheal", "set_focus" },
	DEMONHUNTER = { "focus_interrupt", "mouseover_harm", "cursor", "mod2", "cancel_cast", "selfheal", "set_focus" },
	DRUID       = { "focus_interrupt", "mouseover_help", "mouseover_dispel", "mouseover_external", "combat_switch", "cursor", "mod2", "selfheal" },
	EVOKER      = { "focus_interrupt", "mouseover_help", "mouseover_dispel", "mouseover_external", "cursor", "cancel_cast", "selfheal", "set_focus" },
	HUNTER      = { "focus_interrupt", "petattack", "focus_external", "mouseover_harm", "cursor", "cancel_cast", "selfheal", "set_focus" },
	MAGE        = { "focus_interrupt", "mouseover_harm", "cursor", "mouseover_purge", "cancel_cast", "mod2", "selfheal", "set_focus" },
	MONK        = { "focus_interrupt", "mouseover_help", "mouseover_dispel", "mouseover_external", "cursor", "mod2", "selfheal", "set_focus" },
	PALADIN     = { "focus_interrupt", "mouseover_help", "mouseover_dispel", "mouseover_external", "cancel_cast", "mod2", "selfheal", "set_focus" },
	PRIEST      = { "focus_interrupt", "mouseover_help", "mouseover_dispel", "mouseover_external", "mouseover_purge", "selfcast", "selfheal", "set_focus" },
	ROGUE       = { "focus_interrupt", "focus_external", "mouseover_harm", "cancel_cast", "mod2", "selfheal", "set_focus" },
	SHAMAN      = { "focus_interrupt", "mouseover_help", "mouseover_dispel", "mouseover_purge", "cursor", "mod2", "selfheal", "set_focus" },
	WARLOCK     = { "focus_interrupt", "petattack", "mouseover_harm", "cursor", "mouseover_purge", "sequence", "selfheal", "set_focus" },
	WARRIOR     = { "focus_interrupt", "mouseover_harm", "cursor", "mouseover_external", "mod2", "selfheal", "set_focus" },
}

-- Ids recommended for the current class (CORE templates when the class is
-- unknown), only those that still ship.
function ns.RecommendedTemplates()
	local _, class = UnitClass("player")
	local ids = ns.classRecommended[class]
	local out = {}
	if ids then
		for _, id in ipairs(ids) do
			for _, b in ipairs(ns.builtinTemplates) do
				if b.id == id then out[#out + 1] = id end
			end
		end
	else
		for _, b in ipairs(ns.builtinTemplates) do
			if b.cat == "CORE" then out[#out + 1] = b.id end
		end
	end
	return out
end

-- True when the current class has something to put into every categorised
-- placeholder of shipped template `b` (and the template is not for other
-- classes only). Derived from the spell tables, no extra bookkeeping.
function ns.TemplateFitsClass(b)
	local _, class = UnitClass("player")
	local only = ns.builtinClasses[b.id]
	if only and not only[class] then return false end
	for _, key in ipairs(ns.GetPlaceholders(b.body)) do
		local m = b.meta and b.meta[key]
		if not (m and (m.options or m.text or m.optional)) and not ns.ItemCategoryForKey(key, m) then
			local cat = ns.CategoryForKey(key, m)
			if cat and #ns.GetSuggestionIDs(cat) == 0 then return false end
		end
	end
	return true
end

-- Built-ins this DB has never seen (shown as new in the catalogue).
function ns.NewBuiltinCount()
	local n = 0
	for _, b in ipairs(ns.builtinTemplates) do
		if not (ns.db and ns.db.knownBuiltins and ns.db.knownBuiltins[b.id]) then n = n + 1 end
	end
	return n
end

function ns.MarkBuiltinsKnown()
	if not ns.db then return end
	ns.db.knownBuiltins = ns.db.knownBuiltins or {}
	for _, b in ipairs(ns.builtinTemplates) do ns.db.knownBuiltins[b.id] = true end
end

-- ---------------------------------------------------------------------------
-- DB
-- ---------------------------------------------------------------------------

local function CopyMeta(meta)
	if not meta then return nil end
	local out = {}
	for k, m in pairs(meta) do
		out[k] = {}
		for field, v in pairs(m) do
			if type(v) ~= "table" then out[k][field] = v end
		end
		for _, listKey in ipairs({ "options", "suffixes", "labels", "icons" }) do
			if m[listKey] then
				out[k][listKey] = {}
				for i, o in ipairs(m[listKey]) do out[k][listKey][i] = o end
			end
		end
	end
	return out
end
ns.CopyMeta = CopyMeta

local function CopyTemplate(t)
	-- seedBody remembers what we shipped, so later releases can refresh a
	-- built-in the user never edited without touching one they did
	local c = { id = t.id, name = t.name, desc = t.desc, body = t.body, builtin = t.builtin, seedBody = t.body }
	c.meta = CopyMeta(t.meta)
	return c
end

-- True when `value` is what key `key` reads in any shipped language, i.e.
-- text the user never changed.
local function IsShippedText(key, value)
	if value == key then return true end
	for _, tbl in pairs(ns.locales or {}) do
		if tbl[key] == value then return true end
	end
	for _, old in ipairs(ns.legacyText and ns.legacyText[key] or {}) do
		if old == value then return true end
	end
	return false
end

-- Copies the class's recommended templates into db.templates (which is
-- expected to be empty) and marks them known.
local function SeedTemplates(db)
	db.knownBuiltins = db.knownBuiltins or {}
	local want = {}
	for i, id in ipairs(ns.RecommendedTemplates()) do want[id] = i end
	local picked = {}
	for _, t in ipairs(ns.builtinTemplates) do
		if want[t.id] then picked[#picked + 1] = t end
	end
	table.sort(picked, function(a, b) return want[a.id] < want[b.id] end)
	for _, t in ipairs(picked) do
		db.templates[#db.templates + 1] = CopyTemplate(t)
		db.knownBuiltins[t.id] = true
	end
end

function ns.InitDB()
	if type(MacroMasterDB) ~= "table" then MacroMasterDB = {} end
	local db = MacroMasterDB
	db.version   = db.version or DB_VERSION
	db.templates = db.templates or {}
	db.settings  = db.settings or { pickup = true, scope = "account" }
	db.settings.sort = db.settings.sort or "created"
	-- importMode: what an import does with a template whose id is already in
	-- the list: "replace" it (restoring a backup) or "add" a copy (a share)
	db.settings.importMode = db.settings.importMode or "replace"
	-- closeAfterCopy: the share window closes itself after Ctrl+C
	if db.settings.closeAfterCopy == nil then db.settings.closeAfterCopy = true end
	db.icons = db.icons or {}          -- template id -> macro icon fileID chosen by the user
	-- language: settings.locale ("enUS" / "zhTW") overrides the client's; nil = follow the client
	if db.settings.locale then ns.ApplyLocale(db.settings.locale) end
	ns.RelocalizeBuiltins()
	for _, fn in ipairs(ns.onLocale or {}) do fn() end
	-- a remembered value that is still a shipped default (in any language)
	-- gives way to the current language's default
	for _, b in ipairs(ns.builtinTemplates) do
		for key, m in pairs(b.meta or {}) do
			if m.defaultKey then
				for _, values in pairs(db.charValues or {}) do
					local v = values[key]
					if v and v ~= m.default and IsShippedText(m.defaultKey, v) then values[key] = nil end
				end
			end
		end
	end
	-- a fresh install starts with the set recommended for this class; the
	-- rest waits in the catalogue (Settings -> Add more built-ins)
	if not db.seeded then
		SeedTemplates(db)
		db.seeded = true
	end
	-- knownBuiltins: every built-in this DB has seen; the others show as new
	-- in the catalogue. Nothing is added to the list behind the user's back.
	if not db.knownBuiltins then
		-- a DB from before this bookkeeping existed: it has seen exactly the
		-- built-ins that shipped up to 1.1.1, whether or not they still exist
		db.knownBuiltins = {}
		for _, id in ipairs({ "focus_interrupt", "arena_cc", "cursor", "mouseover_help", "mouseover_harm",
			"stopcast", "trinket_spell", "set_focus" }) do
			db.knownBuiltins[id] = true
		end
	end
	ns.db = db
	ns.RefreshUneditedBuiltins()
	-- 1.2.5: FrameSort placeholders renamed (FS enemy -> FSENEMY, FST ally -> FS)
	if (db.version or 1) < 2 then
		for _, values in pairs(db.charValues or {}) do
			local enemy, ally = values.FS, values.FST
			values.FSENEMY = values.FSENEMY or enemy
			values.FS = ally
			values.FST = nil
			if values.FS and values.FS:find("^Enemy") then values.FS = nil end
		end
		for _, values in pairs(db.charValues or {}) do
			if values.FS == "OtherDPS" then values.FS = "OtherDps" end
		end
		db.version = 2
	end
	-- 1.3.0: the set-focus announcement no longer names the enemy; a stored
	-- old default gives way to the new one (an edited message is kept)
	if db.version < 3 then
		for _, values in pairs(db.charValues or {}) do
			if values.MSG == "Focus: %f" then values.MSG = nil end
		end
		db.version = 3
	end
end

function ns.GetTemplates() return ns.db.templates end

function ns.FindTemplate(id)
	for i, t in ipairs(ns.db.templates) do
		if t.id == id then return t, i end
	end
end

local function NewID()
	local id
	repeat
		id = "user_" .. tostring(time()) .. "_" .. tostring(math.random(1000, 9999))
	until not ns.FindTemplate(id)   -- a batch import can ask several times a second
	return id
end

function ns.AddTemplate(name, desc, body, meta)
	local t = {
		id   = NewID(),
		name = name or L["Untitled"],
		desc = desc or "",
		body = body or "",
		meta = meta,
	}
	ns.db.templates[#ns.db.templates + 1] = t
	return t
end

function ns.DeleteTemplate(id)
	local _, i = ns.FindTemplate(id)
	if i then table.remove(ns.db.templates, i) end
end

-- Bodies shipped by earlier releases, so a 1.0.0 DB (no seedBody yet) can
-- still be recognised as unedited.
local LEGACY_BODIES = {
	set_focus = {
		"/focus [@mouseover,exists][]",                                        -- up to 1.2.3
		"/focus [@mouseover,exists][]\n/tm [@focus] {MARK}\n/p {MSG}",        -- 1.2.4 – 1.2.6
		"/focus [@mouseover,exists][]\n/tm [@focus] {MARK}\n/mmfocus {rt{MARK}} {MSG}",  -- 1.2.7 – 1.2.8
		"/focus [@mouseover,exists][]\n/tm [@focus] {MARK}\n/mmfocus {MSG} {rt{MARK}}",  -- 1.3.0 dev
	},
	trinket_spell = { "#showtooltip {CD}\n/use 13\n/cast {CD}" },                                                  -- up to 1.3.0
	framesort_kick = { "#showtooltip {INTERRUPT}\n#FrameSort X {FS}\n/cancelaura {CANCEL}\n/cast [@focus,harm,nodead][@none,harm,nodead] {INTERRUPT}" },  -- 1.2.0 – 1.2.4
	framesort_external = { "#showtooltip {EXTERNAL}\n#FrameSort X {FST}\n/cast [@mouseover,help,nodead][@none,help,nodead] {EXTERNAL}" },      -- 1.2.3 – 1.2.4
	framesort_dispel = { "#showtooltip {DISPEL}\n#FrameSort X {FST}\n/cast [@mouseover,help,nodead][@none,help,nodead] {DISPEL}" },            -- 1.2.3 – 1.2.4
	focus_interrupt = {
		"#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead][] {INTERRUPT}",   -- 1.0.0
		"#showtooltip\n/cast [@focus,harm,nodead][] {INTERRUPT}",                  -- 1.0.1 – 1.2.1
		"#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}",  -- 1.2.2 – 1.3.0
	},
	arena_cc = { "#showtooltip {CC}\n/cast [@{ARENA}] {CC}" },                                                      -- up to 1.3.0
	cursor   = { "#showtooltip\n/cast [@cursor] {GROUND}" },                                                        -- up to 1.3.0
	stopcast = { "#showtooltip\n/stopcasting\n/cast {SPELL}" },                                                     -- up to 1.3.0
	mouseover_altfocus = { "#showtooltip\n/cast [mod:alt,@focus,harm,nodead][@mouseover,harm,nodead][] {HARM}" },   -- 1.3.0 dev
}

-- Names shipped by earlier releases (any locale); a template still carrying
-- one of these gets the current name.
local LEGACY_NAMES = {
	focus_interrupt = { "Interrupt: focus, else target", "斷法：有焦點斷焦點，否則斷目標" },
	arena_cc        = { "Arena: cast on arena1/2/3", "競技場：對 arena1/2/3 施放" },
	cursor          = { "Ground spell @cursor", "地板技能 @cursor" },
	mouseover_help  = { "Heal: mouseover > target > self", "治療：滑鼠指向 > 目標 > 自己" },
	mouseover_harm  = { "Damage: mouseover > target", "傷害：滑鼠指向 > 目標" },
	stopcast        = { "Stopcasting + cast", "停止施法 + 施放" },
	trinket_spell   = { "飾品 + 技能" },
	set_focus       = { "Set focus: mouseover > target", "設定焦點：滑鼠指向 > 目標" },
}

function ns.RefreshUneditedBuiltins()
	for _, b in ipairs(ns.builtinTemplates) do
		local t = ns.FindTemplate(b.id)
		if t then
			for _, old in ipairs(LEGACY_NAMES[b.id] or {}) do
				if t.name == old then t.name = b.name end
			end
			-- a name / description the user left as shipped follows the language
			if t.name ~= b.name and IsShippedText(b.nameKey, t.name) then t.name = b.name end
			if t.desc ~= b.desc and IsShippedText(b.descKey, t.desc) then t.desc = b.desc end
			-- meta (labels, dropdown options, batch flags) is not user-editable,
			-- so always take the shipped version
			if b.meta then t.meta = CopyMeta(b.meta) end
		end
		if t and t.body ~= b.body then
			local unedited = (t.seedBody and t.body == t.seedBody)
			for _, old in ipairs(LEGACY_BODIES[b.id] or {}) do
				if t.body == old then unedited = true end
			end
			if unedited then
				t.body, t.seedBody = b.body, b.body
				t.desc = b.desc
				if t.name == "" then t.name = b.name end
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Defaults catalogue: the shipped templates are a read-only source the user
-- copies from; the list in the DB is entirely theirs.
-- ---------------------------------------------------------------------------

local function ShippedTemplate(id)
	for _, b in ipairs(ns.builtinTemplates) do
		if b.id == id then return b end
	end
end
ns.ShippedTemplate = ShippedTemplate

-- Copies shipped template `id` into the list. An existing copy is only
-- overwritten when `overwrite` is set. Returns "added" | "replaced" | "exists".
function ns.ImportBuiltin(id, overwrite)
	local b = ShippedTemplate(id)
	if not b then return nil end
	local c = CopyTemplate(b)
	local t = ns.FindTemplate(id)
	if t then
		if not overwrite then return "exists" end
		for k in pairs(t) do t[k] = nil end
		for k, v in pairs(c) do t[k] = v end
		return "replaced"
	end
	ns.db.templates[#ns.db.templates + 1] = c
	ns.db.knownBuiltins[id] = true
	return "added"
end

-- Throws the whole list away (user templates included) and re-seeds it
-- with the class's recommended set.
function ns.ResetAllTemplates()
	ns.db.templates = {}
	SeedTemplates(ns.db)
end

-- ---------------------------------------------------------------------------
-- Export / import: a plain-text block the user can copy out of and paste
-- into an edit box. One [template] record per template, one key=value per
-- line; backslash and newline are escaped so a body stays on one line.
-- ---------------------------------------------------------------------------

local EXPORT_HEADER = "MacroMaster templates 1"

local function Esc(s)
	return (tostring(s or ""):gsub("\\", "\\\\"):gsub("\r", ""):gsub("\n", "\\n"))
end

local function Unesc(s)
	return (s:gsub("\\(.)", function(c)
		if c == "n" then return "\n" end
		return c
	end))
end

-- `list` defaults to every template.
function ns.ExportTemplates(list)
	local out = { EXPORT_HEADER }
	for _, t in ipairs(list or ns.db.templates) do
		out[#out + 1] = ""
		out[#out + 1] = "[template]"
		out[#out + 1] = "id=" .. Esc(t.id)
		out[#out + 1] = "name=" .. Esc(t.name)
		out[#out + 1] = "desc=" .. Esc(t.desc)
		out[#out + 1] = "body=" .. Esc(t.body)
	end
	return table.concat(out, "\n")
end

-- ---------------------------------------------------------------------------
-- Share string: the plain text above, deflated and written in LibDeflate's
-- print alphabet (letters, digits, parentheses) behind a "!MM1!" prefix.
-- One line without whitespace, so it survives Discord, forums and chat.
-- Import takes either form. The encoding is for transport, not safety:
-- what protects the user is the parsing below and the code warnings.
-- ---------------------------------------------------------------------------

local STRING_VERSION = 1
-- refused before decoding can eat memory: a whole library is a few KB
local MAX_ENCODED = 200000
local MAX_DECODED = 1000000
-- longer than the editor allows; anything above is not a macro template
local MAX_BODY = 2000

function ns.EncodeTemplates(list)
	local LD = LibStub("LibDeflate")
	local packed = LD:CompressDeflate(ns.ExportTemplates(list), { level = 9 })
	return "!MM" .. STRING_VERSION .. "!" .. LD:EncodeForPrint(packed)
end

-- "!MM1!..." -> the plain text, or nil, error message. Anything that does
-- not carry the prefix is handed back unchanged (a plain-text export).
local function DecodeString(text)
	local version, payload = text:match("^%s*!MM(%d+)!(.*)$")
	if not version then
		if text:match("^%s*!MM") then return nil, L["MSG_IMPORT_CORRUPT"] end
		return text
	end
	if tonumber(version) > STRING_VERSION then return nil, L["MSG_IMPORT_NEWER"] end
	payload = payload:gsub("%s", "")   -- a forum may have wrapped the line
	if #payload > MAX_ENCODED then return nil, L["MSG_IMPORT_CORRUPT"] end
	local LD = LibStub("LibDeflate")
	local packed = LD:DecodeForPrint(payload)
	local plain = packed and LD:DecompressDeflate(packed)
	if not plain or #plain > MAX_DECODED then return nil, L["MSG_IMPORT_CORRUPT"] end
	return plain
end

-- Name and description are shown as-is in the list, tooltips and the
-- catalogue: a "|" from someone else is escaped so it cannot smuggle in a
-- colour code, a texture or a hyperlink.
local function CleanText(s)
	return (tostring(s or ""):gsub("|", "||"))
end

-- Returns list, nil (entries { id, name, desc, body, code }, id may be nil;
-- code = true when the body runs Lua) or nil, error message.
function ns.ParseTemplates(text)
	local err
	text, err = DecodeString(text or "")
	if not text then return nil, err end
	text = text:gsub("\r", "")
	if not text:match("^%s*MacroMaster templates %d+") then return nil, L["MSG_IMPORT_FORMAT"] end
	local list, cur = {}, nil
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		if line == "[template]" then
			cur = {}
			list[#list + 1] = cur
		elseif cur then
			local k, v = line:match("^(%w+)=(.*)$")
			if k then cur[k] = Unesc(v) end
		end
	end
	local valid = {}
	for _, e in ipairs(list) do
		if e.body and e.body ~= "" and #e.body <= MAX_BODY then
			if e.id == "" or (e.id and #e.id > 100) then e.id = nil end
			e.name = CleanText(e.name)
			if e.name == "" then e.name = L["Untitled"] end
			e.desc = CleanText(e.desc)
			e.code = #ns.CodeLines(e.body) > 0
			valid[#valid + 1] = e
		end
	end
	return valid, nil
end

-- How ns.ImportTemplates would treat `list`: number added, number replaced.
-- mode: "replace" (default) or "add", see db.settings.importMode.
function ns.CountImport(list, mode)
	local added, replaced = 0, 0
	for _, e in ipairs(list) do
		if mode ~= "add" and e.id and ns.FindTemplate(e.id) then replaced = replaced + 1 else added = added + 1 end
	end
	return added, replaced
end

-- Same id -> that template's text is replaced ("replace" mode) or a copy
-- with a fresh id is added ("add" mode); an unknown id is always added. An
-- id that belongs to a shipped template keeps its placeholder metadata
-- (labels, dropdowns) either way.
function ns.ImportTemplates(list, mode)
	local added, replaced = 0, 0
	for _, e in ipairs(list) do
		local existing = mode ~= "add" and e.id and ns.FindTemplate(e.id)
		if existing then
			existing.name, existing.desc, existing.body = e.name, e.desc, e.body
			replaced = replaced + 1
		else
			local shipped = e.id and ShippedTemplate(e.id)
			local t
			if shipped then
				t = CopyTemplate(shipped)
				t.name, t.desc, t.body = e.name, e.desc, e.body
				ns.db.knownBuiltins[t.id] = true
			else
				t = { id = e.id or NewID(), name = e.name, desc = e.desc, body = e.body }
			end
			if ns.FindTemplate(t.id) then
				-- "add" next to the one already there: a plain user template
				-- from here on, not the built-in's slot
				t.id, t.builtin, t.seedBody = NewID(), nil, nil
			end
			ns.db.templates[#ns.db.templates + 1] = t
			added = added + 1
		end
	end
	return added, replaced
end

-- ---------------------------------------------------------------------------
-- Code detection. A macro line that runs Lua when pressed can do whatever
-- an addon can: delete your macros, wipe settings, talk in chat as you.
-- Harmless in a template you wrote; a real risk in one somebody sent you.
-- Every place that shows, imports or creates such a template says so in red.
-- ---------------------------------------------------------------------------

local CODE_CMDS = { run = true, script = true, dump = true, console = true }

function ns.IsCodeLine(line)
	local cmd = line:match("^%s*/(%a+)")
	return cmd and CODE_CMDS[cmd:lower()] or false
end

-- The lines of `body` that run code, trimmed; empty when there are none.
function ns.CodeLines(body)
	local out = {}
	for line in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
		if ns.IsCodeLine(line) then out[#out + 1] = strtrim(line) end
	end
	return out
end

-- ---------------------------------------------------------------------------
-- Placeholder handling
-- ---------------------------------------------------------------------------

-- Ordered, de-duplicated list of placeholder keys in `body`.
function ns.GetPlaceholders(body)
	local list, seen = {}, {}
	for key in (body or ""):gmatch(PH_PATTERN) do
		if not seen[key] then
			seen[key] = true
			list[#list + 1] = key
		end
	end
	return list
end

-- Replace every {KEY} with values[KEY]; unfilled keys are left as-is,
-- except optional ones (meta[key].optional), whose whole line is dropped.
-- An unfilled list token (meta[key].token) leaves together with its comma
-- or its ";" clause instead: "{A}, {B}, {C}" with B empty becomes "{A}, {C}",
-- "[mod:ctrl] {C}; {S}" with C empty becomes "{S}".
-- Returns body, list of unfilled (non-optional) keys.
function ns.Substitute(body, values, meta)
	meta = meta or {}
	local missing, seen = {}, {}
	local lines = {}
	for line in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
		local drop = false
		for key, m in pairs(meta) do
			if m.token and not (values[key] and values[key] ~= "") then
				local esc = ("{" .. key .. "}"):gsub("%W", "%%%0")
				-- ";"-separated clause, with or without its [conditions]
				line = line:gsub("%[[^%]]*%]%s*" .. esc .. "%s*;%s*", "")
				line = line:gsub(";%s*%[[^%]]*%]%s*" .. esc, "")
				line = line:gsub(esc .. "%s*;%s*", "")
				line = line:gsub(";%s*" .. esc, "")
				-- ","-separated list item
				line = line:gsub(",%s*" .. esc, "")
				line = line:gsub(esc .. "%s*,%s*", "")
			end
		end
		local function resolve(key)
			local v = values[key]
			if v and v ~= "" then return v end
			if meta[key] and meta[key].optional then
				drop = true
				return ""
			end
			if not seen[key] then seen[key] = true; missing[#missing + 1] = key end
			return "{" .. key .. "}"
		end
		-- second pass resolves placeholders nested inside another one, e.g. {rt{MARK}}
		local out = line:gsub(PH_PATTERN, resolve)
		out = out:gsub(PH_PATTERN, function(key)
			local v = values[key]
			if v and v ~= "" then return v end
			return "{" .. key .. "}"
		end)
		if not drop then lines[#lines + 1] = out end
	end
	return table.concat(lines, "\n"), missing
end

-- ---------------------------------------------------------------------------
-- Macro -> template: find spell/item names in cast-like lines and replace
-- them with {PLACEHOLDER}. A name the suggestion tables know becomes the
-- matching variable ({INTERRUPT}, {HEAL}, {POTION}...), anything else
-- {SPELL} / {ITEM}; a second of the same kind gets _2, _3... "spell:1234"
-- and "item:1234" are resolved to names first.
-- Returns new body, ordered list of { key, name (value), token (as written) }.
-- ---------------------------------------------------------------------------

local CAST_CMDS = { cast = true, use = true, castsequence = true, castrandom = true, showtooltip = true }
-- commands whose argument plays a fixed role: the key is that role, not the
-- spell's category ("/cancelaura Ice Block" -> {AURA}, not {DEFENSIVE})
local ROLE_CMDS = { cancelaura = "AURA" }

local function UniqueKey(base, used)
	local key, n = base, 2
	while used[key] do
		key = base .. "_" .. n
		n = n + 1
	end
	used[key] = true
	return key
end

-- "spell:1234" / "item:1234" -> name and kind; a bare name stays as-is.
local function ResolveToken(tok)
	local sid = tok:match("^spell:(%d+)$")
	if sid then return C_Spell.GetSpellName(tonumber(sid)) or tok, "spell" end
	local iid = tok:match("^item:(%d+)$")
	if iid then return C_Item.GetItemNameByID(tonumber(iid)) or tok, "item" end
	return tok, nil
end

local function KeyBaseFor(name, kind)
	if kind ~= "item" and ns.CategoryForSpellName then
		local cat = ns.CategoryForSpellName(name)
		if cat then return cat end
	end
	if kind ~= "spell" and ns.ItemKeyForName then
		local key = ns.ItemKeyForName(name)
		if key then return key end
	end
	return kind == "item" and "ITEM" or "SPELL"
end

local function IsSkippableToken(tok)
	if tok == "" then return true end
	if tok:match("^%d+$") then return true end            -- inventory slot (/use 13)
	if tok:match("^reset=") then return true end          -- castsequence reset clause
	if tok:match("^%d+%s+%d+$") then return true end      -- bag slot (/use 0 1)
	return false
end

function ns.MakeTemplateFromMacro(body)
	local names, order, used = {}, {}, {}

	for line in (body .. "\n"):gmatch("([^\n]*)\n") do
		local cmd, rest = line:match("^%s*[/#](%a+)%s*(.*)$")
		local role = cmd and ROLE_CMDS[cmd:lower()]
		if cmd and (CAST_CMDS[cmd:lower()] or role) then
			-- drop [conditionals] and a leading "!" toggle marker per token
			rest = rest:gsub("%[[^%]]*%]", "")
			rest = rest:gsub("^%s*reset=%S+%s*", "")   -- castsequence reset clause
			for tok in rest:gmatch("[^;,]+") do
				tok = strtrim(tok):gsub("^!", "")
				if not IsSkippableToken(tok) and not names[tok] then
					local name, kind = ResolveToken(tok)
					names[tok] = UniqueKey(role or KeyBaseFor(name, kind), used)
					order[#order + 1] = { key = names[tok], name = name, token = tok }
				end
			end
		end
	end

	-- longest tokens first so "Fire Blast" is replaced before "Fire"
	table.sort(order, function(a, b) return #a.token > #b.token end)

	local out = body
	for _, e in ipairs(order) do
		local escaped = e.token:gsub("(%W)", "%%%1")
		out = out:gsub(escaped, "{" .. e.key .. "}")
	end

	-- restore original discovery order for display
	table.sort(order, function(a, b) return body:find(a.token, 1, true) < body:find(b.token, 1, true) end)
	return out, order
end
