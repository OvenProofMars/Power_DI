local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

PdiMainView2 = class("PDIMainView", "BaseView")

local PDI, ui_manager

local definitions = {
    scenegraph_definition = {        
        screen = {
        scale = "fit",
        size = {1920,1080},
    },},
    widget_definitions = {},
    legend_inputs = {}
}
PdiMainView2.init = function(self, settings, context)
    PDI = context
    ui_manager = PDI.ui_manager
	PdiMainView2.super.init(self, definitions, settings)    
end
PdiMainView2.on_enter = function(self)
	PdiMainView2.super.on_enter(self)
    ui_manager.open_ui(self)
end
PdiMainView2.update = function(self, dt, t, input_service)
    PDI.ui_manager.update(dt, t)
	return PdiMainView2.super.update(self, dt, t, input_service)
end
PdiMainView2.draw = function (self, dt, t, input_service, layer)
    PDI.ui_manager.draw_widgets(dt, t)
    PdiMainView2.super.draw(self, dt, t, input_service, layer)
end
PdiMainView2._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	PdiMainView2.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end
PdiMainView2.on_exit = function(self)
    PDI.ui_manager.close_ui()
	PdiMainView2.super.on_exit(self)
end

return PdiMainView2
