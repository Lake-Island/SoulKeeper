SOUL_BAG = 3
NORMAL_BAG = 0
SLOT_NULL  = 666
MAX_BAG_INDEX = 4
SOUL_SHARD_ID = 6265
UNIT_DIED  = "UNIT_DIED"
DRAIN_SOUL = "Drain Soul"
SPELL_NAMES = {
  -- TODO: List spells that consume shards
  HS = "Create Healthstone",
  SS = "Create Soulstone"
}

-- TODO: MOVE ALL THIS TO CONFIG FILE!!!
STONE_NAME = {}
-- HS
STONE_NAME["Create Healthstone (Minor)"] = "Minor Healthstone"
STONE_NAME["Create Healthstone (Lesser)"] = "Lesser Healthstone"
STONE_NAME["Create Healthstone"] = "Healthstone"
STONE_NAME["Create Healthstone (Greater)"] = "Greater Healthstone"
STONE_NAME["Create Healthstone (Major)"] = "Major Healthstone"
-- SS
STONE_NAME["Create Soulstone (Minor)"] = "Minor Soulstone"
STONE_NAME["Create Soulstone (Lesser)"] = "Lesser Soulstone"
STONE_NAME["Create Soulstone"] = "Soulstone"
STONE_NAME["Create Soulstone (Greater)"] = "Greater Soulstone"
STONE_NAME["Create Soulstone (Major)"] = "Major Soulstone"
-- Spellstone
STONE_NAME["Create Spellstone"] = "Spellstone"
STONE_NAME["Create Spellstone (Greater)"] = "Greater Spellstone"
STONE_NAME["Create Spellstone (Major)"] = "Major Spellstone"
-- Firestone
STONE_NAME["Create Firestone (Lesser)"] = "Lesser Firestone"
STONE_NAME["Create Firestone"] = "Firestone"
STONE_NAME["Create Firestone (Greater)"] = "Greater Firestone"
STONE_NAME["Create Firestone (Major)"] = "Major Firestone"

-- Map all created Healthstones and Soulstones to shard info
-- TODO: Need to save this between sessions, then check on login
-- if the HS/SS is still in the bag, if so leave it otherwise
-- reset these tables
created_hs = {}
created_ss = {}

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

-- data of shard selected from bag
-- XXX: When two existing shard slots are swapped the order is 
--       they are both locked before unlocked. Need to cache
--       data for both.
locked_shard_data = {
  last = nil,
  first = nil,
}

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
  local next_shard = { bag = SLOT_NULL, index = SLOT_NULL }
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
  next_shard.bag = next_shard.bag
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
    --print_shard_info()
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
    -- TODO: Make a helper function that checks if skill was any that 
    -- consumes a shard, should return a boolean
    if string.find(spell_name, SPELL_NAMES.HS) or 
       string.find(spell_name, SPELL_NAMES.SS) then
      next_shard = findNextShard()
      if next_shard.bag ~= SLOT_NULL then   -- prevents duplicate executions
        local shard_info = shard_slots[next_shard.bag][next_shard.index]

        -- XXX: REMOVE ME
        print("Successfully cast: " .. spell_name)
        print("Soul of '" .. shard_info.name .. "'")
        print("Location: " .. shard_info.location)
  
        -- remove shard from mapping
        shard_slots[next_shard.bag][next_shard.index] = nil

        -- TODO: 'SAY' MUST be on hardware press (e.g. mouse click)
        -- ----> Possibly on trade for HS/ how for SS? other skills? er...
        -- ----> I remember /say working in strath w/ jiinx, clouds when I created a HS
        mssg = spell_name .. " with the soul of " .. shard_info.name .. "!"
        SendChatMessage(mssg, "WHISPER", 1, "Krel")
        
        -- Map created SS and HS to killed player info. 
        if string.find(spell_name, SPELL_NAMES.HS) then
          --- XXX: TODO: This should run when I create a HS
          print("H1 - - - - - - ")
          created_hs[STONE_NAME[spell_name]] = shard_info
          -- TODO: Now when you consume/trade the HS print the corresponding info
          -- ----> Then nullify the entry in the mapping
          -- ----> This mapping must be cleared after logging out for 15min 
          -- ----> MUST CHECK INVENTORY ON LOGIN TO MAKE SURE MAPPING STILL EXISTS
        elseif string.find(spell_name, SPELL_NAMES.SS) then
          -- TODO: Figure out how to map created SS to shard_info
        end
      end
    -- Consume HS (non spell cast)
    elseif string.find(spell_name, "Healthstone") then
      print("H2 - - - - - -")
      local hs_info = created_hs[spell_name]
      if hs_info ~= nil then  -- runs multiple extra times
        print("Successfully cast: " .. spell_name)
        print("Soul of '" .. hs_info.name .. "'")
        print("Location: " .. hs_info.location)
      end
    end
  end)
  
-- Check if item selected from bag is a soul shard, 
-- if true remove existing mapping.
local bag_slot_lock_frame = CreateFrame("Frame")
bag_slot_lock_frame:RegisterEvent("ITEM_LOCKED")
bag_slot_lock_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag_id, slot_id = ...
    local item_id = GetContainerItemID(bag_id, slot_id)
    if item_id == SOUL_SHARD_ID then
      print("Removing shard from map!")
      print("From [" .. bag_id .. ", " .. slot_id .. "]")

      -- save data, remove from map 
      if locked_shard_data.first == nil then
        locked_shard_data.first = shard_slots[bag_id+1][slot_id]
      else
        locked_shard_data.last = shard_slots[bag_id+1][slot_id]
      end
      shard_slots[bag_id+1][slot_id] = nil
    end
  end)

-- Check if item inserted into bag is a soul shard,
-- if true add new mapping.
local bag_slot_unlock_frame = CreateFrame("Frame")
bag_slot_unlock_frame:RegisterEvent("ITEM_UNLOCKED")
bag_slot_unlock_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag_id, slot_id = ...
    local item_id = GetContainerItemID(bag_id, slot_id)
    if item_id == SOUL_SHARD_ID then
      print("Adding shard to map!")
      print("To [" .. bag_id .. ", " .. slot_id .. "]")

      if locked_shard_data.first == nil then
        shard_slots[bag_id+1][slot_id] = locked_shard_data.last
        locked_shard_data.last = nil
      else
        shard_slots[bag_id+1][slot_id] = locked_shard_data.first
        locked_shard_data.first = nil
      end
    end
  end)

-- 1. Map newly created SS/HS to corresponding kill details 
-- ---> TODO: Test spellstones/firestones, when consumed what's the spell called?
--
-- 2. On use of SS/trade of HS announce whose soul it was in '/say'
-- ---> How will I know what bag item was used? 
--
-- 3. What if shard/HS/SS is destroyed? 
-- --> Need to remove mapping!  
-- --> Possibly write a message saying 'throwing away worthless soul of enemy_name'
--
-- 4. Testing
-- ---> TODO: After logging out for 15min HS/SS will disappear... Need to check on login 
-- ----> if its still there.. iterate through all bags looking for matching healthstones? 
-- ****** Basically if I find one then dont delete them, if i dont find any then reset the table
--
-- 4. Save details of soul shard on logout 
--    4.b. On login make sure to check all bag slots and mark un-mapped shards as nil
--    ---> If shard nil, player will announce it was made from a unkown soul
-- 5. Look into adding other skills
--
-- 6. Add options for user customization

-- TODO: Think about how I plan to design this. How much can the user choose? 
-- What exactly do I want to accomplish right now? What can I add later? How can I develop 
-- it so its easy to add onto later? 

-- TODO: When SS/HS is created, map space in bag to info... 
-- --> When player consumed/trades HS or uses SS will display message

-- TODO: Do I want to message self saying whose soul I used to create HS/SS or should I make an announcement 
-- when I trade a HS or soul stone somebody?
-- >>>> Skills like shadowburn can whisper to you whose soul you used? 

-- TODO: Want to save details of soul shards on log out!

-- TODO: What if you destroy a shard?
--      >> Related event: 'DELETE_ITEM_CONFIRM'

-- TODO: Shadowburn, pets, other skills

-- TODO: Move all constant data to a json 

-- TODO: On login need to check all existing soul shards to see if they have details, otherwise set details to nil

-- TODO: Remove requirement for soul bags to be all the way on RHS

-- TODO: Add level of alliance soul you've saved

-- TODO: Throw in soul stone reminder... e.g. when cooldown is up!

-- TODO: User has option to choose which spells to display mesasge for. User can also input 
--       their own custom message per spell/consumption?
--       >> Add options to determine when to announce, where to announce, etc...

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
-- TODO: REMOVE ME!!!!


-- TODO: REMOVE ME
--[[
local target_info_frame = CreateFrame("Frame")
target_info_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
target_info_frame:SetScript("OnEvent",
  function(self, event, ...)
        --spell_name = "TEST_SPELL"
        --soul_name = "TEST_SOUL"
        --mssg = "Cast " .. spell_name .. " with the soul of " .. soul_name .. "!"
        SendChatMessage("TEST STRING", "SAY")
        --SendChatMessage("TEST STRING", "WHISPER", 1, "Krel")
  end)
--]]
-- TODO: REMOVE ME!!!!

--[[
local bag_lock_frame = CreateFrame("Frame")
target_info_frame:RegisterEvent("ITEM_LOCK_CHANGED")
target_info_frame:SetScript("OnEvent",
  function(self, event, ...)
    local bag_id, slot_id = ...
    print("Bag: " .. bag_id ", slot: " .. slot_id)
    -- TODO:
    -- On successful spellcast it'll say 'first aid', but how can 
    -- I get the name of the item in the slot... e.g. wool bandage or w/e?
    -- What happens if its a healthstone, does that count as a successful spellcast?
  end)
--]]
-- TODO: Fire event when bag item is used... would use this for 
-- healthstone/SS


































-- END
