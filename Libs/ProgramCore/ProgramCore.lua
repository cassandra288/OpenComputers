local OS = require("os")
local event = require("event")


local ProgramLoop = {}

ProgramLoop.targetTPS = 20
ProgramLoop.running = true
ProgramLoop.delta = 0

ProgramLoop.callbacks = {}
ProgramLoop.callbacks.touch = {}
ProgramLoop.callbacks.drag = {}
ProgramLoop.callbacks.drop = {}
ProgramLoop.callbacks.key_down = {}
ProgramLoop.callbacks.key_up = {}


local function AddCallbacks(eventID)
    for _, v in ipairs(ProgramLoop.callbacks[eventID]) do
        event.listen(eventID, v)
    end
end

local function RemoveCallbacks(eventID)
    for _, v in ipairs(ProgramLoop.callbacks[eventID]) do
        event.ignore(eventID, v)
    end
end


ProgramLoop.Run = function (callback)
    ProgramLoop.running = true

    OS.sleep(0.5)

    AddCallbacks("touch")
    AddCallbacks("drag")
    AddCallbacks("drop")
    AddCallbacks("key_down")
    AddCallbacks("key_up")

    local prevTime = OS.time() * 1000/60/60
    local curTime
    while ProgramLoop.running do
        curTime = OS.time() * 1000/60/60
        delta = (curTime - prevTime) * 0.05

        callback()

        prevTime = curTime
        OS.sleep(1/ProgramLoop.targetTPS)
    end

    RemoveCallbacks("touch")
    RemoveCallbacks("drag")
    RemoveCallbacks("drop")
    RemoveCallbacks("key_down")
    RemoveCallbacks("key_up")
end

return ProgramLoop
