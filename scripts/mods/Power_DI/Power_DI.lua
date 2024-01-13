local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local PDI = {}
mod.version = "0.5"
mod.cache = {}
PDI.promise = require("scripts/foundation/utilities/promise")
PDI.utilities = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\utilities]])
PDI.save_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\save_manager]])
PDI.coroutine_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\coroutine_manager]])
PDI.api_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\api_manager]])
PDI.session_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\session_manager]])
PDI.datasource_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\datasource_manager]])
PDI.dataset_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\dataset_manager]])
PDI.report_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\report_manager]])
PDI.view_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\view_manager]])

--Function to print certain steps for debugging--
local debug = mod:get("debug_mode")
PDI.debug = function(function_name, context)
    if not debug then
       return 
    end
    if type(context) == "table" then
        print("Debug: "..function_name)
        print("----------")
        DMF:dump(context)
        print("----------")
    else
        print("Debug: "..function_name.." ("..tostring(context)..")")
    end
end

--Create main data table--
PDI.data = {}

--Initialize components--
PDI.utilities.init(PDI)
PDI.api_manager.init(PDI)
PDI.coroutine_manager.init(PDI)
PDI.datasource_manager.init(PDI)
PDI.dataset_manager.init(PDI)
PDI.report_manager.init(PDI) 
PDI.save_manager.init(PDI)
:next(
    function()
        mod:notify("Save files loaded")
        PDI.report_manager.register_save_data_reports()
    end
)
PDI.view_manager.init(PDI)
PDI.session_manager.init(PDI)

--Main update loop--
function mod.update(main_dt)
    PDI.save_manager.update()
    PDI.coroutine_manager.update()
end

--Trigger for setting changes--
function mod.on_setting_changed(setting_id)
    if setting_id == "max_cycles" then
        local max_cyles = mod:get("max_cycles")
        PDI.coroutine_manager.max_cyles = max_cyles
    elseif setting_id == "debug_mode" then
        debug = mod:get("debug_mode")
    elseif setting_id == "auto_save" then
        PDI.save_manager.auto_save = mod:get("auto_save")
    elseif setting_id == "auto_save_interval" then
        PDI.save_manager.auto_save_interval = mod:get("auto_save_interval")
    end
end

--Triggers for initializing and finalizing a session--
function mod.on_game_state_changed(status, state_name)    
    if state_name == "GameplayStateRun" and status == "enter" and PDI.utilities.in_game() then
        PDI.session_manager.resume_or_create_session()
        PDI.datasource_manager.activate_hooks()
        mod:enable_all_hooks()
    elseif state_name == "GameplayStateRun" and status == "exit" and PDI.utilities.in_game() then
        mod:disable_all_hooks()
        PDI.session_manager.save_current_session()
    elseif state_name == "StateGameScore" and status == "enter" then
        local end_time = os.date("%X")
        PDI.session_manager.update_current_session_info({["end_time"] = end_time})
        PDI.session_manager.save_current_session()
	end
    if PDI.data.session_data and PDI.utilities.in_game() then
        PDI.data.session_data.info.status = Managers.state.game_mode:game_mode_state()
    end
end

--Open the main PDI view--
function mod.open_pdi_view()
    PDI.view_manager.open_main_view()
end

--Dump data for debugging--
function mod.debug_dump()
    mod:notify("test")
    PDI.data.save_data.report_templates = {}
    PDI.save_manager.save("save_data", PDI.data.save_data)
    :next(function()mod:echo("clear successful")end)
-- local datetime_string = os.date('%d_%m_%y_%H_%M_%S')
-- DMF:dtf(PDI.data, "PDI_data_dump_"..datetime_string, 10)
-- mod:notify("Data dump successful")
end


