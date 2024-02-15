local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

PDIWidget = class("PDIWidget")

PDIWidget.init = function(self, parent, position, size, pass_templates)
    self.parent = parent
    self.position = position
    self.size = size
    
end

PDIWidget.update = function(self)

    
end

PDIWidget.destroy = function(self, ...)

end

return PDIWidget