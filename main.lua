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

-- Return player subzone and realzone as concatenated string
function getPlayerZone()
    local real_zone = GetRealZoneText()
    local sub_zone = GetSubZoneText()
    if sub_zone ~= real_zone and sub_zone ~= nil then
      return subzone .. ", " .. real_zone
    else
      return real_zone
    end
end

-- Reset kill data and drain soul start/end times
function resetData()
    drain_soul    = { start_t = -1, end_t = -1 }
    killed_target = { time = -1 }
end

-- From the Combat Log save the targets details, time, and location of kill
combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  curr_time = GetTime()
  local _, subevent, _, _, _, _, _, _, dest_name, dest_guid = CombatLogGetCurrentEventInfo()
  local class_name, _, race_name = GetPlayerInfoByGUID(dest_guid)
  if subevent == UNIT_DIED then 
    killed_target.time = curr_time
    killed_target.name = dest_name 
    killed_target.race = race_name
    killed_target.class = class_name
    killed_target.location = getPlayerZone()
  end
end)

-- Save the time drain soul started channeling
local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  spell_name, _, _, start_time = ChannelInfo()  
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
  _, _, spell_id = ... 
  curr_time = GetTime()  
  spell_name = GetSpellInfo(spell_id)

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
        2. Get killed target details
        3. Check next available back slot since last change (soul bag first) for a shard to update!
      --]]
      print("YOU TRAPPED A SOUL!!!!")  -- TODO: REMOVE ME!!!
      print("Name: " .. killed_target.name)
      print("Location: " .. killed_target.location)
      if killed_target.class ~= nil and killed_target.race ~= nil then 
        print("Class: " .. killed_target.class)
        print("Race: " .. killed_target.race)
      end
      
    else
      print("NO SOUL FOR YOU!!!!")     -- TODO: REMOVE ME!!!
    end

    resetData()
  end
end)


-- END
