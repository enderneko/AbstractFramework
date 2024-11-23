---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- button
---------------------------------------------------------------------
local function RegisterMouseDownUp(b)
    b:SetScript("OnMouseDown", function()
        if b.onMouseDownText then b.onMouseDownText() end
        if b.onMouseDownTexture then b.onMouseDownTexture() end
    end)
    b:SetScript("OnMouseUp", function()
        if b.onMouseUpText then b.onMouseUpText() end
        if b.onMouseUpTexture then b.onMouseUpTexture() end
    end)
end

local function UnregisterMouseDownUp(b)
    b:SetScript("OnMouseDown", nil)
    b:SetScript("OnMouseUp", nil)
end

--- @param color string if strfind(color, "transparent"), border is transparent, but still exists
--- @param noBorder boolean no edgeFile for backdrop
--- @param noBackground boolean remove background texture, not background color
function AF.CreateButton(parent, text, color, width, height, template, noBorder, noBackground, font)
    local b = CreateFrame("Button", nil, parent, template and template..",BackdropTemplate" or "BackdropTemplate")
    if parent then AF.SetFrameLevel(b, 1) end
    AF.SetSize(b, width, height)

    RegisterMouseDownUp(b)

    -- keep color & hoverColor ------------------
    b._color = AF.GetButtonNormalColor(color)
    b._hoverColor = AF.GetButtonHoverColor(color)

    -- text -------------------------------------
    b.text = AF.CreateFontString(b, text, nil, font)
    b.text:SetWordWrap(false)
    AF.SetPoint(b.text, "LEFT", 2, 0)
    AF.SetPoint(b.text, "RIGHT", -2, 0)
    b.text:SetText(text)

    b.onMouseDownText = function()
        if b._disableTextPushEffect then return end
        b.text:AdjustPointsOffset(0, -AF.GetOnePixelForRegion(b))
    end

    b.onMouseUpText = function()
        if b._disableTextPushEffect then return end
        AF.RePoint(b.text)
    end

    b:SetScript("OnEnable", function()
        b.text:SetColor("white")
        RegisterMouseDownUp(b)
    end)

    b:SetScript("OnDisable", function()
        b.text:SetColor("disabled")
        UnregisterMouseDownUp(b)
    end)

    --- @param color string|nil
    function b:SetTextHighlightColor(color)
        if color then
            b.highlightText = function()
                b.text:SetColor(color)
            end
            b.unhighlightText = function()
                b.text:SetColor("white")
            end
        else
            b.highlightText = nil
            b.unhighlightText = nil
        end
    end

    function b:SetText(s)
        b.text:SetText(s)
    end

    function b:GetText()
        b.text:GetText()
    end

    function b:GetFontString()
        return b.text
    end

    function b:SetTextColor(r, g, b, a)
        b.text:SetTextColor(r, g, b, a)
    end

    function b:SetFontObject(f)
        b.text:SetFontObject(f)
    end

    function b:SetFont(...)
        b.text:SetFont(...)
    end

    function b:GetFont()
        return b.text:GetFont()
    end

    function b:SetJustifyH(justify)
        b.text:SetJustifyH(justify)
    end

    -- border -----------------------------------
    if noBorder then
        AF.SetDefaultBackdrop_NoBorder(b)
    else
        AF.SetDefaultBackdrop(b)
        -- local n = AF.GetOnePixelForRegion(b)
        -- b:SetBackdrop({bgFile=AF.GetPlainTexture(), edgeFile=AF.GetPlainTexture(), edgeSize=n, insets={left=n, right=n, top=n, bottom=n}})
    end

    --- @param color string|nil
    function b:SetBorderHighlightColor(color)
        if color then
            b.highlightBorder = function()
                b:SetBackdropBorderColor(AF.GetColorRGB(color))
            end
            b.unhighlightBorder = function()
                b:SetBackdropBorderColor(AF.GetColorRGB("black"))
            end
        else
            b.highlightBorder = nil
            b.unhighlightBorder = nil
        end
    end

    -- color ------------------------------------
    if color and string.find(color, "transparent") then -- drop down item
        b._isTransparent = true
        b._disableTextPushEffect = true
        b:SetBackdropBorderColor(0, 0, 0, 0) -- make border transparent, but still exists
        b.text:SetJustifyH("LEFT")
        AF.ClearPoints(b.text)
        AF.SetPoint(b.text, "LEFT", 5, 0)
        AF.SetPoint(b.text, "RIGHT", -5, 0)
    elseif color == "none" then -- transparent color, border, background
        b:SetBackdropBorderColor(0, 0, 0, 0)
    else
        if not noBackground then
            local bg = b:CreateTexture()
            bg:SetDrawLayer("BACKGROUND", -8)
            b.bg = bg
            bg:SetAllPoints(b)
            bg:SetColorTexture(AF.GetColorRGB("widget"))
        end

        b:SetBackdropBorderColor(0, 0, 0, 1)
    end

    b:SetBackdropColor(unpack(b._color))

    -- OnEnter / OnLeave ------------------------
    b:SetScript("OnEnter", function()
        if color ~= "none" then b:SetBackdropColor(unpack(b._hoverColor)) end
        if b.highlightText then b.highlightText() end
        if b.highlightBorder then b.highlightBorder() end
    end)
    b:SetScript("OnLeave", function()
        if color ~= "none" then b:SetBackdropColor(unpack(b._color)) end
        if b.unhighlightText then b.unhighlightText() end
        if b.unhighlightBorder then b.unhighlightBorder() end
    end)

    -- click sound ------------------------------
    if not AF.isVanilla then
        if template and strfind(template, "SecureActionButtonTemplate") then
            b._isSecure = true
            -- NOTE: ActionButtonUseKeyDown will affect OnClick
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown", "RightButtonDown")
        end

        b:SetScript("PostClick", function(self, button, down)
            if self.noSound then return end
            if b._isSecure then
                if down == GetCVarBool("ActionButtonUseKeyDown") then
                    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
                end
            else
                PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
            end
        end)
    else
        b:SetScript("PostClick", function()
            if self.noSound then return end
            PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
        end)
    end

    function b:SlientClick()
        b.noSound = true
        b:Click()
        b.noSound = nil
    end

    -- texture ----------------------------------
    function b:SetTexture(tex, size, point, isAtlas, noPushDownEffect)
        if not b.texture then
            b.texture = b:CreateTexture(nil, "ARTWORK")
            -- enable / disable
            b:HookScript("OnEnable", function()
                b.texture:SetDesaturated(false)
                b.texture:SetVertexColor(AF.GetColorRGB("white"))
            end)
            b:HookScript("OnDisable", function()
                b.texture:SetDesaturated(true)
                b.texture:SetVertexColor(AF.GetColorRGB("disabled"))
            end)

            assert(#point==3, "point format error! should be something like {\"CENTER\", 0, 0}")
            AF.SetPoint(b.texture, unpack(point))
            AF.SetSize(b.texture, unpack(size))

            -- update fontstring point
            AF.ClearPoints(b.text)
            AF.SetPoint(b.text, "LEFT", b.texture, "RIGHT", 2, 0)
            AF.SetPoint(b.text, "RIGHT", -2, 0)
            -- push effect
            b._disableTextPushEffect = true
            if not noPushDownEffect then
                b.onMouseDownTexture = function()
                    b.texture:ClearAllPoints()
                    b.texture:SetPoint(point[1], point[2], point[3]-AF.GetOnePixelForRegion(b))
                end
                b.onMouseUpTexture = function()
                    b.texture:ClearAllPoints()
                    b.texture:SetPoint(unpack(point))
                end
            end
        end

        if isAtlas then
            b.texture:SetAtlas(tex)
        else
            b.texture:SetTexture(tex)
        end
    end

    function b:UpdatePixels()
        AF.ReSize(b)
        AF.RePoint(b)
        AF.RePoint(b.text)

        if not noBorder then
            AF.ReBorder(b)
        end

        if b.texture then
            AF.ReSize(b.texture)
            AF.RePoint(b.texture)
        end
    end

    AF.AddToPixelUpdater(b)

    return b
end

---------------------------------------------------------------------
-- button group
---------------------------------------------------------------------
function AF.CreateButtonGroup(buttons, onClick, selectedFn, unselectedFn, onEnter, onLeave)
    local function HighlightButton(id)
        for _, b in pairs(buttons) do
            if id == b.id then
                b:SetBackdropColor(unpack(b._hoverColor))
                b:SetScript("OnEnter", function()
                    if b._tooltips then AF.ShowTooltips(b, b._tooltipsAnchor, b._tooltipsX, b._tooltipsY, b._tooltips) end
                    if onEnter then onEnter(b) end
                end)
                b:SetScript("OnLeave", function()
                    AF.HideTooltips()
                    if onLeave then onLeave(b) end
                end)
                if selectedFn then selectedFn(b.id, b) end
            else
                b:SetBackdropColor(unpack(b._color))
                b:SetScript("OnEnter", function()
                    if b._tooltips then AF.ShowTooltips(b, b._tooltipsAnchor, b._tooltipsX, b._tooltipsY, b._tooltips) end
                    b:SetBackdropColor(unpack(b._hoverColor))
                    if onEnter then onEnter(b) end
                end)
                b:SetScript("OnLeave", function()
                    AF.HideTooltips()
                    b:SetBackdropColor(unpack(b._color))
                    if onLeave then onLeave(b) end
                end)
                if unselectedFn then unselectedFn(b.id, b) end
            end
        end
    end

    for _, b in pairs(buttons) do
        b:SetScript("OnClick", function()
            HighlightButton(b.id)
            onClick(b.id, b)
        end)
    end

    return HighlightButton
end

---------------------------------------------------------------------
-- close button
---------------------------------------------------------------------
function AF.CreateCloseButton(parent, frameToHide, width, height, padding)
    padding = padding or 6

    local b = AF.CreateButton(parent, nil, "red", width, height)
    b:SetTexture(AF.GetIcon("Close"), {width - padding, height - padding}, {"CENTER", 0, 0})
    b:SetScript("OnClick", function()
        if frameToHide then
            frameToHide:Hide()
        else
            parent:Hide()
        end
    end)
    return b
end

---------------------------------------------------------------------
-- icon button
---------------------------------------------------------------------
---@param color string|table?
---@param hoverColor string|table?
function AF.CreateIconButton(parent, icon, width, height, padding, color, hoverColor, noPushDownEffect, filterMode)
    padding = padding or 0

    local b = CreateFrame("Button", nil, parent)
    AF.SetSize(b, width, height)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("CENTER")
    AF.SetSize(b.icon, width - padding, height - padding)
    b.icon:SetTexture(icon, nil, nil, filterMode)

    b.color = type(color) == "string" and AF.GetColorTable(color) or (color or AF.GetColorTable("white"))
    b.hoverColor = type(hoverColor) == "string" and AF.GetColorTable(hoverColor) or (hoverColor or AF.GetColorTable("white"))
    b.icon:SetVertexColor(AF.UnpackColor(b.color))

    b:SetScript("OnEnter", function()
        b.icon:SetVertexColor(AF.UnpackColor(b.hoverColor))
    end)
    b:SetScript("OnLeave", function()
        b.icon:SetVertexColor(AF.UnpackColor(b.color))
    end)

    if not noPushDownEffect then
        RegisterMouseDownUp(b)
        b.onMouseDownTexture = function()
            b.icon:ClearAllPoints()
            b.icon:SetPoint("CENTER", 0, -AF.GetOnePixelForRegion(b))
        end
        b.onMouseUpTexture = function()
            b.icon:ClearAllPoints()
            b.icon:SetPoint("CENTER")
        end
    end

    AF.AddToPixelUpdater(b)

    return b
end

---------------------------------------------------------------------
-- check button
---------------------------------------------------------------------
function AF.CreateCheckButton(parent, label, onClick)
    -- InterfaceOptionsCheckButtonTemplate --> FrameXML\InterfaceOptionsPanels.xml line 19
    -- OptionsBaseCheckButtonTemplate -->  FrameXML\OptionsPanelTemplates.xml line 10

    local cb = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    AF.SetSize(cb, 14, 14)

    cb.onClick = onClick
    cb:SetScript("OnClick", function(self)
        PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        if self.onClick then self.onClick(self:GetChecked() and true or false, self) end
    end)

    cb.label = cb:CreateFontString(nil, "OVERLAY", "AF_FONT_NORMAL")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 5, 0)

    function cb:SetText(text)
        cb.label:SetText(text)
        if text and strtrim(text) ~= "" then
            cb:SetHitRectInsets(0, -cb.label:GetStringWidth()-5, 0, 0)
        else
            cb:SetHitRectInsets(0, 0, 0, 0)
        end
    end

    cb:SetText(label)

    AF.SetDefaultBackdrop(cb)
    cb:SetBackdropColor(AF.GetColorRGB("widget"))
    cb:SetBackdropBorderColor(0, 0, 0, 1)

    local checkedTexture = cb:CreateTexture(nil, "ARTWORK")
    checkedTexture:SetColorTexture(AF.GetColorRGB("accent", 0.7))
    AF.SetPoint(checkedTexture, "TOPLEFT", 1, -1)
    AF.SetPoint(checkedTexture, "BOTTOMRIGHT", -1, 1)

    local highlightTexture = cb:CreateTexture(nil, "ARTWORK")
    highlightTexture:SetColorTexture(AF.GetColorRGB("accent", 0.1))
    AF.SetPoint(highlightTexture, "TOPLEFT", 1, -1)
    AF.SetPoint(highlightTexture, "BOTTOMRIGHT", -1, 1)

    cb:SetCheckedTexture(checkedTexture)
    cb:SetHighlightTexture(highlightTexture, "ADD")
    -- cb:SetDisabledCheckedTexture([[Interface\AddOns\Cell\Media\CheckBox\CheckBox-DisabledChecked-16x16]])

    cb:SetScript("OnEnable", function()
        cb.label:SetTextColor(1, 1, 1)
        checkedTexture:SetColorTexture(AF.GetColorRGB("accent", 0.7))
        cb:SetBackdropBorderColor(0, 0, 0, 1)
    end)

    cb:SetScript("OnDisable", function()
        cb.label:SetTextColor(AF.GetColorRGB("disabled"))
        checkedTexture:SetColorTexture(AF.GetColorRGB("disabled", 0.7))
        cb:SetBackdropBorderColor(0, 0, 0, 0.7)
    end)

    function cb:UpdatePixels()
        AF.ReSize(cb)
        AF.RePoint(cb)
        AF.ReBorder(cb)
        AF.RePoint(checkedTexture)
        AF.RePoint(highlightTexture)
    end

    AF.AddToPixelUpdater(cb)

    return cb
end

---------------------------------------------------------------------
-- switch
---------------------------------------------------------------------
--- @param labels table {{["text"]=(string), ["value"]=(boolean/string/number), ["onClick"]=(function)}, ...}
function AF.CreateSwitch(parent, width, height, labels)
    local switch = AF.CreateBorderedFrame(parent, nil, width, height, "widget")

    switch.highlight = AF.CreateTexture(switch, nil, AF.GetColorTable("accent", 0.07))
    AF.SetPoint(switch.highlight, "TOPLEFT", 1, -1)
    AF.SetPoint(switch.highlight, "BOTTOMRIGHT", -1, 1)
    switch.highlight:Hide()

    switch:SetScript("OnEnter", function()
        switch.highlight:Show()
    end)

    switch:SetScript("OnLeave", function()
        switch.highlight:Hide()
    end)

    local n = #labels
    local buttonWidth = width / n

    -- buttons
    local buttons = {}
    for i, l in pairs(labels) do
        buttons[i] = AF.CreateButton(switch, labels[i].text, "none", buttonWidth, height)
        buttons[i].value = labels[i].value or labels[i].text
        buttons[i].isSelected = false

        buttons[i].highlight = AF.CreateTexture(buttons[i], nil, AF.GetColorTable("accent", 0.8))
        AF.SetPoint(buttons[i].highlight, "BOTTOMLEFT", 1, 1)
        AF.SetPoint(buttons[i].highlight, "BOTTOMRIGHT", -1, 1)
        AF.SetHeight(buttons[i].highlight, 1)

        -- fill animation -------------------------------------------
        local fill = buttons[i].highlight:CreateAnimationGroup()
        buttons[i].fill = fill

        fill.t = fill:CreateAnimation("Translation")
        fill.t:SetOffset(0, AF.ConvertPixelsForRegion(height/2-1, buttons[i]))
        fill.t:SetSmoothing("IN")
        fill.t:SetDuration(0.1)

        fill.s = fill:CreateAnimation("Scale")
        fill.s:SetScaleTo(1, AF.ConvertPixelsForRegion(height-2, buttons[i]))
        fill.s:SetDuration(0.1)
        fill.s:SetSmoothing("IN")

        fill:SetScript("OnPlay", function()
            AF.ClearPoints(buttons[i].highlight)
            AF.SetPoint(buttons[i].highlight, "BOTTOMLEFT", 1, 1)
            AF.SetPoint(buttons[i].highlight, "BOTTOMRIGHT", -1, 1)
        end)

        fill:SetScript("OnFinished", function()
            AF.SetHeight(buttons[i].highlight, height-2)
            -- to ensure highlight always fill the whole button exactly
            AF.ClearPoints(buttons[i].highlight)
            AF.SetPoint(buttons[i].highlight, "TOPLEFT", 1, -1)
            AF.SetPoint(buttons[i].highlight, "BOTTOMRIGHT", -1, 1)
        end)
        -------------------------------------------------------------

        -- empty animation ------------------------------------------
        local empty = buttons[i].highlight:CreateAnimationGroup()
        buttons[i].empty = empty

        empty.t = empty:CreateAnimation("Translation")
        empty.t:SetOffset(0, -AF.ConvertPixelsForRegion(height/2-1, buttons[i]))
        empty.t:SetSmoothing("IN")
        empty.t:SetDuration(0.1)

        empty.s = empty:CreateAnimation("Scale")
        empty.s:SetScaleTo(1, 1/AF.ConvertPixelsForRegion(height-2, buttons[i]))
        empty.s:SetDuration(0.1)
        empty.s:SetSmoothing("IN")

        empty:SetScript("OnPlay", function()
            AF.ClearPoints(buttons[i].highlight)
            AF.SetPoint(buttons[i].highlight, "BOTTOMLEFT", 1, 1)
            AF.SetPoint(buttons[i].highlight, "BOTTOMRIGHT", -1, 1)
        end)

        empty:SetScript("OnFinished", function()
            AF.SetHeight(buttons[i].highlight, 1)
        end)
        -------------------------------------------------------------

        buttons[i]:SetScript("OnClick", function(self)
            if self.isSelected or fill:IsPlaying() or empty:IsPlaying() then return end

            fill:Play()
            self.isSelected = true
            switch.selected = self.value

            if labels[i].onClick then
                labels[i].onClick()
            end

            -- deselect others
            for j, b in ipairs(buttons) do
                if j ~= i then
                    if b.isSelected then b.empty:Play() end
                    b.isSelected = false
                end
            end
        end)

        buttons[i]:SetScript("OnEnter", function(self)
            switch:GetScript("OnEnter")()
        end)

        buttons[i]:SetScript("OnLeave", function(self)
            switch:GetScript("OnLeave")()
        end)

        if i == 1 then
            AF.SetPoint(buttons[i], "TOPLEFT")
        elseif i == n then
            AF.SetPoint(buttons[i], "TOPLEFT", buttons[i-1], "TOPRIGHT", -1, 0)
            AF.SetPoint(buttons[i], "TOPRIGHT")
        else
            AF.SetPoint(buttons[i], "TOPLEFT", buttons[i-1], "TOPRIGHT", -1, 0)
        end
    end

    function switch:SetSelectedValue(value)
        for _, b in ipairs(buttons) do
            if b.value == value then
                if not b.isSelected then b.fill:Play() end
                b.isSelected = true
            else
                if b.isSelected then b.empty:Play() end
                b.isSelected = false
            end
        end
    end

    function switch:GetSelectedValue()
        return switch.selected
    end

    function switch:UpdatePixels()
        AF.ReSize(switch)
        AF.RePoint(switch)
        AF.ReBorder(switch)
        AF.RePoint(switch.highlight)

        -- update highlights
        -- for _, b in ipairs(buttons) do
        --     AF.ReSize(b.highlight)
        --     AF.RePoint(b.highlight)
        -- end
    end

    AF.AddToPixelUpdater(switch)

    return switch
end

---------------------------------------------------------------------
-- resize button
---------------------------------------------------------------------
local function ResizeButton_OnEnter(self)
    SetCursor("UI_RESIZE_CURSOR")
end

local function ResizeButton_OnLeave(self)
    SetCursor(nil)
end

function AF.CreateResizeButton(owner, minWidth, minHeight, maxWidth, maxHeight)
    local b = CreateFrame("Button", nil, owner)
    owner.resizeButton = b
    b.owner = owner

    AF.SetSize(b, 16, 16)
    AF.SetPoint(b, "BOTTOMRIGHT", -1, 1)

    b:SetScript("OnEnter", ResizeButton_OnEnter)
    b:SetScript("OnLeave", ResizeButton_OnLeave)

    local tex = b:CreateTexture(nil, "ARTWORK")
    b.tex = tex
    tex:SetAllPoints()
    tex:SetTexture(AF.GetIcon("ResizeButton"))

    return b
end