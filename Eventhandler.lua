local _, core = ...

shard_mapping = { {}, {}, {}, {}, {} }
stone_mapping = {}
logout_time = nil
enable_chat = false
local last_bag_update_time = nil
local shard_added = false
local stone_deleted = false
local shard_deleted = false
local player_in_raid_instance = false
local locked_shards = {}
local locked_stone_iid = {}
local active_target_map = {}
local next_open_shard_slot = {}
local total_active_targets = 0
local last_shard_unlock_time = 0

local current_target = {
  guid = nil,
  name = nil
}

local previous_spellcast = {
  id = nil,
  time = nil
}

local drain_soul_end_t = nil
local drain_soul_data = { 
  casting = false,
  target_guid = ""
}

local summon_details = { 
  end_time = nil,
  location = nil 
}

local shadowburn_data = {
  applied = false,
  application_time = nil,
  end_time = nil,
  target_guid = ""
}

local killed_target = {
  id = -1,
  name = nil,
  race = nil,
  class = nil,
  location = nil,
  is_player = false,
  is_boss = false,
  level = nil,
  faction_color = nil
}


local function get_shard(bag, slot)
  return shard_mapping[bag][slot]
end


local function set_shard(bag, slot, val)
  shard_mapping[bag][slot] = val
end


local function get_stone(stone_iid)
  return stone_mapping[stone_iid]
end


local function set_stone(stone_iid, val)
  stone_mapping[stone_iid] = val
end


local function set_previous_spellcast_data(spell_id, curr_time)
  previous_spellcast.id = spell_id
  previous_spellcast.time = curr_time
end


local function add_active_target(tar_guid, data)
  if active_target_map[tar_guid] ~= nil then return end
  if total_active_targets > core.ACTIVE_TARGET_THRESHOLD then
    active_target_map = {}
    total_active_targets = 0
  end
  active_target_map[tar_guid] = data
  total_active_targets = total_active_targets + 1
end


local function remove_active_target(tar_guid)
  active_target_map[tar_guid] = nil
  total_active_targets = total_active_targets - 1
end


local function reset_killed_target_data()
  killed_target = {
    id = -1,
    name = nil,
    race = nil,
    class = nil,
    location = nil,
    is_player = false,
    is_boss = false,
    level = nil,
    faction_color = nil
  }
end


local function reset_summon_details()
  summon_details = {
    end_time = nil,
    location = nil
  }
end


local function reset_shadowburn_data()
  shadowburn_data = {
    applied = false,
    application_time = nil,
    end_time = nil,
    target_guid = ""
  }
end


local function set_shadowburn_data(dest_guid, time)
  shadowburn_data = {
    applied = true,
    application_time = time,
    end_time = time + core.SHADOWBURN_DEBUFF_TIME,
    target_guid = dest_guid
  }
end


local function reset_drain_soul_data()
  drain_soul_data = { 
    casting = false,
    target_guid = ""
  }
end


--[[ Total points into improved healthstone ]]--
local function get_total_pts_imp_hs()
    _, _, _, _, total_pts = GetTalentInfo(2,1,1)
    return total_pts
end


--[[ Map unmapped shards ]]--
local function set_default_shard_data()
  for bag_num = 0, core.MAX_BAG_INDEX, 1 do
    local num_bag_slots = GetContainerNumSlots(bag_num)
    for slot_num = 1, num_bag_slots, 1 do
      local curr_item_id = GetContainerItemID(bag_num, slot_num)
      local curr_shard_slot = get_shard(bag_num+1, slot_num)
      if curr_item_id == core.SOUL_SHARD_ID and curr_shard_slot == nil then
        set_shard(bag_num+1, slot_num, core.deep_copy(core.DEFAULT_KILLED_TARGET_DATA))
      end
    end
  end 
end


--[[ 
 TODO: REMOVE ME ------------------------------------------------------
  Sets shard data to nubmers for testting
]]--
local function set_shard_data()
  local count = 1
  shard_mapping = { {}, {}, {}, {}, {} }
  for bag_num = 0, core.MAX_BAG_INDEX, 1 do
    local num_bag_slots = GetContainerNumSlots(bag_num)
    for slot_num = 1, num_bag_slots, 1 do
      local curr_item_id = GetContainerItemID(bag_num, slot_num)
      --curr_shard_slot = shard_mapping[bag_num+1][slot_num]
      local curr_shard_slot = get_shard(bag_num+1,slot_num)
      -- unmapped soul shard; map it.
      if curr_item_id == core.SOUL_SHARD_ID then
        local test_data = nil
        if count == 1 then
          test_data = { 
            name="Guy", race="Human", class="Mage", location="somewhere",is_player = true, level = 60, is_boss = false, faction_color = core.ALLIANCE_BLUE 
          }
        elseif count == 2 then
          test_data = { 
            name="Krel", race="Undead", class="Warlock", location="somewhere", is_player = true, level = 60, is_boss = false, faction_color = core.HORDE_RED 
          }
        elseif count == 3 then
          test_data = { name="Nefarian", location="somewhere", is_boss = true }
        else
          test_data = { name=string.format("shard_%d", count) , level = 666}
        end
        test_data.id = count
        count = count + 1
        set_shard(bag_num+1, slot_num, core.deep_copy(test_data))
      end
    end
  end 
end
-- TODO: REMOVE ME ------------------------------------------------------


--[[ Return the bag and slot of next shard that will be consumed --]]
local function find_next_shard_location()
  local next_shard = { bag = core.SLOT_NULL, slot = core.SLOT_NULL }
  for bag_num, _ in ipairs(shard_mapping) do 
    for bag_index, _ in pairs(shard_mapping[bag_num]) do
      if bag_num <= next_shard.bag then
        next_shard.bag = bag_num
        if bag_index <= next_shard.slot then
          next_shard.slot = bag_index
        end
      end
    end
  end
  next_shard.bag = next_shard.bag
  return next_shard
end


--[[ Return the (data, location) of the next shard from inventory ]]--
local function get_next_shard_data()
  local next_shard_location = find_next_shard_location()
  if next_shard_location.bag == core.SLOT_NULL then -- prevents duplicate executions
    return nil
  end
  local shard_data = get_shard(next_shard_location.bag, next_shard_location.slot)
  return shard_data, next_shard_location
end


--[[ Set next open space soulshard will enter bags; soulbag priority. --]]
local function update_next_open_bag_slot()
    local open_soul_bag = {}
    local open_normal_bag = {}
    for bag_num = 0, core.MAX_BAG_INDEX, 1 do
      local num_free_slots, bag_type = GetContainerNumFreeSlots(bag_num);
      if num_free_slots > 0 then
        local free_slots = GetContainerFreeSlots(bag_num)

        -- save bag number and first open index if not yet found for bag type
        if bag_type == core.SOUL_BAG_TYPE and next(open_soul_bag) == nil then
          open_soul_bag['bag_number'] = bag_num
          open_soul_bag['open_index'] = free_slots[1]
        elseif bag_type == core.NORMAL_BAG_TYPE and next(open_normal_bag) == nil then
          open_normal_bag['bag_number'] = bag_num
          open_normal_bag['open_index'] = free_slots[1]
        end
      end
    end

    if next(open_soul_bag) ~= nil then 
      next_open_shard_slot = open_soul_bag
    elseif next(open_normal_bag) ~= nil then
      next_open_shard_slot = open_normal_bag
    else
      next_open_shard_slot = {} 
    end
end


-- get item id of stone associated with conjure spell
local function get_stone_item_id(spell_id, spell_name)
  if core.is_spell_create_hs(spell_id) then
    imp_hs_pts = get_total_pts_imp_hs() 
    return core.SPELL_NAME_TO_ITEM_ID[core.HS][spell_name][imp_hs_pts]
  else
    return core.SPELL_NAME_TO_ITEM_ID[core.NON_HS][spell_name]
  end
end


local function is_consume_stone_spell(spell_id)
  local hs_iid = core.CONSUME_HS_SID_TO_IID[spell_id] 
  local ss_iid = core.CONSUME_SS_SID_TO_IID[spell_id]
  if hs_iid ~= nil then return hs_iid
  elseif ss_iid ~=nil then return ss_iid
  else return nil end
end


--[[ Display message to group (raid > party) ]]--
local function message_active_party(mssg)
  if enable_chat then
    if IsInRaid() then
      SendChatMessage(mssg, core.CHAT_TYPE_RAID)
    elseif IsInGroup() then
      SendChatMessage(mssg, core.CHAT_TYPE_PARTY)
    end
  end
end


--[[ Reset stone data if logged out more than 15min ]]--
local function reset_expired_stone_mapping()
  if logout_time ~= nil then
    current_time = GetServerTime()
    stone_mapping_expr_time = logout_time + core.FIFTEEN_MINUTES
    if current_time > stone_mapping_expr_time then
      stone_mapping = {}
    end
    logout_time = nil
  end
end


--[[ Reset locked shard data when the locked shard was consumed --]]
local function reset_consumed_locked_shard_data(shard_location)
  local locked_shard = locked_shards[1]
  if locked_shard ~= nil then 
    if locked_shard.bag == shard_location.bag and 
       locked_shard.slot == shard_location.slot then
      locked_shards = {}
    end
  end
end


local function set_killed_target(dest_name, dest_guid)
  reset_killed_target_data()
  killed_target.id = GetServerTime()
  killed_target.name = dest_name 
  killed_target.location = core.get_player_zone()
  if core.table_contains(active_target_map, dest_guid) then
    killed_target.level = active_target_map[dest_guid].level
    remove_active_target(dest_guid)
  end

  if core.is_target_player(dest_guid) then 
    local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
    killed_target.race = race_name
    killed_target.class = class_name
    killed_target.is_player = true 

    killed_target.faction_color = core.ALLIANCE_BLUE
    if core.is_faction_horde(race) then
      killed_target.faction_color = core.HORDE_RED
    end

  elseif core.is_boss(core.get_npc_id(dest_guid)) then
    killed_target.is_boss = true 
  end
end


--[[ Track details of cast shadowburn (e.g. debuff duration) ]]--
local function shadowburn_aura_handler(subevent, dest_guid, curr_time)
  if subevent == core.AURA_APPLIED then
    set_shadowburn_data(dest_guid, GetTime(curr_time))
  elseif subevent == core.AURA_REMOVED and 
         shadowburn_data.end_time ~= nil and 
         curr_time >= shadowburn_data.end_time then
    reset_shadowburn_data()
  end
end


--[[ Set shard_added when a spell extracts a shard ]]--
local function add_next_shard()
  if shadowburn_data.applied or drain_soul_data.casting then
    if shadowburn_data.target_guid == dest_guid then
      reset_shadowburn_data()
    end
    if drain_soul_data.target_guid == dest_guid then
      reset_drain_soul_data()
    end
    -- space available?
    if next(next_open_shard_slot) ~= nil then 
      shard_added = true
    end
  end
end


local function drain_soul_batched(curr_time) 
  if drain_soul_end_t == nil then return false end
  local difference = curr_time - drain_soul_end_t
  drain_soul_end_t = nil

  if difference <= core.DRAIN_SOUL_DIFF then
    return true
  end
  return false
end


--[[ Remove stale data from shards old (locking) position ]]--
local function remove_old_shard_data(shard)
  local old_bag  = shard.bag
  local old_slot = shard.slot
  local old_id = get_shard(old_bag, old_slot).id
  if old_id == shard.data.id then
    set_shard(old_bag, old_slot, nil)
  end
end


--[[ Clear the associated consumed shard data on successful summon --]]
local function successful_summon_handler(curr_time)
  -- end_time set on successful summon, before this is called
  if summon_details.location ~= nil and summon_details.end_time ~= nil then
    local difference = curr_time - summon_details.end_time
    if difference <= core.SUCCESSFUL_SUMMON_DIFF then 
      reset_consumed_locked_shard_data(summon_details.location)
      set_shard(summon_details.location.bag, summon_details.location.slot, nil)
    end
    reset_summon_details()
  end
end


--[[ Return bag, slot & item_id of last open slot. --]]
local function get_last_open_slot_data()
  local bag = next_open_shard_slot['bag_number']
  local slot = next_open_shard_slot['open_index']
  if bag ~= nil and slot ~= nil then 
    local item_id = GetContainerItemID(bag, slot)
    return bag+1, slot, item_id    -- bag+1 for indexing at 1, not 0
  end

  return nil
end


--[[ Map/unmap shard being added/deleted from bag ]]--
local function bag_update_shard_handler(curr_time)
  local bag, slot, item_id = get_last_open_slot_data()
  if item_id == core.SOUL_SHARD_ID then
    if shard_added or drain_soul_batched(curr_time) then
      shard_added = false
      set_shard(bag, slot, core.deep_copy(killed_target))
      
    -- shard added for odd behavior (e.g. pet out and taking flight path)
    elseif curr_time ~= last_shard_unlock_time then 
      local killed_target_copy = core.deep_copy(core.DEFAULT_KILLED_TARGET_DATA)
      killed_target_copy.id = GetServerTime()
      set_shard(bag, slot, killed_target_copy)
    end
  end

  -- unless deleted, shards never 'lock' during bag_update
  if shard_deleted then 
    local del_shard = locked_shards[1]
    set_shard(del_shard.bag, del_shard.slot, nil)
    if summon_details.location ~= nil then
      summon_details.location = find_next_shard_location()
    end
    shard_deleted = false
    locked_shards =  {}
  end
end


local function bag_update_stone_handler()
  if stone_deleted then
    set_stone(locked_stone_iid, nil)
    stone_deleted = false
    locked_stone_iid = {}
  end
end


local function unlock_shard(bag, slot)
  last_shard_unlock_time = GetTime()

  -- swapping shards
  local remove_index = 1
  for index, locked_shard in pairs(locked_shards) do
    if locked_shard.bag ~= bag or (locked_shard.bag == bag and locked_shard.slot ~= slot) then
      remove_index = index
      break
    end
  end

  -- remove stale data
  local removed_locked_shard = table.remove(locked_shards, remove_index)
  remove_old_shard_data(removed_locked_shard)
  set_shard(bag, slot, removed_locked_shard.data)

  if summon_details.location ~= nil then 
    summon_details.location = find_next_shard_location()
  end

end


local function lock_shard(bag, slot) 
  local locked_shard = {}
  locked_shard.bag = bag
  locked_shard.slot = slot
  locked_shard.data = get_shard(locked_shard.bag, locked_shard.slot)
  table.insert(locked_shards, locked_shard)
end


local function is_spell_shard_consuming(spell_id)
  for _,spell_list in ipairs(core.SHARD_CONSUMING_SID) do
    if core.list_contains(spell_list, spell_id) then
      return true
    end
  end
  return false
end


local function is_spell_shard_producing(spell_id)
  for _,spell_list in ipairs(core.SHARD_PRODUCING_SID) do
    if core.list_contains(spell_list, spell_id) then
      return true
    end
  end
  return false
end


--[[ True if spell_id is shard consuming -- create stone; summon pet; shadowburn; soul fire; enslave ]]--
local function shard_consuming_spell_handler(spell_id, spell_name) 
  local shard_data, next_shard_location = get_next_shard_data()
  local output_txt = nil

  if core.table_contains(core.CREATE_STONE_SID, spell_id) then
    stone_iid = get_stone_item_id(spell_id, spell_name)
    set_stone(stone_iid, shard_data)
    stone_name = core.STONE_IID_TO_NAME[stone_iid]
    output_txt = string.format(core.OUTPUT_TXT.create_stone, stone_name, shard_data.name)
  elseif is_spell_shard_consuming(spell_id) then
    output_txt = string.format(core.OUTPUT_TXT.cast_spell, spell_name, shard_data.name)
  else
    return false
  end

  core.print_color(output_txt)
  set_shard(next_shard_location.bag, next_shard_location.slot, nil)
  reset_consumed_locked_shard_data(next_shard_location)
  return true
end


--[[ Return true if active target yields honor/xp and is tagged by player ]]--
local function killed_target_produced_shard(dest_guid)
  if core.table_contains(active_target_map, dest_guid) then
    local curr_target = active_target_map[dest_guid]
    if curr_target.is_trivial or curr_target.tap_denied then
      remove_active_target(dest_guid)
      return false
    else
      return true
    end
  end
  return false
end


--[[ Map if target is tagged and yields xp/honor for shard consuming spell ]]--
local function shard_producing_spell_handler(spell_id)
  local tar_guid = UnitGUID("target")
  if spell_id == nil or tar_guid == nil then return end

  if is_spell_shard_producing(spell_id) then
    local target_data = { 
      is_trivial = UnitIsTrivial("target"),
      tap_denied = UnitIsTapDenied("target"),
      level = UnitLevel("target")
    }
    add_active_target(tar_guid, target_data)
    return true
  end
  return false
end


local function format_message(message_list, target, data)
  local ret_mssg = nil
  if data.is_player then
    ret_mssg = string.format(message_list.player, target, data.name, data.level, data.race, data.class)
  elseif data.is_boss then
    ret_mssg = string.format(message_list.boss, target, data.name)
  else
    ret_mssg = string.format(message_list.default, target, data.name)
  end
  return ret_mssg
end


local function duplicate_spellcast_success(spell_id, curr_time)
  if spell_id ~= nil and spell_id == previous_spellcast.id and 
     curr_time == previous_spellcast.time then
    return true
  end
  return false
end


local function format_message(message_list, target, data)
  local ret_mssg = nil
  if data.is_player then
    ret_mssg = string.format(message_list.player, target, data.name, data.level, data.race, data.class)
  elseif data.is_boss then
    ret_mssg = string.format(message_list.boss, target, data.name)
  else
    ret_mssg = string.format(message_list.default, target, data.name)
  end
  return ret_mssg
end


local function duplicate_spellcast_success(spell_id, curr_time)
  if spell_id ~= nil and spell_id == previous_spellcast.id and 
     curr_time == previous_spellcast.time then
    print("DUPLICATE - RETURN") -- TODO: REMOVE ME
    return true
  end

  print("Initial Spell") -- TODO: REMOVE ME!!
  return false
end


----------------------- EVENTS ----------------------------


local current_target_frame = CreateFrame("Frame")
current_target_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
current_target_frame:SetScript("OnEvent",
  function(self, event)
    current_target = {
      guid = UnitGUID("target"),
      name = UnitName("target")
    }
  end)


local combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  local curr_time = GetTime()
  local _, subevent, _, _, _, _, _, dest_guid, dest_name, _, _, _, spell_name = CombatLogGetCurrentEventInfo()
  if subevent == core.UNIT_DIED and killed_target_produced_shard(dest_guid) then 
    set_killed_target(dest_name, dest_guid)
    add_next_shard()
  elseif spell_name == core.SHADOWBURN then
    shadowburn_aura_handler(subevent, dest_guid, curr_time)
  end
end)


local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  local _, _, spell_id = ... 
  if core.list_contains(core.DRAIN_SOUL_SID, spell_id) then 
    drain_soul_data.casting = true
    drain_soul_data.target_guid = current_target.guid
  end
end)


local channel_end_frame = CreateFrame("Frame")
channel_end_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
channel_end_frame:SetScript("OnEvent", function(self,event, ...)
  local _, _, spell_id = ... 
  if core.list_contains(core.DRAIN_SOUL_SID, spell_id) then 
    drain_soul_end_t = GetTime()
    reset_drain_soul_data()
  elseif spell_id == core.RITUAL_OF_SUMM_SID then
    summon_details.end_time = GetTime()
  end
end)


local item_frame = CreateFrame("Frame")
item_frame:RegisterEvent("BAG_UPDATE")
item_frame:SetScript("OnEvent",
  function(self, event, ...)
    local curr_time = GetTime()
    if last_bag_update_time == curr_time then return end
    last_bag_update_time = curr_time

    successful_summon_handler(curr_time)
    bag_update_shard_handler(curr_time)
    bag_update_stone_handler()

    update_next_open_bag_slot()
  end)


local bag_slot_lock_frame = CreateFrame("Frame")
bag_slot_lock_frame:RegisterEvent("ITEM_LOCKED")
bag_slot_lock_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag, slot = ...
    local item_id = GetContainerItemID(bag, slot)
    if item_id == core.SOUL_SHARD_ID then
      lock_shard(bag+1, slot) 
    elseif core.table_contains(core.STONE_IID_TO_NAME, item_id) then
      locked_stone_iid = item_id
    end
  end)


local bag_slot_unlock_frame = CreateFrame("Frame")
bag_slot_unlock_frame:RegisterEvent("ITEM_UNLOCKED")
bag_slot_unlock_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag, slot = ...
    local item_id = GetContainerItemID(bag, slot)
    bag = bag + 1
    if item_id == core.SOUL_SHARD_ID then
      unlock_shard(bag, slot)
    elseif core.table_contains(core.STONE_IID_TO_NAME, item_id) then
      locked_stone_iid = {}
    end
  end)


local reload_frame = CreateFrame("Frame")
reload_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
reload_frame:SetScript("OnEvent", 
  function(self,event,...)
    -- TODO: Change me back
    --set_default_shard_data()
    set_shard_data()
    reset_expired_stone_mapping()
    player_in_raid_instance = core.is_player_in_raid()
    active_target_map = {}
    update_next_open_bag_slot()

    -- TODO: REMOVE ME!!!! (or just add for Krel :))
    CastSpellByID(core.FIND_HERBS_SID)
  end)


local logout_frame = CreateFrame("Frame")
logout_frame:RegisterEvent("PLAYER_LOGOUT")
logout_frame:SetScript("OnEvent", 
  function(self,event,...)
    logout_time = GetServerTime()
  end)


local cast_success_frame = CreateFrame("Frame")
cast_success_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
cast_success_frame:SetScript("OnEvent", 
  function(self,event,...)
    local _, _, spell_id = ...
    local spell_name = GetSpellInfo(spell_id)
    local consumed_stone_iid = is_consume_stone_spell(spell_id)
    local curr_time = GetTime()

    if duplicate_spellcast_success(spell_id, curr_time) then return end
    set_previous_spellcast_data(spell_id, curr_time)

    shard_producing_spell_handler(spell_id)
    local shard_consuming_spell = shard_consuming_spell_handler(spell_id, spell_name)
    if not shard_consuming_spell then

      -- consume HS/SS 
      if consumed_stone_iid ~= nil and core.table_contains(stone_mapping, consumed_stone_iid) then
        local stone_data = get_stone(consumed_stone_iid)
        set_stone(consumed_stone_iid, nil)
        local output_txt = string.format(core.OUTPUT_TXT.consume_stone, stone_data.name)
        core.print_color(output_txt)

      -- summon cast successfully; shard not yet consumed
      elseif spell_id == core.RITUAL_OF_SUMM_SID then
        summon_details.location = find_next_shard_location()
      end
    end

  end)


local cast_sent_frame = CreateFrame("Frame")
cast_sent_frame:RegisterEvent("UNIT_SPELLCAST_SENT")
cast_sent_frame:SetScript("OnEvent", 
  function(self,event,...)
    local _, target, _, spell_id = ...
    local soulstone_iid = core.CONSUME_SS_SID_TO_IID[spell_id]
    if soulstone_iid ~= nil then 
      local data = get_stone(soulstone_iid)
      local mssg = format_message(core.SS_MESSAGE_LIST, target, data)
      message_active_party(mssg)
    elseif spell_id == core.RITUAL_OF_SUMM_SID and core.is_target_player(current_target.guid) then
      local data = get_next_shard_data()
      local mssg = format_message(core.SUMMON_MESSAGE_LIST, current_target.name, data)
      message_active_party(mssg)
    end
  end)


local delete_item_frame = CreateFrame("Frame")
delete_item_frame:RegisterEvent("DELETE_ITEM_CONFIRM")
delete_item_frame:SetScript("OnEvent", 
  function(self,event,...)
    if #locked_shards > 0 then
      shard_deleted = true
    elseif locked_stone_iid ~= nil then
      stone_deleted = true
    end
  end)
  

------------------ API --------------------


local function get_shard_mapping() 
  return shard_mapping
end
core.get_shard_mapping = get_shard_mapping


local function get_stone_mapping()
  return stone_mapping
end
core.get_stone_mapping = get_stone_mapping


local function reset_mapping_data()
  shard_mapping = { {}, {}, {}, {}, {} }
  stone_mapping = {}
  set_default_shard_data()
end
core.reset_mapping_data = reset_mapping_data


local function toggle_chat()
  enable_chat = not enable_chat
end
core.toggle_chat = toggle_chat



 

-- --------------------------TODO-------------------
-- TODO: ADD 20 man raid boss ID's to core
--
-- TODO: BEFORE RAID ---- 
--          XXX. Improve announcement messages
--          XXX. Testing (summon especially)
--          2. Fun little notes; EMOTE the notes!!!
--              *** SendChatMessage("BOOM", "EMOTE")
--
-- TODO: UX: Give the user some options through the console
--         ----> Enable/disable console printing.. maybe what does/doesn't get printed?
--         ----> Enable/disable certain features
--         ----> Custom message can be written by user through console
--         ----> Enable/disable emotes.. add custom emotes.. etc.
--
-- ---------------------------- FUTURE ----------------------------------------------
-- TODO: Bunch of unique messages for summoning/making SS different types of souls.. can be picked randomly
-- TODO: User can create their own messages when summoning/creating a SS 
-- TODO: Shard details option... shift+select a shard or something will display all info.. time acquired, location, etc.
-- TODO: When trading HS -- whisper player the name of the soul!
-- TODO: Map summoned pet to soul name.. so when random lose pet can label it?
-- **** What runs when my pet gets automatically dismissed.. how can I know when that occurs? Test diff methods..
--        combat log, spellcast_success, etc.?
--
-- TODO: TESTING - - - - - - - - - - - - - - - -
-- ---> Soul stone messages
-- ---> Test adding SS to toolbar again .. does it auto target me?
-- ---> SUMMONING
-- ---> Ensure SPELLCAST_SUCCEEDED never runs twice 
--      **** (will see duplicate print statements when casting shard consuming spells/summon/consume stone)
-- ---> Enslave demon
-- ---> Test summong/moving around shards/etc..
--        >> Move shards WHILE summong.. i.e. after initial spellcast sent
--        >> QUESTION: Does it use the shard when SPELLCAST_SUCCESS || what if after success I move shards around? Which is used!
-- ---> Creating a stone when bags are full; stone_created = true; will it stay true or will bag_update run and set to false?
-- ---> KILL ALLIANCE!!!
--
-- - - - - - - - - - - - - - PLAY TESTING MOSTLY - - - - - - - - - - - - -
-- ---> Logout and test on relogin conjured items/stones still the same? What about after 15min?
-- ---> 15min logout -- does data get cleared? Right before 15m mark, right after 15m mark.
--        > Also test going in/out of dungeons after a while, etc... randomly died in AQ saw the clear message
--
-- XXX TEST CREATING EVERY STONE / CASTING EVERY PET
-- XXX Use locked shard for all different consuming spells. Also try locking shard that WONT be used when casting shard 
--          consuming spells
-- XXX DELETE SHARD > then lock/unlock a different shard; will break after first attempt
