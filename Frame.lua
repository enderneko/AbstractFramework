---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- function
---------------------------------------------------------------------
local f = CreateFrame("Frame")
AW.FrameSetSize = f.SetSize
AW.FrameSetHeight = f.SetHeight
AW.FrameSetWidth = f.SetWidth
AW.FrameGetSize = f.GetSize
AW.FrameGetHeight = f.GetHeight
AW.FrameGetWidth = f.GetWidth
AW.FrameSetPoint = f.SetPoint
AW.FrameSetFrameLevel = f.SetFrameLevel
AW.FrameShow = f.Show
AW.FrameHide = f.Hide

local c = CreateFrame("Cooldown")
AW.FrameSetCooldown = c.SetCooldown

---------------------------------------------------------------------
-- frame level relative to parent
---------------------------------------------------------------------
function AW.SetFrameLevel(frame, level, relativeTo)
    if relativeTo then
        frame:SetFrameLevel(relativeTo:GetFrameLevel() + level)
    else
        frame:SetFrameLevel(frame:GetParent():GetFrameLevel() + level)
    end
end

---------------------------------------------------------------------
-- style
---------------------------------------------------------------------
--- @param color string|table color name defined in Color.lua or color table
--- @param borderColor string|table color name defined in Color.lua or color table
function AW.StylizeFrame(frame, color, borderColor)
    color = color or "background"
    borderColor = borderColor or "border"

    AW.SetDefaultBackdrop(frame)
    if type(color) == "string" then
        frame:SetBackdropColor(AW.GetColorRGB(color))
    else
        frame:SetBackdropColor(unpack(color))
    end
    if type(borderColor) == "string" then
        frame:SetBackdropBorderColor(AW.GetColorRGB(borderColor))
    else
        frame:SetBackdropBorderColor(unpack(borderColor))
    end
end

---------------------------------------------------------------------
-- backdrop
---------------------------------------------------------------------
function AW.SetDefaultBackdrop(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    local n = AW.ConvertPixelsForRegion(borderSize or 1, frame)
    frame:SetBackdrop({bgFile=AW.GetPlainTexture(), edgeFile=AW.GetPlainTexture(), edgeSize=n, insets={left=n, right=n, top=n, bottom=n}})
end

function AW.SetDefaultBackdrop_NoBackground(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({edgeFile=AW.GetPlainTexture(), edgeSize=AW.ConvertPixelsForRegion(borderSize or 1, frame)})
end

function AW.SetDefaultBackdrop_NoBorder(frame)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({bgFile=AW.GetPlainTexture()})
end

---------------------------------------------------------------------
-- drag
---------------------------------------------------------------------
function AW.SetDraggable(frame, notUserPlaced)
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
function AW.CreateFrame(parent, name, width, height)
    local f = CreateFrame("Frame", name, parent)
    AW.SetSize(f, width, height)

    function f:UpdatePixels()
        AW.ReSize(f)
        AW.RePoint(f)
    end

    AW.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- titled frame
---------------------------------------------------------------------
local function HeaderedFrame_SetTitleBackgroundColor(self, color)
    if type(color) == "string" then color = AW.GetColorTable(color) end
    color = color or AW.GetColorTable("accent")
end

function AW.CreateHeaderedFrame(parent, name, title, width, height, frameStrata, frameLevel, notUserPlaced)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:Hide()
    f:EnableMouse(true)
    -- f:SetIgnoreParentScale(true)
    -- f:SetResizable(false)
    f:SetMovable(true)
    f:SetUserPlaced(not notUserPlaced)
    f:SetFrameStrata(frameStrata or "HIGH")
    f:SetFrameLevel(frameLevel or 1)
    f:SetClampedToScreen(true)
    f:SetClampRectInsets(0, 0, AW.ConvertPixelsForRegion(20, f), 0)
    AW.SetSize(f, width, height)
    f:SetPoint("CENTER")
    AW.StylizeFrame(f)

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
    AW.SetPoint(header, "LEFT")
    AW.SetPoint(header, "RIGHT")
    AW.SetPoint(header, "BOTTOM", f, "TOP", 0, -1)
    AW.SetHeight(header, 20)
    AW.StylizeFrame(header, "header")

    header.text = AW.CreateFontString(header, title, AW.GetAccentColorName(), "AW_FONT_TITLE")
    header.text:SetPoint("CENTER")

    function f:SetTitleJustify(justify)
        AW.ClearPoints(header.text)
        if justify == "LEFT" then
            AW.SetPoint(header.text, "LEFT", 7, 0)
        elseif justify == "RIGHT" then
            AW.SetPoint(header.text, "RIGHT", header.closeBtn, "LEFT", -7, 0)
        else
            AW.SetPoint(header.text, "CENTER")
        end
    end

    header.closeBtn = AW.CreateCloseButton(header, f, 20, 20)
    header.closeBtn:SetPoint("TOPRIGHT")

    local r, g, b = AW.GetAccentColorRGB()

    header.tex = header:CreateTexture(nil, "ARTWORK")
    header.tex:SetAllPoints(header)
    header.tex:SetColorTexture(r, g, b, 0.025)

    -- header.tex = AW.CreateGradientTexture(header, "Horizontal", {r, g, b, 0.25})
    -- AW.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AW.SetPoint(header.tex, "BOTTOMRIGHT", -1, 1)

    -- header.tex = AW.CreateGradientTexture(header, "VERTICAL", nil, {r, g, b, 0.25})
    -- AW.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AW.SetPoint(header.tex, "BOTTOMRIGHT", header, "RIGHT", -1, 0)

    -- header.tex2 = AW.CreateGradientTexture(header, "VERTICAL", {r, g, b, 0.25})
    -- AW.SetPoint(header.tex2, "TOPLEFT", header, "LEFT", 1, 0)
    -- AW.SetPoint(header.tex2, "BOTTOMRIGHT", -1, 1)

    -- header.tex = AW.CreateGradientTexture(header, "VERTICAL", nil, {r, g, b, 0.1})
    -- AW.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AW.SetPoint(header.tex, "BOTTOMRIGHT", -1, 1)

    -- header.tex2 = AW.CreateGradientTexture(header, "VERTICAL", {r, g, b, 0.1})
    -- AW.SetPoint(header.tex2, "TOPLEFT", 1, -1)
    -- AW.SetPoint(header.tex2, "BOTTOMRIGHT", -1, 1)

    -- header.tex = AW.CreateGradientTexture(header, "VERTICAL", {r, g, b, 0.1})
    -- AW.SetPoint(header.tex, "TOPLEFT", 1, -1)
    -- AW.SetPoint(header.tex, "BOTTOMRIGHT", -1, 1)

    function f:UpdatePixels()
        f:SetClampRectInsets(0, 0, AW.ConvertPixelsForRegion(20, f), 0)
        AW.ReSize(f)
        AW.RePoint(f)
        AW.ReBorder(f)
        AW.ReSize(header)
        AW.RePoint(header)
        AW.ReBorder(header)
        AW.RePoint(header.tex)
        AW.RePoint(header.text)
        header.closeBtn:UpdatePixels()
    end

    AW.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- bordered frame
---------------------------------------------------------------------
--- @param color string|table color name / table
--- @param borderColor string|table color name / table
function AW.CreateBorderedFrame(parent, name, width, height, color, borderColor)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    AW.StylizeFrame(f, color, borderColor)
    AW.SetSize(f, width, height)

    function f:SetTitle(title, fontColor, font, isInside)
        if not f.title then
            f.title = AW.CreateFontString(f, title, fontColor or "accent", font)
            f.title:SetJustifyH("LEFT")
        else
            f.title:SetText(title)
        end

        AW.ClearPoints(f.title)
        if isInside then
            AW.SetPoint(f.title, "TOPLEFT", 2, -2)
        else
            AW.SetPoint(f.title, "BOTTOMLEFT", f, "TOPLEFT", 2, 2)
        end
    end

    function f:UpdatePixels()
        AW.ReSize(f)
        AW.RePoint(f)
        AW.ReBorder(f)
        if f.title then
            AW.RePoint(f.title)
        end
    end

    AW.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- frame static glow
---------------------------------------------------------------------
--- @param color string
function AW.SetFrameStaticGlow(parent, size, color, alpha)
    if not parent.staticGlow then
        parent.staticGlow = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        -- parent.staticGlow:SetAllPoints()
        parent.staticGlow:SetScript("OnHide", function() parent.staticGlow:Hide() end)
    end

    size = size or 5
    color = color or "accent"

    parent.staticGlow:SetBackdrop({edgeFile=AW.GetIcon("StaticGlow"), edgeSize=AW.ConvertPixelsForRegion(size, parent)})
    AW.SetOutside(parent.staticGlow, parent, size)
    parent.staticGlow:SetBackdropBorderColor(AW.GetColorRGB(color, alpha))

    parent.staticGlow:Show()
end

---------------------------------------------------------------------
-- titled pane
---------------------------------------------------------------------
--- @param color string color name defined in Color.lua
function AW.CreateTitledPane(parent, title, width, height, color)
    color = color or "accent"

    local pane = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    AW.SetSize(pane, width, height)

    -- underline
    local line = pane:CreateTexture()
    pane.line = line
    line:SetColorTexture(AW.GetColorRGB(color, 0.8))
    AW.SetHeight(line, 1)
    AW.SetPoint(line, "TOPLEFT", pane, 0, -17)
    AW.SetPoint(line, "TOPRIGHT", pane, 0, -17)

    local shadow = pane:CreateTexture()
    AW.SetHeight(shadow, 1)
    shadow:SetColorTexture(0, 0, 0, 1)
    AW.SetPoint(shadow, "TOPLEFT", line, 1, -1)
    AW.SetPoint(shadow, "TOPRIGHT", line, 1, -1)

    -- title
    local text = AW.CreateFontString(pane, title, "accent")
    pane.title = text
    text:SetJustifyH("LEFT")
    AW.SetPoint(text, "BOTTOMLEFT", line, "TOPLEFT", 0, 2)

    function pane:SetTitle(t)
        text:SetText(t)
    end

    function pane:UpdatePixels()
        AW.ReSize(pane)
        AW.RePoint(pane)
        AW.ReSize(line)
        AW.RePoint(line)
        AW.ReSize(shadow)
        AW.RePoint(shadow)
        AW.RePoint(text)
    end

    AW.AddToPixelUpdater(pane)

    return pane
end

---------------------------------------------------------------------
-- scroll frame
---------------------------------------------------------------------
function AW.CreateScrollFrame(parent, name, width, height, color, borderColor)
    local scrollParent = AW.CreateBorderedFrame(parent, name, width, height, color, borderColor)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollParent, "BackdropTemplate")
    scrollParent.scrollFrame = scrollFrame
    AW.SetPoint(scrollFrame, "TOPLEFT")
    AW.SetPoint(scrollFrame, "BOTTOMRIGHT")

    -- content
    local content = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollParent.scrollContent = content
    AW.SetSize(content, width, 5)
    scrollFrame:SetScrollChild(content)
    -- AW.SetPoint(content, "RIGHT") -- update width with scrollFrame

    -- scrollBar
    local scrollBar = AW.CreateBorderedFrame(scrollParent, nil, 5, nil, color, borderColor)
    scrollParent.scrollBar = scrollBar
    AW.SetPoint(scrollBar, "TOPRIGHT")
    AW.SetPoint(scrollBar, "BOTTOMRIGHT")
    scrollBar:Hide()

    -- scrollBar thumb
    local scrollThumb = AW.CreateBorderedFrame(scrollBar, nil, 5, nil, AW.GetColorTable("accent", 0.8))
    scrollParent.scrollThumb = scrollThumb
    AW.SetPoint(scrollThumb, "TOP")
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    scrollThumb:SetHitRectInsets(-5, -5, 0, 0) -- Frame:SetHitRectInsets(left, right, top, bottom)

    -- reset content height (reset scroll range)
    function scrollParent:ResetHeight()
        AW.SetHeight(content, 5)
    end

    -- reset scroll to top
    function scrollParent:ResetScroll()
        scrollFrame:SetVerticalScroll(0)
    end

    -- scrollFrame:GetVerticalScrollRange may return 0
    function scrollFrame:GetVerticalScrollRange()
        local range = content:GetHeight() - scrollFrame:GetHeight()
        return range > 0 and range or 0
    end
    scrollParent.GetVerticalScrollRange = scrollFrame.GetVerticalScrollRange

    -- for mouse wheel
    function scrollParent:VerticalScroll(step)
        local scroll = scrollFrame:GetVerticalScroll() + step
        if scroll <= 0 then
            scrollFrame:SetVerticalScroll(0)
        elseif scroll >= scrollFrame:GetVerticalScrollRange() then
            scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
        else
            scrollFrame:SetVerticalScroll(scroll)
        end
    end

    -- NOTE: do not call this if not visible, GetVerticalScrollRange may not be valid.
    function scrollParent:ScrollToBottom()
        scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
    end

    function scrollParent:SetContentHeight(height, num, spacing, extraHeight)
        scrollParent:ResetScroll()
        if num and spacing then
            AW.SetListHeight(content, num, height, spacing, extraHeight)
        else
            AW.SetHeight(content, height)
        end
    end

    function scrollParent:ClearContent()
        for _, c in pairs({content:GetChildren()}) do
            c:SetParent(nil)
            c:ClearAllPoints()
            c:Hide()
        end
        scrollParent:ResetHeight()
    end

    function scrollParent:Reset()
        scrollParent:ResetScroll()
        scrollParent:ClearContent()
    end

    -- on width changed (scrollBar show/hide)
    scrollFrame:SetScript("OnSizeChanged", function()
        -- update content width
        content:SetWidth(scrollFrame:GetWidth())
    end)

    -- check if it can scroll
    -- DO NOT USE OnScrollRangeChanged to check whether it can scroll.
    -- "invisible" widgets should be hidden, then the scroll range is NOT accurate!
    -- scrollFrame:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset) end)
    content:SetScript("OnSizeChanged", function()
        -- set thumb height (%)
        local p = scrollFrame:GetHeight() / content:GetHeight()
        p = tonumber(string.format("%.3f", p))
        if p < 1 then -- can scroll
            scrollThumb:SetHeight(scrollBar:GetHeight()*p)
            -- space for scrollBar
            AW.SetPoint(scrollFrame, "BOTTOMRIGHT", -7, 0)
            scrollBar:Show()
        else
            AW.SetPoint(scrollFrame, "BOTTOMRIGHT")
            scrollBar:Hide()
            scrollFrame:SetVerticalScroll(0)
        end
    end)

    local function OnVerticalScroll(self, offset)
        if scrollFrame:GetVerticalScrollRange() ~= 0 then
            local scrollP = scrollFrame:GetVerticalScroll()/scrollFrame:GetVerticalScrollRange()
            local yoffset = -((scrollBar:GetHeight()-scrollThumb:GetHeight())*scrollP)
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
                AW.SetPoint(scrollThumb, "TOP")
                newOffsetY = 0
            elseif (-newOffsetY) + scrollThumb:GetHeight() >= scrollBar:GetHeight() then -- bottom
                AW.SetPoint(scrollThumb, "TOP", 0, -(scrollBar:GetHeight() - scrollThumb:GetHeight()))
                newOffsetY = -(scrollBar:GetHeight() - scrollThumb:GetHeight())
            else
                AW.SetPoint(scrollThumb, "TOP", 0, newOffsetY)
            end
            local vs = (-newOffsetY / (scrollBar:GetHeight()-scrollThumb:GetHeight())) * scrollFrame:GetVerticalScrollRange()
            scrollFrame:SetVerticalScroll(vs)
        end)
    end)

    scrollThumb:SetScript("OnMouseUp", function(self)
        scrollFrame:SetScript("OnVerticalScroll", OnVerticalScroll) -- enable OnVerticalScroll
        self:SetScript("OnUpdate", nil)
    end)

    local step = 25
    function scrollParent:SetScrollStep(s)
        step = s
    end

    -- enable mouse wheel scroll
    scrollParent:EnableMouseWheel(true)
    scrollParent:SetScript("OnMouseWheel", function(self, delta)
        if delta == 1 then -- scroll up
            scrollParent:VerticalScroll(AW.ConvertPixelsForRegion(-step, scrollFrame))
        elseif delta == -1 then -- scroll down
            scrollParent:VerticalScroll(AW.ConvertPixelsForRegion(step, scrollFrame))
        end
    end)

    function scrollParent:UpdatePixels()
        -- scrollBar / scrollThumb / children already AddToPixelUpdater
        --! scrollParent's UpdatePixels is Overrided here
        AW.ReSize(scrollParent)
        AW.RePoint(scrollParent)
        AW.ReBorder(scrollParent)

        AW.RePoint(scrollFrame)
        AW.ReBorder(scrollFrame)

        AW.ReSize(content) -- SetListHeight
        content:SetWidth(scrollFrame:GetWidth())

        -- reset scroll
        scrollParent:ResetScroll()
    end

    AW.AddToPixelUpdater(scrollParent)

    return scrollParent
end

---------------------------------------------------------------------
-- scroll list (filled with widgets)
---------------------------------------------------------------------
--- @param verticalMargins number top/bottom margin
--- @param horizontalMargins number left/right margin
--- @param slotSpacing number spacing between widgets next to each other
function AW.CreateScrollList(parent, name, width, verticalMargins, horizontalMargins, slotNum, slotHeight, slotSpacing, color, borderColor)
    local scrollList = AW.CreateBorderedFrame(parent, name, width, nil, color, borderColor)
    AW.SetListHeight(scrollList, slotNum, slotHeight, slotSpacing, verticalMargins*2)

    local slotFrame = CreateFrame("Frame", nil, scrollList)
    scrollList.slotFrame = slotFrame
    AW.SetPoint(slotFrame, "TOPLEFT", 0, -verticalMargins)
    AW.SetPoint(slotFrame, "BOTTOMRIGHT", 0, verticalMargins)

    -- scrollBar
    local scrollBar = AW.CreateBorderedFrame(scrollList, nil, 5, nil, color, borderColor)
    scrollList.scrollBar = scrollBar
    AW.SetPoint(scrollBar, "TOPRIGHT", 0, -verticalMargins)
    AW.SetPoint(scrollBar, "BOTTOMRIGHT", 0, verticalMargins)
    scrollBar:Hide()

    -- scrollBar thumb
    local scrollThumb = AW.CreateBorderedFrame(scrollBar, nil, 5, nil, AW.GetColorTable("accent", 0.8))
    scrollList.scrollThumb = scrollThumb
    AW.SetPoint(scrollThumb, "TOP")
    scrollThumb:EnableMouse(true)
    scrollThumb:SetMovable(true)
    scrollThumb:SetHitRectInsets(-5, -5, 0, 0) -- Frame:SetHitRectInsets(left, right, top, bottom)

    -- slots
    local slots = {}

    local function UpdateSlots()
        for i = 1, slotNum do
            if not slots[i] then
                slots[i] = AW.CreateFrame(slotFrame)
                AW.SetHeight(slots[i], slotHeight)
                AW.SetPoint(slots[i], "RIGHT", -horizontalMargins, 0)
                if i == 1 then
                    AW.SetPoint(slots[i], "TOPLEFT", horizontalMargins, 0)
                else
                    AW.SetPoint(slots[i], "TOPLEFT", slots[i-1], "BOTTOMLEFT", 0, -slotSpacing)
                end
            end
            slots[i]:Show()
        end
        -- hide unused slots
        for i = slotNum+1, #slots do
            slots[i]:Hide()
        end
    end
    UpdateSlots()

    -- NOTE: for dropdowns only
    function scrollList:SetSlotNum(newSlotNum)
        slotNum = newSlotNum
        if slotNum == 0 then
            AW.SetHeight(scrollList, 5)
        else
            AW.SetListHeight(scrollList, slotNum, slotHeight, slotSpacing, verticalMargins*2)
        end
        UpdateSlots()
    end

    -- items
    scrollList.widgets = {}
    scrollList.widgetNum = 0
    function scrollList:SetWidgets(widgets)
        scrollList.widgets = widgets
        scrollList.widgetNum = #widgets
        scrollList:SetScroll(1)

        if scrollList.widgetNum > slotNum then -- can scroll
            local p = slotNum / scrollList.widgetNum
            scrollThumb:SetHeight(scrollBar:GetHeight()*p)
            AW.SetPoint(slotFrame, "BOTTOMRIGHT", -7, verticalMargins)
            scrollBar:Show()
        else
            AW.SetPoint(slotFrame, "BOTTOMRIGHT", 0, verticalMargins)
            scrollBar:Hide()
        end
    end

    -- reset
    function scrollList:Reset()
        scrollList.widgets = {}
        scrollList.widgetNum = 0
        -- hide slot widgets
        for _, s in ipairs(slots) do
            if s.widget then
                s.widget:Hide()
            end
            s.widget = nil
            s.widgetIndex = nil
        end
        -- resize / repoint
        AW.SetPoint(slotFrame, "BOTTOMRIGHT", 0, verticalMargins)
        scrollBar:Hide()
    end

    -- scroll: set start index of widgets
    function scrollList:SetScroll(startIndex)
        assert(startIndex, "startIndex can not be nil!")

        if startIndex <= 0 then startIndex = 1 end
        local total = scrollList.widgetNum
        local from, to = startIndex, startIndex + slotNum - 1

        -- not enough widgets (fill from the first)
        if total <= slotNum then
            from = 1
            to = total

        -- have enough widgets, but result in empty slots, fix it
        elseif total - startIndex + 1 < slotNum then
            from = total - slotNum + 1 -- total > slotNum
            to = total
        end

        -- fill
        local slotIndex = 1
        for i, w in ipairs(scrollList.widgets) do
            w:ClearAllPoints()
            if i < from or i > to then
                w:Hide()
            else
                w:Show()
                w:SetAllPoints(slots[slotIndex])
                if w.Update then
                    -- NOTE: fix some widget issues, define them manually
                    w:Update()
                end
                slots[slotIndex].widget = w
                slots[slotIndex].widgetIndex = i
                slotIndex = slotIndex + 1
            end
        end

        -- reset empty slots
        for i = slotIndex, slotNum do
            slots[i].widget = nil
            slots[slotIndex].widgetIndex = nil
        end

        -- update scorll thumb
        if scrollList:CanScroll() then
            local offset = (from - 1) * ((scrollBar:GetHeight() - scrollThumb:GetHeight()) / scrollList:GetScrollRange()) -- n * perHeight
            scrollThumb:SetPoint("TOP", 0, -offset)
        end
    end

    -- get widget index on top (the first shown)
    function scrollList:GetScroll()
        return slots[1].widgetIndex, slots[1].widget
    end

    function scrollList:GetScrollRange()
        local range = scrollList.widgetNum - slotNum
        return range <= 0 and 0 or range
    end

    function scrollList:CanScroll()
        return scrollList.widgetNum > slotNum
    end

    -- for mouse wheel ----------------------------------------------
    local step = 1
    function scrollList:SetScrollStep(s)
        step = s
    end

    -- enable mouse wheel scroll
    scrollList:EnableMouseWheel(true)
    scrollList:SetScript("OnMouseWheel", function(self, delta)
        if delta == 1 then -- scroll up
            scrollList:SetScroll(scrollList:GetScroll() - step)
        elseif delta == -1 then -- scroll down
            scrollList:SetScroll(scrollList:GetScroll() + step)
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

    function scrollList:UpdatePixels()
        AW.ReSize(scrollList)
        AW.RePoint(scrollList)
        AW.ReBorder(scrollList)
        AW.RePoint(slotFrame)
        -- do it again, even if already invoked by AW.UpdatePixels
        AW.RePoint(scrollBar)
        for _, s in ipairs(slots) do
            s:UpdatePixels()
            if s.widget and s.widget.UpdatePixels then
                s.widget:UpdatePixels()
            end
        end
        scrollList:SetScroll(1)
    end

    AW.AddToPixelUpdater(scrollList)

    return scrollList
end

---------------------------------------------------------------------
-- mask (+30 frame level)
---------------------------------------------------------------------
--- @param tlX number topleft x
--- @param tlY number topleft y
--- @param brX number bottomright x
--- @param brY number bottomright y
function AW.ShowMask(parent, text, tlX, tlY, brX, brY)
    if not parent.mask then
        parent.mask = AW.CreateBorderedFrame(parent, nil, nil, nil, AW.GetColorTable("widget", 0.7), "none")
        AW.SetFrameLevel(parent.mask, 30, parent)
        parent.mask:EnableMouse(true)
        -- parent.mask:EnableMouseWheel(true) -- not enough
        parent.mask:SetScript("OnMouseWheel", function(self, delta)
            -- setting the OnMouseWheel script automatically implies EnableMouseWheel(true)
            -- print("OnMouseWheel", delta)
        end)

        parent.mask.text = AW.CreateFontString(parent.mask, "", "firebrick")
        AW.SetPoint(parent.mask.text, "LEFT", 5, 0)
        AW.SetPoint(parent.mask.text, "RIGHT", -5, 0)
    end

    parent.mask.text:SetText(text)

    AW.ClearPoints(parent.mask)
    -- if tlX then
        AW.SetPoint(parent.mask, "TOPLEFT", tlX, tlY)
        AW.SetPoint(parent.mask, "BOTTOMRIGHT", brX, brY)
    -- else
    --     AW.SetOnePixelInside(parent.mask, parent)
    -- end
    parent.mask:Show()

    return parent.mask
end

function AW.HideMask(parent)
    if parent.mask then
        parent.mask:Hide()
    end
end

---------------------------------------------------------------------
-- combat mask (+100 frame level)
---------------------------------------------------------------------
local function CreateCombatMask(parent, tlX, tlY, brX, brY)
    parent.combatMask = AW.CreateBorderedFrame(parent, nil, nil, nil, AW.GetColorTable("darkred", 0.8), "none")

    AW.SetFrameLevel(parent.combatMask, 100, parent)
    parent.combatMask:EnableMouse(true)
    parent.combatMask:SetScript("OnMouseWheel", function() end)

    parent.combatMask.text = AW.CreateFontString(parent.combatMask, "", "firebrick")
    AW.SetPoint(parent.combatMask.text, "LEFT", 5, 0)
    AW.SetPoint(parent.combatMask.text, "RIGHT", -5, 0)

    -- HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT
    -- ERR_AFFECTING_COMBAT
    -- ERR_NOT_IN_COMBAT
    parent.combatMask.text:SetText(_G.ERR_AFFECTING_COMBAT)

    AW.ClearPoints(parent.combatMask)
    if tlX then
        AW.SetPoint(parent.combatMask, "TOPLEFT", tlX, tlY)
        AW.SetPoint(parent.combatMask, "BOTTOMRIGHT", brX, brY)
    else
        AW.SetOnePixelInside(parent.combatMask, parent)
    end

    parent.combatMask:Hide()
end

-- show mask
local protectedFrames = {}
function AW.ApplyCombatProtectionToFrame(f, tlX, tlY, brX, brY)
    tinsert(protectedFrames, f)

    if not f.combatMask then
        CreateCombatMask(f, tlX, tlY, brX, brY)
    end

    if InCombatLockdown() then
        f.combatMask:Show()
    end

    f:HookScript("OnShow", function()
        if InCombatLockdown() then
            f.combatMask:Show()
        end
    end)
end

-- disable widget
local protectedWidgets = {}
function AW.ApplyCombatProtectionToWidget(widget)
    tinsert(protectedWidgets, widget)

    if InCombatLockdown() then
        widget:SetEnabled(false)
    end
end

local combatProtection = CreateFrame("Frame")
combatProtection:RegisterEvent("PLAYER_REGEN_DISABLED")
combatProtection:RegisterEvent("PLAYER_REGEN_ENABLED")
combatProtection:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        for _, f in pairs(protectedFrames) do
            f.combatMask:Show()
        end
        for _, w in pairs(protectedWidgets) do
            w:SetEnabled(false)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for _, f in pairs(protectedFrames) do
            f.combatMask:Hide()
        end
        for _, w in pairs(protectedWidgets) do
            w:SetEnabled(true)
        end
    end
end)