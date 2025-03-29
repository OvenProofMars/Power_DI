local mod = get_mod("Power_DI")
local PDI
local session_manager = {}
session_manager.sessions = {}

--Function to generate a session id--
local function generate_session_id()
    local session_id = Managers.connection:session_id() or "local"
    return session_id
end

--Function to prepare a session for use with datasets and reports--
session_manager.prepare_session = function(session)
    PDI.dataset_manager.prepare_session(session)
    PDI.report_manager.prepare_session(session)
end

--Initialize module--
session_manager.init = function(input_table)
    PDI = input_table
end

--Function to create a new session--
session_manager.new = function()
    local save_data = PDI.data.save_data
    local session_id = generate_session_id()
    local session_index = #save_data.sessions_index+1
    local session = {}
    local state_manager = Managers.state
    local data_service_manager = Managers.data_service
    local mechanism_manager = Managers.mechanism
    local backend_mission_id = mechanism_manager and mechanism_manager:backend_mission_id()
    session.info = {}
    session.info.session_id = session_id
    session.info.game_version = APPLICATION_SETTINGS.game_version
    session.info.power_di_version = mod.version
    session.info.mission = state_manager.mission and state_manager.mission:mission()

    if backend_mission_id then
        data_service_manager.mission_board:fetch_mission(backend_mission_id)
        :next(
            function(mission_data)
                session_manager.update_current_session_info({["mission_data"] = mission_data.mission})
                session_manager.save_all_data()
                --session.info.mission_data = mission_data.mission
                --PDI.save_manager.save("save_data", PDI.data.save_data)
            end
        )
    end

    session.info.difficulty = state_manager.difficulty and state_manager.difficulty:get_initial_challenge() or nil
    --session.info.date = os.date("%d/%m/%Y")
    session.info.start_time = os.time()
    session.info.resumed = false

    if session_id ~= "local" then
        save_data.sessions[session_id] = session.info
        save_data.sessions_index[session_index] = session_id
    end

    PDI.datasource_manager.clear_cache()
    PDI.datasource_manager.add_datasources(session)
    return session
end

--Function to save the current session data to disk--
session_manager.save_all_data = function ()
    local session_id = PDI.data.session_data.info.session_id
    if session_id == "local" then
        return
    end
    local save_table = {
        ["save_data"] = PDI.data.save_data,
        ["session_data"] = PDI.data.session_data,
    }
    PDI.save_manager.save_multiple(save_table)
end

--Function to load a session by session_id, returns a promise--
session_manager.load_session = function(session_id)
    local promise = PDI.promise:new()
    PDI.save_manager.load(session_id)
    :next(
        function(data)
            PDI.data.session_data = data
            session_manager.prepare_session(data)
            promise:resolve(data)
        end
    )
    return promise
end

--Function to save the current session, mirror from save manager, returns a promise--
session_manager.save_session = function()
    return PDI.save_manager.save_session_data()
end

--Updates the current session info in the save data table--
session_manager.update_current_session_info = function(session_info)
    local save_data = PDI.data.save_data
    local session_data = PDI.data.session_data
    local session_id = session_data.info.session_id

    if session_id then
        for key, value in pairs(session_info) do
            session_data.info[key] = value
        end
        save_data.sessions[session_id] = session_data.info
    end    
end

--Function to decide to create a new session, or resume a old session due to a crash--
session_manager.resume_or_create_session = function()
    local last_session_id = PDI.data.session_data.info and PDI.data.session_data.info.session_id
    local current_session_id = generate_session_id()
    if last_session_id == current_session_id and last_session_id ~= "local" then
        local datasources = PDI.data.session_data.datasources
        local auto_save_data = PDI.save_manager.get_loaded_auto_save_data()
        if auto_save_data then
            for k,v in pairs(auto_save_data) do
                datasources[k] = v
            end
        end
        session_manager.update_current_session_info({resumed = true})
    else
        PDI.data.session_data = session_manager.new()
    end
    session_manager.prepare_session(PDI.data.session_data)

    session_manager.save_all_data()

    if current_session_id == "local" then
        local local_player = Managers.player:local_player(1)
        local local_player_name = local_player:name()
        local local_player_unit = local_player and local_player.player_unit
        local local_player_unit_uuid = local_player_unit and PDI.utilities.get_unit_uuid(local_player_unit)
        local player_profiles_datasource = PDI.data.session_data.datasources.PlayerProfiles
        local unit_spawner_manager_datasource = PDI.data.session_data.datasources.UnitSpawnerManager
        local local_player_profile = PDI.utilities.copy(local_player._profile)
        player_profiles_datasource[local_player_unit_uuid] = local_player_profile

        local temp_table = {}

        temp_table.unit_template_name = "player_character"
        temp_table.unit_name = local_player_name
        temp_table.time = 0

        unit_spawner_manager_datasource[local_player_unit_uuid] = temp_table
    end
end

--Get the currently loaded session id--
session_manager.get_loaded_session_id = function()
    local session_id = PDI.data.session_data.info and PDI.data.session_data.info.session_id
    return session_id
end

return session_manager

