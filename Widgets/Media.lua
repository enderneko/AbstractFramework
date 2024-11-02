---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- get icon
---------------------------------------------------------------------
function AF.GetIcon(icon, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Icons\\" .. icon
    else
        return "Interface\\AddOns\\AbstractFramework\\Media\\Icons\\" .. icon
    end
end

function AF.GetIconString(icon, addon)
    return "|T" .. AF.GetIcon(icon, addon) .. ":0|t"
end

---------------------------------------------------------------------
-- get texture
---------------------------------------------------------------------
function AF.GetTexture(texture, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Textures\\" .. texture
    else
        return "Interface\\AddOns\\AbstractFramework\\Media\\Textures\\" .. texture
    end
end

---------------------------------------------------------------------
-- get plain texture
---------------------------------------------------------------------
function AF.GetPlainTexture()
    return "Interface\\AddOns\\AbstractFramework\\Media\\Textures\\White"
end

---------------------------------------------------------------------
-- get empty texture
---------------------------------------------------------------------
function AF.GetEmptyTexture()
    return "Interface\\AddOns\\AbstractFramework\\Media\\Textures\\Empty"
end

---------------------------------------------------------------------
-- get sound
---------------------------------------------------------------------
function AF.GetSound(sound, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Sounds\\" .. sound .. ".ogg"
    else
        return "Interface\\AddOns\\AbstractFramework\\Media\\Sounds\\" .. sound .. ".ogg"
    end
end

---------------------------------------------------------------------
-- play sound
---------------------------------------------------------------------
---@param channel string Master|Music|SFX|Ambience|Dialog
function AF.PlaySound(sound, addon, channel)
    return PlaySoundFile(AF.GetSound(sound, addon), channel)
end

---------------------------------------------------------------------
-- get fonts
---------------------------------------------------------------------
function AF.GetFont(font, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Fonts\\" .. font .. ".ttf"
    else
        return "Interface\\AddOns\\AbstractFramework\\Media\\Fonts\\" .. font .. ".ttf"
    end
end