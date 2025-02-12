---@class AbstractFramework
local AF = {}
_G.AbstractFramework = AF

-- no operation
AF.noop = function() end

---------------------------------------------------------------------
-- libs
---------------------------------------------------------------------
AF.LSM = LibStub("LibSharedMedia-3.0")
AF.LCG = LibStub("LibCustomGlow-1.0")

---------------------------------------------------------------------
-- game version
---------------------------------------------------------------------
AF.isAsian = LOCALE_zhCN or LOCALE_zhTW or LOCALE_koKR

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    AF.isRetail = true
    AF.flavor = "retail"
elseif WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
    AF.isCata = true
    AF.flavor = "cata"
elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
    AF.isWrath = true
    AF.flavor = "wrath"
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    AF.isVanilla = true
    AF.flavor = "vanilla"
end

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

AF.UIParent:RegisterEvent("FIRST_FRAME_RENDERED")
AF.UIParent:SetScript("OnEvent", function(self, event)
    AF.UIParent:UnregisterEvent("FIRST_FRAME_RENDERED")
    AF.UIParent:RegisterEvent("UI_SCALE_CHANGED")
    AF.UIParent:SetScript("OnEvent", DelayedUpdatePixels)
end)

-- function AF.SetIgnoreParentScale(ignore)
--     AF.UIParent:SetIgnoreParentScale(ignore)
-- end

--! scale should NOT be TOO SMALL
--! or it will result in abnormal display of borders
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
    -- if not AF.UIParent:IsIgnoringParentScale() then
        UpdatePixels()
    -- end
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