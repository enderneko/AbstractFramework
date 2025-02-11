---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- get icon
---------------------------------------------------------------------
---@param icon string fileName
---@param addon? string addonFolderName
---@return string iconPath
function AF.GetIcon(icon, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Icons\\" .. icon
    else
        return "Interface\\AddOns\\AbstractFramework\\Media\\Icons\\" .. icon
    end
end

---@param icon string fileName
---@param addon? string addonFolderName
---@return string iconString "|T..:0|t" escape sequence
function AF.GetIconString(icon, addon)
    return "|T" .. AF.GetIcon(icon, addon) .. ":0|t"
end

---@param iconPath string
---@param size? number
---@return string iconString "|T..:0|t" escape sequence
function AF.EscapeIcon(iconPath, size)
    return format("|T%s:%d|t", icon, size or 0)
end

---------------------------------------------------------------------
-- get texture
---------------------------------------------------------------------
---@param texture string fileName
---@param addon? string addonFolderName
---@return string texturePath
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
---@return string plainTexturePath
function AF.GetPlainTexture()
    return "Interface\\AddOns\\AbstractFramework\\Media\\Textures\\White"
end

---------------------------------------------------------------------
-- get empty texture
---------------------------------------------------------------------
---@return string emptyTexturePath
function AF.GetEmptyTexture()
    return "Interface\\AddOns\\AbstractFramework\\Media\\Textures\\Empty"
end

---------------------------------------------------------------------
-- get sound
---------------------------------------------------------------------
---@param sound string fileName
---@param addon? string addonFolderName
---@return string soundPath
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
---@return boolean willPlay
---@return number soundHandle
function AF.PlaySound(sound, addon, channel)
    return PlaySoundFile(AF.GetSound(sound, addon), channel)
end

---------------------------------------------------------------------
-- get fonts
---------------------------------------------------------------------
---@param font string fileName
---@param addon? string addonFolderName
---@return string fontPath
function AF.GetFont(font, addon)
    if addon then
        return "Interface\\AddOns\\" .. addon .. "\\Media\\Fonts\\" .. font .. ".ttf"
    else
        return "Interface\\AddOns\\AbstractFramework\\Media\\Fonts\\" .. font .. ".ttf"
    end
end