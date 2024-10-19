---@class AbstractWidgets
local AW = _G.AbstractWidgets

-- NOTE: up to two decimal places value

---------------------------------------------------------------------
-- slider
---------------------------------------------------------------------
function AW.CreateSlider(parent, text, width, low, high, step, showPercentSign, hideLowHighText)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    AW.StylizeFrame(slider, "widget")

    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    AW.SetSize(slider, width, 10)

    local label = AW.CreateFontString(slider, text)
    AW.SetPoint(label, "BOTTOM", slider, "TOP", 0, 2)

    function slider:SetLabel(n)
        label:SetText(n)
    end

    -- OnEnterPressed / dragging
    function slider:SetOnValueChanged(func)
        slider.onValueChanged = func
    end

    -- OnEnterPressed / OnMouseUp
    function slider:SetAfterValueChanged(func)
        slider.afterValueChanged = func
    end

    -- low ----------------------------------------------------------
    local lowText = AW.CreateFontString(slider, nil, "gray")
    AW.SetPoint(lowText, "TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    -----------------------------------------------------------------

    -- high ---------------------------------------------------------
    local highText = AW.CreateFontString(slider, nil, "gray")
    AW.SetPoint(highText, "TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    -----------------------------------------------------------------

    -- thumb --------------------------------------------------------
    local thumbBG = AW.CreateTexture(slider, nil, AW.GetColorTable("black"), "BACKGROUND", 3)
    AW.SetSize(thumbBG, 10, 10)
    slider:SetThumbTexture(thumbBG)

    local thumbBG2 =  AW.CreateTexture(slider, nil, AW.GetColorTable("accent", 0.25), "BACKGROUND", 2)
    AW.SetPoint(thumbBG2, "TOPLEFT", 1, -1)
    AW.SetPoint(thumbBG2, "BOTTOMRIGHT", thumbBG, "BOTTOMLEFT")

    local thumb = AW.CreateTexture(slider, nil, AW.GetColorTable("accent", 0.7), "OVERLAY", 7)
    AW.SetPoint(thumb, "TOPLEFT", thumbBG, 1, -1)
    AW.SetPoint(thumb, "BOTTOMRIGHT", thumbBG, -1, 1)
    -----------------------------------------------------------------

    local oldValue, valueBeforeClick

    -- editbox ------------------------------------------------------
    local eb = AW.CreateEditBox(slider, nil, 48, 14)
    AW.SetPoint(eb, "TOPLEFT", slider, "BOTTOMLEFT", math.ceil(width / 2 - 24), -1)
    eb:SetJustifyH("CENTER")

    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local value = tonumber(self:GetText())

        if value == oldValue then return end
        if value then
            if value < slider.low then value = slider.low end
            if value > slider.high then value = slider.high end
            self:SetText(value)
            slider:SetValue(value)
            if slider.onValueChanged then slider.onValueChanged(value) end
            if slider.afterValueChanged then slider.afterValueChanged(value) end
        else
            self:SetText(self.oldValue)
        end
    end)

    eb:SetScript("OnShow", function(self)
        if oldValue then self:SetText(oldValue) end
    end)
    -----------------------------------------------------------------

    local unit = showPercentSign and "%" or ""
    local percentSign = AW.CreateFontString(slider, "%", "gray")
    AW.SetPoint(percentSign, "LEFT", eb, "RIGHT", 2, 0)
    percentSign:Hide()

    if hideLowHighText then
        lowText:Hide()
        highText:Hide()
        if showPercentSign then
            percentSign:Show()
        end
    end

    -- highlight ----------------------------------------------------
    local highlight = AW.CreateTexture(slider, nil, AW.GetColorTable("accent", 0.05), "BACKGROUND", 1)
    AW.SetPoint(highlight, "TOPLEFT", 1, -1)
    AW.SetPoint(highlight, "BOTTOMRIGHT", -1, 1)
    highlight:Hide()
    -----------------------------------------------------------------

    slider._GetValue = slider.GetValue
    function slider:GetValue()
        local value = slider:_GetValue()
        if math.floor(value) < value then -- decimal
            value = tonumber(string.format("%.2f", value))
        end
        return value
    end

    -- NOTE: OnEnter / OnLeave will still trigger even if disabled
    -- OnEnter ------------------------------------------------------
    local function OnEnter()
        thumb:SetColor("accent")
        highlight:Show()
        valueBeforeClick = slider:GetValue()
    end
    slider:SetScript("OnEnter", OnEnter)
    -----------------------------------------------------------------

    -- OnLeave ------------------------------------------------------
    local function OnLeave()
        thumb:SetColor(AW.GetColorTable("accent", 0.7))
        highlight:Hide()
    end
    slider:SetScript("OnLeave", OnLeave)
    -----------------------------------------------------------------

    -- OnValueChanged -----------------------------------------------
    slider:SetScript("OnValueChanged", function(self, value, userChanged)
        if oldValue == value then return end

        if math.floor(value) < value then -- decimal
            value = tonumber(string.format("%.2f", value))
        end
        oldValue = value

        eb:SetText(value)
        if userChanged and slider.onValueChanged then
            slider.onValueChanged(oldValue)
        end
    end)
    -----------------------------------------------------------------

    -- OnMouseUp ----------------------------------------------------
    slider:SetScript("OnMouseUp", function(self, button, isMouseOver)
        if not slider:IsEnabled() then return end

        -- oldValue here == newValue, OnMouseUp called after OnValueChanged
        if valueBeforeClick ~= oldValue and slider.afterValueChanged then
            valueBeforeClick = oldValue
            slider.afterValueChanged(slider:GetValue())
        end
    end)
    -----------------------------------------------------------------

    -- REVIEW: OnMouseWheel
    --[[
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        if not IsShiftKeyDown() then return end

        -- NOTE: OnValueChanged may not be called: value == low
        oldValue = oldValue and oldValue or low

        local value
        if delta == 1 then -- scroll up
            value = oldValue + step
            value = value > high and high or value
        elseif delta == -1 then -- scroll down
            value = oldValue - step
            value = value < low and low or value
        end

        if value ~= oldValue then
            slider:SetValue(value)
            if slider.onValueChanged then slider.onValueChanged(value) end
            if slider.afterValueChanged then slider.afterValueChanged(value) end
        end
    end)
    ]]

    slider:SetScript("OnDisable", function()
        label:SetColor("disabled")
        eb:SetEnabled(false)
        thumb:SetColor(AW.GetColorTable("disabled", 0.7))
        thumbBG:SetColor(AW.GetColorTable("black", 0.7))
        thumbBG2:SetColor(AW.GetColorTable("disabled", 0.25))
        lowText:SetColor("disabled")
        highText:SetColor("disabled")
        percentSign:SetColor("disabled")
        slider:SetScript("OnEnter", nil)
        slider:SetScript("OnLeave", nil)
        slider:SetBackdropBorderColor(AW.GetColorRGB("black", 0.7))
    end)

    slider:SetScript("OnEnable", function()
        label:SetColor("white")
        eb:SetEnabled(true)
        thumb:SetColor(AW.GetColorTable("accent", 0.7))
        thumbBG:SetColor(AW.GetColorTable("black", 1))
        thumbBG2:SetColor(AW.GetColorTable("accent", 0.25))
        lowText:SetColor("gray")
        highText:SetColor("gray")
        percentSign:SetColor("gray")
        slider:SetScript("OnEnter", OnEnter)
        slider:SetScript("OnLeave", OnLeave)
        slider:SetBackdropBorderColor(AW.GetColorRGB("black", 1))
    end)

    function slider:UpdateMinMaxValues(minV, maxV)
        slider:SetMinMaxValues(minV, maxV)
        slider.low = minV
        slider.high = maxV
        lowText:SetText(minV..unit)
        highText:SetText(maxV..unit)
    end
    slider:UpdateMinMaxValues(low, high)

    function slider:UpdatePixels()
        AW.ReSize(slider)
        AW.RePoint(slider)
        AW.ReBorder(slider)
    end

    AW.AddToPixelUpdater(slider)

    return slider
end

---------------------------------------------------------------------
-- vertical slider
---------------------------------------------------------------------
function AW.CreateVerticalSlider(parent, text, height, low, high, step, isPercentage, showLowHighText)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    AW.StylizeFrame(slider, "widget")

    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("VERTICAL")
    AW.SetSize(slider, 10, height)

    local label = AW.CreateFontString(slider, text)
    AW.SetPoint(label, "TOP", slider, "BOTTOM", 0, -2)

    function slider:SetLabel(n)
        label:SetText(n)
    end

    function slider:UpdateWordWrap(startAt)
        label._wordWrapStartAt = startAt
        label:SetWordWrap(true)
        local current = startAt or 50
        slider:SetScript("OnUpdate", function()
            label:SetWidth(current)
            if label:IsTruncated() then
                current = current + 5
            else
                slider:SetScript("OnUpdate", nil)
            end
        end)
    end

    -- OnEnterPressed / dragging
    function slider:SetOnValueChanged(func)
        slider.onValueChanged = func
    end

    -- OnEnterPressed / OnMouseUp
    function slider:SetAfterValueChanged(func)
        slider.afterValueChanged = func
    end

    -- low ----------------------------------------------------------
    local lowText = AW.CreateFontString(slider, nil, "gray")
    AW.SetPoint(lowText, "TOPLEFT", slider, "TOPRIGHT", 2, 0)
    lowText:Hide()
    AW.CreateFadeInOutAnimation(lowText)
    -----------------------------------------------------------------

    -- high ---------------------------------------------------------
    local highText = AW.CreateFontString(slider, nil, "gray")
    AW.SetPoint(highText, "BOTTOMLEFT", slider, "BOTTOMRIGHT", 2, 0)
    highText:Hide()
    AW.CreateFadeInOutAnimation(highText)
    -----------------------------------------------------------------

    if showLowHighText then
        lowText:Show()
        highText:Show()
    end

    -- thumb --------------------------------------------------------
    local thumbBG = AW.CreateTexture(slider, nil, AW.GetColorTable("black"), "BACKGROUND", 3)
    AW.SetSize(thumbBG, 10, 10)
    slider:SetThumbTexture(thumbBG)

    local thumbBG2 =  AW.CreateTexture(slider, nil, AW.GetColorTable("accent", 0.25), "BACKGROUND", 2)
    AW.SetPoint(thumbBG2, "TOPLEFT", thumbBG, "BOTTOMLEFT")
    AW.SetPoint(thumbBG2, "BOTTOMRIGHT", -1, 1)

    local thumb = AW.CreateTexture(slider, nil, AW.GetColorTable("accent", 0.7), "OVERLAY", 7)
    AW.SetPoint(thumb, "TOPLEFT", thumbBG, 1, -1)
    AW.SetPoint(thumb, "BOTTOMRIGHT", thumbBG, -1, 1)

    local thumbText = AW.CreateFontString(slider, nil, "accent")
    AW.SetPoint(thumbText, "RIGHT", thumbBG, "LEFT", -2, 0)
    thumbText:Hide()
    AW.CreateFadeInOutAnimation(thumbText)
    -----------------------------------------------------------------

    local oldValue, valueBeforeClick
    local unit = isPercentage and "%" or ""

    -- highlight ----------------------------------------------------
    local highlight = AW.CreateTexture(slider, nil, AW.GetColorTable("accent", 0.05), "BACKGROUND", 1)
    AW.SetPoint(highlight, "TOPLEFT", 1, -1)
    AW.SetPoint(highlight, "BOTTOMRIGHT", -1, 1)
    highlight:Hide()
    -----------------------------------------------------------------

    -- GetValue -----------------------------------------------------
    slider._GetValue = slider.GetValue
    function slider:GetValue()
        local value = high - slider:_GetValue()
        if math.floor(value) < value then -- decimal
            value = tonumber(string.format("%.2f", value))
        end
        return value
    end
    -----------------------------------------------------------------

    -- SetValue -----------------------------------------------------
    slider._SetValue = slider.SetValue
    function slider:SetValue(value)
        slider:_SetValue(high - value)
    end
    -----------------------------------------------------------------

    -- NOTE: OnEnter / OnLeave will still trigger even if disabled
    -- OnEnter ------------------------------------------------------
    local function OnEnter()
        thumb:SetColor("accent")
        highlight:Show()
        valueBeforeClick = slider:GetValue()
    end
    slider:SetScript("OnEnter", OnEnter)
    -----------------------------------------------------------------

    -- OnLeave ------------------------------------------------------
    local function OnLeave()
        thumb:SetColor(AW.GetColorTable("accent", 0.7))
        highlight:Hide()
    end
    slider:SetScript("OnLeave", OnLeave)
    -----------------------------------------------------------------

    -- OnValueChanged -----------------------------------------------
    slider:SetScript("OnValueChanged", function(self, value, userChanged)
        value = high - value -- NOTE: ORIGINAL: top == 0, NOW: top == max
        if oldValue == value then return end

        if math.floor(value) < value then -- decimal
            value = tonumber(string.format("%.2f", value))
        end
        oldValue = value

        if userChanged and slider.onValueChanged then
            slider.onValueChanged(oldValue)
        end

        if slider:IsDraggingThumb() then
            thumbText:SetText(oldValue..unit)
        end
    end)
    -----------------------------------------------------------------

    -- OnMouseUp ----------------------------------------------------
    slider:SetScript("OnMouseUp", function(self, button, isMouseOver)
        if not slider:IsEnabled() then return end

        -- oldValue here == newValue, OnMouseUp called after OnValueChanged
        if valueBeforeClick ~= oldValue and slider.afterValueChanged then
            valueBeforeClick = oldValue
            slider.afterValueChanged(slider:GetValue())
        end

        thumbText.fadeOut:Play()
        if showLowHighText then
            lowText.fadeOut:Play()
            highText.fadeOut:Play()
        end
    end)

    slider:SetScript("OnMouseDown", function(self, button, isMouseOver)
        if not slider:IsEnabled() then return end

        thumbText:SetText(slider:GetValue()..unit)
        thumbText.fadeIn:Play()
        if showLowHighText then
            lowText.fadeIn:Play()
            highText.fadeIn:Play()
        end
    end)
    -----------------------------------------------------------------

    slider:SetScript("OnDisable", function()
        label:SetColor("disabled")
        thumb:SetColor(AW.GetColorTable("disabled", 0.7))
        thumbBG:SetColor(AW.GetColorTable("black", 0.7))
        thumbBG2:SetColor(AW.GetColorTable("disabled", 0.25))
        lowText:SetColor("disabled")
        highText:SetColor("disabled")
        slider:SetScript("OnEnter", nil)
        slider:SetScript("OnLeave", nil)
        slider:SetBackdropBorderColor(AW.GetColorRGB("black", 0.7))
    end)

    slider:SetScript("OnEnable", function()
        label:SetColor("white")
        thumb:SetColor(AW.GetColorTable("accent", 0.7))
        thumbBG:SetColor(AW.GetColorTable("black", 1))
        thumbBG2:SetColor(AW.GetColorTable("accent", 0.25))
        lowText:SetColor("gray")
        highText:SetColor("gray")
        slider:SetScript("OnEnter", OnEnter)
        slider:SetScript("OnLeave", OnLeave)
        slider:SetBackdropBorderColor(AW.GetColorRGB("black", 1))
    end)

    function slider:UpdateMinMaxValues(minV, maxV)
        slider:SetMinMaxValues(minV, maxV)
        slider.low = minV
        slider.high = maxV
        lowText:SetText(minV..unit)
        highText:SetText(maxV..unit)
    end
    slider:UpdateMinMaxValues(low, high)

    function slider:UpdatePixels()
        AW.ReSize(slider)
        AW.RePoint(slider)
        AW.ReBorder(slider)
        slider:UpdateWordWrap(label._wordWrapStartAt)
    end

    AW.AddToPixelUpdater(slider)

    return slider
end