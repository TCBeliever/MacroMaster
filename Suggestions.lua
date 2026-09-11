local ADDON, ns = ...
local L = ns.L

-- ---------------------------------------------------------------------------
-- Spell suggestion table
--
-- Per class, per category, a list of spell IDs. Everything is resolved at
-- runtime: an ID the client no longer knows, or a spell this character does
-- not have (other spec, talent not taken, removed in a patch) is simply not
-- shown. A stale table therefore degrades to "fewer suggestions", never to
-- an error — the picker and the templates keep working across expansions.
--
-- The user can edit the list for the current class in-game (Spell table
-- window); edits live in MacroMasterDB.suggestions[CLASS][CATEGORY] and
-- replace the shipped list for that class+category only.
-- ---------------------------------------------------------------------------

ns.categories = { "INTERRUPT", "CC", "DEFENSIVE", "BURST", "MOVEMENT", "GROUND", "HEAL", "DISPEL", "PURGE", "EXTERNAL", "SELFHEAL" }

-- placeholder key -> category (keys equal to a category map to themselves)
ns.categoryAliases = {
	KICK = "INTERRUPT", CD = "BURST", DEF = "DEFENSIVE", MOVE = "MOVEMENT", AOE = "GROUND",
	CLEANSE = "DISPEL", DECURSE = "DISPEL", OFFDISPEL = "PURGE", EXT = "EXTERNAL", SAVE = "EXTERNAL",
}

ns.shippedSuggestions = {
	EVOKER = {
		INTERRUPT = { 351338 },                                  -- Quell
		CC        = { 360806, 358385, 372048, 357214, 368970 },  -- Sleep Walk, Landslide, Oppressing Roar, Wing Buffet, Tail Swipe
		DEFENSIVE = { 363916, 374348, 374227, 370960 },          -- Obsidian Scales, Renewing Blaze, Zephyr, Emerald Communion
		BURST     = { 375087, 357208, 357210, 370553, 403631 },  -- Dragonrage, Fire Breath, Deep Breath, Tip the Scales, Breath of Eons
		MOVEMENT  = { 358267, 370665 },                          -- Hover, Rescue
		GROUND    = { 357210, 358385, 403631 },                  -- Deep Breath, Landslide, Breath of Eons
		HEAL      = { 355913, 364343, 361469, 366155 },          -- Emerald Blossom, Echo, Living Flame, Reversion
		DISPEL    = { 360823, 365585, 374251 },                  -- Naturalize, Expunge, Cauterizing Flame
		EXTERNAL  = { 370665, 357170, 360827, 374227 },          -- Rescue, Time Dilation, Blistering Scales, Zephyr
		SELFHEAL  = { 360995, 355913, 361469 },                          -- Verdant Embrace, Emerald Blossom, Living Flame
	},
	DEATHKNIGHT = {
		INTERRUPT = { 47528 },                                   -- Mind Freeze
		CC        = { 221562, 49576, 207167, 47476, 108199 },    -- Asphyxiate, Death Grip, Blinding Sleet, Strangulate, Gorefiend's Grasp
		DEFENSIVE = { 48707, 48792, 49039, 48743, 55233, 49028, 194679 }, -- AMS, IBF, Lichborne, Death Pact, Vampiric Blood, DRW, Rune Tap
		BURST     = { 51271, 47568, 63560, 42650, 207289, 275699, 279302 }, -- Pillar of Frost, ERW, Dark Transformation, Army, Unholy Assault, Apocalypse, Frostwyrm's Fury
		MOVEMENT  = { 48265, 212552 },                           -- Death's Advance, Wraith Walk
		GROUND    = { 43265, 152280 },                           -- Death and Decay, Defile
		EXTERNAL  = { 51052 },                                   -- Anti-Magic Zone
		SELFHEAL  = { 49998, 48743, 59545 },                             -- Death Strike, Death Pact, Gift of the Naaru
	},
	DEMONHUNTER = {
		INTERRUPT = { 183752 },                                  -- Disrupt
		CC        = { 217832, 179057, 207684, 202137, 211881, 202138 }, -- Imprison, Chaos Nova, Sigil of Misery, Sigil of Silence, Fel Eruption, Sigil of Chains
		DEFENSIVE = { 198589, 196718, 196555, 204021, 203720, 187827 }, -- Blur, Darkness, Netherwalk, Fiery Brand, Demon Spikes, Metamorphosis (Vengeance)
		BURST     = { 191427, 198013, 370965, 258920 },          -- Metamorphosis (Havoc), Eye Beam, The Hunt, Immolation Aura
		MOVEMENT  = { 195072, 198793, 189110 },                  -- Fel Rush, Vengeful Retreat, Infernal Strike
		GROUND    = { 204596, 202137, 207684, 202138, 189110, 191427 }, -- Sigil of Flame, Silence, Misery, Chains, Infernal Strike, Metamorphosis
		PURGE     = { 278326 },                                  -- Consume Magic
		EXTERNAL  = { 196718 },                                  -- Darkness
	},
	DRUID = {
		INTERRUPT = { 106839, 78675 },                           -- Skull Bash, Solar Beam
		CC        = { 33786, 339, 2637, 5211, 99, 132469, 102359, 22570 }, -- Cyclone, Roots, Hibernate, Mighty Bash, Incap Roar, Typhoon, Mass Entanglement, Maim
		DEFENSIVE = { 22812, 61336, 22842, 102342, 108238 },     -- Barkskin, Survival Instincts, Frenzied Regen, Ironbark, Renewal
		BURST     = { 106951, 102543, 194223, 102560, 391528, 5217 }, -- Berserk, Incarnation (Feral), Celestial Alignment, Incarnation (Balance), Convoke, Tiger's Fury
		MOVEMENT  = { 1850, 102401, 106898 },                    -- Dash, Wild Charge, Stampeding Roar
		GROUND    = { 102793, 145205, 102359 },                  -- Ursol's Vortex, Efflorescence, Mass Entanglement
		HEAL      = { 774, 8936, 18562, 33763, 48438 },          -- Rejuvenation, Regrowth, Swiftmend, Lifebloom, Wild Growth
		DISPEL    = { 88423, 2782 },                             -- Nature's Cure, Remove Corruption
		PURGE     = { 2908 },                                    -- Soothe
		EXTERNAL  = { 102342, 29166, 106898 },                   -- Ironbark, Innervate, Stampeding Roar
		SELFHEAL  = { 108238, 8936, 22842, 774 },                        -- Renewal, Regrowth, Frenzied Regeneration, Rejuvenation
	},
	PRIEST = {
		INTERRUPT = { 15487 },                                   -- Silence
		CC        = { 8122, 605, 64044, 9484, 88625 },           -- Psychic Scream, Mind Control, Psychic Horror, Shackle Undead, Chastise
		DEFENSIVE = { 19236, 47585, 586, 33206, 47788, 15286 },  -- Desperate Prayer, Dispersion, Fade, Pain Suppression, Guardian Spirit, Vampiric Embrace
		BURST     = { 34433, 200174, 228260, 391109, 10060, 200183, 246287 }, -- Shadowfiend, Mindbender, Void Eruption, Dark Ascension, Power Infusion, Apotheosis, Evangelism
		MOVEMENT  = { 121536, 73325 },                           -- Angelic Feather, Leap of Faith
		GROUND    = { 205385, 121536, 34861 },                   -- Shadow Crash, Angelic Feather, Holy Word: Sanctify
		HEAL      = { 17, 2061, 2060, 139, 33076, 596, 47540 },   -- PW:Shield, Flash Heal, Heal, Renew, Prayer of Mending, Prayer of Healing, Penance
		DISPEL    = { 527, 213634, 32375 },                      -- Purify, Purify Disease, Mass Dispel
		PURGE     = { 528, 32375 },                              -- Dispel Magic, Mass Dispel
		EXTERNAL  = { 33206, 47788, 17, 10060, 73325, 121536 },  -- Pain Suppression, Guardian Spirit, PW:Shield, Power Infusion, Leap of Faith, Angelic Feather
		SELFHEAL  = { 19236, 2061, 139, 17, 59544 },                     -- Desperate Prayer, Flash Heal, Renew, Power Word: Shield, Gift of the Naaru
	},
	ROGUE = {
		INTERRUPT = { 1766 },                                    -- Kick
		CC        = { 408, 1833, 2094, 6770, 1776 },             -- Kidney Shot, Cheap Shot, Blind, Sap, Gouge
		DEFENSIVE = { 31224, 5277, 1966, 185311, 1856 },         -- Cloak of Shadows, Evasion, Feint, Crimson Vial, Vanish
		BURST     = { 13750, 121471, 185313, 360194, 13877, 212283 }, -- Adrenaline Rush, Shadow Blades, Shadow Dance, Deathmark, Blade Flurry, Symbols of Death
		MOVEMENT  = { 2983, 36554, 195457 },                     -- Sprint, Shadowstep, Grappling Hook
		GROUND    = { 195457, 1725, 212182 },                    -- Grappling Hook, Distract, Smoke Bomb
		EXTERNAL  = { 57934, 114018 },                           -- Tricks of the Trade, Shroud of Concealment
		SELFHEAL  = { 185311, 370626 },                                  -- Crimson Vial, Gift of the Naaru
	},
	PALADIN = {
		INTERRUPT = { 96231 },                                   -- Rebuke
		CC        = { 853, 115750, 20066, 10326 },               -- Hammer of Justice, Blinding Light, Repentance, Turn Evil
		DEFENSIVE = { 642, 498, 403876, 31850, 86659, 633, 1022, 6940 }, -- Divine Shield, Divine Protection (x2), Ardent Defender, GoAK, Lay on Hands, BoP, BoSac
		BURST     = { 31884, 231895, 255937, 375576, 389539 },   -- Avenging Wrath, Crusade, Wake of Ashes, Divine Toll, Sentinel
		MOVEMENT  = { 190784 },                                  -- Divine Steed
		HEAL      = { 19750, 82326, 20473, 85673, 53563 },       -- Flash of Light, Holy Light, Holy Shock, Word of Glory, Beacon of Light
		DISPEL    = { 4987, 213644 },                            -- Cleanse, Cleanse Toxins
		EXTERNAL  = { 1022, 6940, 1044, 204018, 633, 53563 },    -- Blessing of Protection, Sacrifice, Freedom, Spellwarding, Lay on Hands, Beacon of Light
		SELFHEAL  = { 85673, 19750, 20473, 633, 59542 },                 -- Word of Glory, Flash of Light, Holy Shock, Lay on Hands, Gift of the Naaru
	},
	WARRIOR = {
		INTERRUPT = { 6552 },                                    -- Pummel
		CC        = { 107570, 46968, 5246, 376079, 12323 },      -- Storm Bolt, Shockwave, Intimidating Shout, Champion's Spear, Piercing Howl
		DEFENSIVE = { 871, 12975, 118038, 184364, 23920, 190456, 97462, 383762, 386208 }, -- Shield Wall, Last Stand, Die by the Sword, Enraged Regen, Spell Reflection, Ignore Pain, Rallying Cry, Bitter Immunity, Defensive Stance
		BURST     = { 107574, 227847, 46924, 1719, 167105, 262161, 228920, 384318, 385059 }, -- Avatar, Bladestorm (Arms), Bladestorm (Fury), Recklessness, Colossus Smash, Warbreaker, Ravager, Thunderous Roar, Odyn's Fury
		MOVEMENT  = { 100, 6544, 3411 },                         -- Charge, Heroic Leap, Intervene
		GROUND    = { 6544, 228920, 376079 },                    -- Heroic Leap, Ravager, Champion's Spear
		EXTERNAL  = { 3411, 97462 },                             -- Intervene, Rallying Cry
		SELFHEAL  = { 383762, 184364, 202168, 34428, 28880 },            -- Bitter Immunity, Enraged Regeneration, Impending Victory, Victory Rush, Gift of the Naaru
	},
	MAGE = {
		INTERRUPT = { 2139 },                                    -- Counterspell
		CC        = { 118, 122, 31661, 113724, 157981, 157997, 33395 }, -- Polymorph, Frost Nova, Dragon's Breath, Ring of Frost, Blast Wave, Ice Nova, Freeze (pet)
		DEFENSIVE = { 45438, 414659, 11426, 235313, 235450, 342245, 55342, 110959 }, -- Ice Block, Ice Cold, Ice Barrier, Blazing Barrier, Prismatic Barrier, Alter Time, Mirror Image, Greater Invisibility
		BURST     = { 190319, 12472, 365350, 80353, 84714, 382440, 153595, 153561 }, -- Combustion, Icy Veins, Arcane Surge, Time Warp, Frozen Orb, Shifting Power, Comet Storm, Meteor
		MOVEMENT  = { 1953, 212653, 108839, 389713 },            -- Blink, Shimmer, Ice Floes, Displacement
		GROUND    = { 190356, 2120, 153561, 113724 },            -- Blizzard, Flamestrike, Meteor, Ring of Frost
		DISPEL    = { 475 },                                     -- Remove Curse
		PURGE     = { 30449 },                                   -- Spellsteal
		EXTERNAL  = { 414660 },                                  -- Mass Barrier
		SELFHEAL  = { 59548 },                                           -- Gift of the Naaru
	},
	WARLOCK = {
		INTERRUPT = { 19647, 119910, 89766 },                    -- Spell Lock, Command Demon, Axe Toss
		CC        = { 5782, 5484, 6789, 30283, 710 },            -- Fear, Howl of Terror, Mortal Coil, Shadowfury, Banish
		DEFENSIVE = { 104773, 108416, 212295, 6789 },            -- Unending Resolve, Dark Pact, Nether Ward, Mortal Coil
		BURST     = { 1122, 205180, 265187, 113860, 113858, 111898, 386997, 278350 }, -- Summon Infernal, Summon Darkglare, Summon Demonic Tyrant, Dark Soul: Misery, Dark Soul: Instability, Grimoire: Felguard, Soul Rot, Vile Taint
		MOVEMENT  = { 48020, 111400, 111771 },                   -- Demonic Circle: Teleport, Burning Rush, Demonic Gateway
		GROUND    = { 5740, 30283, 152108, 278350, 48018, 111771, 1122 }, -- Rain of Fire, Shadowfury, Cataclysm, Vile Taint, Demonic Circle, Demonic Gateway, Summon Infernal
		DISPEL    = { 119905, 89808 },                           -- Command Demon, Singe Magic (imp)
		PURGE     = { 19505 },                                   -- Devour Magic (felhunter)
		EXTERNAL  = { 20707, 111771 },                           -- Soulstone, Demonic Gateway
		SELFHEAL  = { 234153, 108416, 416250 },                          -- Drain Life, Dark Pact, Gift of the Naaru
	},
	HUNTER = {
		INTERRUPT = { 147362, 187707 },                          -- Counter Shot, Muzzle
		CC        = { 187650, 19577, 109248, 213691, 186387, 187698, 5116 }, -- Freezing Trap, Intimidation, Binding Shot, Scatter Shot, Bursting Shot, Tar Trap, Concussive Shot
		DEFENSIVE = { 186265, 109304, 264735, 5384, 53480 },     -- Aspect of the Turtle, Exhilaration, Survival of the Fittest, Feign Death, Roar of Sacrifice
		BURST     = { 19574, 359844, 288613, 360952, 257044, 260243, 212431 }, -- Bestial Wrath, Call of the Wild, Trueshot, Coordinated Assault, Rapid Fire, Volley, Explosive Shot
		MOVEMENT  = { 781, 186257, 190925 },                     -- Disengage, Aspect of the Cheetah, Harpoon
		GROUND    = { 187650, 187698, 109248, 236776, 260243, 1543 }, -- Freezing Trap, Tar Trap, Binding Shot, High Explosive Trap, Volley, Flare
		HEAL      = { 136, 109304 },                             -- Mend Pet, Exhilaration
		PURGE     = { 19801 },                                   -- Tranquilizing Shot
		EXTERNAL  = { 34477, 53480 },                            -- Misdirection, Roar of Sacrifice
		SELFHEAL  = { 109304, 59543 },                                   -- Exhilaration, Gift of the Naaru
	},
	SHAMAN = {
		INTERRUPT = { 57994 },                                   -- Wind Shear
		CC        = { 192058, 51514, 51490, 51485, 305483, 197214 }, -- Capacitor Totem, Hex, Thunderstorm, Earthgrab Totem, Lightning Lasso, Sundering
		DEFENSIVE = { 108271, 198103, 98008, 108280, 108270, 198838 }, -- Astral Shift, Earth Elemental, Spirit Link Totem, Healing Tide Totem, Stone Bulwark Totem, Earthen Wall Totem
		BURST     = { 114050, 114051, 114052, 191634, 320137, 198067, 192249, 51533, 384352, 375982, 2825, 32182 }, -- Ascendance (x3), Stormkeeper (x2), Fire Elemental, Storm Elemental, Feral Spirit, Doom Winds, Primordial Wave, Bloodlust, Heroism
		MOVEMENT  = { 58875, 192063, 2645 },                     -- Spirit Walk, Gust of Wind, Ghost Wolf
		GROUND    = { 61882, 73920, 207778, 192222, 207399 },    -- Earthquake, Healing Rain, Downpour, Liquid Magma Totem, Ancestral Protection Totem
		HEAL      = { 61295, 8004, 77472, 1064, 73920, 73685, 108280 }, -- Riptide, Healing Surge, Healing Wave, Chain Heal, Healing Rain, Unleash Life, Healing Tide Totem
		DISPEL    = { 77130, 51886, 383013 },                    -- Purify Spirit, Cleanse Spirit, Poison Cleansing Totem
		PURGE     = { 370, 378773 },                             -- Purge, Greater Purge
		EXTERNAL  = { 98008, 198838, 108281, 192077 },           -- Spirit Link Totem, Earthen Wall Totem, Ancestral Guidance, Wind Rush Totem
		SELFHEAL  = { 8004, 61295, 77472, 59547 },                       -- Healing Surge, Riptide, Healing Wave, Gift of the Naaru
	},
	MONK = {
		INTERRUPT = { 116705 },                                  -- Spear Hand Strike
		CC        = { 119381, 115078, 116844, 198898, 324312 },  -- Leg Sweep, Paralysis, Ring of Peace, Song of Chi-Ji, Clash
		DEFENSIVE = { 122470, 115203, 122783, 122278, 115176, 322507, 116849, 115310 }, -- Touch of Karma, Fortifying Brew, Diffuse Magic, Dampen Harm, Zen Meditation, Celestial Brew, Life Cocoon, Revival
		BURST     = { 137639, 123904, 132578, 322118, 325197, 322109, 387184, 392983, 443028, 325153, 116680, 386276 }, -- Storm Earth and Fire, Invoke Xuen, Invoke Niuzao, Invoke Yu'lon, Invoke Chi-Ji, Touch of Death, Weapons of Order, Strike of the Windlord, Celestial Conduit, Exploding Keg, Thunder Focus Tea, Bonedust Brew
		MOVEMENT  = { 109132, 115008, 101545, 101643, 119996, 116841 }, -- Roll, Chi Torpedo, Flying Serpent Kick, Transcendence, Transcendence: Transfer, Tiger's Lust
		GROUND    = { 116844, 115313, 115315, 325153 },          -- Ring of Peace, Jade Serpent Statue, Black Ox Statue, Exploding Keg
		HEAL      = { 116670, 124682, 115151, 115175, 116849, 115310, 322101 }, -- Vivify, Enveloping Mist, Renewing Mist, Soothing Mist, Life Cocoon, Revival, Expel Harm
		DISPEL    = { 115450, 218164 },                          -- Detox (Mistweaver), Detox
		EXTERNAL  = { 116849, 116841 },                          -- Life Cocoon, Tiger's Lust
		SELFHEAL  = { 322101, 116670, 122281, 121093 },                  -- Expel Harm, Vivify, Healing Elixir, Gift of the Naaru
	},
}

function ns.CategoryForKey(key, meta)
	if meta and meta.category then return meta.category end
	local up = key:upper()
	if ns.categoryAliases[up] then return ns.categoryAliases[up] end
	for _, c in ipairs(ns.categories) do
		if c == up then return c end
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Item placeholders
--
-- {HEALTHSTONE} and {POTION} (alias HEALPOT) are filled from the bags, not
-- the spell book. The lists below only rank what to suggest first: the picker
-- also shows every usable item in the bags, and an ID the client no longer
-- knows simply never shows up. Values are item names, so any rank of a potion
-- satisfies the macro.
-- ---------------------------------------------------------------------------

ns.itemCategoryAliases = { HEALTHSTONE = "HEALTHSTONE", POTION = "HEALPOT", HEALPOT = "HEALPOT" }

ns.shippedItemSuggestions = {
	HEALTHSTONE = { 224464, 5512 },   -- Demonic Healthstone, Healthstone
	HEALPOT = {                       -- strongest first; ranks share a name and collapse into one entry
		271884, 271883,               -- Concentrated Silvermoon Health Potion (Midnight)
		241304, 241305,               -- Silvermoon Health Potion
		245918, 245919,               -- Fleeting Silvermoon Health Potion
		258138,                       -- Potent Healing Potion
		244839, 244838, 244835,       -- Invigorating Healing Potion (The War Within)
		211880, 211879, 211878,       -- Algari Healing Potion
		244849, 244848, 244847,       -- Fleeting Invigorating Healing Potion
		212944, 212943, 212942,       -- Fleeting Algari Healing Potion
		241306, 241307,               -- Refreshing Serum (heal + secondary effect)
		212244, 212243, 212242,       -- Cavedweller's Delight
	},
}

-- Item category for a placeholder key, or nil when it is a spell/text key.
function ns.ItemCategoryForKey(key, meta)
	if meta and meta.item then return meta.category or "ITEM" end
	return ns.itemCategoryAliases[key:upper()]
end

local function ItemEntry(id)
	local name = C_Item.GetItemNameByID(id)
	if not name then return nil end
	return { id = id, name = name, icon = C_Item.GetItemIconByID(id), item = true }
end

-- Suggested items of `category` that are in the bags right now, best first,
-- one entry per name.
function ns.ResolveItemSuggestions(category)
	local out, seen = {}, {}
	for _, id in ipairs(ns.shippedItemSuggestions[category] or {}) do
		if (C_Item.GetItemCount(id) or 0) > 0 then
			local e = ItemEntry(id)
			if e and not seen[e.name] then
				seen[e.name] = true
				out[#out + 1] = e
			end
		end
	end
	return out
end

function ns.BestItemForCategory(category)
	local list = ns.ResolveItemSuggestions(category)
	return list[1] and list[1].name
end

-- value is "item:1234" or a name; true when at least one is in the bags.
function ns.IsItemInBags(value)
	if not value or value == "" then return false end
	local id = value:match("^item:(%d+)$")
	local count = C_Item.GetItemCount(id and tonumber(id) or value)
	return (count or 0) > 0
end

local function PlayerClass()
	local _, class = UnitClass("player")
	return class
end

local function CopyList(list)
	local out = {}
	for i, v in ipairs(list or {}) do out[i] = v end
	return out
end

-- Raw ID list for the current class (user override, else shipped).
function ns.GetSuggestionIDs(category)
	local class = PlayerClass()
	local db = ns.db.suggestions and ns.db.suggestions[class]
	if db and db[category] then return db[category], true end
	local shipped = ns.shippedSuggestions[class]
	return CopyList(shipped and shipped[category]), false
end

function ns.IsSuggestionCustomized(category)
	local _, custom = ns.GetSuggestionIDs(category)
	return custom
end

local function EnsureCustom(category)
	local class = PlayerClass()
	ns.db.suggestions = ns.db.suggestions or {}
	ns.db.suggestions[class] = ns.db.suggestions[class] or {}
	if not ns.db.suggestions[class][category] then
		ns.db.suggestions[class][category] = ns.GetSuggestionIDs(category)
	end
	return ns.db.suggestions[class][category]
end

function ns.AddSuggestion(category, spellID)
	local list = EnsureCustom(category)
	for _, id in ipairs(list) do if id == spellID then return false end end
	list[#list + 1] = spellID
	return true
end

function ns.RemoveSuggestion(category, spellID)
	local list = EnsureCustom(category)
	for i, id in ipairs(list) do
		if id == spellID then table.remove(list, i); return true end
	end
	return false
end

function ns.ResetSuggestions(category)
	local class = PlayerClass()
	if ns.db.suggestions and ns.db.suggestions[class] then
		ns.db.suggestions[class][category] = nil
	end
end

-- Spells this character can actually cast right now.
local function IsKnown(spellID, name)
	if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
	if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then return true end
	return ns.IsSpellKnownByName(name)
end

-- Resolved list { {id, name, icon, known}, ... }. Unknown IDs (removed from
-- the game) are dropped; `onlyKnown` also drops spells this character lacks.
function ns.ResolveSuggestions(category, onlyKnown)
	local out = {}
	for _, id in ipairs(ns.GetSuggestionIDs(category)) do
		local info = C_Spell.GetSpellInfo(id)
		if info and info.name then
			local known = IsKnown(id, info.name)
			if known or not onlyKnown then
				out[#out + 1] = { id = id, name = info.name, icon = info.iconID, known = known }
			end
		end
	end
	return out
end
