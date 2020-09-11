local _, core = ...

-- Start and end time of last cast 'Drain Soul'
drain_soul = { 
  start_t = -1, 
  end_t = -1 
}

killed_target = {
  time = -1,
  name = "",
  race = "",
  class = "",
  location = ""
  -- TODO: Add level if alliance? 
}

-- Mapping of soul shards to bag indices
-- TODO: Save these values between sessions
shard_slots = { {}, {}, {}, {}, {} }

-- next available slot in bags (soul bag priority)
next_open_slot = {}
shard_added = false

-- Reset drain soul start/end times
function resetData()
    drain_soul = { start_t = -1, end_t = -1 }
end

--[[ From the Combat Log save the targets details, time, and location of kill --]]
local combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  local curr_time = GetTime()
  local _, subevent, _, _, _, _, _, dest_guid, dest_name = CombatLogGetCurrentEventInfo()
  if subevent == core.UNIT_DIED then 
    killed_target.time = curr_time
    killed_target.name = dest_name 
    killed_target.location = core.getPlayerZone()
    if dest_guid ~= nil then -- non npc?
      local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
      killed_target.race = race_name
      killed_target.class = class_name
    end
  end
end)


--[[ Time drain soul started channeling --]]
local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  local spell_name, _, _, start_time = ChannelInfo()  
  if spell_name == core.DRAIN_SOUL then 
    -- ChannelInfo() multiplies time by 1000 this undos that.
    drain_soul.start_t = start_time/1000
  end
end)


--[[ 
  Time drain soul stopped channeling. 
  Check if the enemy was killed during this time.
--]]
local channel_end_frame = CreateFrame("Frame")
channel_end_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
channel_end_frame:SetScript("OnEvent", function(self,event, ...)
  local _, _, spell_id = ... 
  local curr_time = GetTime()  
  local spell_name = GetSpellInfo(spell_id)

  if spell_name == core.DRAIN_SOUL then 
    drain_soul.end_t = curr_time

    -- enemy killed during drain soul?
    if ( killed_target.time >= drain_soul.start_t 
         and killed_target.time <= drain_soul.end_t
         and killed_target.time ~= -1 
         and drain_soul.start_t ~= -1
         and drain_soul.end_t ~= -1
       ) then 
      -- check if there is space for newly captured soul shard
      if next(next_open_slot) ~= nil then 
        shard_added = true
      end
    end

    resetData()
  end
end)


--[[
  On BAG_UPDATE (inventory change), check if item was a newly added soul shard. 
  Save mapping of new shard to bag index. Update next open bag slot.
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
        print(
         "Soul shard added to bag : " .. 
          bag_number .. ", slot " .. shard_index
        )
        -- save deep copy of table
        -- NOTE: Bag numbers index from [0-4] but the shard_slots table is from [1-5]
        shard_slots[bag_number+1][shard_index] = core.deep_copy(killed_target)
        print("Name: " .. shard_slots[bag_number+1][shard_index].name)
        print("Location: " .. shard_slots[bag_number+1][shard_index].location)
      end
    end

    -- update next open slot
    update_next_open_bag_slot()

    --print_shard_info()
  end)



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
          print("Next open soul bag: " .. bag_num .. " index: " .. free_slots[1])
        elseif bag_type == core.NORMAL_BAG_TYPE and next(open_normal_bag) == nil then
          open_normal_bag['bag_number'] = bag_num
          open_normal_bag['open_index'] = free_slots[1]
          print("Next open regular bag: " .. bag_num .. " index: " .. free_slots[1])
        end
      end
    end

    -- set next_open_slot to corresopnding bag/index
    if next(open_soul_bag) ~= nil then 
      next_open_slot = open_soul_bag
      print("Next shard spot SOUL BAG")
    elseif next(open_normal_bag) ~= nil then
      next_open_slot = open_normal_bag
      print("Next shard spot REGULAR BAG")
    else
      next_open_slot = {} 
    end
end


-- END
