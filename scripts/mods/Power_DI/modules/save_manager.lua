local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local PDI
local auto_save_setting = mod:get("auto_save")
local auto_save_interval = mod:get("auto_save_interval")
local save_manager = {}
save_manager.queue = {}

local auto_save_data = {}

--Function to set auto save--
save_manager.set_auto_save = function(value)
    auto_save_setting = value
end

--Function to set auto save interval--
save_manager.set_auto_save_interval = function(value)
    auto_save_interval = value
end

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
    ["game_lookup_tables"] = "game_lookup_tables_v"..APPLICATION_SETTINGS.game_version
}

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

save_manager.save_user_data = function()
    return save_manager.save("save_data", PDI.data.save_data)
end

save_manager.save_session_data = function()
    return save_manager.save("session_data", PDI.data.session_data)
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

--Function to save multiple tables at the same time, still needs promise implementation--
save_manager.save_multiple = function(input_table)
    for table_key, table_value in pairs(input_table) do
        save_manager.save(table_key, table_value)
    end
end
--Coroutine function for auto saving--
local function auto_save_coroutine()
    local auto_save_coroutine
    
    local function iterative_save()
        local data_sources = PDI.data.session_data.datasources
        for data_source_name, data_source_table in pairs(data_sources) do
            --save_manager.save("auto_save_"..data_source_name, table.clone(data_source_table))
            save_manager.save("auto_save_"..data_source_name, data_source_table)
            :next(
                function()
                    coroutine.resume(auto_save_coroutine) 
                end
            )
            coroutine:yield()
        end
    end

    auto_save_coroutine = coroutine.create(iterative_save)
    coroutine.resume(auto_save_coroutine)
    return auto_save_coroutine
end

local saved_this_cycle = false

--Function that auto saves every interval while in a mission--
local function auto_save()
    if not auto_save_setting then
        return
    end

    if not PDI.utilities.in_game() then
        return
    end

    local gameplay_time = mod.utilities.get_gameplay_time()

    if gameplay_time == 0 then
        return
    end

    local modulus = gameplay_time % (auto_save_interval+1)
    if modulus > auto_save_interval and not saved_this_cycle then
        auto_save_coroutine()
        saved_this_cycle = true
        --mod:notify("Auto save successful")
    elseif modulus < auto_save_interval then
        saved_this_cycle = false
    end
end

--Function to clear the auto save data on disk--
save_manager.clear_auto_save_cache = function ()
    auto_save_data = nil
    local data_sources = PDI.datasource_manager.registered_datasources
    for data_source_name, _ in pairs(data_sources) do
        save_manager.save("auto_save_"..data_source_name, {})
    end
end

--Function to load the auto save data from disk, async, returns a promise--
local function load_auto_save ()
    PDI.debug("load_auto_save", "start")
    local data_sources = PDI.datasource_manager.registered_datasources
    local promise_array = {}
    for data_source_name, _ in pairs(data_sources) do
        promise_array[#promise_array+1] = save_manager.load("auto_save_"..data_source_name)
        :next(
            function(data)
                PDI.debug("load_auto_save", data_source_name)
                auto_save_data[data_source_name] = data
            end
        )
    end
    return PDI.promise.all(unpack(promise_array))
end

--Function to get the local auto save data variable--
save_manager.get_loaded_auto_save_data = function()
    if not auto_save_data or not next(auto_save_data) then
        return
    end
    local has_data
    for k,v in pairs(auto_save_data) do
        if next(v) then
            has_data = true
        end
    end
    if has_data then
        return auto_save_data
    end
end

--Initialize module, loads the save data, and latest session data--
save_manager.init = function(input_table)
    PDI = input_table

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
            return save_manager.save("save_data", PDI.data.save_data)
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
            PDI.session_manager.prepare_session(data)
        end,
        function(err)
            PDI.data.session_data = PDI.session_manager.new()
            sessions = PDI.data.save_data.sessions
            table.remove(sessions_index,#sessions_index)
            sessions[session_id] = nil
            session_id = nil
            return save_manager.save("save_data", PDI.data.save_data)
        end
    )
    :next(
        function()
            if session_id then
                return load_auto_save()
            end
        end,
        function(err)
            print("------")
            DMF:dump(err)
            print("------")
        end
    )
    :next(
        function()
            promise:resolve()
        end,
        function(err)
            print("------")
            DMF:dump(err)
            print("------")
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

