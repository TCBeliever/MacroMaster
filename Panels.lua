local ADDON, ns = ...
local L = ns.L

-- ---------------------------------------------------------------------------
-- Shared bits
-- ---------------------------------------------------------------------------

local function Popup(name, w, h, title)
	local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	f:SetSize(w, h)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})
	f:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.title:SetPoint("TOP", 0, -14)
	f.title:SetText(title)
	f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.close:SetPoint("TOPRIGHT", -4, -4)
	tinsert(UISpecialFrames, name)
	f:Hide()
	return f
end

-- widen a button whose label (other language) is longer than its width
local function Fit(b)
	local fs = b:GetFontString()
	if not fs then return end
	local need = fs:GetStringWidth() + 20
	if need > b:GetWidth() then b:SetWidth(need) end
end

local function Anchor(f, parent)
	f:ClearAllPoints()
	if parent and parent:IsShown() then
		f:SetPoint("TOPLEFT", parent, "TOPRIGHT", 8, 0)
	else
		f:SetPoint("CENTER")
	end
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
		f.intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -36)
		f.intro:SetWidth(528)
		f.intro:SetJustifyH("LEFT")
		f.intro:SetText(L["VAR_INTRO"])

		f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
		f.scroll:SetPoint("TOPLEFT", 16, -96)
		f.scroll:SetPoint("BOTTOMRIGHT", -30, 40)
		f.content = CreateFrame("Frame", nil, f.scroll)
		f.content:SetSize(500, 10)
		f.scroll:SetScrollChild(f.content)
		f.text = f.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.text:SetPoint("TOPLEFT")
		f.text:SetWidth(500)
		f.text:SetJustifyH("LEFT")
		f.text:SetSpacing(3)

		f.footer = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		f.footer:SetPoint("BOTTOMLEFT", 16, 16)
		f.footer:SetWidth(528)
		f.footer:SetJustifyH("LEFT")
		f.footer:SetText(L["VAR_ALIASES"])

		f:SetScript("OnShow", function(self)
			local lines = {}
			for _, d in ipairs(VariableDocs()) do
				local key, meaning, cat, choices, itemCat = d[1], d[2], d[3], d[4], d[5]
				local line = "|cffffd100{" .. key .. "}|r  " .. meaning
				if cat then line = line .. "\n      |cff66ccff" .. L["VAR_SUGGEST"] .. ":|r " .. L["CAT_" .. cat] end
				if itemCat then line = line .. "\n      |cff66ccff" .. L["VAR_ITEM"] .. ":|r " .. L["CAT_" .. itemCat] end
				if choices then line = line .. "\n      |cff66ccff" .. L["VAR_OPTIONS"] .. ":|r " .. choices end
				lines[#lines + 1] = line
			end
			self.text:SetText(table.concat(lines, "\n\n"))
			self.content:SetHeight(self.text:GetStringHeight() + 10)
		end)
		varPanel = f
	end
	Anchor(varPanel, parent)
	varPanel:Show()
end

-- ---------------------------------------------------------------------------
-- Default templates: read-only catalogue of what ships with the addon
-- ---------------------------------------------------------------------------

local function InsetBox(parent)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	box:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	box:SetBackdropColor(0, 0, 0, 0.6)
	box:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	return box
end

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
		local f = Popup("MacroMasterDefaults", W, H, L["Default templates"])
		f.filter = "REC"

		-- filter row: recommended for this class / all / one category
		f.tabs = {}
		local filters = { "REC", "ALL" }
		for _, c in ipairs(ns.templateCategories) do filters[#filters + 1] = c end
		local prev
		for i, key in ipairs(filters) do
			local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
			btn:SetSize(60, 22)
			btn.filter = key
			if i == 1 then btn:SetPoint("TOPLEFT", 14, -38) else btn:SetPoint("LEFT", prev, "RIGHT", 4, 0) end
			btn:SetScript("OnClick", function(self) f.filter = self.filter; f.selected = nil; f:Refresh() end)
			f.tabs[i] = btn
			prev = btn
		end

		f.intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -68)
		f.intro:SetWidth(W - 32)
		f.intro:SetJustifyH("LEFT")
		f.intro:SetText(L["DEFAULTS_INTRO"])

		-- left: list
		local listBox = InsetBox(f)
		listBox:SetPoint("TOPLEFT", 14, -104)
		listBox:SetSize(240, H - 104 - 50)
		f.scroll = CreateFrame("ScrollFrame", nil, listBox, "UIPanelScrollFrameTemplate")
		f.scroll:SetPoint("TOPLEFT", 6, -6)
		f.scroll:SetPoint("BOTTOMRIGHT", -26, 6)
		f.content = CreateFrame("Frame", nil, f.scroll)
		f.content:SetSize(200, 10)
		f.scroll:SetScrollChild(f.content)
		f.buttons = {}

		-- right: read-only preview
		f.pname = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.pname:SetPoint("TOPLEFT", listBox, "TOPRIGHT", 12, -2)
		f.pname:SetWidth(W - 240 - 14 - 12 - 14)
		f.pname:SetJustifyH("LEFT")
		f.pdesc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.pdesc:SetPoint("TOPLEFT", f.pname, "BOTTOMLEFT", 0, -4)
		f.pdesc:SetWidth(W - 240 - 14 - 12 - 14)
		f.pdesc:SetJustifyH("LEFT")
		f.pdesc:SetHeight(56)
		f.pdesc:SetJustifyV("TOP")
		local bodyBox = InsetBox(f)
		bodyBox:SetPoint("TOPLEFT", f.pdesc, "BOTTOMLEFT", -6, -6)
		bodyBox:SetPoint("BOTTOMRIGHT", -14, 118)   -- leaves room for two status lines above the buttons
		f.bodyScroll = CreateFrame("ScrollFrame", nil, bodyBox, "UIPanelScrollFrameTemplate")
		f.bodyScroll:SetPoint("TOPLEFT", 8, -8)
		f.bodyScroll:SetPoint("BOTTOMRIGHT", -26, 8)
		f.bodyContent = CreateFrame("Frame", nil, f.bodyScroll)
		f.bodyContent:SetSize(400, 10)
		f.bodyScroll:SetScrollChild(f.bodyContent)
		f.pbody = f.bodyContent:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
		f.pbody:SetPoint("TOPLEFT")
		f.pbody:SetWidth(400)
		f.pbody:SetJustifyH("LEFT")
		f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.status:SetPoint("TOPLEFT", bodyBox, "BOTTOMLEFT", 2, -6)
		f.status:SetWidth(W - 240 - 14 - 12 - 14)
		f.status:SetJustifyH("LEFT")
		f.status:SetHeight(36)
		f.status:SetJustifyV("TOP")

		-- actions
		f.add = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.add:SetSize(160, 22)
		f.add:SetPoint("BOTTOMLEFT", listBox, "BOTTOMRIGHT", 12, 0)
		f.add:SetText(L["Add to my templates"])
		Fit(f.add)
		f.add:SetScript("OnClick", function()
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

		f.addRec = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.addRec:SetSize(160, 22)
		f.addRec:SetPoint("LEFT", f.add, "RIGHT", 6, 0)
		f.addRec:SetText(L["Add all recommended"])
		Fit(f.addRec)
		f.addRec:SetScript("OnClick", function()
			local n = ns.AddRecommended()
			ns.ReselectTemplate()
			ns.Msg(L["MSG_RECOMMENDED_ADDED"], n)
			f:Refresh()
		end)

		f.reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.reset:SetSize(160, 22)
		f.reset:SetPoint("BOTTOMRIGHT", -14, 14)
		f.reset:SetText(L["Reset all to defaults"])
		Fit(f.reset)
		f.reset:SetScript("OnClick", function() StaticPopup_Show("MACROMASTER_RESET_ALL") end)

		function f:Refresh()
			local className = UnitClass("player")
			for _, btn in ipairs(self.tabs) do
				local key = btn.filter
				btn:SetText(key == "REC" and string.format(L["Recommended for %s"], className)
					or key == "ALL" and L["All"] or L["TCAT_" .. key])
				Fit(btn)
				btn:SetEnabled(key ~= self.filter)
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
			if not self.selected or not ns.ShippedTemplate(self.selected) then self.selected = list[1] and list[1].id end

			local known = ns.db.knownBuiltins or {}
			for i, b in ipairs(list) do
				local btn = self.buttons[i]
				if not btn then
					btn = CreateFrame("Button", nil, self.content)
					btn:SetSize(200, 22)
					btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
					btn.text:SetPoint("LEFT", 6, 0)
					btn.text:SetPoint("RIGHT", -4, 0)
					btn.text:SetJustifyH("LEFT")
					btn.text:SetWordWrap(false)
					btn.sel = btn:CreateTexture(nil, "BACKGROUND")
					btn.sel:SetAllPoints()
					btn.sel:SetColorTexture(0.3, 0.55, 0.9, 0.35)
					btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
					btn:SetScript("OnClick", function(self) f.selected = self.templateID; f:Refresh() end)
					self.buttons[i] = btn
				end
				btn.templateID = b.id
				local mine = ns.FindTemplate(b.id)
				local fits = ns.TemplateFitsClass(b)
				local name = fits and b.name or ("|cff808080" .. b.name .. "|r")
				local tag = (not known[b.id]) and (" |cff40ff40" .. L["NEW"] .. "|r") or ""
				btn.text:SetText((mine and "   " or "|cffffd100+|r ") .. name .. tag)
				btn.sel:SetShown(b.id == self.selected)
				btn:ClearAllPoints()
				btn:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
				btn:Show()
			end
			for i = #list + 1, #self.buttons do self.buttons[i]:Hide() end
			self.content:SetHeight(math.max(10, #list * 22))

			local b = self.selected and ns.ShippedTemplate(self.selected)
			if b then
				self.pname:SetText(b.name .. "  |cff808080" .. L["TCAT_" .. (b.cat or "CORE")] .. "|r")
				self.pdesc:SetText(b.desc or "")
				self.pbody:SetText(b.body)
				self.bodyContent:SetHeight(self.pbody:GetStringHeight() + 10)
				local mine = ns.FindTemplate(b.id)
				local lines = {}
				if not mine then lines[1] = L["(not in your list)"]
				elseif mine.body == b.body then lines[1] = L["(in your list, unchanged)"]
				else lines[1] = L["(in your list, edited)"] end
				if recIndex[b.id] then lines[#lines + 1] = string.format(L["Recommended for %s"], className) .. "." end
				if not ns.TemplateFitsClass(b) then lines[#lines + 1] = "|cff808080" .. string.format(L["FIT_NO"], className) .. "|r" end
				self.status:SetText(table.concat(lines, "\n"))
			else
				self.pname:SetText(""); self.pdesc:SetText(""); self.pbody:SetText(""); self.status:SetText("")
			end
			local missing = 0
			for _, id in ipairs(rec) do if not ns.FindTemplate(id) then missing = missing + 1 end end
			self.addRec:SetEnabled(missing > 0)
		end

		f:SetScript("OnShow", f.Refresh)
		-- everything shown once is no longer "new"
		f:SetScript("OnHide", function() ns.MarkBuiltinsKnown(); if ns.RefreshSettingsPage then ns.RefreshSettingsPage() end end)
		defaultsPanel = f
		function ns.RefreshDefaultsPanel() if defaultsPanel:IsShown() then defaultsPanel:Refresh() end end
	end
	Anchor(defaultsPanel, parent)
	defaultsPanel:Show()
end

-- ---------------------------------------------------------------------------
-- Export / import all templates as text
-- ---------------------------------------------------------------------------

StaticPopupDialogs["MACROMASTER_IMPORT_TEXT"] = {
	text = "%s",
	button1 = L["Import"], button2 = CANCEL,
	OnAccept = function(self, data)
		local added, replaced = ns.ImportTemplates(data.list, data.mode)
		ns.ReselectTemplate()
		ns.Msg(L["MSG_TEMPLATES_IMPORTED"], added, replaced)
		if ns.RefreshDefaultsPanel then ns.RefreshDefaultsPanel() end
	end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

local exportPanel
-- `template` (optional): open with that one template's share string selected
function ns.ShowExportPanel(parent, template)
	if not exportPanel then
		local f = Popup("MacroMasterExport", 620, 480, L["Export / Import"])
		f.intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -36)
		f.intro:SetWidth(588)
		f.intro:SetJustifyH("LEFT")
		f.intro:SetText(L["EXPORT_INTRO"])

		local box = InsetBox(f)
		box:SetPoint("TOPLEFT", 14, -104)
		box:SetPoint("BOTTOMRIGHT", -14, 44)
		local sf = CreateFrame("ScrollFrame", nil, box, "InputScrollFrameTemplate")
		sf:SetPoint("TOPLEFT", 8, -8)
		sf:SetPoint("BOTTOMRIGHT", -8, 8)
		sf.EditBox:SetMaxLetters(0)
		sf.EditBox:SetWidth(620 - 28 - 16 - 24)
		sf.EditBox:SetFontObject(ChatFontNormal)
		sf.EditBox:SetAutoFocus(false)
		sf.EditBox:SetScript("OnEscapePressed", sf.EditBox.ClearFocus)
		if sf.CharCount then sf.CharCount:Hide() end
		f.edit = sf.EditBox

		f.export = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.export:SetSize(120, 22)
		f.export:SetPoint("BOTTOMLEFT", 14, 14)
		f.export:SetText(L["Export"])
		Fit(f.export)
		f.export:SetScript("OnClick", function()
			f.edit:SetText(ns.EncodeTemplates())
			f.edit:SetFocus()
			f.edit:HighlightText()
		end)

		f.import = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.import:SetSize(120, 22)
		f.import:SetPoint("LEFT", f.export, "RIGHT", 6, 0)
		f.import:SetText(L["Import"])
		Fit(f.import)
		f.import:SetScript("OnClick", function()
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
				text = text .. "\n\n|cffff4040" .. string.format(L["IMPORT_CODE_WARNING"], code) .. "|r"
			end
			StaticPopup_Show("MACROMASTER_IMPORT_TEXT", text, nil, { list = list, mode = mode })
		end)

		-- what happens to a template whose id is already in the list
		f.modeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		f.modeLabel:SetPoint("LEFT", f.import, "RIGHT", 14, 0)
		f.modeLabel:SetText(L["Same id:"])
		f.modes = {}
		local prev = f.modeLabel
		for i, mode in ipairs({ "replace", "add" }) do
			local r = CreateFrame("CheckButton", "MacroMasterImportMode" .. i, f, "UIRadioButtonTemplate")
			r:SetPoint("LEFT", prev, "RIGHT", i == 1 and 6 or 10, 0)
			local text = r.Text or r.text or _G[r:GetName() .. "Text"]
			text:SetText(mode == "replace" and L["Replace"] or L["Add new"])
			r.mode = mode
			r:SetScript("OnClick", function(self)
				ns.db.settings.importMode = self.mode
				f:RefreshMode()
			end)
			r:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:SetText(self.mode == "replace" and L["MODE_REPLACE_HELP"] or L["MODE_ADD_HELP"], 1, 1, 1, 1, true)
				GameTooltip:Show()
			end)
			r:SetScript("OnLeave", GameTooltip_Hide)
			f.modes[i] = r
			prev = text
		end
		function f:RefreshMode()
			for _, r in ipairs(self.modes) do r:SetChecked(r.mode == ns.db.settings.importMode) end
		end
		f:SetScript("OnShow", f.RefreshMode)

		f.clear = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.clear:SetSize(80, 22)
		f.clear:SetPoint("BOTTOMRIGHT", -14, 14)
		f.clear:SetText(L["Clear"])
		Fit(f.clear)
		f.clear:SetScript("OnClick", function() f.edit:SetText("") end)

		exportPanel = f
	end
	Anchor(exportPanel, parent)
	exportPanel:Show()
	if template then
		exportPanel.edit:SetText(ns.EncodeTemplates({ template }))
		exportPanel.edit:SetFocus()
		exportPanel.edit:HighlightText()
	end
end

-- ---------------------------------------------------------------------------
-- Spell table editor (current class)
-- ---------------------------------------------------------------------------

local tablePanel
function ns.ShowSpellTablePanel(parent)
	if not tablePanel then
		local f = Popup("MacroMasterSpellTable", 620, 480, "")
		f.category = ns.categories[1]

		f.intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		f.intro:SetPoint("TOPLEFT", 16, -36)
		f.intro:SetWidth(588)
		f.intro:SetJustifyH("LEFT")
		f.intro:SetText(L["TABLE_INTRO"])

		-- category tabs
		f.tabs = {}
		local prev
		local PER_ROW = 6
		for i, cat in ipairs(ns.categories) do
			local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
			b:SetSize(96, 22)
			b:SetText(L["CAT_" .. cat])
			b.category = cat
			local row, col = math.floor((i - 1) / PER_ROW), (i - 1) % PER_ROW
			b:SetPoint("TOPLEFT", 14 + col * 100, -100 - row * 26)
			b:SetScript("OnClick", function(self) f.category = self.category; f:Refresh() end)
			f.tabs[i] = b
			prev = b
		end

		f.status = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		f.status:SetPoint("TOPLEFT", 16, -156)

		local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
		box:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		box:SetBackdropColor(0, 0, 0, 0.6)
		box:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		box:SetPoint("TOPLEFT", 14, -170)
		box:SetPoint("BOTTOMRIGHT", -14, 44)

		f.scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
		f.scroll:SetPoint("TOPLEFT", 6, -6)
		f.scroll:SetPoint("BOTTOMRIGHT", -26, 6)
		f.content = CreateFrame("Frame", nil, f.scroll)
		f.content:SetSize(550, 10)
		f.scroll:SetScrollChild(f.content)
		f.rows = {}

		f.add = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.add:SetSize(90, 22)
		f.add:SetPoint("BOTTOMLEFT", 14, 14)
		f.add:SetText(L["Add"])
		Fit(f.add)
		f.add:SetScript("OnClick", function()
			ns.ShowSpellPicker(f, function(name, spellID)
				if spellID then
					ns.AddSuggestion(f.category, spellID)
					f:Refresh()
				end
			end)
		end)

		f.reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		f.reset:SetSize(110, 22)
		f.reset:SetPoint("LEFT", f.add, "RIGHT", 6, 0)
		f.reset:SetText(L["Reset to shipped"])
		Fit(f.reset)
		f.reset:SetScript("OnClick", function()
			ns.ResetSuggestions(f.category)
			f:Refresh()
		end)

		function f:Refresh()
			local className = UnitClass("player")
			self.title:SetText(string.format(L["Spell table for %s"], className))
			for _, b in ipairs(self.tabs) do
				b:SetEnabled(b.category ~= self.category)
			end
			self.status:SetText(ns.IsSuggestionCustomized(self.category) and L["(custom)"] or "")

			ns.ScanSpellBook()
			local list = ns.ResolveSuggestions(self.category, false)
			for i, s in ipairs(list) do
				local r = self.rows[i]
				if not r then
					r = CreateFrame("Frame", nil, self.content)
					r:SetSize(540, 24)
					r.icon = r:CreateTexture(nil, "ARTWORK")
					r.icon:SetSize(20, 20)
					r.icon:SetPoint("LEFT", 2, 0)
					r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
					r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
					r.name:SetWidth(420)
					r.name:SetJustifyH("LEFT")
					r.remove = CreateFrame("Button", nil, r, "UIPanelCloseButton")
					r.remove:SetSize(22, 22)
					r.remove:SetPoint("RIGHT", -2, 0)
					r.remove:SetScript("OnClick", function(self)
						ns.RemoveSuggestion(f.category, self:GetParent().spellID)
						f:Refresh()
					end)
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
				r.name:SetText(s.known and s.name or ("|cff808080" .. s.name .. " " .. L["(not known by this character)"] .. "|r"))
				r:ClearAllPoints()
				r:SetPoint("TOPLEFT", 0, -(i - 1) * 24)
				r:Show()
			end
			for i = #list + 1, #self.rows do self.rows[i]:Hide() end
			self.content:SetHeight(math.max(10, #list * 24))
		end

		f:SetScript("OnShow", f.Refresh)
		tablePanel = f
	end
	Anchor(tablePanel, parent)
	tablePanel:Show()
end

-- ---------------------------------------------------------------------------
-- Settings page (second tab of the main window): language, and the doors to
-- the defaults catalogue and export/import. `main` anchors those panels.
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
	local lang = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lang:SetPoint("TOPLEFT", x, y)
	lang:SetText(L["Language"])
	local note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	note:SetPoint("LEFT", lang, "RIGHT", 8, 0)
	note:SetText(L["LANG_NOTE"])

	f.radios = {}
	for i, entry in ipairs(LANGUAGES) do
		local r = CreateFrame("CheckButton", "MacroMasterLang" .. i, f, "UIRadioButtonTemplate")
		r:SetPoint("TOPLEFT", x + 4, y - 22 - (i - 1) * 22)
		local text = r.Text or r.text or _G[r:GetName() .. "Text"]
		text:SetText(entry.code and entry.label or L["Auto (client language)"])
		r.code = entry.code
		r:SetScript("OnClick", function(self)
			local before = ns.db.settings.locale
			ns.db.settings.locale = self.code
			f:Refresh()
			if before ~= self.code then StaticPopup_Show("MACROMASTER_RELOAD") end
		end)
		f.radios[i] = r
	end

	local lib = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lib:SetPoint("TOPLEFT", x, y - 110)
	lib:SetText(L["Templates"])
	f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.hint:SetPoint("TOPLEFT", x + 4, y - 132)
	f.hint:SetWidth(520)
	f.hint:SetJustifyH("LEFT")
	f.hint:SetText(L["SETTINGS_TEMPLATES_HINT"])

	f.defaults = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.defaults:SetSize(160, 22)
	f.defaults:SetPoint("TOPLEFT", f.hint, "BOTTOMLEFT", 0, -10)
	f.defaults:SetText(L["Default templates"])
	Fit(f.defaults)
	f.defaults:SetScript("OnClick", function() ns.ShowDefaultsPanel(main) end)

	f.export = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.export:SetSize(160, 22)
	f.export:SetPoint("LEFT", f.defaults, "RIGHT", 8, 0)
	f.export:SetText(L["Export / Import"])
	Fit(f.export)
	f.export:SetScript("OnClick", function() ns.ShowExportPanel(main) end)

	function f:Refresh()
		for _, r in ipairs(self.radios) do r:SetChecked(r.code == ns.db.settings.locale) end
		local n = ns.NewBuiltinCount()
		f.defaults:SetText(n > 0 and string.format(L["Default templates (%d new)"], n) or L["Default templates"])
		Fit(f.defaults)
	end
	f:SetScript("OnShow", f.Refresh)
	ns.RefreshSettingsPage = function() if f:IsShown() then f:Refresh() end end
end
