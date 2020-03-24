DRAIN_SOUL = "Drain Soul"
UNIT_DIED = "UNIT_DIED"

last_kill_time = -1
drain_soul_end = -1
drain_soul_start = -1
killed_target_name = ""
killed_target_location = ""

-- Return player subzone and realzone as concatenated string
function getPlayerZone()
    local real_zone = GetRealZoneText()
    local sub_zone = GetSubZoneText()
    if sub_zone ~= real_zone and sub_zone ~= "" then
      return subzone .. ", " .. real_zone
    else
      return real_zone
    end
end

-- Reset kill data and drain soul start/end times
function resetData()
    last_kill_time = -1
    drain_soul_start = -1
    drain_soul_end = -1
    killed_target_name = ""
    killed_target_location = ""
end

-- From the Combat Log save the name, time, and location enemy was killed
combat_log_frame = CreateFrame("Frame")
combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combat_log_frame:SetScript("OnEvent", function(self,event)
  curr_time = GetTime()
  local _, subevent, _, _, _, _, _, _, dest_name = CombatLogGetCurrentEventInfo()
  if subevent == UNIT_DIED then 
    last_kill_time = curr_time
    killed_target_name = dest_name 
    killed_target_location = getPlayerZone()
    -- TODO: Does this work for ally?
    -- TODO: Want to save ally race and class
    print("KILL TIME : " .. last_kill_time)
    print("name: " .. dest_name)
    print("zone: " .. killed_target_location)
  end
end)

-- Save the time drain soul started channeling
local channel_start_frame = CreateFrame("Frame")
channel_start_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
channel_start_frame:SetScript("OnEvent", function(self,event, ...)
  spell_name, _, _, start_time = ChannelInfo()  
  if spell_name == DRAIN_SOUL then 
    -- ChannelInfo() multiplies time by 1000, undo that.
    drain_soul_start = start_time/1000
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
    drain_soul_end = curr_time
    --[[ TODO: REMOVE ME!!!
    print("Start: " .. drain_soul_start)
    print("End: " .. drain_soul_end)
    print("Kill: " .. last_kill_time)
    --]]

    -- kill time occured during drain soul; check to update shard
    if ( last_kill_time >= drain_soul_start 
         and last_kill_time <= drain_soul_end
         and last_kill_time ~= -1 
         and drain_soul_start ~= -1
         and drain_soul_end ~= -1
       ) then 
      --[[ TODO: 
        0. Save name and location of enemy in combat_log_frame 
          --> Save name and class if player
        1. Check if shard entered bag
        2. Save name and location of killed enemy
        3. Check next available back slot since last change (soul bag first) for a shard to update!
      --]]
      print("YOU TRAPPED A SOUL!!!!")  -- TODO: REMOVE ME!!!
      print("Killed target name: " .. killed_target_name)
      print("Location: " .. killed_target_location)
    else
      print("NO SOUL FOR YOU!!!!")     -- TODO: REMOVE ME!!!
    end

    resetData()
  end
end)


-- END
