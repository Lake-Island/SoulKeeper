last_kill_time = -1
drain_soul_start = -1
drain_soul_end = -1
DRAIN_SOUL = "Drain Soul"

-- From the Combat Log save the kill time of the last enemy
cl_frame = CreateFrame("Frame")
cl_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
cl_frame:SetScript("OnEvent", function(self,event)
  curr_time = GetTime()
  local _, subevent = CombatLogGetCurrentEventInfo()
  if subevent == "UNIT_DIED" then 
    last_kill_time = curr_time
    print("Enemy killed at: " .. curr_time) 
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

    -- TODO: REMOVE ME!!!!
    print("Started casting at: " .. drain_soul_start)
    print("Stopped casting at: " .. drain_soul_end) 
    print("Enemy died at: " .. last_kill_time)

    -- kill time occured during drain soul
    if ( last_kill_time >= drain_soul_start and last_kill_time <= drain_soul_end) then 
      -- TODO: 
      -- 1. Check if yielded honor/xp
      -- 2. Save name and location of killed enemy
      -- 3. Check next available back slot since last change (soul bag first) for a shard to update!
      print("YOU TRAPPED A SOUL!!!!")
    else
      print("NO SOUL FOR YOU!!!!")
    end

    -- reset
    last_kill_time = -1
    drain_soul_start = -1
    drain_soul_end = -1

  end
end)


-- END
