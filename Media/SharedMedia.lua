---@class AbstractFramework
local AF = _G.AbstractFramework
local LSM = AF.Libs.LSM

local strlower = string.lower
local tinsert, tconcat = table.insert, table.concat

---------------------------------------------------------------------
-- register media
---------------------------------------------------------------------
-- fonts
LSM:Register("font", "Visitor", AF.GetFont("Visitor"), 255)
LSM:Register("font", "Emblem", AF.GetFont("Emblem"), 255)
LSM:Register("font", "Expressway", AF.GetFont("Expressway"), 255)

-- statusbar
LSM:Register("statusbar", "AF Plain", AF.GetPlainTexture())
LSM:Register("statusbar", "AF", AF.GetTexture("Bar_AF"))
LSM:Register("statusbar", "AF Underline", AF.GetTexture("Bar_Underline"))
-- https://github.com/mrrosh/pfUI-CustomMedia
LSM:Register("statusbar", "pfUI-S", AF.GetTexture("Bar_pfUI_S"))
LSM:Register("statusbar", "pfUI-U", AF.GetTexture("Bar_pfUI_U"))

---------------------------------------------------------------------
-- functions
---------------------------------------------------------------------
local DEFAULT_BAR_TEXTURE = AF.GetPlainTexture()
local DEFAULT_FONT = GameFontNormal:GetFont()

function AF.LSM_GetBarTexture(name)
    if name and LSM:IsValid("statusbar", name) then
        return LSM:Fetch("statusbar", name)
    end
    return DEFAULT_BAR_TEXTURE
end

function AF.LSM_GetBarTextureDropdownItems()
    local items = {}
    local textureNames = LSM:List("statusbar")
    local textures = LSM:HashTable("statusbar")

    for _, name in next, textureNames do
        tinsert(items, {
            text = name,
            value = name,
            texture = textures[name],
        })
    end

    return items
end

function AF.LSM_GetFont(name)
    if name and LSM:IsValid("font", name) then
        return LSM:Fetch("font", name)
    elseif type(name) == "string" and name:lower():find(".ttf$") then
        return name
    end
    return DEFAULT_FONT
end

function AF.LSM_GetFontDropdownItems()
    local items = {}
    local fontNames = LSM:List("font")
    local fonts = LSM:HashTable("font")

    for _, name in next, fontNames do
        tinsert(items, {
            text = name,
            value = name,
            font = fonts[name],
        })
    end

    return items
end

---@param fs FontString|EditBox
function AF.SetFont(fs, font, size, outline, shadow)
    if type(font) == "table" then
        font, size, outline, shadow = unpack(font)
    end

    font = AF.LSM_GetFont(font)

    local flags = {}

    outline = strlower(outline or "none")

    if outline:find("thickoutline") then
        tinsert(flags, "THICKOUTLINE")
    elseif outline:find("outline") then
        tinsert(flags, "OUTLINE")
    end

    if outline:find("monochrome") then
        tinsert(flags, "MONOCHROME")
    end

    flags = tconcat(flags, ",")

    fs:SetFont(font, size, flags)

    if shadow then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 1)
    else
        fs:SetShadowOffset(0, 0)
        fs:SetShadowColor(0, 0, 0, 0)
    end
end