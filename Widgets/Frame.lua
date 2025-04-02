---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- function
---------------------------------------------------------------------
do
    local f = CreateFrame("Frame")
    AF.FrameSetSize = f.SetSize
    AF.FrameSetHeight = f.SetHeight
    AF.FrameSetWidth = f.SetWidth
    AF.FrameGetSize = f.GetSize
    AF.FrameGetHeight = f.GetHeight
    AF.FrameGetWidth = f.GetWidth
    AF.FrameSetPoint = f.SetPoint
    AF.FrameSetFrameLevel = f.SetFrameLevel
    AF.FrameShow = f.Show
    AF.FrameHide = f.Hide

    local c = CreateFrame("Cooldown")
    AF.FrameSetCooldown = c.SetCooldown
    AF.FrameSetCooldownDuration = c.SetCooldownDuration
end

---------------------------------------------------------------------
-- AF_BaseWidgetMixin
---------------------------------------------------------------------
---@class AF_BaseWidgetMixin
AF_BaseWidgetMixin = {}

function AF_BaseWidgetMixin:SetOnShow(func)
    self:SetScript("OnShow", func)
end

function AF_BaseWidgetMixin:HookOnShow(func)
    self:HookScript("OnShow", func)
end

function AF_BaseWidgetMixin:SetOnHide(func)
    self:SetScript("OnHide", func)
end

function AF_BaseWidgetMixin:HookOnHide(func)
    self:HookScript("OnHide", func)
end

function AF_BaseWidgetMixin:SetOnEnter(func)
    self:SetScript("OnEnter", func)
end

function AF_BaseWidgetMixin:HookOnEnter(func)
    self:HookScript("OnEnter", func)
end

function AF_BaseWidgetMixin:SetOnLeave(func)
    self:SetScript("OnLeave", func)
end

function AF_BaseWidgetMixin:HookOnLeave(func)
    self:HookScript("OnLeave", func)
end

function AF_BaseWidgetMixin:SetOnMouseDown(func)
    self:SetScript("OnMouseDown", func)
end

function AF_BaseWidgetMixin:HookOnMouseDown(func)
    self:HookScript("OnMouseDown", func)
end

function AF_BaseWidgetMixin:SetOnMouseUp(func)
    self:SetScript("OnMouseUp", func)
end

function AF_BaseWidgetMixin:HookOnMouseUp(func)
    self:HookScript("OnMouseUp", func)
end

function AF_BaseWidgetMixin:SetOnMouseWheel(func)
    self:SetScript("OnMouseWheel", func)
end

function AF_BaseWidgetMixin:HookOnMouseWheel(func)
    self:HookScript("OnMouseWheel", func)
end

function AF_BaseWidgetMixin:SetOnLoad(func)
    self:SetScript("OnLoad", func)
end

function AF_BaseWidgetMixin:HookOnLoad(func)
    self:HookScript("OnLoad", func)
end

function AF_BaseWidgetMixin:SetOnEnable(func)
    if self:HasScript("OnEnable") then
        self:SetScript("OnEnable", func)
    end
end

function AF_BaseWidgetMixin:HookOnEnable(func)
    if self:HasScript("OnEnable") then
        self:HookScript("OnEnable", func)
    end
end

function AF_BaseWidgetMixin:SetOnDisable(func)
    if self:HasScript("OnDisable") then
        self:SetScript("OnDisable", func)
    end
end

function AF_BaseWidgetMixin:HookOnDisable(func)
    if self:HasScript("OnDisable") then
        self:HookScript("OnDisable", func)
    end
end

function AF_BaseWidgetMixin:SetOnUpdate(func)
    if self:HasScript("OnUpdate") then
        self:SetScript("OnUpdate", func)
    end
end

function AF_BaseWidgetMixin:HookOnUpdate(func)
    if self:HasScript("OnUpdate") then
        self:HookScript("OnUpdate", func)
    end
end

function AF_BaseWidgetMixin:SetOnSizeChanged(func)
    if self:HasScript("OnSizeChanged") then
        self:SetScript("OnSizeChanged", func)
    end
end

function AF_BaseWidgetMixin:HookOnSizeChanged(func)
    if self:HasScript("OnSizeChanged") then
        self:HookScript("OnSizeChanged", func)
    end
end

function AF_BaseWidgetMixin:Toggle()
    if self:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

---------------------------------------------------------------------
-- enable / disable
---------------------------------------------------------------------
function AF.SetEnabled(isEnabled, ...)
    if isEnabled == nil then isEnabled = false end

    for _, w in pairs({...}) do
        if w:IsObjectType("FontString") then
            if isEnabled then
                w:SetTextColor(AF.GetColorRGB("white"))
            else
                w:SetTextColor(AF.GetColorRGB("disabled"))
            end
        elseif w:IsObjectType("Texture") then
            if isEnabled then
                w:SetDesaturated(false)
            else
                w:SetDesaturated(true)
            end
        elseif w.SetEnabled then
            w:SetEnabled(isEnabled)
        elseif isEnabled then
            w:Show()
        else
            w:Hide()
        end
    end
end

function AF.Enable(...)
    AF.SetEnabled(true, ...)
end

function AF.Disable(...)
    AF.SetEnabled(false, ...)
end

---------------------------------------------------------------------
-- frame level relative to parent
---------------------------------------------------------------------
function AF.SetFrameLevel(frame, level, relativeTo)
    if relativeTo then
        frame:SetFrameLevel(AF.Clamp(relativeTo:GetFrameLevel() + level, 0, 10000))
    else
        frame:SetFrameLevel(AF.Clamp(frame:GetParent():GetFrameLevel() + level, 0, 10000))
    end
end

---------------------------------------------------------------------
-- backdrops
---------------------------------------------------------------------
function AF.ApplyDefaultBackdrop(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    local n = borderSize or 1
    AF.SetBackdrop(frame, {bgFile = AF.GetPlainTexture(), edgeFile = AF.GetPlainTexture(), edgeSize = n, insets = {left = n, right = n, top = n, bottom = n}})
end

function AF.ApplyDefaultBackdrop_NoBackground(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    AF.SetBackdrop(frame, {edgeFile = AF.GetPlainTexture(), edgeSize = borderSize or 1})
end

function AF.ApplyDefaultBackdrop_NoBorder(frame)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    AF.SetBackdrop(frame, {bgFile = AF.GetPlainTexture()})
end

function AF.ApplyDefaultBackdropColors(frame)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdropColor(AF.GetColorRGB("background"))
    frame:SetBackdropBorderColor(AF.GetColorRGB("border"))
end

---@param frame Frame
---@param color string|table color name defined in Color.lua or color table
---@param borderColor string|table color name defined in Color.lua or color table
function AF.ApplyDefaultBackdropWithColors(frame, color, borderColor)
    color = color or "background"
    borderColor = borderColor or "border"

    AF.ApplyDefaultBackdrop(frame)
    if type(color) == "string" then
        frame:SetBackdropColor(AF.GetColorRGB(color))
    else
        frame:SetBackdropColor(unpack(color))
    end
    if type(borderColor) == "string" then
        frame:SetBackdropBorderColor(AF.GetColorRGB(borderColor))
    else
        frame:SetBackdropBorderColor(unpack(borderColor))
    end
end

---------------------------------------------------------------------
-- drag
---------------------------------------------------------------------
function AF.SetDraggable(frame, notUserPlaced)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetMouseClickEnabled(true)
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
        if notUserPlaced then self:SetUserPlaced(false) end
    end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
end

---------------------------------------------------------------------
-- normal frame
---------------------------------------------------------------------
---@class AF_Frame:Frame,AF_BaseWidgetMixin
local AF_FrameMixin = {}

function AF_FrameMixin:SetOnEnter(func)
    self:SetScript("OnEnter", func)
end

function AF_FrameMixin:SetOnLeave(func)
    self:SetScript("OnLeave", func)
end

function AF_FrameMixin:SetOnUpdate(func)
    self:SetScript("OnUpdate", func)
end

---@return AF_Frame frame
function AF.CreateFrame(parent, name, width, height, template)
    local f = CreateFrame("Frame", name, parent, template)
    AF.SetSize(f, width, height)
    Mixin(f, AF_FrameMixin)
    AF.AddToPixelUpdater(f)
    return f
end

---------------------------------------------------------------------
-- titled frame
---------------------------------------------------------------------
local function HeaderedFrame_SetTitleBackgroundColor(self, color)
    if type(color) == "string" then color = AF.GetColorTable(color) end
    color = color or AF.GetColorTable("accent")
end

---@class AF_HeaderedFrame:AF_Frame
local AF_HeaderedFrameMixin = {}

function AF_HeaderedFrameMixin:SetTitleJustify(justify)
    AF.ClearPoints(self.header.text)
    if justify == "LEFT" then
        AF.SetPoint(self.header.text, "LEFT", 5, 0)
    elseif justify == "RIGHT" then
        AF.SetPoint(self.header.text, "RIGHT", self.header.closeBtn, "LEFT", -5, 0)
    else
        AF.SetPoint(self.header.text, "CENTER")
    end
end

function AF_HeaderedFrameMixin:SetTitle(title)
    self.header.text:SetText(title)
end

function AF_HeaderedFrameMixin:SetMovable(movable)
    self:_SetMovable(movable)
    if movable then
        self.header:SetScript("OnDragStart", function()
            self:StartMoving()
            if self.notUserPlaced then
                self:SetUserPlaced(false)
            end
        end)
        self.header:SetScript("OnDragStop", function()
            self:StopMovingOrSizing()
        end)
    else
        self.header:SetScript("OnDragStart", nil)
        self.header:SetScript("OnDragStop", nil)
    end
end

function AF_HeaderedFrameMixin:UpdatePixels()
    self:SetClampRectInsets(0, 0, AF.ConvertPixelsForRegion(20, self), 0)
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    AF.ReSize(self.header)
    AF.RePoint(self.header)
    AF.ReBorder(self.header)
    AF.RePoint(self.header.tex)
    AF.RePoint(self.header.text)
    self.header.closeBtn:UpdatePixels()
end

-- ---@param color? string default is accent
-- function AF_HeaderedFrameMixin:SetHeaderColor(color)
-- end

---@return AF_HeaderedFrame headeredFrame
function AF.CreateHeaderedFrame(parent, name, title, width, height, frameStrata, frameLevel, notUserPlaced)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:Hide()

    f.notUserPlaced = notUserPlaced

    f:EnableMouse(true)
    -- f:SetIgnoreParentScale(true)
    -- f:SetResizable(false)
    -- f:SetUserPlaced(not notUserPlaced)
    f:SetFrameStrata(frameStrata or "HIGH")
    f:SetFrameLevel(frameLevel or 1)
    f:SetClampedToScreen(true)
    f:SetClampRectInsets(0, 0, AF.ConvertPixelsForRegion(20, f), 0)
    AF.SetSize(f, width, height)
    f:SetPoint("CENTER")
    AF.ApplyDefaultBackdropWithColors(f)

    -- header
    local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.header = header
    header:EnableMouse(true)
    header:SetClampedToScreen(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnMouseDown", function()
        f:SetToplevel(true)
    end)

    AF.SetPoint(header, "BOTTOMLEFT", f, "TOPLEFT", 0, -1)
    AF.SetPoint(header, "BOTTOMRIGHT", f, "TOPRIGHT", 0, -1)
    AF.SetHeight(header, 20)
    AF.ApplyDefaultBackdropWithColors(header, "header")

    header.text = AF.CreateFontString(header, title, AF.GetAccentColorName(), "AF_FONT_TITLE")
    header.text:SetPoint("CENTER")

    header.closeBtn = AF.CreateCloseButton(header, f, 20, 20)
    header.closeBtn:SetPoint("TOPRIGHT")
    AF.RemoveFromPixelUpdater(header.closeBtn)

    local r, g, b = AF.GetAccentColorRGB()
    header.tex = header:CreateTexture(nil, "ARTWORK")
    header.tex:SetAllPoints(header)
    header.tex:SetColorTexture(r, g, b, 0.025)

    -- header.tex = AF.CreateGradientTexture(header, "Horizontal", {r, g, b, 0.25})
    -- AF.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AF.SetPoint(header.tex, "BOTTOMRIGHT", -1, 1)

    -- header.tex = AF.CreateGradientTexture(header, "VERTICAL", nil, {r, g, b, 0.25})
    -- AF.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AF.SetPoint(header.tex, "BOTTOMRIGHT", header, "RIGHT", -1, 0)

    -- header.tex2 = AF.CreateGradientTexture(header, "VERTICAL", {r, g, b, 0.25})
    -- AF.SetPoint(header.tex2, "TOPLEFT", header, "LEFT", 1, 0)
    -- AF.SetPoint(header.tex2, "BOTTOMRIGHT", -1, 1)

    -- header.tex = AF.CreateGradientTexture(header, "VERTICAL", nil, {r, g, b, 0.1})
    -- AF.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AF.SetPoint(header.tex, "BOTTOMRIGHT", -1, 1)

    -- header.tex2 = AF.CreateGradientTexture(header, "VERTICAL", {r, g, b, 0.1})
    -- AF.SetPoint(header.tex2, "TOPLEFT", 1, -1)
    -- AF.SetPoint(header.tex2, "BOTTOMRIGHT", -1, 1)

    -- header.tex = AF.CreateGradientTexture(header, "VERTICAL", {r, g, b, 0.1})
    -- AF.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AF.SetPoint(header.tex, "BOTTOMRIGHT", -1, 1)

    f._SetMovable = f.SetMovable

    Mixin(f, AF_FrameMixin)
    Mixin(f, AF_HeaderedFrameMixin)
    Mixin(f, AF_BaseWidgetMixin)

    f:SetMovable(true)

    AF.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- bordered frame
---------------------------------------------------------------------
---@class AF_BorderedFrame:AF_Frame
local AF_BorderedFrameMixin = {}

function AF_BorderedFrameMixin:SetLabel(label, fontColor, font, isInside)
    if not self.label then
        self.label = AF.CreateFontString(self, label, fontColor or "accent", font)
        self.label:SetJustifyH("LEFT")
    else
        self.label:SetText(label)
    end

    AF.ClearPoints(self.label)
    if isInside then
        AF.SetPoint(self.label, "TOPLEFT", 2, -2)
    else
        AF.SetPoint(self.label, "BOTTOMLEFT", self, "TOPLEFT", 2, 2)
    end
end

---@param color string|table color name / table
---@param borderColor string|table color name / table
---@return AF_BorderedFrame borderedFrame
function AF.CreateBorderedFrame(parent, name, width, height, color, borderColor)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    AF.ApplyDefaultBackdropWithColors(f, color, borderColor)
    AF.SetSize(f, width, height)

    Mixin(f, AF_FrameMixin)
    Mixin(f, AF_BorderedFrameMixin)
    Mixin(f, AF_BaseWidgetMixin)
    AF.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- titled pane
---------------------------------------------------------------------
---@class AF_TitledPane:Frame,AF_BaseWidgetMixin
local AF_TitledPaneMixin = {}

function AF_TitledPaneMixin:SetTitle(title)
    self.title:SetText(title)
end

function AF_TitledPaneMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReSize(self.line)
    AF.RePoint(self.line)
    AF.ReSize(self.shadow)
    AF.RePoint(self.shadow)
    -- AF.RePoint(self.title)
end

---@param color string color name defined in Color.lua
---@return AF_TitledPane
function AF.CreateTitledPane(parent, title, width, height, color)
    color = color or "accent"

    local pane = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    AF.SetSize(pane, width, height)

    -- underline
    local line = pane:CreateTexture()
    pane.line = line
    line:SetColorTexture(AF.GetColorRGB(color, 0.8))
    AF.SetHeight(line, 1)
    AF.SetPoint(line, "TOPLEFT", pane, 0, -17)
    AF.SetPoint(line, "TOPRIGHT", pane, 0, -17)

    local shadow = pane:CreateTexture()
    pane.shadow = shadow
    AF.SetHeight(shadow, 1)
    shadow:SetColorTexture(0, 0, 0, 1)
    AF.SetPoint(shadow, "TOPLEFT", line, 1, -1)
    AF.SetPoint(shadow, "TOPRIGHT", line, 1, -1)

    -- title
    local text = AF.CreateFontString(pane, title, "accent")
    pane.title = text
    text:SetJustifyH("LEFT")
    AF.SetPoint(text, "BOTTOMLEFT", line, "TOPLEFT", 0, 2)

    Mixin(pane, AF_TitledPaneMixin)
    Mixin(pane, AF_BaseWidgetMixin)
    AF.AddToPixelUpdater(pane)

    return pane
end

---------------------------------------------------------------------
-- mask (+30 frame level)
---------------------------------------------------------------------
---@param parent Frame
---@param tlX number topleft x
---@param tlY number topleft y
---@param brX number bottomright x
---@param brY number bottomright y
---@return Frame
function AF.ShowMask(parent, text, tlX, tlY, brX, brY)
    if not parent.mask then
        parent.mask = AF.CreateFrame(parent)
        AF.ApplyDefaultBackdrop_NoBorder(parent.mask)
        parent.mask:SetBackdropColor(AF.GetColorRGB("mask"))
        parent.mask:EnableMouse(true)
        -- parent.mask:EnableMouseWheel(true) -- not enough
        parent.mask:SetScript("OnMouseWheel", function(self, delta)
            -- setting the OnMouseWheel script automatically implies EnableMouseWheel(true)
            -- print("OnMouseWheel", delta)
        end)

        parent.mask.text = AF.CreateFontString(parent.mask, "", "firebrick")
        AF.SetPoint(parent.mask.text, "LEFT", 5, 0)
        AF.SetPoint(parent.mask.text, "RIGHT", -5, 0)
    end

    parent.mask.text:SetText(text)

    AF.ClearPoints(parent.mask)
    if tlX or tlY or brX or brY then
        AF.SetPoint(parent.mask, "TOPLEFT", tlX, tlY)
        AF.SetPoint(parent.mask, "BOTTOMRIGHT", brX, brY)
    else
        AF.SetOnePixelInside(parent.mask, parent)
    end
    AF.SetFrameLevel(parent.mask, 30, parent)
    parent.mask:Show()

    return parent.mask
end

---@param parent Frame
function AF.HideMask(parent)
    if parent.mask then
        parent.mask:Hide()
    end
end

---------------------------------------------------------------------
-- cooldown
---------------------------------------------------------------------
---@class AF_Cooldown:Cooldown
local AF_CooldownMixin = {}

function AF_CooldownMixin:Start(duration)
    AF.FrameSetCooldownDuration(self, duration)
end

function AF_CooldownMixin:StartSince(start, duration)
    AF.FrameSetCooldown(self, start, duration)
end

function AF_CooldownMixin:SetOnCooldownDone(func)
    self:SetScript("OnCooldownDone", func)
end

---@param parent Frame
---@param name? string
---@param texture string
---@param color? string default is white
---@param reverse? boolean
---@return AF_Cooldown
function AF.CreateCooldown(parent, name, texture, color, reverse)
    local cd = CreateFrame("Cooldown", name, parent)
    cd:SetSwipeTexture(texture)
    cd:SetSwipeColor(AF.GetColorRGB(color or "white"))
    cd:SetDrawEdge(false)
    cd:SetDrawSwipe(true)
    cd:SetDrawBling(false)
    cd:SetReverse(reverse)

    -- disable omnicc
    cd.noCooldownCount = true

    -- prevent some dirty addons from adding cooldown text
    cd.SetCooldown = nil
    cd.SetCooldownDuration = nil

    Mixin(cd, AF_CooldownMixin)

    AF.AddToPixelUpdater(cd)

    return cd
end

---------------------------------------------------------------------
-- combat mask (+100 frame level)
---------------------------------------------------------------------
local function CreateCombatMask(parent, tlX, tlY, brX, brY)
    parent.combatMask = AF.CreateFrame(parent)
    AF.ApplyDefaultBackdrop_NoBorder(parent.combatMask)
    parent.combatMask:SetBackdropColor(AF.GetColorRGB("combat_mask"))

    AF.SetFrameLevel(parent.combatMask, 100, parent)
    parent.combatMask:EnableMouse(true)
    parent.combatMask:SetScript("OnMouseWheel", function() end)

    parent.combatMask.text = AF.CreateFontString(parent.combatMask, "", "firebrick")
    AF.SetPoint(parent.combatMask.text, "LEFT", 5, 0)
    AF.SetPoint(parent.combatMask.text, "RIGHT", -5, 0)

    -- HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT
    -- ERR_AFFECTING_COMBAT
    -- ERR_NOT_IN_COMBAT
    parent.combatMask.text:SetText(_G.ERR_AFFECTING_COMBAT)

    AF.ClearPoints(parent.combatMask)
    if tlX or tlY or brX or brY then
        AF.SetPoint(parent.combatMask, "TOPLEFT", tlX, tlY)
        AF.SetPoint(parent.combatMask, "BOTTOMRIGHT", brX, brY)
    else
        AF.SetOnePixelInside(parent.combatMask, parent)
    end

    parent.combatMask:Hide()
end

-- show mask
local protectedFrames = {}
-- while in combat, overlay a non-click-through mask to protect the frame.
-- do not use SetScript OnShow/OnHide scripts after this function.
function AF.ApplyCombatProtectionToFrame(frame, tlX, tlY, brX, brY)
    if not frame.combatMask then
        CreateCombatMask(frame, tlX, tlY, brX, brY)
    end

    protectedFrames[frame] = true

    if InCombatLockdown() then
        frame.combatMask:Show()
    end

    frame:HookScript("OnShow", function()
        protectedFrames[frame] = true
        if InCombatLockdown() then
            frame.combatMask:Show()
        else
            frame.combatMask:Hide()
        end
    end)

    frame:HookScript("OnHide", function()
        protectedFrames[frame] = nil
        frame.combatMask:Hide()
    end)
end

local protectedWidgets = {}
-- while in combat, protect the widget by SetEnabled(false).
-- do not use SetScript OnShow/OnHide scripts after this function.
-- NOT SUGGESTED on widgets that are enabled/disabled by other events.
function AF.ApplyCombatProtectionToWidget(widget)
    if InCombatLockdown() then
        widget:SetEnabled(false)
    end

    protectedWidgets[widget] = true

    widget:HookScript("OnShow", function()
        protectedWidgets[widget] = true
        widget:SetEnabled(not InCombatLockdown())
    end)

    widget:HookScript("OnHide", function()
        protectedWidgets[widget] = nil
        widget:SetEnabled(true)
    end)
end

AF.CreateBasicEventHandler(function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        for f in pairs(protectedFrames) do
            f.combatMask:Show()
        end
        for w in pairs(protectedWidgets) do
            w:SetEnabled(false)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for f in pairs(protectedFrames) do
            f.combatMask:Hide()
        end
        for w in pairs(protectedWidgets) do
            w:SetEnabled(true)
        end
    end
end, "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED")