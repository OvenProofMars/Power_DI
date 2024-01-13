--Old module for getting player profiles, currently not needed anymore--

local mod = get_mod("Power_DI")
local utilities = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\utilities]])

local player_manager = {}
player_manager.data = {}

local function handle_queue()
    local datasources = player_manager.data.session_data and player_manager.data.session_data.datasources
    local players_table = datasources and datasources.Players
    local units_table = datasources and datasources.UnitSpawnerManager
    if players_table and utilities.in_game() and utilities.has_gameplay_timer() then
        for index, unit in ipairs(players_table.queue) do
            local player = Managers.player:player_by_unit(unit)
            if player then
                local unit_uuid = utilities.get_address(unit) 
                local player_name = player:name()
                players_table.profiles[unit_uuid] = player:profile()
                utilities.clean_table_for_saving(players_table.profiles[unit_uuid])
                units_table[unit_uuid].name = player_name
                table.remove(players_table.queue, index)
            end
        end
    end
end

player_manager.init = function(input_table)
    player_manager.data = input_table
end
player_manager.update = function()
    handle_queue()
end

return player_manager