local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

--local MasterItems = require("scripts/backend/master_items")

local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")

local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

local UIRenderer = mod:original_require("scripts/managers/ui/ui_renderer")
local ui_renderer_instance = Managers.ui:ui_constant_elements():ui_renderer()

local ScrollbarPassTemplates = require("scripts/ui/pass_templates/scrollbar_pass_templates")

local level_offset_ratio = 20/1024
local font_size_ratio = 18/1024
local font_name = "proxima_nova_bold"

local PDI, view_manager, anchor_position, sizes, font_name, font_size, offscreen_renderers

local level_offset 
local font_size

local background_visibility = false

local packages_array = {
    "packages/ui/views/crafting_view/crafting_view",
    "packages/ui/views/news_view/news_view",
    "packages/ui/views/achievements_view/achievements_view",
}
local packages_loaded = false

local debug = false

local data

PdiPivotTableViewElement = class("PdiPivotTableViewElement", "PdiBaseViewElement")

local function get_text_size(input_text, font_name, font_size)
    return UIRenderer.text_size(ui_renderer_instance, input_text, font_name, font_size)
end
local function get_max_font_size(input_text, font_name, max_width)
    local output_font_size = font_size*1.5
    local text_size = UIRenderer.text_size(ui_renderer_instance, input_text, font_name, output_font_size)
    while text_size > max_width do
        output_font_size = output_font_size - 0.1
        text_size = UIRenderer.text_size(ui_renderer_instance, input_text, font_name, output_font_size)
    end
    return output_font_size
end
local function create_report_size_table(self, report, report_size, number_of_columns, level_offset, font_name, font_size)

    local function get_count_and_max_level(input_table, level)
        local max_count = #input_table
        local max_level = 1
        local max_width = 0
        level = level or 1
        for _, child_table in ipairs(input_table) do
            local current_level = level
            local indent_width = level_offset * current_level
            local text_width = get_text_size(child_table.name, font_name, font_size*1.5)
            local total_width = indent_width + text_width

            max_width = math.max(max_width, total_width)

            local children = child_table.children
            if children then
                local children_max_count, children_max_level, children_max_width = get_count_and_max_level(children, current_level + 1)
                max_count = max_count + children_max_count
                max_level = math.max(current_level, children_max_level)
                max_width = math.max(max_width, children_max_width)
            end            
        end
        return max_count, max_level, max_width
    end

    local max_row_count, max_row_level, max_row_width

    if report.rows and next(report.rows) then
        max_row_count, max_row_level, max_row_width = get_count_and_max_level(report.rows)
        local label_size = get_text_size(report.template.label, font_name, font_size*1.5)
        local min_width = label_size+100
        max_row_width = math.max(max_row_width,min_width)
        max_row_width = math.min(max_row_width, report_size[1]*0.6)
    else
        max_row_count, max_row_level, max_row_width = 1,1,250
    end

    local max_column_count, max_column_level, max_column_width

    if report.columns and next(report.columns) then
        max_column_count, max_column_level, max_column_width = get_count_and_max_level(report.columns)
    else
        max_column_count, max_column_level, max_column_width = 1,1,100
    end

    local unit_size = (report_size[1] - (max_row_width*1.1)) / ((number_of_columns*4)+2.5)

    local column_width = (unit_size * 16)/max_column_count
    local column_hight = report_size[2]*0.1

    local row_width = max_row_width
    local row_hight = sizes.block[1]*0.1

    local column_and_value_mask_width = column_width * number_of_columns
    local column_and_value_pivot_width = column_width * max_column_count
    
    local row_and_value_pivot_length = row_hight * max_row_count
    local row_and_value_mask_length = report_size[2] - column_hight

    local report_size_table = {
        unit_size = unit_size,
        report_size = report_size,
        background_size = {report_size[1]*1.05, report_size[2]*1.05},
        column_item_size = {column_width, column_hight},
        column_count = max_column_count,
        column_max_level = max_column_level,
        column_max_text_size = max_column_width,
        column_mask_size = {column_and_value_mask_width, column_hight},
        column_pivot_size = {column_and_value_pivot_width, column_hight},
        row_item_size = {row_width, row_hight},
        row_count = max_row_count,
        row_max_level = max_row_level,
        row_max_text_size = max_row_width,
        row_mask_size = {row_width, row_and_value_mask_length},
        row_pivot_size = {row_width, row_and_value_pivot_length},
        value_item_size = {column_width, row_hight},
        value_mask_size = {column_and_value_mask_width, row_and_value_mask_length},
        value_pivot_size = {column_and_value_pivot_width, row_and_value_mask_length},
        column_sidebar_size = {column_hight*0.5, column_hight},
        arrow_size = {column_hight*0.25,column_hight*0.25},
        value_sidebar_size = {column_hight*0.5, row_and_value_mask_length}
    }

    return report_size_table
end 
local function horizontal_scroll(self, direction)
    local offset = self.sizes.column_item_size[1] * direction
    self._ui_scenegraph.value_pivot.position[1] = self._ui_scenegraph.value_pivot.position[1] - offset
    self._ui_scenegraph.column_pivot.position[1] = self._ui_scenegraph.column_pivot.position[1] - offset
    self.horizontal_scroll_index = (self.horizontal_scroll_index or 0) + direction
    UIScenegraph.update_scenegraph(self._ui_scenegraph, self._render_scale)
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
            report_anchor = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {1,1},
                position = anchor_position,
            },
            report = {
                parent = "report_anchor",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.report_size,
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_title = {
                parent = "report",
                horizontal_alignment = "top",
                vertical_alignment = "left",
                size = {self.sizes.row_item_size[1],self.sizes.column_item_size[2]},
                position = {
                    0,
                    0,
                    0,
                },
            },
            report_divider = {
                parent = "report_title",
                horizontal_alignment = "left",
                vertical_alignment = "bottom",
                size = {self.sizes.report_size[1], sizes.divider_hight},
                position = {
                    0,
                    sizes.divider_hight,
                    0,
                },
            },
            report_background = {
                parent = "report",
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = self.sizes.background_size,
                position = {
                    0,
                    0,
                    -1,
                },
            },
            row_mask = {
                parent = "report_divider",
                horizontal_alignment = "left",
                vertical_alignment = "bottom",
                size = self.sizes.row_mask_size,
                position = {
                    0,
                    self.sizes.row_mask_size[2],
                    0,
                },
            },
            row_pivot = {
                parent = "row_mask",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.row_pivot_size,
                position = {
                    0,
                    0,
                    0,
                },
            },
            row_item = {
                parent = "row_pivot",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.row_item_size,
                position = {
                    0,
                    0,
                    1,
                },
            },
            row_item_collapsed = {
                parent = "row_pivot",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {self.sizes.row_item_size[1],0},
                position = {
                    0,
                    0,
                    1,
                },
            },
            value_mask = {
                parent = "row_mask",
                horizontal_alignment = "right",
                vertical_alignment = "center",
                size = {self.sizes.value_mask_size[1]+0.1,self.sizes.value_mask_size[2]+0.1},
                position = {
                    self.sizes.value_mask_size[1],
                    0,
                    0,
                },
            },
            value_area = {
                parent = "value_mask",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {self.sizes.value_pivot_size[1]+0.1,self.sizes.value_pivot_size[2]+0.1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            value_sidebar = {
                parent = "value_mask",
                horizontal_alignment = "right",
                vertical_alignment = "center",
                size = self.sizes.value_sidebar_size,
                position = {
                    self.sizes.value_sidebar_size[1],
                    0,
                    0,
                },
            },
            scrollbar = {
                parent = "value_sidebar",
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = {10,self.sizes.value_sidebar_size[2]*0.95},
                position = {
                    0,
                    0,
                    0,
                },
            },
            value_pivot = {
                parent = "value_mask",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.value_pivot_size,
                position = {
                    0,
                    0,
                    0,
                },
            },
            value_item = {
                parent = "value_pivot",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.value_item_size,
                position = {
                    0,
                    0,
                    1,
                },
            },
            value_item_collapsed = {
                parent = "value_pivot",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {self.sizes.value_item_size[1],0},
                position = {
                    0,
                    0,
                    1,
                },
            },
            column_mask = {
                parent = "report_title",
                horizontal_alignment = "right",
                vertical_alignment = "center",
                size = self.sizes.column_mask_size,
                position = {
                    self.sizes.column_mask_size[1],
                    0,
                    0,
                },
            },
            column_sidebar_left = {
                parent = "column_mask",
                horizontal_alignment = "left",
                vertical_alignment = "center",
                size = self.sizes.column_sidebar_size,
                position = {
                    self.sizes.column_sidebar_size[1]*-1,
                    0,
                    0,
                },
            },
            column_sidebar_right = {
                parent = "column_mask",
                horizontal_alignment = "right",
                vertical_alignment = "center",
                size = self.sizes.column_sidebar_size,
                position = {
                    self.sizes.column_sidebar_size[1],
                    0,
                    0,
                },
            },
            column_pivot = {
                parent = "column_mask",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.column_pivot_size,
                position = {
                    0,
                    0,
                    0,
                },
            },
            column_item = {
                parent = "column_pivot",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = self.sizes.column_item_size,
                position = {
                    0,
                    0,
                    1,
                },
            },
        },
        widget_definitions = {
            column_right_arrow = UIWidget.create_definition({
                {
                    --value = "content/ui/materials/icons/system/page_arrow",
                    value = "content/ui/materials/buttons/arrow_01",
                    pass_type = "texture",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(255, true),
                        --angle = math.rad(180),
                        size = self.sizes.arrow_size
                    },
                    visibility_function = function (content)
                        return self.sizes.column_count > 4 and (self.horizontal_scroll_index or 0) < (self.sizes.column_count-4)
                    end
                },
                {   pass_type = "hotspot",
                    style_id = "hotspot",
                    content_id = "hotspot",
                    content = {
                        pressed_callback = callback(horizontal_scroll, self, 1),
                        on_hover_sound = UISoundEvents.default_mouse_hover,
                        on_complete_sound = UISoundEvents.default_click
                    },
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                    },
                    visibility_function = function (content)
                        return self.sizes.column_count > 4 and (self.horizontal_scroll_index or 0) < (self.sizes.column_count-4)
                    end
                },
            }, "column_sidebar_right"),
            column_left_arrow = UIWidget.create_definition({
                {
                    --value = "content/ui/materials/icons/system/page_arrow",
                    value = "content/ui/materials/buttons/arrow_01",
                    pass_type = "rotated_texture",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(255, true),
                        angle = math.rad(180),
                        size = self.sizes.arrow_size
                    },
                    visibility_function = function (content)
                        return self.sizes.column_count > 4 and (self.horizontal_scroll_index or 0) > 0
                    end
                },
                {   pass_type = "hotspot",
                style_id = "hotspot",
                content_id = "hotspot",
                content = {
                    pressed_callback = callback(horizontal_scroll, self, -1),
                    on_hover_sound = UISoundEvents.default_mouse_hover,
                    on_complete_sound = UISoundEvents.default_click
                },
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "center",
                },
                visibility_function = function (content)
                    return self.sizes.column_count > 4 and (self.horizontal_scroll_index or 0) > 0
                end
            },
            }, "column_sidebar_left"),
            report_title = UIWidget.create_definition({
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
                {   pass_type = "texture",
                    style_id = "divider",
                    value = "content/ui/materials/dividers/faded_line_01",
                    style = {
                        vertical_alignment = "bottom",
                        horizontal_alignment = "center",
                        color = Color.terminal_text_body(175, true),
                        size  = {self.sizes.row_item_size[1], sizes.divider_hight},
                        offset = {0,sizes.divider_hight,0}
                    },
                    visibility_function = function (content)
                        return not background_visibility
                    end
                },
            }, "report_title"),
            report_background = UIWidget.create_definition({
                {   pass_type = "texture",
                    value = "content/ui/materials/backgrounds/terminal_basic",
                    style = {
                        scale_to_material = true,
                        color = Color.terminal_grid_background_gradient(255, true),
                        size_addition = {
                            0,
                            0
                        },
                        offset = {
                            0,
                            0,
                            -1
                        }
                    },
                    visibility_function = function (content)
                        return background_visibility
                    end
                },
                {   pass_type = "rect",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {
                            255,
                            0,
                            5,
                            0,
                        },
                        size = {self.sizes.report_size[1]*1.03, self.sizes.report_size[2]*1.025},
                        offset = {
                            0,
                            0,
                            -10
                        }
                    },
                    visibility_function = function (content)
                        return background_visibility
                    end
                },
                {   pass_type = "texture",
                value = "content/ui/materials/dividers/horizontal_frame_big_upper",
                style = {
                    vertical_alignment = "top",
                    horizontal_alignment = "center",
                    size = {self.sizes.report_size[1]*1.03, self.sizes.unit_size*1.5},
                    offset = {
                        0,self.sizes.unit_size*-0.4,5
                    }
                },
                visibility_function = function (content)
                    return background_visibility
                end
                },
                {   pass_type = "texture",
                value = "content/ui/materials/dividers/horizontal_frame_big_lower",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "center",
                    size = {self.sizes.report_size[1]*1.03, self.sizes.unit_size*1.5},
                    offset = {
                        0,self.sizes.unit_size*0.4,5
                    }
                },
                visibility_function = function (content)
                    return background_visibility
                end
                },
                {   pass_type = "texture",
                value = "content/ui/materials/effects/terminal_header_glow",
                style = {
                        scale_to_material = true,
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        color = {
                            150,
                            50,
                            75,
                            50,
                        },
                        size = {math.max(self.sizes.report_size[1], self.sizes.report_size[2]), math.min(self.sizes.report_size[1], self.sizes.report_size[2])},
                        offset = {
                            0,
                            0,
                            -1
                        }
                    },
                visibility_function = function (content)
                    return background_visibility
                end
                },
            --     {   pass_type = "texture",
            --     value = "content/ui/materials/dividers/skull_rendered_center_03_addon",
            --     style = {
            --         vertical_alignment = "bottom",
            --         horizontal_alignment = "center",
            --         size = {self.sizes.unit_size*9,self.sizes.unit_size*1.5},
            --         offset = {
            --             0,
            --             self.sizes.unit_size*0.75,
            --             5
            --         }
            --     }
            -- }
            }, "report_background"),
            scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.metal_scrollbar, "scrollbar"),
            row_mask = UIWidget.create_definition({
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
            }, "row_mask"),
            value_mask = UIWidget.create_definition({
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
                        size_addition = {
                            0,
                            0
                        },
                        offset = {
                            0,
                            0,
                            0,
                        },
                    }
                }
            }, "value_mask"),
            column_mask = UIWidget.create_definition({
                {
                    value = "content/ui/materials/offscreen_masks/ui_overlay_offscreen_straight_blur_viewport_3",
                    pass_type = "texture",
                    style = {
                        color = {
                            255,
                            255,
                            255,
                            255
                        },
                        size_addition = {0,3*sizes.divider_hight,0},
                        offset = {0,3*sizes.divider_hight,0},
                    }
                }
            }, "column_mask"),
            row_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        255,
                        0,
                        0
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end
                }
            }, "row_mask"),
            row_item_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        200,
                        255,
                        0,
                        0
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end
                }
            }, "row_item"),
            value_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        0,
                        255,
                        0
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "value_mask"),
            value_item_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        200,
                        0,
                        255,
                        0
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "value_item"),
            value_sidebar_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        255,
                        0,
                        255
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "value_sidebar"),
            column_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        0,
                        0,
                        255
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "column_mask"),
            column_item_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        200,
                        0,
                        0,
                        255
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "column_item"),
            column_sidebar_left_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        0,
                        255,
                        255
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "column_sidebar_left"),
            column_sidebar_right_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        0,
                        255,
                        255
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "column_sidebar_right"),
            background_area_test = UIWidget.create_definition({
                {	pass_type = "rect",
                    style = {
                    color = {
                        150,
                        100,
                        100,
                        100
                    },
                    },
                    visibility_function = function (content)
                        return debug
                    end,
                }
            }, "report_background"),
    },
        
    }
    return definitions
end
local function get_item_templates(self)
    local item_templates = {
        row = {
            {   pass_type = "text",
                style_id = "text",
                value_id = "text",
                value = "text",
                style = {
                    text_vertical_alignment = "center",
                    text_horizontal_alignment = "left",
                    offset = {
                        0,
                        0,
                        0
                    },
                    size_addition = {1000,0},
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
                    horizontal_alignment = "left",
                    size_addition = {self.sizes.value_mask_size[1],0}
                }
            },
            {   pass_type = "texture",
                style_id = "divider",
                value = "content/ui/materials/dividers/faded_line_01",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "center",
                    color = Color.terminal_text_body(175, true),
                }
            },
            {   pass_type = "circle",
                style_id = "light_off",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "left",
                    color = {200,100,100,100},
                    size = {
                        1,
                        1
                    },
                },
                visibility_function = function (content)
                    local logic = content.logic
                    return not logic.expanded and logic.child_row_widgets
                end
            },
            {   pass_type = "texture",
                style_id = "light_on",
                value_id = "light_on",
                value = "content/ui/materials/symbols/new_item_indicator",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "left",
                    color = Color.ui_terminal(255, true)
                },
                visibility_function = function (content)
                    local logic = content.logic
                    return logic.expanded and logic.child_row_widgets
                end
            },
            {   pass_type = "rect",
                style_id = "hover",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "center",
                    color = Color.citadel_death_guard_green(50, true)
                },
                visibility_function = function (content, style)
                    return content.hotspot.is_hover or false
                end
            },
            {   pass_type = "logic",
                content_id = "logic",
                value_id = "logic",
                value = function (pass, ui_renderer, ui_style, content, position, size)
                end,
                content = {
                    expanded = false
                }

        },
        },
        value = {
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
            {   pass_type = "texture",
            style_id = "divider",
            value = "content/ui/materials/dividers/faded_line_01",
            style = {
                vertical_alignment = "bottom",
                horizontal_alignment = "center",
                color = Color.terminal_text_body(175, true),
                size = {self.sizes.value_item_size[1], sizes.divider_hight}
            }
            },
            {   pass_type = "rect",
            style_id = "hover",
            style = {
                vertical_alignment = "center",
                horizontal_alignment = "center",
                color = Color.citadel_death_guard_green(50, true)
            },
            visibility_function = function (content)
                return content.parent_row_widget.content.hotspot.is_hover or false
            end
            },
        },
        column = {
            {
                style_id = "text",
                pass_type = "text",
                value_id = "text",
                value = "text",
                style = {
                    text_vertical_alignment = "center",
                    text_horizontal_alignment = "center",
                    offset = {
                        0,
                        2,
                        2
                    },
                    font_type = font_name,
                    font_size = font_size * 1.5,
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
                    visible = false,
                }
            },
            {   pass_type = "texture",
                style_id = "divider",
                value = "content/ui/materials/dividers/faded_line_01",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "left",
                    color = Color.terminal_text_body(175, true),
                    size = {self.sizes.value_item_size[1], sizes.divider_hight},
                    offset = {0,sizes.divider_hight,0}
                }
            },
            {   pass_type = "texture",
                style_id = "class_icon",
                value_id = "class_icon",
                value = "content/ui/materials/icons/classes/veteran",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "center",
                    color = Color.terminal_text_body(255, true),
                    size = {self.sizes.value_item_size[2], self.sizes.value_item_size[2]},
                    offset = {0,0,0},
                    visible = false
                }
            },
            {   pass_type = "texture",
                style_id = "inspect_icon",
                value_id = "inspect_icon",
                value = "content/ui/materials/icons/crafting/extract_trait",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "center",
                    color = Color.terminal_text_body(255, true),
                    size = {self.sizes.value_item_size[2], self.sizes.value_item_size[2]},
                    offset = {0,0,0},
                },
                visibility_function = function (content)
                    return content.is_player and content.hotspot.is_hover or false
                end
            },
            {   pass_type = "rect",
                style_id = "hover",
                style = {
                    vertical_alignment = "center",
                    horizontal_alignment = "center",
                    color = Color.citadel_death_guard_green(50, true)
                },
                visibility_function = function (content, style)
                    return content.is_player and content.hotspot.is_hover or false
                end
            },
        },
    }
    return item_templates
end
local function update_grids(self)
    local old_pivot_position_y = math.abs(self._ui_scenegraph.row_pivot.position[2])
    data.row.grid:force_update_list_size()

    local new_grid_length =  data.row.grid._total_grid_length
    local new_scrollbar_progress = math.clamp01(old_pivot_position_y/(new_grid_length-self.sizes.value_mask_size[2]))
    data.row.grid:set_scrollbar_progress(new_scrollbar_progress)  
    data.column.grid:force_update_list_size()
    data.value.grid:force_update_list_size()
end
local function update_widgets_state(widgets_array, parent_state)
    for _, row_widget in ipairs(widgets_array) do
        local row_widget_expanded = row_widget.content.logic.expanded
        local row_scenegraph_id
        local value_scenegraph_id
        local visible
        if parent_state then
            row_scenegraph_id = "row_item"
            value_scenegraph_id = "value_item"
            visible = true
        else
            row_scenegraph_id = "row_item_collapsed"
            value_scenegraph_id = "value_item_collapsed"
            visible = false
        end
        row_widget.scenegraph_id = row_scenegraph_id
        row_widget.visible = visible
        
        for _, value_widget in ipairs(row_widget.content.logic.child_value_widgets) do
            value_widget.scenegraph_id = value_scenegraph_id
            value_widget.visible = visible
        end
        local child_row_widgets = row_widget.content.logic.child_row_widgets
        if child_row_widgets then
            update_widgets_state(child_row_widgets, parent_state and row_widget_expanded)
        end
    end
end
local function toggle_row(self, widget)
    local logic = widget.content.logic
    if logic.expanded then
        logic.expanded = false
    else
        logic.expanded = true
    end
    update_widgets_state(data.row.root_widgets, true)
    update_grids(self)
end
local function generate_widgets(self)
    local row_item_template = self.item_templates.row
    local value_item_template = self.item_templates.value
    local column_item_template = self.item_templates.column
    local report = self.report

    local player_profiles = PDI.data.session_data.datasources.PlayerProfiles

    local function generate_column_widgets(self, input_table, is_player_column)
        for index, column in ipairs(input_table) do

            local item_definition = UIWidget.create_definition(column_item_template, "column_item")
            local widget = self:_create_widget("column_widget_"..index, item_definition)

            local player_profile
            local display_text

            if is_player_column then
                for player_unit_uuid, profile in pairs(player_profiles) do
                    if profile.character_id == column.name then
                        player_profile = table.clone(profile)
                    end
                end
            end

            if player_profile then
                display_text = player_profile.name
                local class_icon = player_profile.archetype.archetype_icon_large
                widget.content.is_player = true
                widget.content.class_icon = class_icon
                widget.style.class_icon.visible = true
                local display_text_size = get_text_size(display_text, font_name, font_size*1.5)
                local column_width = self.sizes.column_item_size[1]
                local icon_width = self.sizes.value_item_size[2]
                local max_text_size = column_width - (icon_width * 2)
                if display_text_size > max_text_size then
                    local override_font_size = get_max_font_size(display_text, font_name, max_text_size)
                    display_text_size = get_text_size(display_text, font_name, override_font_size)
                    widget.style.text.font_size = override_font_size
                end
                local x_offset = (0.5 * display_text_size) + (0.5 * self.sizes.value_item_size[2])
                widget.style.class_icon.offset[1] = -1 * x_offset
                widget.style.inspect_icon.offset[1] = x_offset
                widget.content.hotspot.pressed_callback = callback(view_manager.view_player_profile, player_profile)
                widget.style.hotspot.visible = true

                local column_hotspot_visibility_function = function()
                    local column_count = self.sizes.column_count or 0
                    local scroll_index = self.horizontal_scroll_index or 0
                    return scroll_index < index and (scroll_index + 5) > index
                end
                widget.passes[2].visibility_function = column_hotspot_visibility_function
            else
                display_text = column.name
            end
            widget.content.text = display_text
            data.column.widgets[index] = widget
            -- local children = column.children
            -- if children then
            --     generate_column_widgets(self, children)
            -- end
        end
    end
    local function generate_value_widgets(self, input_table, parent_row_widget)
        local output_array = {}
        local value_widgets = data.value.widgets
        for _, value in ipairs(input_table) do
            local current_index = #value_widgets + 1
            local item_definition = UIWidget.create_definition(value_item_template, "value_item", {text = value})
            local widget = self:_create_widget("value_widget_"..current_index, item_definition)
            widget.content.parent_row_widget = parent_row_widget
            widget.style.divider.size = {self.sizes.value_item_size[1], sizes.divider_hight }
            value_widgets[current_index] = widget
            output_array[#output_array+1] = widget
        end
        return output_array
    end
    local function generate_row_widgets(self, input_table, level)
        level = level or 1
        local output_array = {}
        local row_widgets = data.row.widgets
        for _, row in ipairs(input_table) do
            
            local current_index = #row_widgets + 1
            local row_text = row.name
            local row_text = string.gsub(row_text," percent","%%")
            if string.sub(row_text,1,4) == "loc_" then
                row_text = Localize(row_text)
            end
            local item_definition = UIWidget.create_definition(row_item_template, "row_item", {text = row_text})
            local widget = self:_create_widget("row_widget_"..current_index, item_definition)
            local unit_size = self.sizes.unit_size
            widget.style.text.offset[1] = (unit_size*0.5) + (level_offset*level)
            widget.style.text.font_size = 15
            widget.style.light_on.size = {unit_size,unit_size}
            widget.style.light_on.offset[1] = (unit_size*-0.41)+(level_offset*level)
            widget.style.light_off.size = {unit_size/6,unit_size/6}
            widget.style.light_off.offset[1] = (level_offset*level)
            widget.content.hotspot.pressed_callback = callback(toggle_row, self, widget)
            widget.style.divider.size = {self.sizes.row_item_size[1], sizes.divider_hight}
            row_widgets[current_index] = widget
            output_array[#output_array+1] = widget
            widget.content.logic.child_value_widgets = generate_value_widgets(self, row.values, widget)
            local child_rows = row.children
            if child_rows then
                widget.content.logic.child_row_widgets = generate_row_widgets(self, child_rows, level+1)
            end
        end
        return output_array
    end
    local function generate_column_banding_widget(self)
        local column_count = self.sizes.column_count
    
        local banding_def = UIWidget.create_definition({
            {	pass_type = "rect",
                style_id = "banding",
                style = {
                    vertical_alignment = "top",
                    horizontal_alignment = "left",
                    color = {
                        5,
                        255,
                        255,
                        255
                    },
                    size = {self.sizes.column_item_size[1], self.sizes.column_mask_size[2] + self.sizes.value_mask_size[2]},
                    offset = {0,0,0},
                }
            },
        }, "column_mask")
    
        data.column.banding_widgets = {}
    
        for i = 1, math.min(column_count, 4), 2 do
            local widget = self:_create_widget("banding_"..i, banding_def)
            widget.style.banding.offset[1] = self.sizes.column_item_size[1] * (i-1)
            data.column.banding_widgets[#data.column.banding_widgets+1] = widget
        end
    end
    
    data.row.root_widgets = generate_row_widgets(self, report.values_as_rows or {})
    local column_field = report.template.columns[1]
    local dataset_name = report.template.dataset_name
    local dataset_template = PDI.dataset_manager.get_dataset_template(dataset_name)
    local dataset_field_type = dataset_template.legend[column_field]
    
    local is_player_column = dataset_field_type == "player"
    generate_column_widgets(self, report.columns or {}, is_player_column)
    generate_column_banding_widget(self)

    local template = self.report.template

    self._widgets_by_name.report_title.content.text = template and template.label or "Report"
end
local function generate_grids(self)
    local scrollbar = self._widgets_by_name.scrollbar
    local scenegraph = self._ui_scenegraph
    local row = data.row
    local value = data.value
    local column = data.column
    row.grid = UIWidgetGrid:new(row.widgets, row.widgets, scenegraph, "row_mask", "down")
    row.grid:assign_scrollbar(scrollbar, "row_pivot", "report")
    value.grid = UIWidgetGrid:new(value.widgets, value.widgets, scenegraph, "value_area", "down")
    value.grid:assign_scrollbar(scrollbar, "value_pivot", "report")
    column.grid = UIWidgetGrid:new(column.widgets, column.widgets, scenegraph, "column_mask", "right")
end
PdiPivotTableViewElement.init = function (self, parent, draw_layer, start_scale, context)
    data = {
        row = {
            widgets = {},
        },
        value = {
            widgets = {},
        },
        column = {
            widgets = {},
        }
    }
    
    PDI = context.PDI
    view_manager = PDI.view_manager

    local settings = view_manager.settings
    sizes = settings.sizes
    font_name = settings.font_name
    font_size = settings.font_size

    offscreen_renderers = context.offscreen_renderers
    anchor_position = context.anchor_position

    self.report = context.report_data

    local report_size = sizes.report

    level_offset = report_size[1] * level_offset_ratio

    self.sizes = create_report_size_table(self, self.report, report_size, 4, level_offset, font_name, font_size)

    local definitions = get_definitions(self)

	PdiPivotTableViewElement.super.init(self, parent, draw_layer, start_scale, definitions)

    for _, package_name in ipairs(packages_array) do
        Managers.package:load(package_name, "PdiPivotTableViewElement")
    end

    data.row.renderer = offscreen_renderers[1].ui_offscreen_renderer
    data.value.renderer = offscreen_renderers[2].ui_offscreen_renderer
    data.column.renderer = offscreen_renderers[3].ui_offscreen_renderer

    -- self:_generate_ui_offscreen_renderers(3)
    -- data.row.renderer = self._ui_offscreen_renderer_1
    -- data.value.renderer = self._ui_offscreen_renderer_2
    -- data.column.renderer = self._ui_offscreen_renderer_3    
    self.item_templates = get_item_templates(self)
    generate_widgets(self)
    update_widgets_state(data.row.root_widgets, true)
    generate_grids(self)
    update_grids(self)
end
PdiPivotTableViewElement.set_render_scale = function (self, scale)
	PdiPivotTableViewElement.super.set_render_scale(self, scale)
end
PdiPivotTableViewElement.on_resolution_modified = function (self, scale)
	PdiPivotTableViewElement.super.on_resolution_modified(self, scale)
end
local test_toggle = true
PdiPivotTableViewElement.update = function (self, dt, t, input_service)

        for _, value in pairs(data) do
            local grid  = value.grid
            if grid then
            value.grid:update(dt, t, input_service)
            end
        end
    return PdiPivotTableViewElement.super.update(self, dt, t, input_service)
end

PdiPivotTableViewElement.draw = function (self, dt, t, ui_renderer, render_settings, input_service)
    if not packages_loaded then
        for _, package in ipairs(packages_array) do
            if not Managers.package:has_loaded(package) then
                return
            end
        end
        packages_loaded = true
    end

    local ui_scenegraph = self._ui_scenegraph
	
    for _, settings in pairs(data) do
        local widgets = settings.widgets
        if next(widgets) then
            local renderer = settings.renderer
            UIRenderer.begin_pass(renderer, ui_scenegraph, input_service, dt, render_settings)
            for _,widget in pairs(widgets) do
                if widget.visible then
                    UIWidget.draw(widget, renderer)
                end
            end
            UIRenderer.end_pass(renderer)
        end
    end

	PdiPivotTableViewElement.super.draw(self, dt, t, ui_renderer, render_settings, input_service)
end

PdiPivotTableViewElement._draw_widgets = function (self, dt, t, input_service, ui_renderer, render_settings)   
    for _, widget in ipairs(data.column.banding_widgets) do
        UIWidget.draw(widget, ui_renderer)
    end
	PdiPivotTableViewElement.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

PdiPivotTableViewElement.on_exit = function(self)
	PdiPivotTableViewElement.super.on_exit(self)
end

return PdiPivotTableViewElement
