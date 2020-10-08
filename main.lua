local _, core = ...

local function soulkeeper(cmd)
  core.create_settings_frame()
end

SLASH_SOULKEEPER1 = "/soulkeeper"
SlashCmdList["SOULKEEPER"] = soulkeeper

SLASH_SK1 = "/sk"
SlashCmdList["SK"] = soulkeeper
