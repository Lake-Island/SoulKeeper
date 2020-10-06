local _, core = ...


local function get_mouse_over_bag_slot() 
    local focus = GetMouseFocus()
    if not (focus:GetName() or ""):match("ContainerFrame%d+Item%d+") then return nil end
    local bag, slot = focus:GetParent():GetID(), focus:GetID()
    bag = bag + 1 -- make up for 0 index
    return bag, slot
end


local function display_soul_data(tooltip, soul)
  tooltip:AddLine(" ")
  if soul == nil then return end
  if soul.is_boss then 
    tooltip:AddLine(string.format(core.SOUL_OF, core.ORANGE, soul.name))
    tooltip:AddLine(string.format(core.RAID_BOSS, core.RED))
  elseif soul.is_player then  
    local class_color = core.get_class_color(soul.class)
    tooltip:AddLine(string.format(core.SOUL_OF, class_color, soul.name))
    tooltip:AddLine(string.format(core.PLAYER_DETAILS, soul.faction_color, soul.level, soul.race, soul.class))
    tooltip:AddLine(string.format(core.PLAYER_QUOTE, core.UNMELLOW_YELLOW, soul.emote))
  else 
    tooltip:AddLine(string.format(core.SOUL_OF, core.PURPLE, soul.name))
  end
  tooltip:AddLine(" ")
end


local function GameTooltip_OnTooltipSetItem(tooltip)
    local bag, slot = get_mouse_over_bag_slot()
    if bag == nil or slot == nil then return end

    local _, item_link = tooltip:GetItem()
    if not item_link then return end

    local _, item_id = strsplit(":", item_link)
    item_id = tonumber(item_id)
    if item_id == core.SOUL_SHARD_ID then 
      local shard_mapping = core.get_shard_mapping()
      local soul = shard_mapping[bag][slot]
      display_soul_data(tooltip, soul)
    elseif core.is_item_id_stone(item_id) then
      local stone_mapping = core.get_stone_mapping()
      local soul = stone_mapping[item_id]
      display_soul_data(tooltip, soul)
    end
end


GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)

ItemRefTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
