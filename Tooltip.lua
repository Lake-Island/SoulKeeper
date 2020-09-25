local _, core = ...

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
    tooltip:AddLine("Soul of <" .. curr_shard.name .. ">")

    -- TODO: Do the same for HS/SS/other stones
end

GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)

ItemRefTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
