---@class AbstractFramework
local AF = _G.AbstractFramework

AF.L = setmetatable({
    ["AF_VERSION_REQUIRED"] = "AbstractFramework Version Mismatch\n%s requires: %s or higher\nCurrent: %s",

    ["Blizzard"] = string.gsub(_G.SLASH_TEXTTOSPEECH_BLIZZARD, "^%l", strupper),
    -- ["Shift Click"] = _G.WARDROBE_SHORTCUTS_TUTORIAL_2:match("%[(.+)%]"),
    -- ["Ctrl Click"] = _G.WARDROBE_SHORTCUTS_TUTORIAL_2:match("%[(.+)%]"):gsub("Shift", "Ctrl"),
    -- ["Alt Click"] = _G.WARDROBE_SHORTCUTS_TUTORIAL_2:match("%[(.+)%]"):gsub("Shift", "Alt"),
    ["WIP"] = "Work In Progress",
    ["Loading..."] = _G.SEARCH_LOADING_TEXT,

    ["TANK"] = _G.TANK,
    ["HEALER"] = _G.HEALER,
    ["DAMAGER"] = _G.DAMAGER,

    ["TOPLEFT"] = "Top Left",
    ["TOPRIGHT"] = "Top Right",
    ["BOTTOMLEFT"] = "Bottom Left",
    ["BOTTOMRIGHT"] = "Bottom Right",
    ["CENTER"] = "Center",
    ["LEFT"] = "Left",
    ["RIGHT"] = "Right",
    ["TOP"] = "Top",
    ["BOTTOM"] = "Bottom",

    ["Edit Mode"] = _G.HUD_EDIT_MODE_MENU,
    ["Reload UI"] = _G.RELOADUI,
    ["Reset"] = _G.RESET,

    ["Options"] = _G.GAMEMENU_OPTIONS,
    ["Settings"] = _G.SETTINGS,

    ["Home"] = _G.HOME,
    ["Next"] = _G.NEXT,
    ["Prev"] = _G.PREV,

    ["Okay"] = _G.OKAY,
    ["Cancel"] = _G.CANCEL,
    ["None"] = _G.NONE,
    ["All"] = _G.ALL,
    ["Yes"] = _G.YES,
    ["No"] = _G.NO,
    ["Apply"] = _G.APPLY,
    -- ["Got It"] = _G.HELP_TIP_BUTTON_GOT_IT,

    ["Delete"] = _G.DELETE,
    ["Rename"] = _G.BATTLE_PET_RENAME,
    ["Create"] = _G.CALENDAR_CREATE,
    ["New"] = _G.NEW,
    ["Save"] = _G.SAVE,
    ["Apply"] = _G.APPLY,
    ["Edit"] = _G.EDIT,

    ["Default"] = _G.DEFAULT,
    ["Custom"] = _G.CUSTOM,
    ["Class"] = _G.CLASS,

    ["High"] = _G.HIGH,
    ["Medium"] = _G.LOAD_MEDIUM,
    ["Low"] = _G.LOW,

    ["Current"] = _G.REFORGE_CURRENT,
    ["Total"] = _G.TOTAL,
    ["Percentage"] = _G.STATUS_TEXT_PERCENT,
    ["Progress"] = _G.PVP_PROGRESS_REWARDS_HEADER,

    ["Completed"] = _G.ACCOUNT_COMPLETED_QUEST_NOTICE_LABEL,
    ["Incomplete"] = _G.INCOMPLETE,

    ["Level"] = _G.LEVEL,
    ["Honor Level"] = _G.LFG_LIST_HONOR_LEVEL_INSTR_SHORT,
    ["Reputation"] = _G.REPUTATION,
    ["Rested"] = _G.TUTORIAL_TITLE26,

    ["Name"] = _G.NAME,
    ["Description"] = _G.QUEST_DESCRIPTION,

    ["Auto"] = _G.SELF_CAST_AUTO,

    ["Sort"] = _G.STABLE_FILTER_BUTTON_LABEL,
    ["Sort By"] = _G.STABLE_FILTER_SORT_BY_LABEL,
}, {
    __index = function(self, Key)
        if (Key ~= nil) then
            rawset(self, Key, Key)
            return Key
        end
    end
})

if AF.L.DAMAGER == "Damage" then
    AF.L.DAMAGER = "Damager"
end