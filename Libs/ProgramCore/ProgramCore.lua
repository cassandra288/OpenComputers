local OS = require("os")


local ProgramLoop = {}

ProgramLoop.targetTPS = 20
ProgramLoop.running = true
ProgramLoop.delta = 0

local function Run(callback)
    ProgramLoop.running = true

    local prevTime = OS.time() * 1000/60/60
    local curTime
    while ProgramLoop.running do
        curTime = OS.time() * 1000/60/60
        delta = (curTime - prevTime) * 0.05

        callback()

        prevTime = curTime
        OS.sleep(1/ProgramLoop.targetTPS)
    end
end
ProgramLoop.Run = Run

return ProgramLoop
