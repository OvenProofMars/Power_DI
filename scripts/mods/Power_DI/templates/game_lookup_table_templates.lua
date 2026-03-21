--Generates the lookup tables, still need to write a lookup manager for adding new lookups via the api--
local mod = get_mod("Power_DI")

local function clone_plain_table(input_table, seen)
    if type(input_table) ~= "table" then
        return input_table
    end

    seen = seen or {}
    if seen[input_table] then
        return seen[input_table]
    end

    local output = {}
    seen[input_table] = output

    for k, v in pairs(input_table) do
        output[clone_plain_table(k, seen)] = clone_plain_table(v, seen)
    end

    return output
end

local game_lookup_tables = {
    BuffTemplates = clone_plain_table(require("scripts/settings/buff/buff_templates")),
    ArchetypeTalents = clone_plain_table(require("scripts/settings/ability/archetype_talents/archetype_talents")),
    weapon_trait_templates = clone_plain_table(require("scripts/settings/equipment/weapon_traits/weapon_trait_templates")),
}

for k, v in pairs(NetworkLookup) do
    if type(v) == "table" then
        game_lookup_tables[k] = clone_plain_table(v)
    end
end

return game_lookup_tables
