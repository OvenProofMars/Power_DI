local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local WwiseGameSyncSettings = require("scripts/settings/wwise_game_sync/wwise_game_sync_settings")

local view_templates = {
    pdi_main_view = {
        view_name = "pdi_main_view",
        view_settings = {
            init_view_function = function(ingame_ui_context)
                return true
            end,
            state_bound = true,
            display_name = "loc_eye_color_sienna_desc", -- Only used for debug
            path = [[Power_DI\scripts\mods\Power_DI\views\pdi_main_view]],
            package = "packages/ui/views/mission_board_view/mission_board_view",
            class = "PdiMainView",
            disable_game_world = false,
            load_always = true,
            load_in_hub = true,
            game_world_blur = 1.1,
            enter_sound_events = {
                UISoundEvents.system_menu_enter,
            },
            exit_sound_events = {
                UISoundEvents.system_menu_exit,
            },
            wwise_states = {
                options = WwiseGameSyncSettings.state_groups.options.ingame_menu,
            },
        },
        view_transitions = {},
        view_options = {
            close_all = true,
            close_previous = true,
            close_transition_time = nil,
            transition_time = nil,
        },
    }
}

return view_templates