---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- font string
---------------------------------------------------------------------
--- @param color string color name defined in Color.lua
--- @param font string color name defined in Font.lua
function AF.CreateFontString(parent, text, color, font, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", font or "AF_FONT_NORMAL")
    if color then AF.ColorFontString(fs, color) end
    fs:SetText(text)

    function fs:SetColor(color)
        AF.ColorFontString(fs, color)
    end

    -- function fs:UpdatePixels()
    --     AF.RePoint(fs)
    -- end

    AF.AddToPixelUpdater(fs)

    return fs
end

---------------------------------------------------------------------
-- notification text
---------------------------------------------------------------------
local pool

local function creationFunc()
    -- NOTE: do not use AF.CreateFontString, since we don't need UpdatePixels() for it
    local fs = UIParent:CreateFontString(nil, "OVERLAY", "AF_FONT_NORMAL")
    fs:Hide()

    fs:SetWordWrap(true) -- multiline allowed

    local ag = fs:CreateAnimationGroup()

    -- in ---------------------------------------
    local in_a = ag:CreateAnimation("Alpha")
    in_a:SetOrder(1)
    in_a:SetFromAlpha(0)
    in_a:SetToAlpha(1)
    in_a:SetDuration(0.25)

    -- out -------------------------------------
    local out_a = ag:CreateAnimation("Alpha")
    out_a:SetOrder(2)
    out_a:SetFromAlpha(1)
    out_a:SetToAlpha(0)
    out_a:SetStartDelay(2)
    out_a:SetDuration(0.25)

    function fs:ShowUp(parent, hideDelay)
        parent._notificationString = fs
        out_a:SetStartDelay(hideDelay or 2)
        fs:Show()
        ag:Play()
        ag:SetScript("OnFinished", function()
            parent._notificationString = nil
            pool:Release(fs)
        end)
    end

    function fs:HideOut(parent)
        parent._notificationString = nil
        pool:Release(fs)
        ag:Stop()
    end

    return fs
end

local function resetterFunc(_, f)
    f:Hide()
end

pool = CreateObjectPool(creationFunc, resetterFunc)

function AF.ShowNotificationText(text, color, width, hideDelay, point, relativeTo, relativePoint, offsetX, offsetY)
    assert(relativeTo, "parent can not be nil!")
    if relativeTo._notificationString then
        relativeTo._notificationString:HideOut(relativeTo)
    end

    local fs = pool:Acquire()
    fs:SetParent(relativeTo) --! IMPORTANT, if parent is nil, then game will crash (The memory could not be "read")
    fs:SetText(text)
    AF.ColorFontString(fs, color or "red")
    if width then fs:SetWidth(width) end

    -- alignment
    if strfind(point, "LEFT$") then
        fs:SetJustifyH("LEFT")
    elseif strfind(point, "RIGHT$") then
        fs:SetJustifyH("RIGHT")
    else
        fs:SetJustifyH("CENTER")
    end

    fs:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    fs:ShowUp(relativeTo, hideDelay)
end

---------------------------------------------------------------------
-- scroll text
---------------------------------------------------------------------
function AF.CreateScrollText(parent, frequency, step, startDelay, endDelay)
    -- vars -------------------------------------
    frequency = frequency or 0.02
    step = step or 1
    startDelay = startDelay or 2
    endDelay = endDelay or 2
    local scroll, scrollRange = 0, 0
    local sTime, eTime, elapsedTime = 0, 0, 0
    ---------------------------------------------

    local holder = CreateFrame("ScrollFrame", nil, parent)
    AF.SetHeight(holder, 20)

    local content = CreateFrame("Frame", nil, holder)
    content:SetSize(20, 20)
    holder:SetScrollChild(content)

    local text = AF.CreateFontString(content)
    text:SetWordWrap(false)
    text:SetPoint("LEFT")

    -- fade in ----------------------------------
    local fadeIn = text:CreateAnimationGroup()
    fadeIn._in = fadeIn:CreateAnimation("Alpha")
    fadeIn._in:SetFromAlpha(0)
    fadeIn._in:SetToAlpha(1)
    fadeIn._in:SetDuration(0.5)
    ---------------------------------------------

    -- fade out then in -------------------------
    local fadeOutIn = text:CreateAnimationGroup()

    fadeOutIn._out = fadeOutIn:CreateAnimation("Alpha")
    fadeOutIn._out:SetFromAlpha(1)
    fadeOutIn._out:SetToAlpha(0)
    fadeOutIn._out:SetDuration(0.5)
    fadeOutIn._out:SetOrder(1)

    fadeOutIn._in = fadeOutIn:CreateAnimation("Alpha")
    fadeOutIn._in:SetStartDelay(0.1) -- time for SetHorizontalScroll(0)
    fadeOutIn._in:SetFromAlpha(0)
    fadeOutIn._in:SetToAlpha(1)
    fadeOutIn._in:SetDuration(0.5)
    fadeOutIn._in:SetOrder(2)

    fadeOutIn._out:SetScript("OnFinished", function()
        holder:SetHorizontalScroll(0)
        scroll = 0
    end)

    fadeOutIn:SetScript("OnFinished", function()
        sTime, eTime, elapsedTime = 0, 0, 0
    end)
    ---------------------------------------------

    -- init holder
    holder:SetScript("OnShow", function()
        fadeIn:Play()
        holder:SetHorizontalScroll(0)
        scroll = 0
        sTime, eTime, elapsedTime = 0, 0, 0

        holder:SetScript("OnUpdate", function()
            -- NOTE: holder:GetWidth() is valid on next OnUpdate
            if holder:GetWidth() ~= 0 then
                holder:SetScript("OnUpdate", nil)

                if text:GetStringWidth() <= holder:GetWidth() then
                    holder:SetScript("OnUpdate", nil)
                else
                    scrollRange = text:GetStringWidth() - holder:GetWidth()
                    -- NOTE: FPS significantly affects OnUpdate frequency
                    -- 60FPS  -> 0.0166667 (1/60)
                    -- 90FPS  -> 0.0111111 (1/90)
                    -- 120FPS -> 0.0083333 (1/120)
                    holder:SetScript("OnUpdate", function(self, elapsed)
                        sTime = sTime + elapsed
                        if eTime >= endDelay then
                            fadeOutIn:Play()
                        elseif sTime >= startDelay then
                            if scroll >= scrollRange then -- scroll at max
                                eTime = eTime + elapsed
                            else
                                elapsedTime = elapsedTime + elapsed
                                if elapsedTime >= frequency then -- scroll
                                    elapsedTime = 0
                                    scroll = scroll + step
                                    holder:SetHorizontalScroll(scroll)
                                end
                            end
                        end
                    end)
                end
            end
        end)
    end)

    function holder:SetText(str, color)
        text:SetText(color and AF.WrapTextInColor(str, color) or str)
        if holder:IsVisible() then
            holder:GetScript("OnShow")()
        end
    end

    function holder:UpdatePixels()
        AF.ReSize(holder)
        AF.RePoint(holder)
        if holder:IsVisible() then
            holder:GetScript("OnShow")()
        end
    end

    AF.AddToPixelUpdater(holder)

    return holder
end

---------------------------------------------------------------------
-- SetText with length
---------------------------------------------------------------------
--- @param fs FontString
function AF.SetText(fs, text, length, suffix)
    if length > 0 then
        if length <= 1 then
            local width = fs:GetParent():GetWidth() - 2
            for i = string.utf8len(text), 0, -1 do
                fs:SetText(string.utf8sub(text, 1, i))
                if fs:GetWidth() / width <= length then
                    break
                end
            end
        else
            fs:SetText(string.utf8sub(text, 1, length))
        end
    else
        fs:SetText(text)
    end

    if suffix then
        fs:SetText(fs:GetText() .. suffix)
    end
end