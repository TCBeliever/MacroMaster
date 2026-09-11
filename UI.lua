local ADDON, ns = ...
local L = ns.L

local PREFIX = "|cff66ccffMacro|rMaster: "
local function Msg(fmt, ...) print(PREFIX .. string.format(fmt, ...)) end
ns.Msg = Msg

local MACRO_NAME_MAX = 16
local MACRO_BODY_MAX = 255
-- 12.1 moved these to Constants.MacroConsts (character macros are 30 now)
local MC = Constants and Constants.MacroConsts
local MAX_ACCOUNT_MACROS   = (MC and MC.MAX_ACCOUNT_MACROS)   or _G.MAX_ACCOUNT_MACROS   or 120
local MAX_CHARACTER_MACROS = (MC and MC.MAX_CHARACTER_MACROS) or _G.MAX_CHARACTER_MACROS or 30
local QUESTION_ICON = 134400   -- INV_MISC_QUESTIONMARK
local MAX_ROWS       = 6
local W, H           = 780, 670
local LEFT_W         = 220

-- UTF-8 aware helpers (macro names are counted in characters, and a byte
-- cut in the middle of a CJK character produces garbage)
local function Utf8Len(s) return strlenutf8 and strlenutf8(s) or #s end
local function Utf8Sub(s, n)
	local out, count, i = {}, 0, 1
	while i <= #s and count < n do
		local c = s:byte(i)
		local len = (c >= 240 and 4) or (c >= 224 and 3) or (c >= 192 and 2) or 1
		out[#out + 1] = s:sub(i, i + len - 1)
		i = i + len
		count = count + 1
	end
	return table.concat(out)
end

local main
local state = {
	templateID  = nil,
	values      = {},       -- placeholder -> text (persisted per character)
	nameTouched = false,
}

-- ---------------------------------------------------------------------------
-- Small widget helpers
-- ---------------------------------------------------------------------------

local function Label(parent, text, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	fs:SetText(text)
	return fs
end

local function Button(parent, text, w, h, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w, h or 22)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

local function EditBox(parent, w, maxLetters)
	local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	e:SetSize(w, 22)
	e:SetAutoFocus(false)
	if maxLetters then e:SetMaxLetters(maxLetters) end
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	return e
end

local function Box(parent)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	f:SetBackdropColor(0, 0, 0, 0.6)
	f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	return f
end

local function MultiLine(parent, w, h, maxLetters)
	local sf = CreateFrame("ScrollFrame", nil, parent, "InputScrollFrameTemplate")
	sf:SetSize(w, h)
	sf.EditBox:SetMaxLetters(maxLetters or 0)
	sf.EditBox:SetWidth(w - 18)
	sf.EditBox:SetFontObject(ChatFontNormal)
	sf.EditBox:SetAutoFocus(false)
	sf.EditBox:SetScript("OnEscapePressed", sf.EditBox.ClearFocus)
	if sf.CharCount then sf.CharCount:Hide() end
	return sf
end

-- ---------------------------------------------------------------------------
-- Character-scoped remembered values (your kick stays filled across templates)
-- ---------------------------------------------------------------------------

local function CharKey() return UnitName("player") .. " - " .. GetRealmName() end

local function LoadValues()
	ns.db.charValues = ns.db.charValues or {}
	ns.db.charValues[CharKey()] = ns.db.charValues[CharKey()] or {}
	state.values = ns.db.charValues[CharKey()]
end

-- ---------------------------------------------------------------------------
-- Template list (left pane)
-- ---------------------------------------------------------------------------

-- Array order is creation order (built-ins first, then whatever you added).
local function SortedTemplates()
	local out = {}
	for i, t in ipairs(ns.GetTemplates()) do out[i] = t end
	if ns.db.settings.sort == "name" then
		table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
	end
	return out
end

local function RefreshList()
	local list = main.list
	local templates = SortedTemplates()
	if main.sortBtn then
		main.sortBtn:SetText(ns.db.settings.sort == "name" and L["Sort: name"] or L["Sort: created"])
	end
	for i, t in ipairs(templates) do
		local b = list.buttons[i]
		if not b then
			b = CreateFrame("Button", nil, list.content)
			b:SetSize(LEFT_W - 30, 22)
			b:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
			b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			b.text:SetPoint("LEFT", 6, 0)
			b.text:SetPoint("RIGHT", -4, 0)
			b.text:SetJustifyH("LEFT")
			b.text:SetWordWrap(false)
			b.sel = b:CreateTexture(nil, "BACKGROUND")
			b.sel:SetAllPoints()
			b.sel:SetColorTexture(0.3, 0.55, 0.9, 0.35)
			b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			b:SetScript("OnClick", function(self) ns.SelectTemplate(self.templateID) end)
			b:SetScript("OnEnter", function(self)
				local t = ns.FindTemplate(self.templateID)
				if t and t.desc and t.desc ~= "" then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(t.name, 1, 1, 1)
					GameTooltip:AddLine(t.desc, nil, nil, nil, true)
					GameTooltip:Show()
				end
			end)
			b:SetScript("OnLeave", GameTooltip_Hide)
			list.buttons[i] = b
		end
		b.templateID = t.id
		b.text:SetText(t.name)
		b.sel:SetShown(t.id == state.templateID)
		b:Show()
	end
	for i = #templates + 1, #list.buttons do list.buttons[i]:Hide() end
	list.content:SetHeight(math.max(10, #templates * 22))
end

-- ---------------------------------------------------------------------------
-- Placeholder rows + preview
-- ---------------------------------------------------------------------------

local function CurrentTemplate() return state.templateID and ns.FindTemplate(state.templateID) end

local function CurrentBody()
	-- the editor is the source of truth while editing
	return main.body.EditBox:GetText()
end

local function ReceiveCursorSpell(editbox)
	local kind, _, _, spellID = GetCursorInfo()
	if kind == "spell" and spellID then
		local name = C_Spell.GetSpellName(spellID)
		if name then
			editbox:SetText(name)
			editbox:ClearFocus()
			ClearCursor()
			return true
		end
	end
end

local ALL = "*"   -- sentinel value: "one macro per option"

-- ---------------------------------------------------------------------------
-- Small dropdown list for placeholders with fixed options
-- ---------------------------------------------------------------------------

local optionList
local function ShowOptionList(anchor, items, onPick)
	if not optionList then
		local f = CreateFrame("Frame", "MacroMasterOptionList", UIParent, "BackdropTemplate")
		f:SetFrameStrata("TOOLTIP")
		f:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		f:SetBackdropColor(0.05, 0.05, 0.07, 0.98)
		f:EnableMouse(true)
		f.buttons = {}
		-- click anywhere else closes it
		f:SetScript("OnUpdate", function(self)
			if IsMouseButtonDown("LeftButton") and not self:IsMouseOver() and not self.anchor:IsMouseOver() then
				self:Hide()
			end
		end)
		optionList = f
	end
	local f = optionList
	f.anchor = anchor
	local w = 0
	for i, item in ipairs(items) do
		local b = f.buttons[i]
		if not b then
			b = CreateFrame("Button", nil, f)
			b:SetHeight(20)
			b.icon = b:CreateTexture(nil, "ARTWORK")
			b.icon:SetSize(16, 16)
			b.icon:SetPoint("LEFT", 6, 0)
			b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			b:SetScript("OnClick", function(self)
				f:Hide()
				f.onPick(self.value)
			end)
			f.buttons[i] = b
		end
		b.value, b.label = item.value, item.label
		b.text:SetText(item.label)
		b.text:ClearAllPoints()
		if item.icon then
			b.icon:SetTexture(item.icon)
			b.icon:Show()
			b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
		else
			b.icon:Hide()
			b.text:SetPoint("LEFT", 8, 0)
		end
		w = math.max(w, b.text:GetStringWidth() + 16 + (item.icon and 22 or 0))
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 20)
		b:Show()
	end
	for i = #items + 1, #f.buttons do f.buttons[i]:Hide() end
	for i = 1, #items do f.buttons[i]:SetWidth(w) end
	f.onPick = onPick
	f:SetSize(w + 8, #items * 20 + 8)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	f:Show()
end

local function HideOptionList() if optionList then optionList:Hide() end end

-- Meta of the current template (labels/options per placeholder)
local function CurrentMeta()
	local t = CurrentTemplate()
	return t and t.meta or {}
end

-- Returns a list of { suffix=, values= } — one entry normally, one per option
-- when a "multi" placeholder is set to ALL.
local function ExpandVariants()
	local meta = CurrentMeta()
	for _, key in ipairs(ns.GetPlaceholders(CurrentBody())) do
		local m = meta[key]
		if m and m.multi and m.options and state.values[key] == ALL then
			local list = {}
			for i, opt in ipairs(m.options) do
				local v = {}
				for k, val in pairs(state.values) do v[k] = val end
				v[key] = opt
				list[#list + 1] = { suffix = (m.suffixes and m.suffixes[i]) or opt, values = v }
			end
			return list
		end
	end
	return { { suffix = "", values = state.values } }
end

local function MacroNameFor(base, suffix)
	if suffix == "" then return base end
	return Utf8Sub(base, MACRO_NAME_MAX - Utf8Len(suffix)) .. suffix
end

local function UpdateMacroNameDefault()
	if state.nameTouched then return end
	local body = CurrentBody()
	local keys = ns.GetPlaceholders(body)
	local t = CurrentTemplate()
	local meta = CurrentMeta()
	local candidate
	for _, k in ipairs(keys) do
		local v = state.values[k]
		-- only spell-type placeholders make a sensible macro name
		local m = meta[k]
		local skip = m and (m.options or m.text)
		if v and v ~= "" and not skip then candidate = v; break end
	end
	candidate = candidate or (t and t.name) or ""
	candidate = strtrim(Utf8Sub(candidate, MACRO_NAME_MAX))
	main.macroName:SetText(candidate)
end

local function UpdatePreview()
	local variants = ExpandVariants()
	local base = strtrim(main.macroName:GetText())
	local parts, longest, missingAll = {}, 0, {}
	for _, v in ipairs(variants) do
		local body, missing = ns.Substitute(CurrentBody(), v.values, CurrentMeta())
		v.body, v.missing = body, missing
		for _, k in ipairs(missing) do missingAll[#missingAll + 1] = k end
		longest = math.max(longest, #body)
		if #variants > 1 then
			parts[#parts + 1] = "|cffffd100" .. MacroNameFor(base, v.suffix) .. "|r\n" .. body
		else
			parts[#parts + 1] = body
		end
	end
	main.preview.text:SetText(table.concat(parts, "\n\n"))
	local color = longest > MACRO_BODY_MAX and "|cffff4040" or "|cff40ff40"
	local extra = #variants > 1 and ("  |cff66ccff×" .. #variants .. "|r") or ""
	main.preview.count:SetText(string.format("%s%d|r / %d%s", color, longest, MACRO_BODY_MAX, extra))
	main.preview.variants = variants
	main.preview.missing = missingAll
	main.preview.longest = longest
	-- the cursor can only hold one macro
	if main.pickup then
		local single = #variants == 1
		main.pickup:SetEnabled(single)
		main.pickup:SetChecked(single and ns.db.settings.pickup)
		local t = main.pickup.Text or main.pickup.text
		if t then t:SetTextColor(single and 1 or 0.5, single and 0.82 or 0.5, single and 0 or 0.5) end
	end
	UpdateMacroNameDefault()
end

local function RefreshRows()
	local body = CurrentBody()
	local keys = ns.GetPlaceholders(body)
	local t = CurrentTemplate()
	local meta = t and t.meta or {}
	local rows = main.rows

	for i, key in ipairs(keys) do
		if i > MAX_ROWS then break end
		local r = rows[i]
		if not r then
			r = CreateFrame("Frame", nil, main.fill)
			r:SetSize(main.fill:GetWidth(), 26)
			r:SetPoint("TOPLEFT", 0, -(i - 1) * 27)
			r.label = Label(r, "", "GameFontNormalSmall")
			r.label:SetPoint("LEFT", 4, 0)
			r.label:SetWidth(150)
			r.label:SetJustifyH("LEFT")
			r.label:SetWordWrap(false)
			r.edit = EditBox(r, 190, 80)
			r.edit:SetPoint("LEFT", r.label, "RIGHT", 10, 0)
			r.edit:SetScript("OnTextChanged", function(self, userInput)
				if userInput then
					state.values[self.key] = strtrim(self:GetText())
					UpdatePreview()
				end
			end)
			r.edit:SetScript("OnReceiveDrag", function(self)
				if ReceiveCursorSpell(self) then
					state.values[self.key] = self:GetText()
					UpdatePreview()
				end
			end)
			r.edit:SetScript("OnMouseUp", function(self)
				if ReceiveCursorSpell(self) then
					state.values[self.key] = self:GetText()
					UpdatePreview()
				end
			end)
			r.edit:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:SetText(self.hint or L["Drag a spell here or click Pick"], 1, 1, 1, 1, true)
				GameTooltip:Show()
			end)
			r.edit:SetScript("OnLeave", GameTooltip_Hide)
			r.pick = Button(r, L["Pick"], 60, 22, function(self)
				local row = self:GetParent()
				local category = ns.CategoryForKey(row.edit.key, CurrentMeta()[row.edit.key])
				ns.ShowSpellPicker(main, function(name)
					row.edit:SetText(name)
					state.values[row.edit.key] = name
					UpdatePreview()
				end, category)
			end)
			r.pick:SetPoint("LEFT", r.edit, "RIGHT", 6, 0)
			r.list = Button(r, L["Options"] .. " |cffaaaaaa▼|r", 80, 22, function(self)
				local row = self:GetParent()
				local m = CurrentMeta()[row.edit.key]
				if not m or not m.options then return end
				local items = {}
				for i, opt in ipairs(m.options) do
					items[#items + 1] = {
						value = opt,
						label = (m.labels and m.labels[i]) or opt,
						icon  = m.icons and m.icons[i],
					}
				end
				if m.multi then
					items[#items + 1] = { value = ALL, label = string.format(L["All (%s)"], table.concat(m.options, "/")) }
				end
				ShowOptionList(self, items, function(value)
					row.edit:SetText(value)
					state.values[row.edit.key] = value
					RefreshRows()
				end)
			end)
			r.list:SetPoint("LEFT", r.edit, "RIGHT", 6, 0)
			-- icon of the currently selected option (raid markers etc.)
			r.optIcon = r:CreateTexture(nil, "ARTWORK")
			r.optIcon:SetSize(18, 18)
			r.optIcon:SetPoint("LEFT", r.list, "RIGHT", 6, 0)
			r.optIcon:Hide()
			rows[i] = r
		end
		local m = meta[key]
		r.label:SetText(((m and m.label) or key) .. ((m and m.optional) and (" |cff808080" .. L["(optional)"] .. "|r") or ""))
		r.edit.key = key
		r.edit.hint = m and m.hint
		-- "one macro per option" placeholders default to All
		-- defaults apply only to a never-set value; clearing a box keeps it empty
		if state.values[key] == nil then
			if m and m.multi then state.values[key] = ALL
			elseif m and m.default then state.values[key] = m.default end
		end
		r.edit:SetText(state.values[key] or "")
		-- placeholders with fixed options get a dropdown instead of the spell picker
		local options = m and m.options
		r.pick:SetShown(not options and not (m and m.text))
		r.list:SetShown(options and true or false)
		r.optIcon:Hide()
		if options and m.icons then
			for i, opt in ipairs(options) do
				if state.values[key] == opt and m.icons[i] then
					r.optIcon:SetTexture(m.icons[i])
					r.optIcon:Show()
				end
			end
		end
		r:Show()
	end
	for i = #keys + 1, #rows do rows[i]:Hide() end
	main.fill.empty:SetShown(#keys == 0)
	main.fill.overflow:SetShown(#keys > MAX_ROWS)
	-- shrink the section to the rows in use; the preview box takes the rest
	local shown = math.max(1, math.min(#keys, MAX_ROWS))
	main.fill:SetHeight(shown * 27 + (#keys > MAX_ROWS and 14 or 0))
	UpdatePreview()
end

-- ---------------------------------------------------------------------------
-- Template selection / editing
-- ---------------------------------------------------------------------------

function ns.SelectTemplate(id)
	local t = ns.FindTemplate(id)
	state.templateID = t and id or nil
	state.nameTouched = false
	main.tname:SetText(t and t.name or "")
	main.tdesc:SetText(t and t.desc or "")
	main.body.EditBox:SetText(t and t.body or "")
	main.body.EditBox:SetCursorPosition(0)
	main.saveHint:SetText("")
	RefreshList()
	RefreshRows()
end

local function SaveTemplate()
	local t = CurrentTemplate()
	if not t then return end
	t.name = strtrim(main.tname:GetText())
	if t.name == "" then t.name = L["Untitled"]; main.tname:SetText(t.name) end
	t.desc = strtrim(main.tdesc:GetText())
	t.body = main.body.EditBox:GetText()
	main.saveHint:SetText("|cff40ff40" .. L["Saved."] .. "|r")
	RefreshList()
end

local function NewTemplate()
	local t = ns.AddTemplate(L["New template"], "", "#showtooltip\n/cast {SPELL}")
	ns.SelectTemplate(t.id)
	main.tname:SetFocus()
	main.tname:HighlightText()
end

StaticPopupDialogs["MACROMASTER_DELETE_TEMPLATE"] = {
	text = L["Delete template '%s'?"],
	button1 = L["Delete"], button2 = CANCEL,
	OnAccept = function(self, id)
		ns.DeleteTemplate(id)
		local first = ns.GetTemplates()[1]
		ns.SelectTemplate(first and first.id)
	end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

-- ---------------------------------------------------------------------------
-- Import an existing macro as a template
-- ---------------------------------------------------------------------------

function ns.ImportMacroAsTemplate(index)
	local name, _, body = GetMacroInfo(index)
	if not name or not body then Msg(L["MSG_NO_MACRO"]); return end
	local tbody, order = ns.MakeTemplateFromMacro(body)
	local t = ns.AddTemplate(name, "", tbody)
	ns.ShowMain()   -- creates the window and loads this character's values first
	for _, e in ipairs(order) do state.values[e.key] = e.name end
	ns.SelectTemplate(t.id)
	Msg(L["MSG_IMPORTED"], name, #order)
end

local macroPicker
local function ShowMacroPicker()
	if not macroPicker then
		local f = CreateFrame("Frame", "MacroMasterMacroPicker", UIParent, "BackdropTemplate")
		f:SetSize(300, 420)
		f:SetFrameStrata("DIALOG")
		f:SetToplevel(true)
		f:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 24,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
		f:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
		f:EnableMouse(true)
		f.title = Label(f, L["Choose a macro to import as a template:"], "GameFontNormalSmall")
		f.title:SetPoint("TOP", 0, -14)
		f.title:SetWidth(260)
		f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		f.close:SetPoint("TOPRIGHT", -4, -4)
		f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
		f.scroll:SetPoint("TOPLEFT", 16, -44)
		f.scroll:SetPoint("BOTTOMRIGHT", -34, 16)
		f.content = CreateFrame("Frame", nil, f.scroll)
		f.content:SetSize(240, 10)
		f.scroll:SetScrollChild(f.content)
		f.buttons = {}
		function f:Refresh()
			local numAccount, numChar = GetNumMacros()
			local n = 0
			local function add(index)
				local name, icon = GetMacroInfo(index)
				if not name then return end
				n = n + 1
				local b = self.buttons[n]
				if not b then
					b = CreateFrame("Button", nil, self.content)
					b:SetSize(240, 22)
					b.icon = b:CreateTexture(nil, "ARTWORK")
					b.icon:SetSize(18, 18)
					b.icon:SetPoint("LEFT", 2, 0)
					b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
					b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
					b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
					b:SetScript("OnClick", function(self)
						f:Hide()
						ns.ImportMacroAsTemplate(self.index)
					end)
					self.buttons[n] = b
				end
				b.index = index
				b.icon:SetTexture(icon)
				b.text:SetText((index > MAX_ACCOUNT_MACROS and "|cffffd100[C]|r " or "") .. name)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", 0, -(n - 1) * 22)
				b:Show()
			end
			for i = 1, numAccount do add(i) end
			for i = MAX_ACCOUNT_MACROS + 1, MAX_ACCOUNT_MACROS + numChar do add(i) end
			for i = n + 1, #self.buttons do self.buttons[i]:Hide() end
			self.content:SetHeight(math.max(10, n * 22))
		end
		f:SetScript("OnShow", f.Refresh)
		tinsert(UISpecialFrames, f:GetName())
		macroPicker = f
	end
	macroPicker:ClearAllPoints()
	macroPicker:SetPoint("TOPLEFT", main, "TOPRIGHT", 8, 0)
	macroPicker:Show()
end

-- ---------------------------------------------------------------------------
-- Create the macro
-- ---------------------------------------------------------------------------

local function WriteMacro(name, body, perChar, overwriteIndex, noPickup)
	local index
	if overwriteIndex then
		EditMacro(overwriteIndex, name, nil, body)
		index = overwriteIndex
		Msg(L["MSG_UPDATED"], name)
	else
		index = CreateMacro(name, QUESTION_ICON, body, perChar)
		Msg(L["MSG_CREATED"], name)
	end
	if index and ns.db.settings.pickup and not noPickup then
		PickupMacro(index)
	end
	main.scope:Refresh()
end

local function OpenMacroFrame()
	if ShowMacroFrame then ShowMacroFrame() else
		C_AddOns.LoadAddOn("Blizzard_MacroUI")
		if MacroFrame then ShowUIPanel(MacroFrame) end
	end
end

-- jobs = { {name=, body=, index=|nil}, ... }
local function WriteJobs(jobs, perChar)
	local single = #jobs == 1
	local pickup = single and ns.db.settings.pickup
	for _, j in ipairs(jobs) do
		WriteMacro(j.name, j.body, perChar, j.index, not pickup)
	end
	if not single then Msg(L["MSG_BATCH_DONE"], #jobs) end
	-- nothing on the cursor -> let the user drag from the macro window
	if not pickup then OpenMacroFrame() end
end

StaticPopupDialogs["MACROMASTER_OVERWRITE"] = {
	text = "%s",
	button1 = L["Overwrite"], button2 = CANCEL,
	OnAccept = function(self, data)
		if InCombatLockdown() then Msg(L["MSG_COMBAT"]); return end
		WriteJobs(data.jobs, data.perChar)
	end,
	timeout = 0, whileDead = true, hideOnEscape = true,
}

local function CreateMacroFromState()
	if InCombatLockdown() then Msg(L["MSG_COMBAT"]); return end

	local name = strtrim(main.macroName:GetText())
	if name == "" then Msg(L["MSG_NAME_EMPTY"]); return end
	if Utf8Len(name) > MACRO_NAME_MAX then Msg(L["MSG_NAME_LONG"]); return end

	UpdatePreview()
	local variants, missing = main.preview.variants, main.preview.missing
	if #missing > 0 then Msg(L["MSG_UNFILLED"], missing[1]); return end
	if main.preview.longest > MACRO_BODY_MAX then Msg(L["MSG_TOO_LONG"], main.preview.longest); return end

	-- soft warning only: the macro is still created (items, pet spells, etc.)
	ns.ScanSpellBook()
	local meta = CurrentMeta()
	for _, key in ipairs(ns.GetPlaceholders(CurrentBody())) do
		local v = state.values[key]
		local isSpell = not (meta[key] and meta[key].options)
		if isSpell and v and not ns.IsSpellKnownByName(v) then Msg(L["MSG_UNKNOWN_SPELL"], v) end
	end

	local perChar = ns.db.settings.scope == "character"
	local jobs, overwrite = {}, {}
	for _, v in ipairs(variants) do
		local n = MacroNameFor(name, v.suffix)
		local existing = GetMacroIndexByName(n)
		local job = { name = n, body = v.body, index = (existing and existing > 0) and existing or nil }
		jobs[#jobs + 1] = job
		if job.index then overwrite[#overwrite + 1] = n end
	end

	local numAccount, numChar = GetNumMacros()
	local free = perChar and (MAX_CHARACTER_MACROS - numChar) or (MAX_ACCOUNT_MACROS - numAccount)
	local needed = #jobs - #overwrite
	if needed > free then
		if #jobs == 1 then Msg(L["MSG_FULL"]) else Msg(L["MSG_BATCH_FULL"], needed, free) end
		return
	end

	if #overwrite > 0 then
		local text = (#jobs == 1)
			and string.format(L["Overwrite macro '%s'?"], overwrite[1])
			or string.format(L["Overwrite %d existing macros (%s)?"], #overwrite, table.concat(overwrite, ", "))
		StaticPopup_Show("MACROMASTER_OVERWRITE", text, nil, { jobs = jobs, perChar = perChar })
		return
	end
	WriteJobs(jobs, perChar)
end

-- ---------------------------------------------------------------------------
-- Main window
-- ---------------------------------------------------------------------------

local function CreateMain()
	local f = CreateFrame("Frame", "MacroMasterFrame", UIParent, "BackdropTemplate")
	f:SetSize(W, H)
	f:SetPoint("CENTER")
	f:SetFrameStrata("HIGH")
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

	f:SetBackdropColor(0.05, 0.05, 0.07, 0.96)   -- opaque: the game UI must not bleed through

	local version = C_AddOns.GetAddOnMetadata(ADDON, "Version") or ""
	f.title = Label(f, "|cff66ccffMacro|rMaster |cff808080v" .. version .. "|r", "GameFontNormalLarge")
	f.title:SetPoint("TOP", 0, -14)
	f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.close:SetPoint("TOPRIGHT", -6, -6)

	-- ===== left: template list ==========================================
	local lh = Label(f, L["Templates"])
	lh:SetPoint("TOPLEFT", 20, -44)
	f.sortBtn = Button(f, "", 96, 18, function()
		ns.db.settings.sort = (ns.db.settings.sort == "name") and "created" or "name"
		RefreshList()
	end)
	f.sortBtn:SetPoint("TOPRIGHT", f, "TOPLEFT", 16 + LEFT_W, -42)
	f.sortBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Click to switch between name order and creation order."], 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	f.sortBtn:SetScript("OnLeave", GameTooltip_Hide)

	local listBox = Box(f)
	listBox:SetPoint("TOPLEFT", 16, -62)
	listBox:SetSize(LEFT_W, H - 62 - 126)

	f.list = CreateFrame("ScrollFrame", nil, listBox, "UIPanelScrollFrameTemplate")
	f.list:SetPoint("TOPLEFT", 6, -6)
	f.list:SetPoint("BOTTOMRIGHT", -26, 6)
	f.list.content = CreateFrame("Frame", nil, f.list)
	f.list.content:SetSize(LEFT_W - 30, 10)
	f.list:SetScrollChild(f.list.content)
	f.list.buttons = {}

	local bNew = Button(f, L["New"], 68, 22, NewTemplate)
	bNew:SetPoint("TOPLEFT", listBox, "BOTTOMLEFT", 0, -6)
	local bImp = Button(f, L["Import"], 68, 22, ShowMacroPicker)
	bImp:SetPoint("LEFT", bNew, "RIGHT", 4, 0)
	bImp:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Import from macro"])
		GameTooltip:Show()
	end)
	bImp:SetScript("OnLeave", GameTooltip_Hide)
	local bDel = Button(f, L["Delete"], 68, 22, function()
		local t = CurrentTemplate()
		if t then StaticPopup_Show("MACROMASTER_DELETE_TEMPLATE", t.name, nil, t.id) end
	end)
	bDel:SetPoint("LEFT", bImp, "RIGHT", 4, 0)
	local bRestore = Button(f, L["Restore built-ins"], LEFT_W, 22, function()
		ns.RestoreBuiltins()
		RefreshList()
	end)
	bRestore:SetPoint("TOPLEFT", bNew, "BOTTOMLEFT", 0, -4)
	local bVars = Button(f, L["Variables"], (LEFT_W - 4) / 2, 22, function() ns.ShowVariablesPanel(f) end)
	bVars:SetPoint("TOPLEFT", bRestore, "BOTTOMLEFT", 0, -4)
	local bTable = Button(f, L["Spell table"], (LEFT_W - 4) / 2, 22, function() ns.ShowSpellTablePanel(f) end)
	bTable:SetPoint("LEFT", bVars, "RIGHT", 4, 0)

	-- ===== right: template editor =======================================
	local rx = 16 + LEFT_W + 14
	local rw = W - rx - 20

	local nl = Label(f, L["Template name"], "GameFontNormalSmall")
	nl:SetPoint("TOPLEFT", rx, -46)
	f.tname = EditBox(f, 200, 40)
	f.tname:SetPoint("TOPLEFT", rx + 6, -60)

	-- description: three lines, full width
	local dl = Label(f, L["Description"], "GameFontNormalSmall")
	dl:SetPoint("TOPLEFT", rx, -90)
	f.tdescBox = MultiLine(f, rw, 46, 300)
	f.tdescBox:SetPoint("TOPLEFT", rx, -108)
	f.tdesc = f.tdescBox.EditBox
	f.tdesc:HookScript("OnTextChanged", function(_, userInput) if userInput then f.saveHint:SetText("") end end)

	local bl = Label(f, L["Template body"], "GameFontNormalSmall")
	bl:SetPoint("TOPLEFT", rx, -168)
	f.body = MultiLine(f, rw, 96, 600)
	f.body:SetPoint("TOPLEFT", rx, -192)
	f.body.EditBox:HookScript("OnTextChanged", function(self, userInput)
		if userInput then
			f.saveHint:SetText("")
			RefreshRows()
		end
	end)

	local hint = Label(f, L["Placeholders use {NAME}. Edit the text freely; placeholder rows update as you type."], "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", rx, -298)
	hint:SetWidth(rw)
	hint:SetJustifyH("LEFT")
	hint:SetMaxLines(1)
	-- "Update template" lives on the label row above the editor so the hint
	-- below keeps the full width
	local bSave = Button(f, L["Save template"], 100, 22, SaveTemplate)
	bSave:SetPoint("BOTTOMRIGHT", f.body, "TOPRIGHT", 0, 8)
	f.saveHint = Label(f, "", "GameFontNormalSmall")
	f.saveHint:SetPoint("RIGHT", bSave, "LEFT", -6, 0)

	-- ===== fill placeholders ============================================
	local fl = Label(f, L["Fill placeholders"])
	fl:SetPoint("TOPLEFT", rx, -322)
	f.fill = CreateFrame("Frame", nil, f)
	f.fill:SetPoint("TOPLEFT", rx, -340)
	f.fill:SetSize(rw, 27)
	f.fill.empty = Label(f.fill, L["No placeholders in this template."], "GameFontDisableSmall")
	f.fill.empty:SetPoint("TOPLEFT", 4, -4)
	f.fill.overflow = Label(f.fill, string.format(L["Only the first %d placeholders are shown."], MAX_ROWS), "GameFontDisableSmall")
	f.fill.overflow:SetPoint("BOTTOMLEFT", 4, -2)
	f.rows = {}

	-- ===== preview ======================================================
	local pl = Label(f, L["Preview"])
	pl:SetPoint("TOPLEFT", f.fill, "BOTTOMLEFT", 0, -8)
	f.preview = Box(f)
	f.preview:SetPoint("TOPLEFT", pl, "BOTTOMLEFT", 0, -4)
	f.preview:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 96)
	f.preview.text = Label(f.preview, "", "ChatFontNormal")
	f.preview.text:SetPoint("TOPLEFT", 8, -6)
	f.preview.text:SetPoint("BOTTOMRIGHT", -8, 6)
	f.preview.text:SetJustifyH("LEFT")
	f.preview.text:SetJustifyV("TOP")
	f.preview.count = Label(f, "", "GameFontNormalSmall")
	f.preview.count:SetPoint("BOTTOMRIGHT", f.preview, "TOPRIGHT", -2, 2)

	-- ===== create =======================================================
	local cl = Label(f, L["Macro name"], "GameFontNormalSmall")
	cl:SetPoint("TOPLEFT", rx, -(H - 80))
	f.macroName = EditBox(f, 150, MACRO_NAME_MAX)
	f.macroName:SetPoint("TOPLEFT", rx + 6, -(H - 66))
	f.macroName:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			state.nameTouched = true
			UpdatePreview()
		end
	end)

	-- scope radios
	local scope = CreateFrame("Frame", nil, f)
	scope:SetSize(260, 44)
	scope:SetPoint("LEFT", f.macroName, "RIGHT", 16, 8)
	scope.account = CreateFrame("CheckButton", "MacroMasterScopeAccount", scope, "UIRadioButtonTemplate")
	scope.account:SetPoint("TOPLEFT", 0, 0)
	scope.character = CreateFrame("CheckButton", "MacroMasterScopeCharacter", scope, "UIRadioButtonTemplate")
	scope.character:SetPoint("TOPLEFT", 0, -20)
	local function radioText(b) return b.Text or b.text or _G[b:GetName() .. "Text"] end
	function scope:Refresh()
		local numAccount, numChar = GetNumMacros()
		radioText(self.account):SetText(string.format(L["Account (%d/%d)"], numAccount, MAX_ACCOUNT_MACROS))
		radioText(self.character):SetText(string.format(L["Character (%d/%d)"], numChar, MAX_CHARACTER_MACROS))
		self.account:SetChecked(ns.db.settings.scope ~= "character")
		self.character:SetChecked(ns.db.settings.scope == "character")
	end
	scope.account:SetScript("OnClick", function() ns.db.settings.scope = "account"; scope:Refresh() end)
	scope.character:SetScript("OnClick", function() ns.db.settings.scope = "character"; scope:Refresh() end)
	f.scope = scope

	f.pickup = CreateFrame("CheckButton", "MacroMasterPickup", f, "UICheckButtonTemplate")
	f.pickup:SetSize(24, 24)
	f.pickup:SetPoint("TOPLEFT", f.macroName, "BOTTOMLEFT", -4, -4)
	radioText(f.pickup):SetText(L["Pick up after creating"])
	f.pickup:SetScript("OnClick", function(self) ns.db.settings.pickup = self:GetChecked() and true or false end)
	f.pickup:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(L["Otherwise the macro window opens so you can drag them yourself. Not available when several macros are created at once."], 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	f.pickup:SetScript("OnLeave", GameTooltip_Hide)

	local bCreate = Button(f, L["Create"], 110, 26, CreateMacroFromState)
	bCreate:SetPoint("BOTTOMRIGHT", -20, 12)
	local bOpen = Button(f, L["Open Macros"], 110, 22, OpenMacroFrame)
	bOpen:SetPoint("RIGHT", bCreate, "LEFT", -6, 0)

	f:SetScript("OnShow", function(self)
		LoadValues()
		self.pickup:SetChecked(ns.db.settings.pickup)
		self.scope:Refresh()
		if not state.templateID then
			local first = ns.GetTemplates()[1]
			ns.SelectTemplate(first and first.id)
		else
			RefreshList()
			RefreshRows()
		end
	end)
	f:SetScript("OnHide", function()
		ns.HideSpellPicker()
		HideOptionList()
		if macroPicker then macroPicker:Hide() end
	end)

	tinsert(UISpecialFrames, f:GetName())
	f:Hide()
	return f
end

function ns.ShowMain()
	main = main or CreateMain()
	main:Show()
end

function ns.ToggleMain()
	main = main or CreateMain()
	main:SetShown(not main:IsShown())
end
