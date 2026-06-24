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
        require("scripts/settings/equipment/weapon_templates/crowbars/settings_templates/crowbar_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/dual_shivs/settings_templates/dual_shivs_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/saws/settings_templates/saw_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/transonic_sword_transonic_knife/settings_templates/transonic_sword_transonic_knife_damage_profile_templates"),
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
        require("scripts/settings/equipment/weapon_templates/dual_autopistols/settings_templates/dual_autopistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/dual_stub_pistols/settings_templates/dual_stub_pistols_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/needlepistols/settings_templates/needlepistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/arc_rifle/settings_templates/arc_rifle_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/phosphor_pistol/settings_templates/phosphor_pistol_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/galvanic_rifle/settings_templates/galvanic_rifle_damage_profile_templates"),
    },
  ["mloc_3_blitz_damage"] = {
        require("scripts/settings/damage/damage_profiles/grenade_damage_profile_templates"),        
        require("scripts/settings/damage/damage_profiles/smiter_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/psyker_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/zealot_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/veteran_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/ogryn_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/cryptic_damage_profile_templates"),
        require("scripts/settings/equipment/weapon_templates/servo_skull/companion_servo_skull_lasgun_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/demolitions_damage_profile_templates"),
    },
    ["mloc_4_combat_ability_damage"] = {
        require("scripts/settings/damage/damage_profiles/archetypes/psyker_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/zealot_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/veteran_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/ogryn_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/cryptic_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/archetypes/adamant_damage_profile_templates"),        
    },
    ["mloc_5_debuff_damage"] = {
        require("scripts/settings/damage/damage_profiles/buff_damage_profile_templates"),
    },
    ["mloc_6_environmental_damage"] = {
        require("scripts/settings/damage/damage_profiles/prop_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/minion_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/trap_damage_profile_templates"),
    },
    ["mloc_7_other_damage"] = {
        require("scripts/settings/damage/damage_profiles/common_damage_profile_templates"),
        require("scripts/settings/damage/damage_profiles/artillery_damage_profile_templates"),
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
damage_categories["broker_flash_grenade"] = "mloc_3_blitz_damage"
damage_categories["broker_flash_grenade_close"] = "mloc_3_blitz_damage"
damage_categories["broker_flash_grenade_impact"] = "mloc_3_blitz_damage"
damage_categories["broker_missile_launcher_explosion"] = "mloc_3_blitz_damage"
damage_categories["broker_missile_launcher_explosion_close"] = "mloc_3_blitz_damage"
damage_categories["broker_missile_launcher_impact"] = "mloc_3_blitz_damage"
damage_categories["missile_launcher_knockback"] = "mloc_3_blitz_damage"
damage_categories["broker_punk_rage_shout"] = "mloc_4_combat_ability_damage"
damage_categories["broker_stimm_field"] = "mloc_4_combat_ability_damage"
damage_categories["broker_stimm_field_close"] = "mloc_4_combat_ability_damage"
damage_categories["broker_vultures_mark_aoe_stagger"] = "mloc_3_blitz_damage"
damage_categories["arc_grenade_impact"] = "mloc_3_blitz_damage"
damage_categories["arc_grenade_explosion"] = "mloc_3_blitz_damage"
damage_categories["arc_rifle_p1_m1_damage"] = "mloc_2_ranged_weapon_damage"
damage_categories["arc_rifle_p1_m1_damage_braced"] = "mloc_2_ranged_weapon_damage"
damage_categories["arc_rifle_arc_chain_lightning_link_damage"] = "mloc_2_ranged_weapon_damage"
damage_categories["arc_rifle_arc_chain_lightning_link_damage_brace"] = "mloc_2_ranged_weapon_damage"
damage_categories["phosphor_pistol_backblast_explosion"] = "mloc_2_ranged_weapon_damage"

-- Cryptic
damage_categories["cryptic_arc_chain_lightning_link_damage"] = "mloc_3_blitz_damage"
damage_categories["arc_damage_on_melee_hit"] = "mloc_5_debuff_damage"
damage_categories["cryptic_discharge_shock_damage"] = "mloc_4_combat_ability_damage"
damage_categories["cryptic_discharge_weapon_shock"] = "mloc_4_combat_ability_damage"
damage_categories["cryptic_discharge_explosion"] = "mloc_4_combat_ability_damage"
damage_categories["cryptic_discharge_weapon_malfunction_explosion"] = "mloc_4_combat_ability_damage"
damage_categories["cryptic_overload_keystone_debuff_explosion"] = "mloc_4_combat_ability_damage"
damage_categories["cryptic_corruption_resistance_doom_tick"] = "mloc_7_other_damage"
damage_categories["companion_servo_skull_flamer"] = "mloc_9_companion"
damage_categories["arc_grenade"] = "mloc_3_blitz_damage"
damage_categories["arc_grenade_chain_jump_damage"] = "mloc_3_blitz_damage"
damage_categories["discharge_chain_jump_damage"] = "mloc_3_blitz_damage"
damage_categories["force_field_chain_jump_damage"] = "mloc_4_combat_ability_damage"

-- Shock Maul p3 & Power Sword p3
damage_categories["powermaul_p3_light_smiter"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_light_smiter_pushfollow"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_light_linesman"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_light_tank"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_heavy_tank"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_heavy_smiter"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_pushfollow_special"] = "mloc_1_melee_weapon_damage"
damage_categories["powermaul_p3_arc_chain_lightning_link_damage"] = "mloc_1_melee_weapon_damage"

damage_categories["light_sword_linesman_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["light_sword_linesman_active_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["light_sword_smiter_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["light_sword_smiter_active_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["light_sword_stab_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["light_sword_stab_active_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["heavy_sword_linesman_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["heavy_sword_linesman_active_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["heavy_sword_smiter_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["heavy_sword_smiter_active_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["heavy_sword_stab_p3"] = "mloc_1_melee_weapon_damage"
damage_categories["heavy_sword_stab_active_p3"] = "mloc_1_melee_weapon_damage"

-- Transonic Sword & Knife
damage_categories["transonic_sword_transonic_knife_light_linesman"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_light_linesman_ap"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_light_ninja"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_light_ninja_ap"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_light_smiter"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_light_smiter_ap"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_heavy_linesman"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_heavy_linesman_ap"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_heavy_double_linesman"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_heavy_smiter_ap"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_heavy_double_smiter_ap"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_special_linesman"] = "mloc_1_melee_weapon_damage"
damage_categories["transonic_sword_transonic_knife_special_smiter_ap"] = "mloc_1_melee_weapon_damage"

damage_profile_templates = nil

return damage_categories