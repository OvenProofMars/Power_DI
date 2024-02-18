local mod = get_mod("Power_DI")
local PDI, utilities, master_data_items_cache

local lookup_manager = {}
local game_lookup_tables = {}
local registered_lookup_tables = {}


--Function to initialize the lookup tables based on the game's tables--
local function add_game_lookup_tables()
    game_lookup_tables = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\game_lookup_table_templates]])
    utilities.clean_table_for_saving(game_lookup_tables)

    if master_data_items_cache:get_cached() then
        lookup_manager.add_master_item_lookup_table()
    end
end

--Function to initialize the custome lookup tables--
local function add_custom_lookup_tables()
    local path = "Power_DI/scripts/mods/Power_DI/templates/custom_lookup_table_templates/"
    local index = mod:io_dofile(path.."index")
    for _, value in ipairs(index) do
        local template = {}
        template.name = value
        template.lookup_table = mod:io_dofile(path..value)
        mod.lookup_tables.register_lookup_table(template)
    end
end

--Initialize the module, sets up the lookup tables--
lookup_manager.init = function(input_table)
    PDI = input_table
    utilities = PDI.utilities
    master_data_items_cache = Managers.backend.interfaces.master_data:items_cache()
    add_game_lookup_tables()
    add_custom_lookup_tables()
end

--Update function, currently unused
lookup_manager.update = function()
end

--Function to get the full set of lookup tables--
lookup_manager.get_lookup_tables = function()
    local output = {}
    for k, v in pairs(game_lookup_tables) do
        output[k] = v
    end
    for k, v in pairs(registered_lookup_tables) do
        output[k] = v
    end
    return output
end

--Function to add the MasterItems to the lookup table, only triggered after login--
lookup_manager.add_master_item_lookup_table = function()
    game_lookup_tables["MasterItems"] = table.clone(master_data_items_cache:get_cached())
    PDI.save_manager.save("game_lookup_tables", game_lookup_tables)
end

--Function to register a new lookup table, available via the API--
lookup_manager.register_lookup_table = function(lookup_template)
    if not lookup_template or type(lookup_template) ~= "table" then
        error("Required lookup table template not supplied")
    end
    local lookup_template_name = lookup_template.name
    if not lookup_template_name or type(lookup_template_name) ~= "string" then
        error("Lookup template name not found")
    elseif registered_lookup_tables[lookup_template_name] or game_lookup_tables[lookup_template_name] or lookup_template_name == "MasterItems" then
        error("Lookup table with that name already exists")
    end
    local lookup_template_lookup_table = lookup_template.lookup_table
    if not lookup_template_lookup_table or  type(lookup_template_lookup_table) ~= "table" then
        error("Lookup template does not contain a valid lookup table")
    end
    registered_lookup_tables[lookup_template_name] = lookup_template_lookup_table
    return true
end

--Function to get a list of all the available lookup tables, available via the API--
lookup_manager.get_available_lookup_tables = function()
    local output = {}
    for lookup_table_name, _ in pairs(game_lookup_tables) do
        output[#output+1] = lookup_table_name
    end
    for lookup_table_name, _ in pairs(registered_lookup_tables) do
        output[#output+1] = lookup_table_name
    end
    return output
end

return lookup_manager