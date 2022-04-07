local reactor = require("component").br_reactor


local module = {}

module.values = {
    ["fuel_amount"]             = nil,
    ["fuel_amount_max"]         = nil,
    ["fuel_consumed"]           = nil,

    ["energy_amount"]           = nil,
    ["energy_amount_max"]       = nil,
    ["energy_consumed"]         = nil,

    ["reactor_size_x"]          = nil,
    ["reactor_size_y"]          = nil,
    ["reactor_size_z"]          = nil,
    ["reactor_rod_count"]       = nil,
    ["reactor_assembled"]       = nil,

    ["reactor_active"]          = nil,
    ["insertion_level"]         = nil,   -- highest of the 2 in the case of individual rods


    ["current_rod_index"]       = -1,    -- index of last modified rod for per_rod control
    ["i_acc"]                   = 0,     -- integral accumulator
    ["err_prior"]               = 0,

    ["fuel_consumed_buffer"]    = {},

    ["debug_pid"]               = 0,
    ["debug_min_change"]               = 0,
}
module.settings = {
    ["manager"]                 = false, -- manager toggle
    ["power_target"]            = 20,    -- power target percentage
    ["individual_rods"]         = false, -- toggle for per-rod control

    ["kp"]                      = 2.5,   -- p modifier for PID
    ["ki"]                      = 0,     -- i modifier for PID
    ["kd"]                      = 60,    -- d modifier for PID

    ["ikp"]                     = 2.5,   -- p modifier for PID when on individual rods
    ["iki"]                     = 0,     -- i modifier for PID when on individual rods
    ["ikd"]                     = 60,    -- d modifier for PID when on individual rods

    ["debug"]                   = false,
}


function module.UpdateValues()
    module.values.fuel_amount        = reactor.getFuelAmount()
    module.values.fuel_amount_max    = reactor.getFuelAmountMax()
    module.values.fuel_consumed       = reactor.getFuelConsumedLastTick()

    module.values.energy_amount      = reactor.getEnergyStored()
    module.values.energy_amount_max  = reactor.getEnergyCapacity()
    module.values.energy_consumed     = reactor.getEnergyProducedLastTick()

    min_x, min_y, min_z = reactor.getMinimumCoordinate()
    max_x, max_y, max_z = reactor.getMaximumCoordinate()

    module.values.reactor_size_x      = max_x - min_x + 1
    module.values.reactor_size_y      = max_y - min_y + 1
    module.values.reactor_size_z      = max_z - min_z + 1
    module.values.reactor_rod_count   = reactor.getNumberOfControlRods()
    module.values.reactor_assembled   = reactor.getMultiblockAssembled()

    module.values.reactor_active      = reactor.getActive()
    module.values.insertion_level     = reactor.getControlRodLevel(0)

    if module.values.current_rod_index == -1 then
        module.values.current_rod_index = module.values.reactor_rod_count
    end

    table.insert(module.values.fuel_consumed_buffer, module.values.fuel_consumed)
    if #module.values.fuel_consumed_buffer == 2401 then
        table.remove(module.values.fuel_consumed_buffer, 1)
    end
end

function module.ManageReactor()
    if module.settings.manager then
        power_percent = (module.values.energy_amount / module.values.energy_amount_max) * 100

        error = module.settings.power_target - power_percent
        module.values.i_acc = module.values.i_acc + error
        derivative = error-module.values.err_prior
        
        module.values.err_prior = error

        pid = 0
        if module.settings.individual_rods then
            pid = module.settings.ikp * error + module.settings.iki * module.values.i_acc + module.settings.ikd * derivative
            pid = pid * -1

            total_change = math.abs(pid)
            decreasing = pid < 0

            left_over = module.values.reactor_rod_count - module.values.current_rod_index
            if left_over > total_change then left_over = math.floor(total_change) end
            if left_over > 0 then
                total_change = total_change - left_over
                
                new_insertion = reactor.getControlRodLevel(0)
                if decreasing then
                    new_insertion = new_insertion - 1
                else
                    new_insertion = new_insertion + 1
                end

                for i=module.values.current_rod_index+1, module.values.current_rod_index+left_over do
                    reactor.setControlRodLevel(i-1, new_insertion)
                end
                module.values.current_rod_index = module.values.current_rod_index + left_over
            end
            
            if total_change >= 1 then
                minimum_change = math.floor(total_change / module.values.reactor_rod_count)
                partial_change = math.floor(total_change - (minimum_change * module.values.reactor_rod_count))

                if minimum_change > 0 then
                    new_insertion = reactor.getControlRodLevel(0)
                    if decreasing then
                        new_insertion = new_insertion - minimum_change
                    else
                        new_insertion = new_insertion + minimum_change
                    end

                    for i=1, module.values.reactor_rod_count do
                        reactor.setControlRodLevel(i-1, new_insertion)
                    end
                end

                if partial_change > 0 then
                    new_insertion = reactor.getControlRodLevel(0)
                    if decreasing then
                        new_insertion = new_insertion - 1
                    else
                        new_insertion = new_insertion + 1
                    end

                    for i=1, partial_change do
                        reactor.setControlRodLevel(i-1, new_insertion)
                    end

                    module.values.current_rod_index = partial_change - 1
                end
            end

            module.values.debug_min_change = partial_change
        else
            pid = module.settings.kp * error + module.settings.ki * module.values.i_acc + module.settings.kd * derivative
            pid = pid * -1

            insertion = module.values.insertion_level + pid

            if insertion > 100 then
                insertion = 100
            elseif insertion < 0 then
                insertion = 0
            end

            module.values.current_rod_index = module.values.reactor_rod_count

            for i=0,module.values.reactor_rod_count-1 do
                reactor.setControlRodLevel(i, insertion)
            end
        end

        module.values.debug_pid = pid
    end
end

function module.ToggleReactor()
    if module.values.reactor_active then
        reactor.setActive(false)
    else
        reactor.setActive(true)
    end
end

function module.SetInsertion(val)
    for i=0,module.values.reactor_rod_count-1 do
        reactor.setControlRodLevel(i, val)
    end
end


return module
