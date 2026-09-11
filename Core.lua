local ADDON, ns = ...
local L = ns.L

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")

-- Two buttons on Blizzard's macro window: open MacroMaster, and turn the
-- currently selected macro into a template.
local function HookMacroFrame()
	if not MacroFrame or MacroFrame.MacroMasterHooked then return end
	MacroFrame.MacroMasterHooked = true

	-- A bar attached under the macro window: far more visible than buttons
	-- squeezed into the frame itself. It is a child, so it shows/hides with it.
	local bar = CreateFrame("Frame", "MacroMasterMacroBar", MacroFrame, "BackdropTemplate")
	bar:SetPoint("TOPLEFT", MacroFrame, "BOTTOMLEFT", 0, 4)
	bar:SetPoint("TOPRIGHT", MacroFrame, "BOTTOMRIGHT", 0, 4)
	bar:SetHeight(40)
	bar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	bar:SetBackdropColor(0.05, 0.05, 0.07, 0.96)

	bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.label:SetPoint("LEFT", 14, 0)
	bar.label:SetText("|cff66ccffMacro|rMaster")

	local open = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
	open:SetSize(100, 24)
	open:SetPoint("LEFT", bar.label, "RIGHT", 12, 0)
	open:SetText(L["Open"])
	open:SetScript("OnClick", ns.ShowMain)

	local save = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
	save:SetSize(110, 24)
	save:SetPoint("RIGHT", -12, 0)
	save:SetText(L["Save as template"])
	save:SetScript("OnClick", function()
		-- 12.x MacroFrameMixin: selection lives in MacroSelector
		local index
		if MacroFrame.GetSelectedIndex and MacroFrame.GetMacroDataIndex then
			if MacroFrame.SaveMacro then MacroFrame:SaveMacro() end   -- capture unsaved edits
			local sel = MacroFrame:GetSelectedIndex()
			index = sel and MacroFrame:GetMacroDataIndex(sel)
		else
			index = MacroFrame.selectedMacro
		end
		if not index or index == 0 then ns.Msg(L["MSG_NO_MACRO"]); return end
		ns.ImportMacroAsTemplate(index)
	end)
end

driver:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON then
			ns.InitDB()
		elseif arg1 == "Blizzard_MacroUI" then
			HookMacroFrame()
		end
	elseif event == "PLAYER_LOGIN" then
		if MacroFrame then HookMacroFrame() end
	end
end)

-- /mmfocus <text>: announce the current focus to the group, once per focus.
-- %f / %t expand like chat does; {rtN} icons pass through. Silent when not
-- grouped, and when the focus is the one already announced.
-- 12.x "secret values": in PvP/combat the client may hand us GUIDs and
-- names we are not allowed to compare or concatenate. Never touch such a
-- value with Lua string operations; fall back to a time throttle instead.
local function IsSecret(v)
	return issecretvalue and v ~= nil and issecretvalue(v)
end

local lastAnnounced, lastTime = nil, 0
SLASH_MMFOCUS1 = "/mmfocus"
SlashCmdList.MMFOCUS = function(msg)
	if not UnitExists("focus") then return end
	local guid = UnitGUID("focus")
	if IsSecret(guid) then
		-- cannot tell whether it changed: just don't spam
		if GetTime() - lastTime < 5 then return end
		lastAnnounced = nil
	else
		if guid == lastAnnounced then return end
		lastAnnounced = guid
	end
	lastTime = GetTime()
	if not IsInGroup() then return end
	local text = strtrim(msg or "")
	if text == "" then return end
	-- expand %f / %t ourselves only when the names are plain strings;
	-- a secret name is left as %f for the chat system to expand
	local fname, tname = UnitName("focus"), UnitName("target")
	if fname and not IsSecret(fname) then text = text:gsub("%%f", fname) end
	if tname and not IsSecret(tname) then text = text:gsub("%%t", tname) end
	local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or (IsInRaid() and "RAID" or "PARTY")
	SendChatMessage(text, channel)
end

SLASH_MACROMASTER1 = "/macromaster"
SLASH_MACROMASTER2 = "/mmac"
SlashCmdList.MACROMASTER = function(msg)
	msg = strtrim(msg or ""):lower()
	if msg == "help" then
		ns.Msg(L["Slash help"])
	else
		ns.ToggleMain()
	end
end
