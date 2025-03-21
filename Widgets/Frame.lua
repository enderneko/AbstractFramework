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
        frame:SetFrameLevel(relativeTo:GetFrameLevel() + level)
    else
        frame:SetFrameLevel(frame:GetParent():GetFrameLevel() + level)
    end
end

---------------------------------------------------------------------
-- backdrops
---------------------------------------------------------------------
function AF.ApplyDefaultBackdrop(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    local n = AF.ConvertPixelsForRegion(borderSize or 1, frame)
    AF.SetBackdrop(frame, {bgFile=AF.GetPlainTexture(), edgeFile=AF.GetPlainTexture(), edgeSize=n, insets={left=n, right=n, top=n, bottom=n}})
end

function AF.ApplyDefaultBackdrop_NoBackground(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    AF.SetBackdrop(frame, {edgeFile=AF.GetPlainTexture(), edgeSize=AF.ConvertPixelsForRegion(borderSize or 1, frame)})
end

function AF.ApplyDefaultBackdrop_NoBorder(frame)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    AF.SetBackdrop(frame, {bgFile=AF.GetPlainTexture()})
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

---@class AF_Frame
local AF_FrameMixin = {}

function AF_FrameMixin:SetOnShow(func)
    self:SetScript("OnShow", func)
end

function AF_FrameMixin:SetOnHide(func)
    self:SetScript("OnHide", func)
end

function AF_FrameMixin:SetOnEnter(func)
    self:SetScript("OnEnter", func)
end

function AF_FrameMixin:SetOnLeave(func)
    self:SetScript("OnLeave", func)
end

function AF_FrameMixin:SetOnUpdate(func)
    self:SetScript("OnUpdate", func)
end

---@return AF_Frame|Frame frame
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

---@class AF_HeaderedFrame
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

---@return AF_HeaderedFrame|AF_Frame|Frame headeredFrame
function AF.CreateHeaderedFrame(parent, name, title, width, height, frameStrata, frameLevel, notUserPlaced)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:Hide()
    f:EnableMouse(true)
    -- f:SetIgnoreParentScale(true)
    -- f:SetResizable(false)
    f:SetMovable(true)
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
    header:SetScript("OnDragStart", function()
        f:StartMoving()
        if notUserPlaced then f:SetUserPlaced(false) end
    end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    AF.SetPoint(header, "LEFT")
    AF.SetPoint(header, "RIGHT")
    AF.SetPoint(header, "BOTTOM", f, "TOP", 0, -1)
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

    Mixin(f, AF_FrameMixin)
    Mixin(f, AF_HeaderedFrameMixin)
    AF.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- bordered frame
---------------------------------------------------------------------
---@class AF_BorderedFrame
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
---@return AF_BorderedFrame|AF_Frame|Frame borderedFrame
function AF.CreateBorderedFrame(parent, name, width, height, color, borderColor)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    AF.ApplyDefaultBackdropWithColors(f, color, borderColor)
    AF.SetSize(f, width, height)

    Mixin(f, AF_FrameMixin)
    Mixin(f, AF_BorderedFrameMixin)
    AF.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- titled pane
---------------------------------------------------------------------
---@param color string color name defined in Color.lua
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
    AF.SetHeight(shadow, 1)
    shadow:SetColorTexture(0, 0, 0, 1)
    AF.SetPoint(shadow, "TOPLEFT", line, 1, -1)
    AF.SetPoint(shadow, "TOPRIGHT", line, 1, -1)

    -- title
    local text = AF.CreateFontString(pane, title, "accent")
    pane.title = text
    text:SetJustifyH("LEFT")
    AF.SetPoint(text, "BOTTOMLEFT", line, "TOPLEFT", 0, 2)

    function pane:SetTitle(t)
        text:SetText(t)
    end

    function pane:UpdatePixels()
        AF.ReSize(pane)
        AF.RePoint(pane)
        AF.ReSize(line)
        AF.RePoint(line)
        AF.ReSize(shadow)
        AF.RePoint(shadow)
        AF.RePoint(text)
    end

    AF.AddToPixelUpdater(pane)

    return pane
end

---------------------------------------------------------------------
-- scroll frame
---------------------------------------------------------------------
---@class AF_ScrollFrame
local AF_ScrollFrameMixin = {}

-- reset scrollContent height (reset scroll range)
function AF_ScrollFrameMixin:ResetHeight()
    AF.SetHeight(self.scrollContent, 5)
end

-- reset scroll to top
function AF_ScrollFrameMixin:ResetScroll()
    self.scrollFrame:SetVerticalScroll(0)
end

-- NOTE: GetVerticalScrollRange can be wrong if not visible
function AF_ScrollFrameMixin:GetVerticalScrollRange()
    local range = self.scrollContent:GetHeight() - self.scrollFrame:GetHeight()
    return range > 0 and range or 0
end

-- for mouse wheel
function AF_ScrollFrameMixin:VerticalScroll(step)
    local scroll = self.scrollFrame:GetVerticalScroll() + step
    if scroll <= 0 then
        self.scrollFrame:SetVerticalScroll(0)
    elseif scroll >= self:GetVerticalScrollRange() then
        self.scrollFrame:SetVerticalScroll(self:GetVerticalScrollRange())
    else
        self.scrollFrame:SetVerticalScroll(scroll)
    end
end

function AF_ScrollFrameMixin:ScrollToBottom()
    self.scrollFrame:SetVerticalScroll(self:GetVerticalScrollRange())
end

function AF_ScrollFrameMixin:SetContentHeight(height, num, spacing, extraHeight)
    self:ResetScroll()
    if num and spacing then
        AF.SetListHeight(self.scrollContent, num, height, spacing, extraHeight)
    else
        AF.SetHeight(self.scrollContent, height)
    end
end

function AF_ScrollFrameMixin:SetScrollStep(step)
    self.step = step
end

function AF_ScrollFrameMixin:ClearContent()
    for _, c in pairs({self.scrollContent:GetChildren()}) do
        c:SetParent(nil)
        c:ClearAllPoints()
        c:Hide()
    end
    self:ResetHeight()
end

function AF_ScrollFrameMixin:Reset()
    self:ResetScroll()
    self:ClearContent()
end

function AF_ScrollFrameMixin:UpdatePixels()
    -- scrollBar / scrollThumb / children already AddToPixelUpdater
    --! scrollParent's UpdatePixels is Overrided here
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)

    AF.RePoint(self.scrollFrame)
    AF.ReBorder(self.scrollFrame)

    AF.ReSize(self.scrollContent) -- SetListHeight
    self.scrollContent:SetWidth(self.scrollFrame:GetWidth())

    -- reset scroll
    self:ResetScroll()
end

---@return AF_ScrollFrame|Frame scrollParent
function AF.CreateScrollFrame(parent, name, width, height, color, borderColor)
    local scrollParent = AF.CreateBorderedFrame(parent, name, width, height, color, borderColor)

    -- scrollFrame (which actually scrolls)
    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollParent, "BackdropTemplate")
    scrollParent.scrollFrame = scrollFrame
    AF.SetPoint(scrollFrame, "TOPLEFT")
    AF.SetPoint(scrollFrame, "BOTTOMRIGHT")

    -- scrollContent
    local scrollContent = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollParent.scrollContent = scrollContent
    AF.SetSize(scrollContent, width, 5)
    scrollFrame:SetScrollChild(scrollContent)
    -- AF.SetPoint(scrollContent, "RIGHT") -- update width with scrollFrame

    -- scrollBar
    local scrollBar = AF.CreateBorderedFrame(scrollParent, nil, 5, nil, color, borderColor)
    scrollParent.scrollBar = scrollBar
    AF.SetPoint(scrollBar, "TOPRIGHT")
    AF.SetPoint(scrollBar, "BOTTOMRIGHT")
    scrollBar:Hide()

    -- scrollBar thumb
    local scrollThumb = AF.CreateBorderedFrame(scrollBar, nil, 5, nil, AF.GetColorTable("accent", 0.8))
    scrollParent.scrollThumb = scrollThumb
    AF.SetPoint(scrollThumb, "TOP")
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    scrollThumb:SetHitRectInsets(-5, -5, 0, 0) -- Frame:SetHitRectInsets(left, right, top, bottom)

    Mixin(scrollParent, AF_ScrollFrameMixin)

    -- on width changed (scrollBar show/hide)
    scrollFrame:SetScript("OnSizeChanged", function()
        -- update scrollContent width
        scrollContent:SetWidth(scrollFrame:GetWidth())
    end)

    -- check if it can scroll
    -- DO NOT USE OnScrollRangeChanged to check whether it can scroll.
    -- "invisible" widgets should be hidden, then the scroll range is NOT accurate!
    -- scrollFrame:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset) end)
    scrollContent:SetScript("OnSizeChanged", function()
        -- set thumb height (%)
        local p = scrollFrame:GetHeight() / scrollContent:GetHeight()
        p = tonumber(string.format("%.3f", p))
        if p < 1 then -- can scroll
            scrollThumb:SetHeight(scrollBar:GetHeight()*p)
            -- space for scrollBar
            AF.SetPoint(scrollFrame, "BOTTOMRIGHT", -7, 0)
            scrollBar:Show()
        else
            AF.SetPoint(scrollFrame, "BOTTOMRIGHT")
            scrollBar:Hide()
            scrollFrame:SetVerticalScroll(0)
        end
    end)

    local function OnVerticalScroll(self, offset)
        if scrollParent:GetVerticalScrollRange() ~= 0 then
            local scrollP = scrollFrame:GetVerticalScroll() / scrollParent:GetVerticalScrollRange()
            local yoffset = -((scrollBar:GetHeight() - scrollThumb:GetHeight()) * scrollP)
            scrollThumb:SetPoint("TOP", 0, yoffset)
        end
    end
    scrollFrame:SetScript("OnVerticalScroll", OnVerticalScroll)

    -- dragging and scrolling
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        scrollFrame:SetScript("OnVerticalScroll", nil) -- disable OnVerticalScroll

        local offsetY = select(5, scrollThumb:GetPoint(1))
        local mouseY = select(2, GetCursorPosition()) -- https://warcraft.wiki.gg/wiki/API_GetCursorPosition
        local scale = scrollThumb:GetEffectiveScale()
        local currentScroll = scrollFrame:GetVerticalScroll()
        self:SetScript("OnUpdate", function(self)
            local newMouseY = select(2, GetCursorPosition())
            ------------------ y offset before dragging + mouse offset
            local newOffsetY = offsetY + (newMouseY - mouseY) / scale

            -- even scrollThumb:SetPoint is already done in OnVerticalScroll, but it's useful in some cases.
            if newOffsetY >= 0 then -- top
                AF.SetPoint(scrollThumb, "TOP")
                newOffsetY = 0
            elseif (-newOffsetY) + scrollThumb:GetHeight() >= scrollBar:GetHeight() then -- bottom
                AF.SetPoint(scrollThumb, "TOP", 0, -(scrollBar:GetHeight() - scrollThumb:GetHeight()))
                newOffsetY = -(scrollBar:GetHeight() - scrollThumb:GetHeight())
            else
                AF.SetPoint(scrollThumb, "TOP", 0, newOffsetY)
            end
            local vs = (-newOffsetY / (scrollBar:GetHeight()-scrollThumb:GetHeight())) * scrollParent:GetVerticalScrollRange()
            scrollFrame:SetVerticalScroll(vs)
        end)
    end)

    scrollThumb:SetScript("OnMouseUp", function(self)
        scrollFrame:SetScript("OnVerticalScroll", OnVerticalScroll) -- enable OnVerticalScroll
        self:SetScript("OnUpdate", nil)
    end)

    -- enable mouse wheel scroll
    scrollParent:SetScrollStep(25)
    scrollParent:EnableMouseWheel(true)
    scrollParent:SetScript("OnMouseWheel", function(self, delta)
        if delta == 1 then -- scroll up
            scrollParent:VerticalScroll(AF.ConvertPixelsForRegion(-scrollParent.step, scrollFrame))
        elseif delta == -1 then -- scroll down
            scrollParent:VerticalScroll(AF.ConvertPixelsForRegion(scrollParent.step, scrollFrame))
        end
    end)

    AF.AddToPixelUpdater(scrollParent)

    return scrollParent
end

---------------------------------------------------------------------
-- scroll list (filled with widgets)
---------------------------------------------------------------------
---@class AF_ScrollList
local AF_ScrollListMixin = {}

---@private
function AF_ScrollListMixin:UpdateSlots()
    for i = 1, self.slotNum do
        if not self.slots[i] then
            self.slots[i] = AF.CreateFrame(self.slotFrame)
            AF.SetHeight(self.slots[i], self.slotHeight)
            AF.SetPoint(self.slots[i], "RIGHT", -self.horizontalMargins, 0)
            if i == 1 then
                AF.SetPoint(self.slots[i], "TOPLEFT", self.horizontalMargins, 0)
            else
                AF.SetPoint(self.slots[i], "TOPLEFT", self.slots[i-1], "BOTTOMLEFT", 0, -self.slotSpacing)
            end
        end
        self.slots[i]:Show()
        if self.slots[i].widget then
            self.slots[i].widget:Show()
        end
    end
    -- hide unused slots
    for i = self.slotNum+1, #self.slots do
        self.slots[i]:Hide()
        if self.slots[i].widget then
            self.slots[i].widget:Hide()
        end
    end
end

-- NOTE: for dropdowns only
function AF_ScrollListMixin:SetSlotNum(newSlotNum)
    self.slotNum = newSlotNum
    if self.slotNum == 0 then
        AF.SetHeight(self, 5)
    else
        AF.SetListHeight(self, self.slotNum, self.slotHeight, self.slotSpacing, self.verticalMargins*2)
    end
    self:UpdateSlots()
end

function AF_ScrollListMixin:SetWidgets(widgets)
    self:Reset()
    self.widgets = widgets
    self.widgetNum = #widgets
    self:SetScroll(1)

    if self.widgetNum > self.slotNum then -- can scroll
        local p = self.slotNum / self.widgetNum
        self.scrollThumb:SetHeight(self.scrollBar:GetHeight() * p)
        AF.SetPoint(self.slotFrame, "BOTTOMRIGHT", -7, self.verticalMargins)
        self.scrollBar:Show()
    else
        AF.SetPoint(self.slotFrame, "BOTTOMRIGHT", 0, self.verticalMargins)
        self.scrollBar:Hide()
    end
end

-- reset
function AF_ScrollListMixin:Reset()
    self.widgets = {}
    self.widgetNum = 0
    -- hide slot widgets
    for _, s in ipairs(self.slots) do
        if s.widget then
            s.widget:Hide()
        end
        s.widget = nil
        s.widgetIndex = nil
    end
    -- resize / repoint
    AF.SetPoint(self.slotFrame, "BOTTOMRIGHT", 0, self.verticalMargins)
    self.scrollBar:Hide()
end

---@param startIndex number start index of widgets
function AF_ScrollListMixin:SetScroll(startIndex)
    if not startIndex then return end

    if startIndex <= 0 then startIndex = 1 end
    local total = self.widgetNum
    local from, to = startIndex, startIndex + self.slotNum - 1

    -- not enough widgets (fill from the first)
    if total <= self.slotNum then
        from = 1
        to = total

    -- have enough widgets, but result in empty slots, fix it
    elseif total - startIndex + 1 < self.slotNum then
        from = total - self.slotNum + 1 -- total > slotNum
        to = total
    end

    if self.slots[1].widgetIndex == from then
        return
    end

    -- fill
    local slotIndex = 1
    for i, w in ipairs(self.widgets) do
        w:ClearAllPoints()
        if i < from or i > to then
            w:Hide()
        else
            w:Show()
            w:SetAllPoints(self.slots[slotIndex])
            if w.Update then
                -- NOTE: fix some widget issues, define them manually
                w:Update()
            end
            self.slots[slotIndex].widget = w
            self.slots[slotIndex].widgetIndex = i
            slotIndex = slotIndex + 1
        end
    end

    -- reset empty slots
    for i = slotIndex, self.slotNum do
        self.slots[i].widget = nil
        self.slots[slotIndex].widgetIndex = nil
    end

    -- update scorll thumb
    if self:CanScroll() then
        local offset = (from - 1) * ((self.scrollBar:GetHeight() - self.scrollThumb:GetHeight()) / self:GetScrollRange()) -- n * perHeight
        self.scrollThumb:SetPoint("TOP", 0, -offset)
    end
end

function AF_ScrollListMixin:ScrollToBottom()
    self:SetScroll(self.widgetNum - self.slotNum + 1)
end

---@return number index the first shown widget index
---@return Frame widget the first shown widget
function AF_ScrollListMixin:GetScroll()
    if self.widgetNum == 0 then return end
    return self.slots[1].widgetIndex, self.slots[1].widget
end

function AF_ScrollListMixin:GetScrollRange()
    local range = self.widgetNum - self.slotNum
    return range <= 0 and 0 or range
end

function AF_ScrollListMixin:CanScroll()
    return self.widgetNum > self.slotNum
end

function AF_ScrollListMixin:SetScrollStep(step)
    self.step = step
end

function AF_ScrollListMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.ReBorder(self)
    AF.RePoint(self.slotFrame)
    -- do it again, even if already invoked by AF.UpdatePixels
    AF.RePoint(self.scrollBar)
    for _, s in ipairs(self.slots) do
        s:UpdatePixels()
        if s.widget and s.widget.UpdatePixels then
            s.widget:UpdatePixels()
        end
    end
    -- update scorll thumb
    if self:CanScroll() and self.slots[1].widgetIndex then
        local offset = (self.slots[1].widgetIndex - 1) * ((self.scrollBar:GetHeight() - self.scrollThumb:GetHeight()) / self:GetScrollRange()) -- n * perHeight
        self.scrollThumb:SetPoint("TOP", 0, -offset)
    end
end

---@param verticalMargins number top/bottom margin
---@param horizontalMargins number left/right margin
---@param slotSpacing number spacing between widgets next to each other
---@return AF_ScrollList|Frame scrollList
function AF.CreateScrollList(parent, name, width, verticalMargins, horizontalMargins, slotNum, slotHeight, slotSpacing, color, borderColor)
    local scrollList = AF.CreateBorderedFrame(parent, name, width, nil, color, borderColor)
    AF.SetListHeight(scrollList, slotNum, slotHeight, slotSpacing, verticalMargins*2)

    scrollList.slotNum = slotNum
    scrollList.slotHeight = slotHeight
    scrollList.slotSpacing = slotSpacing
    scrollList.verticalMargins = verticalMargins
    scrollList.horizontalMargins = horizontalMargins

    -- slotFrame
    local slotFrame = CreateFrame("Frame", nil, scrollList)
    scrollList.slotFrame = slotFrame
    AF.SetPoint(slotFrame, "TOPLEFT", 0, -verticalMargins)
    AF.SetPoint(slotFrame, "BOTTOMRIGHT", 0, verticalMargins)

    -- scrollBar
    local scrollBar = AF.CreateBorderedFrame(scrollList, nil, 5, nil, color, borderColor)
    scrollList.scrollBar = scrollBar
    AF.SetPoint(scrollBar, "TOPRIGHT", 0, -verticalMargins)
    AF.SetPoint(scrollBar, "BOTTOMRIGHT", 0, verticalMargins)
    scrollBar:Hide()


    -- scrollBar thumb
    local scrollThumb = AF.CreateBorderedFrame(scrollBar, nil, 5, nil, AF.GetAccentColorTable(0.7))
    scrollList.scrollThumb = scrollThumb
    scrollThumb.r, scrollThumb.g, scrollThumb.b = AF.GetAccentColorRGB()
    -- AF.SetPoint(scrollThumb, "TOP")
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    scrollThumb:SetHitRectInsets(-5, -5, 0, 0) -- Frame:SetHitRectInsets(left, right, top, bottom)
    scrollThumb:SetScript("OnEnter", function()
        scrollThumb:SetBackdropColor(scrollThumb.r, scrollThumb.g, scrollThumb.b, 0.9)
    end)
    scrollThumb:SetScript("OnLeave", function()
        scrollThumb:SetBackdropColor(scrollThumb.r, scrollThumb.g, scrollThumb.b, 0.7)
    end)

    -- slots
    scrollList.slots = {}

    Mixin(scrollList, AF_ScrollListMixin)
    scrollList:UpdateSlots()

    -- items
    scrollList.widgets = {}
    scrollList.widgetNum = 0

    -- for mouse wheel ----------------------------------------------
    scrollList:SetScrollStep(1)

    -- enable mouse wheel scroll
    scrollList:EnableMouseWheel(true)
    scrollList:SetScript("OnMouseWheel", function(self, delta)
        if scrollList.widgetNum == 0 then return end
        if delta == 1 then -- scroll up
            scrollList:SetScroll(scrollList:GetScroll() - scrollList.step)
        elseif delta == -1 then -- scroll down
            scrollList:SetScroll(scrollList:GetScroll() + scrollList.step)
        end
    end)
    -----------------------------------------------------------------

    -- dragging and scrolling ---------------------------------------
    scrollThumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end

        local scale = scrollThumb:GetEffectiveScale()
        local offsetY = select(5, scrollThumb:GetPoint(1))
        local mouseY = select(2, GetCursorPosition()) / scale -- https://warcraft.wiki.gg/wiki/API_GetCursorPosition

        self:SetScript("OnUpdate", function(self)
            local newMouseY = select(2, GetCursorPosition()) / scale
            local mouseOffset = newMouseY - mouseY
            local newOffsetY = offsetY + mouseOffset

            -- top ------------------------------
            if newOffsetY >= 0 then
                if scrollList:GetScroll() ~= 1 then
                    scrollList:SetScroll(1)
                end

            -- bottom ---------------------------
            elseif (-newOffsetY) + scrollThumb:GetHeight() >= scrollBar:GetHeight() then
                if scrollList:GetScroll() ~= scrollList:GetScrollRange() + 1 then
                    scrollList:SetScroll(scrollList:GetScrollRange() + 1)
                end

            -- scroll ---------------------------
            else
                local threshold = (scrollBar:GetHeight() - scrollThumb:GetHeight()) / scrollList:GetScrollRange()
                local targetIndex = Round(abs(newOffsetY) / threshold)
                targetIndex = max(targetIndex, 1)
                if targetIndex ~= scrollList:GetScroll() then
                    scrollList:SetScroll(targetIndex)
                end
            end
        end)
    end)

    scrollThumb:SetScript("OnMouseUp", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    -----------------------------------------------------------------

    AF.AddToPixelUpdater(scrollList)

    return scrollList
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