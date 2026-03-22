--Generates the lookup tables, still need to write a lookup manager for adding new lookups via the api--
local mod = get_mod("Power_DI")

local game_lookup_tables = {
    BuffTemplates = table.clone(require("scripts/settings/buff/buff_templates")),
    ArchetypeTalents = table.clone(require("scripts/settings/ability/archetype_talents/archetype_talents")),
    weapon_trait_templates = table.clone(require("scripts/settings/equipment/weapon_traits/weapon_trait_templates")),
}

local function clone_table(t)
	local clone = {}

	for key, value in pairs(t) do
		if value == t then
			clone[key] = clone
		elseif type(value) == "table" then
			clone[key] = clone_table(value)
		else
			clone[key] = value
		end
	end

	return clone
end

for k, v in pairs(NetworkLookup) do
    if type(v) == "table" then
    game_lookup_tables[k] = clone_table(v)
    end
end

return game_lookup_tables