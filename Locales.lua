---@class AbstractWidgets
local AW = _G.AbstractWidgets

AW.L = setmetatable({

}, {
    __index = function(self, Key)
        if (Key ~= nil) then
            rawset(self, Key, Key)
            return Key
        end
    end
})

if LOCALE_zhCN then
    AW.L["Undo"] = "撤消"
    AW.L["Close this dialog to exit Edit Mode"] = "关闭此窗口以退出编辑模式"
    AW.L["Left Drag"] = "左键拖动"
    AW.L["Right Click"] = "右键单击"
    AW.L["Mouse Wheel"] = "鼠标滚轮"
    AW.L["move frames"] = "移动框体"
    AW.L["toggle Position Adjustment dialog"] = "打开/关闭微调窗口"
    AW.L["move frames vertically"] = "垂直方向移动框体"
    AW.L["move frames horizontally"] = "水平方向移动框体"
    AW.L["hide mover"] = "隐藏移动框"
    AW.L["Right Click the Anchor button to lock the anchor"] = "右键单击锚点按钮以锁定锚点"
    AW.L["Anchor Locked"] = "锚点已锁定"
end