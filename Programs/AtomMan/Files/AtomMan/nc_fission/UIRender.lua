gl = require("OpenTGL")


colors = {
    ["clear_color"] = 0x000000,

    ["ribbon_bg"] = 0x000000,
    ["ribbon_fg"] = 0xffffff,
    ["panel_select"] = 0xbbbb00,

    ["section_bg"] = 0x898989,
    ["section_fg"] = 0xffffff,
    ["controls_btn_on"] = 0x00ff00,
    ["controls_btn_off"] = 0xff0000,
    ["controls_thresh"] = 0xa0a0a0,

    ["bar_empty"] = 0x000000,
    ["bar_full"] = 0x00ff00
}

module = {}
module.data = {}


local function StringifyHeat(v)
    if v >= 1000 or v <= -1000 then
        v = v / 1000
        return string.format("%.1f", v).."kH"
    else
        return string.format("%d", v).."H"
    end
end

local function StringifyEnergy(v)
    if v >= 1000000 or v <= -1000000 then
        v = v / 1000000
        return string.format("%.1f", v).."mRF"
    elseif v >= 1000 or v <= -1000 then
        v = v / 1000
        return string.format("%.1f", v).."kRF"
    else
        return string.format("%d", v).."RF"
    end
end

local function StringifyTicks(v)
    if v >= 72000 then -- 1 hour or higher
        v = v / 72000
        s = string.format("%.0f", v)
        if s == "1" then
            return s.." Hour"
        else
            return s.." Hours"
        end
    elseif v >= 1200 then -- 1 minute or higher
        v = v / 1200
        s = string.format("%.0f", v)
        if s == "1" then
            return s.." Minute"
        else
            return s.." Minutes"
        end
    elseif v >= 120 then -- 6 seconds or higher
        v = v / 120
        return string.format("%.0f", v).." Seconds"
    else -- otherwise just do ticks
        s = string.format("%d", math.floor(v))
        if s == "1" then
            return s.." Tick"
        else
            return s.." Ticks"
        end
    end
end

local function StringifyPercentage(v)
    return string.format("%u", v).."%"
end

local function StringifyPercentageDecimal(v)
    return string.format("%.1f", v).."%"
end


local function Setup(man)
    module.man = man
    gl.Setup()
end

local function Shutdown()
    gl.Shutdown()
end


local function DrawRibbon()
    gl.DrawTextLeft(2, 1, "AtomMan: Fission Edition", colors.ribbon_bg, colors.ribbon_fg)
    gl.DrawTextRight(159, 1, module.man.values.problem, colors.ribbon_bg, colors.ribbon_fg)
    gl.DrawTextLeft(69, 2, "Control Panel | AR Addon", colors.ribbon_bg, colors.ribbon_fg)
    gl.DrawTextLeft(68, 2, " Control Panel ", colors.panel_select, colors.ribbon_fg)
end

local function DrawControlsSection()
    gl.DrawRectangle(5, 5, 156, 8, " ", colors.section_bg, colors.section_fg)
    
    local btn_bg = module.man.values.isProcessing and colors.controls_btn_on or colors.controls_btn_off
    local btn_txt = module.man.values.isProcessing and "On" or "Off"

    gl.DrawTextRight(156, 5, "Reactor Controls", colors.section_bg, colors.section_fg)
        gl.DrawRectangle(151, 6, 156, 8, " ", btn_bg, colors.section_fg)
            gl.DrawTextLeft(153, 7, btn_txt, btn_bg, colors.section_fg)
    
        btn_bg = module.man.settings.manager and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.man.settings.manager and "Auto: On" or "Auto: Off"
        gl.DrawRectangle(141, 6, 150, 8, " ", btn_bg, colors.section_fg)
            gl.DrawTextLeft(142, 7, btn_txt, btn_bg, colors.section_fg)
    
    gl.DrawTextCentred(105, 5, "Heat Threshold ("..StringifyPercentage(module.man.settings.heat_thresh)..")", colors.section_bg, colors.section_fg)
        gl.DrawRectangle(95, 6, 99, 8, " ", colors.controls_thresh, colors.section_fg)
            gl.DrawTextLeft(97, 7, "^", colors.controls_thresh, colors.section_fg)
        gl.DrawRectangle(111, 6, 115, 8, " ", colors.controls_thresh, colors.section_fg)
            gl.DrawTextLeft(113, 7, "V", colors.controls_thresh, colors.section_fg)
            
        btn_bg = module.man.settings.heat_thresh_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.man.settings.heat_thresh_on and "On" or "Off"
        gl.DrawRectangle(100, 6, 110, 8, " ", btn_bg, colors.section_fg)
            gl.DrawTextLeft(104, 7, btn_txt, btn_bg, colors.section_fg)
    
    gl.DrawTextCentred(61, 5, "Heat Warning ("..StringifyPercentage(module.man.settings.heat_warn)..")", colors.section_bg, colors.section_fg)
        gl.DrawRectangle(52, 6, 56, 8, " ", colors.controls_thresh, colors.section_fg)
            gl.DrawTextLeft(54, 7, "^", colors.controls_thresh, colors.section_fg)
        gl.DrawRectangle(66, 6, 70, 8, " ", colors.controls_thresh, colors.section_fg)
            gl.DrawTextLeft(68, 7, "V", colors.controls_thresh, colors.section_fg)
            
        btn_bg = module.man.settings.heat_warn_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.man.settings.heat_warn_on and "On" or "Off"
        gl.DrawRectangle(57, 6, 65, 8, " ", btn_bg, colors.section_fg)
            gl.DrawTextLeft(60, 7, btn_txt, btn_bg, colors.section_fg)
    
    gl.DrawTextCentred(15, 5, "Power Threshold ("..StringifyPercentage(module.man.settings.power_thresh)..")", colors.section_bg, colors.section_fg)
        gl.DrawRectangle(5, 6, 9, 8, " ", colors.controls_thresh, colors.section_fg)
            gl.DrawTextLeft(7, 7, "^", colors.controls_thresh, colors.section_fg)
        gl.DrawRectangle(22, 6, 26, 8, " ", colors.controls_thresh, colors.section_fg)
            gl.DrawTextLeft(24, 7, "V", colors.controls_thresh, colors.section_fg)
            
        btn_bg = module.man.settings.power_thresh_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.man.settings.power_thresh_on and "On" or "Off"
        gl.DrawRectangle(10, 6, 21, 8, " ", btn_bg, colors.section_fg)
            gl.DrawTextLeft(15, 7, btn_txt, btn_bg, colors.section_fg)
end

local function DrawHeatSection()
    gl.DrawRectangle(5, 12, 74, 28, " ", colors.section_bg, colors.section_fg)

    local txt = StringifyHeat(module.man.values.heatLevel).."/"..StringifyHeat(module.man.values.maxHeatLevel).." in buffer ("..StringifyPercentageDecimal(module.man.values.heat_percent).."):"
    gl.DrawTextLeft(7, 13, txt, colors.section_bg, colors.section_fg)

    gl.DrawRectangle(15, 15, 64, 15, " ", colors.bar_empty, colors.section_fg)
    local bar_len = math.floor(module.man.values.heat_percent/2)-1
    if bar_len >= 0 then
        gl.DrawRectangle(15, 15, 15+bar_len, 15, " ", colors.bar_full, colors.section_fg)
    end

    gl.DrawTextLeft(12, 17, "Total Cooling: "..StringifyHeat(module.man.values.reactorCoolingRate).."/t", colors.section_bg, colors.section_fg)
    gl.DrawTextRight(67, 17, "Total Heating: "..StringifyHeat(module.data.total_heating).."/t", colors.section_bg, colors.section_fg)
    gl.DrawTextCentred(39, 19, "Net Heat: "..StringifyHeat(module.man.values.reactorProcessHeat).."/t", colors.section_bg, colors.section_fg)
end

local function DrawPowerSection()
    gl.DrawRectangle(87, 12, 156, 28, " ", colors.section_bg, colors.section_fg)

    local txt = StringifyEnergy(module.man.values.energyStored).."/"..StringifyEnergy(module.man.values.max_energy).." in buffer ("..StringifyPercentageDecimal(module.man.values.energy_percent)..")"
    gl.DrawTextLeft(89, 13, txt, colors.section_bg, colors.section_fg)

    local bar_len = math.floor(module.man.values.energy_percent / 2) - 1
    gl.DrawRectangle(97, 15, 146, 15, " ", colors.bar_empty, colors.section_fg)
    if bar_len >= 0 then
        gl.DrawRectangle(97, 15, 97 + bar_len, 15, " ", colors.bar_full, colors.section_fg)
    end


    txt = StringifyEnergy(module.data.pwr_fuel).."/"..StringifyEnergy(module.data.pwr_fuel_max).." of fuel left ("..StringifyPercentageDecimal(module.data.pwr_fuel_pcnt)..")"
    gl.DrawTextLeft(89, 17, txt, colors.section_bg, colors.section_fg)

    bar_len = math.floor(module.data.pwr_fuel_pcnt / 2) - 1
    gl.DrawRectangle(97, 19, 146, 19, " ", colors.bar_empty, colors.section_fg)
    if bar_len >= 0 then
        gl.DrawRectangle(97, 19, 97 + bar_len, 19, " ", colors.bar_full, colors.section_fg)
    end

    txt = "Reactor Size: "..math.floor(module.man.values.lengthX).."x"..math.floor(module.man.values.lengthY).."x"..math.floor(module.man.values.lengthZ)
    gl.DrawTextLeft(94, 22, txt, colors.section_bg, colors.section_fg)

    txt = "Cell Count: "..math.floor(module.man.values.numberOfCells)
    gl.DrawTextRight(149, 22, txt, colors.section_bg, colors.section_fg)

    txt = "Power Generation: "..StringifyEnergy(module.man.values.reactorProcessPower)
    gl.DrawTextCentred(121, 24, txt, colors.section_bg, colors.section_fg)
end

local function DrawFuelSection()
    gl.DrawRectangle(46, 31, 115, 47, " ", colors.section_bg, colors.section_fg)

    gl.DrawTextLeft(48, 32, "Fuel: "..module.man.values.fissionFuelName, colors.section_bg, colors.section_fg)
    local txt = StringifyTicks(module.man.values.process_time_left).." left ("..StringifyPercentageDecimal(module.man.values.process_percent)..")"
    gl.DrawTextRight(113, 32, txt, colors.section_bg, colors.section_fg)

    local bar_len = math.floor(module.man.values.process_percent / 2) - 1
    gl.DrawRectangle(56, 34, 105, 34, " ", colors.bar_empty, colors.section_fg)
    if bar_len >= 0 then
        gl.DrawRectangle(56, 34, 56 + bar_len, 34, " ", colors.bar_full, colors.section_fg)
    end

    gl.DrawTextLeft(53, 36, "Fuel Base Stats:", colors.section_bg, colors.section_fg)
    gl.DrawTextRight(108, 36, "Fuel Effective Stats:", colors.section_bg, colors.section_fg)

    txt = "Lifetime: "..StringifyTicks(module.man.values.fissionFuelTime)
    gl.DrawTextLeft(53, 38, txt, colors.section_bg, colors.section_fg)
    txt = "Lifetime: "..StringifyTicks(module.man.values.reactorProcessTime)
    gl.DrawTextRight(108, 38, txt, colors.section_bg, colors.section_fg)

    txt = "Power: "..StringifyEnergy(module.man.values.fissionFuelPower).."/t"
    gl.DrawTextLeft(53, 40, txt, colors.section_bg, colors.section_fg)
    txt = "Power: "..StringifyEnergy(module.man.values.reactorProcessPower).."/t"
    gl.DrawTextRight(108, 40, txt, colors.section_bg, colors.section_fg)
    
    txt = "Heat: "..StringifyHeat(module.man.values.fissionFuelHeat).."/t"
    gl.DrawTextLeft(53, 42, txt, colors.section_bg, colors.section_fg)
    txt = "Heat: "..StringifyHeat(module.data.total_heating).."/t"
    gl.DrawTextRight(108, 42, txt, colors.section_bg, colors.section_fg)
end

local function DrawFrame()
    gl.Clear(colors.clear_color)

    module.data.total_heating = module.man.values.reactorProcessHeat - module.man.values.reactorCoolingRate

    module.data.pwr_fuel = module.man.values.process_time_left * module.man.values.reactorProcessPower
    module.data.pwr_fuel_max = module.man.values.fissionFuelTime * module.man.values.fissionFuelPower

    module.data.pwr_fuel_pcnt = modules.UI.data.pwr_fuel / modules.UI.data.pwr_fuel_max * 100

    DrawRibbon()
    DrawControlsSection()
    DrawHeatSection()
    DrawPowerSection()
    DrawFuelSection()

    gl.Render()
end


module.Setup = Setup
module.Shutdown = Shutdown
module.DrawFrame = DrawFrame

return module
