_G.AbstractFramework = {}

---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- vars
---------------------------------------------------------------------
AF.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
AF.isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
AF.isCata = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

---------------------------------------------------------------------
-- UIParent
---------------------------------------------------------------------
AF.UIParent = CreateFrame("Frame", "AFParent", UIParent)
AF.UIParent:SetAllPoints(UIParent)
AF.UIParent:SetFrameLevel(0)

local function UpdatePixels()
    if InCombatLockdown() then
        AF.UIParent:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    AF.UIParent:UnregisterEvent("PLAYER_REGEN_ENABLED")
    AF.UpdatePixels()
end

local timer
local function DelayedUpdatePixels()
    if timer then timer:Cancel() end
    timer = C_Timer.NewTimer(1, UpdatePixels)
end

-- hooksecurefunc(UIParent, "SetScale", UpdatePixels)
-- AF.UIParent:RegisterEvent("DISPLAY_SIZE_CHANGED")
AF.UIParent:RegisterEvent("UI_SCALE_CHANGED")
AF.UIParent:SetScript("OnEvent", DelayedUpdatePixels)

-- function AF.SetIgnoreParentScale(ignore)
--     AF.UIParent:SetIgnoreParentScale(ignore)
-- end

--! scale CANNOT be TOO SMALL (effectiveScale should >= 0.43)
--! or it will lead to abnormal display of borders
--! since AF has changed SetSnapToPixelGrid / SetTexelSnappingBias
function AF.SetScale(scale)
    AF.UIParent:SetScale(scale)
    UpdatePixels()
end

function AF.GetScale()
    return AF.UIParent:GetScale()
end

function AF.SetUIParentScale(scale)
    UIParent:SetScale(scale)
    if not AF.UIParent:IsIgnoringParentScale() then
        UpdatePixels()
    end
end

---------------------------------------------------------------------
-- slash command
---------------------------------------------------------------------
_G["SLASH_ABSTRACTFRAMEWORK1"] = "/abstract"
_G["SLASH_ABSTRACTFRAMEWORK2"] = "/afw"
_G["SLASH_ABSTRACTFRAMEWORK3"] = "/af"
SlashCmdList.ABSTRACTFRAMEWORK = function()
    AF.ShowDemo()
end

---------------------------------------------------------------------
-- enable / disable
---------------------------------------------------------------------
function AF.SetEnabled(isEnabled, ...)
    if isEnabled == nil then isEnabled = false end

    for _, w in pairs({...}) do
        if w:IsObjectType("FontString") then
            if isEnabled then
                w:SetTextColor(AF.GetColorRGB("white"))
            else
                w:SetTextColor(AF.GetColorRGB("disabled"))
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

function AF.Enable(...)
    AF.SetEnabled(true, ...)
end

function AF.Disable(...)
    AF.SetEnabled(false, ...)
end

---------------------------------------------------------------------
-- misc
---------------------------------------------------------------------
function AF.Unpack2(t)
    return t[1], t[2]
end

function AF.Unpack3(t)
    return t[1], t[2], t[3]
end

function AF.Unpack4(t)
    return t[1], t[2], t[3], t[4]
end

function AF.Round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces >= 0 then
        local mult = 10 ^ numDecimalPlaces
        return floor(num * mult + 0.5) / mult
    end
    return floor(num + 0.5)
end

-- function AF.Copy(...)
--     local newTbl = {}
--     for i = 1, select("#", ...) do
--         local t = select(i, ...)
--         for k, v in pairs(t) do
--             if type(v) == "table" then
--                 newTbl[k] = AF.Copy(v)
--             else
--                 newTbl[k] = v
--             end
--         end
--     end
--     return newTbl
-- end

-- function AF.Merge(t, ...)
--     for i = 1, select("#", ...) do
--         local _t = select(i, ...)
--         for k, v in pairs(_t) do
--             if type(v) == "table" then
--                 t[k] = AF.Copy(v)
--             else
--                 t[k] = v
--             end
--         end
--     end
-- end