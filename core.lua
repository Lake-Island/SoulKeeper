local _, core = ...

core.HS = "HS"
core.NON_HS = "NON-HS"
core.HEALTHSTONE = "Healthstone"
core.CHAT_TYPE_RAID = "RAID"
core.CHAT_TYPE_PARTY = "PARTY"
core.SS_MESSAGE = "%s, the soul of <%s> is yours!"
core.SUMMON_MESSAGE = "Summoning %s with the soul of <%s>, please assist!"

core.FIFTEEN_MINUTES = 900 -- seconds
core.FIND_HERBS_SID = 2383
core.RITUAL_OF_SUMM_SID = 698
core.SUCCESSFUL_SUMMON_DIFF  = 0.5 -- seconds
core.DRAIN_SOUL_DIFF = 1 -- seconds

-- Bags
core.SLOT_NULL  = 666
core.MAX_BAG_INDEX = 4
core.SOUL_BAG_TYPE = 3
core.NORMAL_BAG_TYPE = 0

-- Spells
core.SOUL_SHARD_ID = 6265
core.DRAIN_SOUL = "Drain Soul"
core.RITUAL_OF_SUMM = "Ritual of Summoning"

core.SUMMON_PET_SID = {
  [697] = "Summon Voidwalker",
  [712] = "Summon Succubus",
  [691] = "Summon Felhunter"
}

core.SOUL_FIRE_SID = { 6353, 17924 }
core.ENSLAVE_DEMON_SID = { 1098, 11725, 11726 }

-- Misc
core.PARTY_KILL  = "PARTY_KILL"
core.UNIT_DIED  = "UNIT_DIED"
core.SHADOWBURN = "Shadowburn"
core.RAID = "raid"
core.SHADOWBURN_DEBUFF_TIME = 5
core.AURA_APPLIED = "SPELL_AURA_APPLIED"
core.AURA_REMOVED = "SPELL_AURA_REMOVED"
core.DEFAULT_KILLED_TARGET_DATA = {
  id = -1,
  name = "Unknown",
  race = nil,
  class = nil,
  location = nil,
  is_player = false,
  is_boss = false,
  level = nil,
  faction_color = nil
}

local stone_iid = {
  -- Healthstone 
  M_HS_1 = 5512,
  M_HS_2 = 19004,
  M_HS_3 = 19005,
  L_HS_1 = 5511,
  L_HS_2 = 19006,
  L_HS_3 = 19007,
  HS_1   = 5509,
  HS_2   = 19008,
  HS_3   = 19009,
  G_HS_1 = 5510,
  G_HS_2 = 19010,
  G_HS_3 = 19011,
  MAJOR_HS_1 = 9421,
  MAJOR_HS_2 = 19012,
  MAJOR_HS_3 = 19013,
  -- Soulstone
  M_SS = 5232,
  L_SS = 16892,
  SS   = 16893,
  G_SS = 16895,
  MAJOR_SS = 16896,
  -- Spellstone/firestone
  SPELLSTONE = 5522,
  G_SPELLSTONE = 13602,
  M_SPELLSTONE = 13603,
  L_FIRESTONE = 1254,
  FIRESTONE   = 13699,
  G_FIRESTONE = 13700,
  M_FIRESTONE = 13701
}

-- item_id of all stones
core.STONE_IID_TO_NAME = {
  [stone_iid.M_HS_1] = 'Minor Healthstone',
  [stone_iid.M_HS_2] = 'Minor Healthstone',
  [stone_iid.M_HS_3] = 'Minor Healthstone',
  [stone_iid.L_HS_1] = 'Lesser Healthstone',
  [stone_iid.L_HS_2] = 'Lesser Healthstone',
  [stone_iid.L_HS_3] = 'Lesser Healthstone',
  [stone_iid.HS_1]   = 'Healthstone',
  [stone_iid.HS_2]   = 'Healthstone',
  [stone_iid.HS_3]   = 'Healthstone',
  [stone_iid.G_HS_1] = 'Greater Healthstone',
  [stone_iid.G_HS_2] = 'Greater Healthstone',
  [stone_iid.G_HS_3] = 'Greater Healthstone',
  [stone_iid.MAJOR_HS_1] = 'Major Healthstone',
  [stone_iid.MAJOR_HS_2] = 'Major Healthstone',
  [stone_iid.MAJOR_HS_3] = 'Major Healthstone',
  [stone_iid.M_SS]  = 'Minor Soulstone',
  [stone_iid.L_SS] = 'Lesser Soulstone',
  [stone_iid.SS] = 'Soulstone',
  [stone_iid.G_SS] = 'Greater Soulstone',
  [stone_iid.MAJOR_SS] = 'Major Soulstone',
  [stone_iid.SPELLSTONE]  = 'Spellstone',
  [stone_iid.G_SPELLSTONE] = 'Greater Spellstone',
  [stone_iid.M_SPELLSTONE] = 'Major Spellstone',
  [stone_iid.L_FIRESTONE]  = 'Lesser Firestone',
  [stone_iid.FIRESTONE] = 'Firestone',
  [stone_iid.G_FIRESTONE] = 'Greater Firestone',
  [stone_iid.M_FIRESTONE] = 'Major Firestone'
}


-- soulstone ressurection spell_id to item_id
core.CONSUME_SS_SID_TO_IID = {
  [20707] = stone_iid.M_SS,  -- minor 
  [20762] = stone_iid.L_SS,  -- lesser
  [20763] = stone_iid.SS,    -- regular
  [20764] = stone_iid.G_SS,  -- greater
  [20765] = stone_iid.MAJOR_SS   -- major
}


-- consume healthstone spell_id to item_id
core.CONSUME_HS_SID_TO_IID = {
  -- minor
  [6262]  = stone_iid.M_HS_1, 
  [23468] = stone_iid.M_HS_2,
  [23469] = stone_iid.M_HS_3,
  -- lesser
  [6263] = stone_iid.L_HS_1, 
  [23470] = stone_iid.L_HS_2,
  [23471] = stone_iid.L_HS_3,
  -- regular
  [5720] = stone_iid.HS_1, 
  [23472] = stone_iid.HS_2,
  [23473] = stone_iid.HS_3,
  -- greater
  [5723] = stone_iid.G_HS_1, 
  [23474] = stone_iid.G_HS_2,
  [23475] = stone_iid.G_HS_3,
  -- major
  [11732] = stone_iid.MAJOR_HS_1, 
  [23476] = stone_iid.MAJOR_HS_2,
  [23477] = stone_iid.MAJOR_HS_3,
}

core.CREATE_STONE_SID = {
  [6201]  = "Create Healthstone (Minor)",
  [6202]  = "Create Healthstone (Lesser)",
  [5699]  = "Create Healthstone",
  [11729] = "Create Healthstone (Greater)",
  [11730] = "Create Healthstone (Major)",
  [693]   = "Create Soulstone (Minor)",
  [20752] = "Create Soulstone (Lesser)",
  [20755] = "Create Soulstone",
  [20756] = "Create Soulstone (Greater)",
  [20757] = "Create Soulstone (Major)",
  [2362]  = "Create Spellstone",
  [17727] = "Create Spellstone (Greater)",
  [17728] = "Create Spellstone (Major)",
  [6366]  = "Create Firestone (Lesser)",
  [17951] = "Create Firestone",
  [17952] = "Create Firestone (Greater)",
  [17953] = "Create Firestone (Major)",
}


-- TODO: MOVE ME
local function is_spell_create_hs(spell_id)
  local spell_name = core.CREATE_STONE_SID[spell_id]
  if spell_name ~= nil and string.find(spell_name, core.HEALTHSTONE) then
    return true
  end
  return false
end
core.is_spell_create_hs = is_spell_create_hs


-- HS mapped to consume HS spell_id
-- NON_HS mappted to item_id
core.SPELL_NAME_TO_ITEM_ID = {
  ["HS"] = {
    ["Create Healthstone (Minor)"]   = {
      [0] = stone_iid.M_HS_1,
      [1] = stone_iid.M_HS_2,
      [2] = stone_iid.M_HS_3
    },
    ["Create Healthstone (Lesser)"]  = {
      [0] = stone_iid.L_HS_1,
      [1] = stone_iid.L_HS_2,
      [2] = stone_iid.L_HS_3
    },
    ["Create Healthstone"]           = {
      [0] = stone_iid.HS_1,
      [1] = stone_iid.HS_2,
      [2] = stone_iid.HS_3
    },
    ["Create Healthstone (Greater)"] = {
      [0] = stone_iid.G_HS_1,
      [1] = stone_iid.G_HS_2,
      [2] = stone_iid.G_HS_3
    },
    ["Create Healthstone (Major)"]   = {
      [0] = stone_iid.MAJOR_HS_1,
      [1] = stone_iid.MAJOR_HS_2,
      [2] = stone_iid.MAJOR_HS_3
    }
  },
  ["NON-HS"] = {
    ["Create Soulstone (Minor)"]     = stone_iid.M_SS,
    ["Create Soulstone (Lesser)"]    = stone_iid.L_SS,
    ["Create Soulstone"]             = stone_iid.SS,
    ["Create Soulstone (Greater)"]   = stone_iid.G_SS,
    ["Create Soulstone (Major)"]     = stone_iid.MAJOR_SS,
    ["Create Spellstone"]            = stone_iid.SPELLSTONE,
    ["Create Spellstone (Greater)"]  = stone_iid.G_SPELLSTONE,
    ["Create Spellstone (Major)"]    = stone_iid.M_SPELLSTONE,
    ["Create Firestone (Lesser)"]    = stone_iid.L_FIRESTONE,
    ["Create Firestone"]             = stone_iid.FIRESTONE,
    ["Create Firestone (Greater)"]   = stone_iid.G_FIRESTONE,
    ["Create Firestone (Major)"]     = stone_iid.M_FIRESTONE
  }
}

local boss_id = {
    10184, -- Onyxia
    12118, -- Lucifron
    12056, -- Geddon
    12057, -- Garr
    12259, -- Gehennas
    11988, -- Golemagg
    11982, -- Magmadar
    12018, -- Domo
    11502, -- Ragnaros
    12264, -- Shazzrah
    12098, -- Sulfuron
    12017, -- Broodlord
    14020, -- Chromaggus
    14601, -- Ebonroc
    11983, -- Firemaw
    11981, -- Flamegor
    11583, -- Nefarian
    12435, -- Razorgore
    13020, -- Vael
    15516, -- Sartura
    15727, -- Cthun
    15276, -- Veklor
    15275, -- Veknilash
    15510, -- Fankriss
    15511, -- Lord Kri
    15517, -- Ouro
    15509, -- Huhuran
    15543, -- Yauj
    15263, -- Skeram
    15544, -- Vem
    15299, -- Viscidus
    15956, -- Anub'Rekhan
    15932, -- Gluth
    16060, -- Gothik
    15953, -- Faerlina
    15931, -- Grobbulus
    15936, -- Heigan
    16062, -- Mograine
    16061, -- Razuvious
    15990, -- KelThuzad
    16065, -- Blaumeux
    16011, -- Loatheb
    15952, -- Maexxna
    15954, -- Noth
    16028, -- Patchwerk
    15989, -- Sapphiron
    16063, -- Zeliek
    15928, -- Thaddius
    16064, -- Korthazz
    -- TODO: Add 20man boss id
    14517, -- jeklik
    14507, -- Venoxis
    14510, -- Mar'li
    11382, -- Mandokir
    14834, -- hakkar
}


local class_colors = {
    ["Druid"] = "FF7D0A",
    ["Hunter"] = "A9D271",
    ["Mage"] = "40C7EB",
    ["Shaman"] = "F58CBA",
    ["Priest"] = "FFFFFF",
    ["Rogue"] = "FFF569",
    ["Warlock"] = "8787ED",
    ["Warrior"] = "C79C6E"
}

local horde_factions = { "Orc", "Undead", "Tauren", "Troll" }


local function list_contains(list, val)
    for index, value in ipairs(list) do
        if value == val then
            return true
        end
    end

    return false
end
core.list_contains = list_contains


local function is_faction_horde(race)
  if list_contains(horde_factions, race) then
    return true
  end
  return false
end
core.is_faction_horde = is_faction_horde


local function is_item_id_stone(item_id)
  if core.STONE_IID_TO_NAME[item_id] ~= nil then
    return true
  end
  return false
end
core.is_item_id_stone = is_item_id_stone


local function get_class_color(class_name)
  return class_colors[class_name]
end
core.get_class_color = get_class_color


local function get_npc_id(guid)
    local _, _, _, _, _, npc_id = strsplit("-", guid)
    return tonumber(npc_id)
end
core.get_npc_id = get_npc_id


local function is_boss(npc_id)
  if list_contains(boss_id, npc_id) then
    return true
  end
  return false
end
core.is_boss = is_boss


--[[ Return player subzone and realzone as concatenated string --]]
local function get_player_zone()
    local real_zone = GetRealZoneText()
    local sub_zone = GetSubZoneText()
    if sub_zone ~= nil and sub_zone ~= real_zone and sub_zone ~= "" then
      return sub_zone .. ", " .. real_zone
    else
      return real_zone
    end
end
core.get_player_zone = get_player_zone

-- Create a deep copy of a table
local function deep_copy(obj)
  if type(obj) ~= 'table' then return obj end
    local res = {}
      for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
        return res
end
core.deep_copy = deep_copy


local function table_contains(tab, value)
  if tab[value] ~= nil then
    return true
  end
  return false
end
core.table_contains = table_contains


local function is_player_in_raid()
  local _, instance_type = GetInstanceInfo()
  if instance_type == core.RAID then
    return true
  end
  return false
end
core.is_player_in_raid = is_player_in_raid


--[[******* DEBUG TOOLS ********]]--
local function print_table(my_table)
  for key, val in pairs(my_table) do
    print("KEY: " .. key)
    print("VALUE: " .. val)
  end
end
core.print_table = print_table


local function print_shard_info(shard_mapping) 
  for i=1, 5 do
    for j=1, 16 do
      if shard_mapping[i][j] ~= nil then
        print("Bag " .. i-1 .. " slot " .. j ..
       "\nKilled " .. shard_mapping[i][j].name
        .. "\n Location: " .. shard_mapping[i][j].location .. "\n - - - - - -") 
      end
    end
  end
end
core.print_shard_info = print_shard_info
