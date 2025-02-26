---@class AbstractFramework
local AF = _G.AbstractFramework

AF.REGISTERED_ADDONS = {}

local PATTERN = AF.isRetail and "\n%[Interface/AddOns/([^/]+)/" or "@Interface/AddOns/([^/]+)/"
local strmatch = string.gmatch
local debugstack, print, type = debugstack, print, type
local tinsert, tconcat = table.insert, table.concat

function AF.GetAddon()
    for addon in strmatch(debugstack(2), PATTERN) do
        if AF.REGISTERED_ADDONS[addon] then
            return addon, AF.REGISTERED_ADDONS[addon]
        end
    end
    return nil
end

function AF.Print(msg)
    local addon, alias = AF.GetAddon()
    if addon then
        print(AF.WrapTextInColor("[" .. (type(alias) == "string" and alias or addon) .. "] ", addon) .. msg)
    else
        print(AF.WrapTextInColor("[AF] ", "accent") .. msg)
    end
end

function AF.Printf(msg, ...)
    AF.Print(msg:format(...))
end

function AF.PrintStack()
    local stack = {}
    for addon in strmatch(debugstack(2), PATTERN) do
        tinsert(stack, addon)
    end
    print(AF.WrapTextInColor("[AF] ", "accent") .. tconcat(stack, " -> "))
end

function AF.RegisterAddon(addonFolderName, alias)
    AF.REGISTERED_ADDONS[addonFolderName] = alias or true
end