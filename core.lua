local _, core = ...

-- Bags
core.SLOT_NULL  = 666
core.MAX_BAG_INDEX = 4
core.SOUL_BAG_TYPE = 3
core.NORMAL_BAG_TYPE = 0

-- Spells
core.SOUL_SHARD_ID = 6265
core.DRAIN_SOUL = "Drain Soul"
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
core.UNIT_DIED  = "UNIT_DIED"
core.SHADOWBURN = "Shadowburn"
core.SHADOWBURN_DEBUFF_TIME = 5
core.AURA_APPLIED = "SPELL_AURA_APPLIED"
core.AURA_REMOVED = "SPELL_AURA_REMOVED"
core.DEFAULT_KILLED_TARGET_DATA = {
  time = -1,
  name = "<No_Data>",
  race = "<No_Data>",
  class = "<No_Data>",
  location = "<No_Data>"
  -- TODO: Add level if alliance?
}


-- item_id to stone_name
core.STONE_ID = {
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

-- Map stone creating name spell to created stone
core.STONE_NAME = {}

-- Healthstones items have 3 different ID's each; map to spell name instead
core.STONE_NAME["Create Healthstone (Minor)"] = "Minor Healthstone"
core.STONE_NAME["Create Healthstone (Lesser)"] = "Lesser Healthstone"
core.STONE_NAME["Create Healthstone"] = "Healthstone"
core.STONE_NAME["Create Healthstone (Greater)"] = "Greater Healthstone"
core.STONE_NAME["Create Healthstone (Major)"] = "Major Healthstone" 

-- Soulstone items all named 'Soulstone Resurrection'; map to spell ID instead
core.STONE_NAME["Create Soulstone (Minor)"] = 20707
core.STONE_NAME["Create Soulstone (Lesser)"] = 20762
core.STONE_NAME["Create Soulstone"] = 20763
core.STONE_NAME["Create Soulstone (Greater)"] = 20764
core.STONE_NAME["Create Soulstone (Major)"] = 20765

-- TODO: Test spellstone/firestone
core.STONE_NAME["Create Spellstone"] = "Spellstone"
core.STONE_NAME["Create Spellstone (Greater)"] = "Greater Spellstone"
core.STONE_NAME["Create Spellstone (Major)"] = "Major Spellstone"

core.STONE_NAME["Create Firestone (Lesser)"] = "Lesser Firestone"
core.STONE_NAME["Create Firestone"] = "Firestone"
core.STONE_NAME["Create Firestone (Greater)"] = "Greater Firestone"
core.STONE_NAME["Create Firestone (Major)"] = "Major Firestone"


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

