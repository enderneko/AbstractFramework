---@class AbstractFramework
---@field L AF_Locale
local AF = select(2, ...)

---@class AF_Locale
---@field ["%d days"] string
---@field ["%d hours"] string
---@field ["%d minutes"] string
---@field ["%d months"] string
---@field ["%d seconds"] string
---@field ["%d weeks"] string
---@field ["%d years"] string
---@field ["%s ago"] string
---@field ["%s from now"] string
---@field ["A UI reload is required"] string
---@field ["A UI reload is required\nDo it now?"] string
---@field ["About"] string
---@field ["Accent Color"] string
---@field ["Addon Default"] string
---@field ["AF_VERSION_REQUIRED"] string
---@field ["AFK"] string
---@field ["After"] string
---@field ["All"] string
---@field ["Alpha"] string
---@field ["Also deletes sub-items"] string
---@field ["Alt Click"] string
---@field ["Always Hide"] string
---@field ["Always Show"] string
---@field ["Anchor Locked"] string
---@field ["Anchor Point"] string
---@field ["Apply"] string
---@field ["Arrangement"] string
---@field ["Ascending"] string
---@field ["Author"] string
---@field ["Authors"] string
---@field ["Auto"] string
---@field ["Background Color"] string
---@field ["Before"] string
---@field ["Bleed"] string
---@field ["Blizzard"] string
---@field ["Border Color"] string
---@field ["Border"] string
---@field ["Bottom to Top, then Left"] string
---@field ["Bottom to Top, then Right"] string
---@field ["Bottom to Top"] string
---@field ["BOTTOM"] string
---@field ["BOTTOMLEFT"] string
---@field ["BOTTOMRIGHT"] string
---@field ["Buff"] string
---@field ["Buffs"] string
---@field ["Button"] string
---@field ["Cancel"] string
---@field ["CENTER"] string
---@field ["Changelog"] string
---@field ["Changelogs"] string
---@field ["Class"] string
---@field ["Close this dialog to exit Edit Mode"] string
---@field ["Color"] string
---@field ["Colors"] string
---@field ["Completed"] string
---@field ["Config"] string
---@field ["Configs"] string
---@field ["Confirm deletion?"] string
---@field ["Contributors"] string
---@field ["Copy"] string
---@field ["Cosine"] string
---@field ["Create"] string
---@field ["Ctrl Click"] string
---@field ["Cubic"] string
---@field ["Current"] string
---@field ["Curse"] string
---@field ["Custom"] string
---@field ["DAMAGER"] string
---@field ["Day"] string
---@field ["Dead"] string
---@field ["DEAD"] string
---@field ["Debuff"] string
---@field ["Debuffs"] string
---@field ["Default"] string
---@field ["Delete"] string
---@field ["Descending"] string
---@field ["Description"] string
---@field ["Disable"] string
---@field ["Disabled"] string
---@field ["Disease"] string
---@field ["Displayed Per Column"] string
---@field ["Displayed Per Line"] string
---@field ["Displayed Per Row"] string
---@field ["Down"] string
---@field ["Drag to reorder"] string
---@field ["Edit Mode"] string
---@field ["Edit"] string
---@field ["Enable"] string
---@field ["Enabled"] string
---@field ["Export"] string
---@field ["Feedback & Suggestions"] string
---@field ["Fill"] string
---@field ["Font Size"] string
---@field ["Font"] string
---@field ["Fonts"] string
---@field ["Format"] string
---@field ["Frame Level"] string
---@field ["Frame Strata"] string
---@field ["From"] string
---@field ["General"] string
---@field ["Ghost"] string
---@field ["GHOST"] string
---@field ["Got It"] string
---@field ["Gradient"] string
---@field ["HEALER"] string
---@field ["Height"] string
---@field ["hide mover"] string
---@field ["High"] string
---@field ["Home"] string
---@field ["Honor Level"] string
---@field ["Horizontal"] string
---@field ["Hour"] string
---@field ["Icon"] string
---@field ["Icons"] string
---@field ["Import & Export"] string
---@field ["Import"] string
---@field ["Incomplete"] string
---@field ["Index"] string
---@field ["just now"] string
---@field ["Left Click"] string
---@field ["Left Drag"] string
---@field ["Left to Right, then Down"] string
---@field ["Left to Right, then Up"] string
---@field ["Left to Right"] string
---@field ["Left-click: "] string
---@field ["Left-drag: "] string
---@field ["Left"] string
---@field ["LEFT"] string
---@field ["Length"] string
---@field ["Level"] string
---@field ["Linear"] string
---@field ["Link"] string
---@field ["Links"] string
---@field ["Loading..."] string
---@field ["Low"] string
---@field ["Magic"] string
---@field ["Margin"] string
---@field ["Max Columns"] string
---@field ["Max Displayed"] string
---@field ["Max Lines"] string
---@field ["Max Rows"] string
---@field ["Medium"] string
---@field ["Middle Click"] string
---@field ["Middle-click: "] string
---@field ["Minute"] string
---@field ["Module"] string
---@field ["Modules"] string
---@field ["Mono Outline"] string
---@field ["Mono Thick"] string
---@field ["Monochrome"] string
---@field ["Month"] string
---@field ["Mouse wheel click: "] string
---@field ["Mouse wheel click"] string
---@field ["Mouse wheel: "] string
---@field ["Mouse Wheel"] string
---@field ["move frames horizontally"] string
---@field ["move frames vertically"] string
---@field ["move frames"] string
---@field ["Name"] string
---@field ["New version (%s) available! Please visit %s to get the latest version."] string
---@field ["New version (%s) available!"] string
---@field ["New"] string
---@field ["Next"] string
---@field ["No"] string
---@field ["None"] string
---@field ["Normal"] string
---@field ["Offline"] string
---@field ["OFFLINE"] string
---@field ["Offset"] string
---@field ["Okay"] string
---@field ["Option"] string
---@field ["Options"] string
---@field ["Orientation"] string
---@field ["Outline"] string
---@field ["Overlay"] string
---@field ["Padding"] string
---@field ["Parent"] string
---@field ["Paste"] string
---@field ["Path"] string
---@field ["Percentage"] string
---@field ["Poison"] string
---@field ["Popups"] string
---@field ["Position"] string
---@field ["Prev"] string
---@field ["Private Auras"] string
---@field ["Profile"] string
---@field ["Profiles"] string
---@field ["Progress"] string
---@field ["Relative Point"] string
---@field ["Relative To"] string
---@field ["Reload UI"] string
---@field ["Remaining"] string
---@field ["Rename"] string
---@field ["Reputation"] string
---@field ["Reset all settings"] string
---@field ["Reset to default settings?"] string
---@field ["Reset"] string
---@field ["Rested"] string
---@field ["Right Click the Anchor button to lock the anchor"] string
---@field ["Right Click the popup to dismiss"] string
---@field ["Right Click"] string
---@field ["Right Drag"] string
---@field ["Right to Left, then Down"] string
---@field ["Right to Left, then Up"] string
---@field ["Right to Left"] string
---@field ["Right-click: "] string
---@field ["Right-drag: "] string
---@field ["Right"] string
---@field ["RIGHT"] string
---@field ["Save"] string
---@field ["Scale"] string
---@field ["sec"] string
---@field ["Second"] string
---@field ["Setting"] string
---@field ["Settings"] string
---@field ["Shadow"] string
---@field ["Shift Click"] string
---@field ["Size"] string
---@field ["Slash Commands"] string
---@field ["Solid"] string
---@field ["Sort By"] string
---@field ["Sort Direction"] string
---@field ["Sort Method"] string
---@field ["Sort"] string
---@field ["Spacing"] string
---@field ["Step"] string
---@field ["Style"] string
---@field ["TANK"] string
---@field ["Text Color"] string
---@field ["Text"] string
---@field ["Texts"] string
---@field ["Texture"] string
---@field ["Thick Outline"] string
---@field ["Thickness"] string
---@field ["Time"] string
---@field ["Timezone"] string
---@field ["Tip"] string
---@field ["Tips"] string
---@field ["Title"] string
---@field ["To"] string
---@field ["toggle Position Adjustment dialog"] string
---@field ["Top to Bottom, then Left"] string
---@field ["Top to Bottom, then Right"] string
---@field ["Top to Bottom"] string
---@field ["TOP"] string
---@field ["TOPLEFT"] string
---@field ["TOPRIGHT"] string
---@field ["Total"] string
---@field ["Translators"] string
---@field ["Type"] string
---@field ["Undo"] string
---@field ["Up"] string
---@field ["Version"] string
---@field ["Vertical"] string
---@field ["Weekday"] string
---@field ["Width"] string
---@field ["WIP"] string
---@field ["X Offset"] string
---@field ["X Spacing"] string
---@field ["Y Offset"] string
---@field ["Y Spacing"] string
---@field ["Year"] string
---@field ["Yes"] string

---@class AF_Locale
AF.L = setmetatable({
    ["AF_VERSION_REQUIRED"] = "AbstractFramework Version Mismatch\n%s requires: %s or higher\nCurrent: %s",

    ["Blizzard"] = string.gsub(_G.SLASH_TEXTTOSPEECH_BLIZZARD, "^%l", strupper),
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

    -- ["Edit Mode"] = _G.HUD_EDIT_MODE_MENU,
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
    ["Type"] = _G.TYPE,

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

-- ["Shift Click"] = _G.WARDROBE_SHORTCUTS_TUTORIAL_2:match("%[(.+)%]"),
-- ["Ctrl Click"] = _G.WARDROBE_SHORTCUTS_TUTORIAL_2:match("%[(.+)%]"):gsub("Shift", "Ctrl"),
-- ["Alt Click"] = _G.WARDROBE_SHORTCUTS_TUTORIAL_2:match("%[(.+)%]"):gsub("Shift", "Alt"),