local _, core = ...

-- Bags
core.MAX_BAG_INDEX = 4
core.SOUL_BAG_TYPE = 3
core.NORMAL_BAG_TYPE = 0

-- Misc
core.DRAIN_SOUL = "Drain Soul"
core.UNIT_DIED  = "UNIT_DIED"
core.SOUL_SHARD_ID = 6265


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
