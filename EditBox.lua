---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- edit box
---------------------------------------------------------------------
function AW.CreateEditBox(parent, label, width, height, isMultiLine, isNumeric, font)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")

    AW.StylizeFrame(eb, "widget")
    AW.SetWidth(eb, width or 40)
    AW.SetHeight(eb, height or 20)

    eb.label = AW.CreateFontString(eb, label, nil, font)
    eb.label:SetPoint("LEFT", 4, 0)
    eb.label:SetPoint("RIGHT", -4, 0)
    eb.label:SetJustifyH("LEFT")
    eb.label:SetWordWrap(false)
    eb.label:SetTextColor(AW.GetColorRGB("disabled"))

    eb:SetMultiLine(isMultiLine)
    eb:SetNumeric(isNumeric)
    eb:SetFontObject(font or "AW_FONT_NORMAL")
    eb:SetMaxLetters(0)
    eb:SetJustifyH("LEFT")
    eb:SetJustifyV("MIDDLE")
    eb:SetTextInsets(4, 4, 0, 0)
    eb:SetAutoFocus(false)

    eb:SetScript("OnEditFocusGained", function()
        if eb.onEditFocusGained then eb.onEditFocusGained() end
        eb:HighlightText()
    end)

    eb:SetScript("OnEditFocusLost", function()
        if eb.onEditFocusLost then eb.onEditFocusLost() end
        eb:HighlightText(0, 0)
    end)

    eb:SetScript("OnEscapePressed", function()
        if eb.onEscapePressed then eb.onEscapePressed() end
        eb:ClearFocus()
    end)

    eb:SetScript("OnEnterPressed", function()
        if eb.onEnterPressed then eb.onEnterPressed(eb:GetText()) end
        eb:ClearFocus()
    end)

    eb:SetScript("OnDisable", function()
        eb:SetTextColor(AW.GetColorRGB("disabled"))
        eb:SetBackdropBorderColor(0, 0, 0, 0.7)
    end)

    eb:SetScript("OnEnable", function()
        eb:SetTextColor(1, 1, 1, 1)
        eb:SetBackdropBorderColor(0, 0, 0, 1)
    end)

    eb.highlight = AW.CreateTexture(eb, nil, AW.GetColorTable("accent", 0.07))
    AW.SetPoint(eb.highlight, "TOPLEFT", 1, -1)
    AW.SetPoint(eb.highlight, "BOTTOMRIGHT", -1, 1)
    eb.highlight:Hide()

    eb:SetScript("OnEnter", function()
        if not eb:IsEnabled() then return end
        eb.highlight:Show()
    end)

    eb:SetScript("OnLeave", function()
        if not eb:IsEnabled() then return end
        eb.highlight:Hide()
    end)

    eb.value = "" -- init value

    eb:SetScript("OnTextChanged", function(self, userChanged)
        local text = strtrim(eb:GetText())
        if text == "" then
            eb.label:Show()
        else
            eb.label:Hide()
        end

        if userChanged then
            -- NOTE: if confirmBtn is set, onTextChanged will not invoke
            if eb.confirmBtn then
                if eb.value ~= text then
                    eb.confirmBtn:Show()
                else
                    eb.confirmBtn:Hide()
                end
            elseif eb.onTextChanged then
                eb.onTextChanged(text)
                eb.value = text -- update value
            end
        else
            eb.value = text -- update value
        end
    end)

    eb:SetScript("OnHide", function()
        eb:SetText(eb.value) -- restore
    end)

    -- confirm button -----------------------------------------------
    function eb:SetConfirmButton(func, isOutside, text, width)
        eb.confirmBtn = AW.CreateButton(eb, text, "accent", width or 30, 20)
        eb.confirmBtn:Hide()

        if not text then
            eb.confirmBtn:SetTexture(AW.GetIcon("Tick"), {16, 16}, {"CENTER", 0, 0})
        end

        if isOutside then
            AW.SetPoint(eb.confirmBtn, "TOPLEFT", eb, "TOPRIGHT", -1, 0)
        else
            AW.SetPoint(eb.confirmBtn, "TOPRIGHT")
        end

        eb.confirmBtn:SetScript("OnHide", function()
            eb.confirmBtn:Hide()
        end)

        eb.confirmBtn:SetScript("OnClick", function()
            local text = strtrim(eb:GetText())
            if func then func(text) end
            eb.value = text -- update value
            eb.confirmBtn:Hide()
            eb:ClearFocus()
        end)
    end
    -----------------------------------------------------------------

    function eb:SetOnEditFocusGained(func)
        eb.onEditFocusGained = func
    end

    function eb:SetOnEditFocusLost(func)
        eb.onEditFocusLost = func
    end

    function eb:SetOnEnterPressed(func)
        eb.onEnterPressed = func
    end

    function eb:SetOnEscapePressed(func)
        eb.onEscapePressed = func
    end

    function eb:SetOnTextChanged(func)
        eb.onTextChanged = func
    end

    function eb:Clear()
        eb:SetText("")
    end

    function eb:UpdatePixels()
        AW.ReSize(eb)
        AW.RePoint(eb)
        AW.ReBorder(eb)
        -- eb.confirmBtn:UpdatePixels() already called in pixel updater
    end

    AW.AddToPixelUpdater(eb)

    return eb
end

---------------------------------------------------------------------
-- scroll edit box
---------------------------------------------------------------------
function AW.CreateScrollEditBox(parent, label, width, height, scrollStep)
    scrollStep = scrollStep or 1

    local frame = AW.CreateScrollFrame(parent, width, height, "none", "none")
    AW.StylizeFrame(frame.scrollFrame, "widget")
    AW.StylizeFrame(frame.scrollBar)

    -- highlight
    local highlight = AW.CreateTexture(frame.scrollFrame, nil, AW.GetColorTable("accent", 0.07))
    AW.SetPoint(highlight, "TOPLEFT", 1, -1)
    AW.SetPoint(highlight, "BOTTOMRIGHT", -1, 1)
    highlight:Hide()

    frame.scrollFrame:SetScript("OnEnter", function()
        if not frame:IsEnabled() then return end
        highlight:Show()
    end)

    frame.scrollFrame:SetScript("OnLeave", function()
        if not frame:IsEnabled() then return end
        highlight:Hide()
    end)

    -- edit box
    local eb = AW.CreateEditBox(frame.scrollContent, label, 10, 20, true)
    frame.eb = eb
    eb.UpdatePixels = function() end
    eb:ClearBackdrop()
    eb:SetPoint("TOPLEFT")
    eb:SetPoint("RIGHT")
    eb:SetTextInsets(4, 4, 4, 4)
    eb:SetSpacing(2)
    eb:SetScript("OnEnter", frame.scrollFrame:GetScript("OnEnter"))
    eb:SetScript("OnLeave", frame.scrollFrame:GetScript("OnLeave"))

    eb:SetScript("OnEnterPressed", function(self) self:Insert("\n") end)

    -- https://warcraft.wiki.gg/wiki/UIHANDLER_OnCursorChanged
    eb:SetScript("OnCursorChanged", function(self, x, y, arg, lineHeight)
        if not frame:IsEnabled() then return end

        frame:SetScrollStep((lineHeight + eb:GetSpacing()) * scrollStep)

        local vs = frame.scrollFrame:GetVerticalScroll()
        local h  = frame.scrollFrame:GetHeight()

        local cursorHeight = lineHeight + abs(y) + 8 + eb:GetSpacing()

        if vs + y > 0 then -- cursor above current view
            frame.scrollFrame:SetVerticalScroll(-y)
        elseif cursorHeight > h + vs then
            frame.scrollFrame:SetVerticalScroll(cursorHeight-h)
        end

        if frame.scrollFrame:GetVerticalScroll() > frame.scrollFrame:GetVerticalScrollRange() then frame:ScrollToBottom() end
    end)

    function frame:SetOnTextChanged(func)
        eb:SetOnTextChanged(func)
    end

    eb:SetScript("OnTextChanged", function(self, userChanged)
        local text = strtrim(eb:GetText())
        if text == "" then
            eb.label:Show()
        else
            eb.label:Hide()
        end

        -- NOTE: should not use SetContentHeight
        frame.scrollContent:SetHeight(eb:GetHeight())

        if eb.onTextChanged then
            eb.onTextChanged(text)
        end
    end)

    frame.scrollFrame:SetScript("OnMouseDown", function()
        eb:SetFocus(true)
    end)

    function frame:SetText(text)
        frame:ResetScroll()
        eb:SetText(text)
        eb:SetCursorPosition(0)
    end

    function frame:GetText()
        return eb:GetText()
    end

    frame._isEnabled = true
    function frame:IsEnabled()
        return frame._isEnabled
    end

    function frame:SetEnabled(enabled)
        frame._isEnabled = enabled
        eb:SetEnabled(enabled)
        frame:EnableMouseWheel(enabled)
        frame.scrollThumb:EnableMouse(enabled)
        if enabled then
            frame.scrollThumb:SetBackdropColor(AW.GetColorRGB("accent"))
            frame.scrollThumb:SetBackdropBorderColor(AW.GetColorRGB("black"))
            frame.scrollBar:SetBackdropBorderColor(AW.GetColorRGB("black"))
            frame.scrollFrame:SetBackdropBorderColor(AW.GetColorRGB("black"))
        else
            frame.scrollThumb:SetBackdropColor(AW.GetColorRGB("disabled", 0.7))
            frame.scrollThumb:SetBackdropBorderColor(AW.GetColorRGB("black", 0.7))
            frame.scrollBar:SetBackdropBorderColor(AW.GetColorRGB("black", 0.7))
            frame.scrollFrame:SetBackdropBorderColor(AW.GetColorRGB("black", 0.7))
        end
    end

    function eb:Clear()
        eb:SetText("")
    end

    return frame
end