---@class AbstractFramework
local AF = _G.AbstractFramework
local LCG = AF.LCG

---------------------------------------------------------------------
-- recalc texcoords
---------------------------------------------------------------------
function AF.ReCalcTexCoordForAura(aura, width, height)
    aura.icon:SetTexCoord(unpack(AF.CalcTexCoordPreCrop(width, height, 1, 0.12)))
end

---------------------------------------------------------------------
-- cooldown style: vertical progress
---------------------------------------------------------------------
local function VerticalCooldown_OnUpdate(aura, elapsed)
    aura.elapsed = aura.elapsed + elapsed
    if aura.elapsed >= 0.1 then
        aura:SetValue(aura:GetValue() + aura.elapsed)
        aura.elapsed = 0
    end
end

-- for LCG.ButtonGlow_Start
local function VerticalCooldown_GetCooldownDuration()
    return 0
end

local function VerticalCooldown_ShowCooldown(aura, start, duration, _, icon, auraType)
    if auraType then
        aura.spark:SetColorTexture(AF.GetAuraTypeColor(auraType))
    else
        aura.spark:SetColorTexture(0.5, 0.5, 0.5, 1)
    end
    if aura.icon then
    aura.icon:SetTexture(icon)
    end

    aura.elapsed = 0.1 -- update immediately
    aura:SetMinMaxValues(0, duration)
    aura:SetValue(GetTime() - start)
    aura:Show()
end

local function CreateCooldown_Vertical(aura, hasIcon)
    local cooldown = CreateFrame("StatusBar", nil, aura)
    aura.cooldown = cooldown
    cooldown:Hide()

    cooldown.GetCooldownDuration = VerticalCooldown_GetCooldownDuration
    cooldown.ShowCooldown = VerticalCooldown_ShowCooldown
    cooldown:SetScript("OnUpdate", VerticalCooldown_OnUpdate)

    AF.SetPoint(cooldown, "TOPLEFT", aura.icon)
    AF.SetPoint(cooldown, "BOTTOMRIGHT", aura.icon, "BOTTOMRIGHT", 0, 1)
    cooldown:SetOrientation("VERTICAL")
    cooldown:SetReverseFill(true)
    cooldown:SetStatusBarTexture(AF.GetPlainTexture())

    local texture = cooldown:GetStatusBarTexture()

    local spark = cooldown:CreateTexture(nil, "BORDER")
    cooldown.spark = spark
    AF.SetHeight(spark, 1)
    spark:SetBlendMode("ADD")
    spark:SetPoint("TOPLEFT", texture, "BOTTOMLEFT")
    spark:SetPoint("TOPRIGHT", texture, "BOTTOMRIGHT")

    if hasIcon then
        texture:SetAlpha(0)

    local mask = cooldown:CreateMaskTexture()
    mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    mask:SetPoint("TOPLEFT")
    mask:SetPoint("BOTTOMRIGHT", texture)

    local icon = cooldown:CreateTexture(nil, "ARTWORK")
    cooldown.icon = icon
    icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    icon:SetDesaturated(true)
    icon:SetAllPoints(aura.icon)
    icon:SetVertexColor(0.5, 0.5, 0.5, 1)
    icon:AddMaskTexture(mask)
    cooldown:SetScript("OnSizeChanged", AF.ReCalcTexCoordForAura)
    else
        texture:SetVertexColor(0, 0, 0, 0.8)
    end
end

---------------------------------------------------------------------
-- cooldown style: clock (w/ or w/o leading edge)
---------------------------------------------------------------------
local function CreateCooldown_Clock(aura, drawEdge)
    local cooldown = CreateFrame("Cooldown", nil, aura, "AFCooldownFrameTemplate")
    aura.cooldown = cooldown
    cooldown:Hide()

    cooldown:SetAllPoints(aura.icon)
    cooldown:SetReverse(true)
    cooldown:SetDrawEdge(drawEdge)

    -- NOTE: shit, why this EDGE not work, but xml does?
    -- cooldown:SetSwipeTexture(AF.GetPlainTexture())
    -- cooldown:SetSwipeColor(0, 0, 0, 0.8)
    -- cooldown:SetEdgeTexture([[Interface\Cooldown\UI-HUD-ActionBar-SecondaryCooldown]], 1, 1, 0, 1)

    -- cooldown text
    cooldown:SetHideCountdownNumbers(true)
    -- disable omnicc
    cooldown.noCooldownCount = true
    -- prevent some dirty addons from adding cooldown text
    cooldown.ShowCooldown = cooldown.SetCooldown
    cooldown.SetCooldown = nil
end

---------------------------------------------------------------------
-- set cooldown style
---------------------------------------------------------------------
local function Aura_SetCooldownStyle(aura, style)
    if aura.style == style then return end

    if aura.cooldown then
        aura.cooldown:SetParent(nil)
        aura.cooldown:Hide()
    end

    aura.style = style
    if style == "vertical" then
        CreateCooldown_Vertical(aura, true)
    elseif style == "block_vertical" then
        CreateCooldown_Vertical(aura, false)
    elseif strfind(style, "^clock") or strfind(style, "^block_clock") then
        -- clock, clock_with_leading_edge
        -- block_clock, block_clock_with_leading_edge
        CreateCooldown_Clock(aura, strfind(style, "edge$") and true or false)
    end

    if strfind(style, "^block") then
        aura.icon:Hide()
    else
        aura.icon:Show()
    end
end

---------------------------------------------------------------------
-- glow
---------------------------------------------------------------------
local function Aura_CreateGlow(aura)
    aura.glow = CreateFrame("Frame", nil, aura, "BackdropTemplate")
    aura.glow:SetAllPoints()
    aura.glow:SetBackdrop({edgeFile = AF.GetTexture("CalloutGlow"), edgeSize = 7})
    aura.glow:SetBorderBlendMode("ADD")
    aura.glow:SetFrameLevel(aura:GetFrameLevel())
    AF.SetOutside(aura.glow, aura, 4)
    AF.CreateBlinkAnimation(aura.glow, 0.5)
end

---------------------------------------------------------------------
-- SetCooldown
---------------------------------------------------------------------
local GetTime = GetTime

local function UpdateDurationText(aura)
    if aura._remain > 86400 then
        aura.duration:SetFormattedText("%dd", aura._remain / 86400)
    elseif aura._remain > 3600 then
        aura.duration:SetFormattedText("%dh", aura._remain / 3600)
    elseif aura._remain > 60 then
        aura.duration:SetFormattedText("%dm", aura._remain / 60)
    elseif aura._remain < 5 then
        aura.duration:SetFormattedText("%.1f%s", aura._remain, aura.showSecondsUnit and "s" or "")
    else
        aura.duration:SetFormattedText("%d%s", aura._remain, aura.showSecondsUnit and "s" or "")
    end
end

local function UpdateDuration_ColorByPercentSeconds(aura, elapsed)
    if aura._elapsed >= 0.1 then
        aura._remain = aura._duration - (GetTime() - aura._start)
        if aura._remain < 0 then aura._remain = 0 end

        -- color = {
        --     AF.GetColorTable("white"), -- normal
        --     {false, 0.5, AF.GetColorTable("aura_percent")}, -- less than 50%
        --     {true,  5,   AF.GetColorTable("aura_seconds")}, -- less than 5sec
        -- }
        if aura.durationColor[3][1] and aura._remain < aura.durationColor[3][2] then
            aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[3][3]))
        elseif aura.durationColor[2][1] and aura._remain < (aura.durationColor[2][2] * aura._duration) then
            aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[2][3]))
        else
            aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[1]))
        end

        UpdateDurationText(aura)
        aura._elapsed = 0
    else
        aura._elapsed = aura._elapsed + elapsed
    end
end

local function UpdateDuration_ColorByExpiring(aura, elapsed)
    if aura._elapsed >= 0.1 then
        aura._remain = aura._duration - (GetTime() - aura._start)
        if aura._remain < 0 then aura._remain = 0 end

        -- color = {
        --     AF.GetColorTable("white"), -- normal
        --     AF.GetColorTable("aura_seconds"), -- expiring
        -- },
        if aura._remain < 5 then
            aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[2]))
        else
            aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[1]))
        end

        UpdateDurationText(aura)
        aura._elapsed = 0
    else
        aura._elapsed = aura._elapsed + elapsed
    end
end

-- local function UpdateDuration_ColorByUnit(aura, elapsed)
--     if aura._elapsed >= 0.1 then
--         aura._remain = aura._duration - (GetTime() - aura._start)
--         if aura._remain < 0 then aura._remain = 0 end

--         -- color
--         if aura.durationColor[6][1] and aura._remain < 5 then
--             aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[6][2]))
--         elseif aura.durationColor[5][1] and aura._remain < 60 then -- second
--             aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[5][2]))
--         elseif aura.durationColor[4][1] and aura._remain < 3600 then -- minute
--             aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[4][2]))
--         elseif aura.durationColor[3][1] and aura._remain < 86400 then -- hour
--             aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[3][2]))
--         elseif aura.durationColor[2][1] and aura._remain < 86400 then -- hour
--             aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[2][2]))
--         else -- day
--             aura.duration:SetTextColor(AF.UnpackColor(aura.durationColor[1]))
--         end

--         UpdateDurationText(aura)
--         aura._elapsed = 0
--     else
--         aura._elapsed = aura._elapsed + elapsed
--     end
-- end

local function UpdateDuration_NoColor(aura, elapsed)
    if aura._elapsed >= 0.1 then
        aura._remain = aura._duration - (GetTime() - aura._start)
        if aura._remain < 0 then aura._remain = 0 end

        UpdateDurationText(aura)
        aura._elapsed = 0
    else
        aura._elapsed = aura._elapsed + elapsed
    end
end

function AF.SetAuraCooldown(aura, start, duration, count, icon, auraType, desaturated, glow, r, g, b, a)
    if duration == 0 then
        if aura.cooldown then aura.cooldown:Hide() end
        aura.duration:SetText("")
        aura.stack:SetParent(aura)
        aura:SetScript("OnUpdate", nil)
        aura._start = nil
        aura._duration = nil
        aura._remain = nil
        aura._elapsed = nil
    else
        if aura.cooldown then
            -- NOTE: the "nil" is to make it compatible with Cooldown:SetCooldown(start, duration [, modRate])
            aura.cooldown:ShowCooldown(start, duration, nil, icon, auraType)
            aura.duration:SetParent(aura.cooldown)
            aura.stack:SetParent(aura.cooldown)
        else
            aura.duration:SetParent(aura)
            aura.stack:SetParent(aura)
        end
        aura._start = start
        aura._duration = duration
        aura._elapsed = 0.1
        aura:SetScript("OnUpdate", aura.UpdateDuration)
    end

    if glow then
        LCG.ButtonGlow_Start(aura, nil, nil, 0)
        if not aura.glow then
            Aura_CreateGlow(aura)
        end
        aura.glow:Show()
    else
        if aura.glow then aura.glow:Hide() end
        LCG.ButtonGlow_Stop(aura)
    end

    if r then
        aura:SetBackdropColor(r, g, b, a)
    end

    aura:SetDesaturated(desaturated)
    aura:SetBackdropBorderColor(AF.GetAuraTypeColor(auraType))
    aura.stack:SetText((count == 0 or count == 1) and "" or count)
    aura.icon:SetTexture(icon)

    if not aura:IsProtected() then
        aura:Show()
    end
end

---------------------------------------------------------------------
-- tooltip
---------------------------------------------------------------------
local function Aura_SetTooltipPosition(aura)
    if aura.tooltipAnchorTo == "aura" then
        GameTooltip:SetOwner(aura, "ANCHOR_NONE")
        GameTooltip:SetPoint(aura.tooltipPosition[1], aura, aura.tooltipPosition[2], aura.tooltipPosition[3], aura.tooltipPosition[4])
    else -- default
        GameTooltip_SetDefaultAnchor(GameTooltip, aura)
    end
end

local function Aura_ShowBuffTooltip(aura)
    Aura_SetTooltipPosition(aura)
    GameTooltip:SetUnitBuffByAuraInstanceID(aura.root.unit, aura.auraInstanceID)
    end

local function Aura_ShowDebuffTooltip(aura)
    Aura_SetTooltipPosition(aura)
    GameTooltip:SetUnitDebuffByAuraInstanceID(aura.root.unit, aura.auraInstanceID)
end

local function Aura_HideTooltips()
    GameTooltip:Hide()
end

local function Aura_EnableTooltip(aura, config, helpful)
    if config.enabled then
        aura.tooltipAnchorTo = config.anchorTo
        aura.tooltipPosition = config.position
        aura:SetScript("OnEnter", helpful and Aura_ShowBuffTooltip or Aura_ShowDebuffTooltip)
        aura:SetScript("OnLeave", Aura_HideTooltips)
    else
        aura.tooltipAnchorTo = nil
        aura.tooltipPosition = nil
        aura:SetScript("OnEnter", nil)
        aura:SetScript("OnLeave", nil)
        aura:EnableMouse(false)
    end
end

---------------------------------------------------------------------
-- desaturated
---------------------------------------------------------------------
function AF.SetAuraDesaturated(aura, desaturated)
    aura.icon:SetDesaturated(desaturated)
end

---------------------------------------------------------------------
-- stack
---------------------------------------------------------------------
function AF.SetupAuraStackText(aura, config)
    aura.stack:SetShown(config.enabled)
    AF.LoadWidgetPosition(aura.stack, config.position, aura)
    AF.SetFont(aura.stack, unpack(config.font))
    aura.stack:SetTextColor(unpack(config.color))
end

---------------------------------------------------------------------
-- duration
---------------------------------------------------------------------
function AF.SetupAuraDurationText(aura, config)
    aura.duration:SetShown(config.enabled)
    AF.LoadWidgetPosition(aura.duration, config.position, aura)
    AF.SetFont(aura.duration, unpack(config.font))

    if not config.enabled then
        aura.UpdateDuration = AF.noop
        return
    end

    aura.showSecondsUnit = config.showSecondsUnit

    if config.colorBy == "percent_seconds" then
        -- [1]normal, [2]percent, [3]seconds
        aura.durationColor = config.color
        aura.UpdateDuration = UpdateDuration_ColorByPercentSeconds
    elseif config.colorBy == "expiring" then
        -- [1]normal, [2]expiring
        aura.durationColor = config.color
        aura.UpdateDuration = UpdateDuration_ColorByExpiring
    elseif config.colorBy == "none" or not config.colorBy then
        aura.duration:SetTextColor(unpack(config.color))
        aura.UpdateDuration = UpdateDuration_NoColor
    end
end

---------------------------------------------------------------------
-- OnHide
---------------------------------------------------------------------
local function Aura_OnHide(aura)
    LCG.ButtonGlow_Stop(aura)
end

---------------------------------------------------------------------
-- pixels
---------------------------------------------------------------------
local function Aura_UpdatePixels(aura)
    AF.ReSize(aura)
    AF.RePoint(aura)
    AF.ReBorder(aura)
    AF.RePoint(aura.icon)
    if aura.cooldown then
        AF.RePoint(aura.cooldown)
    end
end

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
function AF.CreateAura(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:Hide()

    AF.SetDefaultBackdrop(frame)
    frame:SetBackdropColor(AF.GetColorRGB("black"))

    frame:SetScript("OnHide", Aura_OnHide)

    -- icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon = icon
    AF.SetOnePixelInside(icon, frame)
    icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    frame:SetScript("OnSizeChanged", AF.ReCalcTexCoordForAura)

    -- stack text
    local stack = frame:CreateFontString(nil, "OVERLAY")
    frame.stack = stack

    -- duration text
    local duration = frame:CreateFontString(nil, "OVERLAY")
    frame.duration = duration

    -- functions
    frame.SetCooldown = AF.SetAuraCooldown
    frame.SetCooldownStyle = Aura_SetCooldownStyle
    frame.SetupStackText = AF.SetupAuraStackText
    frame.SetupDurationText = AF.SetupAuraDurationText
    frame.SetDesaturated = AF.SetAuraDesaturated
    frame.EnableTooltip = Aura_EnableTooltip

    -- pixels
    -- AF.AddToPixelUpdater(frame, Aura_UpdatePixels)
    frame.UpdatePixels = Aura_UpdatePixels

    return frame
end