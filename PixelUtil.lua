---@class AbstractWidgets
local AW = _G.AbstractWidgets

-- Interface\SharedXML\PixelUtil.lua
---------------------------------------------------------------------
-- pixel perfect
---------------------------------------------------------------------
function AW.GetPixelFactor()
    local physicalWidth, physicalHeight = GetPhysicalScreenSize()
    return 768.0 / physicalHeight
end

function AW.GetNearestPixelSize(uiUnitSize, layoutScale, minPixels)
    if uiUnitSize == 0 and (not minPixels or minPixels == 0) then
        return 0
    end

    local uiUnitFactor = AW.GetPixelFactor()
    local numPixels = Round((uiUnitSize * layoutScale) / uiUnitFactor)
    if minPixels then
        if uiUnitSize < 0.0 then
            if numPixels > -minPixels then
                numPixels = -minPixels
            end
        else
            if numPixels < minPixels then
                numPixels = minPixels
            end
        end
    end

    return numPixels * uiUnitFactor / layoutScale
end

-- function AW.ConvertPixels(desiredPixels, layoutScale)
--     return AW.GetNearestPixelSize(desiredPixels, layoutScale)
-- end

function AW.ConvertPixels(desiredPixels)
    return AW.GetNearestPixelSize(desiredPixels, AW.UIParent:GetEffectiveScale())
end

function AW.ConvertPixelsForRegion(desiredPixels, region)
    return AW.GetNearestPixelSize(desiredPixels, region:GetEffectiveScale())
end

---------------------------------------------------------------------
-- 1 pixel
---------------------------------------------------------------------
function AW.GetOnePixelForRegion(region)
    return AW.GetNearestPixelSize(1, region:GetEffectiveScale())
end

---------------------------------------------------------------------
-- size
---------------------------------------------------------------------
function AW.SetWidth(region, width, minPixels)
    -- clear conflicts
    region._size_grid = nil
    region._size_list_h = nil
    -- add new
    minPixels = minPixels or 0.001
    region._size_normal = true
    region._width = width
    region._minwidth = minPixels
    region:SetWidth(AW.GetNearestPixelSize(width, region:GetEffectiveScale(), minPixels))
end

function AW.SetHeight(region, height, minPixels)
    -- clear conflicts
    region._size_grid = nil
    region._size_list_v = nil
    -- add new
    minPixels = minPixels or 0.001
    region._size_normal = true
    region._height = height
    region._minheight = minPixels
    region:SetHeight(AW.GetNearestPixelSize(height, region:GetEffectiveScale(), minPixels))
end

-- NOTE: DO NOT USE WITH SetListHeight
function AW.SetListWidth(region, itemNum, itemWidth, itemSpacing, extraWidth)
    -- clear conflicts
    region._size_grid = nil
    region._size_list_v = nil
    region._width = nil
    region._minwidth = nil
    -- add new
    region._size_list_h = true
    region._itemNum = itemNum
    region._itemWidth = itemWidth
    region._itemSpacing = itemSpacing
    extraWidth = extraWidth or 0
    region._extraWidth = extraWidth

    if itemNum == 0 then
        region:SetWidth(0.001)
    else
        region:SetWidth(AW.GetNearestPixelSize(itemWidth, region:GetEffectiveScale())*itemNum
            + AW.GetNearestPixelSize(itemSpacing, region:GetEffectiveScale())*(itemNum-1)
            + AW.GetNearestPixelSize(extraWidth, region:GetEffectiveScale()))
    end
end

-- NOTE: DO NOT USE WITH SetListWidth
function AW.SetListHeight(region, itemNum, itemHeight, itemSpacing, extraHeight)
    -- clear conflicts
    region._size_grid = nil
    region._size_list_h = nil
    region._height = nil
    region._minheight = nil
    -- add new
    region._size_list_v = true
    region._itemNum = itemNum
    region._itemHeight = itemHeight
    region._itemSpacing = itemSpacing
    extraHeight = extraHeight or 0
    region._extraHeight = extraHeight

    if itemNum == 0 then
        region:SetHeight(0.001)
    else
        region:SetHeight(AW.GetNearestPixelSize(itemHeight, region:GetEffectiveScale())*itemNum
            + AW.GetNearestPixelSize(itemSpacing, region:GetEffectiveScale())*(itemNum-1)
            + AW.GetNearestPixelSize(extraHeight, region:GetEffectiveScale()))
    end
end

function AW.SetGridSize(region, gridWidth, gridHeight, gridSpacingH, gridSpacingV, columns, rows)
    -- clear conflicts
    region._size_list_h = nil
    region._size_list_v = nil
    region._size_normal = nil
    -- add new
    region._size_grid = true
    region._gridWidth = gridWidth
    region._gridHeight = gridHeight
    region._gridSpacingH = gridSpacingH
    region._gridSpacingV = gridSpacingV
    region._rows = rows
    region._columns = columns

    if columns == 0 then
        region:SetWidth(0.001)
    else
        region:SetWidth(AW.GetNearestPixelSize(gridWidth, region:GetEffectiveScale())*columns
            + AW.GetNearestPixelSize(gridSpacingH, region:GetEffectiveScale())*(columns-1))
    end

    if rows == 0 then
        region:SetHeight(0.001)
    else
        region:SetHeight(AW.GetNearestPixelSize(gridHeight, region:GetEffectiveScale())*rows
            + AW.GetNearestPixelSize(gridSpacingV, region:GetEffectiveScale())*(rows-1))
    end
end

function AW.SetSize(region, width, height)
    -- height = height or width
    if width then AW.SetWidth(region, width) end
    if height then AW.SetHeight(region, height) end
end

---------------------------------------------------------------------
-- point
---------------------------------------------------------------------
function AW.SetPoint(region, ...)
    if not region._points then region._points = {} end
    local point, relativeTo, relativePoint, offsetX, offsetY

    local n = select("#", ...)
    if n == 1 then
        point = ...
    elseif n == 3 then
        if type(select(2, ...)) == "number" then -- "TOPLEFT", 0, 0
            point, offsetX, offsetY = ...
        else -- "TOPLEFT", AW.UIParent, "TOPRIGHT"
            point, relativeTo, relativePoint = ...
        end
    elseif n == 4 then
        point, relativeTo, offsetX, offsetY = ...
    else
        point, relativeTo, relativePoint, offsetX, offsetY = ...
    end

    offsetX = offsetX and offsetX or 0
    offsetY = offsetY and offsetY or 0

    local points = {point, relativeTo or region:GetParent(), relativePoint or point, offsetX, offsetY}
    region._points[point] = points

    if region._useOriginalPoints then
        region:SetPoint(points[1], points[2], points[3], points[4], points[5])
    else
        region:SetPoint(points[1], points[2], points[3], AW.GetNearestPixelSize(points[4], region:GetEffectiveScale()), AW.GetNearestPixelSize(points[5], region:GetEffectiveScale()))
    end
end

function AW.SetOnePixelInside(region, relativeTo)
    AW.ClearPoints(region)
    AW.SetPoint(region, "TOPLEFT", relativeTo, "TOPLEFT", 1, -1)
    AW.SetPoint(region, "BOTTOMRIGHT", relativeTo, "BOTTOMRIGHT", -1, 1)
end

function AW.SetOnePixelOutside(region, relativeTo)
    AW.ClearPoints(region)
    AW.SetPoint(region, "TOPLEFT", relativeTo, "TOPLEFT", -1, 1)
    AW.SetPoint(region, "BOTTOMRIGHT", relativeTo, "BOTTOMRIGHT", 1, -1)
end

function AW.SetInside(region, relativeTo, size)
    AW.ClearPoints(region)
    AW.SetPoint(region, "TOPLEFT", relativeTo, "TOPLEFT", size, -size)
    AW.SetPoint(region, "BOTTOMRIGHT", relativeTo, "BOTTOMRIGHT", -size, size)
end

function AW.SetOutside(region, relativeTo, size)
    AW.ClearPoints(region)
    AW.SetPoint(region, "TOPLEFT", relativeTo, "TOPLEFT", -size, size)
    AW.SetPoint(region, "BOTTOMRIGHT", relativeTo, "BOTTOMRIGHT", size, -size)
end

function AW.ClearPoints(region)
    region:ClearAllPoints()
    if region._points then wipe(region._points) end
end

---------------------------------------------------------------------
-- backdrop
---------------------------------------------------------------------
function AW.SetBackdrop(region, backdropInfo)
    region._edge_size = backdropInfo.edgeSize
    backdropInfo.edgeSize = AW.ConvertPixelsForRegion(region._edge_size, region)

    if backdropInfo.insets then
        region._inset_size = next(backdropInfo.insets)
        for k in pairs(backdropInfo.insets) do
            backdropInfo.insets[k] = AW.ConvertPixelsForRegion(region._inset_size, region)
        end
    end

    region:SetBackdrop(backdropInfo)
end

---------------------------------------------------------------------
-- re-set
---------------------------------------------------------------------
function AW.ReSize(region)
    if region._size_normal then
        if region._width then
            AW.SetWidth(region, region._width, region._minwidth)
        end
        if region._height then
            AW.SetHeight(region, region._height, region._minheight)
        end

        if region._size_list_h then
            AW.SetListWidth(region, region._itemNum, region._itemWidth, region._itemSpacing, region._extraWidth)
        elseif region._size_list_v then
            AW.SetListHeight(region, region._itemNum, region._itemHeight, region._itemSpacing, region._extraHeight)
        end

    elseif region._size_grid then
        AW.SetGridSize(region, region._gridWidth, region._gridHeight, region._gridSpacingH, region._gridSpacingV, region._columns, region._rows)
    end
end

local function IsEmpty(t)
    if not t then return true end
    for _ in pairs(t) do
        return false
    end
    return true
end

function AW.RePoint(region)
    if IsEmpty(region._points) then return end
    region:ClearAllPoints()
    for _, t in pairs(region._points) do
        local x, y
        if region._useOriginalPoints then
            x = t[4]
            y = t[5]
        else
            x = AW.ConvertPixelsForRegion(t[4], region)
            y = AW.ConvertPixelsForRegion(t[5], region)
        end
        region:SetPoint(t[1], t[2], t[3], x, y)
    end
end

function AW.ReBorder(region)
    if not region.GetBackdrop then return end

    local backdropInfo = region:GetBackdrop()
    if not backdropInfo then return end

    local r, g, b, a = region:GetBackdropColor()
    local br, bg, bb, ba = region:GetBackdropBorderColor()

    local n = AW.GetOnePixelForRegion(region)
    if backdropInfo.edgeSize then
        if region._edge_size then
            backdropInfo.edgeSize = AW.ConvertPixelsForRegion(region._edge_size, region)
        else
            backdropInfo.edgeSize = n
        end
    end
    if backdropInfo.insets then
        if region._inset_size then
            n = AW.ConvertPixelsForRegion(region._inset_size, region)
        end
        backdropInfo.insets.left = n
        backdropInfo.insets.right = n
        backdropInfo.insets.top = n
        backdropInfo.insets.bottom = n
    end

    region:SetBackdrop(backdropInfo)
    region:SetBackdropColor(r, g, b, a)
    region:SetBackdropBorderColor(br, bg, bb, ba)
end

---------------------------------------------------------------------
-- pixel updater
---------------------------------------------------------------------
local function DefaultUpdatePixels(self)
    AW.ReSize(self)
    AW.RePoint(self)
    AW.ReBorder(self)
end
AW.DefaultUpdatePixels = DefaultUpdatePixels

local regions = {}
AW.regions = regions

--- @param fn function
function AW.AddToPixelUpdater(r, fn)
    r.UpdatePixels = fn or r.UpdatePixels or DefaultUpdatePixels
    regions[r] = r:GetName() or true
end

function AW.RemoveFromPixelUpdater(r)
    regions[r] = nil
end

function AW.UpdatePixels()
    for r in next, regions do
        r:UpdatePixels()
    end
end

---------------------------------------------------------------------
-- pixel perfect point
---------------------------------------------------------------------
function AW.PixelPerfectPoint(region)
    local left = Round(region:GetLeft())
    local bottom = Round(region:GetBottom())
    AW.ClearPoints(region)
    AW.SetPoint(region, "BOTTOMLEFT", left, bottom)
end

---------------------------------------------------------------------
-- update text container size
---------------------------------------------------------------------
function AW.SetSizeToFitText(frame, fontString, padding)
    padding = padding or 0
    local width = ceil(fontString:GetWidth() + padding)
    local height = ceil(fontString:GetHeight() + padding)
    frame:SetSize(width, height)
end

---------------------------------------------------------------------
-- statusbar
---------------------------------------------------------------------
function AW.SetStatusBarValue(statusBar, value)
    local width = statusBar:GetWidth()
    if width and width > 0.0 then
        local min, max = statusBar:GetMinMaxValues()
        local percent = ClampedPercentageBetween(value, min, max)
        if percent == 0.0 or percent == 1.0 then
            statusBar:SetValue(value)
        else
            local numPixels = AW.GetNearestPixelSize(statusBar:GetWidth() * percent, statusBar:GetEffectiveScale())
            local roundedValue = Lerp(min, max, numPixels / width)
            statusBar:SetValue(roundedValue)
        end
    else
        statusBar:SetValue(value)
    end
end

---------------------------------------------------------------------
-- load widget position
---------------------------------------------------------------------
function AW.LoadWidgetPosition(widget, pos, relativeTo)
    AW.ClearPoints(widget)
    AW.SetPoint(widget, pos[1], relativeTo or widget:GetParent(), pos[2], pos[3], pos[4])
end

---------------------------------------------------------------------
-- load text position
---------------------------------------------------------------------
function AW.LoadTextPosition(text, pos, relativeTo)
    if strfind(pos[1], "LEFT$") then
        text:SetJustifyH("LEFT")
    elseif strfind(pos[1], "RIGHT$") then
        text:SetJustifyH("RIGHT")
    else
        text:SetJustifyH("CENTER")
    end

    if strfind(pos[1], "^TOP") then
        text:SetJustifyV("TOP")
    elseif strfind(pos[1], "^BOTTOM") then
        text:SetJustifyV("BOTTOM")
    else
        text:SetJustifyV("MIDDLE")
    end

    -- NOTE: text positioning is a pain!
    text._useOriginalPoints = true
    AW.ClearPoints(text)
    AW.SetPoint(text, pos[1], relativeTo or text:GetParent(), pos[2], pos[3], pos[4])
end

---------------------------------------------------------------------
-- get anchor points
---------------------------------------------------------------------
function AW.GetAnchorPoints_Simple(anchor, orientation, spacingH, spacingV)
    local point, relativePoint, newLineRelativePoint -- normal
    local x, y, newLineX, newLineY -- normal
    local headerPoint

    spacingV = spacingV or spacingH

    if orientation == "left_to_right" then
        if strfind(anchor, "^BOTTOM") then
            point = "BOTTOMLEFT"
            relativePoint = "BOTTOMRIGHT"
            newLineRelativePoint = "TOPLEFT"
            y = 0
            newLineY = spacingV
        else
            point = "TOPLEFT"
            relativePoint = "TOPRIGHT"
            newLineRelativePoint = "BOTTOMLEFT"
            y = 0
            newLineY = -spacingV
        end
        x = spacingH
        newLineX = 0
        headerPoint = "LEFT"

    elseif orientation == "right_to_left" then
        if strfind(anchor, "^BOTTOM") then
            point = "BOTTOMRIGHT"
            relativePoint = "BOTTOMLEFT"
            newLineRelativePoint = "TOPRIGHT"
            y = 0
            newLineY = spacingV
        else
            point = "TOPRIGHT"
            relativePoint = "TOPLEFT"
            newLineRelativePoint = "BOTTOMRIGHT"
            y = 0
            newLineY = -spacingV
        end
        x = -spacingH
        newLineX = 0
        headerPoint = "RIGHT"

    elseif orientation == "top_to_bottom" then
        if strfind(anchor, "RIGHT$") then
            point = "TOPRIGHT"
            relativePoint = "BOTTOMRIGHT"
            newLineRelativePoint = "TOPLEFT"
            x = 0
            newLineX = -spacingH
        else
            point = "TOPLEFT"
            relativePoint = "BOTTOMLEFT"
            newLineRelativePoint = "TOPRIGHT"
            x = 0
            newLineX = spacingH
        end
        y = -spacingV
        newLineY = 0
        headerPoint = "TOP"

    elseif orientation == "bottom_to_top" then
        if strfind(anchor, "RIGHT$") then
            point = "BOTTOMRIGHT"
            relativePoint = "TOPRIGHT"
            newLineRelativePoint = "BOTTOMLEFT"
            x = 0
            newLineX = -spacingH
        else
            point = "BOTTOMLEFT"
            relativePoint = "TOPLEFT"
            newLineRelativePoint = "BOTTOMRIGHT"
            x = 0
            newLineX = spacingH
        end
        y = spacingV
        newLineY = 0
        headerPoint = "BOTTOM"
    end

    return point, relativePoint, newLineRelativePoint, x, y, newLineX, newLineY, headerPoint
end

function AW.GetAnchorPoints_Complex(orientation, spacingH, spacingV)
    local point, relativePoint, newLineRelativePoint
    local x, y, newLineX, newLineY

    if orientation == "bottom_to_top_then_left" then
        point = "BOTTOMRIGHT"
        relativePoint = "TOPRIGHT"
        newLineRelativePoint = "BOTTOMLEFT"
        x = 0
        y = spacingV
        newLineX = -spacingH
        newLineY = 0
    elseif orientation == "bottom_to_top_then_right" then
        point = "BOTTOMLEFT"
        relativePoint = "TOPLEFT"
        newLineRelativePoint = "BOTTOMRIGHT"
        x = 0
        y = spacingV
        newLineX = spacingH
        newLineY = 0
    elseif orientation == "top_to_bottom_then_left" then
        point = "TOPRIGHT"
        relativePoint = "BOTTOMRIGHT"
        newLineRelativePoint = "TOPLEFT"
        x = 0
        y = -spacingV
        newLineX = -spacingH
        newLineY = 0
    elseif orientation == "top_to_bottom_then_right" then
        point = "TOPLEFT"
        relativePoint = "BOTTOMLEFT"
        newLineRelativePoint = "TOPRIGHT"
        x = 0
        y = -spacingV
        newLineX = spacingH
        newLineY = 0
    elseif orientation == "left_to_right_then_bottom" then
        point = "TOPLEFT"
        relativePoint = "TOPRIGHT"
        newLineRelativePoint = "BOTTOMLEFT"
        x = spacingH
        y = 0
        newLineX = 0
        newLineY = -spacingV
    elseif orientation == "left_to_right_then_top" then
        point = "BOTTOMLEFT"
        relativePoint = "BOTTOMRIGHT"
        newLineRelativePoint = "TOPLEFT"
        x = spacingH
        y = 0
        newLineX = 0
        newLineY = spacingV
    elseif orientation == "right_to_left_then_bottom" then
        point = "TOPRIGHT"
        relativePoint = "TOPLEFT"
        newLineRelativePoint = "BOTTOMRIGHT"
        x = -spacingH
        y = 0
        newLineX = 0
        newLineY = -spacingV
    elseif orientation == "right_to_left_then_top" then
        point = "BOTTOMRIGHT"
        relativePoint = "BOTTOMLEFT"
        newLineRelativePoint = "TOPRIGHT"
        x = -spacingH
        y = 0
        newLineX = 0
        newLineY = spacingV
    end

    return point, relativePoint, newLineRelativePoint, x, y, newLineX, newLineY
end

function AW.GetAnchorPoints_GroupHeader(orientation, spacingH, spacingV)
    local point, relativePoint, x, y -- normal
    local headerPoint, columnAnchorPoint, columnSpacing -- SecureGroupHeader

    if orientation == "bottom_to_top_then_left" then
        point = "BOTTOMRIGHT"
        relativePoint = "TOPRIGHT"
        x = 0
        y = spacingV
        columnSpacing = -spacingH
        headerPoint = "BOTTOM"
        columnAnchorPoint = "RIGHT"
    elseif orientation == "bottom_to_top_then_right" then
        point = "BOTTOMLEFT"
        relativePoint = "TOPLEFT"
        x = 0
        y = spacingV
        columnSpacing = spacingH
        headerPoint = "BOTTOM"
        columnAnchorPoint = "LEFT"
    elseif orientation == "top_to_bottom_then_left" then
        point = "TOPRIGHT"
        relativePoint = "BOTTOMRIGHT"
        x = 0
        y = -spacingV
        columnSpacing = -spacingH
        headerPoint = "TOP"
        columnAnchorPoint = "RIGHT"
    elseif orientation == "top_to_bottom_then_right" then
        point = "TOPLEFT"
        relativePoint = "BOTTOMLEFT"
        x = 0
        y = -spacingV
        columnSpacing = spacingH
        headerPoint = "TOP"
        columnAnchorPoint = "LEFT"
    elseif orientation == "left_to_right_then_bottom" then
        point = "TOPLEFT"
        relativePoint = "TOPRIGHT"
        x = spacingH
        y = 0
        columnSpacing = -spacingV
        headerPoint = "LEFT"
        columnAnchorPoint = "TOP"
    elseif orientation == "left_to_right_then_top" then
        point = "BOTTOMLEFT"
        relativePoint = "BOTTOMRIGHT"
        x = spacingH
        y = 0
        columnSpacing = spacingV
        headerPoint = "LEFT"
        columnAnchorPoint = "BOTTOM"
    elseif orientation == "right_to_left_then_bottom" then
        point = "TOPRIGHT"
        relativePoint = "TOPLEFT"
        x = -spacingH
        y = 0
        columnSpacing = -spacingV
        headerPoint = "RIGHT"
        columnAnchorPoint = "TOP"
    elseif orientation == "right_to_left_then_top" then
        point = "BOTTOMRIGHT"
        relativePoint = "BOTTOMLEFT"
        x = -spacingH
        y = 0
        columnSpacing = spacingV
        headerPoint = "RIGHT"
        columnAnchorPoint = "BOTTOM"
    end
    return point, relativePoint, x, y, columnSpacing, headerPoint, columnAnchorPoint
end

---------------------------------------------------------------------
-- load position
---------------------------------------------------------------------
--- @param pos table
function AW.LoadPosition(region, pos)
    region._useOriginalPoints = true
    AW.ClearPoints(region)
    if type(pos) == "string" then
        pos = string.gsub(pos, " ", "")
        local point, x, y = strsplit(",", pos)
        x = tonumber(x)
        y = tonumber(y)
        AW.SetPoint(region, point, x, y)
    elseif type(pos) == "table" then
        AW.SetPoint(region, unpack(pos))
    end
end

---------------------------------------------------------------------
-- save position
---------------------------------------------------------------------
function AW.SavePositionAsTable(region, t)
    if t then
        wipe(t)
        t[1], t[2], t[3], t[4], t[5] = region:GetPoint()
    else
        return {region:GetPoint()}
    end
end

-- function AW.SavePositionAsString(region, t, i)
--     t[i] = table.concat({region:GetPoint()}, ",")
-- end

---------------------------------------------------------------------
-- pixel perfect (ElvUI)
---------------------------------------------------------------------
local function CheckPixelSnap(frame, snap)
    if (frame and not frame:IsForbidden()) and frame.PixelSnapDisabled and snap then
        frame.PixelSnapDisabled = nil
    end
end

local function DisablePixelSnap(frame)
    if (frame and not frame:IsForbidden()) and not frame.PixelSnapDisabled then
        if frame.SetSnapToPixelGrid then
            frame:SetSnapToPixelGrid(false)
            frame:SetTexelSnappingBias(0)
            frame.PixelSnapDisabled = true
        elseif frame.GetStatusBarTexture then
            local texture = frame:GetStatusBarTexture()
            if type(texture) == "table" and texture.SetSnapToPixelGrid then
                texture:SetSnapToPixelGrid(false)
                texture:SetTexelSnappingBias(0)
                frame.PixelSnapDisabled = true
            end
        end
    end
end

local function UpdateMetatable(obj)
    local t = getmetatable(obj).__index

    if not obj.DisabledPixelSnap and (t.SetSnapToPixelGrid or t.SetStatusBarTexture or t.SetColorTexture or t.SetVertexColor or t.CreateTexture or t.SetTexCoord or t.SetTexture) then
        if t.SetSnapToPixelGrid then hooksecurefunc(t, "SetSnapToPixelGrid", CheckPixelSnap) end
        if t.SetStatusBarTexture then hooksecurefunc(t, "SetStatusBarTexture", DisablePixelSnap) end
        if t.SetColorTexture then hooksecurefunc(t, "SetColorTexture", DisablePixelSnap) end
        if t.SetVertexColor then hooksecurefunc(t, "SetVertexColor", DisablePixelSnap) end
        if t.CreateTexture then hooksecurefunc(t, "CreateTexture", DisablePixelSnap) end
        if t.SetTexCoord then hooksecurefunc(t, "SetTexCoord", DisablePixelSnap) end
        if t.SetTexture then hooksecurefunc(t, "SetTexture", DisablePixelSnap) end

        t.DisabledPixelSnap = true
    end
end

local obj = CreateFrame("Frame")
UpdateMetatable(CreateFrame("StatusBar"))
UpdateMetatable(obj:CreateTexture())
UpdateMetatable(obj:CreateMaskTexture())

local handled = {Frame = true}
obj = EnumerateFrames()
while obj do
    local objType = obj:GetObjectType()
    if not obj:IsForbidden() and not handled[objType] then
        UpdateMetatable(obj)
        handled[objType] = true
    end
    obj = EnumerateFrames(obj)
end