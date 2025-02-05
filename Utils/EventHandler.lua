---@class AbstractFramework
local AF = _G.AbstractFramework

---------------------------------------------------------------------
-- base
---------------------------------------------------------------------
local sharedEventHandler = CreateFrame("Frame", "BFI_EVENT_HANDLER")
local _RegisterEvent = sharedEventHandler.RegisterEvent
local _RegisterUnitEvent = sharedEventHandler.RegisterUnitEvent
local _UnregisterEvent = sharedEventHandler.UnregisterEvent
local _UnregisterAllEvents = sharedEventHandler.UnregisterAllEvents


---------------------------------------------------------------------
-- CLEU
---------------------------------------------------------------------
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local cleuDispatcher = CreateFrame("Frame", "BFI_CLEU_HANDLER")
cleuDispatcher.eventFuncs = {}
cleuDispatcher:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function DispatchCLEU(_, subevent, ...)
    if cleuDispatcher.eventFuncs[subevent] then
        for fn, obj in pairs(cleuDispatcher.eventFuncs[subevent]) do
            fn(obj, subevent, ...)
        end
    end
end

cleuDispatcher:SetScript("OnEvent", function()
    DispatchCLEU(CombatLogGetCurrentEventInfo())
end)

local function RegisterCLEU(obj, subevent, ...)
    if not cleuDispatcher.eventFuncs[subevent] then
        cleuDispatcher.eventFuncs[subevent] = {}
    end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        cleuDispatcher.eventFuncs[subevent][fn] = obj
    end
end

local function UnregisterCLEU(obj, subevent)
    if not cleuDispatcher.eventFuncs[subevent] then return end

    if subevent then
        for f, o in pairs(cleuDispatcher.eventFuncs[subevent]) do
            if obj == o then
                cleuDispatcher.eventFuncs[subevent][f] = nil
            end
        end
    else
        --! NOT IDEAL
        for _, sub in pairs(cleuDispatcher.eventFuncs) do
            for f, o in pairs(sub) do
                if obj == o then
                    sub[f] = nil
                end
            end
        end

    end
end


---------------------------------------------------------------------
-- register / unregister events
---------------------------------------------------------------------
local function RegisterEvent(self, event, ...)
    if not self._eventHandler.eventFuncs[event] then self._eventHandler.eventFuncs[event] = {} end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self._eventHandler.eventFuncs[event][fn] = true
    end

    _RegisterEvent(self._eventHandler, event)
end

local function RegisterUnitEvent(self, event, unit, ...)
    if not self._eventHandler.eventFuncs[event] then self._eventHandler.eventFuncs[event] = {} end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self._eventHandler.eventFuncs[event][fn] = true
    end

    if type(unit) == "table" then
        _RegisterUnitEvent(self._eventHandler, event, unpack(unit))
    else
        _RegisterUnitEvent(self._eventHandler, event, unit)
    end
end

local function UnregisterEvent(self, event, ...)
    if not self._eventHandler.eventFuncs[event] then return end

    if select("#", ...) == 0 then
        self._eventHandler.eventFuncs[event] = nil
        _UnregisterEvent(self._eventHandler, event)
        return
    end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self._eventHandler.eventFuncs[event][fn] = nil
    end

    -- check if isEmpty
    if AF.IsEmpty(self._eventHandler.eventFuncs[event]) then
        self._eventHandler.eventFuncs[event] = nil
        _UnregisterEvent(self._eventHandler, event)
    end
end

local function UnregisterAllEvents(self)
    wipe(self._eventHandler.eventFuncs)
    _UnregisterAllEvents(self._eventHandler)
end


---------------------------------------------------------------------
-- process events
---------------------------------------------------------------------
local function HandleEvent(eventHandler, event, ...)
    -- if eventHandler.eventFuncs[event] then
        for fn in pairs(eventHandler.eventFuncs[event]) do
            fn(eventHandler.owner, event, ...)
        end
    -- end
end

-- local function CoroutineProcessEvents()
--     while true do
--         -- print("CoroutineProcessEvents", coroutine.running())
--         HandleEvent(coroutine.yield())
--     end
-- end
-- NOTE: poor performance
-- local sharedCoroutine = coroutine.wrap(CoroutineProcessEvents)

-- local eventQueue = AF.NewQueue()
-- local eventsProcessed = 0
-- local tickEventsNum = 0
-- local MAX_EVENTS_PER_TICK = 1000
-- local before

-- local function ProcessEvents()
--     -- before = eventQueue.length

--     while eventQueue.length > 0 and eventsProcessed < MAX_EVENTS_PER_TICK do
--         eventsProcessed = eventsProcessed + 1
--         -- sharedCoroutine(AF.Unpack7(eventQueue:pop()))
--         HandleEvent(AF.Unpack7(eventQueue:pop()))
--     end

--     -- if eventQueue.length > 0 then
--     --     print(format("------------- START %s", GetTime()))
--     --     print("Before:", before)
--     --     print("Remains:", eventQueue.length)
--     --     print(" ")
--     -- end
-- end

-- local function MergeEvent(obj, event, arg1, arg2, arg3, arg4, arg5)
--     if tickEventsNum <= MAX_EVENTS_PER_TICK then
--         tickEventsNum = tickEventsNum + 1
--         HandleEvent(obj.owner or obj, event, arg1, arg2, arg3, arg4, arg5)
--     else
--         eventQueue:push({obj.owner or obj, event, arg1, arg2, arg3, arg4, arg5})
--     end
-- end

-- local ticker, OnTick
-- OnTick = function()
--     tickEventsNum = 0

--     if eventQueue.first > eventQueue.threshold then
--         ticker:Cancel()
--         eventQueue:shrink()
--         C_VoiceChat.SpeakText(0, "queue shrinked", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
--         ticker = C_Timer.NewTicker(0, OnTick)
--     end

--     if eventQueue.length > 0 then
--         eventsProcessed = 0
--         ProcessEvents()
--     end
-- end
-- ticker = C_Timer.NewTicker(0, OnTick)


---------------------------------------------------------------------
-- add event handler
---------------------------------------------------------------------
function AF.AddEventHandler(obj)
    obj.RegisterCLEU = RegisterCLEU
    obj.UnregisterCLEU = UnregisterCLEU

    obj._eventHandler = CreateFrame("Frame")
    obj._eventHandler.owner = obj
    obj._eventHandler.eventFuncs = {}
    obj._eventHandler:SetScript("OnEvent", HandleEvent)

    obj.RegisterEvent = RegisterEvent
    obj.RegisterUnitEvent = RegisterUnitEvent
    obj.UnregisterEvent = UnregisterEvent
    obj.UnregisterAllEvents = UnregisterAllEvents
end


---------------------------------------------------------------------
-- add simple event handler for frame
---------------------------------------------------------------------
function AF.AddSimpleEventHandler(frame)
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
end