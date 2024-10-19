---@class AbstractWidgets
local AW = _G.AbstractWidgets

---------------------------------------------------------------------
-- get icon
---------------------------------------------------------------------
function AW.GetIcon(icon, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Icons\\" .. icon
    else
        return "Interface\\AddOns\\AbstractWidgets\\Media\\Icons\\" .. icon
    end
end

function AW.GetIconString(icon, addon)
    return "|T" .. AW.GetIcon(icon, addon) .. ":0|t"
end

---------------------------------------------------------------------
-- get texture
---------------------------------------------------------------------
function AW.GetTexture(texture, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Textures\\" .. texture
    else
        return "Interface\\AddOns\\AbstractWidgets\\Media\\Textures\\" .. texture
    end
end

---------------------------------------------------------------------
-- get plain texture
---------------------------------------------------------------------
function AW.GetPlainTexture()
    return "Interface\\AddOns\\AbstractWidgets\\Media\\Textures\\White"
end

---------------------------------------------------------------------
-- get empty texture
---------------------------------------------------------------------
function AW.GetEmptyTexture()
    return "Interface\\AddOns\\AbstractWidgets\\Media\\Textures\\Empty"
end

---------------------------------------------------------------------
-- get sound
---------------------------------------------------------------------
function AW.GetSound(sound, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Sounds\\" .. sound .. ".ogg"
    else
        return "Interface\\AddOns\\AbstractWidgets\\Media\\Sounds\\" .. sound .. ".ogg"
    end
end

---------------------------------------------------------------------
-- get font
---------------------------------------------------------------------
function AW.GetFont(font, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Fonts\\" .. font .. ".ttf"
    else
        return "Interface\\AddOns\\AbstractWidgets\\Media\\Fonts\\" .. font .. ".ttf"
    end
end