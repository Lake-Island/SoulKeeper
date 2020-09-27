local _, core = ...

-- TODO: Move to core
core.ORANGE = "|cFFE67D13"

local function GameTooltip_OnTooltipSetItem(tooltip)
    local itemName, itemLink = tooltip:GetItem()
    if not itemName or not itemLink then
        return
    end

    local _, itemId = strsplit(":", itemLink)
    itemId = tonumber(itemId)
    if itemId ~= core.SOUL_SHARD_ID then 
      return 
    end

    local focus = GetMouseFocus()
    if not (focus:GetName() or ""):match("ContainerFrame%d+Item%d+") then return end
    local bag_id, slot_id = focus:GetParent():GetID(), focus:GetID()
    bag_id = bag_id + 1 -- make up for 0 index

    local shard_mapping = core.get_shard_mapping()
    local curr_shard = shard_mapping[bag_id][slot_id]
    tooltip:AddLine(" ")
        --tooltip:AddLine("|cFF00FF00SU Loot Info|r")

    -- TODO: Add hex color codes to core
    if curr_shard.is_boss then -- boss
      tooltip:AddLine("Soul of " .. core.ORANGE .. curr_shard.name .. ">") --orange
    elseif curr_shard.level ~= nil then -- player
      -- TODO: Alliance(blue) vs Horde(red).. a
      tooltip:AddLine("Soul of |cFF58ACFA<" .. curr_shard.name .. ">") --blue
      print("LVL: " .. curr_shard.level)
    else -- other
      tooltip:AddLine("Soul of |cFF9F81F7<" .. curr_shard.name .. ">") --purple
    end

    -- TODO: Do the same for HS/SS/other stones
    -- TODO: Add all boss_ids to list in core
end

GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)

ItemRefTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
