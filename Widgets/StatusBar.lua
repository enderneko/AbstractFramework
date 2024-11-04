---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- blizzard
---------------------------------------------------------------------
--- @param color string color name defined in Color.lua
--- @param borderColor string color name defined in Color.lua
function AF.CreateStatusBar(parent, minValue, maxValue, width, height, color, borderColor, progressTextType)
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    AF.StylizeFrame(bar, AF.GetColorTable(color, 0.9, 0.1), borderColor)
    AF.SetSize(bar, width, height)

    minValue = minValue or 1
    maxValue = maxValue or 1

    bar._SetMinMaxValues = bar.SetMinMaxValues
    function bar:SetMinMaxValues(l, h)
        bar:_SetMinMaxValues(l, h)
        bar.minValue = l
        bar.maxValue = h
    end
    bar:SetMinMaxValues(minValue, maxValue)

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
        AF.SetStatusBarValue(bar, v)
    end

    Mixin(bar, SmoothStatusBarMixin) -- SetSmoothedValue

    function bar:UpdatePixels()
        AF.ReSize(bar)
        AF.RePoint(bar)
        AF.ReBorder(bar)
        if bar.progressText then
            AF.RePoint(bar.progressText)
        end
    end

    AF.AddToPixelUpdater(bar)

    return bar
end

---------------------------------------------------------------------
-- custom
---------------------------------------------------------------------
local Clamp = Clamp

local function UpdateValue(self)
    if self.value == self.min then
        self.fg.mask:SetWidth(0.001)
    elseif self.max == self.min then
        self.fg.mask:SetWidth(self:GetBarWidth())
    else
        self.value = Clamp(self.value, self.min, self.max)
        local p = (self.value - self.min) / (self.max - self.min)
        if self:GetBarWidth() == 0 then
            C_Timer.After(0, function()
                self.fg.mask:SetWidth(p * self:GetBarWidth())
            end)
        else
            self.fg.mask:SetWidth(p * self:GetBarWidth())
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
        self.fg.isGradient = false
        self.fg:SetVertexColor(r, g, b, a)
    end,
    SetGradientColor = function(self, ...)
        self.fg.isGradient = true
        if select("#", ...) == 2 then
            local startColor, endColor = ...
            self.fg:SetGradient("HORIZONTAL", CreateColor(AF.UnpackColor(startColor)), CreateColor(AF.UnpackColor(endColor)))
        else
            local r1, g1, b1, a1, r2, g2, b2, a2 = ...
            self.fg:SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
        end
    end,
    SetLossColor = function(self, r, g, b, a)
        self.loss.isGradient = false
        self.loss:SetVertexColor(r, g, b, a)
    end,
    SetGradientLossColor = function(self, ...)
        self.loss.isGradient = true
        if select("#", ...) == 2 then
            local startColor, endColor = ...
            self.loss:SetGradient("HORIZONTAL", CreateColor(AF.UnpackColor(startColor)), CreateColor(AF.UnpackColor(endColor)))
        else
            local r1, g1, b1, a1, r2, g2, b2, a2 = ...
            self.loss:SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
        end
    end,
    SetBackgroundColor = function(self, r, g, b, a)
        self:SetBackdropColor(r, g, b, a)
    end,
    SetBorderColor = function(self, r, g, b, a)
        self:SetBackdropBorderColor(r, g, b, a)
    end,
    SnapTextureToEdge = function(self, noGaps)
        self.noGaps = noGaps
        AF.ClearPoints(self.fg)
        AF.ClearPoints(self.loss)
        if noGaps then
            AF.SetPoint(self.bg, "TOPLEFT")
            AF.SetPoint(self.bg, "BOTTOMRIGHT")
            AF.SetPoint(self.fg, "TOPLEFT")
            AF.SetPoint(self.fg, "BOTTOMRIGHT")
            AF.SetPoint(self.fg.mask, "TOPLEFT")
            AF.SetPoint(self.fg.mask, "BOTTOMLEFT")
            AF.SetPoint(self.loss, "TOPLEFT")
            AF.SetPoint(self.loss, "BOTTOMRIGHT")
            AF.SetPoint(self.loss.mask, "TOPLEFT", self.fg.mask, "TOPRIGHT")
            AF.SetPoint(self.loss.mask, "BOTTOMLEFT", self.fg.mask, "BOTTOMRIGHT")
            AF.SetPoint(self.loss.mask, "TOPRIGHT")
            AF.SetPoint(self.loss.mask, "BOTTOMRIGHT")
        else
            AF.SetPoint(self.bg, "TOPLEFT", 1, -1)
            AF.SetPoint(self.bg, "BOTTOMRIGHT", -1, 1)
            AF.SetPoint(self.fg, "TOPLEFT", 1, -1)
            AF.SetPoint(self.fg, "BOTTOMRIGHT", -1, 1)
            AF.SetPoint(self.fg.mask, "TOPLEFT", 1, -1)
            AF.SetPoint(self.fg.mask, "BOTTOMLEFT", 1, 1)
            AF.SetPoint(self.loss, "TOPLEFT", 1, -1)
            AF.SetPoint(self.loss, "BOTTOMRIGHT", -1, 1)
            AF.SetPoint(self.loss.mask, "TOPLEFT", self.fg.mask, "TOPRIGHT")
            AF.SetPoint(self.loss.mask, "BOTTOMLEFT", self.fg.mask, "BOTTOMRIGHT")
            AF.SetPoint(self.loss.mask, "TOPRIGHT", -1, -1)
            AF.SetPoint(self.loss.mask, "BOTTOMRIGHT", -1, 1)
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
    DefaultUpdatePixels = function(self)
        AF.ReSize(self)
        AF.RePoint(self)
        AF.ReBorder(self)
        -- AF.ReSize(self.fg.mask)
        AF.RePoint(self.fg)
        AF.RePoint(self.fg.mask)
        AF.RePoint(self.loss)
        AF.RePoint(self.loss.mask)
    end,
}

function AF.CreateSimpleBar(parent, name, noBackdrop)
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
        AF.SetDefaultBackdrop(bar)
        for k, v in pairs(prototype) do
            bar[k] = v
        end
    end

    -- default value
    bar.min = 0
    bar.max = 0
    bar.value = 0

    -- smooth
    Mixin(bar, AF.SmoothStatusBarMixin)
    bar:SetSmoothing(false)

    -- foreground texture
    local fg = bar:CreateTexture(nil, "BORDER", nil, -1)
    bar.fg = fg
    fg.mask = bar:CreateMaskTexture()
    fg.mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    fg:AddMaskTexture(fg.mask)

    -- already done in PixelUtil
    -- fg:SetTexelSnappingBias(0)
    -- fg:SetSnapToPixelGrid(false)

    -- loss texture
    local loss = bar:CreateTexture(nil, "BORDER", nil, -1)
    bar.loss = loss
    loss.mask = bar:CreateMaskTexture()
    loss.mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    loss:AddMaskTexture(loss.mask)

    -- bg texture NOTE: currently only for GetBarSize/Width/Height
    local bg = bar:CreateTexture(nil, "BORDER", nil, -2)
    bar.bg = bg

    -- setup default texture points
    bar:SnapTextureToEdge(noBackdrop)

    -- pixel perfect
    AF.AddToPixelUpdater(bar, bar.DefaultUpdatePixels)

    return bar
end