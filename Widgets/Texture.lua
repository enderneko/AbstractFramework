---@class AbstractFramework
local AF = _G.AbstractFramework

local GetAtlasExists = C_Texture.GetAtlasExists or AF.noop_true
function AF.IsAtlas(atlas)
    return type(atlas) == "string" and not atlas:find("[/\\.]") and GetAtlasExists(atlas)
end

---------------------------------------------------------------------
-- texture
---------------------------------------------------------------------
---@class AF_Texture:Texture
local AF_TextureMixin = {}

---@param color table|string
function AF_TextureMixin:SetColor(color)
    if type(color) == "string" then color = AF.GetColorTable(color) end
    color = color or {1, 1, 1, 1}
    if self:HasTexture() then
        self:SetVertexColor(AF.UnpackColor(color))
    else
        self:SetColorTexture(AF.UnpackColor(color))
    end
end

---@param texture string|number texture path/fileID or atlas
-- - For path/fileID, "..." are wrapModeHorizontal, wrapModeVertical, filterMode
-- - For atlas, "..." are useAtlasSize, filterMode, resetTexCoords
function AF_TextureMixin:SetTextureOrAtlas(texture, ...)
    if AF.IsAtlas(texture) then
        self:SetAtlas(texture, ...)
    else
        self:SetTexture(texture, ...)
    end
end

---@return boolean hasTexture
---@return string|nil texType "texture"|"atlas"
---@return string|number|nil tex texture path/fileID or atlas
function AF_TextureMixin:HasTexture()
    return self._tex ~= nil, self._texType, self._tex
end

local function SetTexture(tex, value)
    tex._texType = value and "texture" or nil
    tex._tex = value
end

local function SetAtlas(tex, value)
    tex._texType = value and "atlas" or nil
    tex._tex = value
end

---@param parent Frame
---@param texture? string
---@param color? table|string
---@param drawLayer? string default "ARTWORK"
---@param subLevel? number
---@param wrapModeHorizontal? string
---@param wrapModeVertical? string
---@param filterMode? string
---@return AF_Texture tex
function AF.CreateTexture(parent, texture, color, drawLayer, subLevel, wrapModeHorizontal, wrapModeVertical, filterMode)
    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)
    Mixin(tex, AF_TextureMixin)

    hooksecurefunc(tex, "SetTexture", SetTexture)
    hooksecurefunc(tex, "SetAtlas", SetAtlas)

    if texture and texture ~= "" then
        if AF.IsAtlas(texture) then
            tex:SetAtlas(texture, nil, filterMode)
        else
            tex:SetTexture(texture, wrapModeHorizontal, wrapModeVertical, filterMode)
        end
    end

    if color then
        tex:SetColor(color)
    end

    AF.AddToPixelUpdater_OnShow(tex)

    return tex
end

---------------------------------------------------------------------
-- default texcoord for blizzard icons
---------------------------------------------------------------------
---@return number left 0.08
---@return number right 0.92
---@return number top 0.08
---@return number bottom 0.92
function AF.GetDefaultTexCoord()
    return 0.08, 0.92, 0.08, 0.92
end

--- 0.08, 0.92, 0.08, 0.92
---@param tex Texture
function AF.ApplyDefaultTexCoord(tex)
    tex:SetTexCoord(AF.GetDefaultTexCoord())
end

---@param tex Texture
function AF.ClearTexCoord(tex)
    tex:SetTexCoord(0, 1, 0, 1)
end

---------------------------------------------------------------------
-- calc texcoord
---------------------------------------------------------------------
---calculates texture coordinates with adjustments for aspect ratio and cropping
---@param crop number|nil cropping percentage
---@param targetAspectRatio number|nil target aspect ratio (targetWidth / targetHeight), defaults to 1
---@param originalAspectRatio number|nil original texture aspect ratio (width/height), defaults to 1
---@param anchor FramePoint|nil defaults to "CENTER"
---@param unpack boolean|nil if true, returns 8 separate values instead of a table
---@return table coordinates {ULx, ULy, LLx, LLy, URx, URy, LRx, LRy}
function AF.CalcTexCoordPreCrop(crop, targetAspectRatio, originalAspectRatio, anchor, unpack)
    crop = crop or 0
    anchor = anchor and anchor:upper() or "CENTER"

    -- apply cropping to initial texCoord
    local texCoord = {
        crop, crop,          -- ULx, ULy
        crop, 1 - crop,      -- LLx, LLy
        1 - crop, crop,      -- URx, URy
        1 - crop, 1 - crop   -- LRx, LRy
    }

    targetAspectRatio = targetAspectRatio or 1
    if originalAspectRatio then
        targetAspectRatio = targetAspectRatio / originalAspectRatio
    else
        -- in most cases, the original aspect ratio is 1
    end

    local xRatio = targetAspectRatio < 1 and targetAspectRatio or 1
    local yRatio = targetAspectRatio > 1 and 1 / targetAspectRatio or 1

    local anchorX, anchorY
    if anchor == "CENTER" then
        anchorX, anchorY = 0.5, 0.5
    elseif anchor == "TOPLEFT" then
        anchorX, anchorY = crop, crop
    elseif anchor == "TOP" then
        anchorX, anchorY = 0.5, crop
    elseif anchor == "TOPRIGHT" then
        anchorX, anchorY = 1 - crop, crop
    elseif anchor == "LEFT" then
        anchorX, anchorY = crop, 0.5
    elseif anchor == "RIGHT" then
        anchorX, anchorY = 1 - crop, 0.5
    elseif anchor == "BOTTOMLEFT" then
        anchorX, anchorY = crop, 1 - crop
    elseif anchor == "BOTTOM" then
        anchorX, anchorY = 0.5, 1 - crop
    elseif anchor == "BOTTOMRIGHT" then
        anchorX, anchorY = 1 - crop, 1 - crop
    end

    for i, coord in next, texCoord do
        local ratio = (i % 2 == 1) and xRatio or yRatio
        local anchorPoint = (i % 2 == 1) and anchorX or anchorY
        texCoord[i] = (coord - anchorPoint) * ratio + anchorPoint
    end

    if unpack then
        return AF.Unpack8(texCoord)
    else
        return texCoord
    end
end

---ccalculates scaling factor to fit a texture to target size while preserving aspect ratio
---@param originalWidth number
---@param originalHeight number
---@param targetWidth number
---@param targetHeight number
---@param crop number crop amount (0-0.5) from each edge
---@return number scale that ensures texture fills at least one dimension
function AF.CalcScale(originalWidth, originalHeight, targetWidth, targetHeight, crop)
    local effectiveWidth = originalWidth * (1 - 2 * crop)
    local effectiveHeight = originalHeight * (1 - 2 * crop)

    local wScale = targetWidth / effectiveWidth
    local hScale = targetHeight / effectiveHeight

    return math.max(wScale, hScale)
end

---------------------------------------------------------------------
-- gradient texture
---------------------------------------------------------------------
---@class AF_GradientTexture:Texture
local AF_GradientTextureMixin = {}

---@param orientation "HORIZONTAL"|"VERTICAL"
---@param color1 string|table|nil
---@param color2 string|table|nil
function AF_GradientTextureMixin:SetColor(orientation, color1, color2)
    if type(color1) == "string" then color1 = AF.GetColorTable(color1) end
    if type(color2) == "string" then color2 = AF.GetColorTable(color2) end
    color1 = color1 or {0, 0, 0, 0}
    color2 = color2 or {0, 0, 0, 0}
    self:SetGradient(orientation:upper(), CreateColor(AF.UnpackColor(color1)), CreateColor(AF.UnpackColor(color2)))
end

---@param orientation "HORIZONTAL"|"VERTICAL"
---@param color1 table|string
---@param color2 table|string
---@return AF_GradientTexture tex
function AF.CreateGradientTexture(parent, orientation, color1, color2, texture, drawLayer, subLevel, filterMode)
    texture = texture or AF.GetPlainTexture()

    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)
    Mixin(tex, AF_GradientTextureMixin)

    tex:SetTexture(texture, nil, nil, filterMode)
    tex:SetColor(orientation, color1, color2)

    AF.AddToPixelUpdater_OnShow(tex)

    return tex
end

---------------------------------------------------------------------
-- separator
---------------------------------------------------------------------
---@class AF_Separator:Texture
local AF_SeparatorMixin = {}

---@param color1 table|string
---@param color2 table|string|nil if provided, creates a gradient instead of solid
function AF_SeparatorMixin:SetColor(color1, color2)
    if type(color1) == "string" then color1 = AF.GetColorTable(color1) end
    color1 = color1 or AF.GetAddonAccentColorTable()

    if type(color2) == "string" then color2 = AF.GetColorTable(color2) end

    if color2 then
        self:SetTexture(AF.GetPlainTexture())
        self:SetGradient(self.isVertical and "VERTICAL" or "HORIZONTAL", CreateColor(AF.UnpackColor(color1)), CreateColor(AF.UnpackColor(color2)))
    else
        self:SetColorTexture(AF.UnpackColor(color1))
    end

    if self.shadow then
        if color2 then
            self.shadow:SetTexture(AF.GetPlainTexture())
            self.shadow:SetGradient(self.isVertical and "VERTICAL" or "HORIZONTAL", CreateColor(AF.GetColorRGB("border", color1[4])), CreateColor(AF.GetColorRGB("border", color2[4])))
        else
            self.shadow:SetColorTexture(AF.GetColorRGB("border", color1[4]))
        end
    end
end

local function Separator_UpdatePixels(self)
    AF.ReSize(self)
    AF.RePoint(self)
    if self.shadow then
        AF.ReSize(self.shadow)
        AF.RePoint(self.shadow)
    end
end

---@param parent Frame
---@param size number|nil
---@param thickness number
---@param color1 table|string
---@param color2 table|string|nil if provided, creates a gradient instead of solid
---@param isVertical boolean|nil
---@param noShadow boolean|nil
---@return AF_Separator separator
function AF.CreateSeparator(parent, size, thickness, color1, color2, isVertical, noShadow)
    local separator = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    Mixin(separator, AF_SeparatorMixin)

    separator.isVertical = isVertical or false
    if isVertical then
        AF.SetSize(separator, thickness, size)
    else
        AF.SetSize(separator, size, thickness)
    end

    if not noShadow then
        local shadow = parent:CreateTexture(nil, "ARTWORK", nil, -1)
        separator.shadow = shadow
        if isVertical then
            AF.SetWidth(shadow, thickness)
            AF.SetPoint(shadow, "TOPLEFT", separator, "TOPRIGHT", 0, -thickness)
            AF.SetPoint(shadow, "BOTTOMLEFT", separator, "BOTTOMRIGHT", 0, -thickness)
        else
            AF.SetHeight(shadow, thickness)
            AF.SetPoint(shadow, "TOPLEFT", separator, "BOTTOMLEFT", thickness, 0)
            AF.SetPoint(shadow, "TOPRIGHT", separator, "BOTTOMRIGHT", thickness, 0)
        end

        hooksecurefunc(separator, "Show", function()
            shadow:Show()
        end)
        hooksecurefunc(separator, "Hide", function()
            shadow:Hide()
        end)
        hooksecurefunc(separator, "SetShown", function(_, shown)
            shadow:SetShown(shown)
        end)
    end

    separator:SetColor(color1, color2)

    AF.AddToPixelUpdater_OnShow(separator, nil, Separator_UpdatePixels)

    return separator
end

---------------------------------------------------------------------
-- icon with background
---------------------------------------------------------------------
---@class AF_Icon:Frame,AF_BaseWidgetMixin
local AF_IconMixin = {}

---@param color string|table
function AF_IconMixin:SetBackgroundColor(color)
    color = color or "border"
    if type(color) == "string" then color = AF.GetColorTable(color) end
    self.bg:SetColorTexture(AF.UnpackColor(color))
end

---@param icon string texture path or atlas
---@param isAtlas boolean
function AF_IconMixin:SetIcon(icon, isAtlas)
    if isAtlas then
        self.icon:SetAtlas(icon)
    else
        self.icon:SetTexture(icon)
    end
end

function AF_IconMixin:SetIconTexCoord(left, right, top, bottom)
    self.icon:SetTexCoord(left, right, top, bottom)
end

function AF_IconMixin:UpdatePixels()
    AF.ReSize(self)
    AF.RePoint(self)
    AF.RePoint(self.icon)
end

---@param parent Frame
---@param icon string|nil texture path or atlas
---@param size number|nil default is 16
---@param bgColor string|table|nil background color, defaults to "border"
---@return AF_Icon
function AF.CreateIcon(parent, icon, size, bgColor)
    local frame = CreateFrame("Frame", nil, parent)
    AF.SetSize(frame, size or 16, size or 16)

    Mixin(frame, AF_IconMixin)
    Mixin(frame, AF_BaseWidgetMixin)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    AF.ApplyDefaultTexCoord(frame.icon)
    AF.SetOnePixelInside(frame.icon, frame)
    frame:SetIcon(icon or AF.GetIcon("QuestionMark"), (icon and not icon:find("[/\\]") and true or false))

    frame.bg = frame:CreateTexture(nil, "BORDER")
    frame.bg:SetAllPoints(frame)
    frame:SetBackgroundColor(bgColor)

    AF.AddToPixelUpdater_OnShow(frame)

    return frame
end