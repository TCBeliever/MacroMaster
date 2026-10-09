local ADDON, ns = ...
local L = ns.L
local Skin = ns.Skin

-- ---------------------------------------------------------------------------
-- Shared bits
-- ---------------------------------------------------------------------------

-- Pop-ups open centred and come back where you last dragged them: the offset
-- from the screen centre is kept per frame name in db.settings.positions.
local function SavePosition(f)
	local x, y = f:GetCenter()
	local ux, uy = UIParent:GetCenter()
	if not (x and ux) then return end
	ns.db.settings.positions = ns.db.settings.positions or {}
	ns.db.settings.positions[f:GetName()] = { math.floor(x - ux + 0.5), math.floor(y - uy + 0.5) }
end

local function Popup(name, w, h, title)
	return Skin.Window(name, w, h, title, { onDragStop = SavePosition })
end

local function Anchor(f)
	f:ClearAllPoints()
	local pos = ns.db.settings.positions and ns.db.settings.positions[f:GetName()]
	if pos then
		f:SetPoint("CENTER", UIParent, "CENTER", pos[1], pos[2])
	else
		f:SetPoint("CENTER")
	end
end

local function Tip(widget, text)
	widget:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(type(text) == "function" and text(self) or text, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	widget:HookScript("OnLeave", GameTooltip_Hide)
end

-- ---------------------------------------------------------------------------
-- Variables reference
-- ---------------------------------------------------------------------------

-- { key, meaning, spell category|nil, fixed choices text|nil, item category|nil }
local function VariableDocs()
	return {
		{ "INTERRUPT", L["P_INTERRUPT_H"], "INTERRUPT" },
		{ "CC",        L["P_CC_H"],        "CC" },
		{ "HEAL",      L["P_HEAL_H"],      "HEAL" },
		{ "HARM",      L["P_HARM_H"],      nil },
		{ "GROUND",    L["P_GROUND_H"],    "GROUND" },
		{ "CD",        L["P_CD_H"],        "BURST" },
		{ "DEFENSIVE", L["CAT_DEFENSIVE"], "DEFENSIVE" },
		{ "MOVEMENT",  L["CAT_MOVEMENT"],  "MOVEMENT" },
		{ "SPELL",     L["P_SPELL_H"],     nil },
		{ "ARENA",     L["P_ARENA_H"],     nil, L["VAR_ARENA_D"] },
		{ "DISPEL",    L["P_DISPEL_H"],    "DISPEL" },
		{ "PURGE",     L["P_PURGE_H"],     "PURGE" },
		{ "EXTERNAL",  L["P_EXTERNAL_H"],  "EXTERNAL" },
		{ "FS",        L["P_FS_H"],        nil, L["VAR_FS_D"] },
		{ "FSENEMY",   L["P_FSENEMY_H"],   nil, L["VAR_FSENEMY_D"] },
		{ "MARK",      L["P_MARK_H"],      nil, L["VAR_MARK_D"] },
		{ "MSG",       L["P_MSG_H"],       nil },
		{ "AURA",      L["P_AURA_H"],      "CANCELAURA" },
		{ "CANCEL",    L["P_CANCEL_H"],    "CANCELAURA" },
		{ "SELFHEAL",  L["P_SELFHEAL_H"],  "SELFHEAL" },
		{ "HEALTHSTONE", L["P_HEALTHSTONE_H"], nil, nil, "HEALTHSTONE" },
		{ "POTION",    L["P_POTION_H"],    nil, nil, "HEALPOT" },
		{ "ITEM",      L["VAR_ITEM_D"],    nil, nil, "ITEM" },
	}
end

local varPanel
function ns.ShowVariablesPanel(parent)
	if not varPanel then
		local f = Popup("MacroMasterVariables", 560, 440, L["Built-in variables"])
		f.intro = Skin.Label(f, L["VAR_INTRO"], "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -36)
		f.intro:SetWidth(528)
		f.intro:SetJustifyH("LEFT")

		f.scroll = Skin.ScrollFrame(f, 560 - 16 - Skin.SCROLL_W - 4)
		f.scroll:SetPoint("TOPLEFT", 16, -96)
		f.scroll:SetPoint("BOTTOMRIGHT", -(Skin.SCROLL_W + 4), 40)
		f.content = f.scroll.content
		f.text = Skin.Label(f.content, "", "GameFontHighlightSmall")
		f.text:SetPoint("TOPLEFT")
		f.text:SetWidth(500)
		f.text:SetJustifyH("LEFT")
		f.text:SetSpacing(3)

		f.footer = Skin.Label(f, L["VAR_ALIASES"], "GameFontDisableSmall")
		f.footer:SetPoint("BOTTOMLEFT", 16, 16)
		f.footer:SetWidth(528)
		f.footer:SetJustifyH("LEFT")

		function f:Refresh()
			local lines = {}
			for _, d in ipairs(VariableDocs()) do
				local key, meaning, cat, choices, itemCat = d[1], d[2], d[3], d[4], d[5]
				local line = Skin.Text("head", "{" .. key .. "}") .. "  " .. meaning
				if cat then line = line .. "\n      " .. Skin.Text("accent", L["VAR_SUGGEST"] .. ":") .. " " .. L["CAT_" .. cat] end
				if itemCat then line = line .. "\n      " .. Skin.Text("accent", L["VAR_ITEM"] .. ":") .. " " .. L["CAT_" .. itemCat] end
				if choices then line = line .. "\n      " .. Skin.Text("accent", L["VAR_OPTIONS"] .. ":") .. " " .. choices end
				lines[#lines + 1] = line
			end
			self.text:SetText(table.concat(lines, "\n\n"))
			self.content:SetHeight(self.text:GetStringHeight() + 10)
		end
		f:SetScript("OnShow", f.Refresh)
		varPanel = f
	end
	Anchor(varPanel)
	varPanel:Show()
end

-- ---------------------------------------------------------------------------
-- Built-in templates: catalogue of what ships with the addon (Settings -> Add more built-ins)
-- ---------------------------------------------------------------------------

StaticPopupDialogs["MACROMASTER_OVERWRITE_DEFAULT"] = {
	text = L["Overwrite your copy of '%s' with the default?"],
	button1 = L["Overwrite"], button2 = CANCEL,
	OnAccept = function(self, id)
		ns.ImportBuiltin(id, true)
		ns.SelectTemplate(id)
		local t = ns.FindTemplate(id)
		ns.Msg(L["MSG_DEFAULT_REPLACED"], t and t.name or id)
		if ns.RefreshDefaultsPanel then ns.RefreshDefaultsPanel() end
	end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["MACROMASTER_RESET_ALL"] = {
	text = L["RESET_ALL_CONFIRM"],
	button1 = L["Reset"], button2 = CANCEL,
	OnAccept = function()
		ns.ResetAllTemplates()
		ns.ReselectTemplate()
		ns.Msg(L["MSG_RESET_ALL"])
		if ns.RefreshDefaultsPanel then ns.RefreshDefaultsPanel() end
	end,
	timeout = 0, whileDead = true, hideOnEscape = true, showAlert = true,
}

ns.onLocale = ns.onLocale or {}
table.insert(ns.onLocale, function()
	StaticPopupDialogs["MACROMASTER_OVERWRITE_DEFAULT"].text = L["Overwrite your copy of '%s' with the default?"]
	StaticPopupDialogs["MACROMASTER_OVERWRITE_DEFAULT"].button1 = L["Overwrite"]
	StaticPopupDialogs["MACROMASTER_RESET_ALL"].text = L["RESET_ALL_CONFIRM"]
	StaticPopupDialogs["MACROMASTER_RESET_ALL"].button1 = L["Reset"]
	StaticPopupDialogs["MACROMASTER_IMPORT_TEXT"].button1 = L["Import"]
end)

local defaultsPanel
function ns.ShowDefaultsPanel(parent)
	if not defaultsPanel then
		local W, H = 720, 540
		local f = Popup("MacroMasterDefaults", W, H, L["Built-in templates"])
		f.filter = "REC"

		-- filter row: recommended for this class / all / one category
		f.tabs = {}
		local filters = { "REC", "ALL" }
		for _, c in ipairs(ns.templateCategories) do filters[#filters + 1] = c end
		local prev
		for i, key in ipairs(filters) do
			local btn = Skin.Button(f, "", 60, 22, function(self) f.filter = self.filter; f.selected = nil; f:Refresh() end)
			btn.filter = key
			if i == 1 then btn:SetPoint("TOPLEFT", 14, -38) else btn:SetPoint("LEFT", prev, "RIGHT", 4, 0) end
			f.tabs[i] = btn
			prev = btn
		end

		f.intro = Skin.Label(f, L["DEFAULTS_INTRO"], "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -68)
		f.intro:SetWidth(W - 32)
		f.intro:SetJustifyH("LEFT")

		-- left: list
		local listBox = Skin.Box(f)
		listBox:SetPoint("TOPLEFT", 14, -104)
		listBox:SetSize(240, H - 104 - 50)
		f.scroll = Skin.ScrollFrame(listBox, 240 - 6 - Skin.SCROLL_W)
		f.scroll:SetPoint("TOPLEFT", 6, -6)
		f.scroll:SetPoint("BOTTOMRIGHT", -Skin.SCROLL_W, 6)
		f.content = f.scroll.content
		f.buttons = {}

		-- right: read-only preview
		f.pname = Skin.Label(f, "", "GameFontNormal")
		f.pname:SetPoint("TOPLEFT", listBox, "TOPRIGHT", 12, -2)
		f.pname:SetWidth(W - 240 - 14 - 12 - 14)
		f.pname:SetJustifyH("LEFT")
		f.pdesc = Skin.Label(f, "", "GameFontHighlightSmall")
		f.pdesc:SetPoint("TOPLEFT", f.pname, "BOTTOMLEFT", 0, -4)
		f.pdesc:SetWidth(W - 240 - 14 - 12 - 14)
		f.pdesc:SetJustifyH("LEFT")
		f.pdesc:SetHeight(56)
		f.pdesc:SetJustifyV("TOP")
		local bodyBox = Skin.Box(f)
		bodyBox:SetPoint("TOPLEFT", f.pdesc, "BOTTOMLEFT", -6, -6)
		bodyBox:SetPoint("BOTTOMRIGHT", -14, 118)   -- leaves room for two status lines above the buttons
		f.bodyScroll = Skin.ScrollFrame(bodyBox, 400)
		f.bodyScroll:SetPoint("TOPLEFT", 8, -8)
		f.bodyScroll:SetPoint("BOTTOMRIGHT", -Skin.SCROLL_W, 8)
		f.bodyContent = f.bodyScroll.content
		f.pbody = Skin.Label(f.bodyContent, "", "ChatFontNormal")
		f.pbody:SetPoint("TOPLEFT")
		f.pbody:SetWidth(400)
		f.pbody:SetJustifyH("LEFT")
		f.status = Skin.Label(f, "", "GameFontHighlightSmall")
		f.status:SetPoint("TOPLEFT", bodyBox, "BOTTOMLEFT", 2, -6)
		f.status:SetWidth(W - 240 - 14 - 12 - 14)
		f.status:SetJustifyH("LEFT")
		f.status:SetHeight(36)
		f.status:SetJustifyV("TOP")

		-- actions: Add = the selected template, Add all = every template on
		-- this tab that is not in the list yet
		f.add = Skin.Button(f, L["Add template"], 100, 22, function()
			local id = f.selected
			if not id then return end
			local b = ns.ShippedTemplate(id)
			local r = ns.ImportBuiltin(id, false)
			if r == "exists" then
				StaticPopup_Show("MACROMASTER_OVERWRITE_DEFAULT", b.name, nil, id)
			elseif r == "added" then
				ns.SelectTemplate(id)
				ns.Msg(L["MSG_DEFAULT_ADDED"], b.name)
				f:Refresh()
			end
		end)
		f.add:SetPoint("BOTTOMLEFT", listBox, "BOTTOMRIGHT", 12, 0)
		Tip(f.add, L["ADD_HELP"])

		f.addAll = Skin.Button(f, L["Add all"], 100, 22, function()
			local n = 0
			for _, b in ipairs(f.list or {}) do
				if ns.ImportBuiltin(b.id, false) == "added" then n = n + 1 end
			end
			ns.ReselectTemplate()
			ns.Msg(L["MSG_ALL_ADDED"], n)
			f:Refresh()
		end)
		f.addAll:SetPoint("LEFT", f.add, "RIGHT", 6, 0)
		Tip(f.addAll, L["ADD_ALL_HELP"])

		f.reset = Skin.Button(f, L["Reset all to defaults"], 160, 22, function() StaticPopup_Show("MACROMASTER_RESET_ALL") end)
		f.reset:SetPoint("BOTTOMRIGHT", -14, 14)

		function f:Refresh()
			local className = UnitClass("player")
			for _, btn in ipairs(self.tabs) do
				local key = btn.filter
				btn:SetLabel(key == "REC" and string.format(L["Recommended for %s"], className)
					or key == "ALL" and L["All"] or L["TCAT_" .. key])
				btn:SetSelected(key == self.filter)
			end

			-- which shipped templates this view lists
			local rec = ns.RecommendedTemplates()
			local recIndex = {}
			for i, id in ipairs(rec) do recIndex[id] = i end
			local list = {}
			if self.filter == "REC" then
				for _, id in ipairs(rec) do list[#list + 1] = ns.ShippedTemplate(id) end
			else
				for i, b in ipairs(ns.builtinTemplates) do
					if self.filter == "ALL" or b.cat == self.filter then
						list[#list + 1] = b
						b.fits = ns.TemplateFitsClass(b)
						b.order = i
					end
				end
				-- what fits this class first, shipped order otherwise
				table.sort(list, function(x, y)
					if x.fits ~= y.fits then return x.fits end
					return x.order < y.order
				end)
			end
			self.list = list   -- what Add all works on
			if not self.selected or not ns.ShippedTemplate(self.selected) then self.selected = list[1] and list[1].id end

			local known = ns.db.knownBuiltins or {}
			for i, b in ipairs(list) do
				local btn = self.buttons[i]
				if not btn then
					btn = Skin.Row(self.content)
					btn:SetHeight(22)
					btn.text = Skin.Label(btn, "", "GameFontHighlightSmall")
					btn.text:SetPoint("LEFT", 6, 0)
					btn.text:SetPoint("RIGHT", -4, 0)
					btn.text:SetJustifyH("LEFT")
					btn.text:SetWordWrap(false)
					btn:SetScript("OnClick", function(self) f.selected = self.templateID; f:Refresh() end)
					self.buttons[i] = btn
				end
				btn.templateID = b.id
				local mine = ns.FindTemplate(b.id)
				local fits = ns.TemplateFitsClass(b)
				local name = fits and b.name or Skin.Text("dim", b.name)
				local tag = (not known[b.id]) and (" " .. Skin.Text("ok", L["NEW"])) or ""
				btn.text:SetText((mine and "   " or (Skin.Text("head", "+") .. " ")) .. name .. tag)
				btn:SetSelected(b.id == self.selected)
				btn:ClearAllPoints()
				btn:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
				btn:SetPoint("TOPRIGHT", 0, -(i - 1) * 22)
				btn:Show()
			end
			for i = #list + 1, #self.buttons do self.buttons[i]:Hide() end
			self.content:SetHeight(math.max(10, #list * 22))

			local b = self.selected and ns.ShippedTemplate(self.selected)
			if b then
				self.pname:SetText(b.name .. "  " .. Skin.Text("dim", L["TCAT_" .. (b.cat or "CORE")]))
				self.pdesc:SetText(b.desc or "")
				self.pbody:SetText(b.body)
				self.bodyContent:SetHeight(self.pbody:GetStringHeight() + 10)
				local mine = ns.FindTemplate(b.id)
				local lines = {}
				if not mine then lines[1] = L["(not in your list)"]
				elseif mine.body == b.body then lines[1] = L["(in your list, unchanged)"]
				else lines[1] = L["(in your list, edited)"] end
				if recIndex[b.id] then lines[#lines + 1] = string.format(L["Recommended for %s"], className) .. "." end
				if not ns.TemplateFitsClass(b) then lines[#lines + 1] = Skin.Text("dim", string.format(L["FIT_NO"], className)) end
				self.status:SetText(table.concat(lines, "\n"))
			else
				self.pname:SetText(""); self.pdesc:SetText(""); self.pbody:SetText(""); self.status:SetText("")
			end
			local missing = 0
			for _, t in ipairs(list) do if not ns.FindTemplate(t.id) then missing = missing + 1 end end
			self.addAll:SetEnabled(missing > 0)
		end

		f:SetScript("OnShow", f.Refresh)
		-- everything shown once is no longer "new"
		f:SetScript("OnHide", function() ns.MarkBuiltinsKnown(); if ns.RefreshSettingsPage then ns.RefreshSettingsPage() end end)
		defaultsPanel = f
		function ns.RefreshDefaultsPanel() if defaultsPanel:IsShown() then defaultsPanel:Refresh() end end
	end
	Anchor(defaultsPanel)
	defaultsPanel:Show()
end

-- ---------------------------------------------------------------------------
-- Import confirmation (the Import window below hands it the parsed list)
-- ---------------------------------------------------------------------------

StaticPopupDialogs["MACROMASTER_IMPORT_TEXT"] = {
	text = "%s",
	button1 = L["Import"], button2 = CANCEL,
	OnAccept = function(self, data)
		local added, replaced = ns.ImportTemplates(data.list, data.mode)
		if ns.HideImportPanel then ns.HideImportPanel() end
		ns.ReselectTemplate()
		ns.Msg(L["MSG_TEMPLATES_IMPORTED"], added, replaced)
		if ns.RefreshDefaultsPanel then ns.RefreshDefaultsPanel() end
	end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ---------------------------------------------------------------------------
-- Copy window (Share, Export): a string, selected and ready for Ctrl+C, a
-- "close after copy" tick and nothing else.
-- ---------------------------------------------------------------------------

local copyPanel
local function ShowCopyPanel(title, text)
	if not copyPanel then
		local W, H = 520, 200
		local f = Popup("MacroMasterCopy", W, H, "")

		local box = Skin.MultiLine(f, W - 28, H - 36 - 44, 0, true)
		box:SetPoint("TOPLEFT", 14, -36)
		local e = box.EditBox
		e:SetScript("OnEscapePressed", function() f:Hide() end)
		-- meant to be copied, not edited: a click reselects it, typing restores it
		e:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
		e:SetScript("OnTextChanged", function(self, userInput)
			if userInput then
				self:SetText(f.text or "")
				self:HighlightText()
			end
		end)
		-- Ctrl+C is the whole point of the window: close right after it
		e:SetScript("OnKeyDown", function(self, key)
			if key == "C" and IsControlKeyDown() and ns.db.settings.closeAfterCopy then
				C_Timer.After(0.1, function() f:Hide() end)
			end
		end)
		f.edit = e

		f.closeAfter = Skin.Checkbox(f, "MacroMasterCopyCloseAfter", L["Close after copy"], function(self)
			ns.db.settings.closeAfterCopy = self:GetChecked() and true or false
		end)
		f.closeAfter:SetPoint("BOTTOMLEFT", 12, 12)

		f.okay = Skin.Button(f, OKAY, 90, 22, function() f:Hide() end)
		f.okay:SetPoint("BOTTOMRIGHT", -14, 14)
		copyPanel = f
	end
	local f = copyPanel
	f.title:SetText(title)
	f.text = text
	f.closeAfter:SetChecked(ns.db.settings.closeAfterCopy)
	Anchor(f)
	f:Show()
	f.edit:SetText(text)
	f.edit:SetFocus()
	f.edit:HighlightText()
end

-- One template, as the editor shows it right now.
function ns.ShowSharePanel(template)
	ShowCopyPanel(string.format(L["Share: %s"], template.name), ns.EncodeTemplates({ template }))
end

-- The whole list, as a backup.
function ns.ShowExportPanel()
	ShowCopyPanel(L["Export"], ns.EncodeTemplates())
end

-- ---------------------------------------------------------------------------
-- Import window: paste a string, say what a template you already have does,
-- press Import. The confirmation popup above does the actual import.
-- ---------------------------------------------------------------------------

local importPanel
function ns.ShowImportPanel()
	if not importPanel then
		local W, H = 520, 260
		local f = Popup("MacroMasterImport", W, H, L["Import"])

		local box = Skin.MultiLine(f, W - 28, H - 36 - 44, 0, true)
		box:SetPoint("TOPLEFT", 14, -36)
		box.EditBox:SetScript("OnEscapePressed", function() f:Hide() end)
		f.edit = box.EditBox

		-- what happens to a template whose id is already in the list
		f.modeLabel = Skin.Label(f, L["Same id:"], "GameFontNormalSmall")
		f.modeLabel:SetPoint("BOTTOMLEFT", 16, 19)
		f.modes = {}
		local prev = f.modeLabel
		for i, mode in ipairs({ "replace", "add" }) do
			local r = Skin.Radio(f, "MacroMasterImportMode" .. i, mode == "replace" and L["Replace"] or L["Add new"], function(self)
				ns.db.settings.importMode = self.mode
				f:RefreshMode()
			end)
			r:SetPoint("LEFT", prev, "RIGHT", i == 1 and 6 or 10, 0)
			r.mode = mode
			Tip(r, function(self) return self.mode == "replace" and L["MODE_REPLACE_HELP"] or L["MODE_ADD_HELP"] end)
			f.modes[i] = r
			prev = r.label
		end
		function f:RefreshMode()
			for _, r in ipairs(self.modes) do r:SetChecked(r.mode == ns.db.settings.importMode) end
		end

		f.import = Skin.Button(f, L["Import"], 100, 22, function()
			local list, err = ns.ParseTemplates(f.edit:GetText())
			if not list then ns.Msg(err); return end
			if #list == 0 then ns.Msg(L["MSG_IMPORT_EMPTY"]); return end
			local mode = ns.db.settings.importMode
			local added, replaced = ns.CountImport(list, mode)
			local text = replaced > 0
				and string.format(L["Import %d new template(s) and replace %d existing?"], added, replaced)
				or string.format(L["Import %d template(s)?"], added)
			-- templates that run Lua are called out before anything is added
			local code = 0
			for _, e in ipairs(list) do if e.code then code = code + 1 end end
			if code > 0 then
				text = text .. "\n\n" .. Skin.Text("bad", string.format(L["IMPORT_CODE_WARNING"], code))
			end
			StaticPopup_Show("MACROMASTER_IMPORT_TEXT", text, nil, { list = list, mode = mode })
		end)
		f.import:SetPoint("BOTTOMRIGHT", -14, 14)
		function ns.HideImportPanel() f:Hide() end
		importPanel = f
	end
	local f = importPanel
	f:RefreshMode()
	Anchor(f)
	f:Show()
	f.edit:SetText("")
	f.edit:SetFocus()
end

-- ---------------------------------------------------------------------------
-- Spell table editor (current class)
-- ---------------------------------------------------------------------------

local tablePanel
function ns.ShowSpellTablePanel(parent)
	if not tablePanel then
		local f = Popup("MacroMasterSpellTable", 620, 480, "")
		f.category = ns.categories[1]

		f.intro = Skin.Label(f, L["TABLE_INTRO"], "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -36)
		f.intro:SetWidth(588)
		f.intro:SetJustifyH("LEFT")

		-- category tabs
		f.tabs = {}
		local PER_ROW = 6
		for i, cat in ipairs(ns.categories) do
			local b = Skin.Button(f, L["CAT_" .. cat], 96, 22, function(self) f.category = self.category; f:Refresh() end)
			b.category = cat
			local row, col = math.floor((i - 1) / PER_ROW), (i - 1) % PER_ROW
			b:SetPoint("TOPLEFT", 14 + col * 100, -100 - row * 26)
			f.tabs[i] = b
		end

		f.status = Skin.Label(f, "", "GameFontDisableSmall")
		f.status:SetPoint("TOPLEFT", 16, -156)

		local box = Skin.Box(f)
		box:SetPoint("TOPLEFT", 14, -170)
		box:SetPoint("BOTTOMRIGHT", -14, 44)

		f.scroll = Skin.ScrollFrame(box, 620 - 28 - 6 - Skin.SCROLL_W)
		f.scroll:SetPoint("TOPLEFT", 6, -6)
		f.scroll:SetPoint("BOTTOMRIGHT", -Skin.SCROLL_W, 6)
		f.content = f.scroll.content
		f.rows = {}

		f.add = Skin.Button(f, L["Add"], 90, 22, function()
			ns.ShowSpellPicker(f, function(name, spellID)
				if spellID then
					ns.AddSuggestion(f.category, spellID)
					f:Refresh()
				end
			end)
		end)
		f.add:SetPoint("BOTTOMLEFT", 14, 14)

		f.reset = Skin.Button(f, L["Reset to shipped"], 110, 22, function()
			ns.ResetSuggestions(f.category)
			f:Refresh()
		end)
		f.reset:SetPoint("LEFT", f.add, "RIGHT", 6, 0)

		function f:Refresh()
			local className = UnitClass("player")
			self.title:SetText(string.format(L["Spell table for %s"], className))
			for _, b in ipairs(self.tabs) do
				b:SetSelected(b.category == self.category)
			end
			self.status:SetText(ns.IsSuggestionCustomized(self.category) and L["(custom)"] or "")

			ns.ScanSpellBook()
			local list = ns.ResolveSuggestions(self.category, false)
			for i, s in ipairs(list) do
				local r = self.rows[i]
				if not r then
					r = CreateFrame("Frame", nil, self.content)
					r:SetHeight(24)
					r.icon = r:CreateTexture(nil, "ARTWORK")
					r.icon:SetSize(20, 20)
					r.icon:SetPoint("LEFT", 2, 0)
					r.name = Skin.Label(r, "", "GameFontHighlightSmall")
					r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
					r.name:SetWidth(420)
					r.name:SetJustifyH("LEFT")
					r.remove = Skin.CloseButton(r, function(self)
						ns.RemoveSuggestion(f.category, self:GetParent().spellID)
						f:Refresh()
					end)
					r.remove:SetSize(22, 22)
					r.remove:SetPoint("RIGHT", -2, 0)
					r:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetSpellByID(self.spellID)
						GameTooltip:Show()
					end)
					r:SetScript("OnLeave", GameTooltip_Hide)
					r:EnableMouse(true)
					self.rows[i] = r
				end
				r.spellID = s.id
				r.icon:SetTexture(s.icon)
				r.icon:SetDesaturated(not s.known)
				r.name:SetText(s.known and s.name or Skin.Text("dim", s.name .. " " .. L["(not known by this character)"]))
				r:ClearAllPoints()
				r:SetPoint("TOPLEFT", 0, -(i - 1) * 24)
				r:SetPoint("TOPRIGHT", 0, -(i - 1) * 24)
				r:Show()
			end
			for i = #list + 1, #self.rows do self.rows[i]:Hide() end
			self.content:SetHeight(math.max(10, #list * 24))
		end

		f:SetScript("OnShow", f.Refresh)
		tablePanel = f
	end
	Anchor(tablePanel)
	tablePanel:Show()
end

-- After a palette switch: the windows that build inline colours draw them again
function ns.RefreshPanels()
	for _, f in pairs({ varPanel, defaultsPanel, tablePanel }) do
		if f:IsShown() then f:Refresh() end
	end
end

-- ---------------------------------------------------------------------------
-- Settings page (second tab of the main window): language, theme, and the
-- doors to the defaults catalogue and export/import. `main` anchors those panels.
-- ---------------------------------------------------------------------------

local LANGUAGES = {
	{ code = nil,    label = "Auto (client language)" },
	{ code = "enUS", label = "English" },
	{ code = "zhTW", label = "繁體中文" },
}

function ns.BuildSettingsPage(f, main)
	StaticPopupDialogs["MACROMASTER_RELOAD"] = {
		text = L["RELOAD_CONFIRM"],
		button1 = L["Reload"], button2 = CANCEL,
		OnAccept = function() ReloadUI() end,
		timeout = 0, whileDead = true, hideOnEscape = true,
	}

	local x, y = 24, -64
	local lang = Skin.Label(f, L["Language"], "GameFontNormal")
	lang:SetPoint("TOPLEFT", x, y)
	local note = Skin.Label(f, L["LANG_NOTE"], "GameFontDisableSmall")
	note:SetPoint("LEFT", lang, "RIGHT", 8, 0)

	f.radios = {}
	for i, entry in ipairs(LANGUAGES) do
		local r = Skin.Radio(f, "MacroMasterLang" .. i, entry.code and entry.label or L["Auto (client language)"], function(self)
			local before = ns.db.settings.locale
			ns.db.settings.locale = self.code
			f:Refresh()
			if before ~= self.code then StaticPopup_Show("MACROMASTER_RELOAD") end
		end)
		r:SetPoint("TOPLEFT", x + 4, y - 22 - (i - 1) * 22)
		r.code = entry.code
		f.radios[i] = r
	end

	-- the look: the game's own frames, or the flat modern one (beta) in one
	-- of two palettes. Between the looks the frames are built differently,
	-- so that switch waits for a reload; between the palettes it is at once.
	local theme = Skin.Label(f, L["Theme"], "GameFontNormal")
	theme:SetPoint("TOPLEFT", x, y - 110)
	local themeNote = Skin.Label(f, L["THEME_NOTE"], "GameFontDisableSmall")
	themeNote:SetPoint("LEFT", theme, "RIGHT", 8, 0)
	f.themes = {}
	for i, entry in ipairs(Skin.THEMES) do
		local r = Skin.Radio(f, "MacroMasterTheme" .. i, L["THEME_" .. entry.key], function(self)
			ns.db.settings.theme = self.key
			f:Refresh()
			if Skin.IsModernKey(self.key) ~= Skin.modern then
				StaticPopup_Show("MACROMASTER_RELOAD")
			elseif Skin.modern then
				ns.SetTheme(self.key)
			end
		end)
		r:SetPoint("TOPLEFT", x + 4, y - 132 - (i - 1) * 22)
		r.key = entry.key
		f.themes[i] = r
	end

	local lib = Skin.Label(f, L["Templates"], "GameFontNormal")
	lib:SetPoint("TOPLEFT", x, y - 220)
	f.hint = Skin.Label(f, string.format(L["SETTINGS_TEMPLATES_HINT"], #ns.builtinTemplates), "GameFontHighlightSmall")
	f.hint:SetPoint("TOPLEFT", x + 4, y - 242)
	f.hint:SetWidth(520)
	f.hint:SetJustifyH("LEFT")

	f.defaults = Skin.Button(f, L["Add more built-ins"], 160, 22, function() ns.ShowDefaultsPanel(main) end)
	f.defaults:SetPoint("TOPLEFT", f.hint, "BOTTOMLEFT", 0, -10)

	f.export = Skin.Button(f, L["Export"], 100, 22, ns.ShowExportPanel)
	f.export:SetPoint("LEFT", f.defaults, "RIGHT", 8, 0)

	f.import = Skin.Button(f, L["Import"], 100, 22, ns.ShowImportPanel)
	f.import:SetPoint("LEFT", f.export, "RIGHT", 8, 0)

	-- community: templates of your own are welcome on the project's comments.
	-- The game cannot open a browser, so the address sits in a box to copy.
	local COMMUNITY_URL = "https://www.curseforge.com/wow/addons/macromaster/comments"
	local share = Skin.Label(f, L["Share your templates"], "GameFontNormal")
	share:SetPoint("TOPLEFT", x, y - 346)
	f.shareHint = Skin.Label(f, L["SHARE_COMMUNITY_HINT"], "GameFontHighlightSmall")
	f.shareHint:SetPoint("TOPLEFT", x + 4, y - 368)
	f.shareHint:SetWidth(520)
	f.shareHint:SetJustifyH("LEFT")
	f.shareURL = Skin.EditBox(f, 420)
	f.shareURL:SetPoint("TOPLEFT", f.shareHint, "BOTTOMLEFT", Skin.EDIT_INSET, -8)
	f.shareURL:SetText(COMMUNITY_URL)
	f.shareURL:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
	f.shareURL:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(COMMUNITY_URL)
			self:HighlightText()
		end
	end)

	function f:Refresh()
		for _, r in ipairs(self.radios) do r:SetChecked(r.code == ns.db.settings.locale) end
		for _, r in ipairs(self.themes) do r:SetChecked(r.key == ns.db.settings.theme) end
		local n = ns.NewBuiltinCount()
		f.defaults:SetLabel(n > 0 and string.format(L["Add more built-ins (%d new)"], n) or L["Add more built-ins"])
	end
	f:SetScript("OnShow", f.Refresh)
	ns.RefreshSettingsPage = function() if f:IsShown() then f:Refresh() end end
end
