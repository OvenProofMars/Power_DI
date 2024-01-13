local ScriptWorld = require("scripts/foundation/utilities/script_world")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local DropdownPassTemplates = require("scripts/ui/pass_templates/dropdown_pass_templates")

PdiBaseView = class("PdiBaseView", "BaseView")

PdiBaseView._generate_ui_offscreen_renderers = function(self, number_of_renderers)
    if not number_of_renderers then
        number_of_renderers = 1
    end
    if number_of_renderers > 3 then
        error("no more than 3 offscreen renderers are supported")
    else
        local offscreen_renderers = {}
        local ui_manager = Managers.ui
        local class_name = self.__class_name
        local timer_name = "ui"
        local world_layer = 1
        local view_name = self.view_name

        for i = 1,number_of_renderers,1 do
            local offscreen_renderer = {}
            local world_name = class_name .. "_ui_offscreen_world_"..i
            local world = ui_manager:create_world(world_name, world_layer, timer_name, view_name)
            offscreen_renderer.world = world
            local viewport_name = class_name .. "_ui_offscreen_world_viewport_"..i
            offscreen_renderer.viewport_name = viewport_name
            local viewport_type
            if i == 1 then 
                viewport_type = "overlay_offscreen"
            else
                viewport_type = "overlay_offscreen_" .. i
            end
            local viewport = ui_manager:create_viewport(world, viewport_name, viewport_type, 1)
            offscreen_renderer.viewport = viewport
            local ui_offscreen_renderer_name = class_name .. "_ui_offscreen_renderer_"..i
            offscreen_renderer.ui_offscreen_renderer_name = ui_offscreen_renderer_name
            offscreen_renderer.ui_offscreen_renderer = ui_manager:create_renderer(ui_offscreen_renderer_name, world)
            offscreen_renderers[#offscreen_renderers+1] = offscreen_renderer
        end
        self.ui_offscreen_renderers = offscreen_renderers
    end
end
PdiBaseView._destroy_ui_offscreen_renderers = function(self)
    local offscreen_renderers = self.ui_offscreen_renderers
    for index, offscreen_renderer in ipairs(offscreen_renderers) do
        local world = offscreen_renderer.world
        offscreen_renderer.ui_offscreen_renderer = nil
        Managers.ui:destroy_renderer(offscreen_renderer.ui_offscreen_renderer_name)
        ScriptWorld.destroy_viewport(world, offscreen_renderer.viewport_name)
        Managers.ui:destroy_world(world)
        offscreen_renderer.world = nil
        offscreen_renderer.viewport = nil
    end
    self.ui_offscreen_renderers = nil
end
PdiBaseView._create_dropdown_widget = function(self, widget_name, scenegraph_id, options, max_visible_options, on_changed_callback, nothing_selected_text)
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

    local size = self._ui_scenegraph[scenegraph_id].size
    local num_options = #options
    local num_visible_options = math.min(num_options, max_visible_options)
    local widget_definition = UIWidget.create_definition(DropdownPassTemplates.settings_dropdown(size[1], size[2], size[1], num_visible_options, true), scenegraph_id, nil, size)

    widget_definition.passes[#widget_definition.passes+1] = {
        pass_type = "logic",
        value_id = "update_logic",
        style_id = "update_logic"
    }

    widget_definition.content.update_logic = function(pass, ui_renderer, logic_style, content, position, size) end
    widget_definition.style.update_logic = {}

    local widget = self:_create_widget(widget_name, widget_definition)
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
        local hotspot_content = content.hotspot or (content.parent and content.parent.hotspot)
        if not hotspot_content.not_first_frame then
            hotspot_content.not_first_frame = true
            return true
        end
        if not self.focussed_hotspot then
            return true
        else
            return hotspot_content == self.focussed_hotspot
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

        if content.hotspot.is_selected then
            self.focussed_hotspot = content.hotspot
        elseif self.focussed_hotspot == content.hotspot then
            self.focussed_hotspot = nil
        end

        if entry.disabled then
            return
        end

        local input_service = Managers.input:get_input_service("View")
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

                    on_changed_callback(self, option.id)
                end
            end
        end
    end

    content.update_logic = update_logic
    return widget
end
return PdiBaseView