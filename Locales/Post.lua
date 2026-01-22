-- Post-locale shared strings
local L = select(2, ...).L

-- Icon-prefixed WIP label using current locale string
L["WIP_WITH_ICON"] = "|TInterface\\AddOns\\AbstractFramework\\Media\\Icons\\Fluent_Tools:16|t |cffffd300" .. L["WIP"] .. "|r"
