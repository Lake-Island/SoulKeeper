local _, core = ...


--[[
core.main_display_frame = CreateFrame("FRAME")
core.main_display_frame.name = "SK_FRAME"
core.main_display_frame:SetSize(100,20); -- width, height
core.main_display_frame:SetPoint("CENTER", UIParent, "CENTER")
core.main_display_frame:SetBackdrop(
    {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        tileSize = 5,
        edgeSize = 2
    }
)
core.main_display_frame:SetBackdropColor(0, 0, 0, 0.8)
core.main_display_frame:SetBackdropBorderColor(0, 0, 0, 0.8)

core.main_display_frame:SetMovable(true)
core.main_display_frame:SetClampedToScreen(true)

core.main_display_frame:SetScript(
    "OnMouseDown",
    function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end
)
core.main_display_frame:SetScript("OnMouseUp", core.main_display_frame.StopMovingOrSizing)

core.main_display_frame.text = core.main_display_frame:CreateFontString(nil, "OVERLAY")
core.main_display_frame.text:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")
core.main_display_frame.text:SetPoint("TOP", 0, -5)
core.main_display_frame.text:SetText("Next soul: ")
]]--


-- TODO: UI
--  1. Display: Frame that says 'next soul is <..>' that user can move around and resize
--  ---> Can also update to say 'creating HS with soul of "x"/summonig pet with soul of "y"'; can then 
--       go back to saying 'next available soul' or w/e
--  ---> Lock/Unlock feature through console
--  ---> Hide/show feature through console
--  ---> Resize feature through console?
--  X. Hover over shard/stone will display name of soul
--  2. Make message nice that hovers over soul shards... make alliance blue, horde red, raid boss orange, etc.
--  3. Option to display info on display (e.g. hide/unhide display); option to enable/disable shard consume info in print; 
