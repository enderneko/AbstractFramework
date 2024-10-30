---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- texture
---------------------------------------------------------------------
--- @param color table|string
function AF.CreateTexture(parent, texture, color, drawLayer, subLevel, wrapModeHorizontal, wrapModeVertical, filterMode)
    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)

    function tex:SetColor(c)
        if type(c) == "string" then c = AF.GetColorTable(c) end
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
    --     AF.ReSize(tex)
    --     AF.RePoint(tex)
    -- end

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
--- @param color1 table|string
--- @param color2 table|string
function AF.CreateGradientTexture(parent, orientation, color1, color2, texture, drawLayer, subLevel)
    texture = texture or AF.GetPlainTexture()
    if type(color1) == "string" then color1 = AF.GetColorTable(color1) end
    if type(color2) == "string" then color2 = AF.GetColorTable(color2) end
    color1 = color1 or {0, 0, 0, 0}
    color2 = color2 or {0, 0, 0, 0}

    local tex = parent:CreateTexture(nil, drawLayer or "ARTWORK", nil, subLevel)
    tex:SetTexture(texture)
    tex:SetGradient(orientation, CreateColor(unpack(color1)), CreateColor(unpack(color2)))

    function tex:UpdatePixels()
        AF.ReSize(tex)
        AF.RePoint(tex)
    end

    AF.AddToPixelUpdater(tex)

    return tex
end

---------------------------------------------------------------------
-- line
---------------------------------------------------------------------
function AF.CreateSeparator(parent, width, height, color)
    if type(color) == "string" then color = AF.GetColorTable(color) end
    color = color or AF.GetColorTable("accent")

    local line = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    AF.SetSize(line, width, height)
    line:SetColorTexture(unpack(color))

    local shadow = parent:CreateTexture(nil, "ARTWORK", nil, -1)
    AF.SetSize(shadow, height)
    AF.SetPoint(shadow, "TOPLEFT", line, 1, -1)
    AF.SetPoint(shadow, "TOPRIGHT", line, 1, -1)
    shadow:SetColorTexture(AF.GetColorRGB("black", color[4])) -- use line alpha

    hooksecurefunc(line, "Show", function()
        shadow:Show()
    end)
    hooksecurefunc(line, "Hide", function()
        shadow:Hide()
    end)

    function line:UpdatePixels()
        AF.ReSize(line)
        AF.RePoint(line)
        AF.ReSize(shadow)
        AF.RePoint(shadow)
    end

    AF.AddToPixelUpdater(line)

    return line
end