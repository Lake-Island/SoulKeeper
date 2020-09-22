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

logout_time = GetServerTime()

-- Mapping of data of saved souls to bag indices
shard_mapping = { {}, {}, {}, {}, {} }

-- map conjured stone item_ID to kill data 
stone_mapping = {}

next_open_slot = {}

locked_shards = {}
shard_added = false
shard_deleted = false
stone_created = false

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


local function reset_mapping_data()
  shard_mapping = { {}, {}, {}, {}, {} }
  stone_mapping = {}
  set_default_shard_data()
end
core.reset_mapping_data = reset_mapping_data


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
local function find_next_shard()
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
local function get_next_shard_data()
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

    -- set next_open_slot to corresopnding bag/index
    if next(open_soul_bag) ~= nil then 
      next_open_slot = open_soul_bag
    elseif next(open_normal_bag) ~= nil then
      next_open_slot = open_normal_bag
    else
      next_open_slot = {} 
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
  local hs_stone_iid = core.CONSUME_HS_SID_TO_IID[spell_id] 
  local ss_stone_iid = core.CONSUME_SS_SID_TO_IID[spell_id]
  if hs_stone_iid ~= nil then return hs_stone_iid
  elseif ss_stone_iid ~=nil then return ss_stone_iid
  else return nil end
end



local current_target_frame = CreateFrame("Frame")
current_target_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
current_target_frame:SetScript("OnEvent",
  function(self, event)
    current_target_guid = UnitGUID("target")
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
  if subevent == core.UNIT_DIED then 
    killed_target.time = curr_time
    killed_target.name = dest_name 
    killed_target.location = core.getPlayerZone()
    if string.find(dest_guid, "Player") ~= nil then -- non npc?
      local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
      killed_target.race = race_name
      killed_target.class = class_name
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
      if next(next_open_slot) ~= nil then 
        shard_added = true
      end
    end
    
  -- track details of cast shadowburn (e.g. debuff duration)
  elseif spell_name == core.SHADOWBURN then
    curr_time = GetTime()
    if subevent == core.AURA_APPLIED then
      set_shadowburn_data(dest_guid, GetTime(curr_time))
    elseif subevent == core.AURA_REMOVED and curr_time >= shadowburn_data.end_time then
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
  Will not map if shard wasn't actually added (preventing errors with no xp/honor target).
  >> NOTE: Bag numbers index from [0-4] but the shard_mapping table is from [1-5]
--]]
local item_frame = CreateFrame("Frame")
item_frame:RegisterEvent("BAG_UPDATE")
item_frame:SetScript("OnEvent",
  function(self, event, ...)
    if shard_added then
      shard_added = false
      local bag_number = next_open_slot['bag_number']
      local shard_index = next_open_slot['open_index']
      local item_id = GetContainerItemID(bag_number, shard_index)
      if item_id == core.SOUL_SHARD_ID then
        shard_mapping[bag_number+1][shard_index] = core.deep_copy(killed_target)
      end
    end

    -- unless deleted, shards never 'lock' during bag_update
    if shard_deleted then 
      locked_shards =  {}
      shard_deleted = false
    end

    if stone_created then 
      stone_created = false
    end

    if stone_deleted then
      stone_mapping[locked_stone_iid] = nil
      locked_stone_iid = {}
      stone_deleted = false
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
    local bag_id, slot_id = ...
    local item_id = GetContainerItemID(bag_id, slot_id)
    if item_id == core.SOUL_SHARD_ID then

      -- select correct shard to insert from table of unlocked shards
      for index, curr_shard in pairs(locked_shards) do
        
        -- only 1 element in table; set into slot; remove from table
        if #locked_shards == 1 then
          shard_mapping[bag_id+1][slot_id] = table.remove(locked_shards,index).data

        -- swapping multiple shards; select the one from a different slot
        elseif curr_shard.bag_id ~= bag_id or curr_shard.bag_id == bag_id and curr_shard.slot_id ~= slot_id then
            shard_mapping[bag_id+1][slot_id] = table.remove(locked_shards,index).data
            break
        end
      end

      -- TODO: REMOVE ME!!!
      print("Added shard --- " .. shard_mapping[bag_id+1][slot_id].name .. " --- to map!")

    -- mark stone 'unlocked'
    elseif core.STONE_ID_TO_NAME[item_id] ~= nil then
      locked_stone_iid = {}
    end
  end)


--[[ 
  On game start/reload default init unmapped shard data.
--]]
local reload_frame = CreateFrame("Frame")
reload_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
reload_frame:SetScript("OnEvent", 
  function(self,event,...)

    set_default_shard_data()

    -- TODO: Test; comment
    current_time = GetServerTime()
    stone_mapping_expr_time = logout_time + core.FIFTEEN_MINUTES
    if current_time > stone_map_expr_time then
      print("EXPIRED: Clearing stone_mapping data...")
      stone_mapping = {}
    end
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
    local unit_target, cast_guid, spell_id = ...
    local spell_name = GetSpellInfo(spell_id)
    local consumed_stone_iid = is_consume_stone_spell(spell_id)

    -- conjure stone spells
    if shard_consuming_spell(spell_name, core.CONJURE_STONE_NAMES) and not stone_created then
      local shard_data = get_next_shard_data()
      shard_mapping[next_shard_location.bag][next_shard_location.index] = nil
      stone_iid = get_stone_item_id(spell_id, spell_name)
      stone_name = core.STONE_ID_TO_NAME[stone_iid]
      stone_mapping[stone_iid] = shard_data

      -- Avoid duplicate execution when this function runs twice
      stone_created = true 
      print("Created " .. stone_name .. " with the soul of --- " .. shard_data.name .. " ---")

    -- summon pet spells
    elseif shard_consuming_spell(spell_name, core.SUMMON_PET_NAMES) then
      local shard_data = get_next_shard_data()
      shard_mapping[next_shard_location.bag][next_shard_location.index] = nil

      print("Summoned " .. spell_name .. " with the soul of --- " .. shard_data.name .. " ---")

    elseif consumed_stone_iid ~= nil and stone_mapping[consumed_stone_iid] ~= nil then
      local stone_data = stone_mapping[consumed_stone_iid]
      stone_mapping[consumed_stone_iid] = nil

      print("Consumed the soul of: " .. stone_data.name)
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
 



-- TODO: On summon, dont set to nil; figure this out
-- ---> STOP_CHANNELING > BAG_UPDATE; on successful summon
-- ---> Can have bool is_summoning while channeling; 
--
-- TODO: When consuming...
--    1. SS: In raid/party: <target_name>, the soul of <killed_target_name> is yours.
--    2. HS: Print message to self (for now)
--    3. Summon: In raid/party: Summoning <target_name> with the soul of <killed_target_name>

-- TODO: Problem: Soul shard appearing in bag other than shadowburn/drain_soul; e.g. pet desummon flight path
    --  >> Solution: On BAG UPDATE check if soul shard and mark as no data initially all the time? 
    --  >> Would this occur before or after mapping? 
-- TODO: Add little UI option that always shows next available soul (like a little square somewhere)
--  **** Can also have text there.. e.g. summoning pet/ creating hs/ with soul of.. w/e can add all these as options
-- TODO: List of all warlocks with available SS?



-- TODO: TESTING - - - - - - - - - - - - - - - -
-- ---> Testing saving data between sessions
-- ---> Drain_soul/shadowburned target that does NOT yield xp/honor shouldn't get mapped || mess anything else up!
-- ---> DELETE SHARD > then lock/unlock a different shard; will break after first attempt
-- ---> Creating a stone when bags are full; stone_created = true; will it stay true or will bag_update run and set to false?
-- ---> SPELL_SUCCESS consuming SS/HS.. Test with SS consumption; swap with healthstones/different healthstones
-- ---> Destroy stuff
-- ---> Logout and test on relogin conjured items/stones still the same? What about after 15min?
-- ---> 15min logout -- does data get cleared? Right before 15m mark, right after 15m mark.
--
-- TODO: REFACTOR
-- ---> Refactor to no longer use spell_name is SPELLCAST_SUCCEED & get_stone_id.. use ID's instead.. would require refactoring core
-- ---> Core code.. label magic numbers... e.g. (MINOR_SS_ITEM_ID = 66666), etc..




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
