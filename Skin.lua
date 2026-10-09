local ADDON, ns = ...
local L = ns.L

-- ===========================================================================
-- Two looks behind one set of widget constructors, so every window is laid
-- out once:
--
--   classic  the game's own frame templates and border art, as the addon has
--            always drawn them. The default.
--   modern   (beta) flat panels, 1px borders, one palette at a time, drawn
--            with the white 8x8 texture and no Blizzard template. Two
--            palettes, Tide (blue) and Dusk (violet), the ones CombatKit
--            uses. Fonts stay the game's own so every locale keeps its glyphs.
--
-- The look is fixed when the saved settings are read (Skin.Init): a frame
-- cannot change its template afterwards, so Classic <-> Modern takes a UI
-- reload. Tide <-> Dusk is a repaint: every widget coloured from the palette
-- says how (Skin.Paint), and the inline colours (Skin.Text) are built again
-- by the refresh that follows.
-- ===========================================================================

local Skin = {}
ns.Skin = Skin

local WHITE = "Interface\\Buttons\\WHITE8x8"

-- The looks to pick from, in the order the settings list them; the first is
-- the default. An entry with colours is a modern palette. ok and bad mean the
-- same in every palette, so an accent keeps clear of green and red.
Skin.THEMES = {
	{ key = "classic" },
	{ key = "tide", colors = {
		bg       = { 0.025, 0.040, 0.055 },
		panel    = { 0.040, 0.100, 0.130 },
		element  = { 0.060, 0.180, 0.230 },
		hover    = { 0.080, 0.240, 0.300 },
		selected = { 0.070, 0.230, 0.290 },
		border   = { 0.160, 0.450, 0.560 },
		accent   = { 0.300, 0.720, 0.880 },
		text     = { 1.00, 1.00, 1.00 },
		dim      = { 0.62, 0.71, 0.76 },
		ok       = { 0.34, 0.88, 0.48 },
		bad      = { 0.95, 0.35, 0.35 },
	} },
	{ key = "dusk", colors = {
		bg       = { 0.040, 0.030, 0.060 },
		panel    = { 0.085, 0.060, 0.135 },
		element  = { 0.140, 0.100, 0.230 },
		hover    = { 0.190, 0.140, 0.300 },
		selected = { 0.180, 0.130, 0.290 },
		border   = { 0.390, 0.280, 0.560 },
		accent   = { 0.700, 0.540, 0.920 },
		text     = { 1.00, 1.00, 1.00 },
		dim      = { 0.70, 0.65, 0.78 },
		ok       = { 0.34, 0.88, 0.48 },
		bad      = { 0.95, 0.35, 0.35 },
	} },
}

-- The classic look colours its text with fixed hues: the gold of
-- GameFontNormal, the addon's own blue, and the usual green, red and grey.
local CLASSIC = {
	text   = { 1.00, 1.00, 1.00 },
	head   = { 1.00, 0.82, 0.00 },
	accent = { 0.40, 0.80, 1.00 },
	dim    = { 0.50, 0.50, 0.50 },
	ok     = { 0.25, 1.00, 0.25 },
	bad    = { 1.00, 0.25, 0.25 },
}

local modern = false   -- the look in force, from Skin.Init
local C = {}           -- the modern palette in force, filled by Skin.SetTheme
Skin.theme = Skin.THEMES[1].key
Skin.modern = false
-- Layout that differs between the looks: the room the tab strip takes above
-- a tabbed window, the room a scroll bar takes at the right of a list, and
-- how far a single-line box sits from the left edge of its label.
Skin.TOP_EXTRA, Skin.SCROLL_W, Skin.EDIT_INSET = 0, 26, 6

local TITLE_H, TAB_H = 28, 24   -- modern: the title bar and the tab strip

local function Find(key)
	for _, t in ipairs(Skin.THEMES) do
		if t.key == key then return t end
	end
end

function Skin.IsModernKey(key)
	local t = Find(key)
	return t ~= nil and t.colors ~= nil
end

-- "head" is a heading inside text: gold in the classic look, the accent in
-- the modern one.
function Skin.Color(name)
	local c
	if modern then
		c = C[name == "head" and "accent" or name] or C.text
	else
		c = CLASSIC[name] or CLASSIC.text
	end
	return c[1], c[2], c[3]
end

-- "|cffrrggbb" for inline colouring
function Skin.Hex(name)
	local r, g, b = Skin.Color(name)
	return string.format("|cff%02x%02x%02x",
		math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

function Skin.Text(name, text)
	return Skin.Hex(name) .. text .. "|r"
end

-- ---------------------------------------------------------------------------
-- Painting. Every widget coloured from the palette says how, so a palette
-- switch can paint it again. A colour that follows a state (a lit button, a
-- dimmed tab) reads the state inside its apply; every inline Skin.Text is set
-- again by the refresh after a switch.
-- ---------------------------------------------------------------------------

local painted = setmetatable({}, { __mode = "k" })   -- widget -> how it is coloured

-- apply(widget) colours it from the palette: run now and on every switch
function Skin.Paint(widget, apply)
	painted[widget] = apply
	apply(widget)
	return widget
end

function Skin.Repaint(widget)
	local apply = painted[widget]
	if apply then apply(widget) end
end

-- key: a modern palette; anything else reads as the first one. Skin.theme is
-- the key in force afterwards.
function Skin.SetTheme(key)
	local theme = Find(key)
	if not (theme and theme.colors) then
		for _, t in ipairs(Skin.THEMES) do
			if t.colors then theme = t; break end
		end
	end
	Skin.theme = theme.key
	for name, c in pairs(theme.colors) do C[name] = { c[1], c[2], c[3] } end
	for widget, apply in pairs(painted) do apply(widget) end
end

-- Reads the saved choice, before any window is built. Returns the key in
-- force: a key that is gone reads as classic.
function Skin.Init(key)
	local theme = Find(key) or Skin.THEMES[1]
	modern = theme.colors ~= nil
	Skin.modern = modern
	Skin.TOP_EXTRA = modern and 14 or 0
	Skin.SCROLL_W = modern and 12 or 26
	Skin.EDIT_INSET = modern and 0 or 6
	if modern then Skin.SetTheme(theme.key) else Skin.theme = theme.key end
	return Skin.theme
end

-- ---------------------------------------------------------------------------
-- Backdrops. kind: "window" (a frame of its own), "bar" (the strip under the
-- game's macro window), "box" (an inset list or text area), "list" (the pick
-- list), "panel" and "element" (a title bar; a button or text box: modern).
-- The frame must have been created with "BackdropTemplate".
-- ---------------------------------------------------------------------------

local DIALOG_EDGE  = "Interface\\DialogFrame\\UI-DialogBox-Border"
local TOOLTIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local CLASSIC_BACKDROP = {
	window = { bgFile = WHITE, edgeFile = DIALOG_EDGE, tile = true, tileSize = 32, edgeSize = 24,
		insets = { left = 6, right = 6, top = 6, bottom = 6 } },
	bar = { bgFile = WHITE, edgeFile = DIALOG_EDGE, tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 } },
	box = { bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = TOOLTIP_EDGE, tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 } },
	list = { bgFile = WHITE, edgeFile = TOOLTIP_EDGE, tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 } },
}
local CLASSIC_COLOR = {   -- background, border (none: the border art as it is)
	window = { { 0.05, 0.05, 0.07, 0.96 } },
	bar    = { { 0.05, 0.05, 0.07, 0.96 } },
	box    = { { 0, 0, 0, 0.6 }, { 0.5, 0.5, 0.5, 1 } },
	list   = { { 0.05, 0.05, 0.07, 0.98 } },
}
local MODERN_COLOR = {    -- background, border, from the palette
	window  = { "bg", "border" },
	bar     = { "bg", "border" },
	box     = { "panel", "border" },
	list    = { "bg", "accent" },
	panel   = { "panel", "border" },
	element = { "element", "border" },
}

function Skin.Backdrop(frame, kind)
	if modern then
		local spec = MODERN_COLOR[kind] or MODERN_COLOR.element
		frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
		Skin.Paint(frame, function(f)
			local r, g, b = Skin.Color(spec[1])
			f:SetBackdropColor(r, g, b, 1)   -- opaque: the game must not bleed through
			f:SetBackdropBorderColor(Skin.Color(spec[2]))
		end)
	else
		frame:SetBackdrop(CLASSIC_BACKDROP[kind] or CLASSIC_BACKDROP.box)
		local c = CLASSIC_COLOR[kind] or CLASSIC_COLOR.box
		frame:SetBackdropColor(unpack(c[1]))
		if c[2] then frame:SetBackdropBorderColor(unpack(c[2])) end
	end
end

function Skin.Panel(parent, kind)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Skin.Backdrop(f, kind)
	return f
end

-- An inset box: a list or a text area sits in it
function Skin.Box(parent)
	return Skin.Panel(parent, "box")
end

-- A solid colour texture
function Skin.Fill(parent, layer, name, alpha)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND")
	return Skin.Paint(t, function(tex)
		local r, g, b = Skin.Color(name)
		tex:SetColorTexture(r, g, b, alpha or 1)
	end)
end

-- ---------------------------------------------------------------------------
-- Text. The classic look keeps each font object's own colour (gold headings,
-- white text, grey hints); the modern one reads the role off the template, or
-- takes it from `role` ("text", "dim", "head", "accent"...).
-- ---------------------------------------------------------------------------

local ROLE_OF = {
	GameFontNormal = "text", GameFontNormalSmall = "dim", GameFontNormalLarge = "text",
	GameFontHighlight = "text", GameFontHighlightSmall = "text", GameFontHighlightLarge = "text",
	GameFontDisable = "dim", GameFontDisableSmall = "dim", ChatFontNormal = "text",
}

function Skin.Label(parent, text, template, role)
	template = template or "GameFontNormal"
	local fs = parent:CreateFontString(nil, "OVERLAY", template)
	if modern then
		role = role or ROLE_OF[template] or "text"
		Skin.Paint(fs, function(f) f:SetTextColor(Skin.Color(role)) end)
	end
	fs:SetText(text or "")
	return fs
end

-- ---------------------------------------------------------------------------
-- Buttons
-- ---------------------------------------------------------------------------

-- modern, at rest: plain, or picked out when the widget is the chosen one of
-- a group (or the window's main action)
local function Rest(self)
	self:SetBackdropColor(Skin.Color(self.selected and "selected" or "element"))
	self:SetBackdropBorderColor(Skin.Color(self.selected and "accent" or "border"))
end

local function Hoverable(widget)
	widget:HookScript("OnEnter", function(self)
		if self.disabled then return end
		self:SetBackdropColor(Skin.Color("hover"))
		self:SetBackdropBorderColor(Skin.Color("accent"))
	end)
	widget:HookScript("OnLeave", Rest)
end

-- w is a minimum: a label longer than that (other language) widens the
-- button. SetLabel instead of SetText keeps that true when the text changes.
-- SetSelected(on): one of several buttons that stand for a choice; the chosen
-- one is lit (modern) or pressed, that is disabled (classic). SetPrimary():
-- the one action a window leads to, lit for good in the modern look.
function Skin.Button(parent, text, w, h, onClick)
	local b
	if modern then
		b = CreateFrame("Button", nil, parent, "BackdropTemplate")
		b:SetSize(w, h or 22)
		Skin.Backdrop(b, "element")
		Skin.Paint(b, Rest)   -- a lit button stays lit through a palette switch
		local fs = Skin.Label(b, "", "GameFontHighlightSmall")
		fs:SetPoint("CENTER")
		b:SetFontString(fs)
		function b:SetLabel(label)
			self:SetText(label or "")
			self:SetWidth(math.max(w, fs:GetStringWidth() + 18))
		end
		function b:SetSelected(on)
			self.selected = on and true or false
			Rest(self)
		end
		function b:SetPrimary() self:SetSelected(true) end
		function b:SetDisabled(disabled)
			self.disabled = disabled and true or false
			self:SetAlpha(self.disabled and 0.55 or 1)
		end
		function b:SetEnabled(on) self:SetDisabled(not on) end
		Hoverable(b)
		b:SetScript("OnClick", function(self, ...)
			if not self.disabled then onClick(self, ...) end
		end)
	else
		b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		b:SetSize(w, h or 22)
		function b:SetLabel(label)
			self:SetText(label or "")
			local fs = self:GetFontString()
			if fs then self:SetWidth(math.max(w, fs:GetStringWidth() + 20)) end
		end
		function b:SetSelected(on) self:SetEnabled(not on) end
		function b:SetPrimary() end
		b:SetScript("OnClick", onClick)
	end
	b:SetLabel(text)
	return b
end

-- Two thin rotated bars: an X, without a texture file (modern)
local function Bars(parent, length, colour, a1, x1, a2, x2)
	local out = {}
	for i, spec in ipairs({ { a1, x1 }, { a2, x2 } }) do
		local t = Skin.Fill(parent, "ARTWORK", colour)
		t:SetSize(length, 1.5)
		t:SetPoint("CENTER", spec[2], 0)
		t:SetRotation(spec[1])
		out[i] = t
	end
	return out
end

-- onClick: what the X does; usually hides the window it sits on
function Skin.CloseButton(parent, onClick)
	local b
	if modern then
		b = CreateFrame("Button", nil, parent)
		b:SetSize(20, 20)
		b.bars = Bars(b, 12, "dim", math.pi / 4, 0, -math.pi / 4, 0)
		local function Tint(name)
			for _, t in ipairs(b.bars) do t:SetColorTexture(Skin.Color(name)) end
		end
		b:SetScript("OnEnter", function() Tint("text") end)
		b:SetScript("OnLeave", function() Tint("dim") end)
	else
		b = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
	end
	b:SetScript("OnClick", onClick)
	return b
end

-- ---------------------------------------------------------------------------
-- Check boxes and radio buttons: .label is the text beside the box, so a
-- neighbour can anchor to it. onClick(self); read self:GetChecked().
-- ---------------------------------------------------------------------------

-- modern: a plain Button that behaves like a check box (radio: a smaller
-- box with a dot)
local function Tick(parent, text, onClick, radio)
	local c = CreateFrame("Button", nil, parent)
	c:SetHeight(18)
	local box, mark = radio and 12 or 14, radio and 5 or 8
	c.box = Skin.Fill(c, "BACKGROUND", "border")
	c.box:SetSize(box, box)
	c.box:SetPoint("LEFT")
	c.fill = Skin.Fill(c, "BORDER", "element")
	c.fill:SetSize(box - 2, box - 2)
	c.fill:SetPoint("CENTER", c.box)
	c.mark = Skin.Fill(c, "ARTWORK", "accent")
	c.mark:SetSize(mark, mark)
	c.mark:SetPoint("CENTER", c.box)
	c.mark:Hide()
	c.label = Skin.Label(c, "", "GameFontHighlightSmall")
	c.label:SetPoint("LEFT", c.box, "RIGHT", 6, 0)

	-- the click area follows the label, whatever the language
	function c:SetLabel(label)
		self.label:SetText(label or "")
		self:SetWidth(box + 6 + self.label:GetStringWidth())
	end
	c:SetLabel(text)

	function c:SetChecked(v)
		self.checked = v and true or false
		self.mark:SetShown(self.checked)
	end
	function c:GetChecked() return self.checked or false end
	function c:SetDisabled(disabled)
		self.disabled = disabled and true or false
		self:SetAlpha(self.disabled and 0.55 or 1)
	end

	c:SetScript("OnEnter", function(self)
		if not self.disabled then self.box:SetColorTexture(Skin.Color("accent")) end
	end)
	c:SetScript("OnLeave", function(self) self.box:SetColorTexture(Skin.Color("border")) end)
	c:SetScript("OnClick", function(self)
		if self.disabled then return end
		self:SetChecked(not self.checked)
		onClick(self)
	end)
	return c
end

-- classic: the game's template, which wants a global name for its text
local function Classic(template, parent, name, text, onClick, size)
	local c = CreateFrame("CheckButton", name, parent, template)
	c:SetSize(size, size)
	c.label = c.Text or c.text or _G[name .. "Text"]
	c.label:SetText(text or "")
	function c:SetLabel(label) self.label:SetText(label or "") end
	function c:SetDisabled(disabled)
		self:SetEnabled(not disabled)
		if disabled then self.label:SetTextColor(0.5, 0.5, 0.5) else self.label:SetTextColor(1, 0.82, 0) end
	end
	c:SetScript("OnClick", onClick)
	return c
end

function Skin.Checkbox(parent, name, text, onClick)
	if modern then return Tick(parent, text, onClick, false) end
	return Classic("UICheckButtonTemplate", parent, name, text, onClick, 24)
end

function Skin.Radio(parent, name, text, onClick)
	if modern then return Tick(parent, text, onClick, true) end
	return Classic("UIRadioButtonTemplate", parent, name, text, onClick, 16)
end

-- ---------------------------------------------------------------------------
-- Text boxes
-- ---------------------------------------------------------------------------

-- One line. The caller adds its own scripts with HookScript, so the modern
-- focus border stays.
function Skin.EditBox(parent, w, maxLetters)
	local e
	if modern then
		e = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
		Skin.Backdrop(e, "element")
		e:SetFontObject(ChatFontNormal)
		e:SetTextInsets(6, 6, 0, 0)
		e:SetScript("OnEditFocusGained", function(self) self:SetBackdropBorderColor(Skin.Color("accent")) end)
		e:SetScript("OnEditFocusLost", function(self) self:SetBackdropBorderColor(Skin.Color("border")) end)
	else
		e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	end
	e:SetSize(w, 22)
	e:SetAutoFocus(false)
	if maxLetters then e:SetMaxLetters(maxLetters) end
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	return e
end

-- A search box: the game's own, or a plain box with a hint while it is empty
function Skin.Search(parent, w)
	if not modern then
		local e = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate")
		e:SetSize(w, 22)
		e:SetAutoFocus(false)
		return e
	end
	local e = Skin.EditBox(parent, w)
	e.hint = Skin.Label(e, L["Search"], "ChatFontNormal", "dim")
	e.hint:SetPoint("LEFT", 7, 0)
	local function UpdateHint(self)
		self.hint:SetShown(not self:HasFocus() and (self:GetText() or "") == "")
	end
	e:HookScript("OnEditFocusGained", UpdateHint)
	e:HookScript("OnEditFocusLost", UpdateHint)
	e:HookScript("OnTextChanged", UpdateHint)
	return e
end

-- A thin scroll indicator at the right of `sf`, in sf's parent: the thumb is
-- as long as the share of the content that is visible. The wheel scrolls; a
-- click or a drag on the track jumps there. (modern)
local SCROLL_STEP = 24
local function Thumbed(sf)
	local track = CreateFrame("Button", nil, sf:GetParent())
	track:SetWidth(8)
	track:SetPoint("TOPLEFT", sf, "TOPRIGHT", 2, 0)
	track:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 2, 0)
	track.thumb = Skin.Fill(track, "ARTWORK", "accent", 0.7)
	track.thumb:SetWidth(3)
	track.thumb:Hide()
	sf.track = track

	local function Update(self)
		local range = self:GetVerticalScrollRange()
		local thumb = self.track.thumb
		if range <= 0 then thumb:Hide(); return end
		local h = self.track:GetHeight()
		local visible = self:GetHeight()
		local len = math.max(12, h * visible / (visible + range))
		thumb:SetHeight(len)
		thumb:ClearAllPoints()
		thumb:SetPoint("TOPRIGHT", -2, -(h - len) * self:GetVerticalScroll() / range)
		thumb:Show()
	end
	sf:HookScript("OnScrollRangeChanged", Update)
	sf:HookScript("OnVerticalScroll", Update)
	sf:EnableMouseWheel(true)
	sf:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * SCROLL_STEP)))
	end)

	track:SetScript("OnMouseDown", function(self) self.dragging = true end)
	track:SetScript("OnMouseUp", function(self) self.dragging = false end)
	track:SetScript("OnUpdate", function(self)
		if not self.dragging then return end
		if not IsMouseButtonDown("LeftButton") then self.dragging = false; return end
		local range = sf:GetVerticalScrollRange()
		if range <= 0 then return end
		local _, y = GetCursorPosition()
		y = y / self:GetEffectiveScale()
		local len = self.thumb:GetHeight()
		local frac = (self:GetTop() - y - len / 2) / math.max(1, self:GetHeight() - len)
		sf:SetVerticalScroll(math.max(0, math.min(range, frac * range)))
	end)
end

-- Several lines, w by h. Returns the frame to anchor; .EditBox is the text.
-- boxed: the classic look sets the text area in an inset box (a window whose
-- whole content it is); the modern look always draws its own.
function Skin.MultiLine(parent, w, h, maxLetters, boxed)
	if not modern then
		local box
		if boxed then
			box = Skin.Box(parent)
			box:SetSize(w, h)
		end
		local sf = CreateFrame("ScrollFrame", nil, box or parent, "InputScrollFrameTemplate")
		if boxed then
			sf:SetPoint("TOPLEFT", 8, -8)
			sf:SetPoint("BOTTOMRIGHT", -8, 8)
			sf.EditBox:SetWidth(w - 16 - 24)
		else
			sf:SetSize(w, h)
			sf.EditBox:SetWidth(w - 18)
		end
		sf.EditBox:SetMaxLetters(maxLetters or 0)
		sf.EditBox:SetFontObject(ChatFontNormal)
		sf.EditBox:SetAutoFocus(false)
		sf.EditBox:SetScript("OnEscapePressed", sf.EditBox.ClearFocus)
		if sf.CharCount then sf.CharCount:Hide() end
		if box then
			box.EditBox = sf.EditBox
			return box
		end
		return sf
	end

	local box = Skin.Panel(parent, "element")
	box:SetSize(w, h)
	local sf = CreateFrame("ScrollFrame", nil, box)
	sf:SetPoint("TOPLEFT", 4, -4)
	sf:SetPoint("BOTTOMRIGHT", -14, 4)
	local e = CreateFrame("EditBox", nil, sf)
	e:SetMultiLine(true)
	e:SetMaxLetters(maxLetters or 0)
	e:SetWidth(w - 4 - 14 - 4)
	e:SetFontObject(ChatFontNormal)
	e:SetAutoFocus(false)
	e:SetTextInsets(2, 2, 2, 2)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	-- the box follows the cursor, as the game's own text areas do
	e:SetScript("OnCursorChanged", function(self, x, y, cw, ch)
		if ScrollingEdit_OnCursorChanged then ScrollingEdit_OnCursorChanged(self, x, y, cw, ch) end
	end)
	e:SetScript("OnUpdate", function(self, elapsed)
		if ScrollingEdit_OnUpdate then ScrollingEdit_OnUpdate(self, elapsed, sf) end
	end)
	e:HookScript("OnEditFocusGained", function() box:SetBackdropBorderColor(Skin.Color("accent")) end)
	e:HookScript("OnEditFocusLost", function() box:SetBackdropBorderColor(Skin.Color("border")) end)
	sf:SetScrollChild(e)
	Thumbed(sf)
	-- a click on the blank part of the box puts the cursor at the end
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function()
		e:SetFocus()
		e:SetCursorPosition(e:GetNumLetters())
	end)
	box.EditBox = e
	box.ScrollFrame = sf
	return box
end

-- A scrolling list: anchor the frame with Skin.SCROLL_W of room at the right.
-- .content is the scroll child, w wide until the frame has its size and then
-- as wide as the frame; the caller sets its height to what it holds.
function Skin.ScrollFrame(parent, w)
	local sf
	if modern then
		sf = CreateFrame("ScrollFrame", nil, parent)
		Thumbed(sf)
	else
		sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	end
	sf.content = CreateFrame("Frame", nil, sf)
	sf.content:SetSize(w or 10, 10)
	sf:SetScrollChild(sf.content)
	sf:HookScript("OnSizeChanged", function(self, width) self.content:SetWidth(width) end)
	return sf
end

-- ---------------------------------------------------------------------------
-- Lists: a row that can be the selected one, and a pick list
-- ---------------------------------------------------------------------------

-- A Button with a hover look and SetSelected(on); the caller adds text and
-- icons, and hooks (not sets) OnEnter and OnLeave.
function Skin.Row(parent)
	local b = CreateFrame("Button", nil, parent)
	if modern then
		b.sel = Skin.Fill(b, "BACKGROUND", "selected")
		b.sel:SetAllPoints()
		b.bar = Skin.Fill(b, "BORDER", "accent")
		b.bar:SetPoint("TOPLEFT")
		b.bar:SetPoint("BOTTOMLEFT")
		b.bar:SetWidth(2)
		b.bar:Hide()
		b.hover = Skin.Fill(b, "BACKGROUND", "hover", 0.5)
		b.hover:SetAllPoints()
		b.hover:Hide()
		b:SetScript("OnEnter", function(self) self.hover:Show() end)
		b:SetScript("OnLeave", function(self) self.hover:Hide() end)
	else
		b.sel = b:CreateTexture(nil, "BACKGROUND")
		b.sel:SetAllPoints()
		b.sel:SetColorTexture(0.3, 0.55, 0.9, 0.35)
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	end
	b.sel:Hide()
	function b:SetSelected(on)
		self.sel:SetShown(on)
		if self.bar then self.bar:SetShown(on) end
	end
	return b
end

local LIST_ROWS = 12   -- more than this and the list scrolls with the mouse wheel

-- A small list under `anchor`: items = { { label=, value=, icon= }, ... },
-- onPick(item). A click anywhere else closes it.
local optionList
function Skin.OptionList(anchor, items, onPick)
	if not optionList then
		local f = CreateFrame("Frame", "MacroMasterOptionList", UIParent, "BackdropTemplate")
		f:SetFrameStrata("TOOLTIP")
		Skin.Backdrop(f, "list")
		f:EnableMouse(true)
		f.buttons = {}
		f.measure = Skin.Label(f, "", "GameFontHighlightSmall")
		f.measure:Hide()
		-- a thumb at the right edge while there is more than fits
		f.thumb = Skin.Fill(f, "ARTWORK", "accent", 0.7)
		f.thumb:SetWidth(2)
		f:EnableMouseWheel(true)
		f:SetScript("OnMouseWheel", function(self, delta)
			local last = math.max(0, #self.items - LIST_ROWS)
			self.offset = math.max(0, math.min(last, self.offset - delta))
			self.Render()
		end)
		f:SetScript("OnUpdate", function(self)
			if IsMouseButtonDown("LeftButton") and not self:IsMouseOver() and not self.anchor:IsMouseOver() then
				self:Hide()
			end
		end)
		optionList = f
	end
	local f = optionList
	if f:IsShown() and f.anchor == anchor then f:Hide(); return end
	f.anchor = anchor
	f.items, f.offset = items, 0
	local w = anchor:GetWidth() - 8
	for _, item in ipairs(items) do
		f.measure:SetText(item.label)
		w = math.max(w, f.measure:GetStringWidth() + 16 + (item.icon and 22 or 0))
	end
	local rows = math.min(#items, LIST_ROWS)
	for i = 1, rows do
		local b = f.buttons[i]
		if not b then
			b = Skin.Row(f)
			b:SetHeight(20)
			b.icon = b:CreateTexture(nil, "ARTWORK")
			b.icon:SetSize(16, 16)
			b.icon:SetPoint("LEFT", 6, 0)
			b.text = Skin.Label(b, "", "GameFontHighlightSmall")
			b:SetScript("OnClick", function(self)
				f:Hide()
				f.onPick(self.item)
			end)
			f.buttons[i] = b
		end
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 20)
		b:SetWidth(w)
		b:Show()
	end
	for i = rows + 1, #f.buttons do f.buttons[i]:Hide() end

	-- the rows show items[offset + 1 ...]
	function f.Render()
		for i = 1, rows do
			local b, item = f.buttons[i], f.items[f.offset + i]
			b.item = item
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
		end
		local more = #f.items > rows
		f.thumb:SetShown(more)
		if more then
			local track = rows * 20
			f.thumb:SetHeight(track * rows / #f.items)
			f.thumb:ClearAllPoints()
			f.thumb:SetPoint("TOPRIGHT", -4, -4 - track * f.offset / #f.items)
		end
	end
	f.Render()
	f.onPick = onPick
	f:SetSize(w + 8, rows * 20 + 8)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	f:Show()
end

function Skin.HideOptionList() if optionList then optionList:Hide() end end

-- ---------------------------------------------------------------------------
-- Windows and their tabs
-- ---------------------------------------------------------------------------

-- A window of its own, named, closable with Esc: title, close button, drag
-- anywhere. title: text, or a function returning it (painted again on a
-- palette switch). opts: strata (DIALOG), titleFont (classic), onDragStop.
-- It starts hidden; the caller places it.
function Skin.Window(name, w, h, title, opts)
	opts = opts or {}
	local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	f:SetSize(w, h)
	f:SetFrameStrata(opts.strata or "DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if opts.onDragStop then opts.onDragStop(self) end
	end)
	Skin.Backdrop(f, "window")

	local host = f
	if modern then
		local bar = Skin.Panel(f, "panel")
		bar:SetPoint("TOPLEFT")
		bar:SetPoint("TOPRIGHT")
		bar:SetHeight(TITLE_H)
		f.titleBar = bar
		f.title = Skin.Label(bar, "", "GameFontHighlight")
		f.title:SetPoint("LEFT", 10, 0)
		f.title:SetJustifyH("LEFT")
		host = bar
	else
		f.title = Skin.Label(f, "", opts.titleFont or "GameFontNormal")
		f.title:SetPoint("TOP", 0, -14)
	end
	if type(title) == "function" then
		Skin.Paint(f.title, function(fs) fs:SetText(title()) end)
	else
		f.title:SetText(title or "")
	end
	f.close = Skin.CloseButton(host, function() f:Hide() end)
	if modern then f.close:SetPoint("RIGHT", -4, 0) else f.close:SetPoint("TOPRIGHT", -4, -4) end

	tinsert(UISpecialFrames, name)
	f:Hide()
	return f
end

-- Tabs on a window: at the bottom in the classic look, in a strip under the
-- title bar in the modern one; the content starts Skin.TOP_EXTRA lower
-- there. onSelect(i); f:SelectTab(i) shows which is open.
function Skin.Tabs(f, labels, onSelect)
	f.tabs = {}
	if modern then
		local strip = Skin.Panel(f, "window")   -- shares a border line with the title bar
		strip:SetPoint("TOPLEFT", 0, -(TITLE_H - 1))
		strip:SetPoint("TOPRIGHT", 0, -(TITLE_H - 1))
		strip:SetHeight(TAB_H)
		f.tabStrip = strip
		for i, text in ipairs(labels) do
			local b = CreateFrame("Button", nil, strip)
			b:SetHeight(TAB_H - 2)   -- between the strip's two border lines
			b.id = i
			b.sel = Skin.Fill(b, "BACKGROUND", "selected")
			b.sel:SetAllPoints()
			b.bar = Skin.Fill(b, "BORDER", "accent")
			b.bar:SetPoint("TOPLEFT")
			b.bar:SetPoint("TOPRIGHT")
			b.bar:SetHeight(2)
			b.hover = Skin.Fill(b, "BACKGROUND", "hover", 0.5)
			b.hover:SetAllPoints()
			b.hover:Hide()
			b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			b.text:SetPoint("CENTER")
			b.text:SetText(text)
			Skin.Paint(b.text, function(fs) fs:SetTextColor(Skin.Color(b.selected and "text" or "dim")) end)
			b:SetWidth(b.text:GetStringWidth() + 28)
			if i == 1 then
				b:SetPoint("TOPLEFT", 1, -1)
			else
				b:SetPoint("LEFT", f.tabs[i - 1], "RIGHT", 0, 0)
			end
			b:SetScript("OnEnter", function(self) self.hover:Show() end)
			b:SetScript("OnLeave", function(self) self.hover:Hide() end)
			b:SetScript("OnClick", function(self) onSelect(self.id) end)
			f.tabs[i] = b
		end
		function f:SelectTab(i)
			for j, b in ipairs(self.tabs) do
				b.selected = (j == i)
				b.sel:SetShown(b.selected)
				b.bar:SetShown(b.selected)
				Skin.Repaint(b.text)
			end
		end
		return
	end

	local template = (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo("PanelTabButtonTemplate"))
		and "PanelTabButtonTemplate" or "CharacterFrameTabButtonTemplate"
	for i, text in ipairs(labels) do
		local t = CreateFrame("Button", f:GetName() .. "Tab" .. i, f, template)
		t:SetID(i)
		t:SetText(text)
		if i == 1 then
			t:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 2)
		else
			t:SetPoint("LEFT", f.tabs[i - 1], "RIGHT", -16, 0)
		end
		t:SetScript("OnClick", function(self) onSelect(self:GetID()) end)
		PanelTemplates_TabResize(t, 0)
		f.tabs[i] = t
	end
	PanelTemplates_SetNumTabs(f, #labels)
	function f:SelectTab(i) PanelTemplates_SetTab(self, i) end
end
