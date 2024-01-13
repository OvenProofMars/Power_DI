local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

local dataset_templates

local attack_reports = function(data)
    data:append_dataset("AttackReportManager")
    :next(
        function()
            return data:iterate_dataset(
                function(k,v)
                    local attacker_lookup = data.datasource_proxies.UnitSpawnerManager[v.attacking_unit_uuid]
                    if attacker_lookup then
                        v.attacker_name = attacker_lookup.unit_name
                        v.attacker_template_name = attacker_lookup.unit_template_name
                        
                        if v.attacker_template_name == "player_character" then
                            v.attacker_attack_type = "Player"
                            v.attacker_faction = "Imperium"
                            v.attacker_type = "Player"
                            v.attacker_class = "Player"
                            v.attacker_display_name = v.attacker_name
                            v.attacker_armor_type = "Player"
                            v.attacker_template_name = nil
                        else
                            local lookup = data.lookup_proxies.minion_categories[v.attacker_name]
                            if lookup then
                                v.attacker_attack_type = lookup.attack_type
                                v.attacker_faction = lookup.faction
                                v.attacker_type = lookup.type
                                v.attacker_class = lookup.class
                                v.attacker_display_name = lookup.display_name
                                v.attacker_armor_type = lookup.armor_type
                                v.attacker_name = lookup.en_name
                                v.attacker_template_name = nil
                            end
                        end
                    end
                    local defender_lookup = data.datasource_proxies.UnitSpawnerManager[v.attacked_unit_uuid]
                    if defender_lookup then
                        v.defender_name = defender_lookup.unit_name
                        v.defender_template_name = defender_lookup.unit_template_name
                        v.defender_max_health = defender_lookup.max_health
                        if v.defender_template_name == "player_character" then
                            v.defender_attack_type = "Player"
                            v.defender_faction = "Imperium"
                            v.defender_type = "Player"
                            v.defender_class = "Player"
                            v.defender_display_name = v.defender_name
                            v.defender_armor_type = "Player"
                            v.defender_template_name = nil
                        else
                            local lookup = data.lookup_proxies.minion_categories[v.defender_name]
                            if lookup then
                                v.defender_attack_type = lookup.attack_type
                                v.defender_faction = lookup.faction
                                v.defender_type = lookup.type
                                v.defender_class = lookup.class
                                v.defender_display_name = lookup.display_name
                                v.defender_armor_type = lookup.armor_type
                                v.defender_name = lookup.en_name
                                v.defender_template_name = nil
                            end
                        end
                        if v.attack_result == "died" then
                            v.killed = 1
                            if defender_lookup.max_health then
                                v.health_damage = defender_lookup.max_health - v.attacked_unit_damage_taken
                            else
                                v.health_damage = 1
                            end
                        else
                            v.killed = 0
                            v.health_damage = v.damage
                        end
                    end

                    if v.damage_profile_name then
                        v.damage_category = data.lookup_proxies.damage_categories[v.damage_profile_name]
                    end
                    v.critical_hit = v.is_critical_strike and 1 or 0
                    v.is_critical_strike = nil
                    v.weakspot_hit = v.hit_weakspot and 1 or 0
                    v.hit_weakspot = nil
                    v.attack_direction = nil
                    v.hit_world_position = nil
                    v.attacked_unit_uuid = nil
                    v.attacked_unit_position = nil
                    v.attacking_unit_uuid = nil
                    v.attacking_unit_position = nil
                    v.attacked_unit_damage_taken = nil 
                end
            )
        end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end

local player_status = function(data)
    data:append_dataset("PlayerUnitStatus")
    :next(
        function()
            return data:iterate_dataset(
                function(k,v)
                    local player_lookup = data.datasource_proxies.UnitSpawnerManager[v.player_unit_uuid]
                    v.player_name = player_lookup.unit_name
                    v.player_unit_uuid = nil
                    v.player_unit_position = nil
                end
            )
        end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end

local player_interactions = function(data)
    data:append_dataset("InteracteeSystem")
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local interactor_lookup = data.datasource_proxies.UnitSpawnerManager[v.interactor_unit_uuid]
                local interaction_type = v.interaction_type and string.gsub(v.interaction_type,"_"," ")
                if interactor_lookup then
                    v.interactor_name = interactor_lookup.unit_name
                else
                    v.interactor_name = "nil"
                end
                v.interactor_unit_uuid = nil
                v.interactor_unit_position = nil
                local interactee_lookup = data.datasource_proxies.UnitSpawnerManager[v.interactee_unit_uuid]
                if interactee_lookup then
                    local unit_name = interactee_lookup.unit_name
                    v.interactee_name = unit_name and string.gsub(unit_name,"_"," ")
                else
                    v.interactee_name = interaction_type or "Level unit"
                end
                v.interactee_unit_position = nil
                v.interaction_type = interaction_type
            end
        )
    end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end

local tagging = function(data)
    data:append_dataset("SmartTagSystem")
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local tagger_lookup = data.datasource_proxies.UnitSpawnerManager[v.tagger_unit_uuid]
                if tagger_lookup then
                    v.player_name = tagger_lookup.unit_name
                else
                    v.player_name = "nil"
                end
                
                v.tagger_unit_uuid = nil
                v.tagger_unit_position = nil

                local target_lookup = data.datasource_proxies.UnitSpawnerManager[v.target_unit_uuid]
                if target_lookup then
                    local unit_name = target_lookup.unit_name
                    local minion_lookup = unit_name and data.lookup_proxies.minion_categories[unit_name]
                    if minion_lookup then
                        v.target_name = minion_lookup.en_name
                    else
                        v.target_name = unit_name and string.gsub(unit_name,"_"," ")
                    end
                else
                    v.target_name = "Level unit"
                end
                
                v.target_unit_uuid = nil
                v.target_unit_position = nil

                local event = v.event
                if event then
                    v.event = string.gsub(event,"_"," ")
                end

                local template_name = v.template_name
                if template_name then
                    v.tag_type = string.gsub(template_name,"_"," ")
                    v.template_name = nil
                else
                    v.tag_type = "nil"
                end

                local reason = v.reason
                if reason then
                    v.reason = string.gsub(reason,"_"," ")
                end
            end
        )
    end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end

local player_suppression = function(data)
    data:append_dataset("PlayerUnitMoodExtension")
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_lookup = data.datasource_proxies.UnitSpawnerManager[v.player_unit_uuid]
                if player_lookup then
                    v.player_name = player_lookup.unit_name
                else
                    v.player_name = "nil"
                end
                v.player_unit_position = nil
                local mood_type = string.gsub(v.mood_type,"_"," ")
                v.suppression_type = mood_type
                v.mood_type = nil
            end
        )
    end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end

local blocked_attacks = function(data)
    data:append_dataset("PlayerBlockedAttacks")
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_lookup = data.datasource_proxies.UnitSpawnerManager[v.player_unit_uuid]
                if player_lookup then
                    v.player_name = player_lookup.unit_name
                else
                    v.player_name = "nil"
                end
                local enemy_lookup = data.datasource_proxies.UnitSpawnerManager[v.attacking_unit_uuid]
                if enemy_lookup then
                    local enemy_name = enemy_lookup.unit_name
                    local lookup = data.lookup_proxies.minion_categories[enemy_name]
                    if lookup then
                        v.enemy_name = lookup.en_name
                    else
                        v.enemy_name = enemy_name
                    end
                else
                    v.enemy_name = "nil"
                end
                v.player_unit_position = nil
                v.attacking_unit_position = nil
            end
        )
    end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end

local slots = function(data)
    data:append_dataset("VisualLoadoutSystem")
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_lookup = data.datasource_proxies.UnitSpawnerManager[v.player_unit_uuid]
                if player_lookup then
                    v.player_name = player_lookup.unit_name
                else
                    v.player_name = "nil"
                end
                v.player_unit_position = nil
                local event = v.event
                v.event = event and string.gsub(event,"_"," ")
                local slot_name = v.slot_name
                v.slot_name = slot_name and string.gsub(slot_name,"_"," ")
            end
        )
    end
    )
    :next(
        function()
            data:complete_dataset()
        end
    )
end 

dataset_templates = {
    attack_reports = {
        name = "attack_reports",
        label = "Attack reports",
        dataset_function = attack_reports,
        required_datasources = {
            "AttackReportManager",
            "UnitSpawnerManager",
        },
        legend = {
            damage_efficiency = "string",
            weakspot_hit = "number",
            defender_faction = "string",
            attack_result = "string",
            defender_name = "string",
            attacker_template_name = "string",
            attacker_name = "string",
            damage_category = "string",
            time = "number",
            defender_attack_type = "string",
            defender_armor_type = "string",
            attacker_display_name = "string",
            defender_type = "string",
            attacker_type = "string",
            critical_hit = "number",
            attacker_faction = "string",
            damage_profile_name = "string",
            attacker_attack_type = "string",
            killed = "number",
            damage = "number",
            attack_type = "string",
            defender_max_health = "number",
            health_damage = "number",
            attacker_class = "string",
            defender_class = "string",
            defender_display_name = "string",
            attacker_armor_type = "string",
        },
    },
    player_status = {
        name = "player_status",
        label = "Player status",
        dataset_function = player_status,
        required_datasources = {
            "PlayerUnitStatus",
            "UnitSpawnerManager",
        },
        legend = {
            player_name = "string",
            time = "number",
            state_name = "string",
            previous_state_name = "string",
        },
    },
    player_interactions = {
        name = "player_interactions",
        label = "Player interactions",
        dataset_function = player_interactions,
        required_datasources = {
            "InteracteeSystem",
            "UnitSpawnerManager",
        },
        legend = {
            interactor_name = "string",
            interactee_name = "string",
            interaction_type = "string",
            event = "string",
            result = "string",
            time = "number",
        }
    },
    tagging = {
        name = "tagging",
        label = "Tagging",
        dataset_function = tagging,
        required_datasources = {
            "SmartTagSystem",
            "UnitSpawnerManager",
        },
        legend = {
            player_name = "string",
            target_name = "string",
            event = "string",
            tag_type = "string",
            reason = "string",
            time = "number",
            tag_id = "number",
        }
    },
    player_suppression = {
        name = "player_suppression",
        label = "Suppression",
        dataset_function = player_suppression,
        required_datasources = {
            "PlayerUnitMoodExtension",
            "UnitSpawnerManager",
        },
        legend = {
            player_name = "string",
            suppression_type = "string",
            time = "number",
        }
    },
    blocked_attacks = {
        name = "blocked_attacks",
        label = "Blocked",
        dataset_function = blocked_attacks,
        required_datasources = {
            "PlayerBlockedAttacks",
            "UnitSpawnerManager",
        },
        legend = {
            player_name = "string",
            enemy_name = "string",
            attack_type = "string",
            weapon_template_name = "string",
            time = "number",
        }
    },
    slot_events = {
        name = "slot_events",
        label = "Slots",
        dataset_function = slots,
        required_datasources = {
            "VisualLoadoutSystem",
            "UnitSpawnerManager",
        },
        legend = {
            player_name = "string",
            event = "string",
            slot_name = "string",
            time = "number",
        }
    },
}


return dataset_templates