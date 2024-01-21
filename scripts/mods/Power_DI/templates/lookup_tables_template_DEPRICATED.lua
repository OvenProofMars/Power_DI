--Generates the lookup tables, still need to write a lookup manager for adding new lookups via the api--

local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")

local ArchetypeTalents = require("scripts/settings/ability/archetype_talents/archetype_talents")

local lookup_tables = {
    game_version = APPLICATION_SETTINGS.game_version,
    power_di_version = mod.version,
    --minion_categories = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\lookup_tables\minion_categories]]),
    --player_state_categories = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\lookup_tables\player_state_categories]]),
    BuffTemplates = require("scripts/settings/buff/buff_templates"),
    ArchetypeTalents = ArchetypeTalents,
    weapon_trait_templates = require("scripts/settings/equipment/weapon_traits/weapon_trait_templates"),
}

local buff_to_talent = {}

local function add_by_key(table)
    local output
    for key, value in pairs(table) do
        if key == "buff_template_name" then
            output = value
        elseif type(value) == "table" then
            local child_output = add_by_key(value)
            if child_output then
                output = child_output
            end
        end
    end
    return output
end

for _, table in pairs(ArchetypeTalents) do
    for talent_name, talent_template in pairs(table) do
        local buff_template_name = add_by_key(talent_template)
        if buff_template_name then
            buff_to_talent[buff_template_name] = talent_template
        end
    end
end

lookup_tables.buff_to_talent = buff_to_talent

local network_lookup = DMF.deepcopy(NetworkLookup)
for k, v in pairs(network_lookup) do
    lookup_tables[k] = v
end
network_lookup = nil

local damage_profile_templates = {
    ["Melee weapon damage"] = {
        require("scripts/settings/equipment/weapon_templates/chain_swords/settings_templates/chain_sword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/chain_swords/settings_templates/chain_sword_2h_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/chain_axes/settings_templates/chain_axe_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_axes/settings_templates/combat_axe_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_blades/settings_templates/combat_blade_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_knives/settings_templates/combat_knife_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_swords/settings_templates/combatsword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/force_swords/settings_templates/force_sword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_clubs/settings_templates/ogryn_club_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_clubs/settings_templates/ogryn_shovel_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_power_mauls/settings_templates/ogryn_power_maul_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_mauls/settings_templates/power_maul_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_swords/settings_templates/power_sword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/thunder_hammers/settings_templates/thunder_hammer_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/linesman_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/ninjafencer_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/luggable_damage_profile_templates"),
    },
    ["Ranged weapon damage"] = {
        require("scripts/settings/equipment/weapon_templates/force_staffs/settings_templates/force_staff_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/flamers/settings_templates/flamer_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/spraynpray_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/autoguns/settings_templates/autogun_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/autopistols/settings_templates/autopistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/bolters/settings_templates/bolter_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/grenadier_gauntlets/settings_templates/grenadier_gauntlet_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/lasguns/settings_templates/lasgun_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/laspistols/settings_templates/laspistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/plasma_rifles/settings_templates/plasma_rifle_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ripperguns/settings_templates/rippergun_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/thumpers/settings_templates/thumper_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/shotguns/settings_templates/shotgun_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/stub_pistols/settings_templates/stub_pistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_heavystubbers/settings_templates/ogryn_heavystubber_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/assault_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/bfg_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/killshot_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/tank_damage_profile_templates"),
    },
    ["Blitz damage"] = {
        require("scripts/settings/damage/damage_profiles/grenade_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/psyker_smite_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/smiter_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/zealot_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/demolitions_damage_profile_templates"),
    },
    ["Combat ability damage"] = {
        require("scripts/settings/damage/damage_profiles/ability_damage_profile_templates"),
    },
    ["Condition damage"] = {
        require("scripts/settings/damage/damage_profiles/buff_damage_profile_templates"),
    },
    ["Environmental damage"] = {
        require("scripts/settings/damage/damage_profiles/prop_damage_profile_templates"),
    },
    ["Minion"] = {
        require("scripts/settings/damage/damage_profiles/minion_damage_profile_templates"),
    },
    ["Other"] = {
        require("scripts/settings/damage/damage_profiles/common_damage_profile_templates"),
    },
}
local damage_template_categories = {}

for category_name, category_array in pairs(damage_profile_templates) do
    for _, damage_templates  in ipairs(category_array) do
        for damage_template_name, _ in pairs(damage_templates.base_templates.__data) do
            damage_template_categories[damage_template_name] = category_name
        end
        for damage_template_name, _ in pairs(damage_templates.overrides.__data) do
            damage_template_categories[damage_template_name] = category_name
        end
    end
end

--Overwrites, because FS is inconsistent
damage_template_categories["heavy_tank"] = "Melee weapon damage"
damage_template_categories["default_powersword_heavy"] = "Melee weapon damage"
damage_template_categories["ogryn_thumper_p1_m2_default"] = "Ranged weapon damage"
damage_template_categories["force_staff_demolition_default"] = "Ranged weapon damage"
damage_template_categories["ogryn_thumper_p1_m2_default_instant"] = "Ranged weapon damage"
damage_template_categories["ogryn_thumper_p1_m2_close"] = "Ranged weapon damage"
damage_template_categories["ogryn_thumper_p1_m2_close_instant"] = "Ranged weapon damage"
damage_template_categories["force_staff_demolition_close"] = "Ranged weapon damage"
damage_template_categories["plasma_demolition"] = "Ranged weapon damage"

lookup_tables.damage_categories = damage_template_categories

return lookup_tables