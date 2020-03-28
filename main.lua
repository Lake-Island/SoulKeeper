-- TODO: Move all constant data to .json
SOUL_BAG = 3
NORMAL_BAG = 0
MAX_BAG_INDEX = 4
SOUL_SHARD_ID = 6265
UNIT_DIED  = "UNIT_DIED"
DRAIN_SOUL = "Drain Soul"

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

next_open_slot = {}
shard_added = false

-- Maps each bag to all indices containing soul shards
-- TODO: Save these values between sessions
shard_slots = { {}, {}, {}, {}, {} }

-- Reset kill data and drain soul start/end times
function resetData()
    drain_soul    = { start_t = -1, end_t = -1 }
end

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

-- Create a deep copy of a table
function deep_copy(obj)
  if type(obj) ~= 'table' then return obj end
    local res = {}
      for k, v in pairs(obj) do res[deep_copy(k)] = deep_copy(v) end
        return res
end

-- Return the bag number and slot of next shard that will be consumed
function findNextShard()
  local next_shard = { bag = 666, index = 666 }
  for bag_num, _ in ipairs(shard_slots) do 
    for bag_index, _ in pairs(shard_slots[bag_num]) do
      if bag_num <= next_shard.bag then
        next_shard.bag = bag_num
        if bag_index <= next_shard.index then
          next_shard.index = bag_index
        end
      end
    end
  end
  return next_shard
end

-- Find next available slot in bag for a soul shard.
-- Return (bag_number, index) of next available slot in bag. 
-- Soul bag gets priority, followed by regular bag, nil if no space.
local item_frame = CreateFrame("Frame")
item_frame:RegisterEvent("BAG_UPDATE")
item_frame:SetScript("OnEvent",
  function(self, event, ...)
    local open_soul_bag = {}
    local open_normal_bag = {}
    for bag_num = 0, MAX_BAG_INDEX, 1 do
      local num_free_slots, bag_type = GetContainerNumFreeSlots(bag_num);
      if num_free_slots > 0 then
        -- get indices of all free slots
        local free_slots = GetContainerFreeSlots(bag_num)
        -- save bag number and index if not yet found for bag type
        if bag_type == SOUL_BAG and next(open_soul_bag) == nil then
          open_soul_bag['bag_number'] = bag_num
          open_soul_bag['open_index'] = free_slots[1]
        elseif bag_type == NORMAL_BAG and next(open_normal_bag) == nil then
          open_normal_bag['bag_number'] = bag_num
          open_normal_bag['open_index'] = free_slots[1]
        end
      end
    end

    -- Drain soul was successfully cast on killed target after last BAG_UPDATE
    -- Check to see if shard was added to bag
    if shard_added then
      shard_added = false
      -- TODO: Possibly check if item_id is null? This would be a bug but it would be good to catch.
      local item_id = GetContainerItemID(next_open_slot['bag_number'], next_open_slot['open_index'])
      local bag_number = next_open_slot['bag_number']
      local shard_index = next_open_slot['open_index']
      if item_id == SOUL_SHARD_ID then
        print(
         "Soul shard added to bag : " .. 
          bag_number .. ", slot " .. shard_index
        )
        -- save deep copy of table
        -- NOTE: Bag numbers index from [0-4] but the shard_slots table is from [1-5]
        shard_slots[bag_number+1][shard_index] = deep_copy(killed_target)
        print("Name: " .. shard_slots[bag_number+1][shard_index].name)
        print("Location: " .. shard_slots[bag_number+1][shard_index].location)
      end
    end

    -- save bag/index that next shard will go into
    if next(open_soul_bag) ~= nil then 
      next_open_slot = open_soul_bag
    elseif next(open_normal_bag) ~= nil then
      next_open_slot = open_normal_bag
    else
      next_open_slot = {} 
    end

    -- TODO: Remove me
    print_shard_info()
  end)

-- From the Combat Log save the targets details, time, and location of kill
local combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  local curr_time = GetTime()
  local _, subevent, _, _, _, _, _, dest_guid, dest_name = CombatLogGetCurrentEventInfo()
  if subevent == UNIT_DIED then 
    killed_target.time = curr_time
    killed_target.name = dest_name 
    killed_target.location = getPlayerZone()
    if dest_guid ~= nil then
      local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
      killed_target.race = race_name
      killed_target.class = class_name
    end
  end
end)

-- Save the time drain soul started channeling
local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  local spell_name, _, _, start_time = ChannelInfo()  
  if spell_name == DRAIN_SOUL then 
    -- ChannelInfo() multiplies time by 1000, undo that.
    drain_soul.start_t = start_time/1000
  end
end)

-- Save the time drain soul stopped channeling. Then check to see if the enemy 
-- was killed while it was being channeled.
local channel_end_frame = CreateFrame("Frame")
channel_end_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
channel_end_frame:SetScript("OnEvent", function(self,event, ...)
  local _, _, spell_id = ... 
  local curr_time = GetTime()  
  local spell_name = GetSpellInfo(spell_id)

  if spell_name == DRAIN_SOUL then 
    drain_soul.end_t = curr_time

    -- kill time occured during drain soul; check to update shard
    if ( killed_target.time >= drain_soul.start_t 
         and killed_target.time <= drain_soul.end_t
         and killed_target.time ~= -1 
         and drain_soul.start_t ~= -1
         and drain_soul.end_t ~= -1
       ) then 
       
      -- TODO: What to do with class/race?
      -- TODO: Don't believe I need this here
      if killed_target.class ~= nil and killed_target.race ~= nil then 
        print("Class: " .. killed_target.class)
        print("Race: " .. killed_target.race)
      end

      -- check if there is space for newly captured soul shard
      if next(next_open_slot) ~= nil then 
        shard_added = true
      end
    end

    resetData()
  end
end)

-- Check if shard consuming spell was successfully cast, display 
-- associated information about shard.
local cast_success_frame = CreateFrame("Frame")
cast_success_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
cast_success_frame:SetScript("OnEvent", 
  function(self,event,...)
    local unit_target, cast_guid, spell_id = ...
    local spell_name = GetSpellInfo(spell_id)
    -- TODO: Will want to check for any skills that use a soul shard
    if string.find(spell_name, "Create Healthstone") then
      print("Successfully cast: " .. spell_name)
      -- TODO: Need to know which shard is the next up to be used
      -- >> Get next from shard_slots... 
      -- TODO: Make note that a requirement for this addon is to have soul bags as last slots
      next_shard = findNextShard()
      print("Used shard at bag " .. next_shard.bag .. ", slot " .. next_shard.index)

    end
  end)



-- TODO: WHAT ABOUT SHADOWBURN!!!!
-- TODO: Want to save details of soul shards on log out!
-- TODO: On login need to check all existing soul shards to see if they have details, otherwise set details to nil
-- TODO: Remove requirement for soul bags to be all the way on RHS
-- TODO: Add level of alliance soul you've saved
-- TODO: Anytime bag is updated need to check if a shard was moved, if true update the mapping

-- TODO: REMOVE ME!!!!
-- Prints all slots in mapped to shards
function print_shard_info() 
  for i=1, 5 do
    for j=1, 16 do
      if shard_slots[i][j] ~= nil then
        print("Bag " .. i-1 .. " slot " .. j ..
       "\nKilled " .. shard_slots[i][j].name
        .. "\n Location: " .. shard_slots[i][j].location)
      end
    end
  end
end

-- END
