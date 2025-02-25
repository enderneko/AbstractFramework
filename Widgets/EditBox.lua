---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- edit box
---------------------------------------------------------------------
---@class AF_EditBox
local AF_EditBoxMixin = {}

---@param func function?
---@param isOutside boolean?
---@param text string?
---@param width number?
---@param mode string? "trim"|"number"|nil
function AF_EditBoxMixin:SetConfirmButton(func, isOutside, text, width, mode)
    self.confirmBtn = self.confirmBtn or AF.CreateButton(self, text, "accent", width or 30, self._height or 20)
    self.confirmBtn:Hide()

    if text then
        self.confirmBtn:SetText(text)
    else
        self.confirmBtn:SetTexture(AF.GetIcon("Tick"), {16, 16}, {"CENTER", 0, 0})
    end

    AF.ClearPoints(self.confirmBtn)
    if isOutside then
        AF.SetPoint(self.confirmBtn, "TOPLEFT", self, "TOPRIGHT", -1, 0)
    else
        AF.SetPoint(self.confirmBtn, "TOPRIGHT")
    end

    self.confirmBtn:SetScript("OnHide", function()
        self.confirmBtn:Hide()
    end)

    self.confirmBtn:SetScript("OnClick", function()
        local value = self:GetText()

        if mode == "number" then
            value = tonumber(value) or 0
        elseif mode == "trim" then
            value = strtrim(value)
        end

        if func then func(value) end

        self.value = value -- update value
        self.confirmBtn:Hide()
        self:ClearFocus()
    end)
end

function AF_EditBoxMixin:SetOnEditFocusGained(func)
    self.onEditFocusGained = func
end

function AF_EditBoxMixin:SetOnEditFocusLost(func)
    self.onEditFocusLost = func
end

function AF_EditBoxMixin:SetOnEnterPressed(func)
    self.onEnterPressed = func
end

function AF_EditBoxMixin:SetOnEscapePressed(func)
    self.onEscapePressed = func
end

function AF_EditBoxMixin:SetOnTextChanged(func)
    self.onTextChanged = func
end

function AF_EditBoxMixin:Clear()
    self:SetText("")
end

---@param parent Frame
---@param label string
---@param width number
---@param height number
---@param isMultiLine? boolean
---@param isNumeric? boolean
---@param font? string|Font
---@return AF_EditBox|EditBox
function AF.CreateEditBox(parent, label, width, height, isMultiLine, isNumeric, font)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")

    AF.StylizeFrame(eb, "widget")
    AF.SetWidth(eb, width or 40)
    AF.SetHeight(eb, height or 20)

    eb.label = AF.CreateFontString(eb, label, nil, font)
    eb.label:SetPoint("LEFT", 4, 0)
    eb.label:SetPoint("RIGHT", -4, 0)
    eb.label:SetJustifyH("LEFT")
    eb.label:SetWordWrap(false)
    eb.label:SetTextColor(AF.GetColorRGB("disabled"))

    eb:SetMultiLine(isMultiLine)
    eb:SetNumeric(isNumeric)
    eb:SetFontObject(font or "AF_FONT_CHAT")
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
        eb:SetTextColor(AF.GetColorRGB("disabled"))
        eb:SetBackdropBorderColor(0, 0, 0, 0.7)
    end)

    eb:SetScript("OnEnable", function()
        eb:SetTextColor(1, 1, 1, 1)
        eb:SetBackdropBorderColor(0, 0, 0, 1)
    end)

    eb.highlight = AF.CreateTexture(eb, nil, AF.GetColorTable("accent", 0.07))
    AF.SetPoint(eb.highlight, "TOPLEFT", 1, -1)
    AF.SetPoint(eb.highlight, "BOTTOMRIGHT", -1, 1)
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

    Mixin(eb, AF_EditBoxMixin)

    AF.AddToPixelUpdater(eb)

    return eb
end

---------------------------------------------------------------------
-- scroll edit box
---------------------------------------------------------------------
---@class AF_ScrollEditBox
local AF_ScrollEditBoxMixin = {}

function AF_ScrollEditBoxMixin:SetText(text)
    self:ResetScroll()
    self.eb:SetText(text)
    self.eb:SetCursorPosition(0)
end

function AF_ScrollEditBoxMixin:GetText()
    return self.eb:GetText()
end

function AF_ScrollEditBoxMixin:IsEnabled()
    return self._isEnabled
end

function AF_ScrollEditBoxMixin:SetEnabled(enabled)
    self._isEnabled = enabled
    self.eb:SetEnabled(enabled)
    self:EnableMouseWheel(enabled)
    self.scrollThumb:EnableMouse(enabled)
    if enabled then
        self.scrollThumb:SetBackdropColor(AF.GetColorRGB("accent"))
        self.scrollThumb:SetBackdropBorderColor(AF.GetColorRGB("black"))
        self.scrollBar:SetBackdropBorderColor(AF.GetColorRGB("black"))
        self.scrollFrame:SetBackdropBorderColor(AF.GetColorRGB("black"))
    else
        self.scrollThumb:SetBackdropColor(AF.GetColorRGB("disabled", 0.7))
        self.scrollThumb:SetBackdropBorderColor(AF.GetColorRGB("black", 0.7))
        self.scrollBar:SetBackdropBorderColor(AF.GetColorRGB("black", 0.7))
        self.scrollFrame:SetBackdropBorderColor(AF.GetColorRGB("black", 0.7))
    end
end

function AF_ScrollEditBoxMixin:Clear()
    self.eb:SetText("")
end

---@return AF_ScrollEditBox|AF_ScrollFrame frame
function AF.CreateScrollEditBox(parent, name, label, width, height, scrollStep)
    scrollStep = scrollStep or 1

    local frame = AF.CreateScrollFrame(parent, name, width, height, "none", "none")
    AF.StylizeFrame(frame.scrollFrame, "widget")
    AF.StylizeFrame(frame.scrollBar)

    -- highlight
    local highlight = AF.CreateTexture(frame.scrollFrame, nil, AF.GetColorTable("accent", 0.07))
    AF.SetPoint(highlight, "TOPLEFT", 1, -1)
    AF.SetPoint(highlight, "BOTTOMRIGHT", -1, 1)
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
    local eb = AF.CreateEditBox(frame.scrollContent, label, 10, 20, true)
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

    frame._isEnabled = true
    Mixin(frame, AF_ScrollEditBoxMixin)

    return frame
end