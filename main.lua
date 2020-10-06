local _, core = ...

local ALERT = "alert"
local GROUP = "group"
local EMOTE = "emote"
local RESET_DATA = "reset"
local HELP = "help"
local EMPTY_STR = ""

local function print_help()
  help_data = {
    "***************** SoulKeeper *****************",
    "/sk alert >> Toggle printing alerts to chat.",
    "/sk group >> Toggle sending messages to your raid/party.",
    "/sk emote >> Toggle displaying emotes.",
    "/sk reset >> Reset all data."
  }

  for i=1, #help_data do 
    print(help_data[i])
  end
end


local function soulkeeper(cmd)
  if cmd == ALERT then
    if core.toggle_alert() then
      core.print_color("Enabled alerts.", core.GREEN)
    else
      core.print_color("Disabled alerts.", core.YELLOW)
    end
  elseif cmd == GROUP then
    if core.toggle_group_messages() then
      core.print_color("Enabled group messaging.", core.GREEN)
    else
      core.print_color("Disabled group messaging.", core.YELLOW)
    end
  elseif cmd == EMOTE then
    if core.toggle_emote() then
      core.print_color("Enabled emotes.", core.GREEN)
    else
      core.print_color("Disabled emotes.", core.YELLOW)
    end
  elseif cmd == RESET_DATA then
    core.reset_mapping_data() 
    core.print_color("Shard data reset.", core.RED)
  elseif cmd == EMPTY_STR or cmd == HELP then
    print_help()
  end
end


SLASH_SOULKEEPER1 = "/soulkeeper"
SlashCmdList["SOULKEEPER"] = soulkeeper

SLASH_SK1 = "/sk"
SlashCmdList["SK"] = soulkeeper
