local mod = get_mod("Power_DI")

local view_templates = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\view_templates]])
local renderer_templates = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\renderer_templates]])

local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIAnimation = require("scripts/managers/ui/ui_animation")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local WorldRenderUtils = require("scripts/utilities/world_render")
local ScriptWorld = require("scripts/foundation/utilities/script_world")
local PlayerInfo = require("scripts/managers/data_service/services/social/player_info")

local circumstance_templates = require("scripts/settings/circumstance/circumstance_templates")
local ScrollbarPassTemplates = require("scripts/ui/pass_templates/scrollbar_pass_templates")
local DropdownPassTemplates = require("scripts/ui/pass_templates/dropdown_pass_templates")
local TextInputPassTemplates = require("scripts/ui/pass_templates/text_input_pass_templates")
local CustomMultiLineTextInput = mod:io_dofile("Power_DI/scripts/mods/Power_DI/templates/widgets/custom_multi_line_text_input")

local BrokerArchetype = require("scripts/settings/archetype/archetypes/broker_archetype")

local input_manager = Managers.input
local input_service = input_manager and input_manager:get_input_service("View")

local UIManager = Managers.ui
local PDI, render_settings, sizes, packages_loaded, main_view_instance, selected_session_id, load_session, loaded_session, delete_session, selected_report_id, load_report, loaded_report, user_reports, loading, load_edit, edit_mode_cache, error_message, in_game, focussed_hotspot, localize, delete_animation_progress, active_scenegraph
local force_report_generation = false

local ui_manager = {}

local renderers = {}
local renderer_order = {"offscreen_renderer_1", "offscreen_renderer_2", "offscreen_renderer_3", "default_renderer"}

local scenegraphs_data = {}

local font_size = 18
local font_type = "proxima_nova_bold"
local font_color = Color.terminal_text_body(200, true)
local circumstance_color = {200,238,186,74}
local terminal_green_color = Color.terminal_text_body(200, true)
local gold_color = {200,238,186,74}
local disabled_color = {200,150,150,150}
local delete_color = {255,255,75,75}
local delete_color_background = {150,200,50,20}
local gold_highlight_color = {255,238,186,74}
local padding = 10

local date_format = mod:get("date_format")

local view_name = "pdi_main_view"

local packages_array = {
    "packages/ui/views/mission_board_view/mission_board_view",
    "packages/ui/views/crafting_view/crafting_view",
    "packages/ui/views/store_view/store_view",
    "packages/ui/hud/mission_objective_popup/mission_objective_popup",
    "packages/ui/hud/interaction/interaction",
    "packages/ui/views/main_menu_view/main_menu_view",
    "packages/ui/views/store_item_detail_view/store_item_detail_view"
}

local edit_pivot_table_functions = {}
local renderer_name_lookup = {
    default = "default_renderer",
    column = "offscreen_renderer_1",
    rows = "offscreen_renderer_2",
    values = "offscreen_renderer_3",
}

--Function to check if widgets are visible when scrolling horizontally
local function is_widget_visible_horizontal (self, widget, extra_margin)
	if self._horizontal_scrollbar_active then
		local scroll_progress = self._horizontal_scrollbar_widget.content.value or 0

        local total_grid_length = self._total_grid_length
        local area_size_x = self._area_size[1]
		local scroll_length = math.max(total_grid_length - area_size_x, 0)
		local scrolled_length = scroll_length * scroll_progress
		local draw_start_length = scrolled_length
		local draw_end_length = draw_start_length + area_size_x
		local content = widget.content
		local offset = widget.offset
		local size = content.size
		local size_length = size[1]
		local start_position_start = math.abs(offset[1])
		local start_position_end = start_position_start + size_length

		if draw_end_length < start_position_start then
			return false
		elseif start_position_end < draw_start_length then
			return false
		end
	end

	return true
end
--Function to get a modified scrollbar template
local function get_custom_scrollbar_template()
    local template = table.clone(ScrollbarPassTemplates.terminal_scrollbar)

    local thumb_pass = template[8]
    thumb_pass.style.idle_color = terminal_green_color
    thumb_pass.style.highlight_color = terminal_green_color

    return template
end
--Function to get the custom horizontal scrollbar template
local function get_custom_horizontal_scrollbar_template()

    local function horizontal_scrollbar_logic_function(pass, ui_renderer, ui_style, content, position, size)

        local grid = content.grid
        local scrollbar_scenegraph_id = content.scrollbar_scenegraph_id
        local pivot_scenegraph_id_array = content.pivot_scenegraph_id
        if not grid or not scrollbar_scenegraph_id or not pivot_scenegraph_id_array then
            return
        end

        local initialized = content.initialized
        local force_update = content.force_update

        if not initialized or force_update then
            local scenegraph = grid._scenegraph
            local scrollbar = scenegraph[scrollbar_scenegraph_id]
            local scrollbar_size = scrollbar.size
            local style = ui_style.parent

            local texture_pivot = {0.5*scrollbar_size[2],0.5*scrollbar_size[2]}

            local track_background_style = style.track_background
            track_background_style.size = {scrollbar_size[2],scrollbar_size[1]}
            track_background_style.pivot = texture_pivot
            local track_frame_style = style.track_frame
            track_frame_style.size = {scrollbar_size[2],scrollbar_size[1]}
            track_frame_style.pivot = texture_pivot
            local area_scenegraph_id  = grid._area_scenegraph_id
            local area_scenegraph = scenegraph[area_scenegraph_id]
            local visible_x = area_scenegraph.size[1]
            local total_x = grid._total_grid_length
            local thumb_ratio = visible_x/total_x

            if thumb_ratio >= 1 then
                content.visible = false
            end

            local thumb_size = {scrollbar_size[2], scrollbar_size[1] * thumb_ratio}
            content.max_thumb_offset = (scrollbar_size[1] - thumb_size[2])
            local thumb_style = style.thumb
            thumb_style.size = thumb_size
            thumb_style.pivot = texture_pivot
            local hotspot_style = style.hotspot
            hotspot_style.size = {thumb_size[2],thumb_size[1]}

            content.max_scroll_amount = total_x - visible_x

            local pivot_position_array = {}
            for _, pivot_scenegraph_id in ipairs(pivot_scenegraph_id_array) do
                local pivot_scenegraph = scenegraph[pivot_scenegraph_id]
                pivot_position_array[#pivot_position_array+1] = pivot_scenegraph.position
            end

            content.pivot_position_array = pivot_position_array
            
            content.initialized = true
        end

        local hotspot = content.hotspot
        local on_pressed = hotspot.on_pressed
        local left_hold = input_service:get("left_hold")
        local current_cursor_position_x = input_service:get("cursor")[1]
        local current_thumb_offset_x = ui_style.parent.thumb.offset[1]

        if on_pressed then
            content.start_cursor_position_x= current_cursor_position_x
            content.start_thumb_offset_x = current_thumb_offset_x
        end

        local drag_active = on_pressed or content.drag_active and left_hold
        content.drag_active = drag_active

        if drag_active then
        local start_cursor_position_x = content.start_cursor_position_x
        local start_thumb_offset_x = content.start_thumb_offset_x
        local inverse_scale = render_settings.inverse_scale
        local cursor_offset_x = (current_cursor_position_x - start_cursor_position_x) * inverse_scale
        
        local max_thumb_offset = content.max_thumb_offset

        local new_thumb_offset = math.clamp(start_thumb_offset_x+cursor_offset_x, 0, max_thumb_offset)

        local style = ui_style.parent
        local thumb_style = style.thumb
        thumb_style.offset[1] = new_thumb_offset
        local hotspot_style = style.hotspot
        hotspot_style.offset[1] = new_thumb_offset

        local scroll_percent = math.auto_lerp(0, max_thumb_offset, 0, 1, new_thumb_offset)
        content.value = scroll_percent

        local max_scroll_amount = content.max_scroll_amount
        
        local new_pivot_position_x = max_scroll_amount * scroll_percent

        local pivot_position_array = content.pivot_position_array

        for _, pivot_position in ipairs(pivot_position_array) do
            pivot_position[1] = -1 * new_pivot_position_x
        end

        local scenegraph = grid._scenegraph
        local render_scale = render_settings.scale

        UIScenegraph.update_scenegraph(scenegraph, render_scale)

        else
            content.cursor_x_start = nil
            content.thumb_x_start = nil 
        end
    end
    
    local scrollbar_template = {
        {   style_id = "track_background",
            pass_type = "rotated_texture",
            value = "content/ui/materials/scrollbars/scrollbar_thumb_default",
            style = {
                vertical_alignment = "top",
                horizontal_alignment = "left",
                angle = math.rad(90),
                color = Color.black(255, true),
                size = {0,0},
                offset = {0,0,0}
            },
        },
        {   style_id = "track_frame",
            pass_type = "rotated_texture",
            value = "content/ui/materials/scrollbars/scrollbar_frame_default",
            style = {
                vertical_alignment = "top",
                horizontal_alignment = "left",
                angle = math.rad(90),
                size = {0,0},
                offset = {0,0,3},
                color = Color.terminal_frame(255, true)
            },
        },
        {   style_id = "thumb",
            pass_type = "rotated_texture",
            value = "content/ui/materials/scrollbars/scrollbar_thumb_default",
            style = {
                vertical_alignment = "top",
                horizontal_alignment = "left",
                angle = math.rad(90),
                size = {0,0},
                offset = {0,0,2},
                color = terminal_green_color,
            },
        },
        {   content_id = "hotspot",
            style_id = "hotspot",
            pass_type = "hotspot",
            content = {
                use_is_focused = true,
            },
            style = {
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {0,0},
                offset = {0,0,10},
                color = {255,255,0,0}
            }
        },
        {   value_id = "horizontal_scrollbar_logic",
            pass_type = "logic",
            value = horizontal_scrollbar_logic_function
        },
    }

    return scrollbar_template
end
--Function to get a modified text input template
local function get_custom_text_input_template()
    local function text_input_hotspot_change_function(hotspot_content, style)
        local content = hotspot_content.parent
    
        if content.last_frame_left_pressed and hotspot_content.on_pressed then
            local is_writing = not content.is_writing
    
            if is_writing then
                local input_text = content.input_text
                local text_length = input_text and Utf8.string_length(input_text) or 0
                content.caret_position = text_length+1
                content.force_caret_update = true
    
                -- if input_text and text_length > 0 and not content.selected_text then
                --     content.input_text = ""
                --     content.selected_text = input_text
                -- end
            end
    
            content.is_writing = true
        elseif content.last_frame_left_pressed then
            content.is_writing = false
        end
    
        content.last_frame_left_pressed = input_service:get("left_pressed")
    end
    local template = table.clone(TextInputPassTemplates.terminal_input_field)

    template[1].change_function = text_input_hotspot_change_function

    template[1].visibility_function = function(content)
        if not focussed_hotspot then
            return true
        else
            return false
        end
    end

    template[8].style.color[1] = 50
    template[10].style.text_color = font_color
    template[10].style.default_text_color = font_color
    template[10].style.font_size = font_size
    template[10].style.default_font_size = font_size
    template[11].style.color = font_color

    table.remove(template,9)

    return template
end
--Function to get the options for dropdown widgets
local function get_dropdown_options(dropdown_name)
    local function convert_array_to_options(input_array)
        local options = {}
        for _, option_name in ipairs(input_array) do
            local temp_table = {}
            temp_table.id = option_name
            temp_table.display_name = localize(option_name)
            options[#options+1] = temp_table
        end
        table.sort(options,function(v1,v2)return v1.display_name < v2.display_name end)
        return options
    end
    local options_lookup = {}

    local templates_array = PDI.report_manager.get_available_reports()
    options_lookup.templates = convert_array_to_options(templates_array)
    local none_option = {
        id = 1,
        display_name = mod:localize("mloc_none")
    }
    table.insert(options_lookup.templates,1,none_option)

    local dataset_array = PDI.dataset_manager.get_available_datasets()
    options_lookup.datasets = convert_array_to_options(dataset_array)

    local report_type_array = {"mloc_report_type_pivot_table"}
    options_lookup.report_types = convert_array_to_options(report_type_array)

    options_lookup.value_types = {
        {
            id = "sum",
            display_name = mod:localize("mloc_edit_item_type_sum")
        },
        {
            id = "count",
            display_name = mod:localize("mloc_edit_item_type_count")
        },
    }

    options_lookup.value_formats = {
        {
            id = "none",
            display_name = mod:localize("mloc_edit_item_format_none")
        },
        {
            id = "number",
            display_name = mod:localize("mloc_edit_item_format_number")
        },
        {
            id = "percentage",
            display_name = mod:localize("mloc_edit_item_format_percent")
        },
    }

    options_lookup.boolean = {
        {
            id = true,
            display_name = mod:localize("mloc_true")
        },
        {
            id = false,
            display_name = mod:localize("mloc_false")
        },
    }

    return options_lookup[dropdown_name]
end
--Function that sets/updates the render settings
local function set_render_settings()
    render_settings = {
        world_target_position = false,
        color_intensity_multiplier = 1,
        start_layer = 900,
        scale = RESOLUTION_LOOKUP.scale,
        inverse_scale = RESOLUTION_LOOKUP.inverse_scale,
        material_flags = 0,
        alpha_multiplier = 1
    }
end
--Function to register the main view
local function register_views()
    for _, view_template in pairs(view_templates) do
        local path = view_template.view_settings.path
        mod:add_require_path(path)
        mod:register_view(view_template)
    end
end
--Function to load all necessary packages
local function load_packages()
    packages_loaded = false
    for _, package_name in ipairs(packages_array) do
        Managers.package:load(package_name, "PDI")
    end
end
--Function to check if all packages have been loaded
local function update_packages_loaded()
    if packages_loaded then
        return packages_loaded
    end
    for _, package in ipairs(packages_array) do
        if not Managers.package:has_loaded(package) then
            return packages_loaded
        end
    end
    packages_loaded = true
    return packages_loaded
end
--Function to create the different renderers needed for rendering widgets
local function create_renderers()
    for _, renderer_name in pairs(renderer_order) do
        local renderer_template = renderer_templates[renderer_name]
        local ui_manager = Managers.ui
        local class_name = "PDI"
        local view_name = "pdi_main_view"
        local timer_name = "ui"
        local renderer_template_name = renderer_template.name
        local renderer_name = class_name..".."..renderer_template_name
        local world_name = renderer_name.."_world"
        local world_layer = renderer_template.world_layer
        local viewport_name = renderer_name.."_viewport"
        local viewport_type = renderer_template.viewport_type
        local viewport_layer = renderer_template.viewport_layer
        local shading_environment = renderer_template.shading_environment
        local shading_callback = renderer_template.shading_callback

        local world = ui_manager:create_world(world_name, world_layer, timer_name, view_name)
        local viewport = ui_manager:create_viewport(world, viewport_name, viewport_type, viewport_layer, shading_environment, shading_callback)
        local renderer = ui_manager:create_renderer(renderer_name, world)

        local temp_table = {}

        temp_table.world = world
        temp_table.world_name = world_name

        temp_table.viewport = viewport
        temp_table.viewport_name = viewport_name

        temp_table.renderer = renderer
        temp_table.renderer_name = renderer_name

        temp_table.scenegraphs = {}

        renderers[renderer_template_name] = temp_table
    end
end
--Function to create the renderer for the background blur effect
local function create_background_renderer()
    -- if UIManager:view_instance("main_menu_view") then
    --     return
    -- end
    local renderer_template = renderer_templates["background_renderer"]
    local ui_manager = Managers.ui
    local class_name = "PDI"
    local view_name = "pdi_main_view"
    local timer_name = "ui"
    local renderer_template_name = renderer_template.name
    local renderer_name = class_name..".."..renderer_template_name
    local world_name = renderer_name.."_world"
    local world_layer = renderer_template.world_layer
    local viewport_name = renderer_name.."_viewport"
    local viewport_type = renderer_template.viewport_type
    local viewport_layer = renderer_template.viewport_layer
    local shading_environment = renderer_template.shading_environment
    local shading_callback = renderer_template.shading_callback

    local world = ui_manager:create_world(world_name, world_layer, timer_name, view_name)
    local viewport = ui_manager:create_viewport(world, viewport_name, viewport_type, viewport_layer, shading_environment, shading_callback)
    local renderer = ui_manager:create_renderer(renderer_name, world)

    local temp_table = {}

    temp_table.world = world
    temp_table.world_name = world_name

    temp_table.viewport = viewport
    temp_table.viewport_name = viewport_name

    temp_table.renderer = renderer
    temp_table.renderer_name = renderer_name

    temp_table.scenegraphs = {}

    renderers[renderer_template_name] = temp_table

    WorldRenderUtils.enable_world_fullscreen_blur(world_name, viewport_name, 0.75)
end
--Function to destroy all renderers used for drawing widgets
local function destroy_renderers()
    for _, renderer_name in pairs(renderer_order) do
        local renderer_settings = renderers[renderer_name]
        local renderer_name = renderer_settings.renderer_name
        Managers.ui:destroy_renderer(renderer_name)

		local world = renderer_settings.world
		local viewport_name = renderer_settings.viewport_name

		ScriptWorld.destroy_viewport(world, viewport_name)
		Managers.ui:destroy_world(world)

        renderer_settings.renderer = nil
        renderer_settings.renderer_name = nil

        renderer_settings.viewport = nil
        renderer_settings.viewport_name = nil

        renderer_settings.world = nil
        renderer_settings.world_name = nil
    end
end
--Function to destroy the renderer used for the background blur effect
local function destroy_background_renderer()
 
    local renderer_settings = renderers.background_renderer

    if not renderer_settings then
        return
    end

    WorldRenderUtils.disable_world_fullscreen_blur(renderer_settings.world_name, renderer_settings.viewport_name)

    local renderer_name = renderer_settings.renderer_name
    Managers.ui:destroy_renderer(renderer_name)

    local world = renderer_settings.world
    local viewport_name = renderer_settings.viewport_name

    ScriptWorld.destroy_viewport(world, viewport_name)
    Managers.ui:destroy_world(world)

    renderer_settings.renderer = nil
    renderer_settings.renderer_name = nil

    renderer_settings.viewport = nil
    renderer_settings.viewport_name = nil

    renderer_settings.world = nil
    renderer_settings.world_name = nil
end
--Function to check if the user pressed back/esc
local function check_back_pressed()
    if not main_view_instance or Managers.ui:active_top_view() ~= view_name then
        return
    end

    if input_service:get("back_released") then
        ui_manager.toggle_view()
    end
end
--Function that generates a table with sizes for the UI--
local function generate_default_sizes()
    local sizes = {}
    sizes.screen = {1920,1080}
    local main_view_size = {1820,980}
    local padding_half = padding / 2
    sizes.padding = padding
    sizes.padding_half = padding_half
    sizes.main_view = main_view_size
    sizes.header_1 = {main_view_size[1], main_view_size[2]*0.1}
    sizes.header_2 = {main_view_size[1], main_view_size[2]*0.075}
    sizes.header_tab = {main_view_size[1]*0.10, sizes.header_2[2]-padding}
    sizes.main_footer = {main_view_size[1], main_view_size[2]*0.025}
    local workspace_outer_size = {main_view_size[1], main_view_size[2]*0.8}
    local workspace_middle_size = {workspace_outer_size[1] - padding, workspace_outer_size[2] - padding}
    local workspace_inner_size = {workspace_outer_size[1] - (2*padding), workspace_outer_size[2] - (2*padding)}
    sizes.workspace_outer = workspace_outer_size
    sizes.workspace_middle = workspace_middle_size
    sizes.workspace_inner = workspace_inner_size
    sizes.anchor = {50,50+sizes.header_1[2]}
    sizes.workspace_anchor = {sizes.anchor[1], sizes.anchor[2] + sizes.header_2[2]}
    
    sizes.header_1_height = workspace_inner_size[2] * 0.1
    sizes.header_2_height = workspace_inner_size[2] * 0.075
    sizes.header_3_height = workspace_inner_size[2] * 0.05
    sizes.divider_height = 2
    sizes.scrollbar_width = 10

    sizes.report_anchor = {50 + (workspace_outer_size[1]/5) - padding_half,50 + sizes.header_1[2] + sizes.header_2[2]}
    local report_outer_size = {workspace_outer_size[1]*0.8, workspace_outer_size[2]}
    local report_inner_size = {report_outer_size[1]-(2*padding), report_outer_size[2]-(2*padding)}
    sizes.report_outer = report_outer_size
    sizes.report_inner = report_inner_size

    sizes.report_item_size = {sizes.workspace_inner[1]/5 - (2*padding) - sizes.scrollbar_width,sizes.header_3_height}

    sizes.loading_icon = {sizes.report_inner[1]*0.25, sizes.report_inner[1]*0.25}

    local rc_factor = 2/7
    local rc_factor_inv = 1 - rc_factor

    sizes.pt_headers = {report_inner_size[1], sizes.header_2_height + padding}
    sizes.pt_title_outer = {sizes.pt_headers[1]*rc_factor, sizes.pt_headers[2]}
    sizes.pt_title_inner = {sizes.pt_title_outer[1]-padding, sizes.pt_title_outer[2]-padding}
    sizes.pt_title_item = {sizes.pt_title_inner[1]-padding, sizes.pt_title_inner[2]-padding}
    sizes.pt_columns_outer = {sizes.pt_headers[1]*rc_factor_inv, sizes.pt_headers[2]}
    sizes.pt_columns_inner = {sizes.pt_columns_outer[1]-padding,sizes.header_2_height}
    sizes.pt_columns_item = {(sizes.pt_columns_inner[1]-padding_half)*0.25 - padding_half,sizes.pt_columns_inner[2]-padding}
    sizes.pt_columns_item_player_icon = {sizes.pt_columns_item[2], sizes.pt_columns_item[2]}
    sizes.pt_columns_item_player_name = {sizes.pt_columns_item[1] - sizes.pt_columns_item[2], sizes.pt_columns_item[2]}
    sizes.pt_rows_outer = {report_inner_size[1]*rc_factor, report_inner_size[2] - sizes.pt_columns_outer[2]}
    sizes.pt_rows_inner = {sizes.pt_rows_outer[1]-padding, sizes.pt_rows_outer[2]-padding}
    sizes.pt_rows_item = {sizes.pt_rows_inner[1]-padding, sizes.header_3_height}
    sizes.pt_values_outer = {report_inner_size[1]*rc_factor_inv, report_inner_size[2] - sizes.pt_columns_outer[2]}
    sizes.pt_values_inner = {sizes.pt_values_outer[1]-padding, sizes.pt_values_outer[2]-padding}
    sizes.pt_values_item = {sizes.pt_columns_item[1],sizes.header_3_height}
    return sizes
end
--Function to generate block sizes, NEEDS TO BE REPLACED BY THE NEWER VERSION
local function get_block_size(columns, rows, padding_level, subtract_width, subtract_height)
    subtract_width = subtract_width or 0
    subtract_height = subtract_height or 0 
    padding_level = padding_level or 0
    local workspace_x = sizes.workspace_inner[1] - subtract_width
    local workspace_y = sizes.workspace_inner[2] - subtract_height

    local x_dimension = workspace_x / columns
    local y_dimension = workspace_y / rows

    if padding_level > 0 then
        x_dimension = x_dimension - (padding_level * padding)
        y_dimension = y_dimension - (padding_level * padding)
    end
    
    return {x_dimension,y_dimension}
end
--Function to generate block sizes, update version
local function get_block_size_NEW(area_size, columns, rows, padding_level)
    padding_level = padding_level or 0
    local area_x = area_size[1]
    local area_y = area_size[2]

    local x_dimension = area_x / columns
    local y_dimension = area_y / rows

    if padding_level > 0 then
        x_dimension = x_dimension - (padding_level * padding)
        y_dimension = y_dimension - (padding_level * padding)
    end
    
    return {x_dimension,y_dimension}
end
--Function to generate the widgets
local function generate_widgets(templates)
    local widgets = {}
    local widgets_by_name = {}
    for widget_name, widget_template in pairs(templates) do
        if type(widget_name) == "number" then
            widget_name = widget_template.name or widget_name
        end
        local passes = widget_template.passes
        local scenegraph_id = widget_template.scenegraph_id
        local widget_definition = UIWidget.create_definition(passes, scenegraph_id)
        local widget = UIWidget.init(widget_name, widget_definition)
        widgets[#widgets+1] = widget
        widgets_by_name[widget_name] = widget

    end
    return widgets, widgets_by_name
end
--Function to generate a dropdown widget
local function generate_dropdown_widget(scenegraph_name, scenegraph_id, options, max_visible_options, on_changed_callback, nothing_selected_text, add_to_renderer)
    local function clamp_string_length(input_string, max_length, font_name, font_size)
        local ui_renderer_instance = Managers.ui:ui_constant_elements():ui_renderer()
        local text_size = UIRenderer.text_size(ui_renderer_instance, input_string, font_name, font_size)
    
        local max_length = max_length * 0.99
    
        if text_size < max_length then
            return input_string
        else
            local output_string = ""
            for i = string.len(input_string), 1, -1 do
                local temp_string = string.sub(input_string, 1, i)
                temp_string = temp_string ..".."
                local temp_string_length = UIRenderer.text_size(ui_renderer_instance, temp_string, font_name, font_size)
                if temp_string_length < max_length then
                    return temp_string
                end
            end
            return output_string
        end
    end

    nothing_selected_text = nothing_selected_text or "Select..."
    local options_by_id = {}

    for index, option in ipairs(options) do
        options_by_id[option.id] = option
        options_by_id[option.id].index = index
    end

    local scenegraph_settings = scenegraphs_data[scenegraph_name]
    local scenegraph = scenegraph_settings.scenegraph
    local size = scenegraph[scenegraph_id].size
    local num_options = #options
    local num_visible_options = math.min(num_options, max_visible_options)
    local widget_definition = UIWidget.create_definition(DropdownPassTemplates.settings_dropdown(size[1], size[2], size[1], num_visible_options, true), scenegraph_id, nil, size)

    widget_definition.passes[#widget_definition.passes+1] = {
        pass_type = "logic",
        value_id = "update_logic",
        style_id = "update_logic"
    }

    for i = 1, num_visible_options, 1 do
        local style = widget_definition.style["outline_"..i]
        style.size[1] = style.size[1]-10
        local style = widget_definition.style["option_text_"..i]
        style.text_color = font_color
        style.font_size = font_size
        style.default_font_size = font_size

    end
    local text_style = widget_definition.style.text
    text_style.text_color = font_color
    text_style.default_text_color = font_color
    text_style.font_size = font_size
    text_style.default_font_size = font_size

    widget_definition.content.update_logic = function(pass, ui_renderer, logic_style, content, position, size) end
    widget_definition.style.update_logic = {}

    local widget = UIWidget.init(scenegraph_id, widget_definition)
    local content = widget.content

    content.options_by_id = options_by_id
    content.options = options
    content.grow_downwards = true

    content.entry = {}
    local entry = content.entry
    entry.options = options
    entry.widget_type = "dropdown"
    entry.widget = widget

    content.num_visible_options = num_visible_options

    content.hotspot.pressed_callback = function ()
        local is_disabled = content.entry.disabled or false

        if is_disabled then
            return
        end
        content.exclusive_focus = true
        local hotspot = content.hotspot or content.button_hotspot

        if hotspot then
            hotspot.is_selected = true
        end
    end

    local hotspot_pass = widget.passes[1]

    hotspot_pass.visibility_function = function(content)
        local parent_content = content.parent
        if parent_content.disabled then
            return false
        end

        local hotspot_content = parent_content.hotspot 

        if not hotspot_content.not_first_frame then
            hotspot_content.not_first_frame = true
            return true
        end
        if not focussed_hotspot then
            return true
        else
            return hotspot_content == focussed_hotspot
        end
    end

    content.area_length = size[2] * num_visible_options
    local scroll_length = math.max(size[2] * num_options - content.area_length, 0)
    content.scroll_length = scroll_length
    local spacing = 0
    local scroll_amount = scroll_length > 0 and (size[2] + spacing) / scroll_length or 0
    content.scroll_amount = scroll_amount

    local function update_logic(pass, ui_renderer, logic_style, content)
        local content = widget.content
        local entry = content.entry

        if content.set_disabled then
            content.set_disabled = nil
            content.disabled = true
        end

        if content.hotspot.is_selected then
            focussed_hotspot = content.hotspot
        elseif focussed_hotspot == content.hotspot then
            focussed_hotspot = nil
        end

        local style = widget.style      
        local options_by_id = content.options_by_id
        local options = content.options
        local num_options = #options
        local num_visible_options = content.num_visible_options
        local selected_index = content.selected_index
        local selected_option
        
        if not selected_index then
            content.value_text = nothing_selected_text
        else
            local selected_option = options[selected_index]
            content.value_text = selected_option and clamp_string_length(selected_option.display_name, style.text.size[1], style.text.font_type, style.text.font_size) or nothing_selected_text
        end

        if content.close_next_frame then
            content.close_next_frame = nil
            content.exclusive_focus = false
            local hotspot = content.hotspot or content.button_hotspot
            if hotspot then
                hotspot.is_selected = false
            end
            return
        end
    
        if (input_service:get("left_pressed") or input_service:get("confirm_pressed") or input_service:get("back")) and content.open_setting then
            content.close_next_frame = true
        end
    
        if content.exclusive_focus then
            content.open_setting = true
        else
            content.open_setting = false
        end

        local start_index = content.start_index or 1
        local end_index = start_index + math.min(num_visible_options, num_options)

        local scroll_percentage = content.scroll_percentage

        if scroll_percentage then
            local step_size = 1 / (num_options - (num_visible_options - 1))
            local start_index = math.max(1, math.ceil(scroll_percentage / step_size))
            content.start_index = start_index
        end

        for i = 1, num_visible_options, 1 do
            local option_index = start_index + i -1
            local option = options[option_index]
    
            local option_text_id = "option_text_" .. i
            local option_hotspot_id = "option_hotspot_" .. i
            local outline_style_id = "outline_" .. i
            local option_hotspot = content[option_hotspot_id]
            local option_display_name = option.display_name
            local option_style = style[option_text_id]

            content[option_text_id] = clamp_string_length(option_display_name, option_style.size[1]-math.abs(option_style.size_addition[1])-math.abs(option_style.offset[1]), option_style.font_type, option_style.font_size)
            if option_hotspot.on_pressed and content.selected_index ~= option_index then
                content.selected_index = option_index
                selected_option =  options[option_index]
                content.value_text = selected_option and clamp_string_length(selected_option.display_name, style.text.size[1], style.text.font_type, style.text.font_size)
                if on_changed_callback then
                    on_changed_callback(option.id)
                end
            end
        end
    end

    content.update_logic = update_logic

    if add_to_renderer then
        scenegraph_settings.widgets_by_name[scenegraph_id] = widget
        scenegraph_settings.widgets[#scenegraph_settings.widgets+1] = widget
    end

    return widget
end
--Function to destroy all widgets
local function destroy_all_widgets()
    for renderer_name, renderer_settings in pairs(renderers) do
        renderer_settings.scenegraphs = {}
    end
end
--Function to generate the scenegraphs for all the different UI components
local function generate_scenegraph (scenegraph_name, widgets, widgets_by_name)
    local scenegraph_templates = {}
    scenegraph_templates.main_window = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        main_window = {
            parent = "screen",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.main_view,
            position = {0,0,0},
        },
        scroll_test_pivot = {
            parent = "main_window",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {0,0},
            position = {0,0,0},
        },
        scroll_test_item = {
            parent = "scroll_test_pivot",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {100,100},
            position = {0,0,0},
        },
        scroll_test_scrollbar = {
            parent = "main_window",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {500,10},
            position = {0,0,0},
        },
        header_1 = {
            parent = "main_window",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.header_1,
            position = {0,0,0},
        },
        header_2 = {
            parent = "header_1",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.header_2,
            position = {0,sizes.header_2[2],0},
        },
        exit_outer = {
            parent = "header_2",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.header_2[2],sizes.header_2[2]},
            position = {0,0,0},
        },
        exit_inner = {
            parent = "exit_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {sizes.header_2[2]-sizes.padding,sizes.header_2[2]-sizes.padding},
            position = {0,0,0},
        },
        main_workspace_outer = {
            parent = "header_2",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.workspace_outer,
            position = {0,sizes.workspace_outer[2],0}
        },
        main_workspace_middle = {
            parent = "main_workspace_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_middle,
            position = {0,0,0}
        },
        main_workspace_inner = {
            parent = "main_workspace_middle",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_inner,
            position = {0,0,0}
        },
        main_footer = {
            parent = "main_window",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.main_footer,
            position = {0,0,0},
        },
    }
    local session_item_size = get_block_size(6,2,1,sizes.scrollbar_width)
    scenegraph_templates.sessions = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        header_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.anchor,
        },
        header = {
            parent = "header_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.header_2,
            position = {0,0,0}
        },
        reports_tab = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = {sizes.header_tab[1] - sizes.padding,sizes.header_tab[2]-sizes.padding},
            position = {sizes.padding_half + sizes.padding,sizes.padding_half,0}
        },
        sessions_tab = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.header_tab,
            position = {sizes.header_tab[1] + sizes.padding_half,sizes.padding_half,0}
        },
        workspace_outer = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.workspace_outer,
            position = {0,sizes.workspace_outer[2],0}
        },
        workspace_inner = {
            parent = "workspace_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_inner,
            position = {0,0,0}
        },
        sessions_scrollbar = {
            parent = "workspace_inner",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width,get_block_size(1,1,1)[2]},
            position = {0,0,0}
        },
        sessions_pivot = {
            parent = "workspace_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0,0}
        },
        sessions_item_outer = {
            parent = "sessions_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = get_block_size(6,2,0,sizes.scrollbar_width),
            position = {0,0,0}
        },
        sessions_item_inner = {
            parent = "sessions_item_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = session_item_size,
            position = {0,0,0}
        },
        sessions_item_location = {
            parent = "sessions_item_inner",
            vertical_alignment = "top",
            horizontal_alignment = "center",
            size = {session_item_size[1],session_item_size[1]*(269/483)},
            position = {0,0,0}
        },
        sessions_item_header = {
            parent = "sessions_item_inner",
            vertical_alignment = "top",
            horizontal_alignment = "center",
            size = {session_item_size[1],session_item_size[1]*(75/483)},
            position = {0,0,0}
        },
        sessions_item_circumstance = {
            parent = "sessions_item_location",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {session_item_size[1],session_item_size[1]*(75/483)},
            position = {0,0,0}
        },
        sessions_item_circumstance_left_bar = {
            parent = "sessions_item_circumstance",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {sizes.padding_half,session_item_size[1]*(75/483)},
            position = {0,0,0}
        },
        sessions_item_circumstance_icon = {
            parent = "sessions_item_circumstance",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {session_item_size[1]*(75/483),session_item_size[1]*(75/483)},
            position = {5,0,0}
        },
        sessions_item_circumstance_title = {
            parent = "sessions_item_circumstance",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {session_item_size[1] - (session_item_size[1]*(75/483)) - 10,session_item_size[1]*(75/483)},
            position = {session_item_size[1]*(75/483)+10,0,0}
        },
        sessions_item_difficulty = {
            parent = "sessions_item_location",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {100,session_item_size[1]*(75/483)},
            position = {0,session_item_size[1]*(75/483),0}
        },
        sessions_item_difficulty_icon = {
            parent = "sessions_item_difficulty",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {session_item_size[1]*(75/483),session_item_size[1]*(75/483)},
            position = {-1*session_item_size[1]*(75/483),5,0}
        },
        sessions_item_difficulty_bar = {
            parent = "sessions_item_difficulty",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {15,session_item_size[1]*(75/483)},
            position = {0,5,0}
        },
        sessions_item_info = {
            parent = "sessions_item_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {session_item_size[1]-20,session_item_size[2] - session_item_size[1]*(194/483) - 20},
            position = {10,session_item_size[1]*(344/483)+5,0}
        },
    }
    local report_item_size = sizes.report_item_size
    scenegraph_templates.reports = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        report_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.report_anchor,
        },
        report_space_outer = {
            parent = "report_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.report_outer,
            position = {0,0},
        },
        report_space_inner= {
            parent = "report_space_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.report_inner,
            position = {0,0},
        },
        error_message= {
            parent = "report_space_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {sizes.report_inner[1] - sizes.padding,0.5*sizes.report_inner[2]},
            position = {sizes.padding,0},
        },
        report_title_outer = {
            parent = "report_space_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.pt_title_outer,
            position = {0,0},
        },
        report_title_inner = {
            parent = "report_title_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.pt_title_inner,
            position = {0,0},
        },
        edit_button_outer = {
            parent = "report_title_inner",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {sizes.pt_title_item[2],sizes.pt_title_item[2]},
            position = {sizes.padding_half,0},
        },
        edit_button_inner = {
            parent = "edit_button_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {sizes.pt_title_item[2]-sizes.padding_half,sizes.pt_title_item[2] - sizes.padding_half},
            position = {0,0},
        },
        report_title_item = {
            parent = "report_title_inner",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.pt_title_item[1]-sizes.pt_title_item[2],sizes.pt_title_item[2]},
            position = {-1*sizes.padding_half,0},
        },
        header_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.anchor,
        },
        header = {
            parent = "header_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.header_2,
            position = {0,0,0}
        },
        reports_tab = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.header_tab,
            position = {sizes.padding_half,sizes.padding_half,0}
        },
        sessions_tab = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = {sizes.header_tab[1],sizes.header_tab[2]-sizes.padding},
            position = {sizes.header_tab[1] + sizes.padding_half,sizes.padding_half,0}
        },
        workspace_outer = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.workspace_outer,
            position = {0,sizes.workspace_outer[2],0}
        },
        workspace_inner = {
            parent = "workspace_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_inner,
            position = {0,0,0}
        },
        loading_icon = {
            parent = "workspace_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.loading_icon,
            position = {0,0},
        },
        block_1_outer = {
            parent = "workspace_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = get_block_size(5,2),
            position = {0,0,0}
        },
        block_1_inner = {
            parent = "block_1_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = get_block_size(5,2,1),
            position = {0,0,0}
        },
        reports_outer = {
            parent = "block_1_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {get_block_size(5,2,1)[1], get_block_size(5,2,1)[2] - sizes.header_3_height - sizes.padding_half},
            position = {0,0,0}
        },
        reports_inner = {
            parent = "reports_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {get_block_size(5,2,2)[1], get_block_size(5,2,2)[2] - sizes.header_2_height},
            position = {sizes.padding_half,sizes.padding_half,0}
        },
        reports_scrollbar = {
            parent = "reports_outer",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width,get_block_size(5,2,2)[2] - sizes.header_3_height - sizes.padding_half},
            position = {-0.5*sizes.padding_half,0,0}
        },
        reports_pivot = {
            parent = "reports_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0,0}
        },
        reports_item = {
            parent = "reports_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_item_size,
            position = {0,0,0}
        },
        reports_item_left_bar = {
            parent = "reports_item",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {sizes.padding_half, report_item_size[2]},
            position = {0,0,0}
        },
        create_report_outer = {
            parent = "block_1_outer",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,0)[1], sizes.header_3_height},
            position = {0,0,0}
        },
        create_report_inner = {
            parent = "create_report_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1], sizes.header_3_height},
            position = {0,0,0}
        },
        block_2_outer = {
            parent = "workspace_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = get_block_size(5,2),
            position = {0,get_block_size(5,2)[2],0}
        },
        block_2_inner = {
            parent = "block_2_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = get_block_size(5,2,1),
            position = {0,0,0}
        },
        report_rows_header_outer = {
            parent = "block_2_inner",
            vertical_alignment = "top",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,0)[1], sizes.header_3_height + sizes.padding},
            position = {0,0,0}
        },
        report_rows_header_inner = {
            parent = "report_rows_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1], sizes.header_3_height},
            position = {0,0,0}
        },
        report_rows_outer = {
            parent = "report_rows_header_outer",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1], get_block_size(5,2,1)[2] - 2*(sizes.header_3_height + sizes.padding)},
            position = {0,get_block_size(5,2,1)[2] - 2*(sizes.header_3_height + sizes.padding),0}
        },
        report_rows_inner = {
            parent = "report_rows_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,2)[1], get_block_size(5,2,2)[2] - 2*(sizes.header_3_height + sizes.padding)},
            position = {0,0,0}
        },
        sessions_select_outer = {
            parent = "block_2_outer",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,0)[1], sizes.header_3_height + sizes.padding},
            position = {0,0,0}
        },
        sessions_select_inner = {
            parent = "sessions_select_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1], sizes.header_3_height},
            position = {0,0,0}
        },
        session_id = {
            parent = "sessions_select_outer",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1],sizes.main_footer[2]},
            position = {0,sizes.main_footer[2]+sizes.padding_half,0}
        },
    }
    scenegraph_templates.report_rows_order = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        header_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {sizes.anchor[1]+sizes.padding,sizes.anchor[2]+get_block_size(5,2)[2]+sizes.header_2[2]+sizes.padding_half}
        },
        block_1_outer = {
            parent = "header_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = get_block_size(5,2),
            position = {0,0,0}
        },
        block_1_inner = {
            parent = "block_1_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = get_block_size(5,2,1),
            position = {0,0,0}
        },
        report_rows_header_outer = {
            parent = "block_1_inner",
            vertical_alignment = "top",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,0)[1], sizes.header_3_height + sizes.padding},
            position = {0,0,0}
        },
        report_rows_header_inner = {
            parent = "report_rows_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1], sizes.header_3_height},
            position = {0,0,0}
        },
        report_rows_outer = {
            parent = "report_rows_header_outer",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,1)[1], get_block_size(5,2,1)[2] - (sizes.header_3_height + sizes.padding_half)},
            position = {0,get_block_size(5,2,1)[2] - (sizes.header_3_height + sizes.padding_half),0}
        },
        report_rows_inner = {
            parent = "report_rows_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {get_block_size(5,2,2)[1], get_block_size(5,2,2)[2] - (sizes.header_3_height + sizes.padding_half)},
            position = {0,0,0}
        },
        report_rows_scrollbar = {
            parent = "report_rows_inner",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width,get_block_size(5,2,2)[2] - sizes.header_3_height - sizes.padding_half},
            position = {1,0,0}
        },
        report_rows_pivot = {
            parent = "report_rows_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0,0}
        },
        report_rows_item = {
            parent = "report_rows_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_item_size,
            position = {0,0,0}
        },
        report_rows_item_left_bar = {
            parent = "report_rows_item",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {sizes.padding_half, report_item_size[2]},
            position = {0,0,0}
        },
        report_rows_item_up_arrow = {
            parent = "report_rows_item",
            vertical_alignment = "top",
            horizontal_alignment = "right",
            size = {report_item_size[2]*0.5-sizes.padding_half, report_item_size[2]*0.5-sizes.padding_half},
            position = {-1*sizes.padding,sizes.padding_half,0}
        },
        report_rows_item_down_arrow = {
            parent = "report_rows_item",
            vertical_alignment = "bottom",
            horizontal_alignment = "right",
            size = {report_item_size[2]*0.5-sizes.padding_half, report_item_size[2]*0.5-sizes.padding_half},
            position = {-1*sizes.padding,-1*sizes.padding_half,0}
        },
    }

    scenegraph_templates.pivot_table = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.report_anchor
        },
        report_outer = {
            parent = "anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.report_outer,
            position = {0,0},
        },
        report_inner = {
            parent = "report_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.report_inner,
            position = {0,0},
        },
        headers = {
            parent = "report_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.pt_headers,
            position = {0,0},
        },
        columns_outer = {
            parent = "headers",
            vertical_alignment = "top",
            horizontal_alignment = "right",
            size = sizes.pt_columns_outer,
            position = {0,0},
        },
        columns_inner = {
            parent = "columns_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.pt_columns_inner,
            position = {0,0},
        },
        columns_grid = {
            parent = "columns_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {sizes.pt_columns_inner[1] - sizes.scrollbar_width - 2*sizes.padding, sizes.pt_columns_inner[2]},
            position = {0,0},
        },
        columns_pivot = {
            parent = "columns_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0},
        },
        columns_item = {
            parent = "columns_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.pt_columns_item,
            position = {sizes.padding_half,sizes.padding_half},
        },
        columns_item_player_icon = {
            parent = "columns_item",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.pt_columns_item_player_icon,
            position = {0,0},
        },
        columns_item_player_name = {
            parent = "columns_item",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.pt_columns_item_player_name,
            position = {0,0},
        },
        rows_outer = {
            parent = "report_inner",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.pt_rows_outer,
            position = {0,0},
        },
        rows_inner = {
            parent = "rows_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.pt_rows_inner,
            position = {0,0},
        },
        rows_grid = {
            parent = "rows_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {sizes.pt_rows_inner[1], sizes.pt_rows_inner[2] - sizes.scrollbar_width - 2*sizes.padding},
            position = {0,0},
        },
        rows_pivot = {
            parent = "rows_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {sizes.padding_half,0},
        },
        rows_item = {
            parent = "rows_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.pt_rows_item,
            position = {0,0},
        },
        rows_item_collapsed = {
            parent = "rows_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {sizes.pt_rows_item[1],0},
            position = {0,0},
        },
        values_outer = {
            parent = "report_inner",
            vertical_alignment = "bottom",
            horizontal_alignment = "right",
            size = sizes.pt_values_outer,
            position = {0,0},
        },
        values_inner = {
            parent = "values_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.pt_values_inner,
            position = {0,0},
        },
        values_grid = {
            parent = "values_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {sizes.pt_values_inner[1] - sizes.scrollbar_width - 2*sizes.padding, sizes.pt_values_inner[2]- sizes.scrollbar_width - 2*sizes.padding},
            position = {0,0},
        },
        rows_values_vertical_scrollbar = {
            parent = "values_inner",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width, sizes.pt_values_inner[2] - 4*sizes.padding},
            position = {-5,0},
        },
        columns_values_horizontal_scrollbar = {
            parent = "values_inner",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {sizes.pt_values_inner[1] - 4*sizes.padding,sizes.scrollbar_width},
            position = {0,-5},
        },
        values_pivot = {
            parent = "values_inner",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0},
        },
        values_item = {
            parent = "values_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.pt_values_item,
            position = {0,0},
        },
    }

    local block_size = get_block_size_NEW(sizes.workspace_inner, 4, 1, 1)
    local block_size_half = get_block_size_NEW(sizes.workspace_inner, 4, 2, 1)
    local report_settings_row_size = {block_size_half[1]-sizes.padding, sizes.header_3_height+padding - 1}

    scenegraph_templates.edit_report_settings = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        header_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.anchor,
        },
        header = {
            parent = "header_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.header_2,
            position = {0,0,0}
        },
        edit_tab = {
            parent = "header",
            vertical_alignment = "bottom",
            horizontal_alignment = "left",
            size = sizes.header_tab,
            position = {sizes.padding_half,sizes.padding_half,0}
        },
        workspace_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.workspace_anchor,
        },
        workspace_outer = {
            parent = "workspace_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.workspace_outer,
            position = {0,0},
        },
        workspace_middle = {
            parent = "workspace_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_middle,
            position = {0,0},
        },
        workspace_inner = {
            parent = "workspace_middle",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_inner,
            position = {0,0},
        },
        block_1_outer = {
            parent = "workspace_inner",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = block_size,
            position = {sizes.padding_half,0},
        },
        report_settings_header_outer = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {0,0},
        },
        report_settings_header_inner = {
            parent = "report_settings_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding,sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        report_settings_frame = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],block_size[2] - sizes.header_2_height - 3*(sizes.header_3_height+sizes.padding_half)},
            position = {0,sizes.header_2_height},
        },
        name_row = {
            parent = "report_settings_frame",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_settings_row_size,
            position = {sizes.padding_half,0},
        },
        name_title = {
            parent = "name_row",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {0.25*report_settings_row_size[1],report_settings_row_size[2]},
            position = {sizes.padding_half,0},
        },
        name_input = {
            parent = "name_row",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {0.75*report_settings_row_size[1],report_settings_row_size[2]-sizes.padding},
            position = {0,0},
        },
        template_row = {
            parent = "report_settings_frame",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_settings_row_size,
            position = {sizes.padding_half,report_settings_row_size[2]+sizes.padding_half},
        },
        template_title = {
            parent = "template_row",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {0.25*report_settings_row_size[1],report_settings_row_size[2]},
            position = {sizes.padding_half,0},
        },
        template_input = {
            parent = "template_row",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {0.75*report_settings_row_size[1],report_settings_row_size[2]-sizes.padding},
            position = {0,0},
        },
        dataset_row = {
            parent = "report_settings_frame",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_settings_row_size,
            position = {sizes.padding_half,2*(report_settings_row_size[2]+sizes.padding_half)},
        },
        dataset_title = {
            parent = "dataset_row",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {0.25*report_settings_row_size[1],report_settings_row_size[2]},
            position = {sizes.padding_half,0},
        },
        dataset_input = {
            parent = "dataset_row",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {0.75*report_settings_row_size[1],report_settings_row_size[2]-sizes.padding},
            position = {0,0},
        },
        report_type_row = {
            parent = "report_settings_frame",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_settings_row_size,
            position = {sizes.padding_half,3*(report_settings_row_size[2]+sizes.padding_half)},
        },
        report_type_title = {
            parent = "report_type_row",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {0.25*report_settings_row_size[1],report_settings_row_size[2]},
            position = {sizes.padding_half,0},
        },
        report_type_input = {
            parent = "report_type_row",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {0.75*report_settings_row_size[1],report_settings_row_size[2]-sizes.padding},
            position = {0,0},
        },
        delete_row = {
            parent = "report_settings_frame",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {block_size[1],sizes.header_3_height},
            position = {0,sizes.header_3_height+sizes.padding_half},
        },
        exit_row = {
            parent = "report_settings_frame",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {block_size[1],sizes.header_3_height},
            position = {0,2*(sizes.header_3_height+sizes.padding_half)},
        },
        save_row = {
            parent = "report_settings_frame",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {block_size[1],sizes.header_3_height},
            position = {0,3*(sizes.header_3_height+sizes.padding_half)},
        },
    }

    local column_block_size = {block_size[1], sizes.header_2_height + sizes.header_3_height + sizes.padding}
    local rows_block_size = {block_size[1], (block_size[2]-column_block_size[2]-sizes.header_3_height-sizes.padding)/2 - sizes.header_3_height - sizes.padding}
    local values_block_size = {rows_block_size[1], rows_block_size[2] + 2*sizes.header_3_height + 2*sizes.padding}
    scenegraph_templates.edit_pivot_table = {
        screen = {
            scale = "aspect_ratio",
            size = sizes.screen,
            vertical_alignment = "center",
            horizontal_alignment = "center",
        },
        header_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.anchor,
        },
        header = {
            parent = "header_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.header_2,
            position = {0,0,0}
        },
        workspace_anchor = {
            parent = "screen",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = sizes.workspace_anchor,
        },
        workspace_outer = {
            parent = "workspace_anchor",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = sizes.workspace_outer,
            position = {0,0},
        },
        workspace_middle = {
            parent = "workspace_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_middle,
            position = {0,0},
        },
        workspace_inner = {
            parent = "workspace_middle",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = sizes.workspace_inner,
            position = {0,0},
        },
        block_1_outer = {
            parent = "workspace_inner",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = block_size,
            position = {sizes.padding_half,0},
        },
        expand_row = {
            parent = "pivot_table_settings_frame",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = report_settings_row_size,
            position = {sizes.padding_half,0},
        },
        expand_title = {
            parent = "expand_row",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {0.25*report_settings_row_size[1],report_settings_row_size[2]},
            position = {sizes.padding_half,0},
        },
        expand_input = {
            parent = "expand_row",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {0.75*report_settings_row_size[1],report_settings_row_size[2]-sizes.padding},
            position = {0,0},
        },
        dataset_fields_header_outer = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {block_size[1] + sizes.padding,0},
        },
        dataset_fields_header_inner = {
            parent = "dataset_fields_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        dataset_fields_frame = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1], block_size[2] - sizes.header_2_height},
            position = {block_size[1] + sizes.padding,sizes.header_2_height},
        },
        dataset_fields_grid = {
            parent = "dataset_fields_frame",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, block_size[2] - sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        dataset_fields_scrollbar = {
            parent = "dataset_fields_grid",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width, block_size[2] - sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        dataset_fields_pivot = {
            parent = "dataset_fields_grid",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0},
        },
        dataset_fields_item = {
            parent = "dataset_fields_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width,sizes.header_3_height},
            position = {0,0},
        },
        edit_item = {
            parent = "dataset_fields_grid",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width,sizes.header_3_height},
            position = {0,0},
        },
        column_block = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = column_block_size,
            position = {2*(block_size[1]+sizes.padding),0},
        },
        column_header_outer = {
            parent = "column_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {0,0},
        },
        column_header_inner = {
            parent = "column_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        column_frame = {
            parent = "column_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1], sizes.header_3_height + sizes.padding},
            position = {0,sizes.header_2_height},
        },
        column_grid = {
            parent = "column_frame",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1]-sizes.padding, sizes.header_3_height},
            position = {0,0},
        },
        column_pivot = {
            parent = "column_grid",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0},
        },
        column_item = {
            parent = "column_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1] - sizes.padding,sizes.header_3_height},
            position = {0,0},
        },
        rows_block = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = rows_block_size,
            position = {2*(block_size[1]+sizes.padding),column_block_size[2]},
        },
        rows_header_outer = {
            parent = "rows_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {0,0},
        },
        rows_header_inner = {
            parent = "rows_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        rows_frame = {
            parent = "rows_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1], rows_block_size[2] - sizes.header_2_height},
            position = {0,sizes.header_2_height},
        },
        rows_grid = {
            parent = "rows_frame",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, rows_block_size[2] - sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        rows_scrollbar = {
            parent = "rows_grid",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width, rows_block_size[2] - sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        rows_pivot = {
            parent = "rows_grid",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0},
        },
        rows_item = {
            parent = "rows_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width,sizes.header_3_height},
            position = {0,0},
        },
        values_block = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = rows_block_size,
            position = {2*(block_size[1]+sizes.padding),column_block_size[2]+rows_block_size[2]},
        },
        values_header_outer = {
            parent = "values_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {0,0},
        },
        values_header_inner = {
            parent = "values_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        values_frame = {
            parent = "values_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {values_block_size[1], values_block_size[2] - sizes.header_2_height},
            position = {0,sizes.header_2_height},
        },
        values_grid = {
            parent = "values_frame",
            vertical_alignment = "top",
            horizontal_alignment = "center",
            size = {values_block_size[1] - sizes.padding, values_block_size[2] - sizes.header_2_height - sizes.padding},
            position = {0,sizes.padding_half},
        },
        values_scrollbar = {
            parent = "values_grid",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {sizes.scrollbar_width, values_block_size[2] - sizes.header_2_height - 2*sizes.padding},
            position = {2.5,0},
        },
        values_pivot = {
            parent = "values_grid",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {0,0},
            position = {0,0},
        },
        values_item = {
            parent = "values_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width,sizes.header_3_height},
            position = {0,0},
        },
        values_item_expanded = {
            parent = "values_pivot",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width,5*sizes.header_3_height+ 5*sizes.padding_half},
            position = {0,0},
        },
        values_item_settings = {
            parent = "values_item_expanded",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width, 4*sizes.header_3_height+ 4*sizes.padding_half},
            position = {0,0},
        },
        values_item_setting = {
            parent = "values_item_settings",
            vertical_alignment = "top",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding - sizes.scrollbar_width,sizes.header_3_height},
            position = {0,sizes.padding_half},
        },
        values_item_setting_header = {
            parent = "values_item_setting",
            vertical_alignment = "center",
            horizontal_alignment = "left",
            size = {0.25*(block_size[1] - sizes.padding - sizes.scrollbar_width),sizes.header_3_height},
            position = {0,0},
        },
        values_item_setting_input = {
            parent = "values_item_setting",
            vertical_alignment = "center",
            horizontal_alignment = "right",
            size = {0.75*(block_size[1] - 1.5*sizes.padding - sizes.scrollbar_width),sizes.header_3_height},
            position = {-1*sizes.padding_half,0},
        },
        values_add_calculated_field = {
            parent = "values_frame",
            vertical_alignment = "bottom",
            horizontal_alignment = "center",
            size = {block_size[1],sizes.header_3_height},
            position = {0,sizes.header_3_height+sizes.padding},
        },
        data_filter_block = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1], column_block_size[2]+rows_block_size[2]},
            position = {3*(block_size[1]+sizes.padding),0},
        },
        data_filter_header_outer = {
            parent = "data_filter_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {0,0},
        },
        data_filter_header_inner = {
            parent = "data_filter_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        data_filter_frame = {
            parent = "data_filter_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1], (column_block_size[2]+rows_block_size[2]) - sizes.header_2_height},
            position = {0,sizes.header_2_height},
        },
        data_filter_input = {
            parent = "data_filter_frame",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, (column_block_size[2]+rows_block_size[2]) - sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        pivot_table_settings_block = {
            parent = "block_1_outer",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1], column_block_size[2]+rows_block_size[2]},
            position = {3*(block_size[1]+sizes.padding),column_block_size[2]+rows_block_size[2]},
        },
        pivot_table_settings_header_outer = {
            parent = "pivot_table_settings_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {block_size[1],sizes.header_2_height},
            position = {0,0},
        },
        pivot_table_settings_header_inner = {
            parent = "pivot_table_settings_header_outer",
            vertical_alignment = "center",
            horizontal_alignment = "center",
            size = {block_size[1] - sizes.padding, sizes.header_2_height - sizes.padding},
            position = {0,0},
        },
        pivot_table_settings_frame = {
            parent = "pivot_table_settings_block",
            vertical_alignment = "top",
            horizontal_alignment = "left",
            size = {values_block_size[1], values_block_size[2] - sizes.header_2_height + sizes.header_3_height + sizes.padding},
            position = {0, sizes.header_2_height},
        },
    }

    local scenegraph_template = scenegraph_templates[scenegraph_name]
    local scenegraph = UIScenegraph.init_scenegraph(scenegraph_template, render_settings.scale)

    renderers.default_renderer.scenegraphs[scenegraph] = widgets

    scenegraphs_data[scenegraph_name] = {
        scenegraph = scenegraph,
        widgets = widgets,
        widgets_by_name = widgets_by_name,
        grids = {}
    }
    return scenegraph
end
--Function to destroy a scenegraph
local function destroy_scenegraph(scenegraph_name)
    local scenegraph_settings = scenegraphs_data[scenegraph_name]
    if not scenegraph_settings then
        return
    end
    local scenegraph = scenegraph_settings.scenegraph
    for _, renderer_name in ipairs(renderer_order) do
        local renderer_settings = renderers[renderer_name]
        renderer_settings.scenegraphs[scenegraph] = nil
    end
    scenegraphs_data[scenegraph_name] = nil
end
--Function to facilitate transitions between UI components
local function destroy_scenegraphs_for_transition_to(scenegraph_name)
    local scenegraph_array_lookup = {}
    scenegraph_array_lookup.reports = {"sessions", "edit_report_settings", "edit_pivot_table"}
    scenegraph_array_lookup.sessions = {"reports", "report_rows_order", "pivot_table"}
    scenegraph_array_lookup.edit_report_settings = {"reports", "report_rows_order", "pivot_table"}

    local scenegraph_array = scenegraph_array_lookup[scenegraph_name]

    for _, scenegraph_name in ipairs(scenegraph_array) do
        destroy_scenegraph(scenegraph_name)
    end

    focussed_hotspot = nil
    error_message = nil
    load_report = false
    load_session = false
    active_scenegraph = scenegraph_name
end
--Function to create a grid
local function generate_grid(grid_name, scenegraph_name, widgets, widgets_by_name, grid_scenegraph_id, grid_direction, grid_padding_size, optional_scrollbar_name, pivot_scenegraph_id, optional_scroll_area_scenegraph_id)
    
    local scenegraph_data = scenegraphs_data[scenegraph_name]
    local scenegraph = scenegraph_data.scenegraph
    local grid = UIWidgetGrid:new(widgets, widgets, scenegraph, grid_scenegraph_id, grid_direction, grid_padding_size)
    local scrollbar = scenegraph_data.widgets_by_name[optional_scrollbar_name]
    if optional_scrollbar_name then
        optional_scroll_area_scenegraph_id = optional_scroll_area_scenegraph_id or grid_scenegraph_id
        local scrollbar = scenegraph_data.widgets_by_name[optional_scrollbar_name]
        grid:assign_scrollbar(scrollbar, pivot_scenegraph_id, optional_scroll_area_scenegraph_id)
    end
    
    local scenegraph_grids = scenegraph_data.grids
    local temp_table = {}

    temp_table.grid = grid
    temp_table.widgets_by_name = widgets_by_name
    temp_table.widgets = widgets

    scenegraph_grids[grid_name] = temp_table

    return grid
end
--Function for handeling the color/size changes of passes when hovering etc, used by most normal passes
local function item_standard_change_function (content, style)
    local content = content.parent or content
    local hotspot = content.hotspot

    if focussed_hotspot and focussed_hotspot ~= hotspot then
        return
    end

    local is_disabled = content.parent and content.parent.disabled or content.disabled

    local default_font_size = style.default_font_size

    if is_disabled then
        style.color = disabled_color
        style.text_color = disabled_color
        style.font_size = default_font_size
        return
    end

    local is_hover = hotspot.is_hover
    local is_selected  = hotspot.is_selected
    local deleting_active = content.deleting_active

    if deleting_active then
        style.color = delete_color
        style.text_color = delete_color
        style.font_size = default_font_size and default_font_size * 1.25               
    elseif is_selected and is_hover then
        style.color = gold_highlight_color
        style.text_color = gold_highlight_color
        style.font_size = default_font_size and default_font_size * 1.25
    elseif is_selected then
        style.color = gold_color
        style.text_color = gold_color
        style.font_size = default_font_size
    elseif  is_hover then
        style.color = Color.terminal_corner_hover(255, true)
        style.text_color = Color.terminal_corner_hover(255, true)
        style.font_size = default_font_size and default_font_size * 1.25
    else
        style.color = terminal_green_color
        style.text_color = font_color
        style.font_size = default_font_size
    end
end
--Function for handeling the changes for the dragable items
local function item_drag_change_function (content, style)
    if focussed_hotspot then
        return
    end
    local content = content.parent or content
    local hotspot = content.hotspot
    if not hotspot then
        return
    end

    local is_drag = content.parent and content.parent.drag_active or content.drag_active
    local is_hover = hotspot.is_hover
    local is_selected  = hotspot.is_selected
    local is_expanded = content.is_expanded
    local default_font_size = style.default_font_size
    if (is_drag or is_expanded) and is_hover then
        style.color = gold_highlight_color
        style.text_color = gold_highlight_color
        style.font_size = default_font_size and default_font_size * 1.25
    elseif is_drag or is_expanded then
        style.color = gold_color
        style.text_color = gold_color
        style.font_size = default_font_size
    elseif is_hover then
        style.color = Color.terminal_corner_hover(255, true)
        style.text_color = Color.terminal_corner_hover(255, true)
        style.font_size = default_font_size and default_font_size * 1.25
    else
        style.color = terminal_green_color
        style.text_color = font_color
        style.font_size = default_font_size
    end
end
--Function for handeling changes, which doesn't change the font size, used by a few passes
local function item_no_font_size_change_function (content, style)
    if focussed_hotspot then
        return
    end

    local content = content.parent or content
    local hotspot = content.hotspot
    if not hotspot then
        return
    end
    local is_hover = hotspot.is_hover
    local is_selected  = hotspot.is_selected
    local deleting_active = content.deleting_active
    if deleting_active then
        style.color = delete_color
        style.text_color = delete_color
        style.font_size = style.default_font_size        
    elseif is_selected and is_hover then
        style.color = gold_highlight_color
        style.text_color = gold_highlight_color
    elseif is_selected then
        style.color = gold_color
        style.text_color = gold_color
    elseif  is_hover then
        style.color = Color.terminal_corner_hover(255, true)
        style.text_color = Color.terminal_corner_hover(255, true)
    else
        style.color = terminal_green_color
        style.text_color = font_color
    end
end
--Function for handeling changes, but only changes the alpha
local function item_alpha_change_function (content, style)
    if focussed_hotspot then
        return
    end

    local hotspot = content.hotspot or content.parent.hotspot
    if not hotspot then
        return
    end
    local is_hover = hotspot.is_hover
    local color = style.color or style.text_color
    color[1] = is_hover and 255 or 200
    style.size_addition = is_hover and {sizes.padding,sizes.padding} or {0,0}
    local default_font_size = style.default_font_size
    if not default_font_size then
        return
    end
    local hover_font_size = default_font_size*1.25
    style.font_size = is_hover and hover_font_size or default_font_size

end
--Function for handeling changes for the gradient passes
local function item_gradient_standard_change_function(content, style)
    local content = content.parent or content
    local hotspot = content.hotspot
    local is_selected  = hotspot.is_selected

    if focussed_hotspot and focussed_hotspot ~= hotspot then
        if not is_selected then
            style.color = Color.terminal_background_gradient(0, true)
        end
        return
    end

    local is_disabled = content.disabled

    if is_disabled or focussed_hotspot then
        return
    end

    local is_hover = hotspot.is_hover
    
    local deleting_active = content.deleting_active

    if deleting_active then
        style.color = delete_color
    elseif is_selected and is_hover then
        style.color = Color.terminal_background_gradient_selected(255, true)
    elseif is_selected then
        style.color = Color.terminal_background_gradient_selected(150, true)
    elseif  is_hover then
        style.color = Color.terminal_background_gradient(200, true)
    else
        style.color = Color.terminal_background_gradient(0, true)
    end
end
--Function for handeling changes for the gradient passes of dragable items
local function item_gradient_drag_change_function(content, style)
    if focussed_hotspot then
        return
    end

    local hotspot = content.hotspot
    local is_hover = hotspot.is_hover
    local is_drag = content.drag_active

    if is_drag and is_hover then
        style.color = Color.terminal_background_gradient_selected(255, true)
    elseif is_drag then
        style.color = Color.terminal_background_gradient_selected(150, true)
    elseif  is_hover then
        style.color = Color.terminal_background_gradient(200, true)
    else
        style.color = Color.terminal_background_gradient(0, true)
    end
end
--Function to update all grids
local function update_grids(dt, t)
    for scenegraph_name, scenegraph_data in pairs(scenegraphs_data) do
        local scenegraph_grids = scenegraph_data.grids
        for grid_name, grid_settings in pairs(scenegraph_grids) do
            local grid = grid_settings.grid
            local widgets = grid_settings.widgets
            grid:update(dt, t, input_service)
            grid.scrollbar_active = true
            for _, widget in ipairs(widgets) do
                local is_visible_vertical = grid:is_widget_visible(widget)
                local is_visible_horizontal = is_widget_visible_horizontal(grid, widget)

                local is_visible = is_visible_vertical and is_visible_horizontal

                if grid_name == "values" then
                    widget.content.hotspot.visible = is_visible
                else
                    widget.visible = is_visible
                end
            end
        end
    end
end
--Function to create a temporary report template
local function generate_temp_report_template()
    local temp_report_template = table.clone(user_reports[selected_report_id])
    local grid_settings = scenegraphs_data.report_rows_order.grids.report_rows_order
    if not grid_settings then
        return temp_report_template
    end
    local row_oder_widgets = grid_settings.widgets
    local temp_rows = {}
    for _, widget in ipairs(row_oder_widgets) do
        local widget_name = widget.name
        temp_rows[#temp_rows+1] = widget_name
    end
    temp_report_template.rows = temp_rows
    return temp_report_template
end
--Function that handles loading and transitioning
local function handle_changes()
    if load_session then
        load_session = false
        if loaded_session and loaded_session.info.session_id == selected_session_id then
            ui_manager.setup_reports()
            return
        end

        loaded_session = nil
        loaded_report = nil
        error_message = nil

        PDI.session_manager.load_session(selected_session_id)
        :next(
            function(data)
                loaded_session = data
                if active_scenegraph == "sessions" then
                    ui_manager.setup_reports()
                end
            end,
            function(err)
                PDI.debug("handle_changes_load_session", err)
            end
        )
    elseif delete_session then
        delete_session = nil
        loaded_session = nil
        local current_selected_session_id = selected_session_id

        local sessions_grid_settings = scenegraphs_data.sessions.grids.sessions
        local sessions_grid = sessions_grid_settings.grid
        local selected_grid_index = sessions_grid:selected_grid_index()
        local sessions_grid_widgets = sessions_grid_settings.widgets
        table.remove(sessions_grid_widgets, selected_grid_index)
        for index, widget in ipairs(sessions_grid_widgets) do
            widget.content.current_grid_index = index
        end
        sessions_grid:select_grid_index(selected_grid_index)
        local new_selected_widget = sessions_grid_widgets[selected_grid_index]
        selected_session_id = new_selected_widget.content.session_id.text
        sessions_grid:force_update_list_size()

        local save_data = PDI.data.save_data
        save_data.sessions[current_selected_session_id] = nil
        local save_data_sessions_index = save_data.sessions_index
        local save_data_session_index
        for index, session_id in ipairs(save_data_sessions_index) do
            if session_id == current_selected_session_id then
                save_data_session_index = index
                break
            end
        end
        if save_data_session_index then
            table.remove(save_data_sessions_index, save_data_session_index)
        end
        PDI.save_manager.save("save_data", save_data)
        :next(
            function()
                load_session = true
            end
        )
    elseif load_report then
        if not loaded_session then
            return
        end
        load_report = false
        loaded_report = nil
        destroy_scenegraph("pivot_table")
        loading = true
        local temp_report_template = generate_temp_report_template()
        local force = force_report_generation or in_game
        PDI.report_manager.generate_report(temp_report_template, force)
        :next(
            function(data)
                local report = data[1]
                local hash_check = data[2]

                loaded_report = report

                if hash_check or selected_session_id == "local" then
                    return PDI.promise.resolved()
                end
                return PDI.session_manager.save_session()
            end,
            function(err)
                PDI.debug("handle_changes_load_report_1", err)
                error_message = err
                loading = false
            end
        )
        :next(
            function()
                if active_scenegraph ~= "reports" then
                    return
                end
                ui_manager.setup_pivot_table()
                loading = false
            end
        )
        :catch(function(err) 
            PDI.debug("handle_changes_load_report_2", err) 
            error_message = err
            loading = false
        end)
    elseif load_edit then
        edit_mode_cache = {}
        edit_mode_cache.mode = load_edit
        
        ui_manager.setup_edit_report_settings()
        if load_edit == "edit" and selected_report_id then
            local template = table.clone(user_reports[selected_report_id])
            edit_mode_cache.template = template
            ui_manager.setup_edit_pivot_table()
            edit_pivot_table_functions.create_dataset_field_widgets(template.dataset_name)edit_pivot_table_functions.load_report_template_to_edit(template)
        end
        load_edit = nil
    end
end
--Function that handles the edit mode
local function handle_edit_mode()
    if not edit_mode_cache then
        return
    end

    if edit_mode_cache.exit then
        edit_mode_cache = nil
        ui_manager.setup_reports()
        return
    end

    if edit_mode_cache.delete_report then
        PDI.report_manager.delete_user_report(selected_report_id)
        selected_report_id = nil
        edit_mode_cache = nil
        ui_manager.setup_reports()
        return
    end

    local edit_report_settings_scenegraph_settings = scenegraphs_data.edit_report_settings
    local widgets_by_name = edit_report_settings_scenegraph_settings.widgets_by_name

    local function settings_check()
        local template_input_widget = widgets_by_name.template_input
        local template_input_content = template_input_widget.content
        local template_input_selected_index = template_input_content.selected_index
        local dataset_input_widget = widgets_by_name.dataset_input
        local dataset_input_content = dataset_input_widget.content
        local dataset_input_selected_index = dataset_input_content.selected_index
        local report_type_input_widget = widgets_by_name.report_type_input
        local report_type_input_content = report_type_input_widget.content
        local report_type_input_selected_index = report_type_input_content.selected_index

        return template_input_selected_index and dataset_input_selected_index and report_type_input_selected_index and true
    end

    local function handle_new()
        local setting_changed = edit_mode_cache.setting_changed

        if setting_changed then
            destroy_scenegraph("edit_pivot_table")
        end
    
        if not edit_mode_cache.minimal_settings or setting_changed then
            if settings_check() then
                local dataset_input_widget = widgets_by_name.dataset_input
                local dataset_input_content = dataset_input_widget.content
                local dataset_input_selected_index = dataset_input_content.selected_index

                local template_input_widget = widgets_by_name.template_input
                local template_input_content = template_input_widget.content
                local template_input_selected_index = template_input_content.selected_index

                edit_mode_cache.minimal_settings = true
                edit_mode_cache.setting_changed = false
                ui_manager.setup_edit_pivot_table()
                local dataset_name = dataset_input_widget.content.options[dataset_input_selected_index].id
                edit_pivot_table_functions.create_dataset_field_widgets(dataset_name)

                if template_input_selected_index == 1 then
                    return
                end
                local name_input_widget = widgets_by_name.name_input
                local name_input_content = name_input_widget.content
                local name_input_text = name_input_content.input_text
                local template_name = template_input_widget.content.options[template_input_selected_index].id
                local template = PDI.report_manager.get_report_template(template_name)
                local template_name = template.name
                template.name = name_input_text or ""
                template.template_name = template_name
                edit_pivot_table_functions.load_report_template_to_edit(template)
            end
        end
    end

    local function save_logic()
        if not settings_check() then
            edit_mode_cache.save_check = nil
            return
        end

        local report_name_input_widget = widgets_by_name.name_input
        local report_name = report_name_input_widget.content.input_text

        if not report_name or report_name == "" then
            edit_mode_cache.save_check = nil
            return
        end
        local edit_pivot_table_scenegraph_settings = scenegraphs_data.edit_pivot_table
        local edit_pivot_table_grids = edit_pivot_table_scenegraph_settings.grids

        local column_grid_settings = edit_pivot_table_grids.column
        local column_grid_widgets = column_grid_settings.widgets

        if #column_grid_widgets == 0 then
            edit_mode_cache.save_check = nil
            return
        end

        local rows_grid_settings = edit_pivot_table_grids.rows
        local rows_grid_widgets = rows_grid_settings.widgets

        if #rows_grid_widgets == 0 then
            edit_mode_cache.save_check = nil
            return
        end

        local values_grid_settings = edit_pivot_table_grids.values
        local values_grid_widgets = values_grid_settings.widgets

        if #values_grid_widgets == 0 then
            edit_mode_cache.save_check = nil
            return
        end

        for _, value_widget in ipairs(values_grid_widgets) do
            local value_template = value_widget.content.value_template
            local label = value_template.label
            if not label or label == "" then
                edit_mode_cache.save_check = nil
                return
            end
            local value_type = value_template.type
            if not value_type then
                edit_mode_cache.save_check = nil
                return
            end
            if value_type == "calculated_field" then
                local function_string = value_template.function_string
                if not function_string or function_string == "" then
                    edit_mode_cache.save_check = nil
                    return
                end
            else
                local field_name = value_template.field_name
                if not field_name or field_name == "" then
                    edit_mode_cache.save_check = nil
                    return
                end
            end
            local format = value_template.format
            if not format then
                edit_mode_cache.save_check = nil
                return
            end
            local visible = value_template.visible
            if not type(visible) then
                edit_mode_cache.save_check = nil
                return
            end
        end

        edit_mode_cache.save_check = true
    end

    local function get_empty_report_template()
        local empty_report_template = {
            columns = {},
            rows = {},
            values = {},
            filters = {},
        }
        return empty_report_template
    end

    local function generate_report_template()
        local report_template = get_empty_report_template()

        local name_input_widget = widgets_by_name.name_input
        local name_input_content = name_input_widget.content
        local report_name = name_input_content.input_text

        local template_input_widget = widgets_by_name.template_input
        local template_input_content = template_input_widget.content
        local template_input_selected_index = template_input_content.selected_index
        local template_name = template_input_content.options[template_input_selected_index].id
        local dataset_input_widget = widgets_by_name.dataset_input
        local dataset_input_content = dataset_input_widget.content
        local dataset_input_selected_index = dataset_input_content.selected_index
        local dataset_name = dataset_input_content.options[dataset_input_selected_index].id
        local report_type_input_widget = widgets_by_name.report_type_input
        local report_type_input_content = report_type_input_widget.content
        local report_type_input_selected_index = report_type_input_content.selected_index
        local report_type_name = report_type_input_content.options[report_type_input_selected_index].id

        report_template.name = report_name
        report_template.template_name = template_name
        report_template.dataset_name = dataset_name
        report_template.report_type = report_type_name

        local scenegraph_settings = scenegraphs_data.edit_pivot_table
        local grids = scenegraph_settings.grids
        local column_widget = grids.column.widgets[1]
        
        report_template.columns[1] = column_widget.name

        local rows_widgets = grids.rows.widgets
        local rows = report_template.rows
        for _, rows_widget in ipairs(rows_widgets) do
            rows[#rows+1] = rows_widget.name
        end

        local values_widgets = grids.values.widgets
        local values = report_template.values

        for _, value_widget in ipairs(values_widgets) do
            local value_template = value_widget.content.value_template
            values[#values+1] = value_template
        end

        local data_filter_input_widget = scenegraph_settings.widgets_by_name.data_filter_input
        local data_filter_string = data_filter_input_widget.content.input_text
        report_template.filters[1] = data_filter_string

        return report_template
    end

    local mode = edit_mode_cache.mode

    if edit_mode_cache.save_report then
        edit_mode_cache.save_report = nil
        local report_template = generate_report_template()

        if mode == "edit" then
            report_template.id = selected_report_id
            user_reports[selected_report_id] = report_template
            PDI.save_manager.save_user_data()
        else
            local report_id = PDI.report_manager.add_user_report(report_template)
            selected_report_id = report_id
        end

        edit_mode_cache = nil
        ui_manager.setup_reports()
        return
    end

    if mode == "new" then
        handle_new()
    end

    save_logic()
end
--Function that returns the maximum font size so a text fits
local function adjusted_font_size(input_text, input_font_size, font_type, max_width)
    local renderer_instance = renderers.default_renderer.renderer
    local output_font_size = input_font_size
    local text_size = UIRenderer.text_size(renderer_instance, input_text, font_type, output_font_size)
    while text_size > max_width do
        output_font_size = output_font_size - 0.1
        text_size = UIRenderer.text_size(renderer_instance, input_text, font_type, output_font_size)
    end
    return output_font_size, text_size
end
--Function that returns the size of a text when rendered
local function get_text_size(input_text, font_size, font_type)
    local renderer_instance = renderers.default_renderer.renderer
    return UIRenderer.text_size(renderer_instance, input_text, font_type, font_size)
end
--Function that updates the font size of all text passes that would exceed the width of the scenegraph item
local function update_font_sizes(widgets, scenegraph_name)
    local scenegraph = scenegraphs_data[scenegraph_name].scenegraph
    for _, widget in pairs(widgets) do
        local widget_scenegraph_id = widget.scenegraph_id
        for _, pass in ipairs(widget.passes) do
            if pass.pass_type == "text" then
                local scenegraph_id = pass.scenegraph_id or widget_scenegraph_id
                local scenegraph_item = scenegraph[scenegraph_id]
                local scenegraph_item_size = scenegraph_item.size
                local style_id = pass.style_id
                local content_id = pass.content_id
                local value_id = pass.value_id
                local style = widget.style[style_id]
                local size_addition = style.size_addition or {0,0}
                local offset = style.offset
                local max_width = scenegraph_item_size[1] + size_addition[1] - offset[1] - 2*sizes.padding
                local current_font_size = style.font_size
                local content = widget.content
                local text_value = content_id and content[content_id][value_id] or content[value_id]
                
                local new_font_size = adjusted_font_size(text_value, current_font_size, font_type, max_width)

                if pass.change_function and current_font_size ~= new_font_size then
                    new_font_size = new_font_size * 0.8
                end
                style.font_size = new_font_size
                style.default_font_size = new_font_size
            end
        end
    end
end
--Function to create on click events
local function on_clicked_callback_hotspot_change_function (callback_function, content, style)
    local is_disabled = content.disabled

    if is_disabled or focussed_hotspot and focussed_hotspot ~= content then
        return
    end

    local is_hover = content.is_hover
    local last_frame_press_active = content.last_frame_press_active

    if not last_frame_press_active then
        local on_pressed = content.on_pressed
        content.last_frame_press_active = on_pressed
        return
    end

    local input_released = input_service and input_service:get("left_released")

    if not input_released then
        return
    end

    if is_hover then
        callback_function(content, style)
    end

    content.last_frame_press_active = nil
end
--function to change the grid index of a widget
local function change_grid_index(widget, grid, offset)
    local current_grid_index = widget.content.current_grid_index
    local new_grid_index = current_grid_index + offset
    local widgets = grid._widgets
    if new_grid_index < 1 or new_grid_index > #widgets then
        return
    end
    table.remove(widgets,current_grid_index)
    table.insert(widgets,new_grid_index,widget)

    grid:force_update_list_size()

    for index, widget in ipairs(widgets) do
        widget.content.current_grid_index = index
    end
end
--function to generate a custom horizontal option selection widget 
local function generate_horizontal_options_widget(scenegraph_name, scenegraph_id, options, on_changed_callback, add_to_renderer)
    local function get_option_passes()
        local passes = {
            {   pass_type = "hotspot",
                content = {
                    use_is_focused = true,
                },
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "left",
                    size = {0,0},
                    offset = {0,0,0},
                }
            },
            {   value = "temp",
                pass_type = "text",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "left",
                    text_vertical_alignment = "center",
                    text_horizontal_alignment = "center",
                    font_type = font_type,
                    font_size = font_size,
                    default_font_size = font_size,
                    text_color = font_color,
                    default_text_color = font_color,
                    size = {0,0},
                    offset = {0,0,0},
                },
            },
            {   value = "content/ui/materials/frames/line_light",
                pass_type = "texture",       
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "left",
                    color = terminal_green_color,
                    size = {0,0},
                    offset = {0,0,0},
                },
            },

            {   pass_type = "texture",
                value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "left",
                    color = {0,0,0,0},
                    size = {0,0},
                    offset = {0,0,0},
                },
            },
        }
        return passes
    end
    local scenegraph_settings = scenegraphs_data[scenegraph_name]
    local scenegraph = scenegraph_settings.scenegraph
    local scenegraph_item = scenegraph[scenegraph_id]
    local scenegraph_item_size = scenegraph_item.size

    local option_count = #options
    local option_size_x = (scenegraph_item_size[1] - ((option_count+1)*sizes.padding_half)) / option_count
    local option_size_y = scenegraph_item_size[2] - sizes.padding

    local function hotspot_function(option_id, content, style)
        local content = content.parent or content
        content.selected_id = option_id

        if on_changed_callback then
            on_changed_callback(option_id, content, style)
        end

    end
    local function standard_change_function (option_id, content, style)
        if focussed_hotspot then
            return
        end

        local content = content.parent or content
        local hotspot_content_id = "hotspot_"..tostring(option_id)
        local hotspot = content[hotspot_content_id]

        local default_font_size = style.default_font_size   
        local is_hover = hotspot.is_hover
        local is_selected = content.selected_id == option_id
        
        if is_selected and is_hover then
            style.color = gold_highlight_color
            style.text_color = gold_highlight_color
            style.font_size = default_font_size and default_font_size * 1.25
        elseif is_selected then
            style.color = gold_color
            style.text_color = gold_color
            style.font_size = default_font_size
        elseif is_hover then
            style.color = Color.terminal_corner_hover(255, true)
            style.text_color = Color.terminal_corner_hover(255, true)
            style.font_size = default_font_size and default_font_size * 1.25
        else
            style.color = terminal_green_color
            style.text_color = font_color
            style.font_size = default_font_size
        end
    end
    local function gradient_standard_change_function(option_id, content, style)
        if focussed_hotspot then
            return
        end

        local content = content.parent or content
        local hotspot_content_id = "hotspot_"..tostring(option_id)
        local hotspot = content[hotspot_content_id]

        local is_hover = hotspot.is_hover
        local is_selected = content.selected_id == option_id    
    
        if is_selected and is_hover then
            style.color = Color.terminal_background_gradient_selected(255, true)
        elseif is_selected then
            style.color = Color.terminal_background_gradient_selected(150, true)
        elseif  is_hover then
            style.color = Color.terminal_background_gradient(200, true)
        else
            style.color = Color.terminal_background_gradient(0, true)
        end
    end

    local widget_passes = {}

    for index, option in ipairs(options) do
        local option_id = option.id
        local option_display_name = option.display_name
        local option_passes = get_option_passes()
        option_passes[1].content_id = "hotspot_"..tostring(option_id)
        option_passes[1].style_id = "hotspot_"..tostring(option_id)
        local hotspot_function_callback = callback(hotspot_function, option_id)
        option_passes[1].change_function = callback(on_clicked_callback_hotspot_change_function, hotspot_function_callback)
        option_passes[1].style.size = {option_size_x, option_size_y}
        option_passes[1].style.offset[1] = sizes.padding_half + ((index-1)*(option_size_x + sizes.padding_half))
        option_passes[2].value = option_display_name
        option_passes[2].change_function = callback(standard_change_function, option_id)
        option_passes[2].style.size = {option_size_x, option_size_y}
        option_passes[2].style.offset[1] = sizes.padding_half + ((index-1)*(option_size_x + sizes.padding_half))
        option_passes[3].change_function = callback(standard_change_function, option_id)
        option_passes[3].style.size = {option_size_x, option_size_y}
        option_passes[3].style.offset[1] = sizes.padding_half + ((index-1)*(option_size_x + sizes.padding_half))
        option_passes[4].change_function = callback(gradient_standard_change_function, option_id)
        option_passes[4].style.size = {option_size_x, option_size_y}
        option_passes[4].style.offset[1] = sizes.padding_half + ((index-1)*(option_size_x + sizes.padding_half))

        for _, pass in ipairs(option_passes) do
            widget_passes[#widget_passes+1] = pass
        end
    end

    local widget_definition = UIWidget.create_definition(widget_passes, scenegraph_id)
    local widget = UIWidget.init(scenegraph_id, widget_definition)

    update_font_sizes({widget}, scenegraph_name)

    if add_to_renderer then
        scenegraph_settings.widgets_by_name[scenegraph_id] = widget
        scenegraph_settings.widgets[#scenegraph_settings.widgets+1] = widget
    end

    return widget
end

--Function to initialize the manager
ui_manager.init = function (input_table)
    PDI = input_table
    localize = PDI.utilities.localize
    sizes = generate_default_sizes()
    register_views()
    load_packages()
end
--Update function
ui_manager.update = function(dt, t)
    if not update_packages_loaded() then
        return
    end
    check_back_pressed()
    handle_changes()
    handle_edit_mode()
    update_grids(dt, t)
    
    if delete_animation_progress then
        delete_animation_progress = delete_animation_progress - dt
    end
end
--Function to draw all widgets
ui_manager.draw_widgets = function(dt, t)
    if not main_view_instance or not packages_loaded then
        return
    end
    for _, renderer_name in ipairs(renderer_order) do
        local renderer_settings = renderers[renderer_name]
        local renderer = renderer_settings.renderer
        local scenegraphs = renderer_settings.scenegraphs
        if scenegraphs and next(scenegraphs) then
            for scenegraph, widgets in pairs(scenegraphs) do
                if widgets and next(widgets) then
                    UIRenderer.begin_pass(renderer, scenegraph, input_service, dt, render_settings)
                    for _, widget in ipairs(widgets) do
                        if widget.visible then
                            UIWidget.draw(widget, renderer)
                        end
                    end
                    UIRenderer.end_pass(renderer)
                end
            end
        end
    end
end
--Function to check if it's possible to open the view
local function restricted_views_check()
    local restricted_views = {
        "title_view",
        "loading_view",
        "inventory_view",
    }
    for _, view_name in ipairs(restricted_views) do
        if UIManager:view_active(view_name) then
            return false
        end
    end
    return true
end
--Function to toggle the view
ui_manager.toggle_view = function()
    set_render_settings()
    if UIManager:view_instance("pdi_main_view") then
        Managers.ui:close_view("pdi_main_view")
    elseif restricted_views_check() and not UIManager:chat_using_input() then
        Managers.ui:open_view("pdi_main_view", nil,nil,nil,nil, PDI)
    end
end
--Function to toggle force report generation, avoiding cache
ui_manager.toggle_force_report_generation = function()
    local new_state = not force_report_generation
    force_report_generation = new_state
    return new_state
end
--Function to handle starting the UI
ui_manager.open_ui = function(instance)
    create_renderers()
    create_background_renderer()
    in_game = PDI.utilities.in_game()
    main_view_instance = instance

    user_reports = PDI.report_manager.get_user_reports()

    local session = PDI.data.session_data
    loaded_session = session
    selected_session_id = session.info.session_id

    if selected_session_id == "local" and not in_game then
        local sessions_index = PDI.data.save_data.sessions_index
        local most_recent_session_id = sessions_index[#sessions_index]
        if most_recent_session_id then
            selected_session_id = most_recent_session_id
            load_session = true
            return
        end
    end

    ui_manager.setup_main_window()
    ui_manager.setup_reports()
end
--Function to handle closing the UI
ui_manager.close_ui = function()
    active_scenegraph = nil
    main_view_instance = nil
    destroy_all_widgets()
    destroy_renderers()
    destroy_background_renderer()
end
--Function to view a player's profile
ui_manager.view_player_profile = function(player_profile)

    if player_profile and player_profile.archetype and player_profile.archetype.name == "broker" then
        player_profile.archetype.conditional_base_talent_funcs = BrokerArchetype.conditional_base_talent_funcs
    end
    
    for _, value in pairs(player_profile.loadout) do
        PDI.utilities.set_master_item_meta_table(value)
    end

    local local_player = Managers.player:local_player(1)
    local local_player_peer_id = local_player:peer_id()
    local local_player_account_id = local_player:account_id()
    local player_info = PlayerInfo:new()
    player_info:set_account(local_player_account_id)

    player_info.local_player_id = function()
        return 1
    end
    player_info.peer_id = function()
        return local_player_peer_id
    end
    player_info.profile = function()
        return player_profile
    end
    player_info.name = function()
        return player_profile.name
    end

    Managers.ui:open_view("inventory_background_view",nil, nil, nil, nil, {
        is_readonly = true,
        player = player_info
    })
end
--Function to set the date format uses by the UI
ui_manager.set_date_format = function(value)
    date_format = value
end
--Function that sets up the main window
ui_manager.setup_main_window = function()

    local widget_templates = {
        main_window = {
            passes = {
                {   pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {255,0,10,0,},
                        size = sizes.main_view,
                        offset = {0,0,-10}
                    }
                },
                {   content_id = "animated_line",
                    value_id = "material_name",
                    value = "content/ui/materials/background/blurred_rectangle",
                    pass_type = "texture",
                    style_id = "animated_line",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {150,50,75,50},
                        size = {sizes.main_view[1], 20},
                        offset = {0,0,-9}
                    },
                },
                {   conten_id = "skull_icon",
                    value_id = "material_name",
                    value = "content/ui/vector_textures/symbols/cog_skull_01",
                    pass_type = "slug_icon",
                    style_id = "skull_icon",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        size = {sizes.workspace_outer[2],sizes.workspace_outer[2]},
                        offset = {0,0,-6},
                        color = {75,0,0,0}
                    },
                    scenegraph_id = "main_workspace_inner"
                },
                {   content_id = "terminal",
                    value_id = "material_name",
                    value = "content/ui/materials/backgrounds/terminal_basic",
                    pass_type = "texture",
                    style_id = "terminal",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        scale_to_material = true,
                        color = {100,49,56,49},
                        size = sizes.main_view,
                        size_addition = {25,25},
                        offset = {0,0,-7}
                    },
                },
                {   content_id = "glow",
                    value_id = "material_name",
                    value = "content/ui/materials/effects/terminal_header_glow",
                    pass_type = "texture",
                    style_id = "glow",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {150,50,75,50},
                        size = {sizes.main_view[1]*0.75,sizes.main_view[2]},
                        offset = {0,(sizes.header_1[2]*0.5)-(sizes.main_footer[2]*0.5),-8}
                    },
                },
                {   content_id = "terminal_noise",
                    value_id = "material_name",
                    value = "content/ui/materials/buttons/background_selected_edge",
                    pass_type = "texture",
                    style_id = "terminal_noise",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        scale_to_material = true,
                        color = {100,15,25,15},
                        size = sizes.main_view,
                        offset = {0,0,10}
                    },
                },
                {   content_id = "frame_upper",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/premium_store/tabs",
                    pass_type = "texture",
                    style_id = "frame_upper",           
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_1[1]+10, sizes.header_1[2]*1.2 - sizes.padding},
                        offset = {0,-5,19}
                    },
                },
                {   content_id = "frame_lower",
                    value_id = "material_name",
                    value = "content/ui/materials/dividers/horizontal_frame_big_lower",
                    pass_type = "texture",
                    style_id = "frame_lower",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        size = {sizes.main_view[1]+5, 40},
                        offset = {0,20,11}
                    }
                },
                {   content_id = "frame_lower_skull",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/premium_store/currency_lower",
                    pass_type = "texture",
                    style_id = "frame_lower_skull",           
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        size = {200, 50},
                        offset = {0,50,20}
                    },
                },
                {   content_id = "title",
                    value_id = "text",
                    value = "Power DI",
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        size = sizes.header_1,
                        material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,-0.5*sizes.padding,20},
                        font_type = "machine_medium",
                        default_font_size = 80,
                        font_size = 80,
                        text_color = {255,255,255,255},
                    },
                },
                {   content_id = "text_mask",
                    pass_type = "rect",
                    style_id = "text_mask",
                    style = {
                        color = {200,15,25,15},
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_1[1]*0.14,sizes.header_1[2]*0.6},
                        offset = {0,sizes.header_1[2]*0.2,19}
                    },
                },
                {   content_id = "header_numbers",
                    value_id = "material_name",
                    value = "content/ui/materials/hud/backgrounds/objective_update_effect",
                    pass_type = "texture",
                    style_id = "header_numbers",
                    style = {
                        color = Color.terminal_text_body(175, true),
                        scale_to_material = true,
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_1[1]*0.8,sizes.header_1[2]},
                        offset = {0,-0.5*sizes.padding,1}
                    },
                },
                {   content_id = "version",
                    value_id = "text",
                    value = "v"..mod.version,
                    pass_type = "text",
                    style_id = "version",
                    style = {
                        text_vertical_alignment = "bottom",
                        text_horizontal_alignment = "center",
                        offset = {0,0,20},
                        font_type = font_type,
                        font_size = 16,
                        default_font_size = 16,
                        text_color = font_color,
                    },
                },               
                {   content_id = "exit_icon",
                    value_id = "material_name",
                    value = "content/ui/materials/icons/system/settings/category_interface",
                    pass_type = "texture",
                    style_id = "exit_icon",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        offset = {0,0,0},
                        color = gold_color,
                    },
                    change_function = item_alpha_change_function,
                    scenegraph_id = "exit_inner",
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, ui_manager.toggle_view),
                    scenegraph_id = "exit_inner",
                },
                {   style_id = "frame_b",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        size = {sizes.workspace_middle[1],2},
                        color = terminal_green_color,
                        offset = {0,1,0}
                    },
                    scenegraph_id = "main_workspace_middle"
                },
                {   style_id = "frame_t",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "right",
                        size = {sizes.workspace_middle[1] - (2*sizes.header_tab[1]),2},
                        color = terminal_green_color,
                        offset = {0,-1,0}
                    },
                    scenegraph_id = "main_workspace_middle"
                },
                {   style_id = "frame_l",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "left",
                        size = {2, sizes.workspace_middle[2]},
                        color = terminal_green_color,
                        offset = {-1,0,0}
                    },
                    scenegraph_id = "main_workspace_middle"
                },
                {   style_id = "frame_r",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "right",
                        size = {2, sizes.workspace_middle[2]},
                        color = terminal_green_color,
                        offset = {1,0,0}
                    },
                    scenegraph_id = "main_workspace_middle"
                },
            },
            scenegraph_id = "main_window",
        },
    }
    local widgets, widgets_by_name = generate_widgets(widget_templates)

    local scenegraph_name = "main_window"
    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)

    local function set_main_view_animations()
        local widget = scenegraphs_data.main_window.widgets_by_name.main_window
        widget.animations = {}
        local animation_time = 5
        local wait_time = 5
        local total_time = animation_time + wait_time
        local min_height = 20
        local max_height = 40
        local max_height_factor = min_height/max_height
    
        --Vertical scroll animation--
        local animation_type = UIAnimation.update_function_by_time
        local target = widget.style.animated_line.offset
        local target_index = 2
        local from = -0.5 * sizes.main_view[2] + (min_height*0.5)
        local to = 0.5 * sizes.main_view[2] - (min_height*0.5)
    
        local vertical_scroll_func = function(time)
            local modulus = time % total_time
           
            if modulus < wait_time then
                return 0
            else
                local lerp = math.auto_lerp(wait_time, total_time, 0, 1, modulus)
                return lerp
            end
        end
        local animation = UIAnimation.init(animation_type, target, target_index, from, to, math.huge, vertical_scroll_func)
        widget.animations[animation] = true
    
        --Height animation--
        local animation_type = UIAnimation.update_function_by_time
        local target = widget.style.animated_line.size
        local target_index = 2
        local from = 0
        local to = max_height
    
        local height_func = function(time)
            local modulus = time % total_time
            if modulus < wait_time then
                return 0
            else
                local lerp = math.auto_lerp(wait_time, total_time, 0, math.pi, modulus)
                lerp = math.auto_lerp(0, 1, max_height_factor, 1, math.sin(lerp))
                return lerp
            end
        end
        local animation = UIAnimation.init(animation_type, target, target_index, from, to, math.huge, height_func)
        widget.animations[animation] = true
    
        --Brightness animation--
        local animation_type = UIAnimation.update_function_by_time
        local target = widget.style.animated_line.color
        local target_index = 1
        local from = 0
        local to = 175
    
        local brightness_func = function(time)
            local modulus = time % total_time
            if modulus < wait_time then
                return 0
            else
                local lerp = math.auto_lerp(wait_time, total_time, 0, 1, modulus)
                lerp = math.auto_lerp(0, 1, max_height_factor, 1, math.sin(math.pi*lerp))
                return lerp
            end
        end
        local animation = UIAnimation.init(animation_type, target, target_index, from, to, math.huge, brightness_func)
        widget.animations[animation] = true
    end

    set_main_view_animations()
end
--Function that sets up the sessions component
ui_manager.setup_sessions = function()
    local scenegraph_name = "sessions"
    destroy_scenegraphs_for_transition_to(scenegraph_name)

    local function report_type_logic_function(pass, ui_renderer, ui_style, content, position, size)
        if active_scenegraph ~= "sessions" then
            return
        end
        local hotspot = content.hotspot
        local is_hover = hotspot.is_hover
        focussed_hotspot = is_hover and hotspot
    end

    local widget_templates = {
        reports_tab = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_reports"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size * 2,
                        default_font_size = font_size * 2,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function
                },
                {
                    pass_type = "rect",
                    style_id = "frame_t",
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_tab[1]-sizes.padding,2},
                        color = terminal_green_color,
                        offset = {0,-1,0}
                    },
                },
                {   style_id = "frame_b",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        size = {sizes.header_tab[1],2},
                        color = terminal_green_color,
                        offset = {-0.5*sizes.padding,1,0}
                    },
                },
                {   style_id = "frame_l",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "left",
                        size = {2, sizes.header_tab[2] - sizes.padding},
                        color = terminal_green_color,
                        offset = {-1,0,0}
                    },
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                        test = true
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, ui_manager.setup_reports)
                },
                {
                    value_id = "report_tab_logic",
                    pass_type  = "logic",
                    value = report_type_logic_function
                }
            },
            scenegraph_id = "reports_tab"
        },
        sessions_tab = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_sessions"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        default_font_size = font_size * 2.5,
                        font_size = font_size * 2.5,
                        text_color = gold_color,
                    },
                    
                },
                {   style_id = "frame_t",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_tab[1],2},
                        color = terminal_green_color,
                        offset = {0,-1,0}
                    },
                },
                {
                    pass_type = "rect",
                    style_id = "frame_l",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "left",
                        size = {2, sizes.header_tab[2]},
                        color = terminal_green_color,
                        offset = {-1,0,0}
                    },
                },
                {   style_id = "frame_r",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "right",
                        size = {2, sizes.header_tab[2]},
                        color = terminal_green_color,
                        offset = {1,0,0}
                    },
                },
            },
            scenegraph_id = "sessions_tab"
        },
        sessions_mask = {
            passes = {
                {   style_id = "mask", 
                    value_id = "material_name",
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_2",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                        size_addition = {0,0}
                    },
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = font_color,
                            offset = {0,0,0}
                        },
                    },
                },
            },
            scenegraph_id = "workspace_outer"
        },
        sessions_scrollbar = {
            passes = get_custom_scrollbar_template(),
            scenegraph_id = "sessions_scrollbar"
        }
    }
    local widgets, widgets_by_name = generate_widgets(widget_templates)

    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)

    update_font_sizes(widgets, scenegraph_name)

    local item_size = get_block_size(6,2,1,sizes.scrollbar_width,sizes.header_2_height)

    local function delete_session_logic(pass, ui_renderer, ui_style, content, position, size)
        if delete_session then
            return
        end
        local grid = content.grid
        local selected_grid_index = grid:selected_grid_index()
        local current_grid_index = content.current_grid_index

        if selected_grid_index ~= current_grid_index then
            return
        end

        local discard_button_pressed = input_service:get("hotkey_item_discard_pressed") 
        local discard_button_held = input_service:get("hotkey_item_discard")

        local animation_time = 1
        local timer_background_style = ui_style.parent.timer_background
        local default_size_addition_x = timer_background_style.default_size_addition[1]

        if discard_button_pressed then
            content.deleting_active = true
            delete_animation_progress = animation_time
            timer_background_style.size_addition[1] = default_size_addition_x
            timer_background_style.visible = true
        end

        if content.deleting_active and discard_button_held then
            if delete_animation_progress <= 0 then
                delete_animation_progress = nil
                content.is_active = false
                delete_session = true
                return
            end

            local size_addition_multiplier = delete_animation_progress /  animation_time
            timer_background_style.size_addition[1] = default_size_addition_x * size_addition_multiplier
        else
            delete_animation_progress = nil
            content.deleting_active = nil
            timer_background_style.visible = false
        end
    end

    local function delete_session_terminal_green_change_function (content, style)
        local content = content.parent or content
        local default_font_size = style.default_font_size
        local deleting_active = content.deleting_active
    
        if deleting_active then
            style.color = delete_color
            style.text_color = delete_color
            style.font_size = default_font_size               
        else
            style.color = terminal_green_color
            style.text_color = font_color
            style.font_size = default_font_size
        end
    end

    local session_item_size = scenegraph.sessions_item_inner.size

    local function get_item_template()
        local item_template = {
            passes = {
                {   value_id = "location_image",
                    style_id = "location_image",
                    pass_type = "texture",
                    value = "content/ui/materials/mission_board/texture_with_grid_effect",
                    scenegraph_id = "sessions_item_location",
                    style = {
                        material_values = {
                            texture_map = "content/ui/textures/missions/cm_habs_big",
                        },
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                    },
                },
                {   content_id = "frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "frame",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,0,3}
                    },
                    change_function = item_standard_change_function
                },
                {   content_id = "header_background",
                    pass_type = "rect",
                    style_id = "header_background",
                    scenegraph_id = "sessions_item_header",   
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {200,0,0,0},
                        offset = {0,0,1},
                    },
                },
                {   content_id = "header_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    scenegraph_id = "sessions_item_header",
                    pass_type = "texture",
                    style_id = "header_frame",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,0,3},
                    },
                    change_function = item_standard_change_function
                },
                {   content_id = "header_title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "header_title",
                    scenegraph_id = "sessions_item_header",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function
                },
                {   content_id = "circumstance_background",
                    pass_type = "rect",
                    style_id = "circumstance_background",
                    style = {
                        visible = false,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {200,0,0,0},
                        offset = {0,0,1},
                    },
                    scenegraph_id = "sessions_item_circumstance",
                },
                {   content_id = "circumstance_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "circumstance_frame",         
                    style = {
                        visible = false,
                        scale_to_material = true,
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        color = circumstance_color,
                        offset = {0,0,3},
                    },
                    scenegraph_id = "sessions_item_circumstance",
                },
                {   content_id = "circumstance_frame_left",
                    pass_type = "rect",
                    style_id = "circumstance_frame_left",           
                    style = {
                        visible = false,
                        vertical_alignment = "top",
                        horizontal_alignment = "left",
                        color = circumstance_color,
                        offset = {0,0,3},
                    },
                    scenegraph_id = "sessions_item_circumstance_left_bar"
                },
                {   content_id = "circumstance_title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "circumstance_title",
                    style = {
                        visible = false,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        font_type = font_type,
                        font_size = font_size*0.75,
                        default_font_size = font_size*0.75,
                        text_color = circumstance_color,
                        offset = {0,0,2},
                    },
                    scenegraph_id = "sessions_item_circumstance_title"
                },
                {   content_id = "circumstance_icon",
                    value_id = "material_name",
                    value = "content/ui/materials/icons/circumstances/more_resistance_01",
                    pass_type = "texture",
                    style_id = "circumstance_icon",           
                    style = {
                        visible = false,
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = circumstance_color,
                        offset = {0,0,2},
                        size_addition = {-10,-10}
                    },
                    scenegraph_id = "sessions_item_circumstance_icon"
                },
                {   content_id = "difficulty_icon",
                    value_id = "material_name",
                    value = "content/ui/materials/icons/generic/danger",
                    pass_type = "texture",
                    style_id = "difficulty_icon",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        size_addition = {-10,-10}
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_difficulty_icon"
                },
                {   content_id = "difficulty_bar_1",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "difficulty_bar_1",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        size_addition = {0,-10}
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_difficulty_bar"
                },
                {   content_id = "difficulty_bar_2",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "difficulty_bar_2",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        size_addition = {0,-10},
                        offset = {20,0}
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_difficulty_bar"
                },
                {   content_id = "difficulty_bar_3",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "difficulty_bar_3",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        size_addition = {0,-10},
                        offset = {40,0}
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_difficulty_bar"
                },
                {   content_id = "difficulty_bar_4",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "difficulty_bar_4",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        size_addition = {0,-10},
                        offset = {60,0}
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_difficulty_bar"
                },
                {   content_id = "difficulty_bar_5",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "difficulty_bar_5",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        size_addition = {0,-10},
                        offset = {80,0}
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_difficulty_bar"
                },
                {   content_id = "session_info",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "session_info",
                    style = {
                        line_spacing = 0.9,
                        text_vertical_alignment = "top",
                        text_horizontal_alignment = "left",
                        font_type = font_type,
                        font_size = font_size*0.75,
                        default_font_size = font_size*0.75,
                        text_color = font_color,
                        offset = {0,0,10},
                    },
                    change_function = delete_session_terminal_green_change_function,
                    scenegraph_id = "sessions_item_info"
                },
                {   content_id = "session_id_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "session_id_frame",           
                    style = {
                        scale_to_material = true,
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,0,3},
                        size = {item_size[1],20}
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "session_id",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "session_id",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,2},
                        font_type = font_type,
                        font_size = 12,
                        default_font_size = 12,
                        text_color = font_color,
                        size = {item_size[1],20}
                    },
                    change_function = item_no_font_size_change_function,
                },
                {   content_id = "hotspot",
                    pass_type = "hotspot",
                    style_id = "hotspot",
                    style = {
                        offset = {0,0,10},
                    },
                    content = {
                        on_hover_sound = UISoundEvents.default_mouse_hover,
                        on_complete_sound = UISoundEvents.default_click
                    },
                    visibility_function = function() return focussed_hotspot ~= true end
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                    },
                },
                {   value_id = "timer_background",
                    style_id = "timer_background",
                    pass_type = "rect",
                    style = {
                        color = delete_color_background,
                        offset = {0,0,-1},
                        size_addition = {-1* session_item_size[1],0},
                        default_size_addition = {-1* session_item_size[1],0},
                        visible = false
                    },
                },
                {   value_id = "delete_session_logic",
                    pass_type = "logic",
                    value = delete_session_logic
                },
            },
            scenegraph_id = "sessions_item_inner",
        }
        return item_template
    end

    local sessions_index = PDI.data.save_data.sessions_index
    local sessions_data = PDI.data.save_data.sessions

    local widget_templates = {}
    local widget_lookup = {}

    for i = #sessions_index, 1, -1 do
        local widget_index = #widget_templates+1
        local session_id = sessions_index[i]
        local session = sessions_data[session_id]
        if session then
            session = table.clone(session)
            local item_template = get_item_template()

            item_template.passes[1].style.material_values.texture_map  = session.mission.texture_big
            local mission_name = Localize(session.mission.mission_name)
            item_template.passes[5].value = mission_name
            item_template.passes[5].style.font_size = font_size * 0.9
            item_template.passes[5].style.default_font_size = font_size * 0.9
        
            local circumstance = session.mission_data and session.mission_data.circumstance

            if circumstance then
                local circumstance_template = circumstance_templates[circumstance]
                local circumstance_template_ui = circumstance_template.ui
                if circumstance_template_ui then
                    local display_name = circumstance_template_ui.display_name
                    local icon = circumstance_template_ui.icon
                    item_template.passes[6].style.visible = true
                    item_template.passes[7].style.visible = true
                    item_template.passes[8].style.visible = true
                    item_template.passes[9].style.visible = true
                    item_template.passes[9].value = Localize(display_name)
                    item_template.passes[10].style.visible = true
                    item_template.passes[10].value = icon
                end
            end
            
            for i = 1, session.difficulty, 1 do
                local pass_index = 11+i
                local pass_template = item_template.passes[pass_index]
                pass_template.pass_type = "rect"
            end

            local session_info_text = ""

            local mission_category = session.mission_data and session.mission_data.category
            if mission_category then
                mission_category = mod:localize("mloc_session_auric")
            else
                mission_category = mod:localize("mloc_session_standard")
            end
            local n_a = mod:localize("mloc_n_a")
            local start_time_epoch = session.start_time
            local end_time_epoch = session.end_time
            local date = start_time_epoch and os.date(date_format, start_time_epoch) or n_a
            local start_time = start_time_epoch and os.date("%X", start_time_epoch)
            local duration = start_time_epoch and end_time_epoch and os.date("!%X", end_time_epoch - start_time_epoch) or n_a

            local outcome_lookup = {
                won = mod:localize("mloc_session_won"),
                lost = mod:localize("mloc_session_lost")
            }

            local outcome = outcome_lookup[session.outcome] or n_a
            local resumed = session.resumed and mod:localize("mloc_true") or mod:localize("mloc_false")
            
            local nl = "\n\n"
            session_info_text = mod:localize("mloc_session_category")..mission_category..nl
            session_info_text = session_info_text..mod:localize("mloc_session_date")..date..nl
            session_info_text = session_info_text..mod:localize("mloc_session_start_time")..start_time..nl
            session_info_text = session_info_text..mod:localize("mloc_session_duration")..duration..nl
            session_info_text = session_info_text..mod:localize("mloc_session_outcome")..outcome..nl
            session_info_text = session_info_text..mod:localize("mloc_session_resumed")..resumed..nl

            item_template.passes[17].value = session_info_text

            item_template.passes[19].value = session_id

            local session_on_clicked_callback = function()
                if session_id ~= selected_session_id then
                    local grid = scenegraphs_data.sessions.grids.sessions.grid
                    local scroll_percentage = grid:get_scrollbar_percentage_by_index(widget_index)
                    grid:select_grid_index(widget_index, scroll_percentage, true)
                end
            end

            local session_selected_callback = function()
                if session_id ~= selected_session_id then
                    selected_session_id = session_id
                    load_session = true
                end
            end

            item_template.passes[20].change_function = callback(on_clicked_callback_hotspot_change_function, session_on_clicked_callback)
            item_template.passes[20].content.selected_callback = session_selected_callback

            item_template.name = session.session_id

            widget_templates[widget_index] = item_template
            widget_lookup[widget_index] = session_id
            widget_lookup[session_id] = widget_index
        end    
    end

    local widgets, widgets_by_name = generate_widgets(widget_templates)

    update_font_sizes(widgets, scenegraph_name)

    renderers.offscreen_renderer_2.scenegraphs[scenegraph] = widgets

    local grid = generate_grid(scenegraph_name, scenegraph_name, widgets, widgets_by_name, "workspace_inner", "down", {sizes.padding,sizes.padding}, "sessions_scrollbar", "sessions_pivot")

    for index, widget in ipairs(widgets) do
        widget.content.size = scenegraph.sessions_item_inner.size
        widget.content.current_grid_index = index
        widget.content.grid = grid
    end

    local widget_index = widget_lookup[selected_session_id]

    local scroll_percentage = grid:get_scrollbar_percentage_by_index(widget_index)
    grid:select_grid_index(widget_index, scroll_percentage, true)
end
--Function that sets up the reports component
ui_manager.setup_reports = function()
    local scenegraph_name = "reports"
    destroy_scenegraphs_for_transition_to(scenegraph_name)
    edit_mode_cache = nil

    local function error_message_change_function(content,style)
        if error_message then
            loading = false
            content.text = "error:\n\t"..tostring(error_message.error).."\n\n"..tostring(error_message.stacktrace)
        else
            content.text = ""
        end
    end

    local loading_frames_delay = 2
    local loading_frame_counter = 0
    local function loading_icon_visibility_function(content)
        if not loading then
            loading_frame_counter = 0
            return false
        elseif loading_frame_counter < loading_frames_delay then
            loading_frame_counter = loading_frame_counter + 1
            return false
        end
        return true
    end

    local widget_templates = {
        reports_tab = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_reports"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size*2.5,
                        default_font_size = font_size*2.5,
                        text_color = gold_color,
                    },
                },
                {
                    pass_type = "rect",
                    style_id = "frame_t",
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_tab[1],2},
                        color = terminal_green_color,
                        offset = {0,-1,0}
                    },
                },
                {   style_id = "frame_b",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        size = {sizes.header_tab[1],2},
                        color = terminal_green_color,
                        offset = {sizes.header_tab[1],1,0}
                    },
                },
                {
                    pass_type = "rect",
                    style_id = "frame_l",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "left",
                        size = {2, sizes.header_tab[2]},
                        color = terminal_green_color,
                        offset = {-1,0,0}
                    },
                },
                {
                    pass_type = "rect",
                    style_id = "frame_r",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "right",
                        size = {2, sizes.header_tab[2]},
                        color = terminal_green_color,
                        offset = {1,0,0}
                    },
                },
            },
            scenegraph_id = "reports_tab"
        },
        sessions_tab = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_sessions"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        default_font_size = font_size * 1.9,
                        font_size = font_size * 1.9,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function
                },
                {   style_id = "frame_t",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        size = {sizes.header_tab[1],2},
                        color = terminal_green_color,
                        offset = {0,-1,0}
                    },
                },
                {   style_id = "frame_r",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "right",
                        size = {2, sizes.header_tab[2]-sizes.padding},
                        color = terminal_green_color,
                        offset = {1,0,0}
                    },
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, ui_manager.setup_sessions)
                },
            },
            scenegraph_id = "sessions_tab"
        },
        report_title = {
            passes = {
                {   content_id = "report_title_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "report_title_frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0}
                    },
                    scenegraph_id = "report_title_inner"
                },
                {   content_id = "title",
                    value_id = "text",
                    value = "",
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size*2,
                        default_font_size = font_size*2,
                        text_color = gold_color,
                    },
                },
                },
                scenegraph_id = "report_title_item"
        },
        report_edit = {
            passes = {
                {   content_id = "edit_icon",
                    value_id = "material_name",
                    value = "content/ui/materials/icons/mission_types/mission_type_07",
                    pass_type = "texture",
                    style_id = "edit_icon",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = gold_color,
                        offset = {0,0,0}
                    },
                    change_function = item_alpha_change_function
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, function()load_edit = "edit" end)
                },
            },
            scenegraph_id = "edit_button_inner"
        },
        reports_mask = {
            passes = {
                {   style_id = "mask", 
                    value_id = "material_name",
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_vertical_blur",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                        size_addition = {20,5}
                    },
                },
            },
            scenegraph_id = "reports_outer"
        },
        reports_frame = {
            passes = {
                {   content_id = "reports_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "reports_frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,0,0}
                    },
                },
            },
            scenegraph_id = "reports_outer"
        },
        create_report = {
            passes = {
                {   content_id = "create_report_icon_1",
                    pass_type = "rect",
                    style_id = "create_report_icon_1",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,-6,0},
                        size = {6,6}
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "create_report_icon_2",
                    pass_type = "rect",
                    style_id = "create_report_icon_2",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,0,0},
                        size = {18,6}
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "create_report_icon_3",
                    pass_type = "rect",
                    style_id = "create_report_icon_3",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,6,0},
                        size = {6,6}
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, function()load_edit = "new" end)
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                    },
                },
                {   value_id = "frame",
                    style_id = "frame",
                    pass_type = "texture",
                    value = "content/ui/materials/frames/line_light",
                    change_function = item_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0}
                    },
                },
            },
            scenegraph_id = "create_report_inner",
        },
        reports_scrollbar = {
            passes = get_custom_scrollbar_template(),
            scenegraph_id = "reports_scrollbar"
        },
        loading_icon = {
            passes = {
                {   style_id = "loading_icon", 
                    value_id = "material_name",
                    value = "content/ui/materials/loading/loading_icon",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        offset = {0,-20,0},
                    },
                    visibility_function = loading_icon_visibility_function
                },
            },
            scenegraph_id = "loading_icon"
        },
        error_message = {
            passes = {
                {   style_id = "error_message",
                    value_id = "text",
                    value = "",
                    pass_type = "text",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = error_message_change_function
                },
                },
                scenegraph_id = "error_message"
        },
    }
    local widgets, widgets_by_name = generate_widgets(widget_templates)

    if in_game then
        widgets_by_name.sessions_tab.visible = false
    end

    local function set_report_title(report_id)
        local report_name = user_reports[report_id].name
        local report_title_widget = widgets_by_name.report_title
        report_title_widget.content.title.text = report_name
        local max_width = scenegraphs_data.reports.scenegraph.report_title_item.size[1] - sizes.padding
        local title_font_size = adjusted_font_size(report_name, font_size*2, font_type, max_width)
        report_title_widget.style.title.font_size = title_font_size
    end

    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)

    update_font_sizes(widgets, scenegraph_name)

    local function get_item_template()
        local item_template = {
            passes = {
                {   content_id = "report_name",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "report_name",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,0,2},
                        size_addition = {-1*sizes.padding,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "left_bar",
                    pass_type = "rect",
                    style_id = "left_bar",
                    style = {
                        color = font_color
                    },
                    change_function = item_standard_change_function,
                    scenegraph_id = "reports_item_left_bar"
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    }
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                    },
                },
                {   value_id = "frame",
                    style_id = "frame",
                    pass_type = "texture",
                    value = "content/ui/materials/frames/frame_tile_2px",
                    change_function = item_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0}
                    },
                },
            },
            scenegraph_id = "reports_item",
        }
        return item_template
    end

    local temp_user_reports_array = {}

    if not next(user_reports) then
        local edit_report_button_widget = widgets_by_name.report_edit
        edit_report_button_widget.visible = false
        local report_title_widget = widgets_by_name.report_title
        report_title_widget.visible = false
        loading = false
        return
    end

    for _, report_template in pairs(user_reports) do
        temp_user_reports_array[#temp_user_reports_array+1] = report_template
    end

    table.sort(temp_user_reports_array,function (v1,v2) return v1.name < v2.name end)

    local function select_report(widget_index, report_id)
        if report_id == selected_report_id then
            return
        end
        local grid = scenegraphs_data.reports.grids.reports.grid
        grid:select_grid_index(widget_index)
    end

    local function report_selected_callback(report_id)
        if report_id == selected_report_id then
            return
        end

        set_report_title(report_id)

        selected_report_id = report_id
        
        ui_manager.setup_report_rows_order()
        load_report = true
    end

    local widget_templates = {}
    local widget_lookup = {}

    for index, report_template in ipairs(temp_user_reports_array) do
        local item_template = get_item_template()
        local report_name = report_template.name
        local report_id = report_template.id
        item_template.name = report_id
        item_template.passes[1].value = report_name

        local select_report_callback = callback(select_report, index, report_id)
        item_template.passes[3].change_function = callback(on_clicked_callback_hotspot_change_function, select_report_callback)
        item_template.passes[3].content.selected_callback = callback(report_selected_callback, report_id)

        widget_templates[#widget_templates+1] = item_template
        widget_lookup[report_id] = index
        widget_lookup[index] = report_id
    end

    local widgets, widgets_by_name = generate_widgets(widget_templates)

    for _, widget in ipairs(widgets) do
        widget.content.size = scenegraph.reports_item.size
    end

    update_font_sizes(widgets, scenegraph_name)

    renderers.offscreen_renderer_1.scenegraphs[scenegraph] = widgets

    local grid = generate_grid(scenegraph_name, scenegraph_name, widgets, widgets_by_name, "reports_inner", "down", {0,sizes.padding_half}, "reports_scrollbar", "reports_pivot")

    local widget_index
    if selected_report_id then
        widget_index = widget_lookup[selected_report_id]
    else
        widget_index = 1
        selected_report_id = widget_lookup[1]
    end
    set_report_title(selected_report_id)
    local scroll_percentage = grid:get_scrollbar_percentage_by_index(widget_index)
    grid:select_grid_index(widget_index, scroll_percentage, true)
    ui_manager.setup_report_rows_order()
    load_report = true
end
--Function that sets up the reports row order component
ui_manager.setup_report_rows_order = function()
    local scenegraph_name = "report_rows_order"
    destroy_scenegraph("report_rows_order")
    local widget_templates = {  
        report_rows_header = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_report_rows"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding_half,0,0},
                        font_type = font_type,
                        font_size = font_size*2,
                        default_font_size = font_size*2,
                        text_color = gold_color,
                    },
                },
            },
            scenegraph_id = "report_rows_header_inner"
        },
        report_rows_frame = {
            passes = {
                {   content_id = "report_rows_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "report_rows_frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = font_color,
                        offset = {0,0,0}
                    },
                },
            },
            scenegraph_id = "report_rows_outer"
        },
        report_rows_mask = {
            passes = {
                {   style_id = "mask", 
                    value_id = "material_name",
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_2",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                        size_addition = {20,5}
                    },
                },
            },
            scenegraph_id = "report_rows_outer"
        },
        report_rows_scrollbar = {
            passes = get_custom_scrollbar_template(),
            scenegraph_id = "report_rows_scrollbar"
        },
    }
    local widgets, widgets_by_name = generate_widgets(widget_templates)

    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)

    update_font_sizes(widgets, scenegraph_name)

    local function get_item_template()
        local item_template = {
            passes = {
                {   content_id = "row_name",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "report_name",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,0,2},
                        default_offset = {sizes.padding,0,2},
                        size_addition = {-1*sizes.padding,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_drag_change_function,
                },
                {   content_id = "left_bar",
                    pass_type = "rect",
                    style_id = "left_bar",
                    style = {
                        color = font_color,
                        offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                    change_function = item_drag_change_function,
                    scenegraph_id = "report_rows_item_left_bar"
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    }
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_drag_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                        default_offset = {0,0,-2},
                    },
                },
                {   value_id = "frame",
                    style_id = "frame",
                    pass_type = "texture",
                    value = "content/ui/materials/frames/frame_tile_2px",
                    change_function = item_drag_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset_offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                },
                {   value_id = "drag_logic",
                    pass_type = "logic",
                },
                {   content_id = "background",
                    pass_type = "rect",
                    style_id = "background",
                    style = {
                        color = {255,0,10,0},
                        offset = {0,0,-3},
                        default_offset = {0,0,-3},
                    },
                    visibility_function = function(content) return content.parent.drag_active end,
                },
            },
            scenegraph_id = "report_rows_item",
        }
        return item_template
    end

    if not selected_report_id then
        return
    end

    local user_report_template = user_reports[selected_report_id]
    local report_template_rows = user_report_template.rows

    local widget_templates = {}

    for _, row_name in ipairs(report_template_rows) do
        local item_template = get_item_template()
        item_template.name = row_name
        local test = PDI.utilities.localize(row_name)
        item_template.passes[1].value = PDI.utilities.localize(row_name)
        widget_templates[#widget_templates+1] = item_template 
    end

    local widgets, widgets_by_name = generate_widgets(widget_templates)

    update_font_sizes(widgets, scenegraph_name)

    local function change_rows_item_index(widget, grid, offset)
        local current_grid_index = widget.current_grid_index
        local new_grid_index = current_grid_index + offset
        local widgets = grid._widgets
        if new_grid_index < 1 or new_grid_index > #widgets then
            return
        end
        table.remove(widgets,current_grid_index)
        table.insert(widgets,new_grid_index,widget)

        grid:force_update_list_size()

        for index, widget in ipairs(widgets) do
            widget.current_grid_index = index
        end
    end

    local function rows_item_drag_function(widget, widget_count, grid, pass, ui_renderer, ui_style, content, position, size)
        local left_released = input_service:get("left_released")

        if left_released and content.drag_active then
            grid:force_update_list_size()
            load_report = true
            return
        end

        local hotspot = content.hotspot
        local on_pressed = hotspot.on_pressed
        local left_hold = input_service:get("left_hold")
        local cursor = input_service:get("cursor")

        if on_pressed then
            content.cursor_start = Vector3.to_array(cursor)
            content.widget_start = table.clone(widget.offset)
        end

        content.drag_active = on_pressed or content.drag_active and left_hold
        local drag_active = content.drag_active

        if drag_active then
            local current_grid_index = widget.current_grid_index
            local cursor_y_start = content.cursor_start[2]
            local widget_y_start = content.widget_start[2]
            
            local max_negative_offset = -1 * (current_grid_index) * (sizes.header_3_height + 5) + (sizes.header_3_height*0.25)
            max_negative_offset = current_grid_index == 1 and 0 or max_negative_offset
            local max_positive_offset = (widget_count - current_grid_index) * (sizes.header_3_height + 5) + (sizes.header_3_height*0.25)
            max_positive_offset = current_grid_index == widget_count and 0 or max_positive_offset

            local inverse_scale = render_settings.inverse_scale
            local cursor_y_offset = (cursor[2] - cursor_y_start) * inverse_scale
            local y_offset = math.clamp(cursor_y_offset, max_negative_offset, max_positive_offset)
            widget.offset[2] = widget_y_start + y_offset
            widget.offset[3] = 5

            local round_function = y_offset > 0 and math.floor or math.ceil

            local index_offset = round_function(y_offset / (sizes.header_3_height + 5))

            if math.abs(index_offset) > 0 then
                change_rows_item_index(widget, grid, index_offset)
                content.cursor_start = Vector3.to_array(cursor)
                content.widget_start = table.clone(widget.offset)
            end
        else
            content.cursor_start = nil
            content.widget_start = nil
            widget.offset[3] = 0
        end
    end

    renderers.offscreen_renderer_2.scenegraphs[scenegraph] = widgets

    local grid = generate_grid(scenegraph_name, scenegraph_name, widgets, widgets_by_name, "report_rows_inner", "down", {0,sizes.padding_half}, "report_rows_scrollbar", "report_rows_pivot")

    local widget_count = #widgets
    for index, widget in ipairs(widgets) do
        widget.content.size = scenegraph.report_rows_item.size
        widget.content.drag_logic = callback(rows_item_drag_function, widget, widget_count, grid)
        widget.current_grid_index = index
    end
end
--Function that sets up the pivot table component
ui_manager.setup_pivot_table = function()
    local scenegraph_name = "pivot_table"
    destroy_scenegraph("pivot_table")
    local widget_templates = {  
        columns_frame = {
            passes = {
                {   content_id = "columns_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "columns_frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0}
                    },
                },
            },
            scenegraph_id = "columns_inner"
        },
        columns_mask = {
            passes = {
                {   style_id = "mask", 
                    value_id = "material_name",
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                        size_addition = {10,20}
                    },
                },
            },
            scenegraph_id = "columns_inner"
        },
        rows_frame = {
            passes = {
                {   content_id = "rows_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "rows_frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0}
                    },
                },
            },
            scenegraph_id = "rows_inner"
        },
        rows_mask = {
            passes = {
                {   style_id = "mask", 
                    value_id = "material_name",
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_2",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                        size_addition = {10,10}
                    },
                },
            },
            scenegraph_id = "rows_grid"
        },
        values_frame = {
            passes = {
                {   content_id = "values_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "values_frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0}
                    },
                },
            },
            scenegraph_id = "values_inner"
        },
        values_mask = {
            passes = {
                {   style_id = "mask", 
                    value_id = "material_name",
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_3",
                    pass_type = "texture",    
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "center",
                        color = {255,255,255,255},
                        offset = {0,0,0},
                        size_addition = {20,10}
                    },
                },
            },
            scenegraph_id = "values_grid"
        },
        rows_values_vertical_scrollbar = {
            passes = get_custom_scrollbar_template(),
            scenegraph_id = "rows_values_vertical_scrollbar"
        },
        columns_values_horizontal_scrollbar = {
            passes = get_custom_horizontal_scrollbar_template(),
            scenegraph_id = "columns_values_horizontal_scrollbar"
        },
    }
    local widgets, widgets_by_name = generate_widgets(widget_templates)

    local columns_values_horizontal_scrollbar_widget = widgets_by_name.columns_values_horizontal_scrollbar

    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)

    local function get_columns_item_template()
        local item_template = {
            passes = {
                {   content_id = "column_title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "column_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,2},
                        font_type = font_type,
                        font_size = font_size*2,
                        default_font_size = font_size*2,
                        text_color = gold_color,
                    },
                },
                {   value_id = "divider",
                    style_id = "divider",
                    pass_type = "texture",
                    value = "content/ui/materials/dividers/skull_center_02",
                    style = {
                        size = {sizes.pt_columns_item[1]*1.25, sizes.pt_columns_item[2]*0.33},
                        offset = {0,sizes.pt_columns_item[2]*0.75},
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        scale_to_material = true,
                        color = gold_color
                    },
                },
            },
            scenegraph_id = "columns_item",
        }
        return item_template
    end

    local function player_item_change_fuction(index)
        local widgets = scenegraphs_data.pivot_table.grids.pt_columns.widgets
        local widget = widgets[index]
        local hotspot = widget.content.hotspot
        local is_hover = hotspot.is_hover
        local previous_frame_is_hover = hotspot.previous_frame_is_hover
        if is_hover == previous_frame_is_hover then
            return
        end
        hotspot.previous_frame_is_hover = is_hover
        local player_name = widget.content.column_title.text
        local column_title_style = widget.style.column_title
        local default_font_size = column_title_style.default_font_size
        local target_font_size = is_hover and (default_font_size*1.25) or default_font_size
        local new_width = get_text_size(player_name, target_font_size, font_type)
        column_title_style.font_size = target_font_size
        column_title_style.text_color[1] = is_hover and 255 or 200

        local padding = sizes.padding
        local column_icon_style = widget.style.class_icon
        local default_icon_width = sizes.pt_columns_item_player_icon[1]
        local new_icon_width = is_hover and (default_icon_width + padding) or default_icon_width
        column_icon_style.size_addition = is_hover and {padding,padding} or {0,0}
        column_icon_style.offset[1] = -0.5 * (new_width + new_icon_width)
        column_icon_style.color[1] = is_hover and 255 or 200
    end

    local function get_player_columns_item_template()
        local item_template = {
            passes = {
                {   content_id = "column_title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "column_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,2},
                        font_type = font_type,
                        font_size = font_size*2,
                        default_font_size = font_size*2,
                        text_color = gold_color,
                    },
                },
                {   content_id = "class_icon",
                    pass_type = "texture",
                    style_id = "class_icon",
                    value_id = "material_name",
                    value = "content/ui/materials/icons/classes/veteran",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = gold_color,
                        offset = {0,0,0},
                    },
                    scenegraph_id = "columns_item_player_icon"
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    }
                },
                {   value_id = "divider",
                    style_id = "divider",
                    pass_type = "texture",
                    value = "content/ui/materials/dividers/skull_center_02",
                    style = {
                        size = {sizes.pt_columns_item[1]*1.25, sizes.pt_columns_item[2]*0.33},
                        offset = {0,sizes.pt_columns_item[2]*0.75},
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        scale_to_material = true,
                        color = gold_color
                    },
                },
            },
            scenegraph_id = "columns_item",
        }
        return item_template
    end

    local columns_array = loaded_report.columns

    local column_widget_templates = {}

    local is_player_column

    for index, column_settings in ipairs(columns_array) do
        local column_name = column_settings.name
        local is_player = column_settings.type == "player"
        local item_template, player_profile
        local max_item_width
        if is_player then
            if not type(is_player_column) then
                is_player_column = true
            end
            local player_profiles = PDI.data.session_data.datasources.PlayerProfiles
            for player_unit_uuid, profile in pairs(player_profiles) do
                if profile.character_id == column_name then
                    player_profile = table.clone(profile)
                end
            end
            column_name = player_profile and player_profile.name or column_name
            item_template = get_player_columns_item_template()
            max_item_width = scenegraph.columns_item_player_name.size[1] - 0.5*(scenegraph.columns_item_player_name.size[2]) - sizes.padding
            local columns_font_size, column_name_text_width = adjusted_font_size(column_name, font_size*2, font_type, max_item_width)
            item_template.passes[1].value = column_name
            item_template.passes[1].style.font_size = columns_font_size
            item_template.passes[1].style.default_font_size = columns_font_size
            item_template.passes[1].change_function = callback(player_item_change_fuction, index)
            item_template.passes[2].style.offset[1] = -0.5 * (column_name_text_width + sizes.pt_columns_item_player_icon[1])
            item_template.passes[2].value = player_profile and player_profile.archetype.archetype_icon_large

            if not player_profile then
                item_template.passes[2].style.visible = false
            end
            
            if player_profile then
                local view_profile_callback = callback(ui_manager.view_player_profile, player_profile)
                item_template.passes[3].change_function = callback(on_clicked_callback_hotspot_change_function,view_profile_callback)
            end

        else
            item_template = get_columns_item_template()
            max_item_width = scenegraph.columns_item.size[1]- sizes.padding
            item_template.passes[1].value = column_name
            item_template.passes[1].style.font_size = font_size * 2
            item_template.passes[1].style.default_font_size = font_size * 2
        end
        item_template.name = column_name
        column_widget_templates[#column_widget_templates+1] = item_template
    end

    local widgets, widgets_by_name = generate_widgets(column_widget_templates)

    for _, widget in ipairs(widgets) do
        widget.content.size = scenegraph.columns_item.size
    end

    if not is_player_column then
        update_font_sizes(widgets, scenegraph_name)
    end

    renderers.offscreen_renderer_1.scenegraphs[scenegraph] = widgets

    local grid = generate_grid("pt_columns", scenegraph_name, widgets, widgets_by_name, "columns_inner", "right", {0,sizes.padding_half})

    local columns_values_horizontal_scrollbar_widget_content = columns_values_horizontal_scrollbar_widget.content

    columns_values_horizontal_scrollbar_widget_content.grid = grid
    columns_values_horizontal_scrollbar_widget_content.scrollbar_scenegraph_id = "columns_values_horizontal_scrollbar"
    columns_values_horizontal_scrollbar_widget_content.pivot_scenegraph_id = {"values_pivot","columns_pivot"}

    grid._horizontal_scrollbar_widget = columns_values_horizontal_scrollbar_widget
    grid._horizontal_scrollbar_active = true

    local function get_rows_item_template()
        local item_template = {
            passes = {
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                        on_hover_sound = UISoundEvents.default_mouse_hover,
                        on_complete_sound = UISoundEvents.default_click
                    },
                    style = {
                        size_addition = {sizes.report_inner[1]-sizes.pt_rows_item[1] - sizes.scrollbar_width - 2*sizes.padding,0}
                    },
                },
                {   content_id = "row_title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "row_title",
                    change_function = item_standard_change_function,
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.header_3_height,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                },
                {   value_id = "icon",
                    style_id = "icon",
                    pass_type = "texture",
                    value = "content/ui/materials/hud/interactions/icons/objective_side",
                    style = {
                        offset = {-0.5*sizes.pt_rows_item[1] + (sizes.padding*2),0,1},
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        size = {sizes.header_3_height,sizes.header_3_height},
                        scale_to_material = true,
                        color = terminal_green_color
                    },
                },
                {   style_id = "highlight",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        size_addition = {0,-1*sizes.padding}
                    },
                },
            },
            scenegraph_id = "rows_item",
        }
        return item_template
    end

    local values_as_rows_array = loaded_report.values_as_rows

    local row_widget_templates = {}
    local index_to_children_index = {}
    local index_to_last_grandchild_index = {}

    local function toggle_row(index)
        local child_index_array = index_to_children_index[index]
        if not next(child_index_array) then
            return
        end

        local pivot_table_grids = scenegraphs_data.pivot_table.grids

        local row_grid_settings = pivot_table_grids.pt_rows
        local value_grid_settings = pivot_table_grids.pt_values
        local row_widgets = row_grid_settings.widgets
        local value_widgets = value_grid_settings.widgets
        local row_widget = row_widgets[index]
        local value_widget = row_widgets[index]

        local is_expanded = not row_widget.is_expanded
        row_widget.is_expanded = is_expanded
        value_widget.is_expanded = is_expanded

        local child_item_height = is_expanded and scenegraph.rows_item.size[2] or 0

        local function update_child(child_index)
            local child_row_widget = row_widgets[child_index]
            local child_value_widget = value_widgets[child_index]
            child_row_widget.content.size[2] = child_item_height
            child_value_widget.content.size[2] = child_item_height
            child_row_widget.content.visible = is_expanded
            child_value_widget.content.visible = is_expanded
            child_row_widget.visible = is_expanded
            child_value_widget.visible = is_expanded
            child_row_widget.is_expanded = false
            child_value_widget.is_expanded = false
        end

        if is_expanded then
            for _, child_widget_index in ipairs(child_index_array) do
                update_child(child_widget_index)
            end
        else
            local last_grand_child_index = index_to_last_grandchild_index[index]
            for i = index+1, last_grand_child_index, 1 do
                update_child(i)
            end
        end
        
        local row_grid = row_grid_settings.grid
        local value_grid = value_grid_settings.grid

        local grid_pivot = scenegraph.rows_pivot

        local previous_pivot_y = math.abs(grid_pivot.position[2])
        row_grid:force_update_list_size()
    
        local total_grid_height= row_grid._total_grid_length
        local visible_grid_height = scenegraph.rows_inner.size[2]
        
        local new_scrollbar_progress = math.clamp01(previous_pivot_y/(total_grid_height-visible_grid_height))
        row_grid:set_scrollbar_progress(new_scrollbar_progress)  
        value_grid:force_update_list_size()
    end

    local normal_green = Color.terminal_text_body(200, true)
    local highlight_green = Color.terminal_text_body(255, true)
    local highlight_gold = {255,238,186,74}
    local expanded_gold = {200,238,186,74}

    local normal_green_background = Color.terminal_background_gradient(0, true)
    local highlight_green_background = Color.terminal_background_gradient(100, true)
    local highlight_gold_background = Color.terminal_background_gradient_selected(150, true)
    local expanded_gold_background = Color.terminal_background_gradient_selected(100, true)

    local function pivot_table_item_change_function (widget_index, content, style)
        local widget = scenegraphs_data.pivot_table.grids.pt_rows.widgets[widget_index]
        local hotspot = widget.content.hotspot or widget.content.parent.hotspot
        local is_expanded = widget.is_expanded
        local is_hover = hotspot.is_hover
        local default_font_size = style.default_font_size
        if is_expanded and is_hover then
            style.color = highlight_gold
            style.text_color = highlight_gold
            style.font_size = default_font_size * 1.25
        elseif is_expanded then
            style.color = expanded_gold
            style.text_color = expanded_gold
            style.font_size = default_font_size
        elseif  is_hover then
            style.color = highlight_green
            style.text_color = highlight_green
            style.font_size = default_font_size * 1.25
        else
            style.color = normal_green
            style.text_color = normal_green
            style.font_size = default_font_size
        end
    end
    local function pivot_table_icon_change_function (widget_index, content, style)
        local widget = scenegraphs_data.pivot_table.grids.pt_rows.widgets[widget_index]
        local hotspot = widget.content.hotspot or widget.content.parent.hotspot
        local is_expanded = widget.is_expanded
        local is_hover = hotspot.is_hover
        if is_expanded and is_hover then
            style.color = highlight_gold
            style.text_color = highlight_gold
            style.size_addition = {sizes.padding,sizes.padding}
        elseif is_expanded then
            style.color = expanded_gold
            style.text_color = expanded_gold
            style.size_addition = {0,0}
        elseif  is_hover then
            style.color = highlight_green
            style.text_color = highlight_green
            style.size_addition = {sizes.padding,sizes.padding}
        else
            style.color = normal_green
            style.text_color = normal_green
            style.size_addition = {0,0}
        end
    end
    local function pivot_table_item_background_change_function(widget_index, content, style)
        local widget = scenegraphs_data.pivot_table.grids.pt_rows.widgets[widget_index]
        local hotspot = widget.content.hotspot or widget.content.parent.hotspot
        local is_expanded = widget.is_expanded
        local is_hover = hotspot.is_hover
    
        if is_expanded and is_hover then
            style.color = highlight_gold_background
        elseif is_expanded then
            style.color = expanded_gold_background
        elseif  is_hover then
            style.color = highlight_green_background
        else
            style.color = normal_green_background
        end
    end
    local function create_row_widget_templates(input_table, level)
        level = level or 0
        local current_level_index_array = {}
        local last_child_index

        local utilities_localize = PDI.utilities.localize

        if level ~= 0 then
            table.sort(input_table,function(v1,v2) return v1.name < v2.name end)
        end

        for index, value in ipairs(input_table) do
            local current_index = #row_widget_templates+1
            last_child_index = current_index
            current_level_index_array[#current_level_index_array+1] = current_index
            local item_template = get_rows_item_template()
            local row_name = utilities_localize(value.name)
          
            local toggle_row_callback = callback(toggle_row, current_index)

            item_template.passes[1].change_function = callback(on_clicked_callback_hotspot_change_function, toggle_row_callback)

            item_template.passes[2].value = row_name
            item_template.passes[2].style.offset[1] = item_template.passes[2].style.offset[1] + (20*level)
            item_template.passes[2].change_function = callback(pivot_table_item_change_function, current_index)
            item_template.passes[3].style.offset[1] = item_template.passes[3].style.offset[1] + (20*level)
            item_template.passes[3].change_function = callback(pivot_table_icon_change_function, current_index)
            item_template.passes[4].change_function = callback(pivot_table_item_background_change_function, current_index)
            row_widget_templates[current_index] = item_template
            local children = value.children
            local children_index_array = {}
            if children and next(children) then
                children_index_array, last_child_index = create_row_widget_templates(children, level+1)
            else
                item_template.passes[3].value = "content/ui/materials/hud/interactions/icons/objective_secondary"
            end
            index_to_children_index[current_index] = children_index_array
            index_to_last_grandchild_index[current_index] = last_child_index
        end
        return current_level_index_array, last_child_index
    end

    index_to_children_index[0] = create_row_widget_templates(values_as_rows_array)

    local widgets, widgets_by_name = generate_widgets(row_widget_templates)


    for _, widget in ipairs(widgets) do
        widget.content.size = {scenegraph.rows_item.size[1],0}
        widget.content.visible = false
        widget.is_expanded = false
    end

    for _, widget_index in ipairs(index_to_children_index[0]) do
        local widget = widgets[widget_index]
        widget.scenegraph_id = "rows_item"
        widget.content.size = scenegraph.rows_item.size
        widget.content.visible = true
    end

    update_font_sizes(widgets, scenegraph_name)


    renderers.offscreen_renderer_2.scenegraphs[scenegraph] = widgets

    local grid = generate_grid("pt_rows", scenegraph_name, widgets, widgets_by_name, "rows_grid", "down", nil, "rows_values_vertical_scrollbar", "rows_pivot", "report_inner")

    local function get_value_item_template()
        local item_template = {
            passes = {
                {   style_id = "highlight",
                    pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        size_addition = {0,-1*sizes.padding}
                    },
                },
            },
            scenegraph_id = "values_item",
        }
        return item_template
    end
    local function get_value_item_pass()
        local pass =                 
        {
        value = "temp",
        pass_type = "text",
        style = {
            text_vertical_alignment = "center",
            text_horizontal_alignment = "center",
            offset = {0,0,2},
            size_addition = {0,0},
            font_type = font_type,
            font_size = font_size,
            default_font_size = font_size,
            text_color = font_color,
        },
        scenegraph_id = "values_item"
        }
        return pass
    end

    local value_widget_templates = {}
    local function create_value_widget_templates(input_table)
         for index, value in ipairs(input_table) do
            local current_index = #value_widget_templates+1
            local item_template = get_value_item_template()

            item_template.passes[1].change_function = callback(pivot_table_item_background_change_function, current_index)

            local value_name = "value_row_"..current_index
            local values = value.values
            for index, value in ipairs(values) do
                local pass = get_value_item_pass()
                pass.value = value
                pass.change_function = callback(pivot_table_item_change_function, current_index)
                pass.style.offset[1] = sizes.padding_half + (sizes.pt_columns_item[1] * (index-1))
                item_template.passes[#item_template.passes+1] = pass
            end
            value_widget_templates[current_index] = item_template
            local children = value.children
            if children and next(children) then
                create_value_widget_templates(children)
            end
        end
    end
    create_value_widget_templates(values_as_rows_array)
    local widgets, widgets_by_name = generate_widgets(value_widget_templates)

    local number_of_columns = #loaded_report.columns

    local value_item_width = (scenegraph.values_item.size[1] + sizes.padding_half) * (number_of_columns*2)
    local value_item_height = scenegraph.values_item.size[2]

    for _, widget in ipairs(widgets) do
        widget.content.size = {value_item_width,0}
        widget.content.visible = false
        widget.is_expanded = false
    end

    for _, widget_index in ipairs(index_to_children_index[0]) do
        local widget = widgets[widget_index]
        widget.content.size = {value_item_width,value_item_height}
        widget.content.visible = true
    end

    renderers.offscreen_renderer_3.scenegraphs[scenegraph] = widgets

    local grid = generate_grid("pt_values", scenegraph_name, widgets, widgets_by_name, "values_grid", "down", nil, "rows_values_vertical_scrollbar", "values_pivot", "report_inner")
end
--Function that sets up the edit report settings component
ui_manager.setup_edit_report_settings = function()
    destroy_scenegraph("reports")
    destroy_scenegraph("report_rows_order")
    destroy_scenegraph("pivot_table")

    local edit_mode = edit_mode_cache.mode

    local edit_tab_title = edit_mode == "edit" and mod:localize("mloc_edit_report") or mod:localize("mloc_new_report")

    local function save_button_disabled_logic_function(pass, ui_renderer, ui_style, content, position, size)
        local save_check = edit_mode_cache.save_check
        if save_check then
            content.disabled = false
        else
            content.disabled = true
        end
    end

    local function delete_button_logic_function(pass, ui_renderer, ui_style, content, position, size)
        local hotspot = content.hotspot
        local on_pressed = hotspot.on_pressed
        local is_hover = hotspot.is_hover
        local left_hold = input_service:get("left_hold")
        local animation_time = 1
        local timer_background_style = ui_style.parent.timer_background
        local default_size_addition_x = timer_background_style.default_size_addition[1]

        if on_pressed then
            content.deleting_active = true
            delete_animation_progress = animation_time
            timer_background_style.size_addition[1] = default_size_addition_x
            timer_background_style.visible = true
        end

        if content.deleting_active and is_hover and left_hold then
            if delete_animation_progress <= 0 then
                delete_animation_progress = nil
                content.is_active = false
                edit_mode_cache.delete_report = true
                return
            end

            local size_addition_multiplier = delete_animation_progress /  animation_time
            timer_background_style.size_addition[1] = default_size_addition_x * size_addition_multiplier
        else
            delete_animation_progress = nil
            content.deleting_active = nil
            timer_background_style.visible = false
        end
    end

    local widget_templates = {
        edit_tab = {
             passes = {
                 {   content_id = "title",
                     value_id = "text",
                     value = edit_tab_title,
                     pass_type = "text",
                     style_id = "title",
                     style = {
                         text_vertical_alignment = "center",
                         text_horizontal_alignment = "center",
                         offset = {0,0,0},
                         font_type = font_type,
                         font_size = font_size*2.5,
                         default_font_size = font_size*2.5,
                         text_color = gold_color,
                     },
                 },
                 {
                     pass_type = "rect",
                     style_id = "frame_t",
                     style = {
                         vertical_alignment = "top",
                         horizontal_alignment = "center",
                         size = {sizes.header_tab[1],2},
                         color = terminal_green_color,
                         offset = {0,-1,0}
                     },
                 },
                 {   style_id = "frame_b",
                     pass_type = "rect",
                     style = {
                         vertical_alignment = "bottom",
                         horizontal_alignment = "center",
                         size = {sizes.header_tab[1],2},
                         color = terminal_green_color,
                         offset = {sizes.header_tab[1],1,0}
                     },
                 },
                 {
                     pass_type = "rect",
                     style_id = "frame_l",
                     style = {
                         vertical_alignment = "center",
                         horizontal_alignment = "left",
                         size = {2, sizes.header_tab[2]},
                         color = terminal_green_color,
                         offset = {-1,0,0}
                     },
                 },
                 {
                     pass_type = "rect",
                     style_id = "frame_r",
                     style = {
                         vertical_alignment = "center",
                         horizontal_alignment = "right",
                         size = {2, sizes.header_tab[2]},
                         color = terminal_green_color,
                         offset = {1,0,0}
                     },
                 },
             },
             scenegraph_id = "edit_tab"
        },
        report_settings_frame = {
            passes = {
                {   content_id = "report_settings_frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    pass_type = "texture",
                    style_id = "report_settings_frame",           
                    style = {
                        vertical_alignment = "top",
                        horizontal_alignment = "left",
                        color = terminal_green_color,
                        offset = {0,0,0},
                        size_addition = {0,0},
                    },
                },
            },
            scenegraph_id = "report_settings_frame"
        },
        report_settings_title = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_report_settings"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size*1.75,
                        default_font_size = font_size*1.75,
                        text_color = gold_color,
                    },
                },
                },
                scenegraph_id = "report_settings_header_inner"
        },
        name_title = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_report_name"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                },
                },
                scenegraph_id = "name_title"
        },
        name_input = {
            passes = get_custom_text_input_template(),
            scenegraph_id = "name_input",
        },
        template_title = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_template_name"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                },
                },
                scenegraph_id = "template_title"
        },
        dataset_title = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_dataset_name"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                },
                },
                scenegraph_id = "dataset_title"
        },
        report_type_title = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_report_type_name"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                },
                },
                scenegraph_id = "report_type_title"
        },
        delete_button = {
            passes = {
                {   content_id = "frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0},
                        size_addition = {0,0},
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_delete_report"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                    },
                },
                {   value_id = "timer_background",
                    style_id = "timer_background",
                    pass_type = "rect",
                    style = {
                        color = delete_color_background,
                        offset = {0,0,-1},
                        size_addition = {-1*get_block_size_NEW(sizes.workspace_inner, 4, 1, 1)[1],0},
                        default_size_addition = {-1*get_block_size_NEW(sizes.workspace_inner, 4, 1, 1)[1],0},
                        visible = false
                    },
                },
                {   value_id = "delete_button_logic",
                    pass_type = "logic",
                    value = delete_button_logic_function,
                },
            },
            scenegraph_id = "delete_row"
        },
        exit_button = {
            passes = {
                {   content_id = "frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0},
                        size_addition = {0,0},
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_exit_without_saving"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, function()edit_mode_cache.exit = true end)
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                    },
                },
            },
            scenegraph_id = "exit_row"
        },
        save_button = {
            passes = {
                {   content_id = "frame",
                    value_id = "material_name",
                    value = "content/ui/materials/frames/line_light",
                    pass_type = "texture",
                    style_id = "frame",           
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = terminal_green_color,
                        offset = {0,0,0},
                        size_addition = {0,0},
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "title",
                    value_id = "text",
                    value = mod:localize("mloc_save_and_exit"),
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {0,0,0},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_standard_change_function,
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    },
                    change_function = callback(on_clicked_callback_hotspot_change_function, function() edit_mode_cache.save_report = true end)
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_standard_change_function,
                    style = {
                        scale_to_material = true,
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                    },
                },
                {   value_id = "disabled_logic",
                    pass_type = "logic",
                    value = save_button_disabled_logic_function,
                },

            },
            scenegraph_id = "save_row"
        },
    }
    local widgets, widgets_by_name = generate_widgets(widget_templates)

    if edit_mode == "new" then
        local delete_button_widget = widgets_by_name.delete_button
        delete_button_widget.visible = false
        local frame_widget = widgets_by_name.report_settings_frame
        frame_widget.style.report_settings_frame.size_addition[2] = sizes.header_3_height + sizes.padding_half
    end

    widgets_by_name.save_button.content.disabled = true

    local select_text = mod:localize("mloc_select")
    local template_dropdown_callback_function = function(option_id)
        local scenegraph_settings = scenegraphs_data.edit_report_settings
        local widgets_by_name = scenegraph_settings.widgets_by_name
        local template_dropdown_widget = widgets_by_name.template_input
        local dataset_dropdown_widget = widgets_by_name.dataset_input
        local report_type_dropdown_widget = widgets_by_name.report_type_input

        local dataset_content = dataset_dropdown_widget.content
        local report_type_content = report_type_dropdown_widget.content

        if option_id == 1 then
            dataset_content.selected_index = nil
            dataset_content.disabled = false
            dataset_content.value_text = select_text

            report_type_content.selected_index = nil
            report_type_content.disabled = false
            report_type_content.value_text = select_text

            edit_mode_cache.setting_changed = true
            edit_mode_cache.selected_template = option_id
            return
        end

        local report_template = PDI.report_manager.get_report_template(option_id)
        local dataset_name =  report_template.dataset_name
        local report_type = "mloc_report_type_pivot_table"

        local dataset_options_by_id = dataset_content.options_by_id
        local dataset_option = dataset_options_by_id[dataset_name]
        local dataset_option_index = dataset_option.index
        local dataset_option_id = dataset_option.id
        dataset_content.selected_index = dataset_option_index
        dataset_content.disabled = true
        edit_mode_cache.selected_dataset = dataset_option_id

        local report_type_options_by_id = report_type_content.options_by_id
        local report_type_option = report_type_options_by_id[report_type]
        local report_type_option_index = report_type_option.index
        local report_type_option_id = report_type_option.id
        report_type_content.selected_index = report_type_option_index
        report_type_content.disabled = true
        edit_mode_cache.selected_report_type = report_type_option_id

        edit_mode_cache.setting_changed = true
        edit_mode_cache.selected_template = option_id
    end
    local dataset_dropdown_callback_function = function(option_id)
        edit_mode_cache.setting_changed = true
        edit_mode_cache.selected_dataset = option_id
    end
    local report_type_dropdown_callback_function = function(option_id)
        edit_mode_cache.setting_changed = true
        edit_mode_cache.selected_report_type = option_id
    end

    local scenegraph_name = "edit_report_settings"
    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)

    update_font_sizes(widgets, scenegraph_name)

    local template_options = get_dropdown_options("templates")
    local template_dropdown_widget = generate_dropdown_widget(scenegraph_name, "template_input", template_options, 6, template_dropdown_callback_function, select_text, true)

    local dataset_options = get_dropdown_options("datasets")
    local dataset_dropdown_widget = generate_dropdown_widget(scenegraph_name, "dataset_input", dataset_options, 5, dataset_dropdown_callback_function, select_text, true)

    local report_type_options = get_dropdown_options("report_types")
    local report_type_dropdown_widget = generate_dropdown_widget(scenegraph_name, "report_type_input", report_type_options, 5, report_type_dropdown_callback_function, select_text, true)
end
--Function that sets up the edit pivot table component
ui_manager.setup_edit_pivot_table = function()
    local scenegraph_name = "edit_pivot_table"
    destroy_scenegraph(scenegraph_name)
    local scenegraph_id_lookup = {
        column = "column_item",
        rows = "rows_item",
        values = "values_item",
    }

    edit_pivot_table_functions.get_widget_templates = function()
        local widget_templates = {
            dataset_fields_title = {
                passes = {
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_dataset_fields"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "left",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size*1.75,
                            default_font_size = font_size*1.75,
                            text_color = gold_color,
                        },
                    },
                    },
                    scenegraph_id = "dataset_fields_header_inner"
            },
            dataset_fields_frame = {
                passes = {
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,0},
                        },
                    },
                },
                scenegraph_id = "dataset_fields_frame"
            },
            dataset_fields_mask = {
                passes = {
                    {   style_id = "mask", 
                        value_id = "material_name",
                        value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur",
                        pass_type = "texture",    
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = {255,255,255,255},
                            offset = {0,0,0},
                            size_addition = {sizes.padding,sizes.padding}
                        },
                    },
                },
                scenegraph_id = "dataset_fields_grid"
            },
            dataset_fields_scrollbar = {
                passes = get_custom_scrollbar_template(),
                scenegraph_id = "dataset_fields_scrollbar"
            },
            column_title = {
                passes = {
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_column"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "left",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size*1.75,
                            default_font_size = font_size*1.75,
                            text_color = gold_color,
                        },
                    },
                    },
                    scenegraph_id = "column_header_inner"
            },
            column_frame = {
                passes = {
                    {   content_id = "frame_1",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "rotated_texture",
                        style_id = "frame_1",           
                        style = {
                            angle = math.rad(180),
                            vertical_alignment = "top",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,-0.5*sizes.header_3_height},
                        },
                    },
                    {   content_id = "frame_2",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame_2",           
                        style = {
                            vertical_alignment = "bottom",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,-0.5*sizes.header_3_height},
                        },
                    },
                    {   content_id = "hotspot",
                        style_id = "hotspot",
                        pass_type = "hotspot",
                        content = {
                            zone = "column",
                            use_is_focused = true,
                        },
                        change_function = edit_pivot_table_functions.drop_zones_hotspot_change_function
                    },
                },
                scenegraph_id = "column_frame"
            },
            column_mask = {
                passes = {
                    {   style_id = "mask", 
                        value_id = "material_name",
                        value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur",
                        pass_type = "texture",    
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = {255,255,255,255},
                            offset = {0,0,0},
                            size_addition = {sizes.padding,sizes.padding}
                        },
                    },
                },
                scenegraph_id = "column_grid"
            },
            rows_title = {
                passes = {
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_rows"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "left",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size*1.75,
                            default_font_size = font_size*1.75,
                            text_color = gold_color,
                        },
                    },
                    },
                    scenegraph_id = "rows_header_inner"
            },
            rows_frame = {
                passes = {
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,0},
                        },
                    },
                    {   content_id = "hotspot",
                        style_id = "hotspot",
                        pass_type = "hotspot",
                        content = {
                            zone = "rows",
                            use_is_focused = true,
                        },
                        change_function = edit_pivot_table_functions.drop_zones_hotspot_change_function
                    },
                },
                scenegraph_id = "rows_frame"
            },
            rows_mask = {
                passes = {
                    {   style_id = "mask", 
                        value_id = "material_name",
                        value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_2",
                        pass_type = "texture",    
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = {255,255,255,255},
                            offset = {0,0,0},
                            size_addition = {sizes.padding,sizes.padding}
                        },
                    },
                },
                scenegraph_id = "rows_grid"
            },
            rows_scrollbar = {
                passes = get_custom_scrollbar_template(),
                scenegraph_id = "rows_scrollbar"
            },
            values_title = {
                passes = {
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_values"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "left",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size*1.75,
                            default_font_size = font_size*1.75,
                            text_color = gold_color,
                        },
                    },
                    },
                    scenegraph_id = "values_header_inner"
            },
            values_frame = {
                passes = {
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,0},
                        },
                    },
                    {   content_id = "hotspot",
                        style_id = "hotspot",
                        pass_type = "hotspot",
                        content = {
                            zone = "values",
                            use_is_focused = true,
                        },
                        change_function = edit_pivot_table_functions.drop_zones_hotspot_change_function
                    },
                },
                scenegraph_id = "values_frame"
            },
            values_mask = {
                passes = {
                    {   style_id = "mask", 
                        value_id = "material_name",
                        value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_3",
                        pass_type = "texture",    
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = {255,255,255,255},
                            offset = {0,0,0},
                            size_addition = {2*sizes.padding,2*sizes.padding}
                        },
                    },
                },
                scenegraph_id = "values_grid"
            },
            values_scrollbar = {
                passes = get_custom_scrollbar_template(),
                scenegraph_id = "values_scrollbar"
            },
            values_add_calculated_field = {
                passes = {
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_light",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,0},
                        },
                        change_function = item_standard_change_function,
                    },
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_add_calculated_field"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "center",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size,
                            default_font_size = font_size,
                            text_color = font_color,
                        },
                        change_function = item_standard_change_function,
                    },
                    {   content_id = "hotspot",
                        style_id = "hotspot",
                        pass_type = "hotspot",
                        content = {
                            use_is_focused = true,
                        },
                        change_function = callback(on_clicked_callback_hotspot_change_function,edit_pivot_table_functions.create_calculated_field_edit_item_widget)
                    },
                    {   value_id = "background_gradient",
                        style_id = "background_gradient",
                        pass_type = "texture",
                        value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                        change_function = item_gradient_standard_change_function,
                        style = {
                            scale_to_material = true,
                            color = {0,0,0,0},
                            offset = {0,0,-2},
                        },
                    },
                },
                scenegraph_id = "values_add_calculated_field"
            },
            data_filter_title = {
                passes = {
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_data_filter"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "left",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size*1.75,
                            default_font_size = font_size*1.75,
                            text_color = gold_color,
                        },
                    },
                    },
                    scenegraph_id = "data_filter_header_inner"
            },
            data_filter_frame = {
                passes = {
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,0},
                        },
                    },
                },
                scenegraph_id = "data_filter_frame"
            },
            data_filter_input = {
                passes = CustomMultiLineTextInput,
                scenegraph_id = "data_filter_input",
            },
            pivot_table_settings_title = {
                passes = {
                    {   content_id = "title",
                        value_id = "text",
                        value = mod:localize("mloc_pivot_table_settings"),
                        pass_type = "text",
                        style_id = "title",
                        style = {
                            text_vertical_alignment = "center",
                            text_horizontal_alignment = "left",
                            offset = {0,0,0},
                            font_type = font_type,
                            font_size = font_size*1.75,
                            default_font_size = font_size*1.75,
                            text_color = gold_color,
                        },
                    },
                    },
                    scenegraph_id = "pivot_table_settings_header_inner"
            },
            pivot_table_settings_frame = {
                passes = {
                    {   content_id = "frame",
                        value_id = "material_name",
                        value = "content/ui/materials/frames/line_thin_detailed_02",
                        pass_type = "texture",
                        style_id = "frame",           
                        style = {
                            vertical_alignment = "center",
                            horizontal_alignment = "center",
                            color = terminal_green_color,
                            offset = {0,0,0},
                            size_addition = {0,0},
                        },
                    },
                },
                scenegraph_id = "pivot_table_settings_frame"
            }
        }

        return widget_templates
    end
    edit_pivot_table_functions.drop_zones_hotspot_change_function = function(content, style)
        local is_hover = content.is_hover
        local zone = content.zone
        if is_hover then
            edit_mode_cache.active_zone = zone
        elseif edit_mode_cache.active_zone == zone then
            edit_mode_cache.active_zone = nil
        end
    end
    edit_pivot_table_functions.remove_widget = function(widget)
        local content = widget.content
        local current_renderer_name = content.current_renderer_name
        local current_renderer_index = content.current_renderer_index
        local scenegraph = edit_pivot_table_functions.get_scenegraph()

        local current_grid_name = content.current_grid_name

        if current_grid_name then
            return
        end
        if current_renderer_name ~= "default_renderer" then
            return
        end
        if not current_renderer_index then
            return
        end

        local offscreen_renderer_3_widgets = renderers.offscreen_renderer_3.scenegraphs[scenegraph]
        local child_widgets = content.child_widgets
        for _, child_widget in pairs(child_widgets) do
            local child_widget_content = child_widget.content
            local current_renderer_index = child_widget_content.current_renderer_index
            table.remove(offscreen_renderer_3_widgets, current_renderer_index)
            for index, widget in ipairs(offscreen_renderer_3_widgets) do
                widget.content.current_renderer_index = index
            end
        end

        local default_renderer_widgets = renderers.default_renderer.scenegraphs[scenegraph]
        table.remove(default_renderer_widgets, current_renderer_index)
        for index, widget in ipairs(default_renderer_widgets) do
            widget.content.current_renderer_index = index
        end
    end
    edit_pivot_table_functions.change_widget_renderer = function(widget, new_renderer_name)
        local content = widget.content
        local current_renderer_name = content.current_renderer_name
        local scenegraph = edit_pivot_table_functions.get_scenegraph()

        if current_renderer_name == new_renderer_name then
            return
        end

        local current_renderer_index = content.current_renderer_index
        local current_renderer_settings = renderers[current_renderer_name]
        local current_renderer_widgets = current_renderer_settings.scenegraphs[scenegraph]

        table.remove(current_renderer_widgets, current_renderer_index)
        for index, widget in ipairs(current_renderer_widgets) do
            widget.content.current_renderer_index = index
        end

        local new_renderer_settings = renderers[new_renderer_name]
        local new_renderer_widgets = new_renderer_settings.scenegraphs[scenegraph]
        local new_renderer_index = #new_renderer_widgets+1

        new_renderer_widgets[new_renderer_index] = widget
        content.current_renderer_name = new_renderer_name
        content.current_renderer_index = new_renderer_index
    end
    edit_pivot_table_functions.change_widget_scenegraph_id = function(widget, new_scenegraph_id)
        local content = widget.content
        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local current_scenegraph_id = widget.scenegraph_id

        if current_scenegraph_id == new_scenegraph_id then
            return
        end

        local current_scenegraph_item = scenegraph[current_scenegraph_id]
        local current_scenegraph_item_world_position = current_scenegraph_item.world_position
        local new_scenegraph_item = scenegraph[new_scenegraph_id]
        local new_scenegraph_item_world_position = new_scenegraph_item.world_position

        local widget_start = content.widget_start or {0,0}
        local new_widget_x_offset = widget_start[1] + (current_scenegraph_item_world_position[1] - new_scenegraph_item_world_position[1])
        local new_widget_y_offset = widget_start[2] + (current_scenegraph_item_world_position[2] - new_scenegraph_item_world_position[2])
        content.widget_start = {new_widget_x_offset, new_widget_y_offset}
        widget.scenegraph_id = new_scenegraph_id
    end
    edit_pivot_table_functions.change_widget_grid = function(widget, new_zone)
        local content = widget.content
        local current_grid_name = content.current_grid_name
        local grids = scenegraphs_data.edit_pivot_table.grids

        if current_grid_name then
            local current_grid_settings = grids[current_grid_name]
            local current_grid = current_grid_settings.grid
            local current_grid_widgets = current_grid_settings.widgets
            local current_grid_index = content.current_grid_index
            table.remove(current_grid_widgets, current_grid_index)
            for index, widget in ipairs(current_grid_widgets) do
                widget.content.current_grid_index = index
            end
            content.current_grid_name = nil
            content.current_grid_index = nil
            current_grid:force_update_list_size()
        end

        if new_zone then
            local widget_name = widget.name
            local new_grid_settings = grids[new_zone]
            local new_grid = new_grid_settings.grid
            local new_grid_widgets = new_grid_settings.widgets

            local is_calculated_field = content.value_template.type == "calculated_field"

            if is_calculated_field and new_zone ~= "values" then
                return
            elseif not is_calculated_field then
                for _, widget in ipairs(new_grid_widgets) do
                    if widget.name == widget_name then
                        return
                    end
                end
            end

            local new_grid_index = #new_grid_widgets+1

            local new_scenegraph_id = scenegraph_id_lookup[new_zone]
            edit_pivot_table_functions.change_widget_scenegraph_id(widget, new_scenegraph_id)

            new_grid_widgets[new_grid_index] = widget
            content.current_grid_name = new_zone
            content.current_grid_index = new_grid_index
            new_grid:force_update_list_size()
        else
            edit_pivot_table_functions.change_widget_scenegraph_id(widget, "edit_item")
        end
    end
    edit_pivot_table_functions.get_default_edit_item_size = function()
        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        return table.clone(scenegraph.values_item.size)
    end
    edit_pivot_table_functions.edit_item_drag_function = function(widget, pass, ui_renderer, ui_style, content, position, size)
        local hotspot = content.hotspot
        local on_pressed = hotspot.on_pressed
        local cursor = input_service:get("cursor")
        local item_size = edit_pivot_table_functions.get_default_edit_item_size()

        if on_pressed then
            widget.size = item_size
            content.drag_active = true
            if content.is_expanded then
                content.is_expanded = false
                local values_grid_settings = scenegraphs_data.edit_pivot_table.grids.values
                local values_grid = values_grid_settings.grid
                values_grid:force_update_list_size()
            end
            content.cursor_start = Vector3.to_array(cursor)
            content.widget_start = table.clone(widget.offset)
            edit_pivot_table_functions.change_widget_renderer(widget, "default_renderer")
        end

        local drag_active = content.drag_active
        local left_released = input_service:get("left_released")
        local current_grid_name = content.current_grid_name
        local active_zone = edit_mode_cache.active_zone

        if drag_active and left_released then
            content.drag_active = false

            if current_grid_name == "column" then
                local widget_name = widget.name
                local column_widgets = scenegraphs_data.edit_pivot_table.grids.column.widgets
                for index, widget in ipairs(column_widgets) do
                    if widget.name ~= widget_name then
                        edit_pivot_table_functions.change_widget_grid(widget)
                        edit_pivot_table_functions.change_widget_renderer(widget, "default_renderer")
                        edit_pivot_table_functions.remove_widget(widget)                        
                    end
                end
            end

            if not current_grid_name then
                edit_pivot_table_functions.remove_widget(widget)
            else
                local new_renderer_name = renderer_name_lookup[current_grid_name]
                edit_pivot_table_functions.change_widget_renderer(widget, new_renderer_name)
                local grid = scenegraphs_data.edit_pivot_table.grids[current_grid_name].grid
                grid:force_update_list_size()
            end

        elseif drag_active then

            if current_grid_name ~= active_zone then
                edit_pivot_table_functions.change_widget_grid(widget, active_zone)
            end

            local cursor_x_start = content.cursor_start[1]
            local cursor_y_start = content.cursor_start[2]
            local widget_x_start = content.widget_start[1]
            local widget_y_start = content.widget_start[2]

            local inverse_scale = render_settings.inverse_scale
            local cursor_x_offset = (cursor[1] - cursor_x_start) * inverse_scale
            local cursor_y_offset = (cursor[2] - cursor_y_start) * inverse_scale

            widget.offset[1] = widget_x_start + cursor_x_offset
            local y_offset = widget_y_start + cursor_y_offset
            widget.offset[2] = y_offset
            widget.offset[3] = 5

            local current_grid_index = content.current_grid_index
            local current_grid_name = content.current_grid_name

            if not current_grid_index or not current_grid_name then
                return
            end

            local total_height_per_index = item_size[2] + 5
            local total_offset_at_index = (current_grid_index-1) * total_height_per_index

            local adjusted_y_offset = y_offset - total_offset_at_index

            local round_function = adjusted_y_offset > 0 and math.floor or math.ceil

            local grid_settings = scenegraphs_data.edit_pivot_table.grids[current_grid_name]
            local grid_widgets = grid_settings.widgets
            local grid_widgets_count = #grid_widgets
            local grid = grid_settings.grid

            local max_negative_index_offset = -1*(current_grid_index-1)
            local max_positive_index_offset = grid_widgets_count-current_grid_index


            local index_offset = round_function(adjusted_y_offset / total_height_per_index)
            index_offset = math.clamp(index_offset,max_negative_index_offset, max_positive_index_offset)

            if math.abs(index_offset) > 0 then
                change_grid_index(widget, grid, index_offset)
            end
        else
            content.cursor_start = nil
            content.widget_start = nil
            widget.offset[3] = 0
        end
    end
    edit_pivot_table_functions.in_values_grid_visibility_function = function(content)
        local content = content.parent or content
        return not content.drag_active and content.current_grid_name == "values"
    end
    edit_pivot_table_functions.expand_icon_change_function = function(content, style)
        local content = content.parent or content
        local hotspot = content.expand_hotspot
        local is_hover = hotspot.is_hover
        local is_expanded = content.is_expanded
        if is_expanded and is_hover then
            style.color = gold_highlight_color
            style.size_addition = {sizes.padding, sizes.padding}
        elseif is_expanded then
            style.color = gold_color
            style.size_addition = {0,0}
        elseif is_hover then
            style.color = Color.terminal_corner_hover(255, true)
            style.size_addition = {sizes.padding, sizes.padding}
        else
            style.color = terminal_green_color
            style.size_addition = {0,0}
        end
    end
    edit_pivot_table_functions.edit_item_hotspot_change_function = function(content, style)
        local content = content.parent
        if not content.drag_active and content.current_grid_name == "values" then
            style.size_addition[1] = -1* (sizes.header_3_height + sizes.padding)
        else
            style.size_addition[1] = 0
        end
    end
    edit_pivot_table_functions.toggle_expand_item_function = function(widget)
        local content = widget.content
        local new_expanded_state = not content.is_expanded
        content.is_expanded = new_expanded_state
        local new_scenegraph_id = new_expanded_state and "values_item_expanded" or "values_item"
        local scenegraph_settings = scenegraphs_data.edit_pivot_table
        local scenegraph_item = scenegraph_settings.scenegraph[new_scenegraph_id]
        local new_size = table.clone(scenegraph_item.size)
        widget.size = new_size

        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local values_grid_pivot = scenegraph.values_pivot
        local previous_pivot_y = math.abs(values_grid_pivot.position[2])
        local values_grid = scenegraph_settings.grids.values.grid

        values_grid:force_update_list_size()
    
        local total_grid_height= values_grid._total_grid_length
        local visible_grid_height = scenegraph.values_grid.size[2]
        
        local new_scrollbar_progress = math.clamp01(previous_pivot_y/(total_grid_height-visible_grid_height))
        values_grid:set_scrollbar_progress(new_scrollbar_progress)
    end
    edit_pivot_table_functions.expanded_visibility_function = function(content)
        local content = content.parent or content
        return content.is_expanded
    end
    edit_pivot_table_functions.expanded_calculated_field_visibility_function = function(content)
        local content = content.parent or content
        local is_expanded = content.is_expanded
        local field_type = content.value_template.type
        local is_calculated_field = field_type == "calculated_field"
        return is_expanded and is_calculated_field
    end
    edit_pivot_table_functions.expanded_normal_field_visibility_function = function(content)
        local content = content.parent or content
        local is_expanded = content.is_expanded
        local field_type = content.value_template.type
        local is_normal_field = field_type ~= "calculated_field"
        return is_expanded and is_normal_field
    end
    edit_pivot_table_functions.edit_item_title_change_function = function(content, style)
        local content = content.parent or content
        local current_crid_name = content.current_grid_name
        
        if current_crid_name == "values" then
            content.title.text = content.child_widgets.label_input_widget.content.input_text
        else
            content.title.text = content.title.default_text
        end
        
        item_drag_change_function(content, style)
    end
    edit_pivot_table_functions.child_widget_logic_function = function(parent_widget, child_widget, pass, ui_renderer, ui_style, content, position, size)

        local content = parent_widget.content
        local is_expanded = content.is_expanded

        if is_expanded then
            child_widget.visible = true
            child_widget.offset[2] = child_widget.default_offset[2] + parent_widget.offset[2]
        else
            child_widget.visible = false
        end
    end
    edit_pivot_table_functions.get_edit_item_passes_template = function()
        local item_size = edit_pivot_table_functions.get_default_edit_item_size()
        local item_passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,0,2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    content = {
                        default_text = "temp"
                    },
                    change_function = edit_pivot_table_functions.edit_item_title_change_function,
                },
                {   content_id = "left_bar",
                    pass_type = "rect",
                    style_id = "left_bar",
                    style = {
                        vertical_alignment = {"center"},
                        horizontal_alignment = {"left"},
                        size = {sizes.padding_half, sizes.header_3_height},
                        color = font_color,
                        offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                    change_function = item_drag_change_function,
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "left",
                        size_addition = {0,0},
                    },
                    content = {
                        use_is_focused = true,
                    },
                    change_function = edit_pivot_table_functions.edit_item_hotspot_change_function
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_drag_change_function,
                    style = {
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                        default_offset = {0,0,-2},
                    },
                },
                {   value_id = "frame",
                    style_id = "frame",
                    pass_type = "texture",
                    value = "content/ui/materials/frames/frame_tile_2px",
                    change_function = item_drag_change_function,
                    style = {
                        color = {0,0,0,0},
                        offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                },
                {   value_id = "drag_logic",
                    pass_type = "logic",
                },
                {   content_id = "background",
                    pass_type = "rect",
                    style_id = "background",
                    style = {
                        color = {255,0,10,0},
                        offset = {0,0,-3},
                        default_offset = {0,0,-3},
                    },
                    visibility_function = function(content) return content.parent.drag_active end,
                },
                {   value_id = "expand_icon",
                    style_id = "expand_icon",
                    pass_type = "texture",
                    value = "content/ui/materials/buttons/dropdown_line",
                    change_function = edit_pivot_table_functions.expand_icon_change_function,
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center", 
                        size = {sizes.header_3_height - 2*sizes.padding, sizes.header_3_height - 2*sizes.padding},
                        color = terminal_green_color,
                        default_color = terminal_green_color,
                        offset = {0.5*(item_size[1]-sizes.header_3_height) - sizes.padding_half,0,0},
                        default_offset = {0,0,0},
                    },
                    visibility_function = edit_pivot_table_functions.in_values_grid_visibility_function,
                },
                {   content_id = "expand_hotspot",
                    style_id = "expand_hotspot",
                    pass_type = "hotspot",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "right",
                        size = {sizes.header_3_height - sizes.padding, sizes.header_3_height - sizes.padding},
                        size_addition = {0,0},
                    },
                    content = {
                        use_is_focused = true,
                    },
                    visibility_function = edit_pivot_table_functions.in_values_grid_visibility_function,
                },
                {   value_id = "expanded_frame",
                    style_id = "expanded_frame",
                    pass_type = "texture",
                    value = "content/ui/materials/frames/line_thin_detailed_02",
                    change_function = item_drag_change_function,
                    style = {
                        color = gold_color,
                        offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                    visibility_function = edit_pivot_table_functions.expanded_visibility_function,
                    scenegraph_id = "values_item_settings"
                },
                {   content_id = "label_title",
                    value_id = "label_title",
                    value = mod:localize("mloc_edit_item_label"),
                    pass_type = "text",
                    style_id = "label_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,0,2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                    visibility_function = edit_pivot_table_functions.expanded_visibility_function,
                    scenegraph_id  ="values_item_setting_header"
                },
                {   value_id = "label_input_logic",
                    pass_type = "logic",
                },
                {   value_id = "label_input_logic_2",
                    pass_type = "logic",
                },
                {   content_id = "field_title",
                    value_id =  "field_title",
                    value = mod:localize("mloc_edit_item_field"),
                    pass_type = "text",
                    style_id = "field_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,sizes.header_3_height+sizes.padding_half,2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                    visibility_function = edit_pivot_table_functions.expanded_normal_field_visibility_function,
                    scenegraph_id  ="values_item_setting_header"
                },
                {   content_id = "field_input",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "field_input",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {3,sizes.header_3_height+sizes.padding_half,2},
                        default_offset = {3,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    visibility_function = edit_pivot_table_functions.expanded_normal_field_visibility_function,
                    scenegraph_id  ="values_item_setting_input"
                },
                {   content_id = "formula_title",
                    value_id =  "field_title",
                    value = mod:localize("mloc_edit_item_formula"),
                    pass_type = "text",
                    style_id = "formula_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,sizes.header_3_height+sizes.padding_half,2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                    visibility_function = edit_pivot_table_functions.expanded_calculated_field_visibility_function,
                    scenegraph_id  ="values_item_setting_header"
                },
                {   value_id = "formula_input_logic",
                    pass_type = "logic",
                },
                {   value_id = "formula_input_logic_2",
                    pass_type = "logic",
                },
                {   content_id = "format_title",
                    value_id = "format_title",
                    value = mod:localize("mloc_edit_item_format"),
                    pass_type = "text",
                    style_id = "format_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,2*(sizes.header_3_height+sizes.padding_half),2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                    visibility_function = edit_pivot_table_functions.expanded_visibility_function,
                    scenegraph_id  ="values_item_setting_header"
                },
                {   value_id = "format_input_logic",
                    pass_type = "logic",
                },
                {   content_id = "visible_title",
                    value_id = "visible_title",
                    value = mod:localize("mloc_edit_item_visible"),
                    pass_type = "text",
                    style_id = "visible_title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,3*(sizes.header_3_height+sizes.padding_half),2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = gold_color,
                    },
                    visibility_function = edit_pivot_table_functions.expanded_visibility_function,
                    scenegraph_id  ="values_item_setting_header"
                },
                {   value_id = "visible_input_logic",
                    pass_type = "logic",
                },
        }
        return item_passes
    end
    edit_pivot_table_functions.add_edit_widget_to_renderer = function(widget, renderer_name)
        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local renderer_settings = renderers[renderer_name]
        local renderer_widgets = renderer_settings.scenegraphs[scenegraph]
        local renderer_index = #renderer_widgets+1
        local content = widget.content

        content.current_renderer_name = renderer_name
        content.current_renderer_index = renderer_index
        renderer_widgets[renderer_index] = widget
    end
    edit_pivot_table_functions.create_edit_item_child_widgets = function(parent_widget, field_type)
        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local parent_widget_content = parent_widget.content
        local base_offset_y = sizes.header_3_height + sizes.padding_half
        local child_widgets = {}

        local label_input_passes = get_custom_text_input_template()
        local label_input_definition = UIWidget.create_definition(label_input_passes, "values_item_setting_input")

        local label_input_widget = UIWidget.init("label_input", label_input_definition)
        local label_input_widget_content = label_input_widget.content
        label_input_widget_content.input_text = parent_widget.content.title.default_text
        label_input_widget.offset = {0,0}
        label_input_widget.default_offset = {0,0}

        child_widgets.label_input_widget = label_input_widget
        parent_widget_content.label_input_logic = callback(edit_pivot_table_functions.child_widget_logic_function, parent_widget, label_input_widget)

        local label_input_logic_2_function = function(parent_widget, label_input_widget)
            local value_template = parent_widget.content.value_template
            local label_input_text = label_input_widget.content.input_text
            value_template.label = label_input_text
        end

        parent_widget_content.label_input_logic_2 = callback(label_input_logic_2_function, parent_widget, label_input_widget)

        if field_type == "calculated_field" then
            parent_widget.content.value_template.type = "calculated_field"
            local formula_input_passes = get_custom_text_input_template()
            local formula_input_definition = UIWidget.create_definition(formula_input_passes, "values_item_setting_input")
            local formula_input_widget = UIWidget.init("formula_input", formula_input_definition)
            formula_input_widget.offset = {0,base_offset_y}
            formula_input_widget.default_offset = {0,base_offset_y}
            child_widgets.formula_input_widget = formula_input_widget
            parent_widget_content.formula_input_logic = callback(edit_pivot_table_functions.child_widget_logic_function, parent_widget, formula_input_widget)

            local formula_input_logic_2_function = function(parent_widget, formula_input_widget)
                local value_template = parent_widget.content.value_template
                local formula_input_text = formula_input_widget.content.input_text
                value_template.function_string = formula_input_text
            end
            parent_widget_content.formula_input_logic_2 = callback(formula_input_logic_2_function, parent_widget, formula_input_widget)

        else
            parent_widget.content.value_template.type = (field_type == "number") and "sum" or "count"
        end

        local format_input_options = get_dropdown_options("value_formats")

        local format_input_changed_callback_function = function(widget, option_id)
            widget.content.value_template.format = option_id
        end

        local format_input_widget = generate_horizontal_options_widget("edit_pivot_table", "values_item_setting_input", format_input_options, callback(format_input_changed_callback_function, parent_widget), false)
        
        format_input_widget.offset = {0,2*base_offset_y}
        format_input_widget.default_offset = {0,2*base_offset_y}

        format_input_widget.content.selected_id = "none"
        parent_widget.content.value_template.format = "none"
        
        child_widgets.format_input_widget = format_input_widget
        parent_widget_content.format_input_logic = callback(edit_pivot_table_functions.child_widget_logic_function, parent_widget, format_input_widget)

        local visible_input_options = get_dropdown_options("boolean")
        local visible_input_changed_callback_function = function(widget, option_id)
            widget.content.value_template.visible = option_id
        end

        local visible_input_widget = generate_horizontal_options_widget("edit_pivot_table", "values_item_setting_input", visible_input_options, callback(visible_input_changed_callback_function, parent_widget), false)
        
        visible_input_widget.offset = {0,3*base_offset_y}
        visible_input_widget.default_offset = {0,3*base_offset_y}

        visible_input_widget.content.selected_id = true
        parent_widget.content.value_template.visible = true

        child_widgets.visible_input_widget = visible_input_widget
        parent_widget_content.visible_input_logic = callback(edit_pivot_table_functions.child_widget_logic_function, parent_widget, visible_input_widget)

        local renderer_widgets = renderers.offscreen_renderer_3.scenegraphs[scenegraph]

        for _, child_widget in pairs(child_widgets) do
            child_widget.visible = false
            local renderer_index = #renderer_widgets+1
            renderer_widgets[renderer_index] = child_widget
            child_widget.content.current_renderer_index = renderer_index
        end

        parent_widget_content.child_widgets = child_widgets
    end
    edit_pivot_table_functions.create_edit_item_widget = function(widget_name, scenegraph_id, field_type)
        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local scenegraph_item_size = scenegraph[scenegraph_id].size
        local edit_widget_pass_template = edit_pivot_table_functions.get_edit_item_passes_template()
        local edit_widget_definition = UIWidget.create_definition(edit_widget_pass_template, scenegraph_id)

        local edit_widget = UIWidget.init(widget_name, edit_widget_definition)
        local edit_widget_content = edit_widget.content

        edit_widget_content.title.default_text = widget_name
        edit_widget_content.field_input.text = widget_name
        edit_widget_content.drag_logic = callback(edit_pivot_table_functions.edit_item_drag_function, edit_widget)
        edit_widget_content.size = {scenegraph_item_size[1],scenegraph_item_size[2]}
        edit_widget_content.value_template = {}

        if field_type ~= "calculated_field" then
            edit_widget_content.value_template.field_name = widget_name
        end

        local toggle_expand_callback = callback(edit_pivot_table_functions.toggle_expand_item_function, edit_widget)
        local edit_widget_passes = edit_widget.passes
        edit_widget_passes[9].change_function = callback(on_clicked_callback_hotspot_change_function, toggle_expand_callback)

        update_font_sizes({edit_widget}, "edit_pivot_table")

        edit_pivot_table_functions.create_edit_item_child_widgets(edit_widget, field_type)

        return edit_widget
    end
    edit_pivot_table_functions.create_edit_item_widget_from_dataset_widget = function(widget)
        local field_type = widget.content.field_type.value_id

        local edit_widget = edit_pivot_table_functions.create_edit_item_widget(widget.name, "edit_item", field_type)
        local edit_widget_content = edit_widget.content

        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local cursor = input_service:get("cursor")
        local pivot_scenegraph_position = scenegraph.dataset_fields_pivot.position
        local widget_x = widget.offset[1] + pivot_scenegraph_position[1]
        local widget_y = widget.offset[2] + pivot_scenegraph_position[2]

        edit_widget.offset = {widget_x, widget_y}
        edit_widget_content.widget_start = {widget_x, widget_y}
        edit_widget_content.cursor_start = Vector3.to_array(cursor)
        edit_widget_content.drag_active = true

        local renderer_name = "default_renderer"
        edit_pivot_table_functions.add_edit_widget_to_renderer(edit_widget, renderer_name)

        return edit_widget
    end
    edit_pivot_table_functions.create_calculated_field_edit_item_widget = function()
        local widget_name = "calculated_field_"..PDI.utilities.uuid()
        local widget_label = "calculated_field"
        local scenegraph_id = "values_item"

        local edit_widget = edit_pivot_table_functions.create_edit_item_widget(widget_name,scenegraph_id, "calculated_field")

        local edit_widget_content = edit_widget.content
        edit_widget_content.title.default_text = widget_label

        local label_input_widget = edit_widget_content.child_widgets.label_input_widget
        local label_input_widget_content = label_input_widget.content
        label_input_widget_content.input_text = widget_label

        local renderer_name = "offscreen_renderer_3"
        edit_pivot_table_functions.add_edit_widget_to_renderer(edit_widget, renderer_name)

        local grid_name = "values"
        edit_pivot_table_functions.change_widget_grid(edit_widget, grid_name)
        return edit_widget
    end
    edit_pivot_table_functions.dataset_field_item_hotspot_change_function = function(widget, content, style)
        local on_pressed = content.on_pressed
        if on_pressed then
            edit_pivot_table_functions.create_edit_item_widget_from_dataset_widget(widget)
        end
    end
    edit_pivot_table_functions.get_scenegraph = function()
        return scenegraphs_data.edit_pivot_table.scenegraph
    end
    edit_pivot_table_functions.add_calculated_field_callback = function()
        local calculated_field_widget = edit_pivot_table_functions.create_calculated_field_edit_item_widget()
    end
    edit_pivot_table_functions.get_dataset_field_item_template = function()
        local item_template = {
            passes = {
                {   content_id = "title",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "title",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {sizes.padding,0,2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    change_function = item_drag_change_function,
                },
                {   content_id = "field_type",
                    value_id = "text",
                    value = "temp",
                    pass_type = "text",
                    style_id = "field_type",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "right",
                        offset = {sizes.padding,0,2},
                        default_offset = {sizes.padding,0,2},
                        font_type = font_type,
                        font_size = font_size,
                        default_font_size = font_size,
                        text_color = font_color,
                    },
                    content = {},
                    change_function = item_drag_change_function,
                },
                {   content_id = "left_bar",
                    pass_type = "rect",
                    style_id = "left_bar",
                    style = {
                        vertical_alignment = {"center"},
                        horizontal_alignment = {"left"},
                        size = {sizes.padding_half, sizes.header_3_height},
                        color = font_color,
                        offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                    change_function = item_drag_change_function,
                },
                {   content_id = "hotspot",
                    style_id = "hotspot",
                    pass_type = "hotspot",
                    content = {
                        use_is_focused = true,
                    }
                },
                {   value_id = "background_gradient",
                    style_id = "background_gradient",
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
                    change_function = item_gradient_drag_change_function,
                    style = {
                        color = {0,0,0,0},
                        offset = {0,0,-2},
                        default_offset = {0,0,-2},
                    },
                },
                {   value_id = "frame",
                    style_id = "frame",
                    pass_type = "texture",
                    value = "content/ui/materials/frames/frame_tile_2px",
                    change_function = item_drag_change_function,
                    style = {
                        color = {0,0,0,0},
                        offset_offset = {0,0,0},
                        default_offset = {0,0,0},
                    },
                },
                {   value_id = "drag_logic",
                    pass_type = "logic",
                },
                {   content_id = "background",
                    pass_type = "rect",
                    style_id = "background",
                    style = {
                        color = {255,0,10,0},
                        offset = {0,0,-3},
                        default_offset = {0,0,-3},
                    },
                    visibility_function = function(content) return content.parent.drag_active end,
                },
            },
            scenegraph_id = "dataset_fields_item",
        }
        return item_template
    end
    edit_pivot_table_functions.create_dataset_field_widgets = function(dataset_name)
        local scenegraph = edit_pivot_table_functions.get_scenegraph()
        local dataset_template = PDI.dataset_manager.get_dataset_template(dataset_name)
        local dataset_legend = dataset_template.legend

        local widget_templates = {}

        for dataset_field_name, dataset_field_type in pairs(dataset_legend) do
            local item_template = edit_pivot_table_functions.get_dataset_field_item_template()
            item_template.name = dataset_field_name
            item_template.passes[1].value = dataset_field_name
            local localized_dataset_field_type = mod:localize("mloc_field_type_"..dataset_field_type)
            item_template.passes[2].value = "("..localized_dataset_field_type..")"
            item_template.passes[2].style.offset[1] = -1*sizes.padding
            item_template.passes[2].content.value_id = dataset_field_type

            widget_templates[#widget_templates+1] = item_template 
        end

        table.sort(widget_templates, function(v1,v2) return v1.name < v2.name end)

        local widgets, widgets_by_name = generate_widgets(widget_templates)

        update_font_sizes(widgets, scenegraph_name)

        for index, widget in ipairs(widgets) do
            widget.content.size = scenegraph.dataset_fields_item.size
            widget.passes[4].change_function = callback(edit_pivot_table_functions.dataset_field_item_hotspot_change_function, widget)
            widget.current_grid_index = index
        end

        local dataset_fields_grid = generate_grid("dataset_fields", scenegraph_name, widgets, widgets_by_name, "dataset_fields_grid", "down", {0,sizes.padding_half}, "dataset_fields_scrollbar", "dataset_fields_pivot")

        renderers.offscreen_renderer_1.scenegraphs[scenegraph] = widgets
    end
    edit_pivot_table_functions.load_report_template_to_edit = function(template)
        if not edit_mode_cache then
            return
        end
    
        local template_name = template.template_name or 1
        local widgets_by_name = scenegraphs_data.edit_report_settings.widgets_by_name
        local name_input_widget = widgets_by_name.name_input
        local template_dropdown_widget = widgets_by_name.template_input
        local dataset_dropdown_widget = widgets_by_name.dataset_input
        local report_type_dropdown_widget = widgets_by_name.report_type_input
    
        name_input_widget.content.input_text = template.name
    
        local template_widget_content = template_dropdown_widget.content
        local template_options_by_id = template_widget_content.options_by_id
        local template_option = template_options_by_id[template_name]
        local template_index = template_option and template_option.index
        local template_id = template_option and template_option.id
        template_widget_content.selected_index = template_index
        if edit_mode_cache.mode == "edit" then
            template_widget_content.set_disabled = true
        end
        edit_mode_cache.selected_template = template_id
    
        local dataset_name = template.dataset_name
        local dataset_widget_content = dataset_dropdown_widget.content
        local dataset_options_by_id = dataset_widget_content.options_by_id
        local dataset_option = dataset_options_by_id[dataset_name]
        local dataset_index = dataset_option and dataset_option.index
        local dataset_id = dataset_option and dataset_option.id
        dataset_widget_content.selected_index = dataset_index
        dataset_widget_content.set_disabled = true
        edit_mode_cache.selected_dataset = dataset_id
    
        local report_type_name = "mloc_report_type_pivot_table"
        local report_type_widget_content = report_type_dropdown_widget.content
        local report_type_options_by_id = report_type_widget_content.options_by_id
        local report_type_option = report_type_options_by_id[report_type_name]
        local report_type_index = report_type_option and report_type_option.index
        local report_type_id = report_type_option and report_type_option.id
        report_type_widget_content.selected_index = report_type_index
        report_type_widget_content.set_disabled = true
        edit_mode_cache.selected_report_type = report_type_id
    
        local dataset_template = PDI.dataset_manager.get_dataset_template(dataset_name)
        local dataset_legend = dataset_template.legend
        local column_name = template.columns[1]
        local column_scenegraph_id = "column_item"
        local column_type = dataset_legend[column_name]
        local column_widget = edit_pivot_table_functions.create_edit_item_widget(column_name, column_scenegraph_id, column_type)
        local column_grid_name = "column"
        local column_renderer_name = renderer_name_lookup[column_grid_name]
        edit_pivot_table_functions.add_edit_widget_to_renderer(column_widget, column_renderer_name)
        edit_pivot_table_functions.change_widget_grid(column_widget, column_grid_name)
    
        local rows = template.rows
        local rows_scenegraph_id = "rows_item"
        local rows_grid_name = "rows"
        local rows_renderer_name = renderer_name_lookup[rows_grid_name]
    
        for _, row_name in ipairs(rows) do
            local row_type = dataset_legend[row_name]
            local rows_widget = edit_pivot_table_functions.create_edit_item_widget(row_name, rows_scenegraph_id, row_type)
            edit_pivot_table_functions.add_edit_widget_to_renderer(rows_widget, rows_renderer_name)
            edit_pivot_table_functions.change_widget_grid(rows_widget, rows_grid_name)
        end
    
        local values = template.values
        local values_scenegraph_id = "values_item"
        local values_grid_name = "values"
        local values_renderer_name = renderer_name_lookup[values_grid_name]
    
        local values_grid_settings = scenegraphs_data.edit_pivot_table.grids[values_grid_name]
        local values_grid = values_grid_settings.grid
    
        for _, value_template in ipairs(values) do
            local calculated_field_uuid = "calculated_field_"..PDI.utilities.uuid()
            local value_name = value_template.field_name or calculated_field_uuid
            local value_type = dataset_legend[value_name] or "calculated_field"
            local values_widget = edit_pivot_table_functions.create_edit_item_widget(value_name, values_scenegraph_id, value_type)
            
            local values_widget_content = values_widget.content
            values_widget_content.value_template = value_template
    
            local child_widgets = values_widget_content.child_widgets
            child_widgets.label_input_widget.content.input_text = value_template.label
            if value_type == "calculated_field" then
                child_widgets.formula_input_widget.content.input_text = value_template.function_string
            end
            child_widgets.format_input_widget.content.selected_id = value_template.format
            child_widgets.visible_input_widget.content.selected_id = value_template.visible
    
            edit_pivot_table_functions.add_edit_widget_to_renderer(values_widget, values_renderer_name)
            edit_pivot_table_functions.change_widget_grid(values_widget, values_grid_name)
        end
        values_grid:force_update_list_size()
    
        local data_filter_input_widget = scenegraphs_data.edit_pivot_table.widgets_by_name.data_filter_input
        local data_filter_input_widget_content = data_filter_input_widget.content
        local filter_string = template.filters[1] or ""
        local new_caret_position = Utf8.string_length(filter_string)+1
        data_filter_input_widget_content.input_text = filter_string
        data_filter_input_widget_content.caret_position = new_caret_position
        data_filter_input_widget_content.force_caret_update = true
    end

    local widget_templates = edit_pivot_table_functions.get_widget_templates()
    local widgets, widgets_by_name = generate_widgets(widget_templates)
    local scenegraph = generate_scenegraph(scenegraph_name, widgets, widgets_by_name)
    update_font_sizes(widgets, scenegraph_name)

    -- for _, widget in ipairs(widgets) do
    --     local scenegraph_id = widget.scenegraph_id
    --     local scenegraph_item = scenegraph[scenegraph_id]
    --     local scenegraph_item_size = table.clone(scenegraph_item.size)
    --     widget.content.size = scenegraph_item_size
    -- end

    renderers.offscreen_renderer_1.scenegraphs[scenegraph] = {}
    renderers.offscreen_renderer_2.scenegraphs[scenegraph] = {}
    renderers.offscreen_renderer_3.scenegraphs[scenegraph] = {}

    local dataset_fields_grid = generate_grid("dataset_fields", scenegraph_name, {}, {}, "dataset_fields_grid", "down", {0,sizes.padding_half}, "dataset_fields_scrollbar", "dataset_fields_pivot")

    local column_grid = generate_grid("column", scenegraph_name, {}, {}, "column_grid", "down", {0,sizes.padding_half})

    local rows_grid = generate_grid("rows", scenegraph_name, {}, {}, "rows_grid", "down", {0,sizes.padding_half}, "rows_scrollbar", "rows_pivot")

    local values_grid = generate_grid("values", scenegraph_name, {}, {}, "values_grid", "down", {0,sizes.padding_half}, "values_scrollbar", "values_pivot")
end

return ui_manager