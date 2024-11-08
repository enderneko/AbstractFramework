---@class AbstractFramework
local AF = _G.AbstractFramework
local LCG = AF.LCG

---------------------------------------------------------------------
-- recalc texcoords
---------------------------------------------------------------------
local function ReCalcTexCoord(self, width, height)
    self.icon:SetTexCoord(unpack(AF.CalcTexCoordPreCrop(width, height, 1, 0.12)))
end

---------------------------------------------------------------------
-- cooldown style: vertical progress
---------------------------------------------------------------------
local function VerticalCooldown_OnUpdate(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= 0.1 then
        self:SetValue(self:GetValue() + self.elapsed)
        self.elapsed = 0
    end
end

-- for LCG.ButtonGlow_Start
local function VerticalCooldown_GetCooldownDuration()
    return 0
end

local function VerticalCooldown_ShowCooldown(self, start, duration, _, icon, auraType)
    if auraType then
        self.spark:SetColorTexture(AF.GetAuraTypeColor(auraType))
    else
        self.spark:SetColorTexture(0.5, 0.5, 0.5, 1)
    end
    if self.icon then
    self.icon:SetTexture(icon)
    end

    self.elapsed = 0.1 -- update immediately
    self:SetMinMaxValues(0, duration)
    self:SetValue(GetTime() - start)
    self:Show()
end

local function CreateCooldown_Vertical(self, hasIcon)
    local cooldown = CreateFrame("StatusBar", nil, self)
    self.cooldown = cooldown
    cooldown:Hide()

    cooldown.GetCooldownDuration = VerticalCooldown_GetCooldownDuration
    cooldown.ShowCooldown = VerticalCooldown_ShowCooldown
    cooldown:SetScript("OnUpdate", VerticalCooldown_OnUpdate)

    AF.SetPoint(cooldown, "TOPLEFT", self.icon)
    AF.SetPoint(cooldown, "BOTTOMRIGHT", self.icon, "BOTTOMRIGHT", 0, 1)
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
    icon:SetAllPoints(self.icon)
    icon:SetVertexColor(0.5, 0.5, 0.5, 1)
    icon:AddMaskTexture(mask)
    cooldown:SetScript("OnSizeChanged", ReCalcTexCoord)
    else
        texture:SetVertexColor(0, 0, 0, 0.8)
    end
end

---------------------------------------------------------------------
-- cooldown style: clock (w/ or w/o leading edge)
---------------------------------------------------------------------
local function CreateCooldown_Clock(self, drawEdge)
    local cooldown = CreateFrame("Cooldown", nil, self, "AFCooldownFrameTemplate")
    self.cooldown = cooldown
    cooldown:Hide()

    cooldown:SetAllPoints(self.icon)
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
local function Aura_SetCooldownStyle(self, style)
    if self.style == style then return end

    if self.cooldown then
        self.cooldown:SetParent(nil)
        self.cooldown:Hide()
    end

    self.style = style
    if style == "vertical" then
        CreateCooldown_Vertical(self, true)
    elseif style == "block_vertical" then
        CreateCooldown_Vertical(self, false)
    elseif strfind(style, "^clock") or strfind(style, "^block_clock") then
        -- clock, clock_with_leading_edge
        -- block_clock, block_clock_with_leading_edge
        CreateCooldown_Clock(self, strfind(style, "edge$") and true or false)
    end

    if strfind(style, "^block") then
        self.icon:Hide()
    else
        self.icon:Show()
    end
end

---------------------------------------------------------------------
-- glow
---------------------------------------------------------------------
local function Aura_CreateGlow(self)
    self.glow = CreateFrame("Frame", nil, self, "BackdropTemplate")
    self.glow:SetAllPoints()
    self.glow:SetBackdrop({edgeFile = AF.GetTexture("CalloutGlow"), edgeSize = 7})
    self.glow:SetBorderBlendMode("ADD")
    self.glow:SetFrameLevel(self:GetFrameLevel())
    AF.SetOutside(self.glow, self, 4)
    AF.CreateBlinkAnimation(self.glow, 0.5)
end

---------------------------------------------------------------------
-- SetCooldown
---------------------------------------------------------------------
local GetTime = GetTime
local function UpdateDuration(self, elapsed)
    if self._elapsed >= 0.1 then
        self._remain = self._duration - (GetTime() - self._start)
        if self._remain < 0 then self._remain = 0 end

        if self.durationColor then
            -- color
            if self.durationColor[3][1] and self._remain < self.durationColor[3][2] then
                self.duration:SetTextColor(AF.UnpackColor(self.durationColor[3][3]))
            elseif self.durationColor[2][1] and self._remain < (self.durationColor[2][2] * self._duration) then
                self.duration:SetTextColor(AF.UnpackColor(self.durationColor[2][3]))
            else
                self.duration:SetTextColor(AF.UnpackColor(self.durationColor[1]))
            end
        end

        -- duration text
        if self._remain > 86400 then
            self.duration:SetFormattedText("%dd", self._remain / 86400)
        elseif self._remain > 3600 then
            self.duration:SetFormattedText("%dh", self._remain / 3600)
        elseif self._remain > 60 then
            self.duration:SetFormattedText("%dm", self._remain / 60)
        elseif self._remain < 5 then
            self.duration:SetFormattedText("%.1f", self._remain)
        else
            self.duration:SetFormattedText("%d", self._remain)
        end

        self._elapsed = 0
    else
        self._elapsed = self._elapsed + elapsed
    end
end

local function UpdateDuration_NoColor(self, elapsed)
    if self._elapsed >= 0.1 then
        self._remain = self._duration - (GetTime() - self._start)
        if self._remain < 0 then self._remain = 0 end

        -- duration text
        if self._remain > 86400 then
            self.duration:SetFormattedText("%dd", self._remain / 86400)
        elseif self._remain > 3600 then
            self.duration:SetFormattedText("%dh", self._remain / 3600)
        elseif self._remain > 60 then
            self.duration:SetFormattedText("%dm", self._remain / 60)
        elseif self._remain < 5 then
            self.duration:SetFormattedText("%.1f", self._remain)
        else
            self.duration:SetFormattedText("%d", self._remain)
        end

        self._elapsed = 0
    else
        self._elapsed = self._elapsed + elapsed
    end
end

local function Aura_SetCooldown(self, start, duration, count, icon, auraType, desaturated, glow, r, g, b, a)
    if duration == 0 then
        if self.cooldown then self.cooldown:Hide() end
        self.duration:SetText("")
        self.stack:SetParent(self)
        self:SetScript("OnUpdate", nil)
        self._start = nil
        self._duration = nil
        self._remain = nil
        self._elapsed = nil
    else
        if self.cooldown then
            -- NOTE: the "nil" is to make it compatible with Cooldown:SetCooldown(start, duration [, modRate])
            self.cooldown:ShowCooldown(start, duration, nil, icon, auraType)
            self.duration:SetParent(self.cooldown)
            self.stack:SetParent(self.cooldown)
        else
            self.duration:SetParent(self)
            self.stack:SetParent(self)
        end
        self._start = start
        self._duration = duration
        self._elapsed = 0.1
        self:SetScript("OnUpdate", self.UpdateDuration)
    end

    if glow then
        LCG.ButtonGlow_Start(self, nil, nil, 0)
        if not self.glow then
            Aura_CreateGlow(self)
        end
        self.glow:Show()
    else
        if self.glow then self.glow:Hide() end
        LCG.ButtonGlow_Stop(self)
    end

    if r then
        self:SetBackdropColor(r, g, b, a)
    end

    self:SetDesaturated(desaturated)
    self:SetBackdropBorderColor(AF.GetAuraTypeColor(auraType))
    self.stack:SetText((count == 0 or count == 1) and "" or count)
    self.icon:SetTexture(icon)
    self:Show()
end

---------------------------------------------------------------------
-- ShowTooltips
---------------------------------------------------------------------
local function Aura_SetTooltipPosition(self)
    if self.tooltipAnchorTo == "self" then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(self.tooltipPosition[1], self, self.tooltipPosition[2], self.tooltipPosition[3], self.tooltipPosition[4])
    else -- default
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
    end
end

local function Aura_ShowBuffTooltip(self)
    Aura_SetTooltipPosition(self)
    GameTooltip:SetUnitBuffByAuraInstanceID(self.root.unit, self.auraInstanceID)
    end

local function Aura_ShowDebuffTooltip(self)
    Aura_SetTooltipPosition(self)
    GameTooltip:SetUnitDebuffByAuraInstanceID(self.root.unit, self.auraInstanceID)
end

local function Aura_HideTooltips()
    GameTooltip:Hide()
end

local function Aura_EnableTooltip(self, config, helpful)
    if config.enabled then
        self.tooltipAnchorTo = config.anchorTo
        self.tooltipPosition = config.position
        self:SetScript("OnEnter", helpful and Aura_ShowBuffTooltip or Aura_ShowDebuffTooltip)
        self:SetScript("OnLeave", Aura_HideTooltips)
    else
        self.tooltipAnchorTo = nil
        self.tooltipPosition = nil
        self:SetScript("OnEnter", nil)
        self:SetScript("OnLeave", nil)
        self:EnableMouse(false)
    end
end

---------------------------------------------------------------------
-- desaturated
---------------------------------------------------------------------
local function Aura_SetDesaturated(self, desaturated)
    self.icon:SetDesaturated(desaturated)
end

---------------------------------------------------------------------
-- base
---------------------------------------------------------------------
local function Aura_SetupStackText(self, config)
    self.stack:SetShown(config.enabled)
    AF.LoadWidgetPosition(self.stack, config.position, self)
    AF.SetFont(self.stack, unpack(config.font))
    self.stack:SetTextColor(unpack(config.color))
end

local function Aura_SetupDurationText(self, config)
    self.duration:SetShown(config.enabled)
    AF.LoadWidgetPosition(self.duration, config.position, self)
    AF.SetFont(self.duration, unpack(config.font))

    if type(config.color[1]) == "table" then
        -- [1]normal, [2]percent, [3]second
        self.durationColor = config.color
        self.UpdateDuration = UpdateDuration
    else
        self.UpdateDuration = UpdateDuration_NoColor
    end
end

local function Aura_OnHide(self)
    LCG.ButtonGlow_Stop(self)
end

local function Aura_UpdatePixels(self)
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    AF.RePoint(self.icon)
    if self.cooldown then
        AF.RePoint(self.cooldown)
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
    frame:SetScript("OnSizeChanged", ReCalcTexCoord)

    -- stack text
    local stack = frame:CreateFontString(nil, "OVERLAY")
    frame.stack = stack

    -- duration text
    local duration = frame:CreateFontString(nil, "OVERLAY")
    frame.duration = duration

    -- functions
    frame.SetCooldown = Aura_SetCooldown
    frame.SetCooldownStyle = Aura_SetCooldownStyle
    frame.SetupStackText = Aura_SetupStackText
    frame.SetupDurationText = Aura_SetupDurationText
    frame.SetDesaturated = Aura_SetDesaturated
    frame.EnableTooltip = Aura_EnableTooltip

    -- pixels
    -- AF.AddToPixelUpdater(frame, Aura_UpdatePixels)
    frame.UpdatePixels = Aura_UpdatePixels

    return frame
end