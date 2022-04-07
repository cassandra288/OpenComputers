local button = require("ButtonLib")


local module = {}


local modules = {}


local function ReactorToggle()
    modules.man.ToggleReactor()
end

local function AutopilotToggle()
    modules.man.settings.manager = not modules.man.settings.manager
end

local function HeatUp()
    modules.man.settings.heat_thresh = modules.man.settings.heat_thresh + 1

    if modules.man.settings.heat_thresh > 100 then
        modules.man.settings.heat_thresh = 100
    end
end

local function HeatDown()
    modules.man.settings.heat_thresh = modules.man.settings.heat_thresh - 1

    if modules.man.settings.heat_thresh < 0 then
        modules.man.settings.heat_thresh = 0
    end
end

local function HeatToggle()
    modules.man.settings.heat_thresh_on = not modules.man.settings.heat_thresh_on
end

local function WarnUp()
    modules.man.settings.heat_warn_thresh = modules.man.settings.heat_warn_thresh + 1

    if modules.man.settings.heat_warn_thresh > 100 then
        modules.man.settings.heat_warn_thresh = 100
    end
end

local function WarnDown()
    modules.man.settings.heat_warn_thresh = modules.man.settings.heat_warn_thresh - 1

    if modules.man.settings.heat_warn_thresh < 0 then
        modules.man.settings.heat_warn_thresh = 0
    end
end

local function WarnToggle()
    modules.man.settings.heat_warn_on = not modules.man.settings.heat_warn_on
end

local function PowerUp()
    modules.man.settings.power_thresh = modules.man.settings.power_thresh + 1

    if modules.man.settings.power_thresh > 100 then
        modules.man.settings.power_thresh = 100
    end
end

local function PowerDown()
    modules.man.settings.power_thresh = modules.man.settings.power_thresh - 1

    if modules.man.settings.power_thresh < 0 then
        modules.man.settings.power_thresh = 0
    end
end

local function PowerToggle()
    modules.man.settings.power_thresh_on = not modules.man.settings.power_thresh_on
end


module.setup = function (mods)
    modules = mods

    button.Setup()

    button.AddButton("ReactorToggle", 151, 6, 156, 8, ReactorToggle)
    button.AddButton("AutopilotToggle", 141, 6, 150, 8, AutopilotToggle)
    button.AddButton("HeatUp", 95, 6, 99, 8, HeatUp)
    button.AddButton("HeatDown", 111, 6, 115, 8, HeatDown)
    button.AddButton("HeatToggle", 100, 6, 110, 8, HeatToggle)
    button.AddButton("WarnUp", 52, 6, 56, 8, WarnUp)
    button.AddButton("WarnDown", 66, 6, 70, 8, WarnDown)
    button.AddButton("WarnToggle", 57, 6, 65, 8, WarnToggle)
    button.AddButton("PowerUp", 5, 6, 9, 8, PowerUp)
    button.AddButton("PowerDown", 22, 6, 26, 8, PowerDown)
    button.AddButton("PowerToggle", 10, 6, 21, 8, PowerToggle)
end

module.shutdown = function ()
    button.Shutdown()
end


return module
