--Custom categories for minions--
local minion_categories = {
	renegade_executor = {
		attack_type = "Melee",
		faction = "Scab",
		type = "Elite",
		class = "Mauler",
		display_name = "loc_breed_display_name_renegade_executor",
		armor_type = "Carapace",
		en_name = "Scab Mauler",
  },
	cultist_gunner = {
		attack_type = "Ranged",
		faction = "Dreg",
		type = "Elite",
		class = "Gunner",
		display_name = "loc_breed_display_name_cultist_gunner",
		armor_type = "Unarmoured",
		en_name = "Dreg Gunner"
  },
	chaos_ogryn_bulwark = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Elite",
		class = "Bulwark",
		display_name = "loc_breed_display_name_chaos_ogryn_bulwark",
		armor_type = "Unyielding",
		en_name = "Bulwark"
  },
	chaos_hound = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Specialist",
		class = "Hound",
		display_name = "loc_breed_display_name_chaos_hound",
		armor_type = "Infested",
		en_name = "Pox Hound"
  },
	renegade_captain = {
		faction = "Scab",
		type = "Monstrosity",
		class = "Scab Captain",
		display_name = "loc_breed_display_name_renegade_captain",
		armor_type = "Flak",
		en_name = "Scab Captain"
  },
	renegade_netgunner = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Specialist",
		class = "Trapper",
		display_name = "loc_breed_display_name_renegade_netgunner",
		armor_type = "Maniac",
		en_name = "Scab Trapper"
  },
	renegade_sniper = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Specialist",
		class = "Sniper",
		display_name = "loc_breed_display_name_renegade_sniper",
		armor_type = "Unarmoured",
		en_name = "Scab Sniper"
  },
	renegade_berzerker = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Elite",
		class = "Rager",
		display_name = "loc_breed_display_name_renegade_berzerker",
		armor_type = "Flak",
		en_name = "Scab Rager"
  },
	chaos_plague_ogryn = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Monstrosity",
		class = "Plague Ogryn",
		display_name = "loc_breed_display_name_chaos_plage_ogryn",
		armor_type = "Unyielding",
		en_name = "Plague Ogryn"
  },
	chaos_daemonhost = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Monstrosity",
		class = "Daemonhost",
		display_name = "loc_breed_display_name_chaos_daemonhost",
		armor_type = "Unyielding",
		en_name = "Daemonhost"
  },
	renegade_grenadier = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Specialist",
		class = "Bomber",
		display_name = "loc_breed_display_name_renegade_grenadier",
		armor_type = "Unarmoured",
		en_name = "Scab Bomber"
  },
	cultist_assault = {
		attack_type = "Ranged",
		faction = "Dreg",
		type = "Horde",
		class = "Stalker",
		display_name = "loc_breed_display_name_cultist_assault",
		armor_type = "Unarmoured",
		en_name = "Dreg Stalker"
  },
	chaos_ogryn_executor = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Elite",
		class = "Crusher",
		display_name = "loc_breed_display_name_chaos_ogryn_executor",
		armor_type = "Carapace",
		en_name = "Crusher"
  },
	human = {
		attack_type = "Player",
		faction = "Imperium",
		type = "Player",
		class = "Player",
		armor_type = "Player",
  },
	renegade_melee = {
		attack_type = "Melee",
		faction = "Scab",
		type = "Horde",
		class = "Bruiser",
		display_name = "loc_breed_display_name_renegade_melee",
		armor_type = "Unarmoured",
		en_name = "Scab Bruiser"
  },
	ogryn = {
		attack_type = "Player",
		faction = "Imperium",
		type = "Player",
		class = "Player",
		armor_type = "Player",
  },
	chaos_spawn = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Monstrosity",
		class = "Chaos Spawn",
		display_name = "loc_breed_display_name_chaos_spawn",
		armor_type = "Unyielding",
		en_name = "Chaos Spawn"
  },
	chaos_newly_infected = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Horde",
		class = "Basic",
		display_name = "loc_breed_display_name_chaos_newly_infected",
		armor_type = "Unarmoured",
		en_name = "Groaner"
  },
	renegade_twin_captain = {
		attack_type = "Ranged",
		faction = "Dreg",
		type = "Monstrosity",
		class = "Rodin Karnak",
		display_name = "loc_breed_display_name_renegade_twin_captain",
		armor_type = "Carapace",
		en_name = "Rodin Karnak"
  },
	cultist_berzerker = {
		attack_type = "Melee",
		faction = "Dreg",
		type = "Elite",
		class = "Rager",
		display_name = "loc_breed_display_name_cultist_berzerker",
		armor_type = "Maniac",
		en_name = "Dreg Rager"
  },
	renegade_gunner = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Elite",
		class = "Gunner",
		display_name = "loc_breed_display_name_renegade_gunner",
		armor_type = "Flak",
		en_name = "Scab Gunner"
  },
	renegade_shocktrooper = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Elite",
		class = "Gunner",
		display_name = "loc_breed_display_name_renegade_shocktrooper",
		armor_type = "Flak",
		en_name = "Scab Shotgunner"
  },
	chaos_ogryn_gunner = {
		attack_type = "Ranged",
		faction = "Chaos",
		type = "Elite",
		class = "Reaper",
		display_name = "loc_breed_display_name_chaos_ogryn_gunner",
		armor_type = "Unyielding",
		en_name = "Reaper"
  },
	cultist_shocktrooper = {
		attack_type = "Ranged",
		faction = "Dreg",
		type = "Elite",
		class = "Gunner",
		display_name = "loc_breed_display_name_cultist_shocktrooper",
		armor_type = "Unarmoured",
		en_name = "Dreg Shotgunner"
  },
	renegade_flamer = {
		attack_type = "Ranged",
		faction = "chaos",
		type = "Specialist",
		class = "Flamer",
		display_name = "loc_breed_display_name_renegade_flamer",
		armor_type = "Maniac",
		en_name = "Scab Flamer"
  },
	chaos_poxwalker = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Horde",
		class = "Basic",
		display_name = "loc_breed_display_name_chaos_poxwalker",
		armor_type = "Infested",
		en_name = "Poxwalker"
  },
	cultist_mutant = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Specialist",
		class = "Mutant",
		display_name = "loc_breed_display_name_cultist_mutant",
		armor_type = "Maniac",
		en_name = "Mutant"
  },
	renegade_twin_captain_two = {
		attack_type = "Melee",
		faction = "Scab",
		type = "Monstrosity",
		class = "Rinda Karnak",
		display_name = "loc_breed_display_name_renegade_twin_captain_two",
		armor_type = "Carapace",
		en_name = "Rinda Karnak"
  },
	chaos_beast_of_nurgle = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Monstrosity",
		class = "Beast of Nurgle",
		display_name = "loc_breed_display_name_chaos_beast_of_nurgle",
		armor_type = "Unyielding",
		en_name = "Beast of Nurgle"
  },
	chaos_poxwalker_bomber = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Specialist",
		class = "Burster",
		display_name = "loc_breed_display_name_chaos_poxwalker_bomber",
		armor_type = "Infested",
		en_name = "Poxburster"
  },
	cultist_melee = {
		attack_type = "Melee",
		faction = "Dreg",
		type = "Horde",
		class = "Bruiser",
		display_name = "loc_breed_display_name_cultist_melee",
		armor_type = "Flak",
		en_name = "Dreg Bruiser"
  },
	cultist_flamer = {
		attack_type = "Ranged",
		faction = "Dreg",
		type = "Specialist",
		class = "Flamer",
		display_name = "loc_breed_display_name_cultist_flamer",
		armor_type = "Maniac",
		en_name = "Dreg Tox Flamer"
  },
	renegade_assault = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Horde",
		class = "Stalker",
		display_name = "loc_breed_display_name_renegade_assault",
		armor_type = "Flak",
		en_name = "Scab Stalker"
  },
	renegade_rifleman = {
		attack_type = "Ranged",
		faction = "Scab",
		type = "Horde",
		class = "Shooter",
		display_name = "loc_breed_display_name_renegade_rifleman",
		armor_type = "Flak",
		en_name = "Scab Shooter"
  },
	chaos_hound_mutator = {
		attack_type = "Melee",
		faction = "Chaos",
		type = "Specialist",
		class = "Hound",
		display_name = "loc_breed_display_name_chaos_hound",
		armor_type = "Infested",
		en_name = "Pox Hound"
  }
 }
 return minion_categories
