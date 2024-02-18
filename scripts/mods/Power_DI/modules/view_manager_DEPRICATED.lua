local mod = get_mod("Power_DI")

local UIManager = Managers.ui

local PDI, main_view_instance, loading, error, packages_loaded, selected_session_id, selected_report_name
local font_name = "proxima_nova_bold"
local font_size = "18"

local view_manager = {}

local view_templates = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\view_templates]])
local base_class_array = {
    [[Power_DI\scripts\mods\Power_DI\views\pdi_base_view]],
    [[Power_DI\scripts\mods\Power_DI\views\view_elements\pdi_base_view_element]],
}
local view_element_array = {
    [[Power_DI\scripts\mods\Power_DI\views\view_elements\pdi_pivot_table_view_element]],
    [[Power_DI\scripts\mods\Power_DI\views\view_elements\pdi_main_view_element]],
    [[Power_DI\scripts\mods\Power_DI\views\view_elements\pdi_edit_view_element]]
}
local packages_array = {
    "packages/ui/views/crafting_view/crafting_view",
    "packages/ui/views/news_view/news_view",
    "packages/ui/views/achievements_view/achievements_view",
    "packages/ui/views/options_view/options_view",
}

local function create_size_table()
    local screen_size = {1920,1080}
    local scrollbar_width = 10
    local divider_hight = 2
    local background_size = {screen_size[1]*0.95,screen_size[2]*0.9}
    local header_size = {background_size[1], background_size[2]*0.1}
    local header_divider_size = {background_size[1], divider_hight}
    local footer_size = {background_size[1], background_size[2]*0.05}
    local footer_divider_size = {background_size[1], divider_hight}
    local workspace_size = {background_size[1], background_size[2]-header_size[2]-footer_size[2]-(2*divider_hight)}
    local block_size = {workspace_size[1]*0.2, (workspace_size[2]-divider_hight)/2}
    local block_header_size = {block_size[1], workspace_size[2]*0.1}
    local block_divider_size = {block_size[1], divider_hight}
    local block_area_size = {block_size[1]-scrollbar_width, block_size[2]-block_header_size[2]-divider_hight}
    local block_scrollbar_size = {scrollbar_width, block_area_size[2]}
    local block_item_size = {block_area_size[1], workspace_size[2]*0.05}
    local report_size = {workspace_size[1]-block_size[1], workspace_size[2]}

    local edit_block_size = {workspace_size[1]/4, workspace_size[2]/2}

    local sizes = {
        divider_hight = 2,
        frame_hight = 50,
        screen = screen_size,
        background = background_size,
        header = header_size,
        header_divider = header_divider_size,
        footer = footer_size,
        footer_divider = footer_divider_size,
        workspace = workspace_size,
        block = block_size,
        block_header = block_header_size,
        block_divider = block_divider_size,
        block_area = block_area_size,
        block_scrollbar = block_scrollbar_size,
        block_item = block_item_size,
        report = report_size,
        loading_icon = {workspace_size[1]*0.2, workspace_size[1]*0.2},
        edit_block = edit_block_size,
    }
    return sizes
end

view_manager.settings = {
    sizes = create_size_table(),
    font_name = font_name,
    font_size = font_size,
}

view_manager.init = function (input_table)
    PDI = input_table

    for view_name, template in pairs(view_templates) do
        mod:add_require_path(template.view_settings.path)
        mod:register_view(template)
    end
    for _, base_class_path in ipairs(base_class_array) do
        mod:add_require_path(base_class_path)
        require(base_class_path)
    end
    for _, view_element_path in ipairs(view_element_array) do
        mod:add_require_path(view_element_path)
        require(view_element_path)
    end
end
view_manager.open_main_view = function()
    if not UIManager:chat_using_input() and not UIManager:view_instance("pdi_main_view") and not UIManager:view_active("title_view") and not UIManager:view_active("loading_view") then
        Managers.ui:open_view("pdi_main_view", 10,nil,nil,nil, PDI)
    elseif Managers.ui:view_instance("pdi_main_view") then
        Managers.ui:close_view("pdi_main_view")
    end
end
view_manager.load_packages = function()
    packages_loaded = false
    for _, package_name in ipairs(packages_array) do
        Managers.package:load(package_name, "PdiMainView")
    end
end
view_manager.packages_loaded = function()
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
view_manager.init_main_view_elements = function(self)
    local context = {}
    context.PDI = PDI
    context.offscreen_renderers = self.ui_offscreen_renderers
    context.anchor_position = self._ui_scenegraph.main_view_element_anchor.world_position

    self:_add_element(PdiMainViewElement, "PdiMainViewElement", 1, context)
end
view_manager.init_pivot_table_view_elements = function()
    local context = {}
    context.PDI = PDI
    context.offscreen_renderers = main_view_instance.ui_offscreen_renderers
    context.report_data = PDI.data.session_data.reports[selected_report_name]
    context.anchor_position = main_view_instance._ui_scenegraph.report_view_element_anchor.world_position

    main_view_instance:_add_element(PdiPivotTableViewElement, "PdiPivotTableViewElement", 1, context)
end
view_manager.set_current_view_instance = function(instance)
    main_view_instance = instance
end
view_manager.get_current_view_instance = function()
    return main_view_instance
end
view_manager.get_loading = function()
    return loading
end
view_manager.set_loading = function(boolean)
    loading = boolean
end
view_manager.set_selected_report_name = function(report_name)
    selected_report_name = report_name
end
view_manager.get_selected_report_name = function()
    return selected_report_name
end
view_manager.set_error = function(input_error)
    error = input_error
end
view_manager.get_error = function()
    return error
end
view_manager.set_selected_session_id = function(session_id)
    selected_session_id = session_id
end
view_manager.get_selected_session_id = function()
    return selected_session_id
end
view_manager.error_message_change_function = function (content,style)
    if error then
        loading = false
        content.text = "error:\n\t"..error.error.."\n\n"..error.stacktrace
    else
        content.text = ""
    end
end
view_manager.session_selected_callback = function(self, session_id)
    if not session_id then
        return
    end
    
    selected_session_id = session_id

    local report_name = selected_report_name
    local report_template = PDI.report_manager.get_report_template(report_name)
    local dataset_name = report_template.dataset_name
    local dataset_manager = PDI.dataset_manager
    local dataset_template = dataset_manager.get_dataset_template(dataset_name)

    if main_view_instance._elements["PdiPivotTableViewElement"] then
        main_view_instance:_remove_element("PdiPivotTableViewElement")
    end

    loading = true
    error = nil
    PDI.session_manager.load_session(session_id)
    :next(
        function(data)
            data.datasets[dataset_name] = nil
            data.reports[report_name] = nil
            return dataset_manager.generate_dataset(dataset_template)
        end
    )
    :next( 
        function()
            return PDI.report_manager.generate_report(report_template)
        end
    )
    :next(
        function()
            view_manager.init_pivot_table_view_elements()
            loading = false
        end
    )
end
view_manager.init_data_in_game = function(self, session_id)

    selected_session_id = session_id
    selected_report_name = "Attack report"

    local report_name = selected_report_name
    local report_template = PDI.report_manager.get_report_template(report_name)
    local dataset_name = report_template.dataset_name
    local dataset_manager = PDI.dataset_manager
    local dataset_template = dataset_manager.get_dataset_template(dataset_name)

    if main_view_instance._elements["PdiPivotTableViewElement"] then
        main_view_instance:_remove_element("PdiPivotTableViewElement")
    end

    loading = true
    error = nil

    local session_data = PDI.data.session_data

    session_data.datasets[dataset_name] = nil
    session_data.reports[report_name] = nil

    PDI.dataset_manager.prepare_session(session_data)
    PDI.report_manager.prepare_session(session_data)

    PDI.dataset_manager.generate_dataset(dataset_template)
    :next( 
        function()
            return PDI.report_manager.generate_report(report_template)
        end
    )
    :next(
        function()
            view_manager.init_pivot_table_view_elements()
            loading = false
        end
    )
end
view_manager.report_selected_callback = function(self, report_list, widget_index, report_name)
    local grid = report_list.grid
    local current_selected_index = grid:selected_grid_index()

    if widget_index == current_selected_index then
        return
    end

    selected_report_name = report_name

    grid:select_grid_index(widget_index)

    if not selected_session_id then
        return
    end

    local report_widget = report_list.widgets[widget_index]

    --local report_name = report_widget.name
    local report_template = PDI.report_manager.get_report_template(report_name)
    local dataset_name = report_template.dataset_name
    local dataset_manager = PDI.dataset_manager
    local dataset_template = dataset_manager.get_dataset_template(dataset_name)

    

    PDI.data.session_data.datasets[dataset_name] = nil
    PDI.data.session_data.reports[report_name] = nil

    if main_view_instance._elements["PdiPivotTableViewElement"] then
        main_view_instance:_remove_element("PdiPivotTableViewElement")
    end

    loading = true
    error = nil

    dataset_manager.generate_dataset(dataset_template)
    :next( 
        function()
            return PDI.report_manager.generate_report(report_template)
        end
    )
    :next(
        function()
            view_manager.init_pivot_table_view_elements()
            loading = false
        end
    )
end
view_manager.open_edit_view = function(self, report_template)
    loading = false
    error = nil
    if main_view_instance._elements["PdiPivotTableViewElement"] then
        main_view_instance:_remove_element("PdiPivotTableViewElement")
    end
    if main_view_instance._elements["PdiMainViewElement"] then
        main_view_instance:_remove_element("PdiMainViewElement")
    end

    local context = {}
    context.PDI = PDI
    context.offscreen_renderers = main_view_instance.ui_offscreen_renderers
    context.anchor_position = main_view_instance._ui_scenegraph.main_view_element_anchor.world_position
    context.report_template = report_template

    main_view_instance:_add_element(PdiEditViewElement, "PdiEditViewElement", 1, context)
end
view_manager.view_player_profile = function(player_profile)
    
    for _, value in pairs(player_profile.loadout) do
        PDI.utilities.set_master_item_meta_table(value)
    end

    local local_player = Managers.player:local_player(1)
    local local_player_peer_id = local_player:peer_id()
    local local_player_account_id = local_player:account_id()
    local data_service_social = Managers.data_service.social
    local player_info = data_service_social:get_player_info_by_account_id(local_player_account_id)
    
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

    Managers.ui:open_view("inventory_background_view", nil, nil, nil, nil, {
        is_readonly = true,
        player = player_info
    })
end

return view_manager