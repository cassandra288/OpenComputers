gl = require("OpenTGL")


colors = {
    ["clear_color"] = 0x888888,

    ["section_bg"] = 0xaaaaaa,
    ["section_fg"] = 0xffffff,

    ["green"] = 0x00ff00,
    ["red"] = 0xff0000,
    ["black"] = 0x000000
}

module = {}
module.data = {}


local function StringifyEnergy(v, figure)
    figure = figure or "%.1f"

    if v >= 1000000 or v <= -1000000 then
        v = v / 1000000
        return string.format(figure, v):gsub("%.?0+$", "").."mRF"
    elseif v >= 1000 or v <= -1000 then
        v = v / 1000
        return string.format(figure, v):gsub("%.?0+$", "").."kRF"
    else
        return string.format("%.0f", v).."RF"
    end
end

local function StringifyFuel(v, figure)
    figure = figure or "%.1f"

    if v >= 100000 or v <= -100000 then
        v = v / 1000
        return string.format(figure, v):gsub("%.?0+$", "").."B"
    else
        return string.format("%.3f", v).."mB"
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
    elseif v >= 100 then -- 5 seconds or higher
        v = v / 100
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
    return string.format("%.1f", v):gsub("%.?0+$", "").."%"
end

local function Int(v)
    return string.format("%u", v)
end


local function Setup(mods)
    module.man = mods.man
    module.interaction = mods.interaction

    module.data.power_graph = {}
    module.data.power_countdown = 0
    module.data.power_countdown_rate = 20
    module.data.fuel_graph = {}
    module.data.fuel_countdown = 0
    module.data.fuel_countdown_rate = 20

    gl.Setup()
end

local function Shutdown()
    gl.Clear(colors.black)
    gl.Render()
    gl.Shutdown()
end


local function DrawBackgrounds()
    gl.DrawRectangle(1, 1, 160, 1, " ", colors.section_bg, colors.section_fg)       -- Ribbon
    gl.DrawRectangle(3, 3, 39, 10, " ", colors.section_bg, colors.section_fg)       -- Reactor Section
    gl.DrawRectangle(112, 3, 158, 10, " ", colors.section_bg, colors.section_fg)    -- Manager Section
    gl.DrawRectangle(3, 12, 78, 12, " ", colors.section_bg, colors.section_fg)      -- Power Ribbon
    gl.DrawRectangle(83, 12, 158, 12, " ", colors.section_bg, colors.section_fg)    -- Fuel Ribbon
    gl.DrawRectangle(3, 13, 78, 43, " ", colors.black, colors.black)                -- Power Graph
    gl.DrawRectangle(83, 13, 158, 43, " ", colors.black, colors.black)              -- Fuel Graph
    gl.DrawRectangle(3, 45, 158, 49, " ", colors.black, colors.black)               -- Console BG
end

local function DrawRibbon()
    gl.DrawTextLeft(68, 1, "AtomMan: Yellorium Edition", colors.section_bg, colors.section_fg)
    gl.SetChar(160, 1, " ", colors.red, colors.section_fg)                          -- Exit button
end

local function DrawReactorStats()
    gl.DrawTextLeft(5, 3, "Reactor Overview", colors.section_bg, colors.section_fg)

    if module.man.values.reactor_assembled then
        gl.DrawTextRight(37, 3, "Assembled", colors.section_bg, colors.green)
    else
        gl.DrawTextRight(37, 3, "Disassembled", colors.section_bg, colors.red)
    end

    gl.DrawTextLeft(5, 5, "Size:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(11, 5, Int(module.man.values.reactor_size_x).."x"..Int(module.man.values.reactor_size_y).."x"..Int(module.man.values.reactor_size_z), colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(5, 7, "Rod Count:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(16, 7, Int(module.man.values.reactor_rod_count), colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(5, 9, "Rod Insertion:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(20, 9, StringifyPercentageDecimal(module.data.insertion_percent), colors.section_bg, colors.section_fg)

    if module.man.values.reactor_active then
        gl.DrawRectangle(26, 6, 37, 8, " ", colors.green, colors.section_fg)
        gl.DrawTextLeft(31, 7, "On", colors.green, colors.section_fg)
    else
        gl.DrawRectangle(26, 6, 37, 8, " ", colors.red, colors.section_fg)
        gl.DrawTextLeft(31, 7, "Off", colors.red, colors.section_fg)
    end
end

local function DrawManagerStats()
    gl.DrawTextLeft(144, 3, "Manager Stats", colors.section_bg, colors.section_fg)

    gl.DrawTextLeft(147, 5, "Manager", colors.section_bg, colors.section_fg)

    if module.man.settings.manager then
        gl.DrawRectangle(145, 6, 156, 8, " ", colors.green, colors.section_fg)
        gl.DrawTextLeft(150, 7, "On", colors.green, colors.section_fg)
    else
        gl.DrawRectangle(145, 6, 156, 8, " ", colors.red, colors.section_fg)
        gl.DrawTextLeft(150, 7, "Off", colors.red, colors.section_fg)
    end
    
    gl.DrawTextLeft(132, 5, "Insertion", colors.section_bg, colors.section_fg)

    if module.man.settings.individual_rods then
        gl.DrawRectangle(131, 6, 142, 8, " ", colors.green, colors.section_fg)
        gl.DrawTextLeft(134, 7, "Single", colors.green, colors.section_fg)
    else
        gl.DrawRectangle(131, 6, 142, 8, " ", colors.red, colors.section_fg)
        gl.DrawTextLeft(134, 7, "Multi", colors.red, colors.section_fg)
    end

    gl.DrawTextLeft(137, 9, "Target:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(145, 9, StringifyPercentage(module.man.settings.power_target), colors.section_bg, colors.section_fg)

    if module.man.settings.individual_rods then
        p = string.format("%.5f", module.man.settings.ikp):gsub("%.?0+$", "")
        i = string.format("%.5f", module.man.settings.iki):gsub("%.?0+$", "")
        d = string.format("%.5f", module.man.settings.ikd):gsub("%.?0+$", "")
    else
        p = string.format("%.5f", module.man.settings.kp):gsub("%.?0+$", "")
        i = string.format("%.5f", module.man.settings.ki):gsub("%.?0+$", "")
        d = string.format("%.5f", module.man.settings.kd):gsub("%.?0+$", "")
    end
    
    gl.DrawTextLeft(114, 5, "P:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(117, 5, p, colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(114, 7, "I:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(117, 7, i, colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(114, 9, "D:", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(117, 9, d, colors.section_bg, colors.section_fg)

    if module.man.settings.debug then
        gl.DrawTextLeft(114, 3, tostring(module.man.values.debug_pid), colors.section_bg, colors.section_fg)
        gl.DrawTextLeft(114, 2, tostring(module.man.values.debug_min_change), colors.clear_color, colors.section_fg)
    end
end

local function DrawPowerStats()
    current_power = StringifyEnergy(module.man.values.energy_amount, "%.3f")
    total_power = StringifyEnergy(module.man.values.energy_amount_max, "%.3f")
    power_percent = module.man.values.energy_amount / module.man.values.energy_amount_max

    gl.DrawTextLeft(38, 12, "Power", colors.section_bg, colors.section_fg)
    gl.DrawTextRight(35, 12, current_power.."/"..total_power.." ("..StringifyPercentageDecimal(power_percent * 100)..")", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(45, 12, StringifyEnergy(module.man.values.energy_consumed, "%.3f").."/t", colors.section_bg, colors.section_fg)

    if module.data.power_countdown == 0 then
        table.insert(module.data.power_graph, power_percent)
        if #module.data.power_graph == 77 then
            table.remove(module.data.power_graph, 1)
        end

        module.data.power_countdown = module.data.power_countdown_rate
    else
        module.data.power_countdown = module.data.power_countdown - 1
    end

    prev_x = -1
    prev_y = 0
    for i=1, #module.data.power_graph do
        x = i + 2 -- 3 to 78
        y = 86 - math.floor(61 * module.data.power_graph[i]) -- 25 to 86

        if prev_x == -1 then
            gl.SetSemiChar(x, y, colors.green)
        else
            gl.DrawSemiLine(prev_x, prev_y, x, y, colors.green)
        end

        prev_x = x
        prev_y = y
    end
end

local function DrawFuelStats()
    current_fuel = StringifyFuel(module.man.values.fuel_amount, "%.3f")
    total_fuel = StringifyFuel(module.man.values.fuel_amount_max, "%.3f")
    fuel_percent = module.man.values.fuel_amount / module.man.values.fuel_amount_max

    fuel_ticks_left = module.man.values.fuel_amount / module.data.fuel_usage

    gl.DrawTextLeft(119, 12, "Fuel", colors.section_bg, colors.section_fg)
    gl.DrawTextRight(116, 12, current_fuel.."/"..total_fuel.." ("..StringifyPercentageDecimal(fuel_percent * 100)..")", colors.section_bg, colors.section_fg)
    gl.DrawTextLeft(125, 12, StringifyFuel(module.data.fuel_usage, "%.3f").."/t ("..StringifyTicks(fuel_ticks_left).." left)", colors.section_bg, colors.section_fg)

    if module.data.fuel_countdown == 0 then
        table.insert(module.data.fuel_graph, fuel_percent)
        if #module.data.fuel_graph == 77 then
            table.remove(module.data.fuel_graph, 1)
        end

        module.data.fuel_countdown = module.data.fuel_countdown_rate
    else
        module.data.fuel_countdown = module.data.fuel_countdown - 1
    end

    prev_x = -1
    prev_y = 0
    for i=1, #module.data.fuel_graph do
        x = i +82 -- 83 to 158
        y = 86 - math.floor(61 * module.data.fuel_graph[i]) -- 25 to 86

        if prev_x == -1 then
            gl.SetSemiChar(x, y, colors.green)
        else
            gl.DrawSemiLine(prev_x, prev_y, x, y, colors.green)
        end

        prev_x = x
        prev_y = y
    end
end

local function DrawConsole()
    gl.SetChar(3, 49, ">", colors.black, colors.section_fg)

    gl.DrawTextLeft(3, 45, module.interaction.cmnd_2, colors.black, colors.section_fg)
    gl.DrawTextLeft(3, 46, module.interaction.resp_2, colors.black, colors.section_fg)
    gl.DrawTextLeft(3, 47, module.interaction.cmnd_1, colors.black, colors.section_fg)
    gl.DrawTextLeft(3, 48, module.interaction.resp_1, colors.black, colors.section_fg)
    gl.DrawTextLeft(3, 49, "> "..module.interaction.current_command, colors.black, colors.section_fg)
    -- Draw Current and Previous Commands
end


local function DrawFrame()
    gl.Clear(colors.clear_color)

    higher_insertion_count = module.man.values.current_rod_index
    lower_insertion_count = module.man.values.reactor_rod_count - higher_insertion_count
    module.data.insertion_percent = ((higher_insertion_count * module.man.values.insertion_level) + (lower_insertion_count * (module.man.values.insertion_level - 1))) / module.man.values.reactor_rod_count

    total_fuel_usage = 0
    for i=1,#module.man.values.fuel_consumed_buffer do
        total_fuel_usage = total_fuel_usage + module.man.values.fuel_consumed_buffer[i]
    end
    module.data.fuel_usage = total_fuel_usage / #module.man.values.fuel_consumed_buffer

    DrawBackgrounds()
    DrawRibbon()
    DrawReactorStats()
    DrawManagerStats()
    DrawPowerStats()
    DrawFuelStats()
    DrawConsole()

    gl.Render()
end


module.Setup = Setup
module.Shutdown = Shutdown
module.DrawFrame = DrawFrame

return module
