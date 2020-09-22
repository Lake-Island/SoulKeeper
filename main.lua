local _, core = ...
RESET_DATA = "reset"
HELP = "help"
EMPTY_STR = ""


local function print_help()
  help_data = {
    "Soulkeeper - - - - - - - - - - - - - - - - - - - - - -",
    "/sk reset >> reset all data",
    "/sk chat  >> toggle enabling chat message",
    "/sk debug >> toggle debug messages (summoning)"
  }

  for i=1, #help_data do 
    print(help_data[i])
  end
end


local function soulkeeper(cmd)
  if cmd == RESET_DATA then
    print("Resetting data...")
    core.reset_mapping_data() 
  elseif cmd == "chat" then
    core.toggle_chat()
  elseif cmd == "debug" then
    core.toggle_debug()
  elseif cmd == EMPTY_STR or cmd == HELP then
    print_help()
  end
end


SLASH_SOULKEEPER1 = "/soulkeeper"
SlashCmdList["SOULKEEPER"] = soulkeeper

SLASH_SK1 = "/sk"
SlashCmdList["SK"] = soulkeeper


-- DEBUG: Print item_name with id
--[[
local function itemid(item_id) 
  print("Item_name: " .. C_Item.GetItemNameByID(item_id))
end

SLASH_SKD1 = '/skd'
SlashCmdList["SKD"] = itemid
]]--
