--Custom lookup table for combat abilities--
local combat_abilities = {
	psyker_shout = {
		display_name = "loc_talent_psyker_shout_vent_warp_charge",
		use_ability_charge_action = "action_shout",
		action_type = "current_action_name",
	},
	psyker_stance = {
		display_name = "loc_talent_psyker_combat_ability_overcharge_stance",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
	psyker_overcharge_stance = {
		display_name = "loc_talent_psyker_combat_ability_overcharge_stance",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
	ogryn_charge = {
		display_name = "loc_talent_ogryn_bull_rush_distance",
		use_ability_charge_action = "action_state_change",
		action_type = "previous_action_name",
	},
	ogryn_gunlugger_stance = {
		display_name = "loc_talent_ogryn_combat_ability_special_ammo",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
	ogryn_taunt_shout = {
		display_name = "loc_ability_ogryn_taunt_shout",
		use_ability_charge_action = "action_shout",
		action_type = "current_action_name",
	},
	veteran_combat_ability = {
		display_name = "loc_talent_veteran_combat_ability_stagger_nearby_enemies",
		use_ability_charge_action = "action_veteran_combat_ability",
		action_type = "previous_action_name",
	},
	veteran_stealth_combat_ability = {
		display_name = "loc_talent_veteran_invisibility_on_combat_ability",
		use_ability_charge_action = "action_veteran_combat_ability",
		action_type = "current_action_name",
	},
	zealot_dash = {
		display_name = "loc_talent_maniac_attack_speed_after_dash",
		use_ability_charge_action = "action_state_change",
		action_type = "previous_action_name",
	},
	zealot_invisibility = {
		display_name = "loc_ability_zealot_stealth",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
}
return combat_abilities