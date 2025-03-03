local addonName, SoulKeeper = ...

-- Create main addon frame
local frame = CreateFrame("Frame", "SoulKeeperFrame", UIParent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Initialize saved variables
SoulKeeperDB = SoulKeeperDB or {}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[SoulKeeper]:|r " .. msg)
end

-- Event handler function
local function EventHandler(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            Print("Addon loaded successfully.")
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
        if subEvent == "UNIT_DIED" and destGUID and destName then
            SoulKeeper:OnUnitDied(destGUID, destName)
        end
    end
end

frame:SetScript("OnEvent", EventHandler)

-- Function to handle when a unit dies
function SoulKeeper:OnUnitDied(guid, name)
    -- Logic for when a unit dies (Soul Shard tracking, notifications, etc.)
    Print("Soul shard potential from: " .. name)
end

-- Slash command to open settings
SLASH_SOULKEEPER1 = "/soulkeeper"
SlashCmdList["SOULKEEPER"] = function()
    SoulKeeper:ToggleSettings()
end

-- Function to toggle settings UI
function SoulKeeper:ToggleSettings()
    if not SoulKeeperSettingsFrame then
        SoulKeeper:CreateSettingsUI()
    end
    if SoulKeeperSettingsFrame:IsShown() then
        SoulKeeperSettingsFrame:Hide()
    else
        SoulKeeperSettingsFrame:Show()
    end
end

-- Function to create settings UI
function SoulKeeper:CreateSettingsUI()
    local frame = CreateFrame("Frame", "SoulKeeperSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 360)
    frame:SetPoint("CENTER")
    
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("SoulKeeper Settings")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 24)
    closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    frame:Hide()
end
