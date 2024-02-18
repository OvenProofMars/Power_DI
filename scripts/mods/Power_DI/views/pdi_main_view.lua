PdiMainView = class("PDIMainView", "BaseView")

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
PdiMainView.init = function(self, settings, context)
    PDI = context
    ui_manager = PDI.ui_manager
	PdiMainView.super.init(self, definitions, settings)    
end
PdiMainView.on_enter = function(self)
	PdiMainView.super.on_enter(self)
    ui_manager.open_ui(self)
end
PdiMainView.update = function(self, dt, t, input_service)
    PDI.ui_manager.update(dt, t)
	return PdiMainView.super.update(self, dt, t, input_service)
end
PdiMainView.draw = function (self, dt, t, input_service, layer)
    PDI.ui_manager.draw_widgets(dt, t)
    PdiMainView.super.draw(self, dt, t, input_service, layer)
end
PdiMainView._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	PdiMainView.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end
PdiMainView.on_exit = function(self)
    PDI.ui_manager.close_ui()
	PdiMainView.super.on_exit(self)
end

return PdiMainView
