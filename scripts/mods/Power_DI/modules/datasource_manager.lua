local mod = get_mod("Power_DI")
local PDI

--Datasource manager data structure--
local datasource_manager = {}
datasource_manager.datasource_templates = {}
datasource_manager.registered_datasources = {}
datasource_manager.registered_datasource_hooks = {}
datasource_manager.session_datasource_proxies = {}

--Function to get active datasource table--
local function get_session_datasource(datasource_name)
    local datasources = PDI.data.session_data and PDI.data.session_data.datasources
    return datasources and datasources[datasource_name]
end

--Initializing the component, loads and registers the datasource templates--
datasource_manager.init = function(input_table)
    PDI = input_table
    local return_value = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\datasource_templates]])
    local datasource_templates = return_value.datasource_templates
    local data_locations = return_value.data_locations

    for _, datasource_template in ipairs(datasource_templates) do
        local datasource_name = datasource_template.name
        data_locations[datasource_name] = mod.datasources.register_datasource(datasource_template)
    end
end

--Function to get a list of the available datasources, accessible via the API--
datasource_manager.get_available_datasources = function()
    local output = {}
    local registered_datasources = datasource_manager.registered_datasources
    for datasource_name, _ in pairs(registered_datasources) do
        output[#output+1] = datasource_name
    end
    table.sort(output)
    return output
end

--Internal function to register datasources, accessible via the API--
datasource_manager.register_datasource = function(datasource_template)
    local datasource_name = datasource_template.name
    if not datasource_name then
        error("Template is missing datasource name")
    elseif datasource_manager.registered_datasources[datasource_name] then
        error("data source with the name \""..datasource_name.."\" already exists")
    end

    datasource_manager.registered_datasources[datasource_name] = datasource_template

    local hook_templates = datasource_template.hook_templates

    if hook_templates and next(hook_templates) then
        for _, hook_template in ipairs(hook_templates) do
            datasource_manager.register_datasource_hook(hook_template)
        end        
    end

    return callback(get_session_datasource, datasource_name)
end

--Function to register the hook templates found in the datasource templates--
datasource_manager.register_datasource_hook = function(hook_template)

    local registered_datasource_hooks = datasource_manager.registered_datasource_hooks
    local hook_class = hook_template.hook_class
    local hook_functions = hook_template.hook_functions

    registered_datasource_hooks[hook_class] = registered_datasource_hooks[hook_class] or {}

    local registered_hook_class = registered_datasource_hooks[hook_class]

    for hook_function_name, hook_function in pairs(hook_functions) do
        registered_hook_class[hook_function_name] = registered_hook_class[hook_function_name] or {}
        local registered_functions = registered_hook_class[hook_function_name]
        registered_functions[#registered_functions+1] = hook_function
    end
end

--Function to activate all the datasource hooks--
datasource_manager.activate_hooks = function()

    local registered_datasource_hooks = datasource_manager.registered_datasource_hooks

    for hook_class, hook_functions in pairs(registered_datasource_hooks) do
        for hook_function_name, registered_functions in pairs(hook_functions) do
            if #registered_functions == 1 then
                mod:hook(hook_class, hook_function_name, function(func, ...)
                    registered_functions[1](...)
                    func(...)
                end)
            else
                mod:hook(hook_class, hook_function_name, function(func,...)
                    for _, hook_function in ipairs(registered_functions) do
                        hook_function(...)
                    end
                    func(...)
                end)
            end
        end
    end
end

--Function to create the required datasource tables in the session data--
datasource_manager.add_datasources = function(session)
    session.datasources = {}

    for _, datasource_template in pairs(datasource_manager.registered_datasources) do
        local datasource_name = datasource_template.name
        session.datasources[datasource_name] = {}
    end
end

--Function to clear the cache used by some datasource functions--
datasource_manager.clear_cache = function()
    for k, v in pairs(mod.cache) do
        mod.cache[k] = {}
    end
end

return datasource_manager