--Custom lookup table for combat abilities--
local combat_abilities = {
	psyker_shout = {
		display_name = "Venting Shriek",
		use_ability_charge_action = "action_shout",
		action_type = "current_action_name",
	},
	psyker_stance = {
		display_name = "Scrier's Gaze",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
	psyker_overcharge_stance = {
		display_name = "Scrier's Gaze",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
	ogryn_charge = {
		display_name = "Indomitable",
		use_ability_charge_action = "action_state_change",
		action_type = "previous_action_name",
	},
	ogryn_gunlugger_stance = {
		display_name = "Point-Blank Barrage",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
	ogryn_taunt_shout = {
		display_name = "Loyal Protector",
		use_ability_charge_action = "action_shout",
		action_type = "current_action_name",
	},
	veteran_combat_ability = {
		display_name = "Voice of Command",
		use_ability_charge_action = "action_veteran_combat_ability",
		action_type = "previous_action_name",
	},
	veteran_stealth_combat_ability = {
		display_name = "Infiltrate",
		use_ability_charge_action = "action_veteran_combat_ability",
		action_type = "current_action_name",
	},
	zealot_dash = {
		display_name = "Fury of the Faithful",
		use_ability_charge_action = "action_state_change",
		action_type = "previous_action_name",
	},
	zealot_invisibility = {
		display_name = "Shroudfield",
		use_ability_charge_action = "action_stance_change",
		action_type = "current_action_name",
	},
}

-- psyker_shout_action_shout = "Venting Shriek",
-- psyker_stance_action_stance_change = "Scrier's Gaze",
-- psyker_overcharge_stance_action_stance_change = "Scrier's Gaze 2",
-- ogryn_charge_action_state_change = "Indomitable",
-- ogryn_gunlugger_stance_action_stance_change = "Point-Blank Barrage",
-- ogryn_taunt_shout_action_shout = "Loyal Protector",
-- veteran_combat_ability_action_veteran_combat_ability = "Executioner's Stance",
-- veteran_stealth_combat_ability_action_veteran_combat_ability = "Infiltrate",
-- zealot_dash_action_state_change = "Fury of the Faithful",
-- zealot_invisibility_action_stance_change = "Shroudfield",

return combat_abilities