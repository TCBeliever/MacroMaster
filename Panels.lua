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
		{ "CANCEL",    L["P_CANCEL_H"],    "DEFENSIVE" },
		{ "SELFHEAL",  L["P_SELFHEAL_H"],  "SELFHEAL" },
		{ "HEALTHSTONE", L["P_HEALTHSTONE_H"], nil, nil, "HEALTHSTONE" },
		{ "POTION",    L["P_POTION_H"],    nil, nil, "HEALPOT" },
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
