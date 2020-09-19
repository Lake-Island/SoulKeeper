local _, core = ...
RESET_DATA = "reset"
HELP = "help"
EMPTY_STR = ""


local function print_help()
  help_data = {
    "Soulkeeper - - - - - - - - - - - - - - - - - - - - - -",
    "/sk reset >> reset all data" 
  }

  for i=1, #help_data do 
    print(help_data[i])
  end
end


local function soulkeeper(cmd)
  if cmd == RESET_DATA then
    print("Resetting data...")
    core.reset_mapping_data() 
  elseif cmd == EMPTY_STR or cmd == HELP then
    print_help()
  end
end


SLASH_SOULKEEPER1 = "/soulkeeper"
SlashCmdList["SOULKEEPER"] = soulkeeper

SLASH_SK1 = "/sk"
SlashCmdList["SK"] = soulkeeper
