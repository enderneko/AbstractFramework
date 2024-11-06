---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- function
---------------------------------------------------------------------
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
-- style
---------------------------------------------------------------------
--- @param color string|table color name defined in Color.lua or color table
--- @param borderColor string|table color name defined in Color.lua or color table
function AF.StylizeFrame(frame, color, borderColor)
    color = color or "background"
    borderColor = borderColor or "border"

    AF.SetDefaultBackdrop(frame)
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
-- backdrop
---------------------------------------------------------------------
function AF.SetDefaultBackdrop(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    local n = AF.ConvertPixelsForRegion(borderSize or 1, frame)
    frame:SetBackdrop({bgFile=AF.GetPlainTexture(), edgeFile=AF.GetPlainTexture(), edgeSize=n, insets={left=n, right=n, top=n, bottom=n}})
end

function AF.SetDefaultBackdrop_NoBackground(frame, borderSize)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({edgeFile=AF.GetPlainTexture(), edgeSize=AF.ConvertPixelsForRegion(borderSize or 1, frame)})
end

function AF.SetDefaultBackdrop_NoBorder(frame)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({bgFile=AF.GetPlainTexture()})
end

function AF.ApplyDefaultBackdropColors(frame)
    frame:SetBackdropColor(AF.GetColorRGB("background"))
    frame:SetBackdropBorderColor(AF.GetColorRGB("border"))
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
function AF.CreateFrame(parent, name, width, height)
    local f = CreateFrame("Frame", name, parent)
    AF.SetSize(f, width, height)

    function f:UpdatePixels()
        AF.ReSize(f)
        AF.RePoint(f)
    end

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

function AF.CreateHeaderedFrame(parent, name, title, width, height, frameStrata, frameLevel, notUserPlaced)
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
    f:SetClampRectInsets(0, 0, AF.ConvertPixelsForRegion(20, f), 0)
    AF.SetSize(f, width, height)
    f:SetPoint("CENTER")
    AF.StylizeFrame(f)

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
    AF.StylizeFrame(header, "header")

    header.text = AF.CreateFontString(header, title, AF.GetAccentColorName(), "AF_FONT_TITLE")
    header.text:SetPoint("CENTER")

    function f:SetTitleJustify(justify)
        AF.ClearPoints(header.text)
        if justify == "LEFT" then
            AF.SetPoint(header.text, "LEFT", 7, 0)
        elseif justify == "RIGHT" then
            AF.SetPoint(header.text, "RIGHT", header.closeBtn, "LEFT", -7, 0)
        else
            AF.SetPoint(header.text, "CENTER")
        end
    end

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

    function f:UpdatePixels()
        f:SetClampRectInsets(0, 0, AF.ConvertPixelsForRegion(20, f), 0)
        AF.ReSize(f)
        AF.RePoint(f)
        AF.ReBorder(f)
        AF.ReSize(header)
        AF.RePoint(header)
        AF.ReBorder(header)
        AF.RePoint(header.tex)
        AF.RePoint(header.text)
        header.closeBtn:UpdatePixels()
    end

    AF.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- bordered frame
---------------------------------------------------------------------
--- @param color string|table color name / table
--- @param borderColor string|table color name / table
function AF.CreateBorderedFrame(parent, name, width, height, color, borderColor)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    AF.StylizeFrame(f, color, borderColor)
    AF.SetSize(f, width, height)

    function f:SetTitle(title, fontColor, font, isInside)
        if not f.title then
            f.title = AF.CreateFontString(f, title, fontColor or "accent", font)
            f.title:SetJustifyH("LEFT")
        else
            f.title:SetText(title)
        end

        AF.ClearPoints(f.title)
        if isInside then
            AF.SetPoint(f.title, "TOPLEFT", 2, -2)
        else
            AF.SetPoint(f.title, "BOTTOMLEFT", f, "TOPLEFT", 2, 2)
        end
    end

    function f:UpdatePixels()
        AF.ReSize(f)
        AF.RePoint(f)
        AF.ReBorder(f)
        if f.title then
            AF.RePoint(f.title)
        end
    end

    AF.AddToPixelUpdater(f)

    return f
end

---------------------------------------------------------------------
-- frame static glow
---------------------------------------------------------------------
--- @param color string
function AF.SetFrameStaticGlow(parent, size, color, alpha)
    if not parent.staticGlow then
        parent.staticGlow = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        -- parent.staticGlow:SetAllPoints()
        parent.staticGlow:SetScript("OnHide", function() parent.staticGlow:Hide() end)
    end

    size = size or 5
    color = color or "accent"

    parent.staticGlow:SetBackdrop({edgeFile=AF.GetIcon("StaticGlow"), edgeSize=AF.ConvertPixelsForRegion(size, parent)})
    AF.SetOutside(parent.staticGlow, parent, size)
    parent.staticGlow:SetBackdropBorderColor(AF.GetColorRGB(color, alpha))

    parent.staticGlow:Show()
end

---------------------------------------------------------------------
-- titled pane
---------------------------------------------------------------------
--- @param color string color name defined in Color.lua
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
function AF.CreateScrollFrame(parent, name, width, height, color, borderColor)
    local scrollParent = AF.CreateBorderedFrame(parent, name, width, height, color, borderColor)

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollParent, "BackdropTemplate")
    scrollParent.scrollFrame = scrollFrame
    AF.SetPoint(scrollFrame, "TOPLEFT")
    AF.SetPoint(scrollFrame, "BOTTOMRIGHT")

    -- content
    local content = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollParent.scrollContent = content
    AF.SetSize(content, width, 5)
    scrollFrame:SetScrollChild(content)
    -- AF.SetPoint(content, "RIGHT") -- update width with scrollFrame

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

    -- reset content height (reset scroll range)
    function scrollParent:ResetHeight()
        AF.SetHeight(content, 5)
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
            AF.SetListHeight(content, num, height, spacing, extraHeight)
        else
            AF.SetHeight(content, height)
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
            AF.SetPoint(scrollFrame, "BOTTOMRIGHT", -7, 0)
            scrollBar:Show()
        else
            AF.SetPoint(scrollFrame, "BOTTOMRIGHT")
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
                AF.SetPoint(scrollThumb, "TOP")
                newOffsetY = 0
            elseif (-newOffsetY) + scrollThumb:GetHeight() >= scrollBar:GetHeight() then -- bottom
                AF.SetPoint(scrollThumb, "TOP", 0, -(scrollBar:GetHeight() - scrollThumb:GetHeight()))
                newOffsetY = -(scrollBar:GetHeight() - scrollThumb:GetHeight())
            else
                AF.SetPoint(scrollThumb, "TOP", 0, newOffsetY)
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
            scrollParent:VerticalScroll(AF.ConvertPixelsForRegion(-step, scrollFrame))
        elseif delta == -1 then -- scroll down
            scrollParent:VerticalScroll(AF.ConvertPixelsForRegion(step, scrollFrame))
        end
    end)

    function scrollParent:UpdatePixels()
        -- scrollBar / scrollThumb / children already AddToPixelUpdater
        --! scrollParent's UpdatePixels is Overrided here
        AF.ReSize(scrollParent)
        AF.RePoint(scrollParent)
        AF.ReBorder(scrollParent)

        AF.RePoint(scrollFrame)
        AF.ReBorder(scrollFrame)

        AF.ReSize(content) -- SetListHeight
        content:SetWidth(scrollFrame:GetWidth())

        -- reset scroll
        scrollParent:ResetScroll()
    end

    AF.AddToPixelUpdater(scrollParent)

    return scrollParent
end

---------------------------------------------------------------------
-- scroll list (filled with widgets)
---------------------------------------------------------------------
--- @param verticalMargins number top/bottom margin
--- @param horizontalMargins number left/right margin
--- @param slotSpacing number spacing between widgets next to each other
function AF.CreateScrollList(parent, name, width, verticalMargins, horizontalMargins, slotNum, slotHeight, slotSpacing, color, borderColor)
    local scrollList = AF.CreateBorderedFrame(parent, name, width, nil, color, borderColor)
    AF.SetListHeight(scrollList, slotNum, slotHeight, slotSpacing, verticalMargins*2)
    scrollList.slotNum = slotNum

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
    AF.SetPoint(scrollThumb, "TOP")
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
    local slots = {}

    local function UpdateSlots()
        for i = 1, scrollList.slotNum do
            if not slots[i] then
                slots[i] = AF.CreateFrame(slotFrame)
                AF.SetHeight(slots[i], slotHeight)
                AF.SetPoint(slots[i], "RIGHT", -horizontalMargins, 0)
                if i == 1 then
                    AF.SetPoint(slots[i], "TOPLEFT", horizontalMargins, 0)
                else
                    AF.SetPoint(slots[i], "TOPLEFT", slots[i-1], "BOTTOMLEFT", 0, -slotSpacing)
                end
            end
            slots[i]:Show()
        end
        -- hide unused slots
        for i = scrollList.slotNum+1, #slots do
            slots[i]:Hide()
        end
    end
    UpdateSlots()

    -- NOTE: for dropdowns only
    function scrollList:SetSlotNum(newSlotNum)
        scrollList.slotNum = newSlotNum
        if scrollList.slotNum == 0 then
            AF.SetHeight(scrollList, 5)
        else
            AF.SetListHeight(scrollList, scrollList.slotNum, slotHeight, slotSpacing, verticalMargins*2)
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

        if scrollList.widgetNum > scrollList.slotNum then -- can scroll
            local p = scrollList.slotNum / scrollList.widgetNum
            scrollThumb:SetHeight(scrollBar:GetHeight()*p)
            AF.SetPoint(slotFrame, "BOTTOMRIGHT", -7, verticalMargins)
            scrollBar:Show()
        else
            AF.SetPoint(slotFrame, "BOTTOMRIGHT", 0, verticalMargins)
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
        AF.SetPoint(slotFrame, "BOTTOMRIGHT", 0, verticalMargins)
        scrollBar:Hide()
    end

    -- scroll: set start index of widgets
    function scrollList:SetScroll(startIndex)
        if not startIndex then return end
        -- assert(startIndex, "startIndex can not be nil!")

        if startIndex <= 0 then startIndex = 1 end
        local total = scrollList.widgetNum
        local from, to = startIndex, startIndex + scrollList.slotNum - 1

        -- not enough widgets (fill from the first)
        if total <= scrollList.slotNum then
            from = 1
            to = total

        -- have enough widgets, but result in empty slots, fix it
        elseif total - startIndex + 1 < scrollList.slotNum then
            from = total - scrollList.slotNum + 1 -- total > slotNum
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
        for i = slotIndex, scrollList.slotNum do
            slots[i].widget = nil
            slots[slotIndex].widgetIndex = nil
        end

        -- update scorll thumb
        if scrollList:CanScroll() then
            local offset = (from - 1) * ((scrollBar:GetHeight() - scrollThumb:GetHeight()) / scrollList:GetScrollRange()) -- n * perHeight
            scrollThumb:SetPoint("TOP", 0, -offset)
        end
    end

    function scrollList:ScrollToBottom()
        scrollList:SetScroll(total - scrollList.slotNum + 1)
    end

    -- get widget index on top (the first shown)
    function scrollList:GetScroll()
        if scrollList.widgetNum == 0 then return end
        return slots[1].widgetIndex, slots[1].widget
    end

    function scrollList:GetScrollRange()
        local range = scrollList.widgetNum - scrollList.slotNum
        return range <= 0 and 0 or range
    end

    function scrollList:CanScroll()
        return scrollList.widgetNum > scrollList.slotNum
    end

    -- for mouse wheel ----------------------------------------------
    local step = 1
    function scrollList:SetScrollStep(s)
        step = s
    end

    -- enable mouse wheel scroll
    scrollList:EnableMouseWheel(true)
    scrollList:SetScript("OnMouseWheel", function(self, delta)
        if scrollList.widgetNum == 0 then return end
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
        AF.ReSize(scrollList)
        AF.RePoint(scrollList)
        AF.ReBorder(scrollList)
        AF.RePoint(slotFrame)
        -- do it again, even if already invoked by AF.UpdatePixels
        AF.RePoint(scrollBar)
        for _, s in ipairs(slots) do
            s:UpdatePixels()
            if s.widget and s.widget.UpdatePixels then
                s.widget:UpdatePixels()
            end
        end
        scrollList:SetScroll(1)
    end

    AF.AddToPixelUpdater(scrollList)

    return scrollList
end

---------------------------------------------------------------------
-- mask (+30 frame level)
---------------------------------------------------------------------
--- @param tlX number topleft x
--- @param tlY number topleft y
--- @param brX number bottomright x
--- @param brY number bottomright y
function AF.ShowMask(parent, text, tlX, tlY, brX, brY)
    if not parent.mask then
        parent.mask = AF.CreateBorderedFrame(parent, nil, nil, nil, AF.GetColorTable("widget", 0.7), "none")
        AF.SetFrameLevel(parent.mask, 30, parent)
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
    -- if tlX then
        AF.SetPoint(parent.mask, "TOPLEFT", tlX, tlY)
        AF.SetPoint(parent.mask, "BOTTOMRIGHT", brX, brY)
    -- else
    --     AF.SetOnePixelInside(parent.mask, parent)
    -- end
    parent.mask:Show()

    return parent.mask
end

function AF.HideMask(parent)
    if parent.mask then
        parent.mask:Hide()
    end
end

---------------------------------------------------------------------
-- combat mask (+100 frame level)
---------------------------------------------------------------------
local function CreateCombatMask(parent, tlX, tlY, brX, brY)
    parent.combatMask = AF.CreateBorderedFrame(parent, nil, nil, nil, AF.GetColorTable("darkred", 0.8), "none")

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
    if tlX then
        AF.SetPoint(parent.combatMask, "TOPLEFT", tlX, tlY)
        AF.SetPoint(parent.combatMask, "BOTTOMRIGHT", brX, brY)
    else
        AF.SetOnePixelInside(parent.combatMask, parent)
    end

    parent.combatMask:Hide()
end

-- show mask
local protectedFrames = {}
function AF.ApplyCombatProtectionToFrame(f, tlX, tlY, brX, brY)
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
function AF.ApplyCombatProtectionToWidget(widget)
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