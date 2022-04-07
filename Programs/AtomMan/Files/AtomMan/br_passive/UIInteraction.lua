local button = require("ButtonLib")
local keyboard = require("keyboard")


local module = {}
module.cmnd_2 = ""
module.resp_2 = ""
module.cmnd_1 = ""
module.resp_1 = ""
module.current_command = ""


local modules = {}
local core = 0


local function ShutdownProgram()
    core.running = false
end

local function ReactorToggle()
    modules.man.ToggleReactor()
end

local function ManagerToggle()
    modules.man.settings.manager = not modules.man.settings.manager
end

local function InsertionModeToggle()
    modules.man.settings.individual_rods = not modules.man.settings.individual_rods
end


local function split_string(inputstr, sep)
    sep = sep or "%s"
    local t = {}

    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end


commands = {}

commands.help = function(args)
    if #args == 0 then
        return "List all commands"
    else
        return "Some help about a command"
    end
end

commands.set = function(args)
    if #args == 0 then
        return "Nothing set."
    else
        output = ""
        for i, arg in ipairs(args) do
            values = split_string(arg, "=")

            if #values ~= 2 then
                output = "Invalid arg["..i.."]"
                break
            end

            key = string.lower(values[1])
            val = tonumber(values[2])

            if not val then
                output = "Invalid arg["..i.."] invalid number"
                break
            end

            if key == "p" then
                if modules.man.settings.individual_rods then
                    modules.man.settings.ikp = val
                else
                    modules.man.settings.kp = val
                end
                output = output.."Set P to "..val..". "
            elseif key == "i" then
                if modules.man.settings.individual_rods then
                    modules.man.settings.iki = val
                else
                    modules.man.settings.ki = val
                end
                output = output.."Set I to "..val..". "
            elseif key == "d" then
                if modules.man.settings.individual_rods then
                    modules.man.settings.ikd = val
                else
                    modules.man.settings.kd = val
                end
                output = output.."Set D to "..val..". "
            elseif key == "target" then
                modules.man.settings.power_target = val
                output = output.."Set Target to "..val..". "
            elseif key == "insertion" then
                modules.man.SetInsertion(val)
                output = output.."Set Insertion to "..val..". "
            else
                output = "Invalid arg["..i.."] invalid key"
                break
            end
        end

        return output
    end
end

commands.reset_integral = function(_)
    modules.man.values.i_acc = 0
    return "Reset integral buffer to 0"
end

commands.debug = function(_)
    modules.man.settings.debug = not modules.man.settings.debug
    if modules.man.settings.debug then
        return "Turned debug mode on"
    else
        return "Turned debug mode off"
    end
end


key_up_commands = {}

key_up_commands[keyboard.keys.enter] = function()
    args = split_string(module.current_command)
    command = table.remove(args, 1)

    if commands[command] then
        feedback = commands[command](args)
    else
        feedback = "Unknown command: "..command
    end

    if #feedback > 154 then
        feedback = string.sub(feedback, 1, 152)..".."
    end

    module.cmnd_2 = module.cmnd_1
    module.resp_2 = module.resp_1
    module.cmnd_1 = module.current_command
    module.resp_1 = feedback
    module.current_command = ""
end

key_up_commands[keyboard.keys.back] = function()
    module.current_command = string.sub(module.current_command, 1, -2)
end


local function KeyUp(_, _, char, code, _)
    if ((code >= 2  and code <= 13)  or
        (code >= 16 and code <= 27)  or
        (code >= 30 and code <= 41)  or
        (code >= 43 and code <= 53)  or
        (code == 55)                 or
        (code == 57)                 or
        (code >= 71 and code <= 83)  or
        (code == 181)             )  and
        not keyboard.isAltDown()     and
        not keyboard.isControlDown() then
        module.current_command = module.current_command..utf8.char(char)
    else
        if key_up_commands[code] then
            key_up_commands[code]()
        end
    end

    if #module.current_command > 154 then
        module.current_command = string.sub(module.current_command, 1, 154)
    end
end


module.setup = function (mods, core_in)
    modules = mods
    core = core_in

    button.Setup()

    button.AddButton("ShutdownProgram", 160, 1, 160, 1, ShutdownProgram)
    button.AddButton("ReactorToggle", 26, 6, 37, 8, ReactorToggle)
    button.AddButton("ManagerToggle", 145, 6, 156, 8, ManagerToggle)
    button.AddButton("InsertionModeToggle", 131, 6, 142, 8, InsertionModeToggle)

    table.insert(core.callbacks.key_up, KeyUp)
end

module.shutdown = function ()
    button.Shutdown()
end


return module
