---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- texture
---------------------------------------------------------------------
--- @param color table|string
function AW.CreateTexture(parent, texture, color, drawLayer, subLevel, wrapModeHorizontal, wrapModeVertical, filterMode)
    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)

    function tex:SetColor(c)
        if type(c) == "string" then c = AW.GetColorTable(c) end
        c = c or {1, 1, 1, 1}
        if texture then
            tex:SetTexture(texture, wrapModeHorizontal, wrapModeVertical, filterMode)
            tex:SetVertexColor(unpack(c))
        else
            tex:SetColorTexture(unpack(c))
        end
    end

    tex:SetColor(color)

    -- function tex:UpdatePixels()
    --     AW.ReSize(tex)
    --     AW.RePoint(tex)
    -- end

    AW.AddToPixelUpdater(tex)

    return tex
end

---------------------------------------------------------------------
-- calc texcoord
---------------------------------------------------------------------
function AW.CalcTexCoordPreCrop(width, height, aspectRatio, crop)
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

function AW.CalcScale(baseOriginalWidth, baseOriginalHeight, baseNewWidth, baseNewHeight, crop)
    local effectiveBaseWidth = baseOriginalWidth * (1 - 2 * crop)
    local effectiveBaseHeight = baseOriginalHeight * (1 - 2 * crop)

    local wScale = baseNewWidth / effectiveBaseWidth
    local hScale = baseNewHeight / effectiveBaseHeight

    return math.max(wScale, hScale)
end

---------------------------------------------------------------------
-- gradient texture
---------------------------------------------------------------------
--- @param color1 table|string
--- @param color2 table|string
function AW.CreateGradientTexture(parent, orientation, color1, color2, texture, drawLayer, subLevel)
    texture = texture or AW.GetPlainTexture()
    if type(color1) == "string" then color1 = AW.GetColorTable(color1) end
    if type(color2) == "string" then color2 = AW.GetColorTable(color2) end
    color1 = color1 or {0, 0, 0, 0}
    color2 = color2 or {0, 0, 0, 0}

    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)
    tex:SetTexture(texture)
    tex:SetGradient(orientation, CreateColor(unpack(color1)), CreateColor(unpack(color2)))

    function tex:UpdatePixels()
        AW.ReSize(tex)
        AW.RePoint(tex)
    end

    AW.AddToPixelUpdater(tex)

    return tex
end

---------------------------------------------------------------------
-- line
---------------------------------------------------------------------
function AW.CreateSeparator(parent, width, height, color)
    if type(color) == "string" then color = AW.GetColorTable(color) end
    color = color or AW.GetColorTable("accent")

    local line = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    AW.SetSize(line, width, height)
    line:SetColorTexture(unpack(color))

    local shadow = parent:CreateTexture(nil, "ARTWORK", nil, -1)
    AW.SetSize(shadow, height)
    AW.SetPoint(shadow, "TOPLEFT", line, 1, -1)
    AW.SetPoint(shadow, "TOPRIGHT", line, 1, -1)
    shadow:SetColorTexture(AW.GetColorRGB("black", color[4])) -- use line alpha

    hooksecurefunc(line, "Show", function()
        shadow:Show()
    end)
    hooksecurefunc(line, "Hide", function()
        shadow:Hide()
    end)

    function line:UpdatePixels()
        AW.ReSize(line)
        AW.RePoint(line)
        AW.ReSize(shadow)
        AW.RePoint(shadow)
    end

    AW.AddToPixelUpdater(line)

    return line
end