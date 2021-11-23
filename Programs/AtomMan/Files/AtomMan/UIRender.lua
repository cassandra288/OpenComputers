Gl = require("OpenTGL")


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
module.data = {
    ["problem"] = "No Problem",

    ["reactor_on"] = false,
    ["autopilot_on"] = false,
    ["heat_thresh"] = 0,
    ["heat_thresh_on"] = false,
    ["heat_warn"] = 0,
    ["heat_warn_on"] = false,
    ["power_thresh"] = 0,
    ["power_thresh_on"] = false,

    ["heat_buffer"] = 0,
    ["heat_buffer_max"] = 0,
    ["heat_buffer_pcnt"] = 0,
    ["total_cooling"] = 0,
    ["total_heating"] = 0,
    ["net_heat"] = 0,

    ["pwr_buffer"] = 0,
    ["pwr_buffer_max"] = 0,
    ["pwr_buffer_pcnt"] = 0,
    ["pwr_fuel"] = 0,
    ["pwr_fuel_max"] = 0,
    ["pwr_fuel_pcnt"] = 0,
    ["reactor_size"] = {["x"] = 0, ["y"] = 0, ["z"] = 0},
    ["cell_count"] = 0,
    ["pwr_gen_tick"] = 0,

    ["fuel_name"] = "TBU",
    ["time_left_ticks"] = 0,
    ["time_left_percent"] = 0,
    ["fuel_base_life"] = 0,
    ["fuel_effective_life"] = 0,
    ["fuel_base_power"] = 0,
    ["fuel_base_heat"] = 0,
}


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


local function Setup()
    Gl.Setup()
end

local function Shutdown()
    Gl.Shutdown()
end


local function DrawRibbon()
    Gl.DrawTextLeft(2, 1, "AtomMan: Fission Edition", colors.ribbon_bg, colors.ribbon_fg)
    Gl.DrawTextRight(159, 1, module.data.problem, colors.ribbon_bg, colors.ribbon_fg)
    Gl.DrawTextLeft(69, 2, "Control Panel | AR Addon", colors.ribbon_bg, colors.ribbon_fg)
    Gl.DrawTextLeft(68, 2, " Control Panel ", colors.panel_select, colors.ribbon_fg)
end

local function DrawControlsSection()
    Gl.DrawRectangle(5, 5, 156, 8, " ", colors.section_bg, colors.section_fg)
    
    local btn_bg = module.data.reactor_on and colors.controls_btn_on or colors.controls_btn_off
    local btn_txt = module.data.reactor_on and "On" or "Off"

    Gl.DrawTextRight(156, 5, "Reactor Controls", colors.section_bg, colors.section_fg)
        Gl.DrawRectangle(151, 6, 156, 8, " ", btn_bg, colors.section_fg)
            Gl.DrawTextLeft(153, 7, btn_txt, btn_bg, colors.section_fg)
    
        btn_bg = module.data.autopilot_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.data.autopilot_on and "Auto: On" or "Auto: Off"
        Gl.DrawRectangle(141, 6, 150, 8, " ", btn_bg, colors.section_fg)
            Gl.DrawTextLeft(142, 7, btn_txt, btn_bg, colors.section_fg)
    
    Gl.DrawTextCentred(105, 5, "Heat Threshold ("..StringifyPercentage(module.data.heat_thresh)..")", colors.section_bg, colors.section_fg)
        Gl.DrawRectangle(95, 6, 99, 8, " ", colors.controls_thresh, colors.section_fg)
            Gl.DrawTextLeft(97, 7, "^", colors.controls_thresh, colors.section_fg)
        Gl.DrawRectangle(111, 6, 115, 8, " ", colors.controls_thresh, colors.section_fg)
            Gl.DrawTextLeft(113, 7, "V", colors.controls_thresh, colors.section_fg)
            
        btn_bg = module.data.heat_thresh_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.data.heat_thresh_on and "On" or "Off"
        Gl.DrawRectangle(100, 6, 110, 8, " ", btn_bg, colors.section_fg)
            Gl.DrawTextLeft(104, 7, btn_txt, btn_bg, colors.section_fg)
    
    Gl.DrawTextCentred(61, 5, "Heat Warning ("..StringifyPercentage(module.data.heat_warn)..")", colors.section_bg, colors.section_fg)
        Gl.DrawRectangle(52, 6, 56, 8, " ", colors.controls_thresh, colors.section_fg)
            Gl.DrawTextLeft(54, 7, "^", colors.controls_thresh, colors.section_fg)
        Gl.DrawRectangle(66, 6, 70, 8, " ", colors.controls_thresh, colors.section_fg)
            Gl.DrawTextLeft(68, 7, "V", colors.controls_thresh, colors.section_fg)
            
        btn_bg = module.data.heat_warn_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.data.heat_warn_on and "On" or "Off"
        Gl.DrawRectangle(57, 6, 65, 8, " ", btn_bg, colors.section_fg)
            Gl.DrawTextLeft(60, 7, btn_txt, btn_bg, colors.section_fg)
    
    Gl.DrawTextCentred(15, 5, "Power Threshold ("..StringifyPercentage(module.data.power_thresh)..")", colors.section_bg, colors.section_fg)
        Gl.DrawRectangle(5, 6, 9, 8, " ", colors.controls_thresh, colors.section_fg)
            Gl.DrawTextLeft(7, 7, "^", colors.controls_thresh, colors.section_fg)
        Gl.DrawRectangle(22, 6, 26, 8, " ", colors.controls_thresh, colors.section_fg)
            Gl.DrawTextLeft(24, 7, "V", colors.controls_thresh, colors.section_fg)
            
        btn_bg = module.data.power_thresh_on and colors.controls_btn_on or colors.controls_btn_off
        btn_txt = module.data.power_thresh_on and "On" or "Off"
        Gl.DrawRectangle(10, 6, 21, 8, " ", btn_bg, colors.section_fg)
            Gl.DrawTextLeft(15, 7, btn_txt, btn_bg, colors.section_fg)
end

local function DrawHeatSection()
    Gl.DrawRectangle(5, 12, 74, 28, " ", colors.section_bg, colors.section_fg)

    local txt = StringifyHeat(module.data.heat_buffer).."/"..StringifyHeat(module.data.heat_buffer_max).." in buffer ("..StringifyPercentageDecimal(module.data.heat_buffer_pcnt).."):"
    Gl.DrawTextLeft(7, 13, txt, colors.section_bg, colors.section_fg)

    Gl.DrawRectangle(15, 15, 64, 15, " ", colors.bar_empty, colors.section_fg)
    local bar_len = math.floor(module.data.heat_buffer_pcnt/2)-1
    if bar_len >= 0 then
        Gl.DrawRectangle(15, 15, 15+bar_len, 15, " ", colors.bar_full, colors.section_fg)
    end

    Gl.DrawTextLeft(12, 17, "Total Cooling: "..StringifyHeat(module.data.total_cooling).."/t", colors.section_bg, colors.section_fg)
    Gl.DrawTextRight(67, 17, "Total Heating: "..StringifyHeat(module.data.total_heating).."/t", colors.section_bg, colors.section_fg)
    Gl.DrawTextCentred(39, 19, "Net Heat: "..StringifyHeat(module.data.net_heat).."/t", colors.section_bg, colors.section_fg)
end

local function DrawPowerSection()
    Gl.DrawRectangle(87, 12, 156, 28, " ", colors.section_bg, colors.section_fg)

    local txt = StringifyEnergy(module.data.pwr_buffer).."/"..StringifyEnergy(module.data.pwr_buffer_max).." in buffer ("..StringifyPercentageDecimal(module.data.pwr_buffer_pcnt)..")"
    Gl.DrawTextLeft(89, 13, txt, colors.section_bg, colors.section_fg)

    local bar_len = math.floor(module.data.pwr_buffer_pcnt / 2) - 1
    Gl.DrawRectangle(97, 15, 146, 15, " ", colors.bar_empty, colors.section_fg)
    if bar_len >= 0 then
        Gl.DrawRectangle(97, 15, 97 + bar_len, 15, " ", colors.bar_full, colors.section_fg)
    end


    txt = StringifyEnergy(module.data.pwr_fuel).."/"..StringifyEnergy(module.data.pwr_fuel_max).." of fuel left ("..StringifyPercentageDecimal(module.data.pwr_fuel_pcnt)..")"
    Gl.DrawTextLeft(89, 17, txt, colors.section_bg, colors.section_fg)

    bar_len = math.floor(module.data.pwr_fuel_pcnt / 2) - 1
    Gl.DrawRectangle(97, 19, 146, 19, " ", colors.bar_empty, colors.section_fg)
    if bar_len >= 0 then
        Gl.DrawRectangle(97, 19, 97 + bar_len, 19, " ", colors.bar_full, colors.section_fg)
    end

    txt = "Reactor Size: "..math.floor(module.data.reactor_size.x).."x"..math.floor(module.data.reactor_size.y).."x"..math.floor(module.data.reactor_size.z)
    Gl.DrawTextLeft(94, 22, txt, colors.section_bg, colors.section_fg)

    txt = "Cell Count: "..math.floor(module.data.cell_count)
    Gl.DrawTextRight(149, 22, txt, colors.section_bg, colors.section_fg)

    txt = "Power Generation: "..StringifyEnergy(module.data.pwr_gen_tick)
    Gl.DrawTextCentred(121, 24, txt, colors.section_bg, colors.section_fg)
end

local function DrawFuelSection()
    Gl.DrawRectangle(46, 31, 115, 47, " ", colors.section_bg, colors.section_fg)

    Gl.DrawTextLeft(48, 32, "Fuel: "..module.data.fuel_name, colors.section_bg, colors.section_fg)
    local txt = StringifyTicks(module.data.time_left_ticks).." left ("..StringifyPercentageDecimal(module.data.time_left_percent)..")"
    Gl.DrawTextRight(113, 32, txt, colors.section_bg, colors.section_fg)

    local bar_len = math.floor(module.data.time_left_percent / 2) - 1
    Gl.DrawRectangle(56, 34, 105, 34, " ", colors.bar_empty, colors.section_fg)
    if bar_len >= 0 then
        Gl.DrawRectangle(56, 34, 56 + bar_len, 34, " ", colors.bar_full, colors.section_fg)
    end

    Gl.DrawTextLeft(53, 36, "Fuel Base Stats:", colors.section_bg, colors.section_fg)
    Gl.DrawTextRight(108, 36, "Fuel Effective Stats:", colors.section_bg, colors.section_fg)

    txt = "Lifetime: "..StringifyTicks(module.data.fuel_base_life)
    Gl.DrawTextLeft(53, 38, txt, colors.section_bg, colors.section_fg)
    txt = "Lifetime: "..StringifyTicks(module.data.fuel_effective_life)
    Gl.DrawTextRight(108, 38, txt, colors.section_bg, colors.section_fg)

    txt = "Power: "..StringifyEnergy(module.data.fuel_base_power).."/t"
    Gl.DrawTextLeft(53, 40, txt, colors.section_bg, colors.section_fg)
    txt = "Power: "..StringifyEnergy(module.data.pwr_gen_tick).."/t"
    Gl.DrawTextRight(108, 40, txt, colors.section_bg, colors.section_fg)
    
    txt = "Heat: "..StringifyHeat(module.data.fuel_base_heat).."/t"
    Gl.DrawTextLeft(53, 42, txt, colors.section_bg, colors.section_fg)
    txt = "Heat: "..StringifyHeat(module.data.total_heating).."/t"
    Gl.DrawTextRight(108, 42, txt, colors.section_bg, colors.section_fg)
end

local function DrawFrame()
    Gl.Clear(colors.clear_color)

    DrawRibbon()
    DrawControlsSection()
    DrawHeatSection()
    DrawPowerSection()
    DrawFuelSection()

    Gl.Render()
end


module.Setup = Setup
module.Shutdown = Shutdown
module.DrawFrame = DrawFrame

return module
