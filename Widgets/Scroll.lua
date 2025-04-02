---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- scroll frame
---------------------------------------------------------------------
---@class AF_ScrollFrame:AF_BorderedFrame
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

---@return AF_ScrollFrame scrollParent
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
---@class AF_ScrollList:AF_BorderedFrame
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
            w._slotIndex = slotIndex
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
---@return AF_ScrollList scrollList
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