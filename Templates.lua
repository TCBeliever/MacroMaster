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

local function B(id, name, desc, body, meta)
	return { id = id, name = L[name], desc = L[desc], body = body, meta = meta, builtin = true }
end

local function P(label, hint, options, multi, suffixes)
	-- options : fixed choices shown in a dropdown instead of the spell picker
	-- multi   : the dropdown also offers "All" -> one macro per option
	-- suffixes: appended to the macro name per option (defaults to the option)
	return { label = L[label], hint = L[hint], options = options, multi = multi, suffixes = suffixes }
end

-- Same, with extra fields: optional (unfilled -> its line is dropped),
-- default (pre-filled value), category (suggestion list to show).
local function PX(label, hint, extra)
	local m = P(label, hint, extra.options)
	for k, v in pairs(extra) do m[k] = v end
	return m
end

local FRAMESORT_ENEMY = { "EnemyHealer", "EnemyTank", "EnemyDPS", "EnemyFrame1", "EnemyFrame2", "EnemyFrame3" }
-- raid target markers 1-8 (star ... skull): value, icon, Blizzard's localized name
local MARK_OPTIONS, MARK_ICONS, MARK_LABELS = {}, {}, {}
for i = 1, 8 do
	MARK_OPTIONS[i] = tostring(i)
	MARK_ICONS[i]   = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i
	MARK_LABELS[i]  = _G["RAID_TARGET_" .. i] or tostring(i)
end

local FRAMESORT_FRIENDLY = { "Healer", "OtherDps", "Tank", "DPS", "Frame1", "Frame2", "Frame3", "Frame4", "Frame5" }

ns.builtinTemplates = {
	B("focus_interrupt", "T_FOCUS_INTERRUPT", "T_FOCUS_INTERRUPT_D",
		"#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead,mod:shift][] {INTERRUPT}",
		{ INTERRUPT = P("P_INTERRUPT", "P_INTERRUPT_H") }),

	B("arena_cc", "T_ARENA_CC", "T_ARENA_CC_D",
		"#showtooltip {CC}\n/cast [@{ARENA}] {CC}",
		{ CC = P("P_CC", "P_CC_H"), ARENA = P("P_ARENA", "P_ARENA_H", { "arena1", "arena2", "arena3" }, true, { "1", "2", "3" }) }),

	B("cursor", "T_CURSOR", "T_CURSOR_D",
		"#showtooltip\n/cast [@cursor] {GROUND}",
		{ GROUND = P("P_GROUND", "P_GROUND_H") }),

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
		"#showtooltip\n/stopcasting\n/cast {SPELL}",
		{ SPELL = P("P_SPELL", "P_SPELL_H") }),

	B("trinket_spell", "T_TRINKET_SPELL", "T_TRINKET_SPELL_D",
		"#showtooltip {CD}\n/use 13\n/cast {CD}",
		{ CD = P("P_CD", "P_CD_H") }),

	B("set_focus", "T_SET_FOCUS", "T_SET_FOCUS_D",
		"/focus [@mouseover,exists][]\n/tm [@focus] {MARK}\n/mmfocus {MSG} {rt{MARK}}",
		{
			MARK = PX("P_MARK", "P_MARK_H", { options = MARK_OPTIONS, icons = MARK_ICONS, labels = MARK_LABELS, default = "2" }),
			MSG  = PX("P_MSG", "P_MSG_H", { text = true, optional = true, default = L["MSG_FOCUS_DEFAULT"] }),
		}),

	-- Requires the FrameSort addon: "#FrameSort X <selector>" rewrites the
	-- second @ (the @none) to the chosen frame; X leaves the first @ alone.
	B("framesort_kick", "T_FRAMESORT_KICK", "T_FRAMESORT_KICK_D",
		"#showtooltip {INTERRUPT}\n#FrameSort X {FSENEMY}\n/cancelaura {CANCEL}\n/cast [@focus,harm,nodead][@none,harm,nodead] {INTERRUPT}",
		{
			INTERRUPT = P("P_INTERRUPT", "P_INTERRUPT_H"),
			FSENEMY   = PX("P_FSENEMY", "P_FSENEMY_H", { options = FRAMESORT_ENEMY, default = "EnemyHealer" }),
			CANCEL    = PX("P_CANCEL", "P_CANCEL_H", { optional = true, category = "DEFENSIVE" }),
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
}

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

function ns.InitDB()
	if type(MacroMasterDB) ~= "table" then MacroMasterDB = {} end
	local db = MacroMasterDB
	db.version   = db.version or DB_VERSION
	db.templates = db.templates or {}
	db.settings  = db.settings or { pickup = true, scope = "account" }
	db.settings.sort = db.settings.sort or "created"
	if not db.seeded then
		for _, t in ipairs(ns.builtinTemplates) do
			db.templates[#db.templates + 1] = CopyTemplate(t)
		end
		db.seeded = true
	end
	-- Built-ins added by later releases: add once, but never re-add one the
	-- user deleted. knownBuiltins records every built-in this DB has seen.
	if not db.knownBuiltins then
		-- a DB from before this bookkeeping existed: it has seen exactly the
		-- built-ins that shipped up to 1.1.1, whether or not they still exist
		db.knownBuiltins = {}
		for _, id in ipairs({ "focus_interrupt", "arena_cc", "cursor", "mouseover_help", "mouseover_harm",
			"stopcast", "trinket_spell", "set_focus" }) do
			db.knownBuiltins[id] = true
		end
	end
	for _, t in ipairs(ns.builtinTemplates) do
		if not db.knownBuiltins[t.id] then
			db.knownBuiltins[t.id] = true
			local exists = false
			for _, e in ipairs(db.templates) do if e.id == t.id then exists = true end end
			if not exists then db.templates[#db.templates + 1] = CopyTemplate(t) end
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
	return "user_" .. tostring(time()) .. "_" .. tostring(math.random(1000, 9999))
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
	},
	framesort_kick = { "#showtooltip {INTERRUPT}\n#FrameSort X {FS}\n/cancelaura {CANCEL}\n/cast [@focus,harm,nodead][@none,harm,nodead] {INTERRUPT}" },  -- 1.2.0 – 1.2.4
	framesort_external = { "#showtooltip {EXTERNAL}\n#FrameSort X {FST}\n/cast [@mouseover,help,nodead][@none,help,nodead] {EXTERNAL}" },      -- 1.2.3 – 1.2.4
	framesort_dispel = { "#showtooltip {DISPEL}\n#FrameSort X {FST}\n/cast [@mouseover,help,nodead][@none,help,nodead] {DISPEL}" },            -- 1.2.3 – 1.2.4
	focus_interrupt = {
		"#showtooltip\n/stopcasting\n/cast [@focus,harm,nodead][] {INTERRUPT}",   -- 1.0.0
		"#showtooltip\n/cast [@focus,harm,nodead][] {INTERRUPT}",                  -- 1.0.1 – 1.2.1
	},
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

-- Throws the whole list away (user templates included) and re-seeds it.
function ns.ResetAllTemplates()
	ns.db.templates = {}
	for _, b in ipairs(ns.builtinTemplates) do
		ns.db.templates[#ns.db.templates + 1] = CopyTemplate(b)
		ns.db.knownBuiltins[b.id] = true
	end
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

function ns.ExportTemplates()
	local out = { EXPORT_HEADER }
	for _, t in ipairs(ns.db.templates) do
		out[#out + 1] = ""
		out[#out + 1] = "[template]"
		out[#out + 1] = "id=" .. Esc(t.id)
		out[#out + 1] = "name=" .. Esc(t.name)
		out[#out + 1] = "desc=" .. Esc(t.desc)
		out[#out + 1] = "body=" .. Esc(t.body)
	end
	return table.concat(out, "\n")
end

-- Returns list, nil (entries { id, name, desc, body }, id may be nil) or
-- nil, error message.
function ns.ParseTemplates(text)
	text = (text or ""):gsub("\r", "")
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
		if e.body and e.body ~= "" then
			if e.id == "" then e.id = nil end
			if not e.name or e.name == "" then e.name = L["Untitled"] end
			e.desc = e.desc or ""
			valid[#valid + 1] = e
		end
	end
	return valid, nil
end

-- How ns.ImportTemplates would treat `list`: number added, number replaced.
function ns.CountImport(list)
	local added, replaced = 0, 0
	for _, e in ipairs(list) do
		if e.id and ns.FindTemplate(e.id) then replaced = replaced + 1 else added = added + 1 end
	end
	return added, replaced
end

-- Same id -> that template's text is replaced; otherwise added. An id that
-- belongs to a shipped template keeps its built-in bookkeeping (meta, seed).
function ns.ImportTemplates(list)
	local added, replaced = 0, 0
	for _, e in ipairs(list) do
		local existing = e.id and ns.FindTemplate(e.id)
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
			ns.db.templates[#ns.db.templates + 1] = t
			added = added + 1
		end
	end
	return added, replaced
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
-- instead: "{A}, {B}, {C}" with B empty becomes "{A}, {C}".
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
		if cmd and CAST_CMDS[cmd:lower()] then
			-- drop [conditionals] and a leading "!" toggle marker per token
			rest = rest:gsub("%[[^%]]*%]", "")
			rest = rest:gsub("^%s*reset=%S+%s*", "")   -- castsequence reset clause
			for tok in rest:gmatch("[^;,]+") do
				tok = strtrim(tok):gsub("^!", "")
				if not IsSkippableToken(tok) and not names[tok] then
					local name, kind = ResolveToken(tok)
					names[tok] = UniqueKey(KeyBaseFor(name, kind), used)
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
