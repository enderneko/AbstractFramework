---@class AbstractFramework
local AF = _G.AbstractFramework

local function IsEmpty(t)
    for _ in pairs(t) do
        return false
    end
    return true
end

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
cleuDispatcher.events = {}
cleuDispatcher:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function DispatchCLEU(_, subevent, ...)
    if cleuDispatcher.events[subevent] then
        for fn, obj in pairs(cleuDispatcher.events[subevent]) do
            fn(obj, subevent, ...)
        end
    end
end

cleuDispatcher:SetScript("OnEvent", function()
    DispatchCLEU(CombatLogGetCurrentEventInfo())
end)

local function RegisterCLEU(obj, subevent, ...)
    if not cleuDispatcher.events[subevent] then
        cleuDispatcher.events[subevent] = {}
    end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        cleuDispatcher.events[subevent][fn] = obj
    end
end

local function UnregisterCLEU(obj, subevent)
    if not cleuDispatcher.events[subevent] then return end

    if subevent then
        for f, o in pairs(cleuDispatcher.events[subevent]) do
            if obj == o then
                cleuDispatcher.events[subevent][f] = nil
            end
        end
    else
        --! NOT IDEAL
        for _, sub in pairs(cleuDispatcher.events) do
            for f, o in pairs(sub) do
                if obj == o then
                    sub[f] = nil
                end
            end
        end

    end
end

---------------------------------------------------------------------
-- self
---------------------------------------------------------------------
local function RegisterEvent(self, event, ...)
    if not self.events[event] then self.events[event] = {} end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self.events[event][fn] = true
    end

    _RegisterEvent(self.eventHandler or self, event)
end

local function RegisterUnitEvent(self, event, unit, ...)
    if not self.events[event] then self.events[event] = {} end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self.events[event][fn] = true
    end

    if type(unit) == "table" then
        _RegisterUnitEvent(self.eventHandler or self, event, unpack(unit))
    else
        _RegisterUnitEvent(self.eventHandler or self, event, unit)
    end
end

local function UnregisterEvent(self, event, ...)
    if not self.events[event] then return end

    if select("#", ...) == 0 then
        self.events[event] = nil
        _UnregisterEvent(self.eventHandler or self, event)
        return
    end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self.events[event][fn] = nil
    end

    -- check if isEmpty
    if IsEmpty(self.events[event]) then
        self.events[event] = nil
        _UnregisterEvent(self.eventHandler or self, event)
    end
end

local function UnregisterAllEvents(self)
    wipe(self.events)
    _UnregisterAllEvents(self.eventHandler or self)
end

---------------------------------------------------------------------
-- embeded
---------------------------------------------------------------------
local function RegisterEvent_Embeded(self, event, ...)
    if not self.eventHandler.events[event] then self.eventHandler.events[event] = {} end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self.eventHandler.events[event][fn] = true
    end

    _RegisterEvent(self.eventHandler, event)
end

local function RegisterUnitEvent_Embeded(self, event, unit, ...)
    if not self.eventHandler.events[event] then self.eventHandler.events[event] = {} end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self.eventHandler.events[event][fn] = true
    end

    if type(unit) == "table" then
        _RegisterUnitEvent(self.eventHandler, event, unpack(unit))
    else
        _RegisterUnitEvent(self.eventHandler, event, unit)
    end
end

local function UnregisterEvent_Embeded(self, event, ...)
    if not self.eventHandler.events[event] then return end

    if select("#", ...) == 0 then
        self.eventHandler.events[event] = nil
        _UnregisterEvent(self.eventHandler, event)
        return
    end

    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        self.eventHandler.events[event][fn] = nil
    end

    -- check if isEmpty
    if IsEmpty(self.eventHandler.events[event]) then
        self.eventHandler.events[event] = nil
        _UnregisterEvent(self.eventHandler, event)
    end
end

local function UnregisterAllEvents_Embeded(self)
    wipe(self.eventHandler.events)
    _UnregisterAllEvents(self.eventHandler)
end

---------------------------------------------------------------------
-- handle events
---------------------------------------------------------------------
local QUEUE_THRESHOLD = 1000000
local MAX_EVENTS_PER_TICK = 2000

local FIFOQueue = {}
FIFOQueue.__index = FIFOQueue

function FIFOQueue:new()
    local instance = {
        first = 1,
        last = 0,
        length = 0,
        threshold = QUEUE_THRESHOLD,
        queue = {},
    }
    setmetatable(instance, FIFOQueue)
    return instance
end

function FIFOQueue:push(value)
    self.length = self.length + 1
    self.last = self.last + 1
    self.queue[self.last] = value
end

function FIFOQueue:pop()
    if self.first > self.last then return end
    local value = self.queue[self.first]
    self.queue[self.first] = nil
    self.first = self.first + 1
    self.length = self.length - 1
    return value
end

function FIFOQueue:isEmpty()
    return self.first > self.last
end

function FIFOQueue:shrink()
    local newQueue = {}
    local newFirst = 1
    for i = self.first, self.last do
        newQueue[newFirst] = self.queue[i]
        newFirst = newFirst + 1
    end
    self.queue = newQueue
    self.first = 1
    self.last = newFirst - 1
end

function FIFOQueue:checkShrink()
    if self.first > self.threshold then
        FIFOQueue:shrink()
    end
end

---------------------------------------------------------------------
-- process events
---------------------------------------------------------------------
local function HandleEvent(obj, event, ...)
    if obj.events[event] then
        for fn in pairs(obj.events[event]) do
            fn(obj, event, ...)
        end
    end
end

-- local function CoroutineProcessEvents()
--     while true do
--         -- print("CoroutineProcessEvents", coroutine.running())
--         HandleEvent(coroutine.yield())
--     end
-- end
-- NOTE: poor performance
-- local sharedCoroutine = coroutine.wrap(CoroutineProcessEvents)

local eventQueue = FIFOQueue:new()
local eventsProcessed = 0
local before

local function ProcessEvents()
    before = eventQueue.length

    while eventQueue.length > 0 and eventsProcessed < MAX_EVENTS_PER_TICK do
        eventsProcessed = eventsProcessed + 1
        -- sharedCoroutine(AF.Unpack7(eventQueue:pop()))
        HandleEvent(AF.Unpack7(eventQueue:pop()))
    end

    if eventQueue.length > 0 then
        print(format("------------- START %s", GetTime()))
        print("Before:", before)
        print("Remains:", eventQueue.length)
        print(" ")
    end
end

local function PushEvent(obj, event, arg1, arg2, arg3, arg4, arg5)
    obj = obj.owner and obj.owner or obj
    eventQueue:push({obj, event, arg1, arg2, arg3, arg4, arg5})
end

local ticker, OnTick
OnTick = function()
    if eventQueue.first > eventQueue.threshold then
        ticker:Cancel()
        eventQueue:shrink()
        C_VoiceChat.SpeakText(0, "queue shrinked", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
        ticker = C_Timer.NewTicker(0, OnTick)
    else
        eventsProcessed = 0
        ProcessEvents()
    end
end
ticker = C_Timer.NewTicker(0, OnTick)

---------------------------------------------------------------------
-- add event handler
---------------------------------------------------------------------
---@param instantProcess boolean
function AF.AddEventHandler(obj, instantProcess)
    obj.RegisterCLEU = RegisterCLEU
    obj.UnregisterCLEU = UnregisterCLEU

    if not obj.GetObjectType then
        -- use embeded
        obj.RegisterEvent = RegisterEvent_Embeded
        obj.RegisterUnitEvent = RegisterUnitEvent_Embeded
        obj.UnregisterEvent = UnregisterEvent_Embeded
        obj.UnregisterAllEvents = UnregisterAllEvents_Embeded

        obj.eventHandler = CreateFrame("Frame")
        obj.eventHandler.events = {}

        obj.eventHandler:SetScript("OnEvent", function(self, event, ...)
            for fn in pairs(self.events[event]) do
                fn(obj, event, ...)
            end
        end)
    else
        obj.events = {}

        if not obj.RegisterEvent then
            -- text, texture ...
            obj.eventHandler = CreateFrame("Frame")
            obj.eventHandler.owner = obj
            if instantProcess then
                obj.eventHandler:SetScript("OnEvent", function(_, event, ...)
                    HandleEvent(obj, event, ...)
                end)
            else
                obj.eventHandler:SetScript("OnEvent", PushEvent)
            end
        else
            -- script region
            if instantProcess then
                obj:SetScript("OnEvent", function(_, event, ...)
                    HandleEvent(obj, event, ...)
                end)
            else
                obj:SetScript("OnEvent", PushEvent)
            end
        end

        obj.RegisterEvent = RegisterEvent
        obj.RegisterUnitEvent = RegisterUnitEvent
        obj.UnregisterEvent = UnregisterEvent
        obj.UnregisterAllEvents = UnregisterAllEvents
    end
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