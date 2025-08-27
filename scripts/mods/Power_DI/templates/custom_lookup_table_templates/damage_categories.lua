local damage_categories = {}

local damage_profile_templates = {
    ["mloc_1_melee_weapon_damage"] = {
        require("scripts/settings/equipment/weapon_templates/chain_swords/settings_templates/chain_sword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/chain_swords_2h/settings_templates/chain_sword_2h_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/chain_axes/settings_templates/chain_axe_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_axes/settings_templates/combat_axe_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_blades/settings_templates/combat_blade_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_knives/settings_templates/combat_knife_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/combat_swords/settings_templates/combatsword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/force_swords_2h/settings_templates/force_sword_2h_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/force_swords/settings_templates/force_sword_damage_profile_templates"),        
        require("scripts/settings/equipment/weapon_templates/ogryn_clubs/settings_templates/ogryn_club_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_clubs/settings_templates/ogryn_shovel_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_power_mauls/settings_templates/ogryn_power_maul_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_mauls/settings_templates/power_maul_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_swords/settings_templates/power_sword_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_swords_2h/settings_templates/power_sword_2h_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/thunder_hammers_2h/settings_templates/thunder_hammer_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/linesman_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/ninjafencer_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/luggable_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/ogryn_pickaxes_2h/settings_templates/ogryn_pickaxe_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_mauls/settings_templates/power_maul_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/power_maul_shields/settings_templates/power_maul_shield_damage_profile_templates"),
    },
    ["mloc_2_ranged_weapon_damage"] = {
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
        require("scripts/settings/equipment/weapon_templates/bolt_pistols/settings_templates/boltpistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/shotpistol_shield/settings_templates/shotpistol_shield_damage_profile_templates"),
    },
  ["mloc_3_blitz_damage"] = {
        require("scripts/settings/damage/damage_profiles/grenade_damage_profile_templates"),        
        require("scripts/settings/damage/damage_profiles/smiter_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/psyker_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/zealot_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/veteran_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/ogryn_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/demolitions_damage_profile_templates"),
    },
    ["mloc_4_combat_ability_damage"] = {
        require("scripts/settings/damage/damage_profiles/archetypes/psyker_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/zealot_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/veteran_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/ogryn_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/adamant_damage_profile_templates"),        
    },
    ["mloc_5_debuff_damage"] = {
        require("scripts/settings/damage/damage_profiles/buff_damage_profile_templates"),
    },
    ["mloc_6_environmental_damage"] = {
        require("scripts/settings/damage/damage_profiles/prop_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/minion_damage_profile_templates"),
    },
    ["mloc_7_other_damage"] = {
        require("scripts/settings/damage/damage_profiles/common_damage_profile_templates"),
    },
}

for category_name, category_array in pairs(damage_profile_templates) do
    for _, damage_templates  in ipairs(category_array) do
        for damage_template_name, _ in pairs(damage_templates.base_templates.__data) do
            damage_categories[damage_template_name] = category_name
        end
        for damage_template_name, _ in pairs(damage_templates.overrides.__data) do
            damage_categories[damage_template_name] = category_name
        end
    end
end

--Overwrites, because FS is inconsistent
damage_categories["heavy_tank"] = "mloc_1_melee_weapon_damage"
damage_categories["default_powersword_heavy"] = "mloc_1_melee_weapon_damage"
damage_categories["ogryn_thumper_p1_m2_default"] = "mloc_2_ranged_weapon_damage"
damage_categories["force_staff_demolition_default"] = "mloc_2_ranged_weapon_damage"
damage_categories["ogryn_thumper_p1_m2_default_instant"] = "mloc_2_ranged_weapon_damage"
damage_categories["ogryn_thumper_p1_m2_close"] = "mloc_2_ranged_weapon_damage"
damage_categories["ogryn_thumper_p1_m2_close_instant"] = "mloc_2_ranged_weapon_damage"
damage_categories["force_staff_demolition_close"] = "mloc_2_ranged_weapon_damage"
damage_categories["plasma_demolition"] = "mloc_2_ranged_weapon_damage"
damage_categories["adamant_companion_pounce"] = "mloc_9_companion"
damage_categories["adamant_companion_human_pounce"] = "mloc_9_companion"
damage_categories["adamant_companion_ogryn_pounce"] = "mloc_9_companion"
damage_categories["adamant_companion_monster_pounce"] = "mloc_9_companion"
damage_categories["adamant_companion_initial_pounce"] = "mloc_9_companion"
damage_categories["adamant_companion_no_damage_pounce"] = "mloc_9_companion"
damage_categories["psyker_heavy_swings_shock"] = "mloc_3_blitz_damage"
damage_categories["psyker_smite_kill"] = "mloc_3_blitz_damage"
damage_categories["psyker_protectorate_channel_chain_lightning_activated"] = "mloc_3_blitz_damage"
damage_categories["psyker_protectorate_spread_chain_lightning_interval"] = "mloc_3_blitz_damage"
damage_categories["psyker_protectorate_chain_lighting"] = "mloc_3_blitz_damage"
damage_categories["psyker_throwing_knives"] = "mloc_3_blitz_damage"
damage_categories["psyker_throwing_knives_aimed"] = "mloc_3_blitz_damage"
damage_categories["psyker_throwing_knives_aimed_pierce"] = "mloc_3_blitz_damage"
damage_categories["psyker_throwing_knives_psychic_fortress"] = "mloc_3_blitz_damage"
damage_categories["zealot_throwing_knives"] = "mloc_3_blitz_damage"
damage_categories["shockmaul_stun_interval_damage"] = "mloc_5_debuff_damage"
damage_categories["shockmaul_shield_stun_interval_damage"] = "mloc_5_debuff_damage"

damage_profile_templates = nil

return damage_categories