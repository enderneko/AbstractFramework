---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- blizzard
---------------------------------------------------------------------
--- @param color string color name defined in Color.lua
--- @param borderColor string color name defined in Color.lua
function AW.CreateStatusBar(parent, minValue, maxValue, width, height, color, borderColor, progressTextType)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    AW.StylizeFrame(bar, AW.GetColorTable(color, 0.9, 0.1), borderColor)
    AW.SetSize(bar, width, height)

    minValue = minValue or 1
    maxValue = maxValue or 1

    bar._SetMinMaxValues = bar.SetMinMaxValues
    function bar:SetMinMaxValues(l, h)
        bar:_SetMinMaxValues(l, h)
        bar.minValue = l
        bar.maxValue = h
    end
    bar:SetMinMaxValues(minValue, maxValue)

    bar:SetStatusBarTexture(AW.GetPlainTexture())
    bar:SetStatusBarColor(AW.GetColorRGB(color, 0.7))
    bar:GetStatusBarTexture():SetDrawLayer("BORDER", -7)

    bar.tex = AW.CreateGradientTexture(bar, "HORIZONTAL", "none", AW.GetColorTable(color, 0.2), nil, "BORDER", -6)
    bar.tex:SetBlendMode("ADD")
    bar.tex:SetPoint("TOPLEFT", bar:GetStatusBarTexture())
    bar.tex:SetPoint("BOTTOMRIGHT", bar:GetStatusBarTexture())

    if progressTextType then
        bar.progressText = AW.CreateFontString(bar)
        AW.SetPoint(bar.progressText, "CENTER")
        if progressTextType == "percentage" then
            bar:SetScript("OnValueChanged", function()
                bar.progressText:SetFormattedText("%d%%", (bar:GetValue()-bar.minValue)/bar.maxValue*100)
            end)
        elseif progressTextType == "value" then
            bar:SetScript("OnValueChanged", function()
                bar.progressText:SetFormattedText("%d", bar:GetValue())
            end)
        elseif progressTextType == "value-max" then
            bar:SetScript("OnValueChanged", function()
                bar.progressText:SetFormattedText("%d/%d", bar:GetValue(), bar.maxValue)
            end)
        end
    end

    bar:SetValue(minValue)

    function bar:SetBarValue(v)
        AW.SetStatusBarValue(bar, v)
    end

    Mixin(bar, SmoothStatusBarMixin) -- SetSmoothedValue

    function bar:UpdatePixels()
        AW.ReSize(bar)
        AW.RePoint(bar)
        AW.ReBorder(bar)
        if bar.progressText then
            AW.RePoint(bar.progressText)
        end
    end

    AW.AddToPixelUpdater(bar)

    return bar
end

---------------------------------------------------------------------
-- custom
---------------------------------------------------------------------
local Clamp = Clamp

local function UpdateValue(self)
    if self.value == self.min then
        self.fg:SetWidth(0.001)
    elseif self.max == self.min then
        self.fg:SetWidth(self:GetBarWidth())
    else
        self.value = Clamp(self.value, self.min, self.max)
        local p = (self.value - self.min) / (self.max - self.min)
        if self:GetBarWidth() == 0 then
            C_Timer.After(0, function()
                self.fg:SetWidth(p * self:GetBarWidth())
            end)
        else
            self.fg:SetWidth(p * self:GetBarWidth())
        end
    end
end

local prototype = {
    -- appearance
    SetTexture = function(self, texture, lossTexture)
        self.fg:SetTexture(texture)
        self.loss:SetTexture(lossTexture or texture)
    end,
    SetColor = function(self, r, g, b, a)
        self.fg:SetVertexColor(r, g, b, a)
    end,
    SetGradientColor = function(self, startColor, endColor)
        self.fg:SetGradient("HORIZONTAL", CreateColor(AW.UnpackColor(startColor)), CreateColor(AW.UnpackColor(endColor)))
    end,
    SetLossColor = function(self, r, g, b, a)
        self.loss:SetVertexColor(r, g, b, a)
    end,
    SetBackgroundColor = function(self, r, g, b, a)
        self:SetBackdropColor(r, g, b, a)
    end,
    SetBorderColor = function(self, r, g, b, a)
        self:SetBackdropBorderColor(r, g, b, a)
    end,
    SnapTextureToEdge = function(self, noGaps)
        self.noGaps = noGaps
        AW.ClearPoints(self.fg)
        AW.ClearPoints(self.loss)
        if noGaps then
            AW.SetPoint(self.bg, "TOPLEFT")
            AW.SetPoint(self.bg, "BOTTOMRIGHT")
            AW.SetPoint(self.fg, "TOPLEFT")
            AW.SetPoint(self.fg, "BOTTOMLEFT")
            AW.SetPoint(self.loss, "TOPLEFT", self.fg, "TOPRIGHT")
            AW.SetPoint(self.loss, "BOTTOMLEFT", self.fg, "BOTTOMRIGHT")
            AW.SetPoint(self.loss, "TOPRIGHT")
            AW.SetPoint(self.loss, "BOTTOMRIGHT")
        else
            AW.SetPoint(self.bg, "TOPLEFT", 1, -1)
            AW.SetPoint(self.bg, "BOTTOMRIGHT", -1, 1)
            AW.SetPoint(self.fg, "TOPLEFT", 1, -1)
            AW.SetPoint(self.fg, "BOTTOMLEFT", 1, 1)
            AW.SetPoint(self.loss, "TOPLEFT", self.fg, "TOPRIGHT")
            AW.SetPoint(self.loss, "BOTTOMLEFT", self.fg, "BOTTOMRIGHT")
            AW.SetPoint(self.loss, "TOPRIGHT", -1, -1)
            AW.SetPoint(self.loss, "BOTTOMRIGHT", -1, 1)
        end
    end,

    -- smooth
    SetSmoothing = function(self, smoothing)
        self:ResetSmoothedValue()
        if smoothing then
            self.SetBarValue = self.SetSmoothedValue
            self.SetBarMinMaxValues = self.SetMinMaxSmoothedValue
        else
            self.SetBarValue = self.SetValue
            self.SetBarMinMaxValues = self.SetMinMaxValues
        end
    end,

    -- get
    GetMinMaxValues = function(self)
        return self.min, self.max
    end,
    GetValue = function(self)
        return self.value
    end,
    GetBarSize = function(self)
        return self.bg:GetSize()
    end,
    GetBarWidth = function(self)
        return self.bg:GetWidth()
    end,
    GetBarHeight = function(self)
        return self.bg:GetHeight()
    end,

    -- set
    SetMinMaxValues = function(self, min, max)
        self.min = min
        self.max = max
        UpdateValue(self)
    end,
    SetValue = function(self, value)
        self.value = value
        UpdateValue(self)
    end,

    -- pixel perfect
    UpdatePixels = function(self)
        AW.ReSize(self)
        AW.RePoint(self)
        AW.ReBorder(self)
        AW.ReSize(self.fg)
        AW.RePoint(self.fg)
        AW.RePoint(self.loss)
    end,
}

function AW.CreateSimpleBar(parent, name, noBackdrop)
    local bar

    if noBackdrop then
        bar = CreateFrame("Frame", name, parent)
        for k, v in pairs(prototype) do
            if k ~= "SetBackgroundColor" and k ~= "SetBorderColor" or k ~= "SnapTextureToEdge" then
                bar[k] = v
            end
        end
    else
        bar = CreateFrame("Frame", name, parent, "BackdropTemplate")
        AW.SetDefaultBackdrop(bar)
        for k, v in pairs(prototype) do
            bar[k] = v
        end
    end

    -- default value
    bar.min = 0
    bar.max = 0
    bar.value = 0

    -- smooth
    Mixin(bar, AW.SmoothStatusBarMixin)
    bar:SetSmoothing(false)

    -- foreground texture
    local fg = bar:CreateTexture(nil, "BORDER", nil, -1)
    bar.fg = fg
    -- already done in PixelUtil
    -- fg:SetTexelSnappingBias(0)
    -- fg:SetSnapToPixelGrid(false)

    -- loss texture
    local loss = bar:CreateTexture(nil, "BORDER", nil, -1)
    bar.loss = loss

    -- bg texture NOTE: currently only for GetBarSize/Width/Height
    local bg = bar:CreateTexture(nil, "BORDER", nil, -2)
    bar.bg = bg

    -- setup default texture points
    bar:SnapTextureToEdge(noBackdrop)

    -- pixel perfect
    -- NOTE: UpdatePixels() added in prototype, remember to use it
    -- AW.AddToPixelUpdater(bar)

    return bar
end