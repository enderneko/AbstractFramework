---@class AbstractFramework
local AF = _G.AbstractFramework

local PI = math.pi
local SmoothStatusBarMixin = SmoothStatusBarMixin
local CreateColor = CreateColor

---@class AF_SecretStatusBar:Frame
---@field bar StatusBar|SmoothStatusBarMixin
---@field SetValue fun(self: AF_SecretStatusBar, value: number)
---@field SetMinMaxValues fun(self: AF_SecretStatusBar, min: number, max: number)
local AF_SecretStatusBarMixin = {}

local function SetSmoothedValue(self, value)
    self.bar:SetSmoothedValue(value)
end

local function SetMinMaxSmoothedValue(self, min, max)
    self.bar:SetMinMaxSmoothedValue(min, max)
end

local function SetValue(self, value)
    self.bar:SetValue(value)
end

local function SetMinMaxValues(self, min, max)
    self.bar:SetMinMaxValues(min, max)
end

function AF_SecretStatusBarMixin:SetSmoothing(smoothing)
    self:ResetSmoothedValue()
    if smoothing then
        self.SetValue = SetSmoothedValue
        self.SetMinMaxValues = SetMinMaxSmoothedValue
    else
        self.SetValue = SetValue
        self.SetMinMaxValues = SetMinMaxValues
    end
end

function AF_SecretStatusBarMixin:ResetSmoothedValue()
    self.bar:ResetSmoothedValue()
end

function AF_SecretStatusBarMixin:GetValue()
    return self.bar:GetValue()
end

function AF_SecretStatusBarMixin:GetMinMaxValues()
    return self.bar:GetMinMaxValues()
end

---@param texture string
---@param lossTexture string|nil if nil then use texture
---@param wrapModeHorizontal string|nil
---@param wrapModeVertical string|nil
---@param filterMode string|nil
function AF_SecretStatusBarMixin:SetTexture(texture, lossTexture, wrapModeHorizontal, wrapModeVertical, filterMode)
    self.fill:SetTexture(texture, wrapModeHorizontal, wrapModeVertical, filterMode)
    self.loss:SetTexture(lossTexture or texture, wrapModeHorizontal, wrapModeVertical, filterMode)
end

function AF_SecretStatusBarMixin:SetColor(r, g, b, a)
    self.fill:SetVertexColor(r, g, b, a)
end

---@param orientation Orientation|nil
---@param ... number|table (r1, g1, b1, a1, r2, g2, b2, a2) or {startColorTable, endColorTable}
function AF_SecretStatusBarMixin:SetGradientColor(orientation, ...)
    if select("#", ...) == 2 then
        local startColor, endColor = ...
        self.fill:SetGradient(orientation or "HORIZONTAL", CreateColor(AF.UnpackColor(startColor)), CreateColor(AF.UnpackColor(endColor)))
    else
        local r1, g1, b1, a1, r2, g2, b2, a2 = ...
        self.fill:SetGradient(orientation or "HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    end
end

function AF_SecretStatusBarMixin:SetLossColor(r, g, b, a)
    self.loss:SetVertexColor(r, g, b, a)
end

----@param orientation Orientation|nil
---@param ... number|table (r1, g1, b1, a1, r2, g2, b2, a2) or {startColorTable, endColorTable}
function AF_SecretStatusBarMixin:SetGradientLossColor(orientation, ...)
    if select("#", ...) == 2 then
        local startColor, endColor = ...
        self.loss:SetGradient(orientation or "HORIZONTAL", CreateColor(AF.UnpackColor(startColor)), CreateColor(AF.UnpackColor(endColor)))
    else
        local r1, g1, b1, a1, r2, g2, b2, a2 = ...
        self.loss:SetGradient(orientation or "HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    end
end

function AF_SecretStatusBarMixin:SetBackgroundColor(r, g, b, a)
    self:SetBackdropColor(r, g, b, a)
end

function AF_SecretStatusBarMixin:SetBorderColor(r, g, b, a)
    self:SetBackdropBorderColor(r, g, b, a)
end

function AF_SecretStatusBarMixin:Dim(enabled)
    self.mod:SetShown(enabled)
end

-- function AF_SecretStatusBarMixin:SetGradient(gradientType)
--     if gradientType == "disabled" then
--         self.fill.gradientMask:Hide()
--         self.loss.gradientMask:Hide()
--     else
--         self.fill.gradientMask:Show()
--         self.loss.gradientMask:Show()

--         if gradientType == "horizontal" then
--             self.fill.gradientMask:SetTexture(AF.GetTexture("Gradient_Linear_Left"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
--             self.loss.gradientMask:SetTexture(AF.GetTexture("Gradient_Linear_Left"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
--         end
--     end
-- end

function AF_SecretStatusBarMixin:EnableBorder(enabled)
    if enabled then
        AF.ApplyDefaultBackdrop(self)
        AF.SetOnePixelInside(self.bar)
    else
        AF.ApplyDefaultBackdrop_NoBorder(self)
        AF.SetAllPoints(self.bar)
    end
end

---@param orientation "left_to_right"|"right_to_left"|"bottom_to_top"|"top_to_bottom"
function AF_SecretStatusBarMixin:SetOrientation(orientation)
    self.loss.mask:ClearAllPoints()
    if orientation == "left_to_right" then
        self.bar:SetOrientation("HORIZONTAL")
        self.bar:SetReverseFill(false)
        self.loss.mask:SetPoint("TOPLEFT", self.fill.mask, "TOPRIGHT")
        self.loss.mask:SetPoint("BOTTOMRIGHT")
    elseif orientation == "right_to_left" then
        self.bar:SetOrientation("HORIZONTAL")
        self.bar:SetReverseFill(true)
        self.loss.mask:SetPoint("BOTTOMRIGHT", self.fill.mask, "BOTTOMLEFT")
        self.loss.mask:SetPoint("TOPLEFT")
    elseif orientation == "bottom_to_top" then
        self.bar:SetOrientation("VERTICAL")
        self.bar:SetReverseFill(false)
        self.loss.mask:SetPoint("BOTTOMRIGHT", self.fill.mask, "TOPRIGHT")
        self.loss.mask:SetPoint("TOPLEFT")
    elseif orientation == "top_to_bottom" then
        self.bar:SetOrientation("VERTICAL")
        self.bar:SetReverseFill(true)
        self.loss.mask:SetPoint("TOPLEFT", self.fill.mask, "BOTTOMLEFT")
        self.loss.mask:SetPoint("BOTTOMRIGHT")
    end
end

function AF_SecretStatusBarMixin:SetTextureQuarterRotations(quarterRotations)
    local rotations = (quarterRotations or 0) % 4
    local angle = (-PI / 2) * rotations

    self.fill:SetRotation(angle)
    self.loss:SetRotation(angle)
end

function AF_SecretStatusBarMixin:GetBarSize()
    return self.bar:GetSize()
end

function AF_SecretStatusBarMixin:GetBarWidth()
    return self.bar:GetWidth()
end

function AF_SecretStatusBarMixin:GetBarHeight()
    return self.bar:GetHeight()
end

function AF_SecretStatusBarMixin:DefaultUpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    AF.RePoint(self.bar)
end


---@return AF_SecretStatusBar frame
function AF.CreateSecretStatusBar(parent, name)
    local frame = CreateFrame("Frame", name, parent)

    local bar = CreateFrame("StatusBar", nil, frame)
    frame.bar = bar
    bar:SetStatusBarTexture(AF.GetEmptyTexture())
    AF.SetFrameLevel(bar, 0)

    Mixin(frame, AF_SecretStatusBarMixin)
    Mixin(bar, SmoothStatusBarMixin)

    -- fill
    local fill = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    frame.fill = fill
    fill:SetAllPoints(bar)

    fill.mask = frame:CreateMaskTexture()
    fill.mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    fill.mask:SetAllPoints(bar:GetStatusBarTexture())
    fill:AddMaskTexture(fill.mask)

    -- fill.gradientMask = frame:CreateMaskTexture()
    -- fill.gradientMask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    -- fill.gradientMask:SetAllPoints(fill)
    -- fill:AddMaskTexture(fill.gradientMask)

    -- loss
    local loss = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    frame.loss = loss
    loss:SetAllPoints(bar)

    loss.mask = frame:CreateMaskTexture()
    loss.mask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    loss:AddMaskTexture(loss.mask)

    -- loss.gradientMask = frame:CreateMaskTexture()
    -- loss.gradientMask:SetTexture(AF.GetPlainTexture(), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "NEAREST")
    -- loss.gradientMask:SetAllPoints(loss)
    -- loss:AddMaskTexture(loss.gradientMask)

    -- dim
    local mod = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.mod = mod
    mod:SetAllPoints(fill.mask)
    mod:SetColorTexture(0.6, 0.6, 0.6)
    mod:SetBlendMode("MOD")
    mod:Hide()

    -- init
    frame:EnableBorder(true)
    frame:SetOrientation("left_to_right")

    -- pixel perfect
    AF.AddToPixelUpdater_Auto(frame, frame.DefaultUpdatePixels)

    return frame
end