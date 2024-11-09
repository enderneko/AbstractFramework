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

local tremove = tremove
local tinsert = tinsert
local unpack = unpack

local function CoroutineEventHandler(obj, event, ...)
    for fn in pairs(obj.events[event]) do
        fn(obj, event, ...)
    end
end

local function CoroutineProcessEvents()
    while true do
        -- print("CoroutineProcessEvents", coroutine.running())
        CoroutineEventHandler(coroutine.yield())
    end
end

local sharedCoroutine = coroutine.wrap(CoroutineProcessEvents)
local eventQueue = {}
local eventQueueLength = 0
local maxEventsPerTick = 5
local eventInProgress = false

local function ResumeCoroutine()
    eventInProgress = true
    local eventsProcessed = 0

    while eventQueueLength > 0 and eventsProcessed < maxEventsPerTick do
        local eventData = tremove(eventQueue, 1)
        eventQueueLength = eventQueueLength - 1
        eventsProcessed = eventsProcessed + 1
        sharedCoroutine(unpack(eventData))
    end

    if eventQueueLength > 0 then
        -- TODO: remove
        print("ResumeCoroutine (next frame): ", eventQueueLength)
        C_VoiceChat.SpeakText(0, "ResumeCoroutine (next frame) " .. eventQueueLength, Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
        C_Timer.After(0, ResumeCoroutine)
    else
        eventInProgress = false
    end
end

-- local function ResumeCoroutine()
--     while #eventQueue > 0 do
--         local eventData = tremove(eventQueue, 1)
--         sharedCoroutine(unpack(eventData))
--     end
-- end

local function CoroutineOnEvent(obj, event, ...)
    obj = obj.owner and obj.owner or obj
    tinsert(eventQueue, {obj, event, ...})
    eventQueueLength = eventQueueLength + 1
    if not eventInProgress then
        ResumeCoroutine()
    end
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
-- add event handler
---------------------------------------------------------------------
function AF.AddEventHandler(obj)
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
            obj.eventHandler:SetScript("OnEvent", CoroutineOnEvent)
            obj.eventHandler.owner = obj
        else
            -- script region
            obj:SetScript("OnEvent", CoroutineOnEvent)
        end

        obj.RegisterEvent = RegisterEvent
        obj.RegisterUnitEvent = RegisterUnitEvent
        obj.UnregisterEvent = UnregisterEvent
        obj.UnregisterAllEvents = UnregisterAllEvents

        -- obj:SetScript("OnEvent", function(self, event, ...)
        --     for fn in pairs(self.events[event]) do
        --         fn(self, event, ...)
        --     end
        -- end)
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