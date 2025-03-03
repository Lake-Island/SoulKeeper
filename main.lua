local _, core = ...

local frame = nil

local function soulkeeper(cmd)
    if frame == nil then
        frame = core.create_settings_frame()
    elseif frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

SLASH_SOULKEEPER1 = "/soulkeeper"
SlashCmdList["SOULKEEPER"] = soulkeeper
SLASH_SK1 = "/sk"
SlashCmdList["SK"] = soulkeeper
