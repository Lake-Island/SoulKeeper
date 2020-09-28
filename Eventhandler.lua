local _, core = ...

-- TODO: TEMP -- or is it?
drain_soul_end_t = nil

-- TODO: Put somewhere else?
enable_chat = false

-- data associated with soul shard
killed_target = {
  time = -1,
  name = nil,
  race = nil,
  class = nil,
  location = nil,
  is_player = false,
  is_boss = false,
  level = nil,
  faction_color = nil
}

player_target_map = {}
current_target_guid = nil
current_target_name = nil

last_bag_update_time = nil
player_in_raid_instance = false

logout_time = nil
summon_details = {
  end_time = nil,
  location = nil
}

-- Mapping of data of saved souls to bag indices
shard_mapping = { {}, {}, {}, {}, {} }

-- map conjured stone item_ID to kill data 
stone_mapping = {}

next_open_shard_slot = {}

locked_shards = {}
shard_added = false
shard_deleted = false
stone_created = false
pet_summoned = false

locked_stone_iid = {}
stone_deleted = false

shadowburn_data = {
  applied = false,
  application_time = nil,
  end_time = nil,
  target_guid = ""
}

drain_soul_data = { 
  casting = false,
  target_guid = ""
}

last_shard_unlock_time = 0

local function get_shard_mapping() 
  return shard_mapping
end
core.get_shard_mapping = get_shard_mapping


local function get_stone_mapping()
  return stone_mapping
end
core.get_stone_mapping = get_stone_mapping


-- TODO: MOVE ME?
local function update_main_display_text(display_str)
  core.main_display_frame.text:SetText(display_str)
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


-- total points invested in improved healthstone talent
local function get_total_pts_imp_hs()
    _, _, _, _, total_pts = GetTalentInfo(2,1,1)
    return total_pts
end


--[[ 
  Iterate over all bag slots and map any unmapped soul shards. 
  Values set to default (<MISSING DATA>).
]]--
local function set_default_shard_data()
  for bag_num = 0, core.MAX_BAG_INDEX, 1 do
    num_bag_slots = GetContainerNumSlots(bag_num)
    for slot_num = 1, num_bag_slots, 1 do
      curr_item_id = GetContainerItemID(bag_num, slot_num)
      curr_shard_slot = shard_mapping[bag_num+1][slot_num]
      -- unmapped soul shard; map it.
      if curr_item_id == core.SOUL_SHARD_ID and curr_shard_slot == nil then
        shard_mapping[bag_num+1][slot_num] = core.deep_copy(core.DEFAULT_KILLED_TARGET_DATA)
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
    num_bag_slots = GetContainerNumSlots(bag_num)
    for slot_num = 1, num_bag_slots, 1 do
      curr_item_id = GetContainerItemID(bag_num, slot_num)
      curr_shard_slot = shard_mapping[bag_num+1][slot_num]
      -- unmapped soul shard; map it.
      if curr_item_id == core.SOUL_SHARD_ID then
        local test_data = nil
        if count == 1 then
          test_data = { 
            name="Guy", race="Human", class="Mage", is_player = true, level = 60, is_boss = false, faction_color = core.ALLIANCE_BLUE 
          }
        elseif count == 2 then
          test_data = { 
            name="Krel", race="Undead", class="Warlock", is_player = true, level = 60, is_boss = false, faction_color = core.HORDE_RED 
          }
        elseif count == 3 then
          test_data = { name="Nefarian", is_boss = true }
        else
          test_data = { name=string.format("shard_%d", count) }
        end
        count = count + 1
        shard_mapping[bag_num+1][slot_num] = core.deep_copy(test_data)
      end
    end
  end 
end
-- TODO: REMOVE ME ------------------------------------------------------


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


--[[ Return true if the spell consumes a shard; false otherwise --]]
local function shard_consuming_spell(spell_name, spell_list)
  for _, shard_spell in pairs(spell_list) do
    if string.find(spell_name,shard_spell) then
      return true
    end
  end
  return false
end


--[[ Return the bag number and slot of next shard that will be consumed --]]
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


--[[ Return the data of the next shard from inventory ]]--
local function get_next_shard_data()
  local next_shard_location = find_next_shard_location()
  if next_shard_location.bag == core.SLOT_NULL then -- prevents duplicate executions
    return nil
  end
  local shard_data = shard_mapping[next_shard_location.bag][next_shard_location.slot]
  return shard_data, next_shard_location
end


local function is_target_player(tar_guid)
  if tar_guid == nil then return false end
  return string.find(tar_guid, "Player") ~= nil
end


--[[
  Set next_open_shard_slot variable to contain the bag_number and index of the 
  next open bag slot. Only soulbags and regular bags considered, soul bags
  get priority order.
--]]
local function update_next_open_bag_slot()
    local open_soul_bag = {}
    local open_normal_bag = {}
    for bag_num = 0, core.MAX_BAG_INDEX, 1 do
      -- get number of free slots in bag and its type
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

    -- set next_open_shard_slot to corresopnding bag/index
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
  -- hs; query with pts in imp. hs
  if core.CREATE_HS_SID[spell_id] ~= nil then
    imp_hs_pts = get_total_pts_imp_hs() 
    return core.SPELL_NAME_TO_ITEM_ID[core.HS][spell_name][imp_hs_pts]
  -- non-hs
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


--[[ Display message to raid, party if no raid, nothing otherwise. ]]--
local function message_active_party(mssg)
  if enable_chat then
    if IsInRaid() then
      SendChatMessage(mssg, core.CHAT_TYPE_RAID)
    elseif IsInGroup() then
      SendChatMessage(mssg, core.CHAT_TYPE_PARTY)
    else
      print("Not currently in a party/raid")
    end
  end
end


--[[ Reset stone data if logged out more than 15min. ]]--
local function reset_expired_stone_mapping()
  if logout_time ~= nil then
    current_time = GetServerTime()
    stone_mapping_expr_time = logout_time + core.FIFTEEN_MINUTES
    if current_time > stone_mapping_expr_time then
      print("EXPIRED: Clearing stone_mapping data...")
      stone_mapping = {}
    end
    logout_time = nil
  end
end


local current_target_frame = CreateFrame("Frame")
current_target_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
current_target_frame:SetScript("OnEvent",
  function(self, event)
    current_target_guid = UnitGUID("target")
    current_target_name = UnitName("target")

    if is_target_player(current_target_guid) then
      player_target_map[current_target_guid] = UnitLevel("target")
    end
  end)


--[[
  Reset locked shard data when the locked shard was consumed.
-- TODO: Change 'next_shard_location' to be local instead of global. Can then call the function 
-- directly.
--]]
local function reset_consumed_locked_shard_data(shard_location)
  local locked_shard = locked_shards[1]
  if locked_shard ~= nil then 
    if locked_shard.bag == shard_location.bag and 
       locked_shard.slot == shard_location.slot then
      locked_shards = {}
    end
  end
end

--[[ 
     From the Combat Log save the targets details, time, and location of kill.
     Track shadowburn debuff data.
--]]
local combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  local curr_time = GetTime()
  local _, subevent, _, _, _, _, _, dest_guid, dest_name, _, _, _, spell_name = CombatLogGetCurrentEventInfo()

  local event_to_execute = core.PARTY_KILL
  if player_in_raid_instance then
    event_to_execute = core.UNIT_DIED
  end

  -- save info of dead target
  -- TODO: HELPER FUNCTION
  if subevent == event_to_execute then 
    killed_target.time = curr_time
    killed_target.name = dest_name 
    killed_target.location = core.getPlayerZone()
    if is_target_player(dest_guid) then -- non npc?
      local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
      killed_target.race = race_name
      killed_target.class = class_name
      killed_target.is_player = true 
      local player_lvl = player_target_map[dest_guid]
      if player_lvl ~= nil then
        killed_target.level = player_lvl
        player_target_map[dest_guid] = nil
      end
      -- faction color
      killed_target.faction_color = core.ALLIANCE_BLUE
      if core.is_faction_horde(race) then
        killed_target.faction_color = core.HORDE_RED
      end
    elseif core.is_boss(core.get_npc_id(dest_guid)) then
      killed_target.is_boss = true 
    end

    -- shard consuming spell active on killed target; reset corresponding data
    if shadowburn_data.applied or drain_soul_data.casting then
      if shadowburn_data.target_guid == dest_guid then
        reset_shadowburn_data()
      end
      if drain_soul_data.target_guid == dest_guid then
        reset_drain_soul_data()
      end
      -- shard added if space available in bag
      if next(next_open_shard_slot) ~= nil then 
        shard_added = true
      end
    end
    
  -- track details of cast shadowburn (e.g. debuff duration)
  elseif spell_name == core.SHADOWBURN then
    curr_time = GetTime()
    if subevent == core.AURA_APPLIED then
      set_shadowburn_data(dest_guid, GetTime(curr_time))
    -- TODO: Ugly fix this if condition now so many ands..
    elseif subevent == core.AURA_REMOVED and shadowburn_data.end_time ~= nil and curr_time >= shadowburn_data.end_time then
      -- TODO: Maybe save timestamp when it was removed, then check when target was killed 
      -- if it was .5 seconds in that window or w/e
      -- >>> e.g. about condition would also check if timestamp fits idfference threshold
      print("Shadowburn Aura - Removed") -- TODO: REMOVE ME!!!
      reset_shadowburn_data()
    end
  end
end)


--[[ Record that drain soul started channeling. --]]
local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  local spell_name, _, spell_id, start_time = ChannelInfo()  
  if spell_name == core.DRAIN_SOUL then 
    drain_soul_data.casting = true
    drain_soul_data.target_guid = current_target_guid
  end
end)


--[[ Record that drain soul stopped channeling. ]]--
local channel_end_frame = CreateFrame("Frame")
channel_end_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
channel_end_frame:SetScript("OnEvent", function(self,event, ...)
  local _, _, spell_id = ... 
  local spell_name = GetSpellInfo(spell_id)
  if spell_name == core.DRAIN_SOUL then 
    drain_soul_end_t = GetTime()
    reset_drain_soul_data()
  elseif spell_name == core.RITUAL_OF_SUMM then
    summon_details.end_time = GetTime()
  end
end)


--[[ TODO: MOVE ME!

]]--
local function drain_soul_batched(curr_time) 
  if drain_soul_end_t == nil then return false end
  difference = curr_time - drain_soul_end_t
  drain_soul_end_t = nil

  if difference <= core.DRAIN_SOUL_DIFF then
    return true
  end

  return false
end


--[[
    Clears the associated consumed shard data on successful summon.
--]]
local function successful_summon_handler(curr_time)
  if summon_details.end_time ~= nil then
    local difference = curr_time - summon_details.end_time

    -- TODO: REMOVE ME -----------------------------------
    print("BAG_UPDATE_TIME: " .. curr_time)
    print("SUMMON_END_TIME: " .. summon_details.end_time)
    print("DIFFERENCE: " .. difference)
    -- TODO: REMOVE ME -----------------------------------

    if difference <= core.SUCCESSFUL_SUMMON_DIFF then 

      -- TODO: REMOVE ME -----------------------------------
      local curr_shard_data = shard_mapping[summon_details.location.bag][summon_details.location.slot] 
      print("Successful summon --- Removing soul: " .. curr_shard_data.name)
      -- TODO: REMOVE ME -----------------------------------

      -- TODO: Reset locked shard data if shard consumed was locked
      reset_consumed_locked_shard_data(summon_details.location)
      shard_mapping[summon_details.location.bag][summon_details.location.slot] = nil
    end

    reset_summon_details()
  end
end

--[[
  Return bag, slot & item_id of last open slot.
--]]
local function get_last_open_slot_data()
  local bag = next_open_shard_slot['bag_number']
  local slot = next_open_shard_slot['open_index']
  if bag ~= nil and slot ~= nil then 
    local item_id = GetContainerItemID(bag, slot)
    return bag+1, slot, item_id    -- bag+1 for indexing at 1, not 0
  end

  return nil
end


--[[
  During BAG_UPDATE, check if a shard was added to the last open shard space. 
  Set corresponding mapping/data if true.
--]]
local function bag_update_shard_handler(curr_time)
  local bag, slot, item_id = get_last_open_slot_data()
  if item_id == core.SOUL_SHARD_ID then
    if shard_added or drain_soul_batched(curr_time) then
      shard_added = false
      shard_mapping[bag][slot] = core.deep_copy(killed_target)
    elseif curr_time ~= last_shard_unlock_time then -- shard added for odd behavior (e.g. pet out and taking flight path)
      shard_mapping[bag][slot] = core.deep_copy(core.DEFAULT_KILLED_TARGET_DATA)
    end
  end

  -- unless deleted, shards never 'lock' during bag_update
  if shard_deleted then 
    local del_shard = locked_shards[1]
    shard_mapping[del_shard.bag][del_shard.slot] = nil
    shard_deleted = false
    locked_shards =  {}
  end
end


local function bag_update_stone_handler()
  if stone_created then 
    stone_created = false
  end

  if stone_deleted then
    stone_mapping[locked_stone_iid] = nil
    stone_deleted = false
    locked_stone_iid = {}
  end
end


--[[
  On BAG_UPDATE (inventory change), check if item was a newly added soul shard. 
  Save mapping of new shard to bag index. Update next open bag slot.
  Will not map if shard wasn't actually added (preventing errors with no xp/honor target).
  >> NOTE: Bag numbers index from [0-4] but the shard_mapping table is from [1-5]
--]]
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

    if pet_summoned then
      pet_summoned = false
    end

    -- update next open slot
    update_next_open_bag_slot()
  end)


--[[
  When a soul shard is locked (selected from inventory), save its data
  in the locked_shards table with its bag/bag_slot numbers. 
  Remove the shards mapping from the shard_mapping table until unlocked.
  ( see 'ITEM_UNLOCKED' frame )
--]]
local bag_slot_lock_frame = CreateFrame("Frame")
bag_slot_lock_frame:RegisterEvent("ITEM_LOCKED")
bag_slot_lock_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag, slot = ...
    local item_id = GetContainerItemID(bag, slot)
    if item_id == core.SOUL_SHARD_ID then
      -- add shard to table of currently locked shards
      local curr_shard = {}
      curr_shard.bag = bag+1 -- bag 0 indexed
      curr_shard.slot = slot
      curr_shard.data = shard_mapping[curr_shard.bag][curr_shard.slot]
      table.insert(locked_shards, curr_shard)

      shard_mapping[curr_shard.bag][curr_shard.slot] = nil

      -- TODO: REMOVE ME!!!
      print("Removing shard --- " .. curr_shard.data.name .. " --- from map!")

    -- mark stone as 'locked'
    elseif core.STONE_ID_TO_NAME[item_id] ~= nil then
      locked_stone_iid = item_id
    end
  end)


--[[
  When a soul shard is unlocked (put into the inventory from locked state),
  update mapping with the shards data. 
  Checks table of locked_shards adding the shard from a different bag slot
  if there are more than one shards in the list (e.g. a swap is occuring).
--]]
local bag_slot_unlock_frame = CreateFrame("Frame")
bag_slot_unlock_frame:RegisterEvent("ITEM_UNLOCKED")
bag_slot_unlock_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag, slot = ...
    local item_id = GetContainerItemID(bag, slot)
    bag = bag + 1
    if item_id == core.SOUL_SHARD_ID then
      last_shard_unlock_time = GetTime()

      -- ensure shard location used in summon is up to date
      if summon_details.location ~= nil then
        summon_details.location = find_next_shard_location()
      end

      -- select correct shard to insert from table of unlocked shards
      for index, curr_shard in pairs(locked_shards) do
        if #locked_shards == 1 then
          shard_mapping[bag][slot] = table.remove(locked_shards,index).data
        elseif curr_shard.bag ~= bag or (curr_shard.bag == bag and curr_shard.slot ~= slot) then
            shard_mapping[bag][slot] = table.remove(locked_shards,index).data
            break
        end
      end

      -- TODO: REMOVE ME!!!
      print("Added shard --- " .. shard_mapping[bag][slot].name .. " --- to map!")

    -- mark stone 'unlocked'
    elseif core.STONE_ID_TO_NAME[item_id] ~= nil then
      locked_stone_iid = {}
    end
  end)


-- TODO: MOVE ME TO CORE?!!!!
local function is_player_in_raid()
  local _, instance_type = GetInstanceInfo()
  if instance_type == core.RAID then
    return true
  end
  return false
end


local reload_frame = CreateFrame("Frame")
reload_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
reload_frame:SetScript("OnEvent", 
  function(self,event,...)
    -- TODO: Change me back
    --set_default_shard_data()
    set_shard_data()
    reset_expired_stone_mapping()
    player_in_raid_instance = is_player_in_raid()
    player_target_map = {}
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


--[[
  Check if a shard consuming spell was cast successfully. Map corresponding shard 
  data to newly conjured stone/pet. 
  -- NOTE: Store stones in mapping by item_id, this way events ITEM_LOCK/UNLOCK can 
            access the corresponding item mapping.
--]]
local cast_success_frame = CreateFrame("Frame")
cast_success_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
cast_success_frame:SetScript("OnEvent", 
  function(self,event,...)
    local _, _, spell_id = ...
    local spell_name = GetSpellInfo(spell_id)
    local consumed_stone_iid = is_consume_stone_spell(spell_id)

    -- conjure stone 
    if shard_consuming_spell(spell_name, core.CONJURE_STONE_NAMES) and not stone_created then
      local shard_data, next_shard_location = get_next_shard_data()
      shard_mapping[next_shard_location.bag][next_shard_location.slot] = nil
      stone_iid = get_stone_item_id(spell_id, spell_name)
      stone_name = core.STONE_ID_TO_NAME[stone_iid]
      stone_mapping[stone_iid] = shard_data

      reset_consumed_locked_shard_data(next_shard_location)

      -- Avoid duplicate execution when this function runs twice
      stone_created = true 
      print("Created " .. stone_name .. " with the soul of <" .. shard_data.name .. ">")

    -- summon pet 
    elseif shard_consuming_spell(spell_name, core.SUMMON_PET_NAMES) and not pet_summoned then
      local shard_data, next_shard_location = get_next_shard_data()
      shard_mapping[next_shard_location.bag][next_shard_location.slot] = nil

      pet_summoned = true
      reset_consumed_locked_shard_data(next_shard_location)
      print("Cast " .. spell_name .. " with the soul of <" .. shard_data.name .. ">")

    -- consume HS/SS 
    elseif consumed_stone_iid ~= nil and stone_mapping[consumed_stone_iid] ~= nil then
      local stone_data = stone_mapping[consumed_stone_iid]
      stone_mapping[consumed_stone_iid] = nil

      print("Consumed the soul of <" .. stone_data.name .. ">")

    elseif spell_id == core.RITUAL_OF_SUMM_SID then
      summon_details.location = find_next_shard_location()

      -- TODO: REMOVE ME ---------------
      local summ_name = shard_mapping[summon_details.location.bag][summon_details.location.slot] 
      print("SPELLCAST_SUCCESS: SUMMON PREDICTING USE OF SOUL: " .. summ_name.name)
      -- TODO: REMOVE ME ---------------
    end
  end)


--[[ Message group who is getting the SS/summon being cast. ]]--
local cast_sent_frame = CreateFrame("Frame")
cast_sent_frame:RegisterEvent("UNIT_SPELLCAST_SENT")
cast_sent_frame:SetScript("OnEvent", 
  function(self,event,...)
    local _, target, _, spell_id = ...
    local ss_iid = core.CONSUME_SS_SID_TO_IID[spell_id]

    if ss_iid ~= nil then 
      local stone_data = stone_mapping[ss_iid]
      local mssg = string.format(core.SS_MESSAGE, target, stone_data.name)
      message_active_party(mssg)

    elseif spell_id == core.RITUAL_OF_SUMM_SID and is_target_player(current_target_guid) then
      local shard_data = get_next_shard_data()
      local mssg = string.format(core.SUMMON_MESSAGE, current_target_name, shard_data.name)
      message_active_party(mssg)
    end
  end)


local delete_item_frame = CreateFrame("Frame")
delete_item_frame:RegisterEvent("DELETE_ITEM_CONFIRM")
delete_item_frame:SetScript("OnEvent", 
  function(self,event,...)
    if locked_shards[1] ~= nil then
      shard_deleted = true
    elseif locked_stone_iid ~= nil then
      stone_deleted = true
    end
  end)
 


-- TODO: When trading HS -- whisper player the name of the soul!
-- TODO: Enslave demon; make sure all shard using spells accounted for; be sure to test them
-- TODO: Update announced messages, if alliance add information... etc..
-- TODO: Custom message can be written by user through console
-- TODO: Shard details option... shift+select a shard or something will display all info.. time acquired, location, etc.
--

-- TODO: TESTING - - - - - - - - - - - - - - - -
-- ---> Use locked shard for all different consuming spells. Also try locking shard that WONT be used when casting shard 
--          consuming spells
-- ---> DELETE SHARD > then lock/unlock a different shard; will break after first attempt
-- ---> Creating a stone when bags are full; stone_created = true; will it stay true or will bag_update run and set to false?
--
-- ---> Someone else fighting alliance; I also get tag? Dunno.. test drain soul on alliacne.. also on one that was already fighting 
--        another and see what happens
-- ---> Drain soul on enemy that I dont have tagged
-- ---> Drain_soul/shadowburned target that does NOT yield xp/honor shouldn't get mapped || mess anything else up!
-- ---> Logout and test on relogin conjured items/stones still the same? What about after 15min?
-- ---> 15min logout -- does data get cleared? Right before 15m mark, right after 15m mark.
--        > Also test going in/out of dungeons after a while, etc... randomly died in AQ saw the clear message
-- ---> Test summong/moving around shards/etc..
--        >> Move shards WHILE summong.. i.e. after initial spellcast sent
--        >> QUESTION: Does it use the shard when SPELLCAST_SUCCESS || what if after success I move shards around? Which is used!
--
--
-- TODO: REFACTOR
-- ---> Create getter functions for getting map values.. e.g. x = stonemapping[item_id]  should be x = get_stone(item_id); etc..
-- ---> Refactor to no longer use spell_name is SPELLCAST_SUCCEED & get_stone_id.. use ID's instead.. would require refactoring core
-- ---> 'next_shard_location' needs to be local.. that means it need sto be fixed in multiple places




-- TODO: FOR TESTING -- REMOVE ME!!!!
--[[
t1 = nil
t2 = nil
local test_frame = CreateFrame("Frame")
test_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
test_frame:SetScript("OnEvent",
  function(self, event)
    print("ServerTime: " .. GetServerTime())
    print("Uptime: " .. GetTime())
    if t1 == nil then 
      t1 = GetTime()
    elseif t2 == nil then
      t2 = GetTime()
      print("T1: " .. t1)
      print("T2: " .. t2)
      difference = t2-t1
      print("DIFFERENCE: " .. difference)
      if difference < 1 then
        print("DIFFERENCE LESS THAN 1!")
      end
      t1 = nil
      t2 = nil
    end
  end)

local cast_start_frame = CreateFrame("Frame")
cast_start_frame:RegisterEvent("UNIT_SPELLCAST_START")
cast_start_frame:SetScript("OnEvent", 
  function(self,event,...)
    local unit_target, cast_guid, spell_id = ...
    
    mssg = "%s, the soul of <%s> is yours!"
    print(string.format(mssg, "Krel", "Monkey"))
    print("MY_NAME: " .. UnitName("player"))
    print("TARGET_NAME: " .. UnitName("target"))
    
  end)

]]--

-- END
