local _, core = ...

SOUL_BAG = 3
NORMAL_BAG = 0
SLOT_NULL  = 666
MAX_BAG_INDEX = 4
SOUL_SHARD_ID = 6265
UNIT_DIED  = "UNIT_DIED"
DRAIN_SOUL = "Drain Soul"
SPELL_NAMES = {
  -- TODO: List spells that consume shards
  HS = "Create Healthstone",
  SS = "Create Soulstone"
}

-- TODO: MOVE ALL THIS TO CONFIG FILE!!!
STONE_NAME = {}
-- HS
STONE_NAME["Create Healthstone (Minor)"] = "Minor Healthstone"
STONE_NAME["Create Healthstone (Lesser)"] = "Lesser Healthstone"
STONE_NAME["Create Healthstone"] = "Healthstone"
STONE_NAME["Create Healthstone (Greater)"] = "Greater Healthstone"
STONE_NAME["Create Healthstone (Major)"] = "Major Healthstone"
-- SS
STONE_NAME["Create Soulstone (Minor)"] = "Minor Soulstone"
STONE_NAME["Create Soulstone (Lesser)"] = "Lesser Soulstone"
STONE_NAME["Create Soulstone"] = "Soulstone"
STONE_NAME["Create Soulstone (Greater)"] = "Greater Soulstone"
STONE_NAME["Create Soulstone (Major)"] = "Major Soulstone"
-- Spellstone
STONE_NAME["Create Spellstone"] = "Spellstone"
STONE_NAME["Create Spellstone (Greater)"] = "Greater Spellstone"
STONE_NAME["Create Spellstone (Major)"] = "Major Spellstone"
-- Firestone
STONE_NAME["Create Firestone (Lesser)"] = "Lesser Firestone"
STONE_NAME["Create Firestone"] = "Firestone"
STONE_NAME["Create Firestone (Greater)"] = "Greater Firestone"
STONE_NAME["Create Firestone (Major)"] = "Major Firestone"

-- Return player subzone and realzone as concatenated string
function getPlayerZone()
    local real_zone = GetRealZoneText()
    local sub_zone = GetSubZoneText()
    if sub_zone ~= nil and sub_zone ~= real_zone and sub_zone ~= "" then
      return sub_zone .. ", " .. real_zone
    else
      return real_zone
    end
end

-- Create a deep copy of a table
function deep_copy(obj)
  if type(obj) ~= 'table' then return obj end
    local res = {}
      for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
        return res
end
