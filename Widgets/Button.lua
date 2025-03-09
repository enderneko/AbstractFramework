---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- button
---------------------------------------------------------------------
local function RegisterMouseDownUp(b)
    b:SetScript("OnMouseDown", function()
        if not b._disableTextPushEffect then b:HandleMouseDownText() end
        if not b._disableTexturePushEffect then b:HandleMouseDownTexture() end
    end)
    b:SetScript("OnMouseUp", function()
        if not b._disableTextPushEffect then b:HandleMouseUpText() end
        if not b._disableTexturePushEffect then b:HandleMouseUpTexture() end
    end)
end

local function UnregisterMouseDownUp(b)
    b:SetScript("OnMouseDown", nil)
    b:SetScript("OnMouseUp", nil)
end

---@class AF_Button
local AF_ButtonMixin = {}

function AF_ButtonMixin:HandleMouseDownText()
    -- if self._disableTextPushEffect then return end
    self.text:AdjustPointsOffset(0, -AF.GetOnePixelForRegion(self))
end

function AF_ButtonMixin:HandleMouseUpText()
    -- if self._disableTextPushEffect then return end
    AF.RePoint(self.text)
end

function AF_ButtonMixin:HandleMouseDownTexture()
    if self.texture then
        self.texture:AdjustPointsOffset(0, -AF.GetOnePixelForRegion(self))
    end
end

function AF_ButtonMixin:HandleMouseUpTexture()
    if self.texture then
        AF.RePoint(self.texture)
    end
end

---@param color string @see
function AF_ButtonMixin:SetTextHighlightColor(color)
    if color then
        self.highlightText = function()
            self.text:SetColor(color)
        end
        self.unhighlightText = function()
            self.text:SetColor("white")
        end
    else
        self.highlightText = nil
        self.unhighlightText = nil
    end
end

function AF_ButtonMixin:SetText(str)
    self.text:SetText(str)
end

function AF_ButtonMixin:GetText()
    return self.text:GetText()
end

function AF_ButtonMixin:GetFontString()
    return self.text
end

function AF_ButtonMixin:SetTextColor(r, g, b, a)
    self.text:SetTextColor(r, g, b, a)
end

function AF_ButtonMixin:SetFontObject(f)
    self.text:SetFontObject(f)
end

function AF_ButtonMixin:SetFont(...)
    self.text:SetFont(...)
end

function AF_ButtonMixin:GetFont()
    return self.text:GetFont()
end

function AF_ButtonMixin:SetJustifyH(justify)
    self.text:SetJustifyH(justify)
end

function AF_ButtonMixin:SetBorderHighlightColor(color)
    if color then
        self.highlightBorder = function()
            self:SetBackdropBorderColor(AF.GetColorRGB(color))
        end
        self.unhighlightBorder = function()
            self:SetBackdropBorderColor(AF.GetColorRGB("black"))
        end
    else
        self.highlightBorder = nil
        self.unhighlightBorder = nil
    end
end

---@param tex string
---@param size table
---@param point table
---@param isAtlas boolean
---@param noPushDownEffect boolean
---@param borderColor? string no texture border if nil
function AF_ButtonMixin:SetTexture(tex, size, point, isAtlas, noPushDownEffect, borderColor)
    if not self.texture then
        self.texture = self:CreateTexture(nil, "BORDER")
        self:HookScript("OnEnable", function()
            self.realTexture:SetDesaturated(false)
            self.realTexture:SetVertexColor(AF.GetColorRGB("white"))
        end)
        self:HookScript("OnDisable", function()
            self.realTexture:SetDesaturated(true)
            self.realTexture:SetVertexColor(AF.GetColorRGB("disabled"))
        end)
        assert(#point == 3, "point format error! should be something like {\"CENTER\", 0, 0}")
        self.point = point
        AF.SetPoint(self.texture, unpack(point))
        AF.SetSize(self.texture, unpack(size))
    end

    AF.ClearPoints(self.text)
    AF.SetPoint(self.text, "LEFT", self.texture, "RIGHT", 2, 0)
    AF.SetPoint(self.text, "RIGHT", -2, 0)
    self._disableTextPushEffect = true

    if borderColor then
        if not self.textureFG then
            self.textureFG = self:CreateTexture(nil, "ARTWORK")
            AF.SetOnePixelInside(self.textureFG, self.texture)
        end
        self.texture:SetColorTexture(AF.GetColorRGB(borderColor))
        self.realTexture = self.textureFG
    else
        if self.textureFG then
            self.textureFG:Hide()
        end
        self.realTexture = self.texture
    end

    self._disableTexturePushEffect = noPushDownEffect

    if isAtlas then
        self.realTexture:SetAtlas(tex)
    else
        if type(tex) == "number" then
            self.realTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            self.realTexture:SetTexCoord(0, 1, 0, 1)
        end
        self.realTexture:SetTexture(tex)
    end
end

function AF_ButtonMixin:HideTexture()
    if self.texture then
        self.texture:Hide()
    end
    if self.textureFG then
        self.textureFG:Hide()
    end
    AF.ClearPoints(self.text)
    AF.SetPoint(self.text, "LEFT", 2, 0)
    AF.SetPoint(self.text, "RIGHT", -2, 0)
    self._disableTextPushEffect = self._isTransparent and true or false
end

function AF_ButtonMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.RePoint(self.text)
    if not self._noBorder then
        AF.ReBorder(self)
    end
    if self.texture then
        AF.ReSize(self.texture)
        AF.RePoint(self.texture)
    end
    if self.textureFG then
        AF.RePoint(self.textureFG)
    end
end

function AF_ButtonMixin:SlientClick()
    self._noSound = true
    self:Click()
    self._noSound = nil
end

---@param parent Frame
---@param text string
---@param color? string if end with "transparent", border is transparent, but still exists
---@param width number
---@param height number
---@param template? string
---@param noBorder? boolean no edgeFile for backdrop
---@param noBackground? boolean remove background texture, not background color
---@param font? string?
---@return AF_Button|Button button
function AF.CreateButton(parent, text, color, width, height, template, noBorder, noBackground, font)
    local b = CreateFrame("Button", nil, parent, template and template..",BackdropTemplate" or "BackdropTemplate")
    if parent then AF.SetFrameLevel(b, 1) end
    AF.SetSize(b, width, height)

    Mixin(b, AF_ButtonMixin)
    RegisterMouseDownUp(b)

    -- keep color & hoverColor ------------------
    b._color = AF.GetButtonNormalColor(color)
    b._hoverColor = AF.GetButtonHoverColor(color)

    -- text -------------------------------------
    b.text = AF.CreateFontString(b, text, nil, font)
    AF.RemoveFromPixelUpdater(b.text)
    b.text:SetWordWrap(false)
    AF.SetPoint(b.text, "LEFT", 2, 0)
    AF.SetPoint(b.text, "RIGHT", -2, 0)
    b.text:SetText(text)

    b:SetScript("OnEnable", function()
        b.text:SetColor("white")
        RegisterMouseDownUp(b)
    end)

    b:SetScript("OnDisable", function()
        b.text:SetColor("disabled")
        UnregisterMouseDownUp(b)
    end)

    -- border -----------------------------------
    b._noBorder = noBorder
    if noBorder then
        AF.SetDefaultBackdrop_NoBorder(b)
    else
        AF.SetDefaultBackdrop(b)
        -- local n = AF.GetOnePixelForRegion(b)
        -- b:SetBackdrop({bgFile=AF.GetPlainTexture(), edgeFile=AF.GetPlainTexture(), edgeSize=n, insets={left=n, right=n, top=n, bottom=n}})
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
            if self._noSound then return end
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
            if self._noSound then return end
            PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
        end)
    end

    -- pixel updater ----------------------------
    AF.AddToPixelUpdater(b)

    return b
end

---------------------------------------------------------------------
-- button group
---------------------------------------------------------------------
---@param buttons table
---@param onClick function
---@param selectedFn function
---@param unselectedFn function
---@param onEnter function
---@param onLeave function
---@return function HighlightButton accept button.id as parameter
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
---@param color? string|table
---@param hoverColor? string|table
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
---@class AF_CheckButton
local AF_CheckButtonMixin = {}

function AF_CheckButtonMixin:SetText(text)
    self.label:SetText(text)
    if text and strtrim(text) ~= "" then
        self:SetHitRectInsets(0, -self.label:GetStringWidth()-5, 0, 0)
    else
        self:SetHitRectInsets(0, 0, 0, 0)
    end
end

function AF_CheckButtonMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    AF.RePoint(self.checkedTexture)
    AF.RePoint(self.highlightTexture)
end

---@return AF_CheckButton|CheckButton cb
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

    Mixin(cb, AF_CheckButtonMixin)
    cb:SetText(label)

    AF.SetDefaultBackdrop(cb)
    cb:SetBackdropColor(AF.GetColorRGB("widget"))
    cb:SetBackdropBorderColor(0, 0, 0, 1)

    local checkedTexture = cb:CreateTexture(nil, "ARTWORK")
    cb.checkedTexture = checkedTexture
    checkedTexture:SetColorTexture(AF.GetColorRGB("accent", 0.7))
    AF.SetPoint(checkedTexture, "TOPLEFT", 1, -1)
    AF.SetPoint(checkedTexture, "BOTTOMRIGHT", -1, 1)

    local highlightTexture = cb:CreateTexture(nil, "ARTWORK")
    cb.highlightTexture = highlightTexture
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

    AF.AddToPixelUpdater(cb)

    return cb
end

---------------------------------------------------------------------
-- switch
---------------------------------------------------------------------
---@class AF_Switch
local AF_SwitchMixin = {}

function AF_SwitchMixin:SetSelectedValue(value)
    for _, b in ipairs(self.buttons) do
        if b.value == value then
            if not b.isSelected then b.fill:Play() end
            b.isSelected = true
        else
            if b.isSelected then b.empty:Play() end
            b.isSelected = false
        end
    end
end

function AF_SwitchMixin:GetSelectedValue()
    return self.selected
end

-- function AF_SwitchMixin:UpdatePixels()
--     AF.ReSize(self)
--     AF.RePoint(self)
--     AF.ReBorder(self)
--     -- AF.RePoint(self.highlight)

--     -- update highlights
--     -- for _, b in ipairs(buttons) do
--     --     AF.ReSize(b.highlight)
--     --     AF.RePoint(b.highlight)
--     -- end
-- end

---@param labels table {{["text"]=(string), ["value"]=(boolean/string/number), ["onClick"]=(function)}, ...}
---@return AF_Switch|Frame switch
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
    switch.buttons = buttons

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

    Mixin(switch, AF_SwitchMixin)

    AF.AddToPixelUpdater(switch)

    return switch
end

---------------------------------------------------------------------
-- resize button
---------------------------------------------------------------------
function AF.CreateResizeButton(target, minWidth, minHeight, maxWidth, maxHeight)
    local b = CreateFrame("Button", nil, target)
    Mixin(b, PanelResizeButtonMixin)

    b:Init(target, minWidth, minHeight, maxWidth, maxHeight)

    AF.SetSize(b, 16, 16)
    AF.SetPoint(b, "BOTTOMRIGHT", -1, 1)


    b:SetScript("OnEnter", b.OnEnter)
    b:SetScript("OnLeave", b.OnLeave)
    b:SetScript("OnMouseDown", b.OnMouseDown)
    b:SetScript("OnMouseUp", b.OnMouseUp)

    local tex = b:CreateTexture(nil, "ARTWORK")
    b.tex = tex
    tex:SetAllPoints()
    tex:SetTexture(AF.GetIcon("ResizeButton"))

    return b
end