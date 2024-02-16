local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local UIRenderer = mod:original_require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")

local DropdownPassTemplates = require("scripts/ui/pass_templates/dropdown_pass_templates")
local ScrollbarPassTemplates = require("scripts/ui/pass_templates/scrollbar_pass_templates")
local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")

local TextInputPassTemplates = require("scripts/ui/pass_templates/text_input_pass_templates")

local CustomMultiLineTextInput = mod:io_dofile("Power_DI/scripts/mods/Power_DI/views/widgets/custom_multi_line_text_input")

local input_service = Managers.input:get_input_service("View")

local PDI, instance, view_manager, anchor_position, sizes, font_name, font_size, options_array, session_dropdown_widget, report_list, offscreen_renderers

local data

local widget_grid_lookup

local frame_size_addition = {-15,-10}

local field_type_dropdown_options = {
    {id = "sum", display_name = "Sum"},
    {id = "count", display_name = "Count"},
    {id = "calculated_field", display_name = "Calculated field"},
}
local value_format_dropdown_options = {
    {id = "none", display_name = "None"},
    {id = "number", display_name = "Number"},
    {id = "percentage", display_name = "Percentage"},
}
local value_visible_dropdown_options = {
    {id = true, display_name = "True"},
    {id = false, display_name = "False"},
}

PdiEditViewElement = class("PdiEditViewElement", "PdiBaseViewElement")

local function sort_widgets(widgets)
    table.sort(widgets, function(v1,v2) return v1.content.text < v2.content.text end)
end
local function set_widgets_content(widgets,current_grid_name)
    for index, widget in ipairs(widgets) do
        widget.content.current_grid_index = index
        widget.content.current_grid_name = current_grid_name
        widget.content.hotspot.is_selected = false
    end
end
local function move_widget(widget, target_name)
    local source_name = widget.content.current_grid_name
    local source_data = data[source_name]
    local source_grid = source_data.grid
    local source_grid_widgets = source_grid._widgets
    local source_grid_index = widget.content.current_grid_index

    table.remove(source_grid_widgets, source_grid_index)
    --source_grid.selected_grid_index = nil
    source_grid._selected_grid_index = nil
    set_widgets_content(source_grid_widgets, source_name)
    source_grid:force_update_list_size()
    
    local target_grid = data[target_name].grid
    local target_grid_widgets = target_grid._widgets
    local target_grid_index = #target_grid_widgets+1
    
    widget.scenegraph_id = target_name.."_item"
    target_grid_widgets[target_grid_index] = widget
    --target_grid.selected_grid_index = nil
    target_grid._selected_grid_index = nil
    if target_name == "fields" then
        sort_widgets(target_grid_widgets)
    end
    set_widgets_content(target_grid_widgets, target_name)
    target_grid:force_update_list_size()
end
local function change_widget_index(widget, offset)
    local source_name = widget.content.current_grid_name
    local source_grid_index =  widget.content.current_grid_index
    local source_data = data[source_name]
    local source_grid = source_data.grid
    local source_grid_widgets = source_grid._widgets
    
    table.remove(source_grid_widgets, source_grid_index)
    table.insert(source_grid_widgets, source_grid_index + offset, widget)

    set_widgets_content(source_grid_widgets,source_name)
    source_grid:force_update_list_size()
    source_grid:select_grid_index(source_grid_index + offset)
end
local function save_button_callback(self)
    local report_template = {}

    local widgets = self._widgets_by_name
    local report_name_text_input = widgets.report_name_text_input
    local dataset_dropdown = widgets.dataset_dropdown
    local report_type_dropdown = widgets.report_type_dropdown
    local filter_text_input = widgets.filter_text_input

    local column_widgets = data.columns.widgets
    local rows_widgets = data.rows.widgets
    local value_widgets = data.values.widgets

    report_template.name = report_name_text_input.content.input_text
    report_template.label = report_name_text_input.content.input_text
    report_template.dataset_name = dataset_dropdown.content.options[dataset_dropdown.content.selected_index].id
    report_template.report_type = report_type_dropdown.content.options[report_type_dropdown.content.selected_index].id
    report_template.columns = {}
    report_template.rows = {}
    report_template.values = {}
    report_template.filters = {filter_text_input.content.input_text}

    for _, widget in ipairs(column_widgets) do
        report_template.columns[#report_template.columns+1] = widget.name
    end

    for _, widget in ipairs(rows_widgets) do
        report_template.rows[#report_template.rows+1] = widget.name
    end

    for _, widget in ipairs(value_widgets) do
        report_template.values[#report_template.values+1] = widget.content.value_settings
    end

    view_manager.set_selected_report_name(report_template.name)

    PDI.report_manager.add_user_report(report_template)

    PDI.save_manager.save("save_data", PDI.data.save_data)
    :next(
        function()
            mod:notify("Saved")
        end
    )
end
local function exit_button_callback(self)
    local view_instance = view_manager.get_current_view_instance()
    if view_instance._elements["PdiEditViewElement"] then
        view_instance:_remove_element("PdiEditViewElement")
    end
    view_manager.init_main_view_elements(view_instance)
end
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
local function save_button_change_function(content, style)
    local can_save

    local widgets = instance._widgets_by_name
    local report_name_text_input = widgets.report_name_text_input
    local dataset_dropdown = widgets.dataset_dropdown
    local report_type_dropdown = widgets.report_type_dropdown

    local column_widgets = data.columns.widgets
    local rows_widgets = data.rows.widgets
    local value_widgets = data.values.widgets

    if not report_name_text_input.content.input_text then
        can_save = false
    elseif not dataset_dropdown.content.selected_index then
        can_save = false
    elseif not report_type_dropdown.content.selected_index then
        can_save = false
    elseif #column_widgets < 1 or #rows_widgets < 1 or #value_widgets < 1 then
        can_save = false
    else
        can_save = true
    end

    if can_save then
        content.disabled = false
    else
        content.disabled = true
    end
end
local function add_column_button_change_function(content, style)
    local fields_grid = data.fields.grid
    local columns_grid = data.columns.grid
    local columns_grid_widgets = columns_grid._widgets
    if fields_grid:selected_grid_index() and #columns_grid_widgets == 0 then
        content.disabled = false
    else
        content.disabled = true
    end
end
local function add_row_button_change_function(content, style)
    local fields_grid = data.fields.grid
    if fields_grid:selected_grid_index() then
        content.disabled = false
    else
        content.disabled = true
    end
end
local function remove_button_visibility_function(content)
    local hotspot
    if content.hotspot then
        hotspot = content.hotspot
    else
        hotspot = content.parent.hotspot
    end
    return hotspot.is_selected and hotspot._is_selected and content.current_grid_name ~= "fields"
end
local function remove_button_visibility_function_2(content)
    local hotspot
    if content.hotspot then
        hotspot = content.hotspot
    else
        hotspot = content.parent.hotspot
    end
    return hotspot.is_selected and hotspot._is_selected
end
local function up_button_visibility_function(content)
    if not content.hotspot then
        content = content.parent
    end

    local current_grid_name = content.current_grid_name
    if current_grid_name == "fields" then
        return false
    end

    local hotspot = content.hotspot
    if not hotspot.is_selected and not hotspot._is_selected then
        return false
    end


    local current_grid_index = content.current_grid_index

    if current_grid_index > 1 then
        return true
    else
        return false
    end
end
local function down_button_visibility_function(content)
    if not content.hotspot then
        content = content.parent
    end

    local current_grid_name = content.current_grid_name
    if current_grid_name == "fields" then
        return false
    end

    local hotspot = content.hotspot
    if not hotspot.is_selected and not hotspot._is_selected then
        return false
    end


    local current_grid_index = content.current_grid_index

    local current_data = data[current_grid_name]
    local current_grid = current_data.grid
    local current_grid_widgets = current_grid._widgets
    local widgets_cound = #current_grid_widgets

    if current_grid_index < #current_grid_widgets then
        return true
    else
        return false
    end
end
local function add_column_callback(self)
    local fields_grid = data.fields.grid
    local fields_grid_selected_index = fields_grid:selected_grid_index()
    local fields_grid_widgets = fields_grid._widgets
    local field_widget = fields_grid_widgets[fields_grid_selected_index]

    move_widget(field_widget, "columns")
end
local function add_row_callback(self)
    local fields_grid = data.fields.grid
    local fields_grid_selected_index = fields_grid:selected_grid_index()
    local fields_grid_widgets = fields_grid._widgets
    local field_widget = fields_grid_widgets[fields_grid_selected_index]

    move_widget(field_widget, "rows")
end
local function remove_field_callback(self, widget)
    local source_name = widget.content.current_grid_name
    move_widget(widget, "fields")
end
local function create_custom_button_definition(self, scenegraph_id, button_text, button_callback, change_function)

    local definition = UIWidget.create_definition(ButtonPassTemplates.terminal_button, scenegraph_id, {original_text = button_text, hotspot = {pressed_callback = button_callback}})

    if change_function then
        definition.passes[1].change_function = change_function
    end

    

    definition.passes[1].visibility_function = function(content)
        if not self.focussed_hotspot then
            return true
        else
            return false
        end
    end

    return definition
end
local function create_custom_text_input_definition(self, scenegraph_id)

    local definition = UIWidget.create_definition(TextInputPassTemplates.terminal_input_field , scenegraph_id)

    definition.passes[1].change_function = text_input_hotspot_change_function

    definition.passes[1].visibility_function = function(content)
        if not self.focussed_hotspot then
            return true
        else
            return false
        end
    end

    definition.style.baseline.visible = false

    return definition
end
local function set_value_settings(self, value_settings)
    local widgets = self._widgets_by_name

    local label_widget_content = widgets.value_label_text_input.content
    local function_widget_content = widgets.value_function_text_input.content
    local type_widget_content = widgets.value_type_dropdown.content
    local field_widget_content = widgets.value_field_dropdown.content
    local visible_widget_content = widgets.value_visible_dropdown.content
    local format_widget_content = widgets.value_format_dropdown.content

    local label_string = value_settings.label
    label_widget_content.input_text = label_string
    label_widget_content.caret_position = Utf8.string_length(label_string)+1
    label_widget_content.force_caret_update = true 

    local function_string = value_settings.function_string

    if function_string then
        function_widget_content.input_text = function_string
        function_widget_content.caret_position = Utf8.string_length(function_string)+1
        function_widget_content.force_caret_update = true
    else
        function_widget_content.input_text = ""
        function_widget_content.caret_position = 1
        function_widget_content.force_caret_update = true
    end 

    local type_widget_index = type_widget_content.options_by_id[value_settings.type].index
    type_widget_content.selected_index = type_widget_index

    local field_name = value_settings.field_name

    if field_name then
        local field_widget_index = field_widget_content.options_by_id[field_name].index
        field_widget_content.selected_index = field_widget_index
    else
        field_widget_content.selected_index = nil
    end

    local visible_widget_index = visible_widget_content.options_by_id[value_settings.visible].index
    visible_widget_content.selected_index = visible_widget_index

    local format_widget_index = format_widget_content.options_by_id[value_settings.format].index
    format_widget_content.selected_index = format_widget_index
end
local function value_widget_selected_callback(self, widget, widget_index)
    local grid = data.values.grid
    local current_selected_index = grid:selected_grid_index()
    
    if widget_index == current_selected_index then
        return
    end

    grid:select_grid_index(widget_index)

    local value_settings = widget.content.value_settings

    set_value_settings(self, value_settings)
end
local function clear_value_options(self)
    local widgets_by_name = self._widgets_by_name
    local label_widget = widgets_by_name.value_label_text_input
    local function_widget = widgets_by_name.value_function_text_input
    local type_widget = widgets_by_name.value_type_dropdown
    local field_widget = widgets_by_name.value_field_dropdown
    local visible_widget = widgets_by_name.value_visible_dropdown
    local format_widget = widgets_by_name.value_format_dropdown

    local label_content = label_widget.content
    label_content.input_text = ""
    label_content.display_text = ""
    label_content.caret_position = 1
    label_content.is_writing = false
    
    local function_content = function_widget.content
    function_content.input_text = ""
    function_content.display_text = ""
    function_content.caret_position = 1
    function_content.is_writing = false

    type_widget.content.selected_index = nil
    field_widget.content.selected_index = nil
    visible_widget.content.selected_index = nil
    format_widget.content.selected_index = nil
end
local function remove_value_callback(self, widget)
    local value_fields = data.values
    local widgets = value_fields.widgets
    local grid = value_fields.grid
    local selected_grid_index = grid._selected_grid_index

    table.remove(widgets,selected_grid_index)
    grid._selected_grid_index = nil
    grid:force_update_list_size()
    clear_value_options(self)
end
local function get_value_setting(self)
    local widgets = self._widgets_by_name

    local label_widget_content = widgets.value_label_text_input.content
    local function_widget_content = widgets.value_function_text_input.content
    local type_widget_content = widgets.value_type_dropdown.content
    local field_widget_content = widgets.value_field_dropdown.content
    local visible_widget_content = widgets.value_visible_dropdown.content
    local format_widget_content = widgets.value_format_dropdown.content

    local type_widget_selected_index = type_widget_content.selected_index
    local field_widget_selected_index = field_widget_content.selected_index
    local visible_widget_selected_index = visible_widget_content.selected_index
    local format_widget_selected_index = format_widget_content.selected_index

    local type_widget_option = type_widget_content.options[type_widget_selected_index]
    local field_widget_option = field_widget_content.options[field_widget_selected_index]
    local visible_widget_option = visible_widget_content.options[visible_widget_selected_index]
    local format_option = format_widget_content.options[format_widget_selected_index]

    local value_settings = {}

    value_settings.field_name = field_widget_option and field_widget_option.id
    value_settings.type = type_widget_option and type_widget_option.id
    value_settings.label = label_widget_content.input_text
    value_settings.visible = visible_widget_option and visible_widget_option.id
    value_settings.format = format_option and format_option.id
    value_settings.function_string = function_widget_content.input_text

    return value_settings
end
local function create_value_widget(self)
    local values_widgets = data.values.widgets
    local values_grid = data.values.grid
    local value_widget_template = {
        {   pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "text",
            style = {
                text_vertical_alignment = "center",
                text_horizontal_alignment = "left",
                font_type = font_name,
                font_size = font_size,
                text_color = Color.terminal_text_body(255, true),
                default_text_color = {
                    255,
                    255,
                    255,
                    255,
                },
                offset = {20,0,0}
            },
        },
        {   pass_type = "hotspot",
            style_id = "hotspot",
            content_id = "hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
            },
        },
        {   pass_type = "texture",
            style_id = "divider",
            value = "content/ui/materials/dividers/faded_line_01",
            style = {
                vertical_alignment = "bottom",
                horizontal_alignment = "left",
                color = Color.terminal_text_body(175, true),
                size = {sizes.edit_block[1],sizes.block_divider[2]}
            }
        },
        
        {   pass_type = "texture",
            style_id = "remove",
            value = "content/ui/materials/icons/system/settings/category_interface",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                color = Color.terminal_text_body(255, true),
                size = {sizes.edit_block[2]*0.1,sizes.edit_block[2]*0.1},
                offset = {-1*sizes.edit_block[2]*0.05,0,0},
            },
            visibility_function = remove_button_visibility_function_2
        },
        {   pass_type = "hotspot",
            style_id = "remove_hotspot",
            content_id = "remove_hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click,
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.edit_block[2]*0.1,sizes.edit_block[2]*0.1},
                offset = {-1*sizes.edit_block[2]*0.05,0,0},
            },
            visibility_function = remove_button_visibility_function_2
        },
        {   pass_type = "rect",
            style_id = "hover",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
                color = Color.citadel_death_guard_green(50, true)
            },
            visibility_function = function (content)
                return content.hotspot.is_selected or false
            end
        },
    }
    local value_widget_definition = UIWidget.create_definition(value_widget_template, "values_item", {text = "values_item"})
    local widget_index = #values_widgets+1
    local widget = self:_create_widget("value_widget_"..widget_index, value_widget_definition)
    widget.content.hotspot.pressed_callback = callback(value_widget_selected_callback, self, widget, #values_widgets+1)
    widget.content.remove_hotspot.pressed_callback = callback(remove_value_callback, self, widget, #values_widgets+1)

    values_widgets[widget_index] = widget
    values_grid:force_update_list_size()
    
    return widget
end
local function save_value_options_callback(self)
    local widgets_by_name = self._widgets_by_name
    local values_data = data.values
    local values_grid = values_data.grid
    local selected_grid_index = values_grid._selected_grid_index
    local values_widgets = values_data.widgets
    local widget

    if selected_grid_index then
        widget = values_grid._widgets[selected_grid_index]
    else
        widget = create_value_widget(self)
        selected_grid_index = #values_widgets
    end
    values_grid:select_grid_index(selected_grid_index)
    local value_settings = get_value_setting(self)
    widget.content.text = value_settings.label
    widget.content.value_settings = value_settings
    
    mod:notify("Value saved")
end
local function save_value_options_change_function(content,style)
    local value_settings = get_value_setting(instance)
    local disabled

    if not value_settings.label then
        disabled = true
    elseif not value_settings.type then
        disabled = true
    elseif not value_settings.field_name and not value_settings.function_string then
        disabled = true
    elseif type(value_settings.visible) ~= "boolean" then
        disabled = true
    elseif not value_settings.format then
        disabled = true
    else
        disabled = false
    end

    content.disabled = disabled

    local selected_grid_index = data.values.grid._selected_grid_index

    if selected_grid_index then
        content.parent.original_text = "Save value"
    else
        content.parent.original_text = "Add value"
    end

end
local function clear_value_options_callback(self)
    local values_data = data.values
    local values_grid = values_data.grid

    local selected_grid_index = values_grid._selected_grid_index

    if selected_grid_index then
        local value_widget = values_grid._widgets[selected_grid_index]
        if value_widget then
            value_widget.content.hotspot.is_selected = false
            values_grid._selected_grid_index = nil
        end
    end

    clear_value_options(self)

end
local function clear_value_options_change_function(content,style)
    local values_selected_grid_index = data.values.grid._selected_grid_index
    if values_selected_grid_index then
        content.disabled = false
    else
        content.disabled = true
    end
end
local function edit_value_options_callback(self)
end
local function edit_value_options_change_function(content,style)
end
local function get_definitions(self)
    local definitions = {
        scenegraph_definition = {
            screen = {
                scale = "fit",
                size = {
                    1920,
                    1080,
                },
            },
            anchor = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {0,0},
                position = anchor_position,
            },
            edit_block_1_1 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = sizes.edit_block,
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_settings_header = {
                parent = "edit_block_1_1",
                vertical_alignment = "top",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_settings_container_outer = {
                parent = "edit_block_1_1",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            report_settings_container_inner = {
                parent = "edit_block_1_1",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9, sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_name_header = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.25,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.05,
                    0,
                },
            },
            report_name_text_input = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.6,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.3,
                    sizes.edit_block[2]*0.05,
                    0,
                },
            },
            dataset_header = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.25,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.2275,
                    0,
                },
            },
            dataset_dropdown = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.6,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.3,
                    sizes.edit_block[2]*0.2275,
                    0,
                },
            },
            report_type_header = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.25,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.405,
                    0,
                },
            },
            report_type_dropdown = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.6,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.3,
                    sizes.edit_block[2]*0.405,
                    0,
                },
            },
            save_button = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.75,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.5825,
                    0,
                },
            },
            exit_button = {
                parent = "report_settings_container_inner",
                vertical_alignment = "top",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.75,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.76,
                    0,
                },
            },
            edit_block_1_2 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = sizes.edit_block,
                position = {
                    0,
                    sizes.edit_block[2],
                    0,
                },
            },
            filter_header = {
                parent = "edit_block_1_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            filter_block_outer = {
                parent = "edit_block_1_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            filter_block_inner = {
                parent = "filter_block_outer",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            edit_block_2 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*2},
                position = {
                    sizes.edit_block[1],
                    0,
                    0,
                },
            },
            fields_header = {
                parent = "edit_block_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            fields_block_outer = {
                parent = "edit_block_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*1.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            fields_block_inner = {
                parent = "fields_block_outer",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*1.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            fields_mask = {
                parent = "fields_block_inner",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*1.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            fields_scrollbar = {
                parent = "fields_mask",
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.block_scrollbar[1],sizes.edit_block[2]*1.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            fields_pivot = {
                parent = "fields_mask",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {0,0},
                position = {
                    0,
                    0,
                    0,
                },
            },
            fields_item = {
                parent = "fields_pivot",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {(sizes.edit_block[1]*0.9)-sizes.block_scrollbar[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            edit_block_3_1 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = sizes.edit_block,
                position = {
                    sizes.edit_block[1]*2,
                    0,
                    0,
                },
            },
            columns_header = {
                parent = "edit_block_3_1",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            columns_block_outer = {
                parent = "edit_block_3_1",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            columns_block_inner = {
                parent = "columns_block_outer",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            columns_mask = {
                parent = "columns_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            columns_scrollbar = {
                parent = "columns_mask",
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.block_scrollbar[1],sizes.edit_block[2]*0.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            columns_pivot = {
                parent = "columns_mask",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {0,0},
                position = {
                    0,
                    0,
                    0,
                },
            },
            columns_item = {
                parent = "columns_pivot",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {(sizes.edit_block[1]*0.9)-sizes.block_scrollbar[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            columns_add_button = {
                parent = "columns_mask",
                vertical_alignment = "bottom",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.75,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            edit_block_3_2 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = sizes.edit_block,
                position = {
                    sizes.edit_block[1]*2,
                    sizes.edit_block[2],
                    0,
                },
            },
            rows_header = {
                parent = "edit_block_3_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            rows_block_outer = {
                parent = "edit_block_3_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            rows_block_inner = {
                parent = "rows_block_outer",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            rows_mask = {
                parent = "rows_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            rows_scrollbar = {
                parent = "rows_mask",
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.block_scrollbar[1],sizes.edit_block[2]*0.71},
                position = {
                    0,
                    0,
                    0,
                },
            },
            rows_pivot = {
                parent = "rows_mask",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {0,0,0},
                position = {
                    0,
                    0,
                    0,
                },
            },
            rows_item = {
                parent = "rows_pivot",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {(sizes.edit_block[1]*0.9)-sizes.block_scrollbar[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            rows_add_button = {
                parent = "rows_mask",
                vertical_alignment = "bottom",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.75,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            edit_block_4_1 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = sizes.edit_block,
                position = {
                    sizes.edit_block[1]*3,
                    0,
                    0,
                },
            },
            values_header = {
                parent = "edit_block_4_1",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            values_block_outer = {
                parent = "edit_block_4_1",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            values_block_inner = {
                parent = "values_block_outer",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            values_mask = {
                parent = "values_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            values_scrollbar = {
                parent = "values_mask",
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.block_scrollbar[1],sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            values_pivot = {
                parent = "values_mask",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {0,0,0},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            values_item = {
                parent = "values_pivot",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {(sizes.edit_block[1]*0.9)-sizes.block_scrollbar[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            edit_block_4_2 = {
                parent = "anchor",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = sizes.edit_block,
                position = {
                    sizes.edit_block[1]*3,
                    sizes.edit_block[2],
                    0,
                },
            },
            value_options_header = {
                parent = "edit_block_4_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            value_options_block_outer = {
                parent = "edit_block_4_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            value_options_block_inner = {
                parent = "value_options_block_outer",
                vertical_alignment = "center",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.9,sizes.edit_block[2]*0.81},
                position = {
                    0,
                    0,
                    0,
                },
            },
            value_options = {
                parent = "edit_block_4_2",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1],sizes.edit_block[2]*0.9},
                position = {
                    0,
                    sizes.edit_block[2]*0.1,
                    0,
                },
            },
            value_label_header = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.225,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            value_label_text_input = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.675,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.225,
                    0,
                    0,
                },
            },
            value_type_header = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.225,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.12,
                    0,
                },
            },
            value_type_dropdown = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.675,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.225,
                    sizes.edit_block[2]*0.12,
                    0,
                },
            },
            value_field_header = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.225,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.24,
                    0,
                },
            },
            value_field_dropdown = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.675,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.225,
                    sizes.edit_block[2]*0.24,
                    0,
                },
            },
            value_function_header = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.225,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.24,
                    0,
                },
            },
            value_function_text_input = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.675,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.225,
                    sizes.edit_block[2]*0.24,
                    0,
                },
            },
            value_visible_header = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.225,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.36,
                    0,
                },
            },
            value_visible_dropdown = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.675,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.225,
                    sizes.edit_block[2]*0.36,
                    0,
                },
            },
            value_format_header = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.225,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.48,
                    0,
                },
            },
            value_format_dropdown = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "left",
                size = {sizes.edit_block[1]*0.675,sizes.edit_block[2]*0.1},
                position = {
                    sizes.edit_block[1]*0.225,
                    sizes.edit_block[2]*0.48,
                    0,
                },
            },

            value_save_button = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.75,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.60,
                    0,
                },
            },
            values_clear_button = {
                parent = "value_options_block_inner",
                vertical_alignment = "top",
                horizontal_alignment = "center",
                size = {sizes.edit_block[1]*0.75,sizes.edit_block[2]*0.1},
                position = {
                    0,
                    sizes.edit_block[2]*0.72,
                    0,
                },
            },
        },
        widget_definitions = {
            report_settings_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Report settings:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "report_settings_header"),
            report_settings_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_1_1"),
            report_name_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Report name:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "report_name_header"),
            report_name_text_input = create_custom_text_input_definition(self, "report_name_text_input"),
            dataset_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Dataset:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "dataset_header"),
            report_type_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Report type:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "report_type_header"),
            save_button = create_custom_button_definition(self, "save_button", "Save", callback(save_button_callback, self),save_button_change_function),
            exit_botton = create_custom_button_definition(self, "exit_button", "Main menu", callback(exit_button_callback, self)),
            filter_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_1_2"),
            filter_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Data filter:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "filter_header"),
            filter_text_input = UIWidget.create_definition(CustomMultiLineTextInput , "filter_block_inner"),
            fields_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_2"),
            fields_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Fields:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "fields_header"),
            fields_mask = UIWidget.create_definition({
                {
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur",
                    pass_type = "texture",
                    style = {
                        color = {
                            255,
                            255,
                            255,
                            255
                        },
                    }
                }
            }, "fields_mask"),
            fields_scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.metal_scrollbar, "fields_scrollbar"),
            columns_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_3_1"),
            columns_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Columns:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "columns_header"),
            columns_mask = UIWidget.create_definition({
                {
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur",
                    pass_type = "texture",
                    style = {
                        color = {
                            255,
                            255,
                            255,
                            255
                        },
                    }
                },
                {   pass_type = "hotspot",
                    style_id = "hotspot",
                    content_id = "hotspot",
                    content = {},
                    change_function = function (hotspot_content, style)
                        local content = hotspot_content.parent
            
                        if content.last_frame_left_pressed and not hotspot_content.on_pressed then
                            local columns_data = data.columns
                            local grid = columns_data.grid
                            local selected_grid_index = grid._selected_grid_index

                            if selected_grid_index then
                                local widget = grid._widgets[selected_grid_index]
                                widget.content.hotspot.is_selected = false
                                grid._selected_grid_index = nil
                            end
                        end
                        content.last_frame_left_pressed = input_service:get("left_pressed")
                    end
                },
            }, "columns_mask"),
            columns_scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.metal_scrollbar, "columns_scrollbar"),
            columns_add_button = create_custom_button_definition(self, "columns_add_button", "Add selected field", callback(add_column_callback, self),add_column_button_change_function),
            rows_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_3_2"),
            rows_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Rows:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "rows_header"),
            rows_mask = UIWidget.create_definition({
                {
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_2",
                    pass_type = "texture",
                    style = {
                        color = {
                            255,
                            255,
                            255,
                            255
                        },
                    }
                },
                {   pass_type = "hotspot",
                    style_id = "hotspot",
                    content_id = "hotspot",
                    content = {},
                    change_function = function (hotspot_content, style)
                        local content = hotspot_content.parent
            
                        if content.last_frame_left_pressed and not hotspot_content.on_pressed then
                            local rows_data = data.rows
                            local grid = rows_data.grid
                            local selected_grid_index = grid._selected_grid_index

                            if selected_grid_index then
                                local widget = grid._widgets[selected_grid_index]
                                widget.content.hotspot.is_selected = false
                                grid._selected_grid_index = nil
                            end
                        end
                        content.last_frame_left_pressed = input_service:get("left_pressed")
                    end
                },
            }, "rows_mask"),
            rows_scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.metal_scrollbar, "rows_scrollbar"),
            rows_add_button = create_custom_button_definition(self, "rows_add_button", "Add selected field", callback(add_row_callback, self),add_row_button_change_function),
            values_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_4_1"),
            values_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Values:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "values_header"),
            values_mask = UIWidget.create_definition({
                {
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur",
                    pass_type = "texture",
                    style = {
                        color = {
                            255,
                            255,
                            255,
                            255
                        },
                    }
                }
            }, "values_mask"),
            values_scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.metal_scrollbar, "values_scrollbar"),
            values_clear_button = create_custom_button_definition(self, "values_clear_button", "Clear selections", callback(clear_value_options_callback, self),clear_value_options_change_function),
            value_options_frame = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "frame",
                    value = "content/ui/materials/frames/hover",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size_addition  = frame_size_addition,
                        offset = {0,0,0}
                    },
                },
            }, "edit_block_4_2"),
            value_options_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Value options:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*1.5,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {sizes.edit_block[1]*0.9, sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "value_options_header"),
            value_label_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Label:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "value_label_header"),
            value_label_text_input = create_custom_text_input_definition(self,"value_label_text_input"),
            value_type_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Type:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "value_type_header"),
            value_field_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Field:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "value_field_header"),
            value_format_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Format:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "value_format_header"),
            value_visible_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Visible:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "value_visible_header"),
            value_function_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Function:",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "value_function_header"),
            value_function_text_input = create_custom_text_input_definition(self,"value_function_text_input"),
            value_save_button = create_custom_button_definition(self, "value_save_button", "Save value", callback(save_value_options_callback, self),save_value_options_change_function),
            -- test = UIWidget.create_definition({
            --     {   pass_type = "rect",
            --         style = {
            --             color = {255,255,255,255}
            --         },
            --     },
            -- }, "edit_block_1_1"),
        }
    }
    return definitions
end
local function create_dataset_options_array()
    local datasets = PDI.dataset_manager.registered_datasets
    local options_array = {}

    for dataset_name, dataset_template in pairs(datasets) do
        local option = {}
        option.id = dataset_name
        option.display_name = dataset_template.label or dataset_name
        options_array[#options_array+1] = option
    end
    return options_array
end
local function create_report_type_options_array()
    local options_array = {
        {id = "pivot_table",
        display_name = "Pivot table"}
    }
    return options_array
end
local function field_widget_selected_callback(self, widget)
    local current_grid_name = widget.content.current_grid_name
    local grid = data[current_grid_name].grid
    local widget_index = widget.content.current_grid_index
    local current_selected_index = grid:selected_grid_index()
    
    if widget_index == current_selected_index then
        return
    end

    grid:select_grid_index(widget_index)
    
end
local function clear_data_filter(self)
    local filter_text_input = self._widgets_by_name.filter_text_input
    filter_text_input.content.input_text = ""
    filter_text_input.content.caret_position = 1
    filter_text_input.content.force_caret_update = true 
end
local function dataset_selected_callback(self, dataset_name)
    for _, settings in pairs(data) do
        local widgets = settings.widgets
        if next(widgets) then
            local renderer = settings.renderer
            for index,widget in pairs(widgets) do
                UIWidget.destroy(renderer, widget)
                widgets[index] = nil
            end
            --settings.widgets = {}
        end
    end

    clear_data_filter(self)
    clear_value_options(self)

    local dataset_template = PDI.dataset_manager.get_dataset_template(dataset_name)
    local legend = dataset_template.legend
    local widgets = data.fields.widgets
    local grid = data.fields.grid
    local value_field_dropdown_options = {}
    local value_field_dropdown_options_by_id = {}
    local item_template = {
        {   pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "text",
            style = {
                text_vertical_alignment = "center",
                text_horizontal_alignment = "left",
                font_type = font_name,
                font_size = font_size,
                text_color = Color.terminal_text_body(255, true),
                default_text_color = {
                    255,
                    255,
                    255,
                    255,
                },
                offset = {20,0,0}
            },
        },
        {   pass_type = "hotspot",
            style_id = "hotspot",
            content_id = "hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
            },
        },
        {   pass_type = "texture",
            style_id = "divider",
            value = "content/ui/materials/dividers/faded_line_01",
            style = {
                vertical_alignment = "bottom",
                horizontal_alignment = "left",
                color = Color.terminal_text_body(175, true),
                size = {sizes.edit_block[1],sizes.block_divider[2]}
            }
        },
        {   pass_type = "rotated_texture",
            style_id = "down_arrow",
            value = "content/ui/materials/buttons/arrow_01",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                color = Color.terminal_text_body(255, true),
                size = {sizes.edit_block[2]*0.075,sizes.edit_block[2]*0.075},
                offset = {-2*sizes.edit_block[2]*0.075,0,0},
                angle = math.rad(-90),
            },
            visibility_function = down_button_visibility_function 
        },
        {   pass_type = "hotspot",
            style_id = "down_arrow_hotspot",
            content_id = "down_arrow_hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click,
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.edit_block[2]*0.075,sizes.edit_block[2]*0.075},
                offset = {-2*sizes.edit_block[2]*0.075,0,0},
            },
            visibility_function = down_button_visibility_function
        },
        {   pass_type = "rotated_texture",
            style_id = "up_arrow",
            value = "content/ui/materials/buttons/arrow_01",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                color = Color.terminal_text_body(255, true),
                size = {sizes.edit_block[2]*0.075,sizes.edit_block[2]*0.075},
                offset = {-3*sizes.edit_block[2]*0.075,0,0},
                angle = math.rad(90),
            },
            visibility_function = up_button_visibility_function
        },
        {   pass_type = "hotspot",
            style_id = "up_arrow_hotspot",
            content_id = "up_arrow_hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click,
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.edit_block[2]*0.075,sizes.edit_block[2]*0.075},
                offset = {-3*sizes.edit_block[2]*0.075,0,0},
            },
            visibility_function = up_button_visibility_function
        },
        {   pass_type = "texture",
            style_id = "remove",
            value = "content/ui/materials/icons/system/settings/category_interface",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                color = Color.terminal_text_body(255, true),
                size = {sizes.edit_block[2]*0.1,sizes.edit_block[2]*0.1},
                offset = {-1*sizes.edit_block[2]*0.05,0,0},
            },
            visibility_function = remove_button_visibility_function
        },
        {   pass_type = "hotspot",
            style_id = "remove_hotspot",
            content_id = "remove_hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click,
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.edit_block[2]*0.1,sizes.edit_block[2]*0.1},
                offset = {-1*sizes.edit_block[2]*0.05,0,0},
            },
            visibility_function = remove_button_visibility_function
        },
        {   pass_type = "rect",
            style_id = "hover",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
                color = Color.citadel_death_guard_green(50, true)
            },
            visibility_function = function (content)
                return content.hotspot.is_selected or false
            end
        },
    }
    for field_name, field_type in pairs(legend) do
        local widget_index = #widgets+1
        local display_text = field_name.." ("..field_type..")"
        local item_definition = UIWidget.create_definition(item_template, "fields_item", {text = display_text})
        local widget = self:_create_widget(field_name, item_definition)
        widget.content.hotspot.pressed_callback = callback(field_widget_selected_callback, self, widget)
        widget.content.remove_hotspot.pressed_callback = callback(remove_field_callback, self, widget)
        widget.content.up_arrow_hotspot.pressed_callback = callback(change_widget_index, widget, -1)
        widget.content.down_arrow_hotspot.pressed_callback = callback(change_widget_index, widget, 1)
        widgets[widget_index] = widget

        local value_field_dropdown_option = {}
        value_field_dropdown_option.id = field_name
        value_field_dropdown_option.display_name = field_name
        value_field_dropdown_options[#value_field_dropdown_options+1] = value_field_dropdown_option
        value_field_dropdown_options_by_id[field_name] = value_field_dropdown_option
    end

    table.sort(value_field_dropdown_options, function(v1,v2)return v1.id>v2.id end)

    sort_widgets(widgets)
    set_widgets_content(widgets,"fields")

    grid._selected_grid_index = nil
    grid._widgets = widgets
    grid._alignment_list = widgets

    grid:force_update_list_size()

    local dropdown_widget_visible = self._widgets[self.value_field_dropdown_widget_index].visible    
    
    self._widgets[self.value_field_dropdown_widget_index] = self._create_dropdown_widget(self, "value_field_dropdown", "value_field_dropdown", value_field_dropdown_options, 5)
    self._widgets[self.value_field_dropdown_widget_index].visible = dropdown_widget_visible
end
local function report_type_selected_callback (self, report_type)
end
local function create_grids(self)
    local scenegraph = self._ui_scenegraph
    local widgets_by_name = self._widgets_by_name
    for setting_name, setting in pairs(data) do
        local widgets = setting.widgets
        local mask_id = setting_name.."_mask"
        setting.grid = UIWidgetGrid:new(widgets, widgets, scenegraph, mask_id, "down")
        local scrollbar = widgets_by_name[setting_name.."_scrollbar"]
        local grid_pivot_id = setting_name.."_pivot"
        setting.grid:assign_scrollbar(scrollbar, grid_pivot_id, mask_id)
    end
end
local function create_dropdown_widgets(self)
    local dataset_options = create_dataset_options_array()
    self._widgets[#self._widgets+1] = self._create_dropdown_widget(self, "dataset_dropdown", "dataset_dropdown", dataset_options, 5, dataset_selected_callback)

    local report_type_options = create_report_type_options_array()
    local report_type_dropdown_widget = self._create_dropdown_widget(self, "report_type_dropdown", "report_type_dropdown", report_type_options, 5, report_type_selected_callback)
    self._widgets[#self._widgets+1] = report_type_dropdown_widget

    local value_field_dropdown_widget_index = #self._widgets+1
    self.value_field_dropdown_widget_index = value_field_dropdown_widget_index
    local value_field_dropdown_widget = self._create_dropdown_widget(self, "value_field_dropdown", "value_field_dropdown", {}, 1)
    self._widgets[value_field_dropdown_widget_index] = value_field_dropdown_widget

    local value_type_dropdown_widget = self._create_dropdown_widget(self, "value_type_dropdown", "value_type_dropdown", field_type_dropdown_options, 5)
    self._widgets[#self._widgets+1] = value_type_dropdown_widget
    local value_visible_dropdown_widget = self._create_dropdown_widget(self, "value_visible_dropdown", "value_visible_dropdown", value_visible_dropdown_options, 5)
    self._widgets[#self._widgets+1] = value_visible_dropdown_widget
    local value_format_dropdown_widget = self._create_dropdown_widget(self, "value_format_dropdown", "value_format_dropdown", value_format_dropdown_options, 5)
    self._widgets[#self._widgets+1] = value_format_dropdown_widget

    local widgets_by_name = self._widgets_by_name

    local value_field_header_widget = widgets_by_name.value_field_header
    local value_function_header_widget = widgets_by_name.value_function_header
    local value_function_text_input_widget = widgets_by_name.value_function_text_input

    value_field_dropdown_widget.content.disabled = true
    value_function_header_widget.visible = false
    value_function_text_input_widget.visible = false

    value_type_dropdown_widget.passes[#value_type_dropdown_widget.passes+1] = {
        data = {
          _parent_name = "value_field_dropdown"
        },
        pass_type = "logic",
        value_id = "conditional_logic",
        style_id = "conditional_logic",
      }

      value_type_dropdown_widget.content.conditional_logic = function(pass, ui_renderer, logic_style, content, position, size)
        local selected_index = value_type_dropdown_widget.content.selected_index
        local previous_selected_index = value_type_dropdown_widget.content._selected_index
        local widgets_by_name = self._widgets_by_name

        local value_field_dropdown_widget = widgets_by_name.value_field_dropdown

        if selected_index == previous_selected_index then
            return
        end
        if selected_index == 3 then
            value_field_dropdown_widget.content.selected_index = nil
            value_field_header_widget.visible = false
            value_field_dropdown_widget.visible = false
            value_function_header_widget.visible = true
            value_function_text_input_widget.visible = true
        elseif selected_index == 1 or selected_index == 2 then
            value_field_header_widget.visible = true
            value_field_dropdown_widget.visible = true
            value_field_dropdown_widget.content.disabled = false
            --value_field_dropdown_widget.content.selected_index = nil
            value_function_header_widget.visible = false
            value_function_text_input_widget.visible = false
        elseif not selected_index then
            value_field_dropdown_widget.content.disabled = true
            value_field_header_widget.visible = true
            value_field_dropdown_widget.visible = true
            value_function_header_widget.visible = false
            value_function_text_input_widget.visible = false
        end
        value_type_dropdown_widget.content._selected_index = selected_index
    end
end
local function load_template(self, template)
    local widgets = self._widgets_by_name
    local report_name_text_input = widgets.report_name_text_input
    local dataset_dropdown = widgets.dataset_dropdown
    local report_type_dropdown = widgets.report_type_dropdown
    local filter_text_input = widgets.filter_text_input

    report_name_text_input.content.input_text = template.name

    local dataset_option = dataset_dropdown.content.options_by_id[template.dataset_name]
    dataset_dropdown.content.selected_index = dataset_option.index

    dataset_selected_callback(self, template.dataset_name)

    local report_type_option = report_type_dropdown.content.options_by_id[template.report_type]
    report_type_dropdown.content.selected_index = report_type_option.index

    local filter_string = template.filters[1]

    filter_text_input.content.input_text = filter_string or ""
    filter_text_input.content.caret_position = 1
    filter_text_input.content.force_caret_update = true 

    local field_widgets = data.fields.widgets

    for index, column_name in ipairs(template.columns) do
        for index, widget in ipairs(field_widgets) do
            if widget.name == column_name then
                move_widget(widget, "columns")
                break
            end
        end
    end

    for index, row_name in ipairs(template.rows) do
        for index, widget in ipairs(field_widgets) do
            if widget.name == row_name then
                move_widget(widget, "rows")
                break
            end
        end
    end

    local value_widgets = data.values.widgets

    for index, value_settings in ipairs(template.values) do
        local widget = create_value_widget(self)
        widget.content.text = value_settings.label
        widget.content.value_settings = value_settings
    end

    -- local column_widgets = data.columns.widgets
    -- local rows_widgets = data.rows.widgets
    -- local value_widgets = data.values.widgets

    -- report_template.name = report_name_text_input.content.input_text
    -- report_template.label = report_name_text_input.content.input_text
    -- report_template.dataset_name = dataset_dropdown.content.options[dataset_dropdown.content.selected_index].id
    -- report_template.report_type = report_type_dropdown.content.options[report_type_dropdown.content.selected_index].id
    -- report_template.columns = {}
    -- report_template.rows = {}
    -- report_template.values = {}
    -- report_template.filters = {filter_text_input.content.input_text}
end

PdiEditViewElement.init = function (self, parent, draw_layer, start_scale, context)
    PDI = context.PDI
    view_manager = PDI.view_manager

    local settings = view_manager.settings
    sizes = settings.sizes
    font_name = settings.font_name
    font_size = settings.font_size

    offscreen_renderers = context.offscreen_renderers
    anchor_position = context.anchor_position
    instance = self

    data = {
        fields = {
            widgets = {},
            renderer = offscreen_renderers[1].ui_offscreen_renderer,
        },
        columns = {
            widgets = {},
            renderer = offscreen_renderers[1].ui_offscreen_renderer,
        },
        rows = {
            widgets = {},
            renderer = offscreen_renderers[2].ui_offscreen_renderer,
        },
        values = {
            widgets = {},
            renderer = offscreen_renderers[1].ui_offscreen_renderer,
        },
    }

    local definitions = get_definitions(self)
	PdiEditViewElement.super.init(self, parent, draw_layer, start_scale, definitions)

    create_grids(self)
    create_dropdown_widgets(self)

    local report_template = context.report_template

    if report_template then
        load_template(self, report_template)
    end

    for index, value in pairs(data) do
        value.grid:set_handle_grid_navigation(false)
    end
end
PdiEditViewElement.set_render_scale = function (self, scale)
	PdiEditViewElement.super.set_render_scale(self, scale)
end
PdiEditViewElement.on_resolution_modified = function (self, scale)
	PdiEditViewElement.super.on_resolution_modified(self, scale)
end
PdiEditViewElement.update = function (self, dt, t, input_service)
    local main_view_instance = view_manager.get_current_view_instance()
    if main_view_instance._elements["PdiPivotTableViewElement"] then
        main_view_instance:_remove_element("PdiPivotTableViewElement")
    end

    for _, value in pairs(data) do
        local grid  = value.grid
        if grid then
        value.grid:update(dt, t, input_service)
        end
    end
    return PdiEditViewElement.super.update(self, dt, t, input_service)
end
PdiEditViewElement.draw = function (self, dt, t, ui_renderer, render_settings, input_service)
    local ui_scenegraph = self._ui_scenegraph
    for _, settings in pairs(data) do
        local widgets = settings.widgets
        if next(widgets) then
            local renderer = settings.renderer
            UIRenderer.begin_pass(renderer, ui_scenegraph, input_service, dt, render_settings)
            for _,widget in pairs(widgets) do
                UIWidget.draw(widget, renderer)
            end
            UIRenderer.end_pass(renderer)
        end
    end
	PdiEditViewElement.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end
PdiEditViewElement._draw_widgets = function (self, dt, t, input_service, ui_renderer, render_settings)
	PdiEditViewElement.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end
PdiEditViewElement.on_exit = function(self)
	PdiEditViewElement.super.on_exit(self)
end

return PdiEditViewElement
