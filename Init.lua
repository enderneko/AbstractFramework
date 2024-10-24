_G.AbstractWidgets = {}

---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- vars
---------------------------------------------------------------------
AW.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
AW.isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
AW.isCata = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

---------------------------------------------------------------------
-- UIParent
---------------------------------------------------------------------
AW.UIParent = CreateFrame("Frame", "AWParent", UIParent)
AW.UIParent:SetAllPoints(UIParent)
AW.UIParent:SetFrameLevel(0)

local function UpdatePixels()
    if InCombatLockdown() then
        AW.UIParent:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    AW.UIParent:UnregisterEvent("PLAYER_REGEN_ENABLED")
    AW.UpdatePixels()
end

local timer
local function DelayedUpdatePixels()
    if timer then timer:Cancel() end
    timer = C_Timer.NewTimer(1, UpdatePixels)
end

-- hooksecurefunc(UIParent, "SetScale", UpdatePixels)
-- AW.UIParent:RegisterEvent("DISPLAY_SIZE_CHANGED")
AW.UIParent:RegisterEvent("UI_SCALE_CHANGED")
AW.UIParent:SetScript("OnEvent", DelayedUpdatePixels)

-- function AW.SetIgnoreParentScale(ignore)
--     AW.UIParent:SetIgnoreParentScale(ignore)
-- end

--! scale CANNOT be TOO SMALL (effectiveScale should >= 0.43)
--! or it will lead to abnormal display of borders
--! since AW has changed SetSnapToPixelGrid / SetTexelSnappingBias
function AW.SetScale(scale)
    AW.UIParent:SetScale(scale)
    UpdatePixels()
end

function AW.GetScale()
    return AW.UIParent:GetScale()
end

function AW.SetUIParentScale(scale)
    UIParent:SetScale(scale)
    if not AW.UIParent:IsIgnoringParentScale() then
        UpdatePixels()
    end
end

---------------------------------------------------------------------
-- slash command
---------------------------------------------------------------------
_G["SLASH_ABSTRACTWIDGETS1"] = "/abstractwidgets"
_G["SLASH_ABSTRACTWIDGETS2"] = "/abstract"
_G["SLASH_ABSTRACTWIDGETS3"] = "/aw"
SlashCmdList.ABSTRACTWIDGETS = function()
    AW.ShowDemo()
end

---------------------------------------------------------------------
-- enable / disable
---------------------------------------------------------------------
function AW.SetEnabled(isEnabled, ...)
    if isEnabled == nil then isEnabled = false end

    for _, w in pairs({...}) do
        if w:IsObjectType("FontString") then
            if isEnabled then
                w:SetTextColor(AW.GetColorRGB("white"))
            else
                w:SetTextColor(AW.GetColorRGB("disabled"))
            end
        elseif w:IsObjectType("Texture") then
            if isEnabled then
                w:SetDesaturated(false)
            else
                w:SetDesaturated(true)
            end
        elseif w.SetEnabled then
            w:SetEnabled(isEnabled)
        elseif isEnabled then
            w:Show()
        else
            w:Hide()
        end
    end
end

function AW.Enable(...)
    AW.SetEnabled(true, ...)
end

function AW.Disable(...)
    AW.SetEnabled(false, ...)
end

---------------------------------------------------------------------
-- misc
---------------------------------------------------------------------
function AW.Unpack2(t)
    return t[1], t[2]
end

function AW.Unpack3(t)
    return t[1], t[2], t[3]
end

function AW.Unpack4(t)
    return t[1], t[2], t[3], t[4]
end

function AW.Round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces >= 0 then
        local mult = 10 ^ numDecimalPlaces
        return floor(num * mult + 0.5) / mult
    end
    return floor(num + 0.5)
end

-- function AW.Copy(...)
--     local newTbl = {}
--     for i = 1, select("#", ...) do
--         local t = select(i, ...)
--         for k, v in pairs(t) do
--             if type(v) == "table" then
--                 newTbl[k] = AW.Copy(v)
--             else
--                 newTbl[k] = v
--             end
--         end
--     end
--     return newTbl
-- end

-- function AW.Merge(t, ...)
--     for i = 1, select("#", ...) do
--         local _t = select(i, ...)
--         for k, v in pairs(_t) do
--             if type(v) == "table" then
--                 t[k] = AW.Copy(v)
--             else
--                 t[k] = v
--             end
--         end
--     end
-- end