local _, core = ...

core.SOUL_BAG = 3
core.NORMAL_BAG = 0
core.SLOT_NULL  = 666
core.MAX_BAG_INDEX = 4
core.SOUL_SHARD_ID = 6265
core.UNIT_DIED  = "UNIT_DIED"
core.DRAIN_SOUL = "Drain Soul"
core.SPELL_NAMES = {
  -- TODO: List spells that consume shards
  HS = "Create Healthstone",
  SS = "Create Soulstone"
}

core.STONE_NAME = {}
-- HS
core.STONE_NAME["Create Healthstone (Minor)"] = "Minor Healthstone"
core.STONE_NAME["Create Healthstone (Lesser)"] = "Lesser Healthstone"
core.STONE_NAME["Create Healthstone"] = "Healthstone"
core.STONE_NAME["Create Healthstone (Greater)"] = "Greater Healthstone"
core.STONE_NAME["Create Healthstone (Major)"] = "Major Healthstone"
-- SS
core.STONE_NAME["Create Soulstone (Minor)"] = "Minor Soulstone"
core.STONE_NAME["Create Soulstone (Lesser)"] = "Lesser Soulstone"
core.STONE_NAME["Create Soulstone"] = "Soulstone"
core.STONE_NAME["Create Soulstone (Greater)"] = "Greater Soulstone"
core.STONE_NAME["Create Soulstone (Major)"] = "Major Soulstone"
-- Spellstone
core.STONE_NAME["Create Spellstone"] = "Spellstone"
core.STONE_NAME["Create Spellstone (Greater)"] = "Greater Spellstone"
core.STONE_NAME["Create Spellstone (Major)"] = "Major Spellstone"
-- Firestone
core.STONE_NAME["Create Firestone (Lesser)"] = "Lesser Firestone"
core.STONE_NAME["Create Firestone"] = "Firestone"
core.STONE_NAME["Create Firestone (Greater)"] = "Greater Firestone"
core.STONE_NAME["Create Firestone (Major)"] = "Major Firestone"

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
core.getPlayerZone = getPlayerZone

-- Create a deep copy of a table
function deep_copy(obj)
  if type(obj) ~= 'table' then return obj end
    local res = {}
      for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
        return res
end
core.deep_copy = deep_copy
