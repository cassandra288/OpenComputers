local core = require("ProgramCore")


local modules = {}

if require("component").isAvailable("nc_fission_reactor") then
    error("No reactor type")
    -- not tested after a core update
    --modules.ui = require("Files/AtomMan/nc_fission/UIRender")
    --modules.man = require("Files/AtomMan/nc_fission/ReactorManager")
    --modules.interaction = require("Files/AtomMan/nc_fission/UIInteraction")
elseif require("component").isAvailable("br_reactor") then
    modules.ui = require("Files/AtomMan/br_passive/UIRender")
    modules.man = require("Files/AtomMan/br_passive/ReactorManager")
    modules.interaction = require("Files/AtomMan/br_passive/UIInteraction")
else
    error("No reactor type")
end


modules.ui.Setup(modules)
modules.interaction.setup(modules, core)

core.targetTPS = 20


local function main()
    modules.man.UpdateValues()
    modules.man.ManageReactor()
    modules.ui.DrawFrame()


    --core.running = false
end
core.Run(main)


modules.interaction.shutdown()
modules.ui.Shutdown()
