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
LSM:Register("statusbar", "AF 1", AF.GetTexture("StatusBar1"))

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

function AF.LSM_GetFont(name)
    if name and LSM:IsValid("font", name) then
        return LSM:Fetch("font", name)
    elseif type(name) == "string" and name:lower():find(".ttf$") then
        return name
    end
    return DEFAULT_FONT
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