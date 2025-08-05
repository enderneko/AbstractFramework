---@class AbstractFramework
local AF = _G.AbstractFramework

AF.L = setmetatable({
    ["WIP"] = "Work In Progress",
    ["TANK"] = _G["TANK"],
    ["HEALER"] = _G["HEALER"],
    ["DAMAGER"] = _G["DAMAGER"],
    ["TOPLEFT"] = "Top Left",
    ["TOPRIGHT"] = "Top Right",
    ["BOTTOMLEFT"] = "Bottom Left",
    ["BOTTOMRIGHT"] = "Bottom Right",
    ["CENTER"] = "Center",
    ["LEFT"] = "Left",
    ["RIGHT"] = "Right",
    ["TOP"] = "Top",
    ["BOTTOM"] = "Bottom",
}, {
    __index = function(self, Key)
        if (Key ~= nil) then
            rawset(self, Key, Key)
            return Key
        end
    end
})

local L = AF.L

if L.DAMAGER == "Damage" then
    L.DAMAGER = "Damager"
end

if LOCALE_zhCN then
    L["%d days"] = "%d天"
    L["%d hours"] = "%d小时"
    L["%d minutes"] = "%d分钟"
    L["%d months"] = "%d月"
    L["%d seconds"] = "%d秒"
    L["%d weeks"] = "%d周"
    L["%d years"] = "%d年"
    L["%s ago"] = "%s前"
    L["%s from now"] = "%s后"
    L["just now"] = "刚刚"

    L["TOPLEFT"] = "左上"
    L["TOPRIGHT"] = "右上"
    L["BOTTOMLEFT"] = "左下"
    L["BOTTOMRIGHT"] = "右下"
    L["TOP"] = "上"
    L["BOTTOM"] = "下"
    L["LEFT"] = "左"
    L["RIGHT"] = "右"
    L["CENTER"] = "中"

    L["Left to Right"] = "从左到右"
    L["Right to Left"] = "从右到左"
    L["Top to Bottom"] = "从上到下"
    L["Bottom to Top"] = "从下到上"
    L["Left to Right then Top"] = "从左到右再到上"
    L["Left to Right then Bottom"] = "从左到右再到下"
    L["Right to Left then Top"] = "从右到左再到上"
    L["Right to Left then Bottom"] = "从右到左再到下"
    L["Top to Bottom then Left"] = "从上到下再到左"
    L["Top to Bottom then Right"] = "从上到下再到右"
    L["Bottom to Top then Left"] = "从下到上再到左"
    L["Bottom to Top then Right"] = "从下到上再到右"

    L["A UI reload is required.\nDo it now?"] = "需要重载界面。\n现在重载么？"
    L["A UI reload is required"] = "需要重载界面"

    L["Anchor Locked"] = "锚点已锁定"
    L["hide mover"] = "隐藏移动框"
    L["move frames horizontally"] = "水平方向移动框体"
    L["move frames vertically"] = "垂直方向移动框体"
    L["move frames"] = "移动框体"
    L["toggle Position Adjustment dialog"] = "打开/关闭微调窗口"
    L["Close this dialog to exit Edit Mode"] = "关闭此窗口以退出编辑模式"
    L["Right Click the Anchor button to lock the anchor"] = "右键单击锚点按钮以锁定锚点"

    L["Accent Color"] = "强调色"

    L["Dead"] = "死亡"
    L["Ghost"] = "鬼魂"

    L["About"] = "关于"
    L["Author"] = "作者"
    L["Authors"] = "作者"
    L["Config"] = "设置"
    L["Feedback & Suggestions"] = "反馈与建议"
    L["Options"] = "选项"
    L["Tips"] = "提示"
    L["Translator"] = "翻译"
    L["Translators"] = "翻译"
    L["Undo"] = "撤消"
    L["Version"] = "版本"
    L["WIP"] = "正在开发中"

    L["Popups"] = "通知弹窗"
    L["Right Click the popup to dismiss"] = "右键单击可以关闭弹窗"

    L["Export"] = "导出"
    L["Import"] = "导入"
    L["Import & Export"] = "导入 & 导出"

    L["Left Click"] = "左键单击"
    L["Left Drag"] = "左键拖动"
    L["Middle Click"] = "中键单击"
    L["Mouse Wheel"] = "鼠标滚轮"
    L["Right Click"] = "右键单击"
    L["Right Drag"] = "右键拖动"
end

L["WIP_WITH_ICON"] = "|TInterface\\AddOns\\AbstractFramework\\Media\\Icons\\Fluent_Tools:16|t |cffffd300" .. L["WIP"] .. "|r"