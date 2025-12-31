---@class AbstractFramework
local AF = _G.AbstractFramework

local Comm = AF.Libs.Comm
local GetChannelName = GetChannelName
local JoinTemporaryChannel = JoinTemporaryChannel
local LeaveChannelByName = LeaveChannelByName
local InCombatLockdown = InCombatLockdown
local IsInGuild = IsInGuild
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local ChatFrame_RemoveChannel = ChatFrame_RemoveChannel

---------------------------------------------------------------------
-- register/unregister addon prefix
---------------------------------------------------------------------
---@param prefix string max 16 characters
---@param callback fun(data: any?, sender: string, channel: string)
function AF.RegisterComm(prefix, callback)
    local _self = AF.GetAddon() or "AF_COMM_SELF"
    Comm.RegisterComm(_self, prefix, function(prefix, encoded, channel, sender)
        local data = AF.Deserialize(encoded, true)
        callback(data, sender, channel)
    end)
end

---@param prefix string
function AF.UnregisterComm(prefix)
    local _self = AF.GetAddon() or "AF_COMM_SELF"
    Comm.UnregisterComm(_self, prefix)
end

---------------------------------------------------------------------
-- send addon message (whisper)
---------------------------------------------------------------------
---@param prefix string max 16 characters
---@param data any
---@param target string
---@param priority string "BULK", "NORMAL", "ALERT".
---@param callbackFn fun(callbackArg: any?, sentBytes: number, totalBytes: number, didSend: boolean)
---@param callbackArg any? any data you want to pass to the callback function
---@param isSerializedData boolean if true, data is already serialized
function AF.SendCommMessage_Whisper(prefix, data, target, priority, callbackFn, callbackArg, isSerializedData)
    local encoded = isSerializedData and data or AF.Serialize(data, true)
    Comm:SendCommMessage(prefix, encoded, "WHISPER", target, priority, callbackFn, callbackArg)
end

---------------------------------------------------------------------
-- send addon message (group)
---------------------------------------------------------------------
---@param prefix string max 16 characters
---@param data any
---@param priority string "BULK", "NORMAL", "ALERT".
---@param callbackFn fun(callbackArg: any?, sentBytes: number, totalBytes: number, didSend: boolean)
---@param callbackArg any? any data you want to pass to the callback function
---@param isSerializedData boolean if true, data is already serialized
function AF.SendCommMessage_Group(prefix, data, priority, callbackFn, callbackArg, isSerializedData)
    local channel
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        channel = "PARTY"
    end
    if not channel then
        AF.Debug(AF.GetColorStr("lightred") .. "SendCommMessage_Group, not in a group")
    else
        local encoded = isSerializedData and data or AF.Serialize(data, true)
        Comm:SendCommMessage(prefix, encoded, channel, nil, priority, callbackFn, callbackArg)
    end
end

---------------------------------------------------------------------
-- send addon message (guild)
---------------------------------------------------------------------
---@param prefix string max 16 characters
---@param data any
---@param isOfficer boolean if true, send to officer chat, otherwise guild chat
---@param priority string "BULK", "NORMAL", "ALERT".
---@param callbackFn fun(callbackArg: any?, sentBytes: number, totalBytes: number, didSend: boolean)
---@param callbackArg any? any data you want to pass to the callback function
---@param isSerializedData boolean if true, data is already serialized
function AF.SendCommMessage_Guild(prefix, data, isOfficer, priority, callbackFn, callbackArg, isSerializedData)
    if not IsInGuild() then
        AF.Debug(AF.GetColorStr("lightred") .. "SendCommMessage_Guild, not in a guild")
    else
        local encoded = isSerializedData and data or AF.Serialize(data, true)
        Comm:SendCommMessage(prefix, encoded, isOfficer and "OFFICER" or "GUILD", nil, priority, callbackFn, callbackArg)
    end
end

---------------------------------------------------------------------
-- send addon message (channel)
---------------------------------------------------------------------
---@param prefix string max 16 characters
---@param data any
---@param channelName string
---@param priority string "BULK", "NORMAL", "ALERT".
---@param callbackFn? fun(callbackArg: any?, sentBytes: number, totalBytes: number, didSend: boolean)
---@param callbackArg? any any data you want to pass to the callback function
---@param isSerializedData? boolean if true, data is already serialized
function AF.SendCommMessage_Channel(prefix, data, channelName, priority, callbackFn, callbackArg, isSerializedData)
    local channelId = GetChannelName(channelName)
    if channelId == 0 then
        AF.Debug(AF.GetColorStr("lightred") .. "SendCommMessage_Channel, channel not found: " .. channelName)
    else
        local encoded = isSerializedData and data or AF.Serialize(data, true)
        Comm:SendCommMessage(prefix, encoded, "CHANNEL", channelId, priority, callbackFn, callbackArg)
    end
end

---------------------------------------------------------------------
-- join temporary channel
---------------------------------------------------------------------
local registeredChannels = {
    -- [channelName] = id = (number)
}
AF.registeredChannels = registeredChannels

-- join
local function DoJoin(channelName)
    local channelID = GetChannelName(channelName)
    if channelID == 0 then
        JoinTemporaryChannel(channelName)
        C_Timer.After(1, function()
            DoJoin(channelName) -- check if joined
        end)
    elseif registeredChannels[channelName] ~= channelID then
        registeredChannels[channelName] = channelID
        AF.Fire("AF_JOIN_TEMP_CHANNEL", channelName, channelID)
        -- disable channel message
        for i = 1, 10 do
            if _G["ChatFrame" .. i] then
                ChatFrame_RemoveChannel(_G["ChatFrame" .. i], channelName)
            end
        end
    end
end

-- will fire AF_JOIN_TEMP_CHANNEL(channelName, channelID) when the channel is joined
---@param channelName string
---@param joinNow boolean if true, join the channel immediately; otherwise, wait for PLAYER_ENTERING_WORLD event
function AF.RegisterTemporaryChannel(channelName, joinNow)
    assert(type(channelName) == "string", "channelName must be a string")
    if not registeredChannels[channelName] or registeredChannels[channelName] == -1 then
        registeredChannels[channelName] = 0
    end
    if joinNow then
        DoJoin(channelName)
    end
end

-- leave
local function DoLeave(channelName)
    local channelID = GetChannelName(channelName)
    if channelID ~= 0 then
        LeaveChannelByName(channelName)
        C_Timer.After(1, function()
            DoLeave(channelName) -- check if left
        end)
    else
        registeredChannels[channelName] = nil
        AF.Fire("AF_LEAVE_TEMP_CHANNEL", channelName)
    end
end

-- will fire AF_LEAVE_TEMP_CHANNEL(channelName) when the channel is left
---@param channelName string
---@param leaveNow boolean if true, leave the channel immediately; otherwise, wait for PLAYER_ENTERING_WORLD event
function AF.UnregisterChannel(channelName, leaveNow)
    assert(type(channelName) == "string", "channelName must be a string")
    registeredChannels[channelName] = -1
    if leaveNow then
        DoLeave(channelName)
    end
end

local function CheckAllRegisteredChannels()
    if InCombatLockdown() then return end
    for name, id in pairs(registeredChannels) do
        if id == -1 then
            DoLeave(name)
        else
            DoJoin(name)
        end
    end
end

-- check all "registered" temp channels
AF.CreateBasicEventHandler(AF.GetDelayedInvoker(9, CheckAllRegisteredChannels), "PLAYER_ENTERING_WORLD")

---------------------------------------------------------------------
-- block ChatConfigFrame widgets interaction
---------------------------------------------------------------------
local blockedChannels = {}

local tip = CHAT_CONFIG_CHANNEL_SETTINGS_TITLE_WITH_DRAG_INSTRUCTIONS
tip = tip:gsub("（", "(")
tip = tip:gsub("）", ")")
tip = tip:match("%((.+)%)")

hooksecurefunc("ChatConfig_CreateCheckboxes", function(frame, checkBoxTable, checkBoxTemplate, title)
    local name = frame:GetName()
    if name == "ChatConfigChannelSettingsLeft" then
        for i = 1, #checkBoxTable do
            local checkBox = _G[name .. "Checkbox" .. i]
            if checkBoxTable[i].channelName and blockedChannels[checkBoxTable[i].channelName] then
                AF.ShowMask(checkBox, AF.WrapTextInColor(tip, "firebrick"))
                if not checkBox._dragHooked then
                    checkBox._dragHooked = true
                    AF.ClearPoints(checkBox.mask.text)
                    checkBox.mask.text:SetPoint("RIGHT", checkBox.CloseChannel, "LEFT", -5, 0)
                    checkBox.mask:RegisterForDrag("LeftButton")
                    checkBox.mask:SetScript("OnDragStart", function()
                        checkBox:GetScript("OnDragStart")(checkBox)
                    end)
                end
            else
                AF.HideMask(checkBox)
            end
        end
    end
end)

function AF.BlockChatConfigFrameInteractionForChannel(channelName)
    blockedChannels[channelName] = true
end

---------------------------------------------------------------------
-- send to chat
---------------------------------------------------------------------
local MSG_INTERVAL = 0.25
local MSG_MAX_LENGTH = 255

local SendChatMessage = C_ChatInfo.SendChatMessage
local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local min, max = math.min, math.max

local messageQueue = AF.NewQueue()
local chatTicker
local validChatTypes = {
    PARTY = true,
    RAID = true,
    RAID_WARNING = true,
    INSTANCE_CHAT = true,
    GUILD = true,
    OFFICER = true,
    WHISPER = true,
}

local function StartChatTicker()
    if chatTicker then return end
    chatTicker = C_Timer.NewTicker(MSG_INTERVAL, function()
        if messageQueue:isEmpty() then
            chatTicker:Cancel()
            chatTicker = nil
            return
        end
        local payload = messageQueue:pop()
        if payload then
            SendChatMessage(payload.text, payload.chatType, nil, payload.target)
        end
    end)
end

local function EnqueueLine(lineText, chatType, target)
    if AF.IsBlank(lineText) then return end

    lineText = lineText:gsub("||?T.-||?t", "")
    lineText = lineText:gsub("||?c%x%x%x%x%x%x%x%x(.-)||?r", "%1")
    lineText = lineText:gsub("||?cn[%w_]+:(.-)||?r", "%1")
    lineText = lineText:gsub("||?cnIQ%d:(.-)||?r", "%1")
    lineText = strtrim(lineText)

    local byteLen = #lineText
    if byteLen <= MSG_MAX_LENGTH then
        -- 整行可以发送
        messageQueue:push({text = lineText, chatType = chatType, target = target})
    else
        -- 需要分块，按字节数分割但避免截断 UTF-8 字符和英文单词
        local startByte = 1
        while startByte <= byteLen do
            local endByte = min(startByte + MSG_MAX_LENGTH - 1, byteLen)

            -- 检查是否在 UTF-8 字符中间
            if endByte < byteLen then
                local nextByte = lineText:byte(endByte + 1)
                -- 如果下一个字节是后续字节 [\128-\191]，说明当前位置在字符中间
                while endByte > startByte and nextByte and nextByte >= 128 and nextByte <= 191 do
                    endByte = endByte - 1
                    nextByte = lineText:byte(endByte + 1)
                end
            end

            -- 尝试在空白字符处分割，避免截断英文单词
            if endByte < byteLen then
                local originalEndByte = endByte
                local char = lineText:sub(endByte, endByte)
                local nextChar = lineText:sub(endByte + 1, endByte + 1)

                -- 如果当前位置和下一个位置都不是空白字符，尝试向前查找空白字符
                if not char:match("%s") and not nextChar:match("%s") then
                    local found = false
                    -- 向前最多查找 30 个字节（避免过度回退）
                    for i = endByte, max(startByte, endByte - 30), -1 do
                        local c = lineText:sub(i, i)
                        if c:match("%s") then
                            endByte = i
                            found = true
                            break
                        end
                    end
                    -- 如果没找到空白字符，保持原位置（避免单词过长导致无法分割）
                    if not found then
                        endByte = originalEndByte
                    end
                end
            end

            local chunk = lineText:sub(startByte, endByte)
            messageQueue:push({text = chunk, chatType = chatType, target = target})
            startByte = endByte + 1
        end
    end
end

---@param message string
---@param chatType "PARTY"|"RAID"|"RAID_WARNING"|"INSTANCE_CHAT"|"GUILD"|"OFFICER"|"WHISPER"
function AF.SendChatMessage(message, chatType, target)
    assert(not AF.IsBlank(message), "message cannot be blank")
    chatType = type(chatType) == "string" and chatType or "RAID"
    assert(validChatTypes[chatType], "invalid chatType: " .. chatType)

    if chatType == "RAID" then
        if IsInRaid() then
            -- ok
        elseif IsInGroup() then
            chatType = "PARTY"
        else
            return
        end
    end

    local lastPos = 1
    while true do
        local newLinePos = message:find("\n", lastPos, true)
        if newLinePos then
            EnqueueLine(message:sub(lastPos, newLinePos - 1), chatType, target)
            lastPos = newLinePos + 1
        else
            EnqueueLine(message:sub(lastPos), chatType, target)
            break
        end
    end

    messageQueue:checkShrink()
    StartChatTicker()
end