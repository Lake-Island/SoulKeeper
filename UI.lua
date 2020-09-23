local _, core

local my_frame = CreateFrame("FRAME")
my_frame.name = "SK_FRAME"
my_frame:SetSize(100,20); -- width, height
my_frame:SetPoint("CENTER", UIParent, "CENTER")

my_frame:SetBackdrop(
    {
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        tileSize = 5,
        edgeSize = 2
    }
)
my_frame:SetBackdropColor(0, 0, 0, 0.8)
my_frame:SetBackdropBorderColor(0, 0, 0, 0.8)

my_frame:SetMovable(true)
my_frame:SetClampedToScreen(true)

my_frame:SetScript(
    "OnMouseDown",
    function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        end
    end
)
my_frame:SetScript("OnMouseUp", my_frame.StopMovingOrSizing)

my_frame.text = my_frame:CreateFontString(nil, "OVERLAY")
my_frame.text:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")
--my_frame.text:SetPoint("TOP", 0, -5)
my_frame.text:SetText("Next soul: ")

local closeButton = CreateFrame("Button", nil, my_frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", 5, 5)
