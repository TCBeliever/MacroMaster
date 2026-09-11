local ADDON, ns = ...
local L = ns.L

-- ---------------------------------------------------------------------------
-- Spell book scan: every active, non-passive spell the character knows,
-- de-duplicated by name, sorted alphabetically.
-- ---------------------------------------------------------------------------

local spells = {}          -- every castable spell (class + general)
local classSpells = {}     -- skill lines 2+ (class / spec)
local generalSpells = {}   -- skill line 1 (General: racials, utilities...)

function ns.ScanSpellBook()
	wipe(spells); wipe(classSpells); wipe(generalSpells)
	local seen = {}
	local bank = Enum.SpellBookSpellBank.Player
	for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
		if line and not line.offSpecID then
			local bucket = (tab == 1) and generalSpells or classSpells
			for i = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
				local itemType, _, spellID = C_SpellBook.GetSpellBookItemType(i, bank)
				if itemType == Enum.SpellBookItemType.Spell and spellID
					and not C_SpellBook.IsSpellBookItemPassive(i, bank) then
					local info = C_Spell.GetSpellInfo(spellID)
					if info and info.name and not seen[info.name] then
						seen[info.name] = true
						local entry = { id = info.spellID, name = info.name, icon = info.iconID }
						spells[#spells + 1] = entry
						bucket[#bucket + 1] = entry
					end
				end
			end
		end
	end
	local byName = function(a, b) return a.name < b.name end
	table.sort(spells, byName); table.sort(classSpells, byName); table.sort(generalSpells, byName)
	return spells
end

function ns.IsSpellKnownByName(name)
	if not name or name == "" then return false end
	name = name:lower()
	for _, s in ipairs(spells) do
		if s.name:lower() == name then return true end
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Bag scan: every usable item (one with an on-use spell) in the bags,
-- de-duplicated by name, sorted alphabetically.
-- ---------------------------------------------------------------------------

local bagItems = {}

function ns.ScanBags()
	wipe(bagItems)
	local seen = {}
	local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
	for bag = 0, last do
		for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			local id = info and info.itemID
			if id and C_Item.GetItemSpell(id) then
				local name = C_Item.GetItemNameByID(id)
				if name and not seen[name] then
					seen[name] = true
					bagItems[#bagItems + 1] = { id = id, name = name, icon = info.iconFileID or C_Item.GetItemIconByID(id), item = true }
				end
			end
		end
	end
	table.sort(bagItems, function(a, b) return a.name < b.name end)
	return bagItems
end

-- ---------------------------------------------------------------------------
-- Picker frame: search box + icon grid. ns.ShowSpellPicker(anchor, callback)
-- and ns.ShowItemPicker(anchor, callback) share it; entries are
-- { id, name, icon, item=true|nil } and the callback gets (name, spellID, itemID).
-- ---------------------------------------------------------------------------

local COLS, CELL, PAD = 8, 36, 4
local picker

local function CreatePicker()
	local f = CreateFrame("Frame", "MacroMasterSpellPicker", UIParent, "BackdropTemplate")
	f:SetSize(COLS * (CELL + PAD) + 40, 420)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})
	f:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.title:SetPoint("TOP", 0, -14)
	f.title:SetText(L["Spell picker"])

	f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	f.close:SetPoint("TOPRIGHT", -4, -4)

	f.search = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
	f.search:SetSize(f:GetWidth() - 60, 22)
	f.search:SetPoint("TOP", 0, -36)
	f.search:SetAutoFocus(false)
	f.search:HookScript("OnTextChanged", function() f:Refresh() end)
	f.search:SetScript("OnEscapePressed", function() f:Hide() end)

	f.scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
	f.scroll:SetPoint("TOPLEFT", 16, -66)
	f.scroll:SetPoint("BOTTOMRIGHT", -26, 16)

	f.content = CreateFrame("Frame", nil, f.scroll)
	f.content:SetSize(COLS * (CELL + PAD), 10)
	f.scroll:SetScrollChild(f.content)

	f.buttons = {}
	f.headers = {}

	function f:GetHeader(i)
		local h = self.headers[i]
		if h then return h end
		h = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		h:SetJustifyH("LEFT")
		self.headers[i] = h
		return h
	end

	function f:GetButton(i)
		local b = self.buttons[i]
		if b then return b end
		b = CreateFrame("Button", nil, self.content)
		b:SetSize(CELL, CELL)
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetAllPoints()
		b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if self.isItem then GameTooltip:SetItemByID(self.entryID) else GameTooltip:SetSpellByID(self.entryID) end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		b:SetScript("OnClick", function(self)
			if f.callback then
				if self.isItem then f.callback(self.entryName, nil, self.entryID)
				else f.callback(self.entryName, self.entryID) end
			end
			f:Hide()
		end)
		self.buttons[i] = b
		return b
	end

	-- Lays out one section (header + grid) starting at y; returns new y.
	local function LayoutSection(self, headerIndex, title, list, filter, n, y)
		local shown = {}
		for _, s in ipairs(list) do
			if filter == "" or s.name:lower():find(filter, 1, true) then shown[#shown + 1] = s end
		end
		if #shown == 0 then return n, y end
		if title then
			local h = self:GetHeader(headerIndex)
			h:SetText(title)
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", self.content, "TOPLEFT", 2, y)
			h:Show()
			y = y - 16
		end
		for i, s in ipairs(shown) do
			n = n + 1
			local b = self:GetButton(n)
			b.entryID, b.entryName, b.isItem = s.id, s.name, s.item and true or false
			b.icon:SetTexture(s.icon)
			local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", self.content, "TOPLEFT", col * (CELL + PAD), y - row * (CELL + PAD))
			b:Show()
		end
		return n, y - math.ceil(#shown / COLS) * (CELL + PAD) - 6
	end

	function f:Refresh()
		local filter = self.search:GetText():lower()
		for _, h in ipairs(self.headers) do h:Hide() end
		local n, y = 0, 0
		if self.suggestions and #self.suggestions > 0 then
			n, y = LayoutSection(self, 1, self.suggestionTitle, self.suggestions, filter, n, y)
		end
		if self.itemMode then
			n, y = LayoutSection(self, 2, L["Bag items"], bagItems, filter, n, y)
		else
			n, y = LayoutSection(self, 2, L["Class spells"], classSpells, filter, n, y)
			n, y = LayoutSection(self, 3, L["General spells"], generalSpells, filter, n, y)
		end
		for i = n + 1, #self.buttons do self.buttons[i]:Hide() end
		self.content:SetHeight(math.max(10, -y))
	end

	f:SetScript("OnShow", function(self)
		if self.itemMode then ns.ScanBags() else ns.ScanSpellBook() end
		self.title:SetText(self.itemMode and L["Item picker"] or L["Spell picker"])
		self.search:SetText("")
		self:Refresh()
		self.search:SetFocus()
	end)

	tinsert(UISpecialFrames, f:GetName())
	f:Hide()
	return f
end

local function OpenPicker(anchor)
	picker:ClearAllPoints()
	if anchor then
		picker:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
	else
		picker:SetPoint("CENTER")
	end
	-- OnShow (rescan + refresh) only fires on a hidden frame; an open picker
	-- switching row or mode has to go through it again
	if picker:IsShown() then picker:Hide() end
	picker:Show()
end

-- category (optional): show that category's suggestions for this character
-- above the full spell list.
function ns.ShowSpellPicker(anchor, callback, category)
	picker = picker or CreatePicker()
	picker.callback = callback
	picker.itemMode = false
	picker.suggestions = nil
	if category and ns.ResolveSuggestions then
		picker.suggestions = ns.ResolveSuggestions(category, true)
		picker.suggestionTitle = string.format(L["Suggested: %s"], L["CAT_" .. category])
	end
	OpenPicker(anchor)
end

-- Same grid fed from the bags: the item category's suggestions that are in
-- the bags first, then every usable item. callback(name, nil, itemID).
function ns.ShowItemPicker(anchor, callback, category)
	picker = picker or CreatePicker()
	picker.callback = callback
	picker.itemMode = true
	picker.suggestions = nil
	if category and ns.ResolveItemSuggestions then
		picker.suggestions = ns.ResolveItemSuggestions(category)
		picker.suggestionTitle = string.format(L["Suggested: %s"], L["CAT_" .. category])
	end
	OpenPicker(anchor)
end

function ns.HideSpellPicker()
	if picker then picker:Hide() end
end
