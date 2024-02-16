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

local PDI, view_manager, anchor_position, sizes, font_name, font_size, session_dropdown_widget, report_list, offscreen_renderers, in_game

PdiMainViewElement = class("PdiMainViewElement", "PdiBaseViewElement")

local function set_session_info_change_function(content,style)
    local main_view  = PDI.view_manager.main_view
    local selected_session_option_index = session_dropdown_widget.content.selected_index

    if not selected_session_option_index then
        return
    end

    local selected_session_option = session_dropdown_widget.content.options[selected_session_option_index]
    local selected_session_id = selected_session_option.id

    if selected_session_id == content.session_id then
        return
    end

    local session_info = PDI.data.save_data.sessions[selected_session_id]
    
    if not session_info then
        return
    end

    local session_info_text = ""

    local mission_name = Localize(session_info.mission.mission_name) or "n.a."
    local date = session_info.date or "n.a."
    local start_time = session_info.start_time or "n.a."
    local end_time = session_info.end_time or "n.a."
    local difficulty = session_info.difficulty or "n.a."
    local outcome = session_info.outcome or "n.a."
    local resumed = session_info.resumed and "true" or "false"
    local session_id = session_info.session_id or "n.a."

    session_info_text = "Mission: "..mission_name.."\n\nDate: "..date.."\n\nStart time: "..start_time.."\n\nEnd time: "..end_time.."\n\nDifficulty: "..difficulty.."\n\nOutcome: "..outcome.."\n\nResumed: "..resumed.."\n\nSession id: "..session_id
    
    content.text = session_info_text
    content.session_id = selected_session_id
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
            test_block = {
                parent = "report_header",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block,
                position = {
                    0,
                    0,
                    0,
                },
            },
            session_header = {
                parent = "anchor",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block_header,
                position = {
                    0,
                    0,
                    0,
                },
            },
            session_divider_top = {
                parent = "session_header",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block_divider,
                position = {
                    0,
                    sizes.block_header[2],
                    0,
                },
            },
            session_dropdown = {
                parent = "session_header",
                horizontal_alignment = "left",
                vertical_alignment = "bottom",
                size = {sizes.block_header[1],sizes.block_header[2]/2},
                position = {
                    0,
                    sizes.block_divider[2],
                    0,
                },
            },
            session_info = {
                parent = "session_divider_top",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {sizes.block_area[1], sizes.block_area[2]},
                position = {
                    0,
                    sizes.block_divider[2],
                    0,
                },
            },
            session_divider_bottom = {
                parent = "session_info",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block_divider,
                position = {
                    0,
                    sizes.block_area[2],
                    0,
                },
            },
            report_header = {
                parent = "session_divider_bottom",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block_header,
                position = {
                    0,
                    sizes.block_divider[2],
                    0,
                },
            },
            report_divider_top = {
                parent = "report_header",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block_divider,
                position = {
                    0,
                    sizes.block_header[2],
                    0,
                },
            },
            report_area = {
                parent = "report_divider_top",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {sizes.block_area[1],sizes.block_area[2]-sizes.block_item[2]},
                position = {
                    0,
                    sizes.block_divider[2],
                    0,
                },
            },
            report_scrollbar = {
                parent = "report_area",
                horizontal_alignment = "right",
                vertical_alignment = "center",
                size = {sizes.block_scrollbar[1], sizes.block_area[2]-sizes.block_item[2]},
                position = {
                    sizes.block_scrollbar[1],
                    0,
                    0,
                },
            },
            report_pivot = {
                parent = "report_area",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {0,0},
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_item = {
                parent = "report_pivot",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.block_item,
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_new_divider_top = {
                parent = "report_area",
                horizontal_alignment = "left",
                vertical_alignment = "bottom",
                size = sizes.block_divider,
                position = {
                    0,
                    sizes.block_divider[2],
                    0,
                },
            },
            report_new = {
                parent = "report_new_divider_top",
                horizontal_alignment = "left",
                vertical_alignment = "bottom",
                size = {sizes.block_item[1], sizes.block_item[2]},
                position = {
                    0,
                    sizes.block_item[2],
                    0,
                },
            },
        },
        widget_definitions = {
            session_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Session",
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
            }, "session_header"),
            session_divider_top = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        --size  = {sizes.header[1], sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "session_divider_top"),
            session_info = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Session info unavailable",
                    style = {
                        line_spacing = 0.9,
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "left",
                        offset = {
                            20,
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
                    change_function = set_session_info_change_function
                },
            }, "session_info"),
            session_divider_bottom = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        --size  = {sizes.header[1], sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "session_divider_bottom"),
            report_header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Report",
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
            }, "report_header"),
            report_divider_top = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        --size  = {sizes.header[1], sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "report_divider_top"),
            report_mask = UIWidget.create_definition({
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
            }, "report_area"),
            report_new_divider_top = UIWidget.create_definition({
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        --size  = {sizes.header[1], sizes.divider_hight},
                        offset = {0,0,0}
                    },
                },
            }, "report_new_divider_top"),
            report_new = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "+",
                    style = {
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        font_type = font_name,
                        font_size = font_size*2,
                        text_color = Color.terminal_text_body(255, true),
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                    --visibility_function = function() return not in_game end
                },
                {   
                    pass_type = "hotspot",
                    style_id = "hotspot",
                    content_id = "hotspot",
                    content = {
                        on_hover_sound = UISoundEvents.default_mouse_hover,
                        on_complete_sound = UISoundEvents.default_click,
                        pressed_callback = callback(PDI.view_manager.open_edit_view, self)
                    },
                    style = {
                        offset = {0,0,1},
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                    },
                    visibility_function = function() return not in_game end
                },
            }, "report_new"),
            report_scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.metal_scrollbar, "report_scrollbar"),      
        }        
    }
    return definitions
end
local function create_options_array()
    local sessions_index = PDI.data.save_data.sessions_index
    local sessions = PDI.data.save_data.sessions
    local options_array = {}

    for i = #sessions_index, 1, -1 do
        local session_id = sessions_index[i]
        local session = sessions[session_id]
        local mission = session and session.mission
        local option = {}
        if mission and mission.name ~= "tg_shooting_range" then
            option.id = session_id
            option.display_name = Localize(mission.mission_name)

            options_array[#options_array+1] = option
        end
    end
    return options_array
end
local function generate_report_list(self)
    local report_item_template = {
        {   pass_type = "text",
            style_id = "text",
            value_id = "text",
            value = "text",
            style = {
                text_vertical_alignment = "center",
                text_horizontal_alignment = "center",
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
            }
        },
        {   pass_type = "texture",
            style_id = "divider",
            value = "content/ui/materials/dividers/faded_line_01",
            style = {
                vertical_alignment = "bottom",
                horizontal_alignment = "center",
                color = Color.terminal_text_body(175, true),
                size = {sizes.block_item[1],sizes.block_divider[2]}
            }
        },
        {   pass_type = "texture",
            style_id = "edit",
            value = "content/ui/materials/icons/system/settings/category_gameplay",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                color = Color.terminal_text_body(255, true),
                size = {sizes.block_item[2]*0.9,sizes.block_item[2]*0.9},
                offset = {-10,0,0},
            },
            visibility_function = function (content)
                return content.hotspot.is_selected and not in_game
            end  
        },
        {   pass_type = "hotspot",
            style_id = "edit_hotspot",
            content_id = "edit_hotspot",
            content = {
                on_hover_sound = UISoundEvents.default_mouse_hover,
                on_complete_sound = UISoundEvents.default_click,
            },
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "right",
                size = {sizes.block_item[2]*0.9,sizes.block_item[2]*0.9},
                offset = {-10,0,1},
            },
            visibility_function = function (content)
                return content.parent.hotspot.is_selected and not in_game
            end  
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
    local reports = PDI.report_manager.registered_reports
    report_list = {
        widgets = {}
    }
    report_list.renderer = offscreen_renderers[1].ui_offscreen_renderer

    local widgets_table = report_list.widgets
    local callback_function = PDI.view_manager.report_selected_callback

    local sorted_report_array = {}

    for _, report in pairs(reports) do
        sorted_report_array[#sorted_report_array+1] = report
    end

    table.sort(sorted_report_array,function(v1,v2)return v1.name < v2.name end)

    for _, report in pairs(sorted_report_array) do
        local report_name = report.name
        local widget_index = #widgets_table+1
        local item_definition = UIWidget.create_definition(report_item_template, "report_item", {text = report.label})
        local widget = self:_create_widget(report_name, item_definition)
        widget.content.hotspot.pressed_callback = callback(callback_function, self, report_list, widget_index, report_name)
        widget.content.edit_hotspot.pressed_callback = callback(PDI.view_manager.open_edit_view, self, report)
        widget.content.size = sizes.block_item
        
        widget.report_template = report
        widgets_table[widget_index] = widget
    end

    local scenegraph = self._ui_scenegraph
    report_list.grid = UIWidgetGrid:new(widgets_table, widgets_table, scenegraph, "report_area", "down")
    local grid = report_list.grid
    local scrollbar = self._widgets_by_name.report_scrollbar
    grid:assign_scrollbar(scrollbar, "report_pivot", "report_area")

    local selected_report_name = view_manager.get_selected_report_name()
    local selected_report_index
    if selected_report_name then
        for index, widget in ipairs(widgets_table) do
            if widget.name == selected_report_name then
                selected_report_index = index
                break
            end
        end
        local scroll_percent = grid:get_scrollbar_percentage_by_index(selected_report_index or 1)
        grid:select_grid_index(selected_report_index or 1, scroll_percent, true)
    else
        grid:select_grid_index(1)
        view_manager.set_selected_report_name(widgets_table[1].report_template.name)
    end
end
local function set_session_dropdown_custom_style(self, widget)
    local size = {sizes.block_header[1],sizes.block_header[2]/2}
    widget.style.style_id_4.visible = false
    widget.style.background.visible = false
    widget.style.frame.size[2] = size[2]*2
    widget.style.frame.offset = {0,-1*size[2],0}
    widget.style.hotspot.size = {size[1],size[2]*2,1}
    widget.style.hotspot.offset = {0,-1*size[2],0}
    widget.style.text.visible = false
    widget.style.line.offset = {-10,-0.5*size[2],0}
    widget.style.fill.offset = {-10,-0.5*size[2],0}
    widget.passes[7].change_function = nil
    widget.passes[7].visibility_function = function(content)
        return content.hotspot.is_hover
    end
end

PdiMainViewElement.init = function (self, parent, draw_layer, start_scale, context)
    PDI = context.PDI
    view_manager = PDI.view_manager

    local settings = view_manager.settings
    sizes = settings.sizes
    font_name = settings.font_name
    font_size = settings.font_size

    offscreen_renderers = context.offscreen_renderers
    anchor_position = context.anchor_position

    in_game = PDI.utilities.in_game()

    local definitions = get_definitions(self)
	PdiMainViewElement.super.init(self, parent, draw_layer, start_scale, definitions)

    generate_report_list(self)

    if in_game then
        local session = PDI.data.session_data
        local session_id = session.info.session_id
       
        local options_array = {
            {
            id = session_id,
            display_name = Localize(session.info.mission.mission_name)
            }
        }
        session_dropdown_widget = self._create_dropdown_widget(self, "sessions_dropdown_widget", "session_dropdown", options_array, 8)
        set_session_dropdown_custom_style(self, session_dropdown_widget)
        self._widgets[#self._widgets+1] = session_dropdown_widget
        session_dropdown_widget.content.selected_index = 1
        session_dropdown_widget.content.disabled = true
        session_dropdown_widget.content.hotspot.disabled = true
        session_dropdown_widget.style.line.visible = false
        session_dropdown_widget.style.fill.visible = false

        view_manager.init_data_in_game(self, session_id)

        self._widgets_by_name.report_new.style.text.text_color = {200,100,110,100}
    else
        local options_array = create_options_array()
        local session_selected_callback = view_manager.session_selected_callback
        session_dropdown_widget = self._create_dropdown_widget(self, "sessions_dropdown_widget", "session_dropdown", options_array, 8, session_selected_callback)
        self._widgets[#self._widgets+1] = session_dropdown_widget
        if #options_array > 0 then
            local selected_session_id = view_manager.get_selected_session_id()
            local selected_session_index
            if selected_session_id then
                for index, option in ipairs(options_array) do
                    if option.id == selected_session_id then
                        selected_session_index = index
                        break
                    end
                end
            end
            selected_session_index = selected_session_index or 1
            selected_session_id = selected_session_id or options_array[1].id
            session_dropdown_widget.content.selected_index = selected_session_index
            view_manager.session_selected_callback(self, selected_session_id)
        end
        set_session_dropdown_custom_style(self, session_dropdown_widget)
    end
end
PdiMainViewElement.set_render_scale = function (self, scale)
	PdiMainViewElement.super.set_render_scale(self, scale)
end
PdiMainViewElement.on_resolution_modified = function (self, scale)
	PdiMainViewElement.super.on_resolution_modified(self, scale)
end
PdiMainViewElement.update = function (self, dt, t, input_service)
    local grid  = report_list.grid
    grid:update(dt, t, input_service)
    return PdiMainViewElement.super.update(self, dt, t, input_service)
end
PdiMainViewElement.draw = function (self, dt, t, ui_renderer, render_settings, input_service)
    local report_widgets = report_list.widgets
    local renderer = report_list.renderer
    local ui_scenegraph = self._ui_scenegraph
    if next(report_widgets) then
        
        UIRenderer.begin_pass(renderer, ui_scenegraph, input_service, dt, render_settings)
        for _,widget in pairs(report_widgets) do
            UIWidget.draw(widget, renderer)
        end
        UIRenderer.end_pass(renderer)
    end

	PdiMainViewElement.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end
PdiMainViewElement._draw_widgets = function (self, dt, t, input_service, ui_renderer, render_settings)
    --UIWidget.draw(sessions_dropdown_widget, ui_renderer)

	PdiMainViewElement.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end
PdiMainViewElement.on_exit = function(self)
	PdiMainViewElement.super.on_exit(self)
end

return PdiMainViewElement
