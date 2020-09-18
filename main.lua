local _, core = ...

-- data associated with soul shard
killed_target = {
  time = -1,
  name = "",
  race = "",
  class = "",
  location = ""
  -- TODO: Add level if alliance? 
}

current_target_guid = ""

-- Mapping of data of saved souls to bag indices
-- TODO: Save these values between sessions
shard_mapping = { {}, {}, {}, {}, {} }

-- map created stones to kill_data used to create them
stone_mapping = {}

-- next available slot in bags (soul bag priority)
next_open_slot = {}
shard_added = false

-- shard(s) that are currently locked (selected/swapping)
locked_shards = {}

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

function reset_shadowburn_data()
  shadowburn_data = {
    applied = false,
    application_time = nil,
    end_time = nil,
    target_guid = ""
  }
end


function set_shadowburn_data(dest_guid, time)
  shadowburn_data = {
    applied = true,
    application_time = time,
    end_time = time + core.SHADOWBURN_DEBUFF_TIME,
    target_guid = dest_guid
  }
end


function reset_drain_soul_data()
  drain_soul_data = { 
    casting = false,
    target_guid = ""
  }
end


--[[ Return true if the spell consumes a shard; false otherwise --]]
function shard_consuming_spell(spell_name, spell_list)
  for _, shard_spell in pairs(spell_list) do
    if ( string.find(spell_name,shard_spell) ) then
      return true
    end
  end
  return false
end


--[[ Return the bag number and slot of next shard that will be consumed --]]
function find_next_shard()
  local next_shard = { bag = core.SLOT_NULL, index = core.SLOT_NULL }
  for bag_num, _ in ipairs(shard_mapping) do 
    for bag_index, _ in pairs(shard_mapping[bag_num]) do
      if bag_num <= next_shard.bag then
        next_shard.bag = bag_num
        if bag_index <= next_shard.index then
          next_shard.index = bag_index
        end
      end
    end
  end
  next_shard.bag = next_shard.bag
  return next_shard
end


--[[ Return the data of the next shard from inventory ]]--
function get_next_shard_data()
  next_shard_location = find_next_shard()
  if next_shard_location.bag == core.SLOT_NULL then -- prevents duplicate executions
    return nil
  end
  local shard_data = shard_mapping[next_shard_location.bag][next_shard_location.index]
  return shard_data
end


--[[
  Set next_open_slot variable to contain the bag_number and index of the 
  next open bag slot. Only soulbags and regular bags considered, soul bags
  get priority order.
--]]
function update_next_open_bag_slot()
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

    -- set next_open_slot to corresopnding bag/index
    if next(open_soul_bag) ~= nil then 
      next_open_slot = open_soul_bag
    elseif next(open_normal_bag) ~= nil then
      next_open_slot = open_normal_bag
    else
      next_open_slot = {} 
    end
end

local current_target_frame = CreateFrame("Frame")
current_target_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
current_target_frame:SetScript("OnEvent",
  function(self, event)
    current_target_guid = UnitGUID("target")
    --[[ TODO: Remove me! InGroup fires if also in raid
    if (IsInGroup()) then
      print("In a group!")
    end
    if (IsInRaid()) then
      print("In a raid!")
    end
    ]]--
  end)


--[[ 
     From the Combat Log save the targets details, time, and location of kill.
     Track shadowburn debuff data.
--]]
local combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  local curr_time = GetTime()
  local _, subevent, _, _, _, _, _, dest_guid, dest_name, _, _, _, spell_name = CombatLogGetCurrentEventInfo()
  -- save info of dead target
  -- TODO: Code always runs even if im not the one fighting; is this a problem?
  if (subevent == core.UNIT_DIED) then 
    killed_target.time = curr_time
    killed_target.name = dest_name 
    killed_target.location = core.getPlayerZone()
    if (string.find(dest_guid, "Player")) ~= nil then -- non npc?
      local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
      killed_target.race = race_name
      killed_target.class = class_name
    end

    -- shard consuming spell active on killed target; reset corresponding data
    if (shadowburn_data.applied or drain_soul_data.casting) then
      if (shadowburn_data.target_guid == dest_guid ) then
        reset_shadowburn_data()
      end
      if (drain_soul_data.target_guid == dest_guid) then
        reset_drain_soul_data()
      end
      -- shard added if space available in bag
      if (next(next_open_slot) ~= nil) then 
        shard_added = true
      end
    end
    
  -- track details of cast shadowburn (e.g. debuff duration)
  elseif (spell_name == core.SHADOWBURN) then
    curr_time = GetTime()
    if (subevent == core.AURA_APPLIED) then
      set_shadowburn_data(dest_guid, GetTime(curr_time))
    elseif ((subevent == core.AURA_REMOVED) and 
            (curr_time >= shadowburn_data.end_time) ) then
      reset_shadowburn_data()
    end
  end
end)


--[[ Record that drain soul started channeling. --]]
local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  local spell_name, _, _, start_time = ChannelInfo()  
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
    reset_drain_soul_data()
  end
end)


--[[
  On BAG_UPDATE (inventory change), check if item was a newly added soul shard. 
  Save mapping of new shard to bag index. Update next open bag slot.
  >> NOTE: Bag numbers index from [0-4] but the shard_mapping table is from [1-5]
--]]
local item_frame = CreateFrame("Frame")
item_frame:RegisterEvent("BAG_UPDATE")
item_frame:SetScript("OnEvent",
  function(self, event, ...)
    -- Drain soul was successfully cast on killed target after last BAG_UPDATE
    if shard_added then
      shard_added = false
      local bag_number = next_open_slot['bag_number']
      local shard_index = next_open_slot['open_index']
      local item_id = GetContainerItemID(bag_number, shard_index)
      if item_id == core.SOUL_SHARD_ID then
        shard_mapping[bag_number+1][shard_index] = core.deep_copy(killed_target)
      end
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
    local bag_id, slot_id = ...
    local item_id = GetContainerItemID(bag_id, slot_id)
    if item_id == core.SOUL_SHARD_ID then
      -- add shard to table of currently locked shards
      curr_shard = {}
      curr_shard.data = shard_mapping[bag_id+1][slot_id]
      curr_shard.bag_id = bag_id
      curr_shard.slot_id = slot_id
      table.insert(locked_shards, curr_shard)
      shard_mapping[bag_id+1][slot_id] = nil

      -- TODO: Different target while casting drain_soul bug?

      -- TODO: REMOVE ME!!!
      print("Removing shard --- " .. curr_shard.data.name .. " --- from map!")
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
    local bag_id, slot_id = ...
    local item_id = GetContainerItemID(bag_id, slot_id)
    if item_id == core.SOUL_SHARD_ID then

      -- select correct shard to insert from table of unlocked shards
      for index, curr_shard in pairs(locked_shards) do
        
        -- only 1 element in table; set into slot; remove from table
        if (#locked_shards == 1) then
          shard_mapping[bag_id+1][slot_id] = table.remove(locked_shards,index).data

        -- swapping multiple shards; select the one from a different slot
        elseif ( (curr_shard.bag_id ~= bag_id) or 
             (curr_shard.bag_id == bag_id and curr_shard.slot_id ~= slot_id) 
           ) then
            shard_mapping[bag_id+1][slot_id] = table.remove(locked_shards,index).data
            break
        end
      end

      -- TODO: REMOVE ME!!!
      print("Added shard --- " .. shard_mapping[bag_id+1][slot_id].name .. " --- to map!")
    end
  end)


--[[ 
  On game start/reload, iterate over all bag slots and map any unmapped soul shards. 
  Values set to default (<MISSING DATA>).
--]]
local reload_frame = CreateFrame("Frame")
reload_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
reload_frame:SetScript("OnEvent", 
  function(self,event,...)
    for bag_num = 0, core.MAX_BAG_INDEX, 1 do
      num_bag_slots = GetContainerNumSlots(bag_num)
      for slot_num = 1, num_bag_slots, 1 do
        curr_item_id = GetContainerItemID(bag_num, slot_num)
        curr_shard_slot = shard_mapping[bag_num+1][slot_num]
        -- unmapped soul shard; map it.
        if ( (curr_item_id == core.SOUL_SHARD_ID) and (curr_shard_slot == nil) ) then
          shard_mapping[bag_num+1][slot_num] = core.deep_copy(core.DEFAULT_KILLED_TARGET_DATA)
        end
      end
    end 
  end)


--[[
  Check if a shard consuming spell was cast successfully. Map corresponding shard 
  data to newly conjured stone/pet. 
  -- NOTE: Soulstones are mapped to spell_IDs, healthstones/spellstones/firestones to spell_names.
--]]
local cast_success_frame = CreateFrame("Frame")
cast_success_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
cast_success_frame:SetScript("OnEvent", 
  function(self,event,...)
    local unit_target, cast_guid, spell_id = ...
    local spell_name = GetSpellInfo(spell_id)

    -- conjure stone spells
    if ( shard_consuming_spell(spell_name, core.CONJURE_STONE_NAMES) ) then
      shard_data = get_next_shard_data()
      shard_mapping[next_shard_location.bag][next_shard_location.index] = nil
      stone_name = core.STONE_NAME[spell_name]
      stone_mapping[stone_name] = shard_data

      print("Created " .. stone_name .. " with the soul of --- " .. shard_data.name .. " ---")

    -- summon pet spells
    elseif ( shard_consuming_spell(spell_name, core.SUMMON_PET_NAMES) ) then
      local shard_data = get_next_shard_data()
      shard_mapping[next_shard_location.bag][next_shard_location.index] = nil

      print("Summoned " .. spell_name .. " with the soul of --- " .. shard_data.name .. " ---")

    -- consuming healthstone 
    elseif ( stone_mapping[spell_name] ~= nil ) then
      stone_data = stone_mapping[spell_name]
      stone_mapping[spell_name] = nil

      print("Consumed the soul of: " .. stone_data.name)

    -- consuming soulstone
    elseif ( stone_mapping[spell_id] ~= nil ) then
      stone_data = stone_mapping[spell_id]
      stone_mapping[spell_name] = nil

      print("Consumed the soul of: " .. stone_data.name)
    end
  end)



-- TODO: On summon, dont set to nil; figure this out
-- ---> STOP_CHANNELING > BAG_UPDATE; on successful summon
-- ---> Can have bool is_summoning whiel channeling; 
-- TODO: Created HS/SS will show --made with soul of "x"--; then maybe option to announce on use of SS/summon whose
--        soul it is :D
-- TODO: How to handle spellstone/firestone? Just map data and make the UI show when hovering over it?
-- TODO: Handle if player destroys a shard
-- TODO: Reset data option
-- TODO: Make sure drain_soul/shadowburn checks if enemy yielded xp/honor before mapping shard
-- TODO: Problem: Soul shard appearing in bag other than shadowburn/drain_soul; e.g. pet desummon flight path
    --  >> Solution: On BAG UPDATE check if soul shard and mark as no data initially all the time? 
    --  >> Would this occur before or after mapping? 
-- TODO: Add little UI option that always shows next available soul (like a little square somewhere)
--  **** Can also have text there.. e.g. summoning pet/ creating hs/ with soul of.. w/e can add all these as options
-- TODO: List of all warlocks with available SS?


-- TODO: FOR TESTING -- REMOVE ME!!!!
--[[
local test_frame = CreateFrame("Frame")
test_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
test_frame:SetScript("OnEvent",
  function(self, event)
    --print_target_debuffs()
  end)

local cast_start_frame = CreateFrame("Frame")
cast_start_frame:RegisterEvent("UNIT_SPELLCAST_START")
cast_start_frame:SetScript("OnEvent", 
  function(self,event,...)
    local unit_target, cast_guid, spell_id = ...
    local spell_name = GetSpellInfo(spell_id)
    print("Name: " .. spell_name .. ", ID: " .. spell_id)

    -- consuming health stone 
    if ( stone_mapping[spell_name] ~= nil ) then
      stone_data = stone_mapping[spell_name]
      print("Consumed the soul of: " .. stone_data.name)

    -- consuming soul stone
    elseif ( stone_mapping[spell_id] ~= nil ) then
      stone_data = stone_mapping[spell_id]
      print("Consumed the soul of: " .. stone_data.name)
    end
  end)


]]--
-- END
