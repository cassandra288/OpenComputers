GPU = require("component").gpu


--========== FUNCTION CACHES ==========--
local GpuGetResolution = GPU.getResolution


--========== VARIABLES ==========--
local ButtonData = {}
local width, height
local ScreenButtons = {}


--========== LOCAL FUNCTIONS ==========--
local function OnClickRelease(eventId, screenId, x, y, buttonId, player)
    local button, priority = nil, nil
    for btn, pri in pairs(ScreenButtons[(y - 1) * width + x]) do
        if priority == nil or pri > priority then
            button, priority = btn, pri
        end
    end

    if button and (ButtonData[button].button == 2 or ButtonData[button].button == math.floor(buttonId)) then
        ButtonData[button].callback(x, y)
    end
end


--========== LIBRARY FUNCTIONS ==========--
local function Setup()
    width, height = GpuGetResolution()
    
    for x = 1, width, 1 do
        for y = 1, height, 1 do
            local index = (y-1) * width + x
            ScreenButtons[index] = {}
        end
    end

    require("event").listen("drop", OnClickRelease)
end

local function Shutdown()
    require("event").ignore("drop", OnClickRelease)

    ButtonData = {}
    for x = 1, width, 1 do
        for y = 1, height, 1 do
            local index = (y-1) * width + x
            ScreenButtons[index] = {}
        end
    end
end

local function RemoveButton(name)
    if ButtonData[name] == nil then
        return 0
    end

    for x = ButtonData[name].x1, ButtonData[name].x2, 1 do
        for y = ButtonData[name].y1, ButtonData[name].y2, 1 do
            local index = (y-1) * width + x
            ScreenButtons[index][name] = nil
        end
    end

    ButtonData[name] = nil
end

local function AddButton(name, x1, y1, x2, y2, callback, button, priority)
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    if y1 > y2 then
        y1, y2 = y2, y1
    end

    button = button or 2
    priority = priority or 0

    if ButtonData[name] ~= nil then
        RemoveButton(name)
    end
    
    ButtonData[name] = {
        x1 = x1,
        x2 = x2,
        y1 = y1,
        y2 = y2,
        callback = callback,
        button = button
    }

    for x = x1, x2, 1 do
        for y = y1, y2, 1 do
            local index = (y-1) * width + x
            ScreenButtons[index] = ScreenButtons[index] or {}
            ScreenButtons[index][name] = priority
        end
    end
end


return {
    Setup = Setup,
    Shutdown = Shutdown,
    AddButton = AddButton,
    RemoveButton = RemoveButton
}