---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- normal glow
---------------------------------------------------------------------
---@param parent Frame
---@param size number
---@param color string
---@param alpha number
---@param autoHide boolean only available for the first call
function AF.ShowNormalGlow(parent, size, color, alpha, autoHide)
    if not parent.normalGlow then
        parent.normalGlow = CreateFrame("Frame", nil, parent, "BackdropTemplate")

        if autoHide then
            parent.normalGlow:SetScript("OnHide", function() parent.normalGlow:Hide() end)
        end
    end

    parent.normalGlow:SetBackdrop({edgeFile = AF.GetTexture("StaticGlow"), edgeSize = AF.ConvertPixelsForRegion(size or 5, parent)})
    AF.SetOutside(parent.normalGlow, parent, size or 5)
    parent.normalGlow:SetBackdropBorderColor(AF.GetColorRGB(color or "accent", alpha))

    parent.normalGlow:Show()
end

function AF.HideNormalGlow(parent)
    if parent.normalGlow then
        parent.normalGlow:Hide()
    end
end

---------------------------------------------------------------------
-- callout glow
---------------------------------------------------------------------
---@param parent Frame
---@param blink boolean only available for the first call
---@param autoHide boolean only available for the first call
function AF.ShowCalloutGlow(parent, blink, autoHide)
    if not parent.calloutGlow then
        parent.calloutGlow = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        parent.calloutGlow:SetBackdrop({edgeFile = AF.GetTexture("CalloutGlow"), edgeSize = 7})
        parent.calloutGlow:SetBorderBlendMode("ADD")
        AF.SetOutside(parent.calloutGlow, parent, 4)

        if autoHide then
            parent.calloutGlow:SetScript("OnHide", function() parent.calloutGlow:Hide() end)
        end

        if blink then
            AF.CreateBlinkAnimation(parent.calloutGlow, 0.5)
        end
    end

    parent.calloutGlow:Show()
end

function AF.HideCalloutGlow(parent)
    if parent.calloutGlow then
        parent.calloutGlow:Hide()
    end
end