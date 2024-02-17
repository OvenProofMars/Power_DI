local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local PDI = {}
local MasterItems = require("scripts/backend/master_items")
mod.version = "0.9.3"
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
PDI.lookup_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\lookup_manager]])
PDI.ui_manager = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\ui_manager]])

local debug = mod:get("debug_mode")
--Function to set debug mode--
PDI.set_debug_mode = function (value)
    debug = value
end
--Function to print certain steps for debugging--
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

--Setting functions table--
local setting_functions = {
    max_cycles = PDI.coroutine_manager.set_max_cycles,
    debug_mode = PDI.set_debug_mode,
    auto_save =  PDI.save_manager.set_auto_save,
    auto_save_interval =  PDI.save_manager.set_auto_save_interval,
    date_format = PDI.ui_manager.set_date_format,
}

--Create main data table--
PDI.data = {}

--Initialize components--
PDI.utilities.init(PDI)
PDI.save_manager.init(PDI)
:next(
    function()
        mod:notify("PDI: Save files loaded")        
    end
)
PDI.api_manager.init(PDI)
PDI.coroutine_manager.init(PDI)
PDI.datasource_manager.init(PDI)
PDI.dataset_manager.init(PDI)
PDI.report_manager.init(PDI)
PDI.lookup_manager.init(PDI)
PDI.session_manager.init(PDI)
PDI.ui_manager.init(PDI)

--Main update loop--
function mod.update(dt)
    PDI.save_manager.update()
    PDI.coroutine_manager.update()
end

--Trigger for updating settings--
function mod.on_setting_changed(setting_id)
    local new_value = mod:get(setting_id)
    local setting_function = setting_functions[setting_id]
    if setting_function then
        setting_function(new_value)
    end
end

local previous_state_name

--Triggers for initializing and finalizing a session--
function mod.on_game_state_changed(status, state_name)
    if previous_state_name == "StateTitle" and state_name == "StateMainMenu" then
        PDI.lookup_manager.add_master_item_lookup_table()
    end
    if state_name == "GameplayStateRun" and status == "enter" and PDI.utilities.in_game() then
        PDI.session_manager.resume_or_create_session()
        PDI.datasource_manager.activate_hooks()
        mod:enable_all_hooks()
    elseif state_name == "GameplayStateRun" and status == "exit" and PDI.utilities.in_game() then
        mod:disable_all_hooks()
        PDI.session_manager.save_all_data()
        PDI.save_manager.clear_auto_save_cache()
    elseif state_name == "StateGameScore" and status == "enter" then
        local end_time = os.time()
        PDI.session_manager.update_current_session_info({["end_time"] = end_time})
        PDI.session_manager.save_all_data()
        PDI.save_manager.clear_auto_save_cache()
	end
    if PDI.data.session_data and PDI.utilities.in_game() then
        local game_mode_state = Managers.state.game_mode:game_mode_state()
        PDI.session_manager.update_current_session_info({["status"] = game_mode_state})
        --PDI.data.session_data.info.status = Managers.state.game_mode:game_mode_state()
    end
    previous_state_name = state_name
end

--Hook to check if a session has ended, to update info in the save files--
mod:hook_safe(CLASS.GameModeManager, "rpc_game_mode_end_conditions_met", function(self, channel_id, outcome_id)
	local outcome = NetworkLookup.game_mode_outcomes[outcome_id]
    PDI.session_manager.update_current_session_info({["outcome"] = outcome})
end)

--Toggle the PDI UI--
function mod.open_pdi_view()
    PDI.ui_manager.toggle_view()
end

--Dump data for debugging--
function mod.debug_dump()
    local datetime_string = os.date('%d_%m_%y_%H_%M_%S')
    DMF:dtf(PDI.data, "PDI_data_dump_"..datetime_string, 20)
    mod:notify("Data dump successful")
end
--Function to clear all user report templates--
function mod.clear_user_reports()
    PDI.data.save_data.report_templates = {}
    PDI.save_manager.save("save_data", PDI.data.save_data)
    :next(function()mod:echo("User report templates cleared successfully, requires restart to show")end)
end

--Testing function--
function mod.testing()

end