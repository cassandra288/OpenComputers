local Core = require("ProgramCore")
local Button = require("ButtonLib")


local modules = {}
modules.UI = require("Files/AtomMan/UIRender")
modules.Man = require("Files/AtomMan/ReactorManager")


modules.UI.Setup()
Button.Setup()

Core.targetTPS = 2


local function ReactorToggle()
    modules.Man.ToggleReactor()
end
Button.AddButton("ReactorToggle", 151, 6, 156, 8, ReactorToggle)

local function AutopilotToggle()
    modules.Man.settings.manager = not modules.Man.settings.manager
end
Button.AddButton("AutopilotToggle", 141, 6, 150, 8, AutopilotToggle)

local function HeatUp()
    modules.Man.settings.heat_thresh = modules.Man.settings.heat_thresh + 1

    if modules.Man.settings.heat_thresh > 100 then
        modules.Man.settings.heat_thresh = 100
    end
end
Button.AddButton("HeatUp", 95, 6, 99, 8, HeatUp)

local function HeatDown()
    modules.Man.settings.heat_thresh = modules.Man.settings.heat_thresh - 1

    if modules.Man.settings.heat_thresh < 0 then
        modules.Man.settings.heat_thresh = 0
    end
end
Button.AddButton("HeatDown", 111, 6, 115, 8, HeatDown)

local function HeatToggle()
    modules.Man.settings.heat_thresh_on = not modules.Man.settings.heat_thresh_on
end
Button.AddButton("HeatToggle", 100, 6, 110, 8, HeatToggle)

local function WarnUp()
    modules.Man.settings.heat_warn_thresh = modules.Man.settings.heat_warn_thresh + 1

    if modules.Man.settings.heat_warn_thresh > 100 then
        modules.Man.settings.heat_warn_thresh = 100
    end
end
Button.AddButton("WarnUp", 52, 6, 56, 8, WarnUp)

local function WarnDown()
    modules.Man.settings.heat_warn_thresh = modules.Man.settings.heat_warn_thresh - 1

    if modules.Man.settings.heat_warn_thresh < 0 then
        modules.Man.settings.heat_warn_thresh = 0
    end
end
Button.AddButton("WarnDown", 66, 6, 70, 8, WarnDown)

local function WarnToggle()
    modules.Man.settings.heat_warn_on = not modules.Man.settings.heat_warn_on
end
Button.AddButton("WarnToggle", 57, 6, 65, 8, WarnToggle)

local function PowerUp()
    modules.Man.settings.power_thresh = modules.Man.settings.power_thresh + 1

    if modules.Man.settings.power_thresh > 100 then
        modules.Man.settings.power_thresh = 100
    end
end
Button.AddButton("PowerUp", 5, 6, 9, 8, PowerUp)

local function PowerDown()
    modules.Man.settings.power_thresh = modules.Man.settings.power_thresh - 1

    if modules.Man.settings.power_thresh < 0 then
        modules.Man.settings.power_thresh = 0
    end
end
Button.AddButton("PowerDown", 22, 6, 26, 8, PowerDown)

local function PowerToggle()
    modules.Man.settings.power_thresh_on = not modules.Man.settings.power_thresh_on
end
Button.AddButton("PowerToggle", 10, 6, 21, 8, PowerToggle)


local function main()
    modules.Man.UpdateValues()
    modules.Man.ManageReactor()


    modules.UI.data.problem = modules.Man.values.problem
    
    modules.UI.data.reactor_on = modules.Man.values.isProcessing
    modules.UI.data.autopilot_on = modules.Man.settings.manager
    modules.UI.data.heat_thresh = modules.Man.settings.heat_thresh
    modules.UI.data.heat_thresh_on = modules.Man.settings.heat_thresh_on
    modules.UI.data.heat_warn = modules.Man.settings.heat_warn
    modules.UI.data.heat_warn_on = modules.Man.settings.heat_warn_on
    modules.UI.data.power_thresh = modules.Man.settings.power_thresh
    modules.UI.data.power_thresh_on = modules.Man.settings.power_thresh_on
    
    modules.UI.data.heat_buffer = modules.Man.values.heatLevel
    modules.UI.data.heat_buffer_max = modules.Man.values.maxHeatLevel
    modules.UI.data.heat_buffer_pcnt = modules.Man.values.heat_percent
    modules.UI.data.total_cooling = modules.Man.values.reactorCoolingRate
    modules.UI.data.total_heating = modules.Man.values.reactorProcessHeat - modules.Man.values.reactorCoolingRate
    modules.UI.data.net_heat = modules.Man.values.reactorProcessHeat
    
    modules.UI.data.pwr_buffer = modules.Man.values.energyStored
    modules.UI.data.pwr_buffer_max = modules.Man.values.max_energy
    modules.UI.data.pwr_buffer_pcnt = modules.Man.values.energy_percent
    modules.UI.data.pwr_fuel = modules.Man.values.process_time_left * modules.Man.values.reactorProcessPower
    modules.UI.data.pwr_fuel_max = modules.Man.values.fissionFuelTime * modules.Man.values.fissionFuelPower
    modules.UI.data.pwr_fuel_pcnt = modules.UI.data.pwr_fuel / modules.UI.data.pwr_fuel_max * 100
    modules.UI.data.reactor_size.x = modules.Man.values.lengthX
    modules.UI.data.reactor_size.y = modules.Man.values.lengthY
    modules.UI.data.reactor_size.z = modules.Man.values.lengthZ
    modules.UI.data.cell_count = modules.Man.values.numberOfCells
    modules.UI.data.pwr_gen_tick = modules.Man.values.reactorProcessPower
    
    modules.UI.data.fuel_name = modules.Man.values.fissionFuelName
    modules.UI.data.time_left_ticks = modules.Man.values.process_time_left
    modules.UI.data.time_left_percent = modules.Man.values.process_percent
    modules.UI.data.fuel_base_life = modules.Man.values.fissionFuelTime
    modules.UI.data.fuel_effective_life = modules.Man.values.reactorProcessTime
    modules.UI.data.fuel_base_power = modules.Man.values.fissionFuelPower
    modules.UI.data.fuel_base_heat = modules.Man.values.fissionFuelHeat

    modules.UI.DrawFrame()


    --Core.running = false
end
Core.Run(main)


Button.Shutdown()
modules.UI.Shutdown()
