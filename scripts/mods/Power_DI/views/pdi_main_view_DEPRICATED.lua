local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

local PdiPivotTableViewElement = require([[Power_DI\scripts\mods\Power_DI\views\view_elements\pdi_pivot_table_view_element]])
local PdiMainView_DEPRICATEDElement = require([[Power_DI\scripts\mods\Power_DI\views\view_elements\pdi_main_view_element]])

local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIFontSettings = mod:original_require("scripts/managers/ui/ui_font_settings")
local ScrollbarPassTemplates = require("scripts/ui/pass_templates/scrollbar_pass_templates")
local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local DropdownPassTemplates = require("scripts/ui/pass_templates/dropdown_pass_templates")
local ContentBlueprints = require("scripts/ui/views/options_view/options_view_content_blueprints")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")

local WorldRenderUtils = require("scripts/utilities/world_render")

local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

PdiMainView_DEPRICATED = class("PdiMainView_DEPRICATED", "PdiBaseView")

local edit_mode = true

local PDI, view_manager, sizes, font_name, font_size


mod:add_global_localize_strings({
    loc_pdi_exit = {
        en = "Exit Power DI",
    },
})

local function get_definitions(self)
    local definitions = {
        scenegraph_definition = {
            screen = {
                scale = "fit",
                size = sizes.screen,
            },
            background = {
                parent = "screen",
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = sizes.background,
                position = {
                    0,
                    sizes.background[2]*-0.025,
                    0,
                },
            },
            background_icon = {
                vertical_alignment = "center",
                parent = "screen",
                horizontal_alignment = "center",
                size = {
                    1250,
                    1250
                },
                position = {
                    0,
                    0,
                    1
                }
            },
            header = {
                parent = "background",
                horizontal_alignment = "center",
                vertical_alignment = "top",
                size = sizes.header,
                position = {
                    0,
                    0,
                    0,
                },
            },
            header_divider = {
                parent = "header",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.header_divider,
                position = {
                    0,
                    sizes.header[2],
                    0,
                },
            },
            workspace = {
                parent = "header_divider",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.workspace,
                position = {
                    0,
                    sizes.header_divider[2],
                    0,
                },
            },
            main_view_element_anchor = {
                parent = "workspace",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {1,1},
                position = {
                    0,
                    0,
                    0,
                },
            },
            report = {
                parent = "workspace",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.report,
                position = {
                    sizes.block[1],
                    0,
                    0,
                },
            },
            report_view_element_anchor = {
                parent = "workspace",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = {1,1},
                position = {
                    sizes.block[1],
                    0,
                    0,
                },
            },
            loading_icon = {
                parent = "report",
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = sizes.loading_icon,
                position = {
                    0,
                    0,
                    0,
                },
            },
            footer_divider = {
                parent = "workspace",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.footer_divider,
                position = {
                    0,
                    sizes.workspace[2],
                    0,
                },
            },
            footer = {
                parent = "footer_divider",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = sizes.footer,
                position = {
                    0,
                    sizes.footer_divider[2],
                    0,
                },
            },
        },
        widget_definitions = {
            loading_icon = UIWidget.create_definition({
                {
                    value = "content/ui/materials/loading/loading_icon",
                    pass_type = "texture",
                    style = {
                        color = {
                            255,
                            255,
                            255,
                            255
                        },
                    },
                    visibility_function = function (content)
                        return view_manager.get_loading()
                    end
                }
            }, "loading_icon"),
            error_message = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "TEST",
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
                    change_function = view_manager.error_message_change_function
                },
            }, "report"),
            header = UIWidget.create_definition({
                {   pass_type = "text",
                    style_id = "text",
                    value_id = "text",
                    value = "Power DI",
                    style = {
                        material = "content/ui/materials/font_gradients/slug_font_gradient_gold",
                        text_vertical_alignment = "center",
                        text_horizontal_alignment = "center",
                        offset = {
                            0,
                            0,
                            0
                        },
                        --font_type = font_name,
                        font_type = "machine_medium",
                        font_size = font_size*4,
                        --text_color = Color.terminal_text_body(255, true),
                        text_color = {255,255,255,255},
                        default_text_color = {
                            255,
                            255,
                            255,
                            255,
                        }
                    },
                },
            }, "header"),
            header_divider = UIWidget.create_definition({
                {   pass_type = "texture",
                style_id = "divider",
                value = "content/ui/materials/dividers/faded_line_01",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "center",
                    color = Color.terminal_text_body(175, true),
                    size = {sizes.header[1],sizes.divider_hight}
                }
                },
            }, "header_divider"),
            background = UIWidget.create_definition({
                {   pass_type = "texture",
                    value = "content/ui/materials/backgrounds/terminal_basic",
                    style = {
                        vertical_alignment = "center",
                        horizontal_alignment = "center",
                        scale_to_material = true,
                        color = Color.terminal_grid_background_gradient(255, true),
                        size = {sizes.background[1]*1.01, sizes.background[2]*1.02},
                        offset = {
                            0,
                            0,
                            -1
                        }
                    },
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
                        size = sizes.background,
                        offset = {
                            0,
                            0,
                            -5
                        }
                    }
                },
                {   pass_type = "texture",
                value = "content/ui/materials/dividers/horizontal_frame_big_upper",
                style = {
                    vertical_alignment = "top",
                    horizontal_alignment = "center",
                    size = {sizes.background[1], sizes.frame_hight},
                    offset = {
                        0,sizes.frame_hight*-0.5,5
                    }
                }
                },
                {   pass_type = "texture",
                value = "content/ui/materials/dividers/horizontal_frame_big_lower",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "center",
                    size = {sizes.background[1], sizes.frame_hight},
                    offset = {
                        0,sizes.frame_hight*0.5,5
                    }
                }
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
                        size = {sizes.background[1]*0.75,sizes.background[2]},
                        offset = {
                            0,
                            0,
                            -1
                        }
                    }
                },
                {   pass_type = "texture",
                value = "content/ui/materials/dividers/skull_rendered_center_03_addon",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "center",
                    size = {sizes.block_item[1], sizes.block_item[2]*1.25},
                    offset = {
                        0,
                        sizes.block_item[2]*1.1,
                        5
                    }
                }
            }
            }, "background"),
            background_icon = UIWidget.create_definition({
                {
                    value = "content/ui/vector_textures/symbols/cog_skull_01",
                    pass_type = "slug_icon",
                    style = {
                        offset = {
                            0,
                            0,
                            -1
                        },
                        color = {
                            20,
                            0,
                            0,
                            0
                        }
                    }
                }
            }, "background_icon"),
            footer_divider = UIWidget.create_definition({
                {   pass_type = "texture",
                style_id = "divider",
                value = "content/ui/materials/dividers/faded_line_01",
                style = {
                    vertical_alignment = "bottom",
                    horizontal_alignment = "center",
                    color = Color.terminal_text_body(175, true),
                    size = {sizes.header[1],sizes.divider_hight}
                }
                },
            }, "footer_divider"),
            footer = UIWidget.create_definition({
                {   pass_type = "text",
                style_id = "text",
                value_id = "text",
                value = "Version "..mod.version,
                style = {
                    text_vertical_alignment = "center",
                    text_horizontal_alignment = "center",
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
            }, "footer"),
        },
        legend_inputs = {
        {
            input_action = "back",
            on_pressed_callback = "_on_back_pressed",
            display_name = "loc_pdi_exit",
            alignment = "left_alignment",
        },
        },
    }
    return definitions
end
PdiMainView_DEPRICATED.cb_shading_callback = function (self, world, shading_env, viewport, default_shading_environment_name)
	local gamma = Application.user_setting("gamma") or 0

	ShadingEnvironment.set_scalar(shading_env, "exposure_compensation", ShadingEnvironment.scalar(shading_env, "exposure_compensation") + gamma)

	local blur_value = World.get_data(world, "fullscreen_blur") or 0

	if blur_value > 0 then
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_amount", math.clamp(blur_value, 0, 1))
	else
		World.set_data(world, "fullscreen_blur", nil)
		ShadingEnvironment.set_scalar(shading_env, "fullscreen_blur_enabled", 0)
	end

	local greyscale_value = World.get_data(world, "greyscale") or 0

	if greyscale_value > 0 then
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 1)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_amount", math.clamp(greyscale_value, 0, 1))
		ShadingEnvironment.set_vector3(shading_env, "grey_scale_weights", Vector3(0.33, 0.33, 0.33))
	else
		World.set_data(world, "greyscale", nil)
		ShadingEnvironment.set_scalar(shading_env, "grey_scale_enabled", 0)
	end
end
PdiMainView_DEPRICATED._setup_background_gui = function (self)
	local ui_manager = Managers.ui
	local class_name = self.__class_name
	local timer_name = "ui"
	local world_layer = 100
	local world_name = class_name .. "_ui_background_world"
	local view_name = self.view_name
	self._background_world = ui_manager:create_world(world_name, world_layer, timer_name, view_name)
	self._background_world_name = world_name
	self._background_world_draw_layer = world_layer
	self._background_world_default_layer = world_layer
	local shading_environment = "content/shading_environments/ui/ui_popup_background"
	local shading_callback = callback(self, "cb_shading_callback")
	local viewport_name = class_name .. "_ui_background_world_viewport"
	local viewport_type = "overlay"
	local viewport_layer = 1
	self._background_viewport = ui_manager:create_viewport(self._background_world, viewport_name, viewport_type, viewport_layer, shading_environment, shading_callback)
	self._background_viewport_name = viewport_name
	self._ui_background_renderer = ui_manager:create_renderer(class_name .. "_ui_background_renderer", self._background_world)
	local max_value = 0.75

	WorldRenderUtils.enable_world_fullscreen_blur(world_name, viewport_name, max_value)
end
PdiMainView_DEPRICATED._setup_default_gui = function (self)
	local ui_manager = Managers.ui
	local class_name = self.__class_name
	local timer_name = "ui"
	local world_layer = 110
	local world_name = class_name .. "_ui_default_world"
	local view_name = self.view_name
	self._world = ui_manager:create_world(world_name, world_layer, timer_name, view_name)
	self._world_name = world_name
	self._world_draw_layer = world_layer
	self._world_default_layer = world_layer
	local viewport_name = class_name .. "_ui_default_world_viewport"
	local viewport_type = "overlay"
	local viewport_layer = 1
	self._viewport = ui_manager:create_viewport(self._world, viewport_name, viewport_type, viewport_layer)
	self._viewport_name = viewport_name
	self._ui_default_renderer = ui_manager:create_renderer(class_name .. "_ui_default_renderer", self._world)
end
PdiMainView_DEPRICATED._destroy_background = function (self)
	if self._ui_background_renderer then
		self._ui_background_renderer = nil

		Managers.ui:destroy_renderer(self.__class_name .. "_ui_background_renderer")

		local world = self._background_world
		local viewport_name = self._background_viewport_name

		ScriptWorld.destroy_viewport(world, viewport_name)
		Managers.ui:destroy_world(world)

		self._background_viewport_name = nil
		self._background_world = nil
	end
end
PdiMainView_DEPRICATED._destroy_default_gui = function (self)
	if self._ui_default_renderer then
		self._ui_default_renderer = nil

		Managers.ui:destroy_renderer(self.__class_name .. "_ui_default_renderer")

		local world = self._world
		local viewport_name = self._viewport_name

		ScriptWorld.destroy_viewport(world, viewport_name)
		Managers.ui:destroy_world(world)

		self._viewport_name = nil
		self._world = nil
	end
end

PdiMainView_DEPRICATED.init = function(self, settings, context)
    PDI = context
    view_manager = PDI.view_manager

    local view_manager_settings = view_manager.settings
    sizes = view_manager_settings.sizes
    font_name = view_manager_settings.font_name
    font_size = view_manager_settings.font_size

    view_manager.set_current_view_instance(self)
    view_manager.load_packages()
    
    local definitions = get_definitions(self)
	PdiMainView_DEPRICATED.super.init(self, definitions, settings)
end
PdiMainView_DEPRICATED.on_enter = function(self)
    self:_setup_default_gui()
    self:_setup_background_gui()
    self:_generate_ui_offscreen_renderers(3)
    self:_setup_input_legend()
    view_manager.init_main_view_elements(self)
	PdiMainView_DEPRICATED.super.on_enter(self)
end
PdiMainView_DEPRICATED._setup_input_legend = function(self)
	self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)
	local legend_inputs = self._definitions.legend_inputs

	for i = 1, #legend_inputs do
		local legend_input = legend_inputs[i]
		local on_pressed_callback = legend_input.on_pressed_callback
			and callback(self, legend_input.on_pressed_callback)

		self._input_legend_element:add_entry(
			legend_input.display_name,
			legend_input.input_action,
			legend_input.visibility_function,
			on_pressed_callback,
			legend_input.alignment
		)
	end
end
PdiMainView_DEPRICATED._on_back_pressed = function(self)
	Managers.ui:close_view(self.view_name)
end
PdiMainView_DEPRICATED._destroy_renderer = function(self)
	if self._offscreen_renderer then
		self._offscreen_renderer = nil
	end

	local world_data = self._offscreen_world

	if world_data then
		Managers.ui:destroy_renderer(world_data.renderer_name)
		ScriptWorld.destroy_viewport(world_data.world, world_data.viewport_name)
		Managers.ui:destroy_world(world_data.world)

		world_data = nil
	end
end
PdiMainView_DEPRICATED.update = function(self, dt, t, input_service)
	return PdiMainView_DEPRICATED.super.update(self, dt, t, input_service)
end
PdiMainView_DEPRICATED.draw = function (self, dt, t, input_service, layer)

    if not view_manager.packages_loaded() then
        return
    end

    local render_scale = self._render_scale
	local render_settings = self._render_settings
	local ui_renderer = self._ui_default_renderer
	render_settings.start_layer = layer
	render_settings.scale = render_scale
	render_settings.inverse_scale = render_scale and 1 / render_scale
	local ui_scenegraph = self._ui_scenegraph

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, render_settings)
	self:_draw_widgets(dt, t, input_service, ui_renderer)
	UIRenderer.end_pass(ui_renderer)
	self:_draw_elements(dt, t, ui_renderer, render_settings, input_service)
end
PdiMainView_DEPRICATED._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	PdiMainView_DEPRICATED.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end
PdiMainView_DEPRICATED.on_exit = function(self)
	PdiMainView_DEPRICATED.super.on_exit(self)
    self:_destroy_background()
    self:_destroy_default_gui()
    self:_destroy_ui_offscreen_renderers()
	self:_destroy_renderer()
end

return PdiMainView_DEPRICATED
