---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- color utils
---------------------------------------------------------------------
function AF.ConvertToRGB(r, g, b, a, saturation)
    a = a or 255
    saturation = saturation or 1
    r = AF.Round(r / 255 * saturation, 5)
    g = AF.Round(g / 255 * saturation, 5)
    b = AF.Round(b / 255 * saturation, 5)
    a = AF.Round(a / 255, 5)
    return r, g, b, a
end

function AF.ConvertToRGB256(r, g, b, a)
    return floor(r * 255), floor(g * 255), floor(b * 255), a and floor(a * 255)
end

function AF.ConvertRGB256ToHEX(r, g, b, a)
    local result = ""

    local t = a and {a, r, g, b} or {r, g, b}

    for key, value in pairs(t) do
        local hex = ""

        while (value > 0) do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub("0123456789abcdef", index, index) .. hex
        end

        if (string.len(hex) == 0) then
            hex = "00"
        elseif (string.len(hex) == 1) then
            hex = "0" .. hex
        end

        result = result .. hex
    end

    return result
end

function AF.ConvertRGBToHEX(r, g, b, a)
    return AF.ConvertRGB256ToHEX(AF.ConvertToRGB256(r, g, b, a))
end

function AF.ConvertHEXToRGB256(hex)
    hex = hex:gsub("#", "")
    if strlen(hex) == 6 then
        return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
    else
        return tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)), tonumber("0x" .. hex:sub(7, 8)), tonumber("0x" .. hex:sub(1, 2))
    end
end

function AF.ConvertHEXToRGB(hex)
    return AF.ConvertToRGB(AF.ConvertHEXToRGB256(hex))
end

-- https://warcraft.wiki.gg/wiki/ColorGradient
function AF.ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
    perc = perc or 1
    if perc >= 1 then
        return r3, g3, b3
    elseif perc <= 0 then
        return r1, g1, b1
    end

    local segment, relperc = math.modf(perc * 2)
    local rr1, rg1, rb1, rr2, rg2, rb2 = select((segment * 3) + 1, r1, g1, b1, r2, g2, b2, r3, g3, b3)

    return rr1 + (rr2 - rr1) * relperc, rg1 + (rg2 - rg1) * relperc, rb1 + (rb2 - rb1) * relperc
end

-- From ColorPickerAdvanced by Feyawen-Llane
--[[ Convert RGB to HSV ---------------------------------------------------
    Inputs:
        r = Red [0, 1]
        g = Green [0, 1]
        b = Blue [0, 1]
    Outputs:
        H = Hue [0, 360]
        S = Saturation [0, 1]
        B = Brightness [0, 1]
]] --
function AF.ConvertRGBToHSB(r, g, b)
    local colorMax = max(r, g, b)
    local colorMin = min(r, g, b)
    local delta = colorMax - colorMin
    local H, S, B

    -- WoW's LUA doesn't handle floating point numbers very well (Somehow 1.000000 != 1.000000   WTF?)
    -- So we do this weird conversion of, Number to String back to Number, to make the IF..THEN work correctly!
    colorMax = tonumber(format("%f", colorMax))
    r = tonumber(format("%f", r))
    g = tonumber(format("%f", g))
    b = tonumber(format("%f", b))

    if (delta > 0) then
        if (colorMax == r) then
            H = 60 * (((g - b) / delta) % 6)
        elseif (colorMax == g) then
            H = 60 * (((b - r) / delta) + 2)
        elseif (colorMax == b) then
            H = 60 * (((r - g) / delta) + 4)
        end

        if (colorMax > 0) then
            S = delta / colorMax
        else
            S = 0
        end

        B = colorMax
    else
        H = 0
        S = 0
        B = colorMax
    end

    if (H < 0) then
        H = H + 360
    end

    return H, S, B
end

--[[ Convert HSB to RGB ---------------------------------------------------
    Inputs:
        h = Hue [0, 360]
        s = Saturation [0, 1]
        b = Brightness [0, 1]
    Outputs:
        R = Red [0,1]
        G = Green [0,1]
        B = Blue [0,1]
]] --
function AF.ConvertHSBToRGB(h, s, b)
    local chroma = b * s
    local prime = (h / 60) % 6
    local X = chroma * (1 - abs((prime % 2) - 1))
    local M = b - chroma
    local R, G, B

    if (0 <= prime) and (prime < 1) then
        R = chroma
        G = X
        B = 0
    elseif (1 <= prime) and (prime < 2) then
        R = X
        G = chroma
        B = 0
    elseif (2 <= prime) and (prime < 3) then
        R = 0
        G = chroma
        B = X
    elseif (3 <= prime) and (prime < 4) then
        R = 0
        G = X
        B = chroma
    elseif (4 <= prime) and (prime < 5) then
        R = X
        G = 0
        B = chroma
    elseif (5 <= prime) and (prime < 6) then
        R = chroma
        G = 0
        B = X
    else
        R = 0
        G = 0
        B = 0
    end

    R = tonumber(format("%.3f", R + M))
    G = tonumber(format("%.3f", G + M))
    B = tonumber(format("%.3f", B + M))

    return R, G, B
end

---------------------------------------------------------------------
-- colors
---------------------------------------------------------------------
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction

local colors = {
    -- accent
    ["accent"] = {["hex"] = "ffff6600", ["t"] = {1, 0.4, 0, 1}, ["normal"] = {1, 0.4, 0, 0.3}, ["hover"] = {1, 0.4, 0, 0.6}},
    ["accent_alt"] = {["hex"] = "ffff0066", ["t"] = {1, 0, 0.4, 1}, ["normal"] = {1, 0, 0.4, 0.3}, ["hover"] = {1, 0, 0.4, 0.6}},

    -- for regions
    ["background"] = {["hex"] = "e61a1a1a", ["t"] = {0.1, 0.1, 0.1, 0.9}},
    ["border"] = {["hex"] = "ff000000", ["t"] = {0, 0, 0, 1}},
    ["header"] = {["hex"] = "ff202020", ["t"] = {0.127, 0.127, 0.127, 1}}, -- header background
    ["widget"] = {["hex"] = "ff262626", ["t"] = {0.15, 0.15, 0.15, 1}}, -- widget background
    ["disabled"] = {["hex"] = "ff666666", ["t"] = {0.4, 0.4, 0.4, 1}},
    ["none"] = {["hex"] = "00000000", ["t"] = {0, 0, 0, 0}},
    ["sheet_bg"] = {["t"] = {0.15, 0.15, 0.15, 0.9}},
    ["sheet_cell_highlight"] = {["t"] = {1, 1, 1, 0.1}},
    ["sheet_row_highlight"] = {["t"] = {0.7, 0.7, 0.7, 0.1}},

    -- common
    ["red"] = {["hex"] = "ffff0000", ["t"] = {1, 0, 0, 1}},
    ["yellow"] = {["hex"] = "ffffff00", ["t"] = {1, 1, 0, 1}},
    ["green"] = {["hex"] = "ff00ff00", ["t"] = {0, 1, 0, 1}},
    ["cyan"] = {["hex"] = "ff00ffff", ["t"] = {0, 1, 1, 1}},
    ["blue"] = {["hex"] = "ff0000ff", ["t"] = {0, 0, 1, 1}},
    ["purple"] = {["hex"] = "ffff00ff", ["t"] = {1, 0, 1, 1}},
    ["white"] = {["hex"] = "ffffffff", ["t"] = {1, 1, 1, 1}},
    ["black"] = {["hex"] = "ff000000", ["t"] = {0, 0, 0, 1}},

    -- others
    ["gray"] = {["hex"] = "ffb2b2b2", ["t"] = {0.83, 0.83, 0.83, 1}},
    ["lightgray"] = {["hex"] = "ffd3d3d3", ["t"] = {0.7, 0.7, 0.7, 1}},
    ["sand"] = {["hex"] = "ffeccc68", ["t"] = {0.93, 0.8, 0.41, 1}},
    ["gold"] = {["hex"] = "ffffd100", ["t"] = {1, 0.82, 0, 1}},
    ["darkred"] = {["hex"] = "ff402020", ["t"] = {0.17, 0.13, 0.13, 1}},
    ["orange"] = {["hex"] = "ffffa502", ["t"] = {1, 0.65, 0.01, 1}},
    ["orangered"] = {["hex"] = "ffff4f00", ["t"] = {1, 0.31, 0, 1}},
    ["firebrick"] = {["hex"] = "ffff3030", ["t"] = {1, 0.19, 0.19, 1}},
    ["coral"] = {["hex"] = "ffff7f50", ["t"] = {1, 0.5, 0.31, 1}},
    ["tomato"] = {["hex"] = "ffff6348", ["t"] = {1, 0.39, 0.28, 1}},
    ["lightred"] = {["hex"] = "ffff4757", ["t"] = {1, 0.28, 0.34, 1}},
    ["classicrose"] = {["hex"] = "fffbcce7", ["t"] = {0.98, 0.8, 0.91, 1}},
    ["pink"] = {["hex"] = "ffff6b81", ["t"] = {1, 0.42, 0.51, 1}},
    ["hotpink"] = {["hex"] = "ffff4466", ["t"] = {1, 0.27, 0.4, 1}},
    ["lime"] = {["hex"] = "ff7bed9f", ["t"] = {0.48, 0.93, 0.62, 1}},
    ["brightgreen"] = {["hex"] = "ff2ed573", ["t"] = {0.18, 0.84, 0.45, 1}},
    ["chartreuse"] = {["hex"] = "ff80ff00", ["t"] = {0.502, 1, 0, 1}},
    ["skyblue"] = {["hex"] = "ff00ccff", ["t"] = {0, 0.8, 1, 1}},
    ["vividblue"] = {["hex"] = "ff1e90ff", ["t"] = {0.12, 0.56, 1, 1}},
    ["softblue"] = {["hex"] = "ff5352ed", ["t"] = {0.33, 0.32, 0.93, 1}},
    ["brightblue"] = {["hex"] = "ff3742fa", ["t"] = {0.22, 0.26, 0.98, 1}},
    ["guild"] = {["hex"] = "ff40ff40", ["t"] = {0.251, 1, 0.251, 1}},

    -- class (data from RAID_CLASS_COLORS)
    ["DEATHKNIGHT"] = {["hex"] = "ffc41e3a", ["t"] = {0.7686275243759155, 0.1176470667123795, 0.2274509966373444}},
    ["DEMONHUNTER"] = {["hex"] = "ffa330c9", ["t"] = {0.6392157077789307, 0.1882353127002716, 0.7882353663444519}},
    ["DRUID"] = {["hex"] = "ffff7c0a", ["t"] = {1, 0.4862745404243469, 0.03921568766236305}},
    ["EVOKER"] = {["hex"] = "ff33937f", ["t"] = {0.2000000178813934, 0.5764706134796143, 0.4980392456054688}},
    ["HUNTER"] = {["hex"] = "ffaad372", ["t"] = {0.6666666865348816, 0.8274510502815247, 0.4470588564872742}},
    ["MAGE"] = {["hex"] = "ff3fc7eb", ["t"] = {0.2470588386058807, 0.7803922295570374, 0.9215686917304993}},
    ["MONK"] = {["hex"] = "ff00ff98", ["t"] = {0, 1, 0.5960784554481506}},
    ["PALADIN"] = {["hex"] = "fff48cba", ["t"] = {0.9568628072738647, 0.5490196347236633, 0.729411780834198}},
    ["PRIEST"] = {["hex"] = "ffffffff", ["t"] = {1, 1, 1}},
    ["ROGUE"] = {["hex"] = "fffff468", ["t"] = {1, 0.9568628072738647, 0.4078431725502014}},
    ["SHAMAN"] = {["hex"] = "ff0070dd", ["t"] = {0, 0.4392157196998596, 0.8666667342185974}},
    ["WARLOCK"] = {["hex"] = "ff8788ee", ["t"] = {0.529411792755127, 0.5333333611488342, 0.9333333969116211}},
    ["WARRIOR"] = {["hex"] = "ffc69b6d", ["t"] = {0.7764706611633301, 0.6078431606292725, 0.4274510145187378}},
    ["UNKNOWN"] = {["hex"] = "ff666666", ["t"] = {0.4, 0.4, 0.4}},

    -- faction
    ["Horde"] = {["hex"] = "ffc70000", ["t"] = {0.78, 0, 0}},
    ["Alliance"] = {["hex"] = "ff1a80ff", ["t"] = {0.1, 0.5, 1}},

    -- role
    ["TANK"] = {["hex"] = "ff627ee2", ["t"] = {0.38, 0.49, 0.89}},
    ["HEALER"] = {["hex"] = "ff4baa4e", ["t"] = {0.29, 0.67, 0.31}},
    ["DAMAGER"] = {["hex"] = "ffa74c4d", ["t"] = {0.65, 0.3, 0.3}},

    -- reaction
    ["FRIENDLY"] = {["hex"] = "ff4ab04d", ["t"] = {0.29, 0.69, 0.3}},
    ["NEUTRAL"] = {["hex"] = "ffd9c45c", ["t"] = {0.85, 0.77, 0.36}},
    ["HOSTILE"] = {["hex"] = "ffc74040", ["t"] = {0.78, 0.25, 0.25}},

    -- power color (color from PowerBarColor & ElvUI)
    ["MANA"] = {["hex"] = "ff007fff", ["t"] = {0, 0.5, 1}}, -- 0, 0, 1
    ["RAGE"] = {["hex"] = "ffff0000", ["t"] = {1, 0, 0}},
    ["FOCUS"] = {["hex"] = "ffff7f3f", ["t"] = {1, 0.50, 0.25}},
    ["ENERGY"] = {["hex"] = "ffffff00", ["t"] = {1, 1, 0}},
    ["COMBO_POINTS"] = {["hex"] = "fffff468", ["t"] = {1, 0.96, 0.41}},
    ["RUNES"] = {["hex"] = "ff7f7f7f", ["t"] = {0.50, 0.50, 0.50}},
    ["RUNIC_POWER"] = {["hex"] = "ff00d1ff", ["t"] = {0, 0.82, 1}},
    ["SOUL_SHARDS"] = {["hex"] = "ff9482c9", ["t"] = {0.58, 0.51, 0.79}}, --{["hex"]="ff7f518c", ["t"]={0.50, 0.32, 0.55}}
    ["LUNAR_POWER"] = {["hex"] = "ff4c84e5", ["t"] = {0.30, 0.52, 0.90}},
    ["HOLY_POWER"] = {["hex"] = "fff2e54d", ["t"] = {0.95, 0.9, 0.3}}, -- {["hex"]="fff2e599", ["t"]={0.95, 0.90, 0.60}},
    ["MAELSTROM"] = {["hex"] = "ff007fff", ["t"] = {0, 0.5, 1}},
    ["INSANITY"] = {["hex"] = "ff9933ff", ["t"] = {0.6, 0.2, 1}}, -- 0.40, 0, 0.80
    ["CHI"] = {["hex"] = "ffb5ffea", ["t"] = {0.71, 1, 0.92}},
    ["ESSENCE"] = {["hex"] = "FF76DFD1", ["t"] = {0.46, 0.87, 0.82}, ["start"] = {0.71, 0.82, 1}, ["end"] = {1, 0.75, 0.75}},
    ["ARCANE_CHARGES"] = {["hex"] = "ff009eff", ["t"] = {0, 0.62, 1}}, -- {["hex"]="ff1919f9", ["t"]={0.10, 0.10, 0.98}}
    ["FURY"] = {["hex"] = "ffc842fc", ["t"] = {0.788, 0.259, 0.992}},
    ["PAIN"] = {["hex"] = "ffff9c00", ["t"] = {1, 0.612, 0}},
    -- vehicle colors
    ["AMMOSLOT"] = {["hex"] = "ffcc9900", ["t"] = {0.80, 0.60, 0}},
    ["FUEL"] = {["hex"] = "ff008c7f", ["t"] = {0.0, 0.55, 0.5}},
    -- alternate power bar colors
    ["EBON_MIGHT"] = {["hex"] = "ffe58c4c", ["t"] = {0.9, 0.55, 0.3}},
    ["STAGGER_GREEN"] = {["hex"] = "ff84ff84", ["t"] = {0.52, 1, 0.52,}},
    ["STAGGER_YELLOW"] = {["hex"] = "fffff9b7", ["t"] = {1, 0.98, 0.72}},
    ["STAGGER_RED"] = {["hex"] = "ffff6b6b", ["t"] = {1, 0.42, 0.42}},

    -- quality https://warcraft.wiki.gg/wiki/Quality
    ["Poor"] = {["hex"] = "ff9d9d9d", ["t"] = {0.62, 0.62, 0.62, 1}}, -- ITEM_QUALITY0_DESC
    ["Common"] = {["hex"] = "ffffffff", ["t"] = {1, 1, 1, 1}}, -- ITEM_QUALITY1_DESC
    ["Uncommon"] = {["hex"] = "ff1eff00", ["t"] = {0.12, 1, 0, 1}}, -- ITEM_QUALITY2_DESC
    ["Rare"] = {["hex"] = "ff0070dd", ["t"] = {0, 0.44, 0.87, 1}}, -- ITEM_QUALITY3_DESC
    ["Epic"] = {["hex"] = "ffa335ee", ["t"] = {0.64, 0.21, 0.93, 1}}, -- ITEM_QUALITY4_DESC
    ["Legendary"] = {["hex"] = "ffff8000", ["t"] = {1, 0.5, 0, 1}}, -- ITEM_QUALITY5_DESC
    ["Artifact"] = {["hex"] = "ffe6cc80", ["t"] = {0.9, 0.8, 0.5, 1}}, -- ITEM_QUALITY6_DESC
    ["Heirloom"] = {["hex"] = "ff00ccff", ["t"] = {0, 0.8, 1, 1}}, -- ITEM_QUALITY7_DESC
    ["WoWToken"] = {["hex"] = "ff00ccff", ["t"] = {0, 0.8, 1, 1}}, -- ITEM_QUALITY8_DESC
}

function AF.HasColor(name)
    return colors[name] and true or false
end

function AF.GetColorRGB(name, alpha, saturation)
    assert(colors[name], "no such color:", name)
    -- if not colors[name] then
    --     return 1, 1, 1, 1
    -- end

    saturation = saturation or 1
    alpha = alpha or colors[name]["t"][4]
    return colors[name]["t"][1] * saturation, colors[name]["t"][2] * saturation, colors[name]["t"][3] * saturation, alpha
end

function AF.GetColorTable(name, alpha, saturation)
    assert(colors[name], "no such color:", name)
    -- if not colors[name] then
    --     return AF.GetColorTable("white", alpha, saturation)
    -- end

    saturation = saturation or 1
    alpha = alpha or colors[name]["t"][4]

    return {colors[name]["t"][1] * saturation, colors[name]["t"][2] * saturation, colors[name]["t"][3] * saturation, alpha}
end

function AF.GetColorHex(name)
    assert(colors[name], "no such color:", name)
    if not colors[name]["hex"] then
        colors[name]["hex"] = AF.ConvertRGB256ToHEX(AF.ConvertToRGB256(unpack(colors[name]["t"])))
    end
    return colors[name]["hex"]
end

local ADDONS = {}
function AF.RegisterAddonForAccentColor(addon)
    ADDONS[addon] = true
end

local function GetAddon()
    for addon in string.gmatch(debugstack(2), "@Interface/AddOns/([^/]+)/") do
        if ADDONS[addon] then
            return addon
        end
    end
end

---@param color string|table
---@param alias string?
function AF.SetAccentColor(color, alias)
    local addon = GetAddon()
    assert(addon, "no registered addon found")

    if type(color) == "string" then
        if colors[color] then
            colors[addon] = colors[color]
        else
            color = strlower(color)
            local hex = strlen(color) == 6 and "ff" .. color or color
            colors[addon] = {["hex"] = hex, ["t"] = {AF.ConvertHEXToRGB(hex)}}
        end
    elseif type(color) == "table" then
        if #color == 3 then
            color[4] = 1
        end
        colors[addon] = {["hex"] = AF.ConvertRGBToHEX(AF.UnpackColor(color)), ["t"] = color}
    end

    if alias then
        colors[alias] = colors[addon]
    end
end

function AF.GetAccentColorName()
    return GetAddon() or "accent"
end

function AF.GetAccentColorTable(alpha)
    return AF.GetColorTable(AF.GetAccentColorName(), alpha)
end

function AF.GetAccentColorRGB(alpha)
    return AF.GetColorRGB(AF.GetAccentColorName(), alpha)
end

function AF.GetAccentColorHex(alpha)
    return AF.GetColorHex(AF.GetAccentColorName(), alpha)
end

function AF.GetClassColor(class, alpha, saturation)
    saturation = saturation or 1

    if colors[class] then
        return AF.GetColorRGB(class, alpha, saturation)
    end

    if RAID_CLASS_COLORS[class] then
        local r, g, b = RAID_CLASS_COLORS[class]:GetRGB()
        return r * saturation, g * saturation, b * saturation, alpha
    end

    return AF.GetColorRGB("UNKNOWN")
end

function AF.GetReactionColor(unit, alpha, saturation)
    --! reaction to player, MUST use UnitReaction(unit, "player")
    --! NOT UnitReaction("player", unit)
    local reaction = UnitReaction(unit, "player") or 0
    if reaction <= 2 then
        return AF.GetColorRGB("HOSTILE", alpha, saturation)
    elseif reaction <= 4 then
        return AF.GetColorRGB("NEUTRAL", alpha, saturation)
    else
        return AF.GetColorRGB("FRIENDLY", alpha, saturation)
    end
end

function AF.GetPowerColor(power, unit, alpha, saturation)
    saturation = saturation or 1

    if colors[power] then
        if colors[power]["start"] then -- gradient
            return colors[power]["start"][1] * saturation, colors[power]["start"][2] * saturation, colors[power]["start"][3] * saturation, alpha,
                colors[power]["end"][1] * saturation, colors[power]["end"][2] * saturation, colors[power]["end"][3] * saturation, alpha
        else
            return AF.GetColorRGB(power, alpha, saturation)
        end
    end

    if unit then
        local r, g, b = select(3, UnitPowerType(unit))
        if r then
            return r, g, b, alpha
        end
    end

    return AF.GetColorRGB("MANA", alpha, saturation)
end

function AF.AddColor(name, color)
    colors[name] = {["t"] = color, ["hex"] = AF.ConvertRGBToHEX(AF.UnpackColor(color))}
end

function AF.AddColors(t)
    for k, v in pairs(t) do
        AF.AddColor(k, v)
    end
end

function AF.UnpackColor(t, alpha)
    return t[1], t[2], t[3], alpha or t[4]
end

function AF.ExtractColor(t, alpha)
    return t.r, t.g, t.b, alpha or t.a
end

---------------------------------------------------------------------
-- coloring
---------------------------------------------------------------------
function AF.ColorFontString(fs, name)
    assert(colors[name], "no such color:", name)
    fs:SetTextColor(colors[name]["t"][1], colors[name]["t"][2], colors[name]["t"][3])
end

function AF.WrapTextInColor(text, name)
    -- assert(colors[name], "no such color:", name)
    if not colors[name] then
        return text
    end
    return AF.WrapTextInColorCode(text, AF.GetColorHex(name))
end

function AF.WrapTextInColorRGB(text, r, g, b)
    return AF.WrapTextInColorCode(text, AF.ConvertRGBToHEX(r, g, b, 1))
end

function AF.WrapTextInColorCode(text, colorHexString)
    colorHexString = colorHexString or "ffffffff"
    if #colorHexString == 6 then
        colorHexString = "ff" .. colorHexString
    end
    return format("|c%s%s|r", colorHexString, text)
end

function AF.Interpolate(start, stop, step, maxSteps)
    return start + (stop - start) * step / maxSteps
end

---@param text string
---@param startColor string colorName or hexColor
---@param endColor string colorName or hexColor
---@return string: colored text
function AF.GetGradientText(text, startColor, endColor)
    local gradient = ""
    local length = #text
    local r1, g1, b1, r2, g2, b2

    if colors[startColor] then
        r1, g1, b1 = AF.ConvertHEXToRGB256(AF.GetColorHex(startColor))
    else
        r1, g1, b1 = AF.ConvertHEXToRGB256(startColor)
    end

    if colors[endColor] then
        r2, g2, b2 = AF.ConvertHEXToRGB256(AF.GetColorHex(endColor))
    else
        r2, g2, b2 = AF.ConvertHEXToRGB256(endColor)
    end

    local r, g, b, hex
    for i = 0, length - 1 do
        r = AF.Interpolate(r1, r2, i, length - 1)
        g = AF.Interpolate(g1, g2, i, length - 1)
        b = AF.Interpolate(b1, b2, i, length - 1)
        hex = AF.ConvertRGB256ToHEX(r, g, b)
        gradient = gradient .. "|cff" .. hex .. text:sub(i + 1, i + 1) .. "|r"
    end

    return gradient
end

---------------------------------------------------------------------
-- button colors
---------------------------------------------------------------------
local button_color_normal = {0.127, 0.127, 0.127, 1}
local buttonColors = {
    ["accent"] = {["normal"] = colors["accent"]["normal"], ["hover"] = colors["accent"]["hover"]},
    ["accent_hover"] = {["normal"] = button_color_normal, ["hover"] = colors["accent"]["hover"]},
    ["accent_transparent"] = {["normal"] = {0, 0, 0, 0}, ["hover"] = colors["accent"]["hover"]},
    ["border_only"] = {["normal"] = {0, 0, 0, 0}, ["hover"] = {0, 0, 0, 0}},
    ["none"] = {["normal"] = {0, 0, 0, 0}, ["hover"] = {0, 0, 0, 0}},
    ["red"] = {["normal"] = {0.6, 0.1, 0.1, 0.6}, ["hover"] = {0.6, 0.1, 0.1, 1}},
    ["red_hover"] = {["normal"] = button_color_normal, ["hover"] = {0.6, 0.1, 0.1, 1}},
    ["green"] = {["normal"] = {0.1, 0.6, 0.1, 0.6}, ["hover"] = {0.1, 0.6, 0.1, 1}},
    ["green_hover"] = {["normal"] = button_color_normal, ["hover"] = {0.1, 0.6, 0.1, 1}},
    ["blue"] = {["normal"] = {0, 0.5, 0.8, 0.6}, ["hover"] = {0, 0.5, 0.8, 1}},
    ["blue_hover"] = {["normal"] = button_color_normal, ["hover"] = {0, 0.5, 0.8, 1}},
    ["yellow"] = {["normal"] = {0.7, 0.7, 0, 0.6}, ["hover"] = {0.7, 0.7, 0, 1}},
    ["yellow_hover"] = {["normal"] = button_color_normal, ["hover"] = {0.7, 0.7, 0, 1}},
    ["hotpink"] = {["normal"] = {1, 0.27, 0.4, 0.6}, ["hover"] = {1, 0.27, 0.4, 1}},
    ["lime"] = {["normal"] = {0.8, 1, 0, 0.35}, ["hover"] = {0.8, 1, 0, 0.65}},
    ["lavender"] = {["normal"] = {0.96, 0.73, 1, 0.35}, ["hover"] = {0.96, 0.73, 1, 0.65}},
}

function AF.GetButtonNormalColor(name)
    assert(buttonColors[name], "no such button color:", name)
    return buttonColors[name]["normal"]
end

function AF.GetButtonHoverColor(name)
    assert(buttonColors[name], "no such button color:", name)
    return buttonColors[name]["hover"]
end

function AF.AddButtonColor(name, normalColor, hoverColor)
    buttonColors[name] = {["normal"] = normalColor, ["hover"] = hoverColor}
end

function AF.AddButtonColors(t)
    for k, v in pairs(t) do
        AF.AddColor(k, v.normalColor, v.hoverColor)
    end
end