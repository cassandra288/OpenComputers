local reactor = require("component").nc_fission_reactor


local module = {}

module.values = {}
module.settings = {
    ["manager"] = false,
    ["heat_thresh_on"] = false,
    ["heat_thresh"] = 20,
    ["power_thresh_on"] = false,
    ["power_thresh"] = 20,
    ["heat_warn_on"] = true,
    ["heat_warn"] = 40,
    ["shutdown_on_warning"] = true
}


function module.UpdateValues()
    reactor.forceUpdate()

    module.values.reactorProcessTime = reactor.getReactorProcessTime()
    module.values.reactorProcessPower = reactor.getReactorProcessPower()
    module.values.reactorCoolingRate = reactor.getReactorCoolingRate()
    module.values.reactorProcessHeat = reactor.getReactorProcessHeat()
    
    module.values.fissionFuelTime = reactor.getFissionFuelTime()
    module.values.fissionFuelPower = reactor.getFissionFuelPower()
    module.values.fissionFuelHeat = reactor.getFissionFuelHeat()
    module.values.fissionFuelName = reactor.getFissionFuelName()
    
    module.values.currentProcessTime = reactor.getCurrentProcessTime()
    
    module.values.heatLevel = reactor.getHeatLevel()
    module.values.maxHeatLevel = reactor.getMaxHeatLevel()
    
    module.values.energyStored = reactor.getEnergyStored()
    
    module.values.lengthX = reactor.getLengthX()
    module.values.lengthY = reactor.getLengthY()
    module.values.lengthZ = reactor.getLengthZ()
    module.values.numberOfCells = reactor.getNumberOfCells()
    
    module.values.isProcessing = reactor.isProcessing()
    module.values.problem = reactor.getProblem()

    module.values.heat_percent = module.values.heatLevel / module.values.maxHeatLevel * 100

    module.values.max_energy = 64000 * module.values.lengthX * module.values.lengthY * module.values.lengthZ
    module.values.energy_percent = module.values.energyStored / module.values.max_energy * 100

    module.values.process_time_left = (module.values.fissionFuelTime - module.values.currentProcessTime) / module.values.numberOfCells
    module.values.process_percent = module.values.process_time_left / module.values.reactorProcessTime * 100
end

function module.ManageReactor()
    if module.settings.manager then

        heat_thresh_hit = module.settings.heat_thresh_on and module.values.heat_percent >= module.settings.heat_thresh
        power_thresh_hit = module.settings.power_thresh_on and module.values.energy_percent >= module.settings.power_thresh
        heat_warn_hit = module.settings.heat_warn_on and module.values.heat_percent >= module.settings.heat_warn

        if heat_thresh_hit or power_thresh_hit or (heat_warn_hit and module.settings.shutdown_on_warning) then
            reactor.deactivate()
            module.values.isProcessing = false
        elseif not heat_thresh_hit and not power_thresh_hit and not (heat_warn_hit and module.settings.shutdown_on_warning) then
            reactor.activate()
            module.values.isProcessing = true
        end

        if heat_warn_hit then
            -- do something to warn
        end
    end
end

function module.ToggleReactor()
    if module.values.isProcessing then
        reactor.deactivate()
    else
        reactor.activate()
    end
end


return module
