---@class AbstractFramework
local AF = _G.AbstractFramework

AF.L = setmetatable({

}, {
    __index = function(self, Key)
        if (Key ~= nil) then
            rawset(self, Key, Key)
            return Key
        end
    end
})

local L = AF.L

if LOCALE_zhCN then
    L["Undo"] = "撤消"
    L["Close this dialog to exit Edit Mode"] = "关闭此窗口以退出编辑模式"
    L["Left Drag"] = "左键拖动"
    L["Right Click"] = "右键单击"
    L["Mouse Wheel"] = "鼠标滚轮"
    L["move frames"] = "移动框体"
    L["toggle Position Adjustment dialog"] = "打开/关闭微调窗口"
    L["move frames vertically"] = "垂直方向移动框体"
    L["move frames horizontally"] = "水平方向移动框体"
    L["hide mover"] = "隐藏移动框"
    L["Right Click the Anchor button to lock the anchor"] = "右键单击锚点按钮以锁定锚点"
    L["Anchor Locked"] = "锚点已锁定"
    L["%d seconds"] = "%d秒"
    L["%d minutes"] = "%d分钟"
    L["%d hours"] = "%d小时"
    L["%d days"] = "%d天"
    L["%d weeks"] = "%d周"
    L["%d months"] = "%d月"
    L["%d years"] = "%d年"
    L["%s ago"] = "%s前"
    L["%s from now"] = "%s后"
    L["just now"] = "刚刚"
end