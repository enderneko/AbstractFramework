---@class AbstractFramework
local AF = select(2, ...)

local CreateColor = CreateColor
local UnpackColor = AF.UnpackColor

---------------------------------------------------------------------
-- status bar countdown
---------------------------------------------------------------------
---@param bar table
---@param totalTime number
---@param timeRemaining number|nil if nil then countdown will be used
---@param onFinish? fun(self:AF_BlizzardStatusBar|AF_SimpleStatusBar)
function AF.StartStatusBarCountdown(bar, totalTime, timeRemaining, onFinish)
    bar._countdownTime = timeRemaining or totalTime

    bar:SetMinMaxValues(0, totalTime)
    bar:SetValue(bar._countdownTime)

    bar:SetScript("OnUpdate", function(self, elapsed)
        self._countdownTime = self._countdownTime - elapsed
        if self._countdownTime <= 0 then
            self:SetValue(0)
            self:SetScript("OnUpdate", nil)
            if onFinish then onFinish(self) end
        else
            self:SetValue(self._countdownTime)
        end
    end)
end

function AF.StopStatusBarCountdown(bar)
    bar:SetScript("OnUpdate", nil)
end

---------------------------------------------------------------------
-- blizzard
---------------------------------------------------------------------
---@class AF_BlizzardStatusBar:AF_SmoothStatusBar,Frame
local AF_BlizzardStatusBarMixin = {}

function AF_BlizzardStatusBarMixin:SetBarValue(v)
    AF.SetStatusBarValue(self, v)
end

function AF_BlizzardStatusBarMixin:SetMinMaxValues(minValue, maxValue)
    self:_SetMinMaxValues(minValue, maxValue)
    self.minValue = minValue
    self.maxValue = maxValue
end
AF_BlizzardStatusBarMixin.SetBarMinMaxValues = AF_BlizzardStatusBarMixin.SetMinMaxValues

function AF_BlizzardStatusBarMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    if self.progressText then
        AF.RePoint(self.progressText)
    end
end

---@param minValue number|nil default is 0
---@param maxValue number|nil default is 100
---@param width number|nil
---@param height number|nil
---@param color string|nil default is addon accent color
---@param borderColor string|nil default is border color
---@param progressTextType string|nil "percentage" or "current_value" or "current_max".
---@return AF_BlizzardStatusBar bar
function AF.CreateBlizzardStatusBar(parent, minValue, maxValue, width, height, color, borderColor, progressTextType)
    color = color or AF.GetAddonAccentColorName()
    borderColor = borderColor or "border"

    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    AF.ApplyDefaultBackdropWithColors(bar, AF.GetColorTable(color, 0.9, 0.1), borderColor)
    AF.SetSize(bar, width, height)

    minValue = minValue or 0
    maxValue = maxValue or 100

    bar._SetMinMaxValues = bar.SetMinMaxValues

    Mixin(bar, AF_BaseWidgetMixin)
    Mixin(bar, AF_SmoothStatusBarMixin) -- SetSmoothedValue/ResetSmoothedValue/SetMinMaxSmoothedValue
    Mixin(bar, AF_BlizzardStatusBarMixin)

    bar:SetStatusBarTexture(AF.GetPlainTexture())
    bar:SetStatusBarColor(AF.GetColorRGB(color, 0.7))
    bar:GetStatusBarTexture():SetDrawLayer("BORDER", -7)

    bar.tex = AF.CreateGradientTexture(bar, "HORIZONTAL", "none", AF.GetColorTable(color, 0.2), nil, "BORDER", -6)
    bar.tex:SetBlendMode("ADD")
    bar.tex:SetPoint("TOPLEFT", bar:GetStatusBarTexture())
    bar.tex:SetPoint("BOTTOMRIGHT", bar:GetStatusBarTexture())

    if progressTextType then
        bar.progressText = AF.CreateFontString(bar)
        AF.SetPoint(bar.progressText, "CENTER")
        if progressTextType == "percentage" then
            bar:SetScript("OnValueChanged", function()
                bar.progressText:SetFormattedText("%d%%", (bar:GetValue()-bar.minValue)/bar.maxValue*100)
            end)
        elseif progressTextType == "current_value" then
            bar:SetScript("OnValueChanged", function()
                bar.progressText:SetFormattedText("%d", bar:GetValue())
            end)
        elseif progressTextType == "current_max" then
            bar:SetScript("OnValueChanged", function()
                bar.progressText:SetFormattedText("%d/%d", bar:GetValue(), bar.maxValue)
            end)
        end
    end

    bar:SetMinMaxValues(minValue, maxValue)
    bar:SetValue(minValue)

    AF.AddToPixelUpdater_OnShow(bar)

    return bar
end

---------------------------------------------------------------------
-- AF_BaseStatusBar
---------------------------------------------------------------------
---@class AF_BaseStatusBar
AF_BaseStatusBarMixin = {}

---@param fillTexture string
---@param unfillTexture string|nil if nil then use fillTexture
---@param wrapModeHorizontal string|nil
---@param wrapModeVertical string|nil
---@param filterMode string|nil
function AF_BaseStatusBarMixin:SetTexture(fillTexture, unfillTexture, wrapModeHorizontal, wrapModeVertical, filterMode)
    self.fill:SetTexture(fillTexture, wrapModeHorizontal, wrapModeVertical, filterMode)
    self.unfill:SetTexture(unfillTexture or fillTexture, wrapModeHorizontal, wrapModeVertical, filterMode)
end

function AF_BaseStatusBarMixin:LSM_SetTexture(fillTexture, unfillTexture, wrapModeHorizontal, wrapModeVertical, filterMode)
    fillTexture = AF.LSM_GetBarTexture(fillTexture)
    unfillTexture = unfillTexture and AF.LSM_GetBarTexture(unfillTexture) or fillTexture
    self:SetTexture(fillTexture, unfillTexture, wrapModeHorizontal, wrapModeVertical, filterMode)
end

function AF_BaseStatusBarMixin:SetFillColor(r, g, b, a)
    self.fill:SetVertexColor(r, g, b, a)
end

---@param orientation Orientation|nil
---@param ... number|table (r1, g1, b1, a1, r2, g2, b2, a2) or {startColorTable, endColorTable}
function AF_BaseStatusBarMixin:SetGradientFillColor(orientation, ...)
    if select("#", ...) == 2 then
        local startColor, endColor = ...
        self.fill:SetGradient(orientation or "HORIZONTAL", CreateColor(UnpackColor(startColor)), CreateColor(UnpackColor(endColor)))
    else
        local r1, g1, b1, a1, r2, g2, b2, a2 = ...
        self.fill:SetGradient(orientation or "HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    end
end

function AF_BaseStatusBarMixin:SetUnfillColor(r, g, b, a)
    self.unfill:SetVertexColor(r, g, b, a)
end

----@param orientation Orientation|nil
---@param ... number|table (r1, g1, b1, a1, r2, g2, b2, a2) or {startColorTable, endColorTable}
function AF_BaseStatusBarMixin:SetGradientUnfillColor(orientation, ...)
    if select("#", ...) == 2 then
        local startColor, endColor = ...
        self.unfill:SetGradient(orientation or "HORIZONTAL", CreateColor(UnpackColor(startColor)), CreateColor(UnpackColor(endColor)))
    else
        local r1, g1, b1, a1, r2, g2, b2, a2 = ...
        self.unfill:SetGradient(orientation or "HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    end
end

-- function AF_BaseStatusBarMixin:SetGradient(gradientType)
--     if gradientType == "disabled" then
--         self.fill.gradientMask:Hide()
--         self.unfill.gradientMask:Hide()
--     else
--         self.fill.gradientMask:Show()
--         self.unfill.gradientMask:Show()

--         if gradientType == "horizontal" then
--             self.fill.gradientMask:SetTexture(AF.GetTexture("Gradient_Linear_Left"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
--             self.unfill.gradientMask:SetTexture(AF.GetTexture("Gradient_Linear_Left"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
--         end
--     end
-- end

function AF_BaseStatusBarMixin:SetBackgroundColor(r, g, b, a)
    self:SetBackdropColor(r, g, b, a)
end

function AF_BaseStatusBarMixin:SetBorderColor(r, g, b, a)
    self:SetBackdropBorderColor(r, g, b, a)
end

function AF_BaseStatusBarMixin:EnableBorder(enabled)
    if enabled then
        AF.ApplyDefaultBackdrop(self)
        AF.SetOnePixelInside(self.innerBar)
    else
        AF.ApplyDefaultBackdrop_NoBorder(self)
        AF.SetAllPoints(self.innerBar)
    end
end

function AF_BaseStatusBarMixin:GetBarSize()
    return self.innerBar:GetSize()
end

function AF_BaseStatusBarMixin:GetBarWidth()
    return self.innerBar:GetWidth()
end

function AF_BaseStatusBarMixin:GetBarHeight()
    return self.innerBar:GetHeight()
end

function AF_BaseStatusBarMixin:DefaultUpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    AF.RePoint(self.innerBar)
end

---------------------------------------------------------------------
-- simple
---------------------------------------------------------------------
local ClampedPercentageBetween = AF.ClampedPercentageBetween
local ApproxEqual = AF.ApproxEqual

local function UpdateValue_Horizontal(self)
    self.progress = ClampedPercentageBetween(self.value, self.min, self.max)

    if ApproxEqual(self.progress, 0.0) then
        self.fill.mask:SetWidth(0.00001)
        self.fill:Hide()
    elseif ApproxEqual(self.progress, 1.0) then
        self.fill.mask:SetWidth(self:GetBarWidth())
        self.fill:Show()
    else
        self.fill.mask:SetWidth(self.progress * self:GetBarWidth())
        self.fill:Show()
    end
end

local function UpdateValue_Vertical(self)
    self.progress = ClampedPercentageBetween(self.value, self.min, self.max)

    if ApproxEqual(self.progress, 0.0) then
        self.fill.mask:SetHeight(0.00001)
        self.fill:Hide()
    elseif ApproxEqual(self.progress, 1.0) then
        self.fill.mask:SetHeight(self:GetBarHeight())
        self.fill:Show()
    else
        self.fill.mask:SetHeight(self.progress * self:GetBarHeight())
        self.fill:Show()
    end
end

---@class AF_SimpleStatusBar:AF_BaseStatusBar,AF_SmoothStatusBar,Frame
local AF_SimpleStatusBarMixin = {}

---@param orientation "left_to_right"|"right_to_left"|"bottom_to_top"|"top_to_bottom"
function AF_SimpleStatusBarMixin:SetOrientation(orientation)
    self.fill.mask:ClearAllPoints()
    self.unfill.mask:ClearAllPoints()

    if orientation == "left_to_right" then
        self.UpdateValue = UpdateValue_Horizontal
        AF.SetPoint(self.fill.mask, "TOPLEFT")
        AF.SetPoint(self.fill.mask, "BOTTOMLEFT")
        AF.SetPoint(self.unfill.mask, "TOPLEFT", self.fill.mask, "TOPRIGHT")
        AF.SetPoint(self.unfill.mask, "BOTTOMRIGHT")
    elseif orientation == "right_to_left" then
        self.UpdateValue = UpdateValue_Horizontal
        AF.SetPoint(self.fill.mask, "TOPRIGHT")
        AF.SetPoint(self.fill.mask, "BOTTOMRIGHT")
        AF.SetPoint(self.unfill.mask, "BOTTOMRIGHT", self.fill.mask, "BOTTOMLEFT")
        AF.SetPoint(self.unfill.mask, "TOPLEFT")
    elseif orientation == "bottom_to_top" then
        self.UpdateValue = UpdateValue_Vertical
        AF.SetPoint(self.fill.mask, "BOTTOMLEFT")
        AF.SetPoint(self.fill.mask, "BOTTOMRIGHT")
        AF.SetPoint(self.unfill.mask, "BOTTOMRIGHT", self.fill.mask, "TOPRIGHT")
        AF.SetPoint(self.unfill.mask, "TOPLEFT")
    elseif orientation == "top_to_bottom" then
        self.UpdateValue = UpdateValue_Vertical
        AF.SetPoint(self.fill.mask, "TOPLEFT")
        AF.SetPoint(self.fill.mask, "TOPRIGHT")
        AF.SetPoint(self.unfill.mask, "TOPLEFT", self.fill.mask, "BOTTOMLEFT")
        AF.SetPoint(self.unfill.mask, "BOTTOMRIGHT")
    end

    self:UpdateValue()
end

-- smooth
function AF_SimpleStatusBarMixin:SetSmoothing(smoothing)
    self:ResetSmoothedValue()
    if smoothing then
        self.SetBarValue = self.SetSmoothedValue
        self.SetBarMinMaxValues = self.SetMinMaxSmoothedValue
    else
        self.SetBarValue = self.SetValue
        self.SetBarMinMaxValues = self.SetMinMaxValues
    end
end

-- get
function AF_SimpleStatusBarMixin:GetMinMaxValues()
    return self.min, self.max
end

function AF_SimpleStatusBarMixin:GetValue()
    return self.value
end

function AF_SimpleStatusBarMixin:GetRemainingValue()
    return self.max - self.value
end

-- set
function AF_SimpleStatusBarMixin:SetMinMaxValues(min, max)
    self.min = min
    self.max = max
    self:UpdateValue()
end

function AF_SimpleStatusBarMixin:SetValue(value)
    self.value = value
    self:UpdateValue()
end

-- dim
function AF_SimpleStatusBarMixin:Dim(enabled)
    self.mod:SetShown(enabled)
end

---@return AF_SimpleStatusBar bar
function AF.CreateSimpleStatusBar(parent, name, noBackdrop)
    local frame = CreateFrame("Frame", name, parent)
    Mixin(frame, AF_BaseWidgetMixin)
    Mixin(frame, AF_BaseStatusBarMixin)
    Mixin(frame, AF_SimpleStatusBarMixin)

    -- smooth
    Mixin(frame, AF_SmoothStatusBarMixin)
    frame:SetSmoothing(false)

    if noBackdrop then
        frame.SetBackgroundColor = nil
        frame.SetBorderColor = nil
    else
        AF.ApplyDefaultBackdropWithColors(frame)
    end

    -- default value
    frame.min = 0
    frame.max = 0
    frame.value = 0

    -- innerBar
    local bar = CreateFrame("Frame", nil, frame)
    frame.innerBar = bar
    AF.SetFrameLevel(bar, 0)

    -- fill texture
    local fill = frame:CreateTexture(nil, "BORDER", nil, -1)
    frame.fill = fill
    fill:SetAllPoints(bar)

    fill.mask = frame:CreateMaskTexture()
    fill.mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    fill:AddMaskTexture(fill.mask)

    -- already done in PixelUtil
    -- fill:SetTexelSnappingBias(0)
    -- fill:SetSnapToPixelGrid(false)

    -- unfill texture
    local unfill = frame:CreateTexture(nil, "BORDER", nil, -1)
    frame.unfill = unfill
    unfill:SetAllPoints(bar)

    unfill.mask = frame:CreateMaskTexture()
    unfill.mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    unfill:AddMaskTexture(unfill.mask)

    -- dim
    local mod = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.mod = mod
    mod:SetAllPoints(fill.mask)
    mod:SetColorTexture(0.6, 0.6, 0.6)
    mod:SetBlendMode("MOD")
    mod:Hide()

    -- setup border and orientation
    frame:EnableBorder(not noBackdrop)
    frame:SetOrientation("left_to_right")

    -- pixel perfect
    AF.AddToPixelUpdater_Auto(frame, frame.DefaultUpdatePixels)

    return frame
end