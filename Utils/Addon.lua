---@class AbstractFramework
local AF = _G.AbstractFramework

AF.REGISTERED_ADDONS = {}

local PATTERN = AF.isRetail and "\n%[Interface/AddOns/([^/]+)/" or "@Interface/AddOns/([^/]+)/"
local strmatch = string.gmatch
local debugstack, print, type = debugstack, print, type
local tinsert, tconcat = table.insert, table.concat
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local DevTools_Dump = DevTools_Dump

function AF.GetAddon()
    for addon in strmatch(debugstack(2), PATTERN) do
        if AF.REGISTERED_ADDONS[addon] then
            return addon, AF.REGISTERED_ADDONS[addon]
        end
    end
    return nil
end

local function GetPrefix()
    local addon, alias = AF.GetAddon()
    if addon then
        return AF.WrapTextInColor("[" .. (type(alias) == "string" and alias or addon) .. "]", addon)
    else
        return AF.WrapTextInColor("[AF]", "accent")
    end
end

function AF.Debug(arg, ...)
    if AFConfig.debugMode then
        if type(arg) == "string" or type(arg) == "number" then
            print(GetPrefix(), arg, ...)
        elseif type(arg) == "table" then
            if IsAddOnLoaded("TableExplorer") then
                texplore(arg) -- kinda bug
            else
                DevTools_Dump(arg)
            end
        elseif type(arg) == "function" then
            arg(...)
        elseif arg == nil then
            return true
        end
    end
end

function AF.Print(msg)
    print(GetPrefix(), msg)
end

function AF.Printf(msg, ...)
    AF.Print(msg:format(...))
end

function AF.PrintStack()
    local stack = {}
    for addon in strmatch(debugstack(2), PATTERN) do
        tinsert(stack, addon)
    end
    print(AF.WrapTextInColor("[AF] ", "accent") .. tconcat(stack, "\n-> "))
end

function AF.RegisterAddon(addonFolderName, alias)
    AF.REGISTERED_ADDONS[addonFolderName] = alias or true
end