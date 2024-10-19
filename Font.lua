---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- fonts
---------------------------------------------------------------------
local FONT_TITLE_NAME = "AW_FONT_TITLE"
local FONT_NORMAL_NAME = "AW_FONT_NORMAL"
local FONT_OUTLINE_NAME = "AW_FONT_OUTLINE"
local FONT_SMALL_NAME = "AW_FONT_SMALL"
local FONT_CHINESE_NAME = "AW_FONT_CHINESE"

local FONT_TITLE_SIZE = 14
local FONT_NORMAL_SIZE = 13
local FONT_OUTLINE_SIZE = 13
local FONT_SMALL_SIZE = 11
local FONT_CHINESE_SIZE = 14

local BASE_FONT = GameFontNormal:GetFont()

local font_title = CreateFont(FONT_TITLE_NAME)
font_title:SetFont(BASE_FONT, FONT_TITLE_SIZE, "")
font_title:SetTextColor(1, 1, 1, 1)
font_title:SetShadowColor(0, 0, 0)
font_title:SetShadowOffset(1, -1)
font_title:SetJustifyH("CENTER")

local font_normal = CreateFont(FONT_NORMAL_NAME)
font_normal:SetFont(BASE_FONT, FONT_NORMAL_SIZE, "")
font_normal:SetTextColor(1, 1, 1, 1)
font_normal:SetShadowColor(0, 0, 0)
font_normal:SetShadowOffset(1, -1)
font_normal:SetJustifyH("CENTER")

local font_outline = CreateFont(FONT_OUTLINE_NAME)
font_outline:SetFont(BASE_FONT, FONT_OUTLINE_SIZE, "OUTLINE")
font_outline:SetTextColor(AW.GetColorRGB("accent"))
font_outline:SetShadowColor(0, 0, 0)
font_outline:SetShadowOffset(0, 0)
font_outline:SetJustifyH("CENTER")

local font_small = CreateFont(FONT_SMALL_NAME)
font_small:SetFont(BASE_FONT, FONT_SMALL_SIZE, "")
font_small:SetTextColor(1, 1, 1, 1)
font_small:SetShadowColor(0, 0, 0)
font_small:SetShadowOffset(1, -1)
font_small:SetJustifyH("CENTER")

local font_chinese = CreateFont(FONT_CHINESE_NAME)
font_chinese:SetFont(UNIT_NAME_FONT_CHINESE, FONT_CHINESE_SIZE, "")
font_chinese:SetTextColor(1, 1, 1, 1)
font_chinese:SetShadowColor(0, 0, 0)
font_chinese:SetShadowOffset(1, -1)
font_chinese:SetJustifyH("CENTER")

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
function AW.CreateFonts(prefix, suffix, font, size, flags, shadow)

end

---------------------------------------------------------------------
-- update size for all used fonts
---------------------------------------------------------------------
local fontStrings = {}
function AW.AddToFontSizeUpdater(fs, originalSize)
    fs.originalSize = originalSize
    tinsert(fontStrings, fs)
end

AW.fontSizeOffset = 0
function AW.UpdateFontSize(offset)
    AW.fontSizeOffset = offset
    font_title:SetFont(BASE_FONT, FONT_TITLE_SIZE + offset, "")
    font_normal:SetFont(BASE_FONT, FONT_NORMAL_SIZE + offset, "")
    font_outline:SetFont(BASE_FONT, FONT_OUTLINE_SIZE + offset, "")
    font_small:SetFont(BASE_FONT, FONT_SMALL_SIZE + offset, "")
    font_chinese:SetFont(UNIT_NAME_FONT_CHINESE, FONT_CHINESE_SIZE + offset, "")

    for _, fs in ipairs(fontStrings) do
        local f, _, o = fs:GetFont()
        fs:SetFont(f, (fs.originalSize or FONT_NORMAL_SIZE) + offset, o)
    end
end

---------------------------------------------------------------------
-- get font by "type"
---------------------------------------------------------------------
-- function AW.GetFontName(font, isDisabled)
--     if font == "title" then
--         return isDisabled and FONT_TITLE_DISABLE_NAME or FONT_TITLE_NAME
--     elseif font == "normal" then
--         return isDisabled and FONT_NORMAL_DISABLE_NAME or FONT_NORMAL_NAME
--     elseif font == "small" then
--         return isDisabled and FONT_SMALL_DISABLE_NAME or FONT_SMALL_NAME
--     elseif font == "accent_title" then
--         return FONT_ACCENT_TITLE_NAME
--     elseif font == "accent_outline" then
--         return FONT_OUTLINE_NAME
--     elseif font == "accent" then
--         return FONT_ACCENT_NAME
--     end
-- end

-- function AW.GetFontObject(font, isDisabled)
--     if font == "title" then
--         return isDisabled and font_title_disable or font_title
--     elseif font == "normal" then
--         return isDisabled and font_normal_disable or font_normal
--     elseif font == "small" then
--         return isDisabled and font_small_disable or font_small
--     elseif font == "accent_title" then
--         return font_accent_title
--     elseif font == "accent_outline" then
--         return font_outline
--     elseif font == "accent" then
--         return font_accent
--     end
-- end

function AW.GetFontProps(font)
    if font == "title" then
        return BASE_FONT, FONT_TITLE_SIZE + AW.fontSizeOffset, ""
    elseif font == "normal" then
        return BASE_FONT, FONT_NORMAL_SIZE + AW.fontSizeOffset, ""
    elseif font == "small" then
        return BASE_FONT, FONT_SMALL_SIZE + AW.fontSizeOffset, ""
    elseif font == "outline" then
        return BASE_FONT, FONT_OUTLINE_SIZE + AW.fontSizeOffset, "OUTLINE"
    else
        return font, FONT_NORMAL_SIZE + AW.fontSizeOffset, ""
    end
end