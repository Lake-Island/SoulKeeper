SOUL_BAG = 3
NORMAL_BAG = 0
MAX_BAG_INDEX = 4
SOUL_SHARD_ID = 6265
DRAIN_SOUL = "Drain Soul"
UNIT_DIED = "UNIT_DIED"

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
}
next_open_slot = {}
shard_added = false

-- Reset kill data and drain soul start/end times
function resetData()
    drain_soul    = { start_t = -1, end_t = -1 }
    killed_target = { time = -1 }
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

    -- TODO: Helper function to map location (e.g. shard) to killer info
    -- confirm shard added in previous bag location, then map killer info to last space (e.g. shard) 
    if shard_added then
      shard_added = false
      local item_id = GetContainerItemID(next_open_slot['bag_number'], next_open_slot['open_index'])
      if item_id == SOUL_SHARD_ID then
        print(
         "Soul shard added to bag : " .. 
          next_open_slot['bag_number'] .. ", slot " .. next_open_slot['open_index']
        )
      end
    end

    if next(open_soul_bag) ~= nil then 
      next_open_slot = open_soul_bag
      --[[
      print("Soul Bag")
      print("Bag #: " .. next_open_slot['bag_number'])
      print("Index #: " .. next_open_slot['open_index'])
      --]]
    elseif next(open_normal_bag) ~= nil then
      next_open_slot = open_normal_bag
      --[[
      print("Regular Bag")
      print("Bag #: " .. next_open_slot['bag_number'])
      print("Index #: " .. next_open_slot['open_index'])
      --]]
    else
      next_open_slot = {} 
    end
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
      --[[ TODO: 
        1. Check if shard entered bag
        2. Check next available back slot since last change (soul bag first) for a shard to update!
      --]]
      -- TODO: REMOVE ME!!!
      -- Target details to save on shard
      --print("Name: " .. killed_target.name)
      --print("Location: " .. killed_target.location)
      -- TODO: What to do with class/race?
      if killed_target.class ~= nil and killed_target.race ~= nil then 
        print("Class: " .. killed_target.class)
        print("Race: " .. killed_target.race)
      end

      -- TODO: 
      -- >> Move this to a frame on BAG_UPDATE, then under this comment check to see if shard was added 
      -- in that available slot. 
      -- POSSIBLE BUG: Will the shard going into the bag trigger the BAG_UPDATE frame and change the space 
      -- before I check for the shard? This would result in a pointer to the next available space when it should 
      -- be pointing to the space the shard was placed in.
      if next(next_open_slot) ~= nil then 
        print("Soul captured!") 
        print(killed_target.name .. ", " .. killed_target.location)
        print("Storing in bag " .. next_open_slot['bag_number'] .. " slot " .. next_open_slot['open_index'] .. ".")
        -- TODO: Need to check if a soul shard actually gets stored there, check ID? 
        -- NOTE: Shard ID ... 6265
       
        -- TODO: its null... bag doesnt update w/ shard yet!
        -- >>>>> set flag  so on next bag update it'll know since the last update a shard was addded!
        shard_added = true
      else
        print("Bags full, cant store soul!")
      end
      
    else
      -- Drain soul failed
    end

    resetData()
  end
end)

-- TODO: WHAT ABOUT SHADOWBURN!!!!

-- END
