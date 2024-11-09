local ItemUtils = require("scripts/utilities/items")
local mod = get_mod("Power_DI")

local dataset_templates

local attack_reports = function(data)
    local UnitSpawnerManager = data.datasource_proxies.UnitSpawnerManager
    local PlayerProfiles = {}
    local minion_categories = data.lookup_proxies.minion_categories
    local damage_categories = data.lookup_proxies.damage_categories
    local is_local_session = mod.get_loaded_session_id() == "local"
    data:append_dataset("AttackReportManager")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(
        function()
            return data:iterate_dataset(
                function(k,v)
                    local attacking_unit_uuid = v.attacking_unit_uuid
                    local attacker_lookup = UnitSpawnerManager[attacking_unit_uuid]
                    if attacker_lookup then
                        local attacker_name = attacker_lookup.unit_name
                        local attacker_template_name = attacker_lookup.unit_template_name
                        local is_player = attacker_template_name == "player_character"
                        local lookup_value = is_player and "player" or attacker_name
                        local lookup = minion_categories[lookup_value]
                        if lookup then
                            v.attacker_attack_type = lookup.attack_type
                            v.attacker_faction = lookup.faction
                            v.attacker_type = lookup.type
                            v.attacker_class = lookup.class
                            v.attacker_armor_type = lookup.armor_type
                            v.attacker_name = lookup.display_name
                        else
                            --print(lookup_value)
                        end
                        if is_player then
                            local player_profile = PlayerProfiles[attacking_unit_uuid]
                            v.attacker_player = player_profile and player_profile.character_id
                            v.attacker_name = player_profile and player_profile.name
                        end
                    end
                    local defending_unit_uuid = v.attacked_unit_uuid
                    local defender_lookup = UnitSpawnerManager[defending_unit_uuid]
                    if defender_lookup then
                        local defender_name = defender_lookup.unit_name
                        local defender_template_name = defender_lookup.unit_template_name

                        local is_player = defender_template_name == "player_character"
                        local lookup_value = is_player and "player" or defender_name
                        local lookup = minion_categories[lookup_value]
                        local defender_max_health = defender_lookup.max_health
                        
                        if lookup then
                            v.defender_attack_type = lookup.attack_type
                            v.defender_faction = lookup.faction
                            v.defender_type = lookup.type
                            v.defender_class = lookup.class
                            v.defender_armor_type = lookup.armor_type
                            v.defender_name = lookup.display_name
                            v.defender_max_health = defender_max_health
                        end

                        if is_player then
                            local player_profile = PlayerProfiles[defending_unit_uuid]
                            v.defender_player = player_profile and player_profile.character_id
                            v.defender_name = player_profile and player_profile.name
                        end

                        if v.attack_result == "died" then
                            v.killed = 1
                            local attacked_unit_damage_taken = v.attacked_unit_damage_taken
                            if defender_max_health and not is_local_session then
                                v.health_damage = defender_max_health - attacked_unit_damage_taken
                            elseif defender_max_health and is_local_session then
                                v.health_damage = defender_max_health - attacked_unit_damage_taken + v.damage
                            else
                                v.health_damage = 1
                            end
                        else
                            v.killed = 0
                            v.health_damage = v.damage
                        end
                    end
                    
                    local damage_profile_name = v.damage_profile_name
                    v.damage_category = damage_profile_name and damage_categories[damage_profile_name]
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
                    --v.attacked_unit_damage_taken = nil 
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
    local PlayerProfiles = {}
    local player_state_categories = data.lookup_proxies.player_state_categories
    data:append_dataset("PlayerUnitStatus")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(
        function()
            return data:iterate_dataset(
                function(k,v)
                    local player_profile_lookup = PlayerProfiles[v.player_unit_uuid]
                    v.player_name = player_profile_lookup and player_profile_lookup.name
                    v.player = player_profile_lookup and player_profile_lookup.character_id
                    
                    local state_name = v.state_name
                    v.state_category = player_state_categories[state_name] or "mloc_other"
                    v.state_name = string.gsub(state_name,"_", " ")
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
    local PlayerProfiles = {}
    local UnitSpawnerManager = data.datasource_proxies.UnitSpawnerManager
    data:append_dataset("InteracteeSystem")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local interactor_profile_lookup = PlayerProfiles[v.interactor_unit_uuid]
                local interaction_type = v.interaction_type and string.gsub(v.interaction_type,"_"," ")
                v.interactor_name = interactor_profile_lookup and interactor_profile_lookup.name
                v.interactor_player = interactor_profile_lookup and interactor_profile_lookup.character_id

                local interactee_unit_uuid = v.interactee_unit_uuid
                local interactee_lookup = UnitSpawnerManager[interactee_unit_uuid]
                if interactee_lookup then
                    local interactee_player_profile_lookup = PlayerProfiles[interactee_unit_uuid]
                    if interactee_player_profile_lookup then
                        v.interactee_name = interactee_player_profile_lookup.name
                        v.interactee_player = interactee_player_profile_lookup.character_id
                    else
                        local unit_name = interactee_lookup.unit_name
                        v.interactee_name = unit_name and string.gsub(unit_name,"_"," ")
                    end
                else
                    v.interactee_name = interaction_type or "Level unit"
                end
                v.interaction_type = interaction_type

                v.interactor_unit_uuid = nil
                v.interactor_unit_position = nil
                v.interactor_unit_uuid = nil
                v.interactee_unit_position = nil
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
    local PlayerProfiles = {}
    local UnitSpawnerManager = data.datasource_proxies.UnitSpawnerManager
    local minion_categories = data.lookup_proxies.minion_categories
    data:append_dataset("SmartTagSystem")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local tagger_profile_lookup = PlayerProfiles[v.tagger_unit_uuid]
                v.player_name = tagger_profile_lookup and tagger_profile_lookup.name
                v.player = tagger_profile_lookup and tagger_profile_lookup.character_id
                
                v.tagger_unit_uuid = nil
                v.tagger_unit_position = nil

                local target_lookup = UnitSpawnerManager[v.target_unit_uuid]
                if target_lookup then
                    local unit_name = target_lookup.unit_name
                    local minion_lookup = unit_name and minion_categories[unit_name]
                    if minion_lookup then
                        v.target_name = minion_lookup.display_name
                        v.target_type = minion_lookup.type
                        v.target_class = minion_lookup.class
                    else
                        local target_name = unit_name and string.gsub(unit_name,"_"," ")
                        v.target_name = target_name
                        v.target_type = target_name
                        v.target_class = target_name
                    end
                else
                    v.target_name = "Level unit"
                    v.target_type = "Level unit"
                    v.target_class = "Level unit"
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
    local PlayerProfiles = {}
    data:append_dataset("PlayerUnitMoodExtension")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_profile_lookup = PlayerProfiles[v.player_unit_uuid]
                v.player_name = player_profile_lookup and player_profile_lookup.unit_name
                v.player = player_profile_lookup and player_profile_lookup.character_id
                
                local mood_type = string.gsub(v.mood_type,"_"," ")
                v.suppression_type = mood_type
                v.player_unit_uuid = nil
                v.player_unit_position = nil
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
    local PlayerProfiles = {}
    local UnitSpawnerManager = data.datasource_proxies.UnitSpawnerManager
    local minion_categories = data.lookup_proxies.minion_categories
    data:append_dataset("PlayerBlockedAttacks")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_profile_lookup = PlayerProfiles[v.player_unit_uuid]
                v.player_name = player_profile_lookup and player_profile_lookup.unit_name
                v.player = player_profile_lookup and player_profile_lookup.character_id

                local enemy_lookup = UnitSpawnerManager[v.attacking_unit_uuid]
                if enemy_lookup then
                    local enemy_name = enemy_lookup.unit_name
                    local lookup = minion_categories[enemy_name]
                    if lookup then
                        v.enemy_name = lookup.display_name
                        v.enemy_attack_type = lookup.attack_type
                        v.enemy_faction = lookup.faction
                        v.enemy_type = lookup.type
                        v.enemy_class = lookup.class
                        v.enemy_armor_type = lookup.armor_type
                    else
                        v.enemy_name = enemy_name
                    end
                end
                v.player_unit_uuid = nil
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
    local PlayerProfiles = {}
    data:append_dataset("VisualLoadoutSystem")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_profile_lookup = PlayerProfiles[v.player_unit_uuid]
                v.player_name = player_profile_lookup and player_profile_lookup.unit_name
                v.player = player_profile_lookup and player_profile_lookup.character_id

                local event = v.event
                v.event = event and string.gsub(event,"_"," ")
                local slot_name = v.slot_name
                v.slot_name = slot_name and string.gsub(slot_name,"_"," ")

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

local player_abilities = function(data)
    local PlayerProfiles = {}
    local player_ability_types_lookup = {combat_ability = "mloc_combat_ability", grenade_ability = "mloc_blitz_ability"}
    data:append_dataset("PlayerAbilities")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
            function(k,v)
                PlayerProfiles[k] = v
            end
        )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)
                local player_profile_lookup = PlayerProfiles[v.player_unit_uuid]
                v.player_name = player_profile_lookup and player_profile_lookup.unit_name
                v.player = player_profile_lookup and player_profile_lookup.character_id

                local event_type
                if v.charge_delta > 0 then
                    event_type = "mloc_ability_charge_gained"
                elseif v.charge_delta < 0 then
                    event_type = "mloc_ability_charge_used"
                end
                v.event_type = event_type
                local ability_type = v.ability_type
                v.ability_type = player_ability_types_lookup[ability_type]
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

local player_buffs = function(data)
    local PlayerProfiles = {}
    local item_slot_names = {"slot_primary", "slot_secondary", "slot_attachment_1", "slot_attachment_2", "slot_attachment_3"}
    local item_types_lookup = {WEAPON_MELEE = "mloc_melee_weapon", WEAPON_RANGED = "mloc_ranged_weapon", GADGET = "mloc_curio"}
    local player_items = {}
    local master_items = data.lookup_proxies.MasterItems

    if not master_items then
        local items_cache = Managers.backend.interfaces.master_data:items_cache()
        master_items = items_cache and items_cache:get_cached()
    end
    local weapon_trait_templates = data.lookup_proxies.weapon_trait_templates
    local BuffTemplates = data.lookup_proxies.BuffTemplates
    local buff_to_talent = data.lookup_proxies.buff_to_talent
    local buff_templates = data.lookup_proxies.buff_templates
    data:append_dataset("PlayerBuffExtension")
    :next(
        function()
            return data:iterate_datasource("PlayerProfiles",
                function(k,v)
                    PlayerProfiles[k] = v

                    local loadout = v.loadout
                    player_items[k] = {}

                    local player_items_table = player_items[k]

                    for _, item_slot_name in ipairs(item_slot_names) do
                        local slot = loadout[item_slot_name]
                        local slot_item = slot and slot.__master_item
                        if slot_item then
                            local item_display_name = slot_item.display_name
                            local item_type = slot_item.item_type
                            local perks = slot_item.perks
                            local traits = slot_item.traits
                            if perks then
                                for _, perk in ipairs(perks) do
                                    local perk_id = perk.id
                                    local perk_rarity = perk.rarity
                                    local perk_value = perk.value
                                    local perk_item = master_items[perk_id]
                                    local weapon_perk_id = perk_item.trait
                                    local weapon_perk_icon = perk_item.icon
                                    local buff_template_id = next(weapon_trait_templates[weapon_perk_id].buffs)
                                    local buff_template = BuffTemplates[buff_template_id]
                                    local buff_name = buff_template and buff_template.name
                                    local child_buff_name = buff_template and buff_template.child_buff_template
                                    local display_name = ItemUtils.perk_description(perk_item, perk_rarity, perk_value)
                                    display_name = string.gsub(display_name,"%%", " percent")
                                    local item_data = {}
                                    item_data.item_type = item_types_lookup[item_type]
                                    item_data.item_display_name = item_display_name
                                    item_data.type = "Perk"
                                    item_data.display_name = display_name
                                    item_data.icon = weapon_perk_icon

                                    player_items_table[buff_name] = item_data
                                    if child_buff_name then
                                        player_items_table[child_buff_name] = item_data
                                    end
                                end
                            end

                            if traits then
                                for _, trait in ipairs(traits) do
                                    local trait_id = trait.id
                                    local trait_item = master_items[trait_id]
                                    local weapon_trait_id = trait_item.trait
                                    local weapon_trait_icon = trait_item.icon
                                    local weapon_trait_template = weapon_trait_templates[weapon_trait_id]
                                    local buff_template_id = weapon_trait_template and next(weapon_trait_template.buffs) or weapon_trait_id
                                    local buff_template = BuffTemplates[buff_template_id]
                                    local buff_name = buff_template and buff_template.name
                                    local child_buff_name = buff_template and buff_template.child_buff_template
                                    local display_name = ItemUtils.display_name(trait_item)
                                    local item_data = {}
                                    item_data.item_type = item_types_lookup[item_type]
                                    item_data.item_display_name = item_display_name
                                    item_data.type = "Blessing"
                                    item_data.display_name = display_name
                                    item_data.icon = weapon_trait_icon
                                    player_items_table[buff_name] = item_data
                                    if child_buff_name then
                                        player_items_table[child_buff_name] = item_data
                                    end
                                    
                                end
                            end
                        end
                    end
                end
            )
        end
    )
    :next(function()
        return data:iterate_dataset(
            function(k,v)

                local player_unit = v.unit_uuid
                local player_profile_lookup = PlayerProfiles[player_unit]
                v.player_name = player_profile_lookup and player_profile_lookup.unit_name
                v.player = player_profile_lookup and player_profile_lookup.character_id

                local template_id = v.buff_template_id
                local template_name = template_id and buff_templates[template_id]
                local template = template_name and BuffTemplates[template_name]
                local buff_category = template and template.buff_category
                v.template_name = template_name
                v.buff_category = buff_category
                v.class_name = template.class_name
                v.icon = template.icon
                local parent_template_id = v.optional_parent_buff_id
                local parent_template_name = parent_template_id and buff_templates[parent_template_id]
                local parent_template = parent_template_name and BuffTemplates[parent_template_name]
                if parent_template then
                    v.parent_template_name = parent_template_name
                    v.parent_buff_category = parent_template.buff_category
                    v.parent_class_name = parent_template.class_name
                    v.parent_icon = parent_template.icon
                end

                local source_category, source_sub_category, source_item_name, source_name, source_icon
                local player_item_table = player_items[player_unit]
                local source_item = player_item_table[template_name]
                local talent = buff_to_talent[template_name]

                if source_item then
                    source_category = source_item.item_type
                    source_sub_category = source_item.type
                    source_item_name = source_item.item_display_name
                    source_name = source_item.display_name
                    source_icon = source_item.icon
                elseif talent then
                    source_category = "Talent"
                    source_sub_category = "Talent"
                    source_item_name = "N.a."
                    source_name = talent.display_name
                    source_icon = talent.icon
                elseif buff_category == "talents" then
                    source_category = "Talent"
                    source_sub_category = "Talent"
                    source_item_name = "N.a."
                    source_name = "Unknown"
                else
                    source_category = "Generic"
                    source_sub_category = "Generic"
                    source_item_name = "Unknown"
                    source_name = "Unknown"
                    source_icon = "Unknown"
                end

                v.source_category = source_category
                v.source_sub_category = source_sub_category
                v.source_item_name = source_item_name
                v.source_icon = source_icon
                v.source_name = source_name

                v.buff_template_id = nil
                v.optional_lerp_value = nil
                v.optional_parent_buff_id = nil
                v.optional_item_slot_id = nil
                v.player_unit_uuid = nil
                v.unit_position = nil
                v.activation_frame = nil
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
        name = "mloc_dataset_attack_reports",
        dataset_function = attack_reports,
        required_datasources = {
            "AttackReportManager",
            "UnitSpawnerManager",
            "PlayerProfiles",
        },
        legend = {
            attacker_player = "player",
            defender_player = "player",
            damage_efficiency = "string",
            weakspot_hit = "number",
            defender_faction = "string",
            attack_result = "string",
            defender_name = "string",
            attacker_name = "string",
            damage_category = "string",
            time = "number",
            defender_attack_type = "string",
            defender_armor_type = "string",
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
            attacker_armor_type = "string",
        },
    },
    player_status = {
        name = "mloc_dataset_player_status",
        dataset_function = player_status,
        required_datasources = {
            "PlayerUnitStatus",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            state_category = "string",
            state_name = "string",
            previous_state_name = "string",
            time = "number",
        },
    },
    player_interactions = {
        name = "mloc_dataset_player_interactions",
        dataset_function = player_interactions,
        required_datasources = {
            "InteracteeSystem",
            "UnitSpawnerManager",
            "PlayerProfiles",
        },
        legend = {
            interactor_name = "string",
            interactee_name = "string",
            interactor_player = "player",
            interactee_player = "player",
            interaction_type = "string",
            event = "string",
            result = "string",
            time = "number",
        }
    },
    tagging = {
        name = "mloc_dataset_tagging",
        label = "Tagging",
        dataset_function = tagging,
        required_datasources = {
            "SmartTagSystem",
            "UnitSpawnerManager",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            target_name = "string",
            target_type = "string",
            target_class = "string",
            event = "string",
            tag_type = "string",
            reason = "string",
            time = "number",
            tag_id = "number",
        }
    },
    player_suppression = {
        name = "mloc_dataset_player_supression",
        dataset_function = player_suppression,
        required_datasources = {
            "PlayerUnitMoodExtension",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            suppression_type = "string",
            time = "number",
        }
    },
    blocked_attacks = {
        name = "mloc_dataset_blocked_attacks",
        dataset_function = blocked_attacks,
        required_datasources = {
            "PlayerBlockedAttacks",
            "UnitSpawnerManager",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            enemy_name = "string",
            enemy_attack_type = "string",
            enemy_faction = "string",
            enemy_type = "string",
            enemy_class = "string",
            enemy_armor_type = "string",
            weapon_template_name = "string",
            time = "number",
        }
    },
    slot_events = {
        name = "mloc_dataset_slot_events",
        dataset_function = slots,
        required_datasources = {
            "VisualLoadoutSystem",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            event = "string",
            slot_name = "string",
            time = "number",
        }
    },
    player_abilities = {
        name = "mloc_dataset_player_abilities",
        dataset_function = player_abilities,
        required_datasources = {
            "PlayerAbilities",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            ability_type = "string",
            charge_delta = "number",
            event_type = "string",
            time = "number",
        }
    },
    player_buffs = {
        name = "mloc_dataset_player_buffs",
        dataset_function = player_buffs,
        required_datasources = {
            "PlayerBuffExtension",
            "UnitSpawnerManager",
            "PlayerProfiles",
        },
        legend = {
            player_name = "string",
            player = "player",
            template_name = "string",
            buff_category = "string",
            class_name = "string",
            icon = "string",
            parent_template_name = "string",
            parent_buff_category = "string",
            parent_class_name = "string",
            parent_icon = "string",
            source_category = "string",
            source_sub_category = "string",
            source_item_name = "string",
            source_icon = "string",
            source_name = "string",
            event = "string",
            time = "number",
        }
    },
}

return dataset_templates