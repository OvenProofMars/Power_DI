local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local PDI
local save_manager = {}
save_manager.queue = {}

--Function that returns the currently loaded session id--
local function get_loaded_session_id()
    local session_id = PDI.data.session_data and PDI.data.session_data.info.session_id
    return session_id
end

--Table for filenames--
save_manager.filenames = {
    ["save_data"] = "power_di",
    ["session_data"] = get_loaded_session_id,
    ["lookup_data"] = "lookup_tables_"..mod.version.."_v"..APPLICATION_SETTINGS.game_version,
} 

local saved_this_cycle = false

--Function to clean a string to comply with the stingray save functions--
local function clean_string(input_string)
    local output_string = input_string:lower():gsub("[%p%c%s]","_")
    return output_string
end

--Function that handles the save queue--
local function handle_queue()
    for k,v in ipairs(save_manager.queue) do
        local save_progress = SaveSystem.progress(v.token)
        if save_progress and save_progress.done then
            if save_progress.error then
                v.promise:reject(save_progress.error)
            elseif save_progress.data then
                v.promise:resolve(save_progress.data)
            else
                v.promise:resolve(true)
            end
            SaveSystem.close(v.token)
            table.remove(save_manager.queue,k)
        end
    end
end

--Function to save a table to disk, returns a promise--
save_manager.save = function(file_or_table_name, table_data)
    local filename
    if save_manager.filenames[file_or_table_name] then
        if type(save_manager.filenames[file_or_table_name]) == "function" then
            filename = save_manager.filenames[file_or_table_name]()
        else
            filename = save_manager.filenames[file_or_table_name]
        end
    else
        filename = file_or_table_name
    end
    local promise = PDI.promise:new()
    local temp_table = {}
    temp_table.token = SaveSystem.auto_save(clean_string(filename), table_data)
    temp_table.promise = promise
    table.insert(save_manager.queue, temp_table)
    return promise
end

--Function to load a file from disk, returns a promise--
save_manager.load = function(file_or_table_name)
    local filename
    if save_manager.filenames[file_or_table_name] then
        if type(save_manager.filenames[file_or_table_name]) == "function" then
            filename = save_manager.filenames[file_or_table_name]()
        else
            filename = save_manager.filenames[file_or_table_name]
        end
    else
            filename = file_or_table_name
    end
    local promise = PDI.promise:new()
    local temp_table = {}
    temp_table.token = SaveSystem.auto_load(clean_string(filename))
    temp_table.promise = promise
    table.insert(save_manager.queue, temp_table)
    return promise
end

--Function to save multiple tables at the same time, still needs promide implementation--
save_manager.save_multiple = function(input_table)
    for table_key, table_value in pairs(input_table) do
        save_manager.save(table_key, table_value)
    end
end

--Function that auto saves every interval while in a mission--
local function auto_save()
    if save_manager.auto_save then
        if PDI.utilities.in_game() then
            local gameplay_time = mod.utilities.get_gameplay_time()
            if gameplay_time == 0 then
                return
            end
            local auto_save_interval = save_manager.auto_save_interval
            local modulus = gameplay_time % auto_save_interval
            if (modulus > (auto_save_interval-1)) and not saved_this_cycle then
                PDI.session_manager.save_current_session()
                saved_this_cycle = true
            elseif (modulus < (auto_save_interval-1)) then
                saved_this_cycle = false
            end
        end
    end
end

--Initialize module, loads the save data, and latest session data--
save_manager.init = function(input_table)
    PDI = input_table

    save_manager.auto_save = mod:get("auto_save")
    save_manager.auto_save_interval = mod:get("auto_save_interval")

    local promise = PDI.promise:new()
    local sessions_index
    local sessions
    local session_id
    save_manager.load("save_data")
    :next(
        function(data)
            PDI.data.save_data = data
        end,
        function(err)
            PDI.data.save_data = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\save_data_template]])
        end
    )
    :next(
        function()
            sessions_index = PDI.data.save_data.sessions_index
            session_id = sessions_index[#sessions_index]
            if session_id then
                return save_manager.load(session_id)
            else
                return PDI.session_manager.new()
            end
        end
    )
    :next(
        function(data)
            PDI.data.session_data = data
        end,
        function(err)
            PDI.data.session_data = PDI.session_manager.new()
            sessions = PDI.data.save_data.sessions
            table.remove(sessions_index,#sessions_index)
            sessions[session_id] = nil
            session_id = nil
        end
    )
    :next(
        function()
            if session_id then
                local power_di_version = sessions[session_id].info.power_di_version
                local game_version = sessions[session_id].info.game_version
                local lookup_tables_filename = "lookup_tables_"..power_di_version.."_v"..game_version
                return save_manager.load(lookup_tables_filename)
            else
                return PDI.promise:rejected("no previous session found")
            end
        end
    )
    :next(
        function(data)
            PDI.data.lookup_data = data
        end,
        function(err)
            PDI.data.lookup_data = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\lookup_tables_template]])
            PDI.utilities.clean_table_for_saving(PDI.data.lookup_data)
        end
    )
    :next(
        function(a)
            save_manager.save_multiple(PDI.data)
        end
    )
    :next(
        function()
            promise:resolve()
        end
    )
    return promise
end

--Update function--
save_manager.update = function()
    handle_queue()
    auto_save()
end

--Function to register additional filenames to be uses to save files--
save_manager.register_filename = function(table_name, file_name)
    save_manager.filenames[table_name] = file_name
end

return save_manager
