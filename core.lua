local _, core = ...

core.HS = "HS"
core.NON_HS = "NON-HS"
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
core.CONJURE_STONE_NAMES = {
  HS = "Create Healthstone",
  SS = "Create Soulstone",
  FS = "Create Firestone",
  SPELL_S = "Create Spellstone",
}
core.SUMMON_PET_NAMES = {
  SUMMON_VW = "Summon Voidwalker",
  SUMMON_SUCCUBUS = "Summon Succubus",
  SUMMON_FELHUNTER = "Summon Felhunter"
}
core.MISC_SPELL_NAMES = {
  SUMMON = "Ritual of Summoning",
  -- TODO: 
  ----> Enslave demon (add/test)
  ----> Anything else? 
}

-- Misc
core.PARTY_KILL  = "PARTY_KILL"
core.UNIT_DIED  = "UNIT_DIED"
core.SHADOWBURN = "Shadowburn"
core.RAID = "raid"
core.SHADOWBURN_DEBUFF_TIME = 5
core.AURA_APPLIED = "SPELL_AURA_APPLIED"
core.AURA_REMOVED = "SPELL_AURA_REMOVED"
core.DEFAULT_KILLED_TARGET_DATA = {
  time = -1,
  name = "Unkown",
  race = "Unknown",
  class = "Unknown",
  location = "Unknown",
  level = nil,
  is_boss = false
}

-- item_id of all stones
core.STONE_ID_TO_NAME = {
  [5512]  = 'Minor Healthstone',
  [19004] = 'Minor Healthstone',
  [19005] = 'Minor Healthstone',
  [5511]  = 'Lesser Healthstone',
  [19006] = 'Lesser Healthstone',
  [19007] = 'Lesser Healthstone',
  [5509]  = 'Healthstone',
  [19008] = 'Healthstone',
  [19009] = 'Healthstone',
  [5510]  = 'Greater Healthstone',
  [19010] = 'Greater Healthstone',
  [19011] = 'Greater Healthstone',
  [9421]  = 'Major Healthstone',
  [19012] = 'Major Healthstone',
  [19013] = 'Major Healthstone',
  [5232]  = 'Minor Soulstone',
  [16892] = 'Lesser Soulstone',
  [16893] = 'Soulstone',
  [16895] = 'Greater Soulstone',
  [16896] = 'Major Soulstone',
  [5522]  = 'Spellstone',
  [13602] = 'Greater Spellstone',
  [13603] = 'Major Spellstone',
  [1254]  = 'Lesser Firestone',
  [13699] = 'Firestone',
  [13700] = 'Greater Firestone',
  [13701] = 'Major Firestone'
}

-- soulstone ressurection spell_id to item_id
core.CONSUME_SS_SID_TO_IID = {
  [20707] = 5232,   -- minor 
  [20762] = 16892,  -- lesser
  [20763] = 16893,  -- regular
  [20764] = 16895,  -- greater
  [20765] = 16896   -- major
}

-- consume healthstone spell_id to item_id
core.CONSUME_HS_SID_TO_IID = {
  -- minor
  [6262] = 5512, 
  [23468] = 19004,
  [23469] = 19005,
  -- lesser
  [6263] = 5511, 
  [23470] = 19006,
  [23471] = 19007,
  -- regular
  [5720] = 5509, 
  [23472] = 19008,
  [23473] = 19009,
  -- greater
  [5723] = 5510, 
  [23474] = 19010,
  [23475] = 19011,
  -- major
  [11732] = 9421, 
  [23476] = 19012,
  [23477] = 19013,
}


core.CREATE_HS_SID = {
  [6201]  = "Create Healthstone (Minor)",
  [6202]  = "Create Healthstone (Lesser)",
  [5699]  = "Create Healthstone",
  [11729] = "Create Healthstone (Greater)",
  [11730] = "Create Healthstone (Major)"
}

-- HS mapped to consume HS spell_id
-- NON_HS mappted to item_id
core.SPELL_NAME_TO_ITEM_ID = {
  ["HS"] = {
    ["Create Healthstone (Minor)"]   = {
      [0] = 5512,
      [1] = 19004,
      [2] = 19005
    },
    ["Create Healthstone (Lesser)"]  = {
      [0] = 5511,
      [1] = 19006,
      [2] = 19007
    },
    ["Create Healthstone"]           = {
      [0] = 5509,
      [1] = 19008,
      [2] = 19009
    },
    ["Create Healthstone (Greater)"] = {
      [0] = 5510,
      [1] = 19010,
      [2] = 19011
    },
    ["Create Healthstone (Major)"]   = {
      [0] = 9421,
      [1] = 19012,
      [2] = 19013
    }
  },
  ["NON-HS"] = {
    ["Create Soulstone (Minor)"]     = 5232,
    ["Create Soulstone (Lesser)"]    = 16892,
    ["Create Soulstone"]             = 16893,
    ["Create Soulstone (Greater)"]   = 16895,
    ["Create Soulstone (Major)"]     = 16896,
    ["Create Spellstone"]            = 5522,
    ["Create Spellstone (Greater)"]  = 13602,
    ["Create Spellstone (Major)"]    = 13603,
    ["Create Firestone (Lesser)"]    = 1254,
    ["Create Firestone"]             = 13699,
    ["Create Firestone (Greater)"]   = 13700,
    ["Create Firestone (Major)"]     = 13701
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
    14507, -- 
    14510, -- 
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

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function get_npc_id(guid)
    local _, _, _, _, _, npc_id = strsplit("-", guid)
    return tonumber(npc_id)
end
core.get_npc_id = get_npc_id


local function is_boss(npc_id)
  if has_value(boss_id, npc_id) then
    return true
  end
  return false
end
core.is_boss = is_boss


--[[ Return player subzone and realzone as concatenated string --]]
function getPlayerZone()
    local real_zone = GetRealZoneText()
    local sub_zone = GetSubZoneText()
    if sub_zone ~= nil and sub_zone ~= real_zone and sub_zone ~= "" then
      return sub_zone .. ", " .. real_zone
    else
      return real_zone
    end
end
core.getPlayerZone = getPlayerZone

-- Create a deep copy of a table
function deep_copy(obj)
  if type(obj) ~= 'table' then return obj end
    local res = {}
      for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
        return res
end
core.deep_copy = deep_copy


--[[******* DEBUG TOOLS ********]]--
function print_table(my_table)
  for key, val in pairs(my_table) do
    print("KEY: " .. key)
    print("VALUE: " .. val)
  end
end
core.print_table = print_table


function print_shard_info(shard_mapping) 
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

