local mod = get_mod("Power_DI")
local utilities = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\modules\utilities]])
local SmartTag = require("scripts/extension_systems/smart_tag/smart_tag")
local remove_tags_reason_lookup = table.mirror_array_inplace(table.keys(SmartTag.REMOVE_TAG_REASONS))local datasource_templates = {}
local data_locations = {}


mod.cache.active_interactions = {}
mod.cache.active_smart_tags = {}
mod.cache.active_player_states = {}
mod.cache.player_ability_num_charges = {}
mod.cache.player_psyker_grenade_abilities = {}
mod.cache.buffs = {}

local ability_types = {"combat_ability", "grenade_ability"}
local managers_state = Managers.state
local get_unit_uuid = utilities.get_unit_uuid
local get_position = utilities.get_position
local get_gameplay_time = utilities.get_gameplay_time
local vector_to_string = utilities.vector_to_string

--Function to lookup which data location to use for the buff functions--
local buff_data_location_lookup = function (class_name)
    local lookup = {
        PlayerUnitBuffExtension = data_locations.PlayerBuffExtension(),
        PlayerHuskBuffExtension = data_locations.PlayerBuffExtension(),
        MinionBuffExtension = data_locations.MinionBuffExtension(),
    }
    return lookup[class_name]
end
--Datasource hook functions--
local add_attack_result = function (self, damage_profile, attacked_unit, attacking_unit, attack_direction, hit_world_position, hit_weakspot, damage, attack_result, attack_type, damage_efficiency, is_critical_strike)
    local output_table = data_locations.AttackReportManager()
    local attacked_unit_health_extension = attacked_unit and ScriptUnit.has_extension(attacked_unit, "health_system")

    local attack_report = {}
    
    attack_report.time = get_gameplay_time()
    attack_report.damage_profile_name = damage_profile.name
    attack_report.attacked_unit_uuid = get_unit_uuid(attacked_unit)
    attack_report.attacked_unit_damage_taken = attacked_unit_health_extension and attacked_unit_health_extension:damage_taken()
    attack_report.attacked_unit_position = get_position(attacked_unit)
    attack_report.attacking_unit_uuid = get_unit_uuid(attacking_unit)
    attack_report.attacking_unit_position = get_position(attacking_unit)
    attack_report.attack_direction = attack_direction and vector_to_string(attack_direction)
    attack_report.hit_world_position = hit_world_position and vector_to_string(hit_world_position)
    attack_report.hit_weakspot = hit_weakspot or false
    attack_report.damage = damage
    attack_report.attack_result = attack_result
    attack_report.attack_type = attack_type
    attack_report.damage_efficiency = damage_efficiency
    attack_report.is_critical_strike = is_critical_strike or false

    output_table[#output_table+1] = attack_report
end
local rpc_player_blocked_attack = function (self, channel_id, unit_id, attacking_unit_id, hit_world_position, block_broken, weapon_template_id, attack_type_id)
    local output_table = data_locations.PlayerBlockedAttacks()
    local player_unit = managers_state.unit_spawner:unit(unit_id)
    local attacking_unit = managers_state.unit_spawner:unit(attacking_unit_id)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.attacking_unit_uuid = get_unit_uuid(attacking_unit)
    temp_table.attacking_unit_position = get_position(attacking_unit)
    temp_table.weapon_template_name = NetworkLookup.weapon_templates[weapon_template_id]
    temp_table.attack_type = NetworkLookup.attack_types[attack_type_id]

    output_table[#output_table+1] = temp_table
end
local rpc_player_suppressed = function (self, channel_id, unit_id, num_suppression_hits)
    local output_table = data_locations.PlayerSuppressionExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(unit_id)
    
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.num_suppression_hits = num_suppression_hits

    output_table[#output_table+1] = temp_table
end
local rpc_interaction_started = function (self, channel_id, unit_id, is_level_unit, game_object_id)
    local output_table = data_locations.InteracteeSystem()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactor_unit = unit_spawner_manager:unit(game_object_id, false)
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
    local extension = self._unit_to_extension_map[interactee_unit]
    local interaction_type = extension:interaction_type()

    active_interactions[unit_id] = interactor_unit
    
    local temp_table ={}

    temp_table.time = get_gameplay_time()
    temp_table.event = "interaction_started"
    temp_table.interaction_type = interaction_type
    temp_table.interactor_unit_uuid = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit_uuid = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.is_level_unit = is_level_unit

    output_table[#output_table+1] = temp_table
end
local rpc_interaction_stopped = function (self, channel_id, unit_id, is_level_unit, result)
    local output_table = data_locations.InteracteeSystem()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
    local interactor_unit = active_interactions[unit_id]
    local extension = self._unit_to_extension_map[interactee_unit]
    local interaction_type = extension:interaction_type()

    active_interactions[unit_id] = nil

    local temp_table ={}

    temp_table.time = get_gameplay_time()
    temp_table.event = "interaction_stopped"
    temp_table.interaction_type = interaction_type
    temp_table.interactor_unit_uuid = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit_uuid = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.is_level_unit = self._is_level_unit
    temp_table.result = NetworkLookup.interaction_result[result]

    output_table[#output_table+1] = temp_table
end
local rpc_interaction_set_missing_player = function (self, channel_id, unit_id, is_level_unit, is_missing)
    local output_table = data_locations.InteracteeSystem()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactor_unit = active_interactions[unit_id]
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)

    local temp_table ={}

    temp_table.time = get_gameplay_time()
    temp_table.event = "interaction_set_missing_player"
    temp_table.interactor_unit_uuid = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit_uuid = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.is_level_unit = is_level_unit
    temp_table.is_missing = is_missing

    output_table[#output_table+1] = temp_table
end
local rpc_interaction_hot_join = function (self, channel_id, unit_id, is_level_unit, state, is_used, active_type_id)
    local output_table = data_locations.InteracteeSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local active_type = active_type_id ~= 0 and NetworkLookup.interaction_type_strings[active_type_id] or nil
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
    
    local temp_table ={}

    temp_table.time = get_gameplay_time()
    temp_table.event = "interaction_hot_join"
    temp_table.interactee_unit_uuid = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.is_level_unit = is_level_unit
    temp_table.active_type = active_type

    output_table[#output_table+1] = temp_table
end
local rpc_player_unit_enter_coherency = function (self, channel_id, game_object_id, enter_game_object_id)
    local output_table = data_locations.HuskCoherencyExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(game_object_id)
    local coherency_unit = unit_spawner_manager:unit(enter_game_object_id)
    local coherency_player_unit = managers_state.player_unit_spawn:owner(coherency_unit).player_unit

    local temp_table = {}

    temp_table.time = Managers.time:time("gameplay")
    temp_table.event = "enter"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.coherency_player_unit_uuid = get_unit_uuid(coherency_player_unit)
    temp_table.coherency_player_unit_position = get_position(coherency_player_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_player_unit_exit_coherency = function (self, channel_id, game_object_id, exit_game_object_id)
    local output_table = data_locations.HuskCoherencyExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(game_object_id)
    local coherency_unit = unit_spawner_manager:unit(exit_game_object_id)
    local coherency_player_unit = managers_state.player_unit_spawn:owner(coherency_unit).player_unit

    local temp_table = {}

    temp_table.time = Managers.time:time("gameplay")
    temp_table.event = "exit"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.coherency_player_unit_uuid = get_unit_uuid(coherency_player_unit)
    temp_table.coherency_player_unit_position = get_position(coherency_player_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_add_buff = function(self, channel_id, game_object_id, buff_template_id, server_index, optional_lerp_value, optional_item_slot_id, optional_parent_buff_template_id, from_specialization)

    local class_name = self.__class_name
    local output_table = buff_data_location_lookup(class_name)
    local buff_lookup_table = mod.cache.buffs
    local unit_spawner_manager = managers_state.unit_spawner
    local unit = unit_spawner_manager:unit(game_object_id)
    local unit_uuid = get_unit_uuid(unit)
    local server_index_uuid = unit_uuid.."_"..server_index

    local temp_table = {}

    temp_table.event = "add_buff"
    temp_table.unit_uuid = unit_uuid
    temp_table.unit_position = get_position(unit)
    temp_table.time = get_gameplay_time()
    
    temp_table.buff_template_id = buff_template_id
    temp_table.optional_lerp_value = optional_lerp_value
    temp_table.optional_parent_buff_id = optional_parent_buff_template_id
    temp_table.optional_item_slot_id = optional_item_slot_id
    temp_table.from_specialization = from_specialization
    temp_table.server_index = server_index

    buff_lookup_table[server_index_uuid] = temp_table
    output_table[#output_table+1] = temp_table
end
local rpc_add_buff_with_stacks = function(self, channel_id, game_object_id, buff_template_id, server_index_array, optional_lerp_value, optional_item_slot_id, optional_parent_buff_template_id)

    local class_name = self.__class_name
    local output_table = buff_data_location_lookup(class_name)
    local buff_lookup_table = mod.cache.buffs
    local unit_spawner_manager = managers_state.unit_spawner
    local unit = unit_spawner_manager:unit(game_object_id)
    local unit_uuid = get_unit_uuid(unit)
    local server_index_uuid = unit_uuid.."_"..server_index_array[1]

    local temp_table = {}

    temp_table.event = "add_buff_with_stacks"
    temp_table.unit_uuid = unit_uuid
    temp_table.unit_position = get_position(unit)
    temp_table.time = get_gameplay_time()
    
    temp_table.buff_template_id = buff_template_id
    temp_table.optional_lerp_value = optional_lerp_value
    temp_table.optional_parent_buff_id = optional_parent_buff_template_id
    temp_table.optional_item_slot_id = optional_item_slot_id

    buff_lookup_table[server_index_uuid] = temp_table
    output_table[#output_table+1] = temp_table
end
local rpc_remove_buff = function(self, channel_id, game_object_id, server_index)
    local class_name = self.__class_name
    local output_table = buff_data_location_lookup(class_name)
    local buff_lookup_table = mod.cache.buffs
    local unit_spawner_manager = managers_state.unit_spawner
    local unit = unit_spawner_manager:unit(game_object_id)
    local unit_uuid = get_unit_uuid(unit)
    local server_index_uuid = unit_uuid.."_"..server_index
    local buff_lookup = buff_lookup_table[server_index_uuid]

    if not buff_lookup then
        return
    end

    local temp_table = {}

    temp_table.event = "remove_buff"
    temp_table.unit_uuid = unit_uuid
    temp_table.unit_position = get_position(unit)
    temp_table.time = get_gameplay_time()
    
    temp_table.buff_template_id = buff_lookup.buff_template_id
    temp_table.optional_lerp_value = buff_lookup.optional_lerp_value
    temp_table.optional_parent_buff_id = buff_lookup.optional_parent_buff_template_id
    temp_table.optional_item_slot_id = buff_lookup.optional_item_slot_id
    temp_table.from_specialization = buff_lookup.from_specialization
    temp_table.server_index = server_index

    output_table[#output_table+1] = temp_table
end
local rpc_buff_proc_set_active_time = function(self, channel_id, game_object_id, server_index, activation_frame)
    local class_name = self.__class_name
    local output_table = buff_data_location_lookup(class_name)
    local buff_lookup_table = mod.cache.buffs
    local unit_spawner_manager = managers_state.unit_spawner
    local unit = unit_spawner_manager:unit(game_object_id)
    local unit_uuid = get_unit_uuid(unit)
    local server_index_uuid = unit_uuid.."_"..server_index
    local buff_lookup = buff_lookup_table[server_index_uuid]

    if not buff_lookup then
        return
    end

    local temp_table = {}

    temp_table.event = "buff_proc_set_active_time"
    temp_table.unit_uuid = unit_uuid
    temp_table.unit_position = get_position(unit)
    temp_table.time = get_gameplay_time()
    
    temp_table.buff_template_id = buff_lookup.buff_template_id
    temp_table.optional_lerp_value = buff_lookup.optional_lerp_value
    temp_table.optional_parent_buff_id = buff_lookup.optional_parent_buff_template_id
    temp_table.optional_item_slot_id = buff_lookup.optional_item_slot_id
    temp_table.from_specialization = buff_lookup.from_specialization
    temp_table.activation_frame = activation_frame

    output_table[#output_table+1] = temp_table
end
local rpc_buff_set_start_time = function(self, channel_id, game_object_id, server_index, activation_frame)
    local class_name = self.__class_name
    local output_table = buff_data_location_lookup(class_name)
    local buff_lookup_table = mod.cache.buffs
    local unit_spawner_manager = managers_state.unit_spawner
    local unit = unit_spawner_manager:unit(game_object_id)
    local unit_uuid = get_unit_uuid(unit)
    local server_index_uuid = unit_uuid.."_"..server_index
    local buff_lookup = buff_lookup_table[server_index_uuid]

    if not buff_lookup then
        return
    end
    
    local temp_table = {}

    temp_table.event = "buff_set_start_time"
    temp_table.unit_uuid = unit_uuid
    temp_table.unit_position = get_position(unit)
    temp_table.time = get_gameplay_time()
    
    temp_table.buff_template_id = buff_lookup.buff_template_id
    temp_table.optional_lerp_value = buff_lookup.optional_lerp_value
    temp_table.optional_parent_buff_id = buff_lookup.optional_parent_buff_template_id
    temp_table.optional_item_slot_id = buff_lookup.optional_item_slot_id
    temp_table.from_specialization = buff_lookup.from_specialization
    temp_table.activation_frame = activation_frame

    output_table[#output_table+1] = temp_table
end
local rpc_player_collected_materials = function(self, channel_id, peer_id, material_type_lookup, material_size_lookup)
    local output_table = data_locations.PickupSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local player = Managers.player:player(peer_id, 1)
    local player_unit = player.player_unit
    
    local temp_table = {}

    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.time = get_gameplay_time()
    temp_table.material_type = NetworkLookup.material_type_lookup[material_type_lookup]
    temp_table.material_size = NetworkLookup.material_size_lookup[material_size_lookup]

    output_table[#output_table+1] = temp_table
end
local add_network_unit = function(self, unit, game_object_id, is_husk)
    local go_field = GameSession.game_object_field
    local has_go_field = GameSession.has_game_object_field
    local output_table = data_locations.UnitSpawnerManager()
    local game_session = managers_state.game_session:game_session()
    local unit_spawner_manager = managers_state.unit_spawner
    local unit_template_name = self._unit_template_network_lookup[go_field(game_session, game_object_id, "unit_template")]
    local unit_uuid = utilities.get_address(unit)
    local unit_name, max_health, owner_unit
    
    if unit_template_name == "player_character" then
        local owner_peer_id = go_field(game_session, game_object_id, "owner_peer_id")     
        local local_player_id = go_field(game_session, game_object_id, "local_player_id")
        local player_target = owner_peer_id and Managers.player:player(owner_peer_id, local_player_id)
        if player_target:is_human_controlled() then
            local player_profile = player_target:profile()
            local players_table = data_locations.PlayerProfiles()
            players_table[unit_uuid] = utilities.copy(player_profile)
            unit_name = player_profile and player_profile.name
            utilities.clean_table_for_saving(players_table[unit_uuid])
        end
    elseif has_go_field(game_session, game_object_id, "breed_id") then
        local breed_id = go_field(game_session, game_object_id, "breed_id")
        unit_name = NetworkLookup.breed_names[breed_id]
    elseif has_go_field(game_session, game_object_id, "pickup_id") then
        local pickup_id = go_field(game_session, game_object_id, "pickup_id")
        unit_name = NetworkLookup.pickup_names[pickup_id]
    elseif has_go_field(game_session, game_object_id, "prop_id") then
        local prop_id = go_field(game_session, game_object_id, "prop_id")
		unit_name = NetworkLookup.level_props_names[prop_id]
    end
    if has_go_field(game_session, game_object_id, "health") then
        max_health = go_field(game_session, game_object_id, "health")
    end
    if has_go_field(game_session, game_object_id, "owner_unit_id") then
        local owner_unit_id = go_field(game_session, game_object_id, "owner_unit_id")
        owner_unit = unit_spawner_manager:unit(owner_unit_id)
    end

    local temp_table = {}
    temp_table.time = get_gameplay_time()
    temp_table.unit_template_name = unit_template_name
    temp_table.unit_name = unit_name
    temp_table.unit_position = get_position(unit)
    temp_table.max_health = max_health
    temp_table.owner_unit_uuid = owner_unit and get_unit_uuid(owner_unit)
    temp_table.owner_unit_position = owner_unit and get_position(owner_unit)

    output_table[unit_uuid] = temp_table
end
local rpc_start_boss_encounter = function(self, channel_id, unit_id)
    local output_table = data_locations.BossSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local boss_unit = unit_spawner_manager:unit(unit_id)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.boss_unit_uuid = get_unit_uuid(boss_unit)
    temp_table.boss_unit_position = get_position(boss_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_start_pickup_animation = function (self, channel_id, pickup_id, pickup_is_level_unit, end_id, end_is_level_unit)
    local output_table = data_locations.PickupAnimationSystem()
	local unit_spawner_manager = managers_state.unit_spawner
	local pickup_unit = unit_spawner_manager:unit(pickup_id, pickup_is_level_unit)
	local player_unit = unit_spawner_manager:unit(end_id, end_is_level_unit)

	local temp_table = {}
    
    temp_table.time = get_gameplay_time()
    temp_table.event = "start_pickup_animation"
    temp_table.pickup_unit_uuid = get_unit_uuid(pickup_unit)
    temp_table.pickup_unit_position = get_position(pickup_unit)
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_start_place_animation = function (self, channel_id, pickup_id, pickup_is_level_unit, end_id, end_is_level_unit)
    local output_table = data_locations.PickupAnimationSystem()
	local unit_spawner_manager = managers_state.unit_spawner
	local pickup_unit = unit_spawner_manager:unit(pickup_id, pickup_is_level_unit)
	local player_unit = unit_spawner_manager:unit(end_id, end_is_level_unit)

	local temp_table = {}
    
    temp_table.time = get_gameplay_time()
    temp_table.event = "start_place_animation"
    temp_table.pickup_unit_uuid = get_unit_uuid(pickup_unit)
    temp_table.pickup_unit_position = get_position(pickup_unit)
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_luggable_socket_luggable = function (self, channel_id, socket_id, socket_is_level_unit, socketed_id, socketed_is_level_unit)
    local output_table = data_locations.LuggableSocketSystem()
    local unit_spawner_manager = managers_state.unit_spawner
	local socket_unit = unit_spawner_manager:unit(socket_id, socket_is_level_unit)
	local socketed_unit = unit_spawner_manager:unit(socketed_id, socketed_is_level_unit)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "luggable_socket_luggable"
    temp_table.socket_unit_uuid = get_unit_uuid(socket_unit)
    temp_table.socket_unit_position = get_position(socket_unit)
    temp_table.socketed_unit_uuid = get_unit_uuid(socketed_unit)
    temp_table.socketed_unit_position = get_position(socketed_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_luggable_socket_unlock = function (self, channel_id, socket_id, socket_is_level_unit)
    local output_table = data_locations.LuggableSocketSystem()
    local unit_spawner_manager = managers_state.unit_spawner
	local socket_unit = unit_spawner_manager:unit(socket_id, socket_is_level_unit)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "luggable_socket_unlock"
    temp_table.socket_unit_uuid = get_unit_uuid(socket_unit)
    temp_table.socket_unit_position = get_position(socket_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_luggable_socket_set_visibility = function (self, channel_id, socket_id, socket_is_level_unit, value)
    local output_table = data_locations.LuggableSocketSystem()
    local unit_spawner_manager = managers_state.unit_spawner
	local socket_unit = unit_spawner_manager:unit(socket_id, socket_is_level_unit)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "luggable_socket_set_visibility"
    temp_table.socket_unit_uuid = get_unit_uuid(socket_unit)
    temp_table.socket_unit_position = get_position(socket_unit)
    temp_table.value = value

    output_table[#output_table+1] = temp_table
end
local rpc_player_wield_slot = function(self, channel_id, go_id, slot_id)
    local output_table = data_locations.VisualLoadoutSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(go_id)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_wield_slot"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.slot_name = NetworkLookup.player_inventory_slot_names[slot_id]

    output_table[#output_table+1] = temp_table
end
local rpc_player_unwield_slot = function(self, channel_id, go_id, slot_id)
    local output_table = data_locations.VisualLoadoutSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(go_id)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_unwield_slot"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.slot_name = NetworkLookup.player_inventory_slot_names[slot_id]

    output_table[#output_table+1] = temp_table
end
local on_slot_wielded = function(self, slot_name, t, skip_wield_action)
    local output_table = data_locations.VisualLoadoutSystem()
    local player_unit = self._unit

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_wield_slot_local"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.slot_name = slot_name

    output_table[#output_table+1] = temp_table
end
local on_slot_unwielded = function(self, slot_name, t)
    local output_table = data_locations.VisualLoadoutSystem()
    local player_unit = self._unit

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_unwield_slot_local"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.slot_name = slot_name

    output_table[#output_table+1] = temp_table
end
local rpc_player_equip_item_from_profile_to_slot = function(self, channel_id, go_id, slot_id, item_id)
    local output_table = data_locations.PlayerHuskVisualLoadoutExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(go_id)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_equip_item_from_profile_to_slot"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.slot_name = NetworkLookup.player_inventory_slot_names[slot_id]
    temp_table.item_name = NetworkLookup.player_item_names[item_id]

    output_table[#output_table+1] = temp_table
end
local rpc_player_equip_item_to_slot = function(self, channel_id, go_id, slot_id, item_id, optional_existing_unit_3p_id)
    local output_table = data_locations.PlayerHuskVisualLoadoutExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(go_id)
    local optional_existing_unit_3p = unit_spawner_manager:unit(optional_existing_unit_3p_id)

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_equip_item_to_slot"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.optional_existing_unit_3p_uuid = optional_existing_unit_3p and get_unit_uuid(optional_existing_unit_3p)
    temp_table.optional_existing_unit_3p_position = optional_existing_unit_3p and get_position(optional_existing_unit_3p)
    temp_table.slot_name = NetworkLookup.player_inventory_slot_names[slot_id]
    temp_table.item_name = NetworkLookup.player_item_names[item_id]

    output_table[#output_table+1] = temp_table
end
local rpc_player_unequip_item_from_slot = function(self, channel_id, go_id, slot_id)
    local output_table = data_locations.PlayerHuskVisualLoadoutExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local player_unit = unit_spawner_manager:unit(go_id)
    local slot_name = NetworkLookup.player_inventory_slot_names[slot_id]
    local equipment = self._equipment
    local slot = equipment[slot_name]
    local item_name = slot.item

    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "player_unequip_item_from_slot"
    temp_table.player_unit_uuid = get_unit_uuid(player_unit)
    temp_table.player_unit_position = get_position(player_unit)
    temp_table.slot_name = slot_name
    temp_table.item_name = item_name

    output_table[#output_table+1] = temp_table
end
local rpc_health_station_use = function(self, channel_id, level_unit_id)
    local output_table = data_locations.HealthStationSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local health_station_unit = unit_spawner_manager:unit(level_unit_id, true)
    
    local temp_table ={}

    temp_table.time = get_gameplay_time()
    temp_table.event = "health_station_use"
    temp_table.health_station_unit_uuid = get_unit_uuid(health_station_unit)
    temp_table.health_station_unit_position = get_position(health_station_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_health_station_on_socket_spawned = function(self, channel_id, level_unit_id, socket_object_id)
    local output_table = data_locations.HealthStationSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local health_station_unit = unit_spawner_manager:unit(level_unit_id, true)
    local socket_unit = unit_spawner_manager:unit(socket_object_id, false)
   
    local temp_table ={}

    temp_table.time = get_gameplay_time()
    temp_table.event = "health_station_on_socket_spawned"
    temp_table.health_station_unit_uuid = get_unit_uuid(health_station_unit)
    temp_table.health_station_unit_position = get_position(health_station_unit)
    temp_table.socket_unit_uuid = get_unit_uuid(socket_unit)
    temp_table.socket_unit_position = get_position(socket_unit)

    output_table[#output_table+1] = temp_table
end
-- local rpc_health_station_on_battery_spawned = function(self, channel_id, level_unit_id, battery_id, battery_is_level_unit)
--     local output_table = data_locations.HealthStationSystem()
--     local unit_spawner_manager = managers_state.unit_spawner
--     local health_station_unit = unit_spawner_manager:unit(level_unit_id, true)
--     local battery_unit = unit_spawner_manager:unit(battery_id, battery_is_level_unit)
   
--     local temp_table ={}

--     temp_table.time = get_gameplay_time()
--     temp_table.event = "health_station_on_battery_spawned"
--     temp_table.health_station_unit_uuid = get_unit_uuid(health_station_unit)
--     temp_table.health_station_unit_position = get_position(health_station_unit)
--     temp_table.battery_unit_uuid = get_unit_uuid(battery_unit)
--     temp_table.battery_unit_position = get_position(battery_unit)

--     output_table[#output_table+1] = temp_table

-- end
local rpc_health_station_sync_charges = function(self, channel_id, level_unit_id, charge_amount)
    local output_table = data_locations.HealthStationSystem()
    local unit_spawner_manager = managers_state.unit_spawner
    local health_station_unit = unit_spawner_manager:unit(level_unit_id, true)

    local temp_table ={}
    
    temp_table.time = get_gameplay_time()
    temp_table.event = "health_station_sync_charges"
    temp_table.health_station_unit_uuid = get_unit_uuid(health_station_unit)
    temp_table.health_station_unit_position = get_position(health_station_unit)
    temp_table.charge_amount = charge_amount

    output_table[#output_table+1] = temp_table
end
local rpc_health_station_hot_join = function (self, channel_id, level_unit_id, charge_amount, socket_object_id, battery_id, battery_is_level_unit)
    local output_table = data_locations.HealthStationSystem()
    local unit_spawner_manager = managers_state.unit_spawner
	local health_station_unit = unit_spawner_manager:unit(level_unit_id, true)
	local socket_unit
    local battery_unit

	if socket_object_id ~= NetworkConstants.invalid_game_object_id then
		socket_unit = unit_spawner_manager:unit(socket_object_id, false)
	end
	if unit_spawner_manager:valid_unit_id(battery_id, battery_is_level_unit) then
		battery_unit = unit_spawner_manager:unit(battery_id, battery_is_level_unit)
	end

    local temp_table ={}
    temp_table.time = get_gameplay_time()
    temp_table.event = "health_station_hot_join"
    temp_table.health_station_unit_uuid = get_unit_uuid(health_station_unit)
    temp_table.health_station_unit_position = get_position(health_station_unit)
    temp_table.socket_unit_uuid = get_unit_uuid(socket_unit)
    temp_table.socket_unit_position = get_position(socket_unit)
    temp_table.battery_unit_uuid = get_unit_uuid(battery_unit)
    temp_table.battery_unit_position = get_position(battery_unit)
    temp_table.charge_amount = charge_amount

    output_table[#output_table+1] = temp_table
end
local rpc_servo_skull_do_pulse_fx = function (self, channel_id, game_object_id)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
	local interactee_unit = unit_spawner_manager:unit(game_object_id, false)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "servo_skull_do_pulse_fx"
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_servo_skull_player_nearby = function (self, channel_id, game_object_id, player_nearby)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
	local interactee_unit = unit_spawner_manager:unit(game_object_id, false)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "servo_skull_player_nearby"
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.unit_position = get_position(interactee_unit)
    temp_table.player_nearby = tostring(player_nearby)

    output_table[#output_table+1] = temp_table
end
local rpc_servo_skull_activator_set_visibility = function (self, channel_id, level_unit_id, value)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
	local interactee_unit = unit_spawner_manager:unit(level_unit_id, true)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "servo_skull_activator_set_visibility"
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.visible = value

    output_table[#output_table+1] = temp_table
end
local rpc_servo_skull_set_scanning_active = function (self, channel_id, game_object_id, active)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
	local interactee_unit = unit_spawner_manager:unit(game_object_id, false)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "servo_skull_set_scanning_active"
    temp_table.interactee_unit_uuid = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.active = active

    output_table[#output_table+1] = temp_table
end
-- local rpc_minigame_hot_join = function (self, channel_id, unit_id, is_level_unit, state_id)
--     local output_table = data_locations.ServoSkullEvents()
--     local unit_spawner_manager = managers_state.unit_spawner
-- 	local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
--     local temp_table = {}

--     temp_table.time = get_gameplay_time()
--     temp_table.event = "minigame_hot_join"
--     temp_table.interactee_unit = get_unit_uuid(interactee_unit)
--     temp_table.interactee_unit_position = get_position(interactee_unit)
--     temp_table.state = NetworkLookup.minigame_states[state_id]

--     output_table[#output_table+1] = temp_table
-- end
local rpc_minigame_sync_start = function (self, channel_id, unit_id, is_level_unit)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "minigame_sync_start"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_minigame_sync_stop = function (self, channel_id, unit_id, is_level_unit)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "minigame_sync_stop"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_minigame_sync_completed = function (self, channel_id, unit_id, is_level_unit)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, is_level_unit)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "minigame_sync_completed"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactor_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_decoder_device_hot_join = function (self, channel_id, unit_id, unit_is_enabled, is_placed, started_decode, decoding_interrupted, is_finished)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
	local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "decoder_device_hot_join"
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.unit_is_enabled = unit_is_enabled
    temp_table.is_placed = is_placed
    temp_table.started_decode = started_decode
    temp_table.decoding_interrupted = decoding_interrupted
    temp_table.is_finished = is_finished

    output_table[#output_table+1] = temp_table
end
local rpc_decoder_device_enable_unit = function (self, channel_id, unit_id)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
	local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "decoder_device_enable_unit"
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_decoder_device_place_unit = function (self, channel_id, unit_id)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "decoder_device_place_unit"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_decoder_device_start_decode = function (self, channel_id, unit_id)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "decoder_device_start_decode"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_decoder_device_decode_interrupt = function (self, channel_id, unit_id)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "decoder_device_decode_interrupt"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_decoder_device_finished = function (self, channel_id, unit_id)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "decoder_device_finished"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_scanning_device_finished = function (self, channel_id, unit_id)
    local output_table = data_locations.ServoSkullEvents()
    local active_interactions = mod.cache.active_interactions
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local interactor_unit_id = active_interactions[unit_id]
    local interactor_unit = interactor_unit_id and unit_spawner_manager:unit(interactor_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "scanning_device_finished"
    temp_table.interactor_unit = get_unit_uuid(interactor_unit)
    temp_table.interactor_unit_position = get_position(interactor_unit)
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)

    output_table[#output_table+1] = temp_table
end
local rpc_scanning_device_hot_join = function (self, channel_id, unit_id, past_spline_start_position, at_end_position, reached_end_of_spline)
    local output_table = data_locations.ServoSkullEvents()
    local unit_spawner_manager = managers_state.unit_spawner
    local interactee_unit = unit_spawner_manager:unit(unit_id, true)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "scanning_device_finished"
    temp_table.interactee_unit = get_unit_uuid(interactee_unit)
    temp_table.interactee_unit_position = get_position(interactee_unit)
    temp_table.past_spline_start_position = past_spline_start_position and tostring(past_spline_start_position)
    temp_table.at_end_position = at_end_position and tostring(at_end_position)
    temp_table.reached_end_of_spline = reached_end_of_spline and tostring(reached_end_of_spline)

    output_table[#output_table+1] = temp_table
end
local rpc_set_smart_tag = function (self, channel_id, tag_id, template_name_id, tagger_game_object_id, target_game_object_id, target_level_index, target_location)
    local output_table = data_locations.SmartTagSystem()
    local active_smart_tags = mod.cache.active_smart_tags
	local unit_spawner_manager = managers_state.unit_spawner
    local template_name = NetworkLookup.smart_tag_templates[template_name_id]
	local tagger_unit = tagger_game_object_id and unit_spawner_manager:unit(tagger_game_object_id)
	local target_unit
    local temp_table = {}

    local taget_unit_is_level_unit

	if target_game_object_id then
        taget_unit_is_level_unit = false
		target_unit = unit_spawner_manager:unit(target_game_object_id, taget_unit_is_level_unit)
	elseif target_level_index then
        taget_unit_is_level_unit = true
		target_unit = unit_spawner_manager:unit(target_level_index, taget_unit_is_level_unit)
    end

    local tagger_unit_uuid = tagger_unit and get_unit_uuid(tagger_unit)
    local target_unit_uuid = target_unit and get_unit_uuid(target_unit)
    
    temp_table.time = get_gameplay_time()
    temp_table.event = "set_smart_tag"
    temp_table.tagger_unit_uuid = tagger_unit_uuid
    --temp_table.tagger_unit_position = tagger_unit and get_position(tagger_unit)
    temp_table.target_unit_uuid = target_unit_uuit
    --temp_table.target_unit_position = target_unit and get_position(target_unit)
    temp_table.template_name = template_name

    output_table[#output_table+1] = temp_table

    local active_smart_tag = {}

    active_smart_tag.template_name = template_name
    active_smart_tag.tagger_unit = tagger_unit
    active_smart_tag.tagger_unit_uuid = tagger_unit_uuid
    active_smart_tag.target_unit = target_unit
    active_smart_tag.target_unit_uuid = target_unit_uuid
   
    active_smart_tags[tag_id] = active_smart_tag
end
local rpc_set_smart_tag_hot_join = function (self, channel_id, tag_id, template_name_id, tagger_game_object_id, target_game_object_id, target_level_index, target_location, replier_array, reply_name_id_array)
    local output_table = data_locations.SmartTagSystem()
    local active_smart_tags = mod.cache.active_smart_tags
	local unit_spawner_manager = managers_state.unit_spawner
    local template_name = NetworkLookup.smart_tag_templates[template_name_id]
	local tagger_unit = tagger_game_object_id and unit_spawner_manager:unit(tagger_game_object_id)
	local target_unit
    local temp_table = {}
    local replies = {}

	if target_game_object_id then
		target_unit = unit_spawner_manager:unit(target_game_object_id, false)
	elseif target_level_index then
		target_unit = unit_spawner_manager:unit(target_level_index, true)
	end

	for i = 1, #replier_array do
		local replier_game_object_id = replier_array[i]
		local replier_unit = unit_spawner_manager:unit(replier_game_object_id)
        local replier_unit_uuid = get_unit_uuid(replier_unit)
		local reply_name_id = reply_name_id_array[i]
		local reply_name = NetworkLookup.smart_tag_replies[reply_name_id]
		replies[replier_unit_uuid] = reply_name
	end

    local tagger_unit_uuid = tagger_unit and get_unit_uuid(tagger_unit)
    local target_unit_uuid = target_unit and get_unit_uuid(target_unit)

    temp_table.time = get_gameplay_time()
    temp_table.event = "set_smart_tag_hot_join"
    temp_table.tag_id = tag_id
    temp_table.tagger_unit_uuid = tagger_unit_uuid
    --temp_table.tagger_unit_position = tagger_unit and get_position(tagger_unit)
    temp_table.target_unit_uuid = target_unit_uuid
    --temp_table.target_unit_position = target_unit and get_position(target_unit)
    temp_table.template_name = template_name
    temp_table.replies = replies

    output_table[#output_table+1] = temp_table

    local active_smart_tag = {}
    
    active_smart_tag.template_name = template_name
    active_smart_tag.tagger_unit = tagger_unit
    active_smart_tag.tagger_unit_uuid = tagger_unit_uuid
    active_smart_tag.target_unit = target_unit
    active_smart_tag.target_unit_uuid = target_unit_uuid
   
    active_smart_tags[tag_id] = active_smart_tag
end
local rpc_remove_smart_tag = function (self, channel_id, tag_id, reason_id)
    local output_table = data_locations.SmartTagSystem()
    local active_smart_tags = mod.cache.active_smart_tags
    local active_smart_tag = active_smart_tags and active_smart_tags[tag_id]
	local tagger_unit = active_smart_tag and active_smart_tag.tagger_unit
    local tagger_unit_uuid = active_smart_tag and active_smart_tag.tagger_unit_uuid
    local target_unit = active_smart_tag and active_smart_tag.target_unit
    local target_unit_uuid = active_smart_tag and active_smart_tag.target_unit_uuid
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "remove_smart_tag"
    temp_table.tag_id = tag_id
    temp_table.tagger_unit_uuid = tagger_unit_uuid
    --temp_table.tagger_unit_position = tagger_unit and get_position(tagger_unit)
    temp_table.target_unit_uuid = target_unit_uuid
    --temp_table.target_unit_position = target_unit and get_position(target_unit)
    temp_table.template_name = active_smart_tag and active_smart_tag.template_name
    temp_table.reason = remove_tags_reason_lookup[reason_id]

    output_table[#output_table+1] = temp_table

    active_smart_tags[tag_id] = nil
end
local rpc_smart_tag_reply = function (self, channel_id, tag_id, replier_game_object_id, reply_name_id)
    local output_table = data_locations.SmartTagSystem()
    local active_smart_tags = mod.cache.active_smart_tags
    local active_smart_tag = active_smart_tags and active_smart_tags[tag_id]
    local replier_unit = managers_state.unit_spawner:unit(replier_game_object_id)
	local tagger_unit = active_smart_tag and active_smart_tag.tagger_unit
    local tagger_unit_uuid = active_smart_tag and active_smart_tag.tagger_unit_uuid
    local target_unit = active_smart_tag and active_smart_tag.target_unit
    local target_unit_uuid = active_smart_tag and active_smart_tag.target_unit_uuid
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.event = "smart_tag_reply"
    temp_table.tag_id = tag_id

    temp_table.tagger_unit_uuid = tagger_unit_uuid
    --temp_table.tagger_unit_position = get_position(tagger_unit)
    temp_table.target_unit_uuid = target_unit_uuid
    --temp_table.target_unit_position = get_position(target_unit)
    temp_table.template_name = active_smart_tag and active_smart_tag.template_name
    temp_table.replier_unit_uuid = get_unit_uuid(replier_unit)
    --temp_table.replier_unit_position = get_position(replier_unit)

    output_table[#output_table+1] = temp_table
end
local PUME_update = function (self, unit, dt, t)
    local output_table = data_locations.PlayerUnitStatus()
    local active_player_states = mod.cache.active_player_states
    local unit_data_extension = self._unit_data_extension
    local character_state_component = self._character_state_read_component
    local disabled_character_state_component = unit_data_extension:read_component("disabled_character_state")
    local state_name = character_state_component.state_name
    local unit_uuid = get_unit_uuid(unit)

    if active_player_states[unit_uuid] ~= state_name then
        local temp_table = {}

        temp_table.time = get_gameplay_time()
        temp_table.player_unit_uuid = unit_uuid
        temp_table.player_unit_position = get_position(unit)
        temp_table.state_name = state_name
        temp_table.previous_state_name = active_player_states[unit_uuid]
        if disabled_character_state_component and disabled_character_state_component.disabling_unit then
            local disabling_unit = disabled_character_state_component.disabling_unit
            temp_table.disabling_unit_uuid = get_unit_uuid(disabling_unit)
            temp_table.disabling_unit_position = get_position(disabling_unit)
        end
        
        output_table[#output_table+1] = temp_table
        active_player_states[unit_uuid] = state_name
    end

    local weapon_action_component = unit_data_extension:read_component("weapon_action")
    local template_name = weapon_action_component.template_name

    if template_name == "psyker_smite" or template_name == "psyker_chain_lightning" then
        local current_action_name = weapon_action_component.current_action_name
        local player_psyker_grenade_abilities = mod.cache.player_psyker_grenade_abilities
        local last_frame_action_name = player_psyker_grenade_abilities[unit_uuid]

        if last_frame_action_name ~= current_action_name then
            if current_action_name == "action_use_power" or current_action_name == "action_spread_charged" then
                local output_table = data_locations.PlayerAbilities()
                local temp_table = {}

                temp_table.player_unit_uuid = unit_uuid
                temp_table.ability_type = "grenade_ability"
                temp_table.player_unit_position = get_position(unit)
                temp_table.charge_delta = -1
                temp_table.time = get_gameplay_time()

                output_table[#output_table+1] = temp_table
            end
            player_psyker_grenade_abilities[unit_uuid] = current_action_name
        end
    end
end
local rpc_trigger_timed_mood = function (self, channel_id, go_id, mood_type_id)
    local output_table = data_locations.PlayerUnitMoodExtension()
    local unit_spawner_manager = managers_state.unit_spawner
    local unit = unit_spawner_manager:unit(go_id)
	local mood_type = NetworkLookup.moods_types[mood_type_id]
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.player_unit_uuid = get_unit_uuid(unit)
    temp_table.player_unit_position = get_position(unit)
    temp_table.mood_type = mood_type

    output_table[#output_table+1] = temp_table
end
local rpc_minion_set_dead = function (self, channel_id, unit_id, attack_direction, hit_zone_id, damage_profile_id, do_ragdoll_push, herding_template_id_or_nil)
	local output_table = data_locations.MinionDeathManager()
    local unit = managers_state.unit_spawner:unit(unit_id)
	local hit_zone_name = hit_zone_id and NetworkLookup.hit_zones[hit_zone_id]
	local damage_profile_name = NetworkLookup.damage_profile_templates[damage_profile_id]
	local herding_template_name = herding_template_id_or_nil and NetworkLookup.herding_templates[herding_template_id_or_nil]
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.unit_uuid = get_unit_uuid(unit)
    temp_table.unit_position = get_position(unit)
    temp_table.hit_zone_name = hit_zone_name
    temp_table.damage_profile_name = damage_profile_name
    temp_table.herding_template_name = herding_template_name
    output_table[#output_table+1] = temp_table
end
local rpc_server_reported_unit_suppression = function (self, channel_id, suppressed_unit_id, is_suppressed)
    local output_table = data_locations.MinionSuppressionHuskExtension()
    local unit = managers_state.unit_spawner:unit(suppressed_unit_id)
    local temp_table = {}

    temp_table.time = get_gameplay_time()
    temp_table.unit_uuid = get_unit_uuid(unit)
    temp_table.unit_position = get_position(unit)
    temp_table.is_suppressed = is_suppressed
    output_table[#output_table+1] = temp_table
end
local PlayerAbilityExtensionUpdate = function(self, unit, dt, t)
    for _, ability_type in ipairs(ability_types) do
        local enabled = self:ability_enabled(ability_type)
        if enabled then
            local player_unit_uuid = get_unit_uuid(unit)
            local player_ability_num_charges = mod.cache.player_ability_num_charges
            local lookup_string = ability_type.."_"..player_unit_uuid
            local previous_num_charges = player_ability_num_charges[lookup_string] or 0
            local ability_components = self._ability_components or self._components
            local component = ability_components[ability_type]
            local current_num_charges = component.num_charges

            if previous_num_charges ~= current_num_charges then
                local output_table = data_locations.PlayerAbilities()
                local temp_table = {}

                temp_table.player_unit_uuid = player_unit_uuid
                temp_table.ability_type = ability_type
                temp_table.player_unit_position = get_position(unit)
                temp_table.charge_delta = current_num_charges - previous_num_charges
                temp_table.time = get_gameplay_time()

                output_table[#output_table+1] = temp_table
                player_ability_num_charges[lookup_string] = current_num_charges
            end
        end
    end
end

--Datasource template array--
datasource_templates = {
    {   name = "AttackReportManager",
        hook_templates = {
            {
                hook_class = CLASS.AttackReportManager,
                hook_functions = {
                    add_attack_result = add_attack_result,
                },
            },
        },
    },
    {   name = "PlayerBlockedAttacks",
        hook_templates = {
            {
                hook_class = CLASS.WeaponSystem,
                hook_functions = {
                    rpc_player_blocked_attack = rpc_player_blocked_attack,
                },
            },
        },
    },
    {   name = "PlayerSuppressionExtension",
        hook_templates = {
            {
                hook_class = CLASS.PlayerSuppressionExtension,
                hook_functions = {
                    rpc_player_suppressed = rpc_player_suppressed,
                },
            },
        },
    },
    {   name = "InteracteeSystem",
        hook_templates = {
            {
                hook_class = CLASS.InteracteeSystem,
                hook_functions = {
                    rpc_interaction_started = rpc_interaction_started,
                    rpc_interaction_stopped = rpc_interaction_stopped,
                    rpc_interaction_set_missing_player = rpc_interaction_set_missing_player,
                    rpc_interaction_hot_join = rpc_interaction_hot_join,
                },
            },
        },
    },
    {   name = "HuskCoherencyExtension",
        hook_templates = {
            {
                hook_class = CLASS.HuskCoherencyExtension,
                hook_functions = {
                    rpc_player_unit_enter_coherency = rpc_player_unit_enter_coherency,
                    rpc_player_unit_exit_coherency = rpc_player_unit_exit_coherency,
                },
            },
        },
    },
    {   name = "PlayerBuffExtension",
        hook_templates = {
            {
                hook_class = CLASS.PlayerUnitBuffExtension,
                hook_functions = {
                    rpc_add_buff = rpc_add_buff,
                    rpc_add_buff_with_stacks = rpc_add_buff_with_stacks,
                    rpc_remove_buff = rpc_remove_buff,
                    rpc_buff_proc_set_active_time = rpc_buff_proc_set_active_time,
                    rpc_buff_set_start_time = rpc_buff_set_start_time,
                },
            },
            {
                hook_class = CLASS.PlayerHuskBuffExtension,
                hook_functions = {
                    rpc_add_buff = rpc_add_buff,
                    rpc_remove_buff = rpc_remove_buff,
                    rpc_buff_proc_set_active_time = rpc_buff_proc_set_active_time,
                    rpc_buff_set_start_time = rpc_buff_set_start_time,
                },
            },
        },
    },
    {   name = "MinionBuffExtension",
        hook_templates = {
            {
                hook_class = CLASS.MinionBuffExtension,
                hook_functions = {
                    rpc_add_buff = rpc_add_buff,
                    rpc_add_buff_with_stacks = rpc_add_buff_with_stacks,
                    rpc_remove_buff = rpc_remove_buff,
                    rpc_buff_proc_set_active_time = rpc_buff_proc_set_active_time,
                    rpc_buff_set_start_time = rpc_buff_set_start_time,
                },
            },
        },
    },
    {   name = "UnitSpawnerManager",
        hook_templates = {
            {
                hook_class = CLASS.UnitSpawnerManager,
                hook_functions = {
                    _add_network_unit = add_network_unit,
                },
            },
        },
    },
    {   name = "PlayerProfiles",
        hook_templates = {},
    },
    {   name = "PickupSystem",
        hook_templates = {
            {
                hook_class = CLASS.PickupSystem,
                hook_functions = {
                    rpc_player_collected_materials = rpc_player_collected_materials,
                },
            },
        },
    },
    {   name = "BossSystem",
        hook_templates = {
            {
                hook_class = CLASS.BossSystem,
                hook_functions = {
                    rpc_start_boss_encounter = rpc_start_boss_encounter,
                },
            },
        },
    },
    {   name = "PickupAnimationSystem",
        hook_templates = {
            {
                hook_class = CLASS.PickupAnimationSystem,
                hook_functions = {
                    rpc_start_pickup_animation = rpc_start_pickup_animation,
                    rpc_start_place_animation = rpc_start_place_animation,
                },
            },
        },
    },
    {   name = "LuggableSocketSystem",
        hook_templates = {
            {
                hook_class = CLASS.LuggableSocketSystem,
                hook_functions = {
                    rpc_luggable_socket_luggable = rpc_luggable_socket_luggable,
                    rpc_luggable_socket_unlock = rpc_luggable_socket_unlock,
                    rpc_luggable_socket_set_visibility = rpc_luggable_socket_set_visibility,
                },
            },
        },
    },
    {   name = "VisualLoadoutSystem",
        hook_templates = {
            {
                hook_class = CLASS.VisualLoadoutSystem,
                hook_functions = {
                    rpc_player_wield_slot = rpc_player_wield_slot,
                    rpc_player_unwield_slot = rpc_player_unwield_slot,
                },
            },
            {
                hook_class = CLASS.PlayerUnitWeaponExtension,
                hook_functions = {
                    on_slot_wielded = on_slot_wielded,
                    on_slot_unwielded = on_slot_unwielded,
                },
            },
        },
    },
    {   name = "PlayerHuskVisualLoadoutExtension",
        hook_templates = {
            {
                hook_class = CLASS.PlayerHuskVisualLoadoutExtension,
                hook_functions = {
                    rpc_player_equip_item_from_profile_to_slot = rpc_player_equip_item_from_profile_to_slot,
                    rpc_player_equip_item_to_slot = rpc_player_equip_item_to_slot,
                    rpc_player_unequip_item_from_slot = rpc_player_unequip_item_from_slot,
                },
            },
        },
    },
    {   name = "HealthStationSystem",
        hook_templates = {
            {
                hook_class = CLASS.HealthStationSystem,
                hook_functions = {
                    rpc_health_station_use = rpc_health_station_use,
                    rpc_health_station_on_socket_spawned = rpc_health_station_on_socket_spawned,
                    --rpc_health_station_on_battery_spawned = rpc_health_station_on_battery_spawned,
                    rpc_health_station_sync_charges = rpc_health_station_sync_charges,
                    rpc_health_station_hot_join = rpc_health_station_hot_join,
                },
            },
        },
    },
    {   name = "ServoSkullEvents",
        hook_templates = {
            {
                hook_class = CLASS.ServoSkullSystem,
                hook_functions = {
                    rpc_servo_skull_do_pulse_fx = rpc_servo_skull_do_pulse_fx,
                    rpc_servo_skull_player_nearby = rpc_servo_skull_player_nearby,
                    rpc_servo_skull_activator_set_visibility = rpc_servo_skull_activator_set_visibility,
                    rpc_servo_skull_set_scanning_active = rpc_servo_skull_set_scanning_active,
                },
            },
            {
                hook_class = CLASS.MinigameSystem,
                hook_functions = {
                    --rpc_minigame_hot_join = rpc_minigame_hot_join,
                    rpc_minigame_sync_start = rpc_minigame_sync_start,
                    rpc_minigame_sync_stop = rpc_minigame_sync_stop,
                    rpc_minigame_sync_completed = rpc_minigame_sync_completed,
                },
            },
            {
                hook_class = CLASS.DecoderDeviceSystem,
                hook_functions = {
                    rpc_decoder_device_hot_join = rpc_decoder_device_hot_join,
                    rpc_decoder_device_enable_unit = rpc_decoder_device_enable_unit,
                    rpc_decoder_device_place_unit = rpc_decoder_device_place_unit,
                    rpc_decoder_device_start_decode = rpc_decoder_device_start_decode,
                    rpc_decoder_device_decode_interrupt = rpc_decoder_device_decode_interrupt,
                    rpc_decoder_device_finished = rpc_decoder_device_finished,
                },
            },
            {
                hook_class = CLASS.ScanningEventSystem,
                hook_functions = {
                    rpc_scanning_device_finished = rpc_scanning_device_finished,
                    rpc_scanning_device_hot_join = rpc_scanning_device_hot_join,
                },
            },
        },
    },
    {   name = "SmartTagSystem",
        hook_templates = {
            {
                hook_class = CLASS.SmartTagSystem,
                hook_functions = {
                    rpc_set_smart_tag = rpc_set_smart_tag,
                    rpc_set_smart_tag_hot_join = rpc_set_smart_tag_hot_join,
                    rpc_remove_smart_tag = rpc_remove_smart_tag,
                    rpc_smart_tag_reply = rpc_smart_tag_reply,
                },
            },
        },
    },
    {   name = "PlayerUnitStatus",
        hook_templates = {
            {
                hook_class = CLASS.PlayerUnitMoodExtension,
                hook_functions = {
                    update = PUME_update,
                },
            },
        },
    },
    {   name = "PlayerUnitMoodExtension",
        hook_templates = {
            {
                hook_class = CLASS.PlayerUnitMoodExtension,
                hook_functions = {
                    rpc_trigger_timed_mood = rpc_trigger_timed_mood,
                },
            },
        },
    },
    {   name = "PlayerAbilities",
        hook_templates = {
            {
                hook_class = CLASS.PlayerUnitAbilityExtension,
                hook_functions = 
                {
                    update = PlayerAbilityExtensionUpdate,
                },
            },
            {
                hook_class = CLASS.PlayerHuskAbilityExtension,
                hook_functions = 
                {
                    update = PlayerAbilityExtensionUpdate,
                },
            },
        },
    },
    {   name = "MinionDeathManager",
        hook_templates = {
            {
                hook_class = CLASS.MinionDeathManager,
                hook_functions = {
                    rpc_minion_set_dead = rpc_minion_set_dead,
                },
            },
        },
    },
    {   name = "MinionSuppressionHuskExtension",
        hook_templates = {
            {
                hook_class = CLASS.MinionSuppressionHuskExtension,
                hook_functions = {
                    rpc_server_reported_unit_suppression = rpc_server_reported_unit_suppression,
                },
            },
        },
    },
    {   name = "Players",
    hook_templates = {},
},
}

local output = {
    datasource_templates = datasource_templates,
    data_locations = data_locations
}

return output