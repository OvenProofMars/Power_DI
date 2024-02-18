local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local MD5 = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\libraries\md5]])
local PDI

--The async save functions only support the following data types--
local allowed_types_for_saving = {"string","boolean","number","Vector3","Vector3Box","Matrix4x4","Matrix4x4Box",}

local utilities = {}

utilities.DMF = DMF


utilities.init = function(input_table)
    PDI = input_table
end

--Function to create a uuid--
utilities.uuid = function(optional_template)
    local template = optional_template or 'xxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--Function to get the current elapsed time in a mission--
utilities.get_gameplay_time = function()
    local gameplay_timer = Managers.time:has_timer("gameplay")
    if gameplay_timer then
        return Managers.time:time("gameplay")
    else
        return 0
    end
end

--Function to check if currently in a mission--
utilities.in_game = function()
    local game_state_manager = Managers.state.game_mode
    if game_state_manager and game_state_manager:game_mode_name() ~= "hub" then
        return true
    else
        return false
    end
end

--Function to check if the mission timer has been initialized--
utilities.has_gameplay_timer = function()
    return Managers.time:has_timer("gameplay")
end

--Function to remove any data types unsupported by the save system from a table--
utilities.clean_table_for_saving = function(input_table)
    if not input_table then
        return
    end
    local t_index = {}
    local function ct(input_table)
        if not input_table then
            return
        end
        for k, v in pairs(input_table) do
            if type(v) == "table" and not t_index[v] then
                t_index[v] = k
                setmetatable(v, nil)
                ct(v)
            elseif type(v) == "Vector3" then
                input_table[k] = utilities.vector_to_string(v)
            elseif not table.array_contains(allowed_types_for_saving, type(v)) then
                input_table[k] = nil
            end
        end
    end
    ct(input_table)
end

utilities.clean_table_for_saving_2 = function(input_table)
    if not input_table then
        return
    end
    local t_index = {}
    local function ct(input_table)
        if not input_table then
            return
        end
        for k, v in pairs(input_table) do
            if type(v) == "table" and not t_index[v] then
                t_index[v] = k
                --setmetatable(v, nil)
                ct(v)
            elseif not table.array_contains(allowed_types_for_saving, type(v)) then
                input_table[k] = nil
            end
        end
    end
    ct(input_table)
end

--Function to create a copy of a table--
utilities.copy = function(input_table)
    return DMF.deepcopy(input_table)
end

--Function to create a JSON dump of a table--
utilities.dump = function(input_table, filename)
    local path = filename..".json"
    local output_string = cjson.encode(input_table)
    local file = Mods.lua.io.open(path, "w+")
    file:write(output_string)
    file:close()    
end

--Function to get the memory address of a table as a string--
utilities.get_address = function (input_table)
    return "u_"..string.format("%p", input_table)
end

--Function to get the memory address of a unit to use as an uuid--
utilities.get_unit_uuid = function(input_unit)
    if not input_unit then
        return
    end
    local unit_spawner_manager = Managers.state.unit_spawner
    local is_level_unit, level_unit_id = unit_spawner_manager:game_object_id_or_level_index(input_unit)
    local unit = unit_spawner_manager:unit(level_unit_id, is_level_unit)
    local unit_uuid

    if is_level_unit and unit then
        unit_uuid = "lu_"..string.format("%p", unit)
    else
        unit_uuid = "u_"..string.format("%p", input_unit)
    end
    return unit_uuid
end

--Function to get the position of a unit
utilities.get_position = function(input_unit)
    if not input_unit then
        return
    end

    if not Unit.alive(input_unit) then
        local game_session = Managers.state.game_session:game_session()
        local unit_spawner_manager = Managers.state.unit_spawner
        local level_unit_id = unit_spawner_manager:level_index(input_unit)
        if GameSession.has_game_object_field(game_session, level_unit_id, "position") then
            local position_vector = GameSession.game_object_field(game_session, level_unit_id, "position")
            return Vector3.to_array(position_vector)
        end
        return
    end

    local position_vector = Unit.world_position(input_unit, 1)
    return Vector3.to_array(position_vector)
end

--Function to convert a vector to a string--
utilities.vector_to_string = function(input_vector)
    return Vector3.to_array(input_vector)
end

--Function to create a proxy table--
utilities.create_proxy_table = function(input_table)
    local proxy = {}
    local mt = {
      __index = function (t,k)
        local item = rawget(input_table,k)
        if item and type(item) == "table" then
            return table.clone(item)
        elseif item then
            return(item)
        else
            return nil
        end
      end,
      __newindex = function (t,k,v)
        error("attempt to update a read-only table", 2)
      end
    }
    setmetatable(proxy, mt)
    return proxy
end

--Function to quickly check if a table is likely an array, only doing a few checks for speed--
utilities.is_array = function(input_table)
    local array_count = #input_table
    if type(input_table) ~= "table" or array_count == 0 then
        return false
    end

    local max_check = math.min(5,array_count)

    for i = 1,5,1 do
        if input_table[i] == nil then
            return false
        end
    end
    return true
end

--Function to hash a table, uses MD5--
utilities.hash = function(input_table)
    local json_string = cjson.encode(input_table)
    local hash = MD5.sumhexa(json_string)
    return hash
end

--Function to recreate the meta table for a master item--
utilities.set_master_item_meta_table = function(item_instance)
    setmetatable(item_instance, {
        __index = function (t, field_name)
            local master_ver = rawget(item_instance, "__master_ver")

            if field_name == "gear_id" then
                return rawget(item_instance, "__gear_id")
            end

            if field_name == "gear" then
                return rawget(item_instance, "__gear")
            end

            local master_item = rawget(item_instance, "__master_item")

            if not master_item then
                return nil
            end

            local field_value = master_item[field_name]

            if field_name == "rarity" and field_value == -1 then
                return nil
            end

            return field_value
        end,
        __newindex = function (t, field_name, value)

        end,
        __tostring = function (t)
            local master_item = rawget(item_instance, "__master_item")

            return string.format("master_item: [%s] gear_id: [%s]", tostring(master_item and master_item.name), tostring(rawget(item_instance, "__gear_id")))
        end
    })

    return item_instance
end

--Function to handle localization--
utilities.localize = function(input_string)
    if not input_string then
        return
    end
    local prefix = string.sub(input_string,1,4)
    if prefix == "loc_" then
        return Localize(input_string)
    else
        local localized_string = mod:localize(input_string)
        local starting_character = string.sub(localized_string,1,1)
        if starting_character == "<" then
            return input_string
        else
            return localized_string
        end
    end
end

return utilities