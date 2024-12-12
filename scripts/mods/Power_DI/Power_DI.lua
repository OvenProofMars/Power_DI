local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local PDI = {}
mod.version = "1.1.7"
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
PDI.set_debug_mode = function(value)
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

local open_ui_on_end_screen = mod:get("open_ui_on_end_screen")
--Function to set the open_ui_on_end_screen settings
PDI.set_open_ui_on_end_screen = function(value)
    open_ui_on_end_screen = value
end

--Setting functions table--
local setting_functions = {
    max_cycles = PDI.coroutine_manager.set_max_cycles,
    debug_mode = PDI.set_debug_mode,
    auto_save =  PDI.save_manager.set_auto_save,
    auto_save_interval =  PDI.save_manager.set_auto_save_interval,
    date_format = PDI.ui_manager.set_date_format,
    open_ui_on_end_screen = PDI.open_ui_on_end_screen
}

--Create main data table--
PDI.data = {}

--Initialize components--
PDI.utilities.init(PDI)
PDI.save_manager.init(PDI)
:next(
    function()
        mod:notify(mod:localize("mloc_notification_save_files_loaded"))
        PDI.save_files_loaded = true        
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

mod.get_loaded_session_id = PDI.session_manager.get_loaded_session_id

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
local previous_status

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
        if previous_state_name ~= "GameplayStateRun" and previous_status ~= "exit" then
            PDI.session_manager.resume_or_create_session()
            PDI.session_manager.save_all_data()
            PDI.save_manager.clear_auto_save_cache()
        end
        local end_time = os.time()
        PDI.session_manager.update_current_session_info({["end_time"] = end_time})
        PDI.session_manager.save_all_data()
        PDI.save_manager.clear_auto_save_cache()

        if open_ui_on_end_screen then
            PDI.ui_manager.toggle_view()
        end
	end
    if PDI.data.session_data and PDI.utilities.in_game() then
        local game_mode_state = Managers.state.game_mode:game_mode_state()
        PDI.session_manager.update_current_session_info({["status"] = game_mode_state})
    end
    previous_state_name = state_name
    previous_status = status
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
    local filename = "PDI_data_dump_"..datetime_string
    PDI.utilities.dump(PDI.data, filename)
    DMF:dtf(PDI.data, "PDI_data_dump_"..datetime_string, 20)
    mod:notify(mod:localize("mloc_notification_data_dup_successful"))
end
--Function to clear all user report templates--
function mod.clear_user_reports()
    local user_reports = PDI.data.save_data.report_templates
    for key, _ in pairs(user_reports) do
        user_reports[key] = nil
    end
    PDI.save_manager.save("save_data", PDI.data.save_data)
    :next(
        function()
            mod:notify(mod:localize("mloc_notification_user_reports_cleared"))
        end
    )
end

--Function to toggle forcing report generation, avoiding cache
function mod.toggle_force_report_generation()
    local new_state = PDI.ui_manager.toggle_force_report_generation()
    local state_string = new_state and "mloc_enabled" or "mloc_disabled"
    mod:notify(mod:localize("mloc_notification_toggle_force_report_generation").." "..mod:localize(state_string))
end


--Testing functions--
function mod.testing()
end
function mod.testing2()
end
