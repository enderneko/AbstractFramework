---@class AbstractFramework
local AF = select(2, ...)
local LSM = AF.Libs.LSM
local L = AF.L

local strlower = string.lower
local tinsert, tconcat = table.insert, table.concat

---------------------------------------------------------------------
-- register media
---------------------------------------------------------------------
-- fonts
LSM:Register("font", "Noto_AP", AF.GetFont("NotoSansCJKsc_AP"), 255)
LSM:Register("font", "Noto_Dolphin", AF.GetFont("NotoSansCJKsc_Dolphin"), 255)
LSM:Register("font", "Accidental Presidency", AF.GetFont("Accidental_Presidency"), 255)
LSM:Register("font", "Cal Sans", AF.GetFont("CalSans"), 255)
LSM:Register("font", "Dolphin", AF.GetFont("Dolphin"), 255)
LSM:Register("font", "Emblem", AF.GetFont("Emblem"), 255)
LSM:Register("font", "Expressway", AF.GetFont("Expressway"), 255)
LSM:Register("font", "Visitor", AF.GetFont("Visitor"), 255)
LSM:Register("font", "Unifont", AF.GetFont("Unifont.otf"), 255)

-- statusbar
LSM:Register("statusbar", "AF Plain", AF.GetPlainTexture())
LSM:Register("statusbar", "AF Plain Half Top", AF.GetTexture("White_Half_Top"))
LSM:Register("statusbar", "AF Plain Half Bottom", AF.GetTexture("White_Half_Bottom"))
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

function AF.LSM_GetFontOutlineDropdownItems()
    return {
        {text = L["None"], value = "none"},
        {text = L["Outline"], value = "outline"},
        {text = L["Thick Outline"], value = "thickoutline"},
        {text = L["Monochrome"], value = "monochrome"},
        {text = L["Mono Outline"], value = "monochrome_outline"},
        {text = L["Mono Thick"], value = "monochrome_thickoutline"},
    }
end

-- if font is a table, non-nil size/outline/shadow values will override those in the table
---@param fs FontString|EditBox
---@param font string|table fontName/fontFile or fontTable {font, size, outline, shadow}
---@param size number|nil
---@param outline string|nil
---@param shadow boolean|nil
function AF.SetFont(fs, font, size, outline, shadow)
    if type(font) == "table" then
        local _font, _size, _outline, _shadow = unpack(font)
        font = _font
        size = size or _size
        outline = outline or _outline
        shadow = shadow or _shadow
    end

    font = AF.LSM_GetFont(font)
    outline = strlower(outline or "none")

    local flag1
    if outline:find("thickoutline") then
        flag1 = "THICKOUTLINE"
    elseif outline:find("outline") then
        flag1 = "OUTLINE"
    end

    local flag2
    if outline:find("monochrome") then
        flag2 = "MONOCHROME"
    end

    if flag1 and flag2 then
        fs:SetFont(font, size or 13, flag1 .. "," .. flag2)
    elseif flag1 then
        fs:SetFont(font, size or 13, flag1)
    elseif flag2 then
        fs:SetFont(font, size or 13, flag2)
    else
        fs:SetFont(font, size or 13, "")
    end

    if shadow then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 1)
    else
        fs:SetShadowOffset(0, 0)
        fs:SetShadowColor(0, 0, 0, 0)
    end
end

-- Update the font object with new values, nil values will remain unchanged
---@param size number|string if a string, represents the font size delta for fontObj, e.g. "-1", "+2"
function AF.UpdateFont(fontObj, font, size, outline)
    local _font, _size, _flags = fontObj:GetFont()

    font = font and AF.LSM_GetFont(font) or _font
    size = size or _size
    outline = outline or _flags


    if type(size) == "string" then
        size = tonumber(size) + _size
    end

    AF.SetFont(fontObj, font, size, outline)

    -- restore shadow
    local shadowX, shadowY = fontObj:GetShadowOffset()
    local shadowR, shadowG, shadowB, shadowA = fontObj:GetShadowColor()

    fontObj:SetShadowOffset(shadowX or 0, shadowY or 0)
    fontObj:SetShadowColor(shadowR or 0, shadowG or 0, shadowB or 0, shadowA or 0)
end

---@param shadowPos table|nil default {1, -1}
---@param shadowColor table|string|nil default "font_shadow"
function AF.SetFontShadow(fontObj, shadowPos, shadowColor)
    shadowPos = shadowPos or {1, -1}
    shadowColor = shadowColor or "font_shadow"

    fontObj:SetShadowOffset(AF.Unpack2(shadowPos))

    if type(shadowColor) == "string" then
        fontObj:SetShadowColor(AF.GetColorRGB(shadowColor))
    elseif type(shadowColor) == "table" then
        fontObj:SetShadowColor(AF.UnpackColor(shadowColor))
    end
end

function AF.RemoveFontShadow(fontObj)
    fontObj:SetShadowOffset(0, 0)
    fontObj:SetShadowColor(0, 0, 0, 0)
end