---@class AbstractFramework
local AF = select(2, ...)

local atlasBase = {
    Anchors = {256, 256},
}

local atlasInfo = {
    -- Anchors
    Anchor_BOTTOM = {"Anchors", 0, 0, 64, 64},
    Anchor_BOTTOMLEFT = {"Anchors", 64, 0, 64, 64},
    Anchor_BOTTOMRIGHT = {"Anchors", 128, 0, 64, 64},
    Anchor_CENTER = {"Anchors", 192, 0, 64, 64},
    Anchor_LEFT = {"Anchors", 0, 64, 64, 64},
    Anchor_RIGHT = {"Anchors", 64, 64, 64, 64},
    Anchor_TOP = {"Anchors", 128, 64, 64, 64},
    Anchor_TOPLEFT = {"Anchors", 192, 64, 64, 64},
    Anchor_TOPRIGHT = {"Anchors", 0, 128, 64, 64},
}

---@param texture Texture
---@param name string
function AF.SetAtlas(texture, name)
    local atlas = atlases[name]
    if atlas then
        local base, x, y, w, h = AF.Unpack5(atlas)
        local bW, bH = AF.Unpack2(atlasBase[base])
        texture:SetTexture("Interface\\AddOns\\AbstractFramework\\Media\\Atlases\\" .. base)
        texture:SetTexCoord(x / bW, (x + w) / bW, y / bH, (y + h) / bH)
    end
end