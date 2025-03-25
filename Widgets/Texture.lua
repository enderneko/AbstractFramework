---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- texture
---------------------------------------------------------------------
---@class AF_Texture:Texture
local AF_TextureMixin = {}

function AF_TextureMixin:SetColor(color)
    if type(color) == "string" then color = AF.GetColorTable(color) end
    color = color or {1, 1, 1, 1}
    if self._hasTexture then
        self:SetVertexColor(unpack(color))
    else
        self:SetColorTexture(unpack(color))
    end
end

---@param color table|string
---@return AF_TextureMixin tex
function AF.CreateTexture(parent, texture, color, drawLayer, subLevel, wrapModeHorizontal, wrapModeVertical, filterMode)
    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)
    Mixin(tex, AF_TextureMixin)

    if texture then
        tex._hasTexture = true
        tex:SetTexture(texture, wrapModeHorizontal, wrapModeVertical, filterMode)
    end

    tex:SetColor(color)

    AF.AddToPixelUpdater(tex)

    return tex
end

---------------------------------------------------------------------
-- calc texcoord
---------------------------------------------------------------------
function AF.CalcTexCoordPreCrop(width, height, aspectRatio, crop)
    -- apply cropping to initial texCoord
    local texCoord = {
        crop, crop,          -- ULx, ULy
        crop, 1 - crop,      -- LLx, LLy
        1 - crop, crop,      -- URx, URy
        1 - crop, 1 - crop   -- LRx, LRy
    }

    local newAspectRatio = width / height
    newAspectRatio = newAspectRatio / aspectRatio

    local xRatio = newAspectRatio < 1 and newAspectRatio or 1
    local yRatio = newAspectRatio > 1 and 1 / newAspectRatio or 1

    for i, coord in ipairs(texCoord) do
        local ratio = (i % 2 == 1) and xRatio or yRatio
        texCoord[i] = (coord - 0.5) * ratio + 0.5
    end

    return texCoord
end

function AF.CalcScale(baseOriginalWidth, baseOriginalHeight, baseNewWidth, baseNewHeight, crop)
    local effectiveBaseWidth = baseOriginalWidth * (1 - 2 * crop)
    local effectiveBaseHeight = baseOriginalHeight * (1 - 2 * crop)

    local wScale = baseNewWidth / effectiveBaseWidth
    local hScale = baseNewHeight / effectiveBaseHeight

    return math.max(wScale, hScale)
end

---------------------------------------------------------------------
-- gradient texture
---------------------------------------------------------------------
---@param color1 table|string
---@param color2 table|string
---@return Texture tex
function AF.CreateGradientTexture(parent, orientation, color1, color2, texture, drawLayer, subLevel)
    texture = texture or AF.GetPlainTexture()
    if type(color1) == "string" then color1 = AF.GetColorTable(color1) end
    if type(color2) == "string" then color2 = AF.GetColorTable(color2) end
    color1 = color1 or {0, 0, 0, 0}
    color2 = color2 or {0, 0, 0, 0}

    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)
    tex:SetTexture(texture)
    tex:SetGradient(orientation, CreateColor(unpack(color1)), CreateColor(unpack(color2)))

    AF.AddToPixelUpdater(tex)

    return tex
end

---------------------------------------------------------------------
-- line
---------------------------------------------------------------------
local function Separator_UpdatePixels(self)
    AF.ReSize(self)
    AF.RePoint(self)
    if self.shadow then
        AF.ReSize(self.shadow)
        AF.RePoint(self.shadow)
    end
end

---@param color table|string
---@return Texture separator
function AF.CreateSeparator(parent, size, thickness, color, isVertical, noShadow)
    if type(color) == "string" then color = AF.GetColorTable(color) end
    color = color or AF.GetColorTable("accent")

    local separator = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    separator:SetColorTexture(unpack(color))
    if isVertical then
        AF.SetSize(separator, thickness, size)
    else
        AF.SetSize(separator, size, thickness)
    end

    if not noShadow then
        local shadow = parent:CreateTexture(nil, "ARTWORK", nil, -1)
        separator.shadow = shadow
        shadow:SetColorTexture(AF.GetColorRGB("black", color[4])) -- use line alpha
        if isVertical then
            AF.SetSize(shadow, thickness, size)
            AF.SetPoint(shadow, "TOPLEFT", separator, "TOPRIGHT", 0, -thickness)
        else
            AF.SetSize(shadow, size, thickness)
            AF.SetPoint(shadow, "TOPLEFT", separator, "BOTTOMLEFT", thickness, 0)
        end

        hooksecurefunc(separator, "Show", function()
            shadow:Show()
        end)
        hooksecurefunc(separator, "Hide", function()
            shadow:Hide()
        end)
    end

    AF.AddToPixelUpdater(separator, Separator_UpdatePixels)

    return separator
end