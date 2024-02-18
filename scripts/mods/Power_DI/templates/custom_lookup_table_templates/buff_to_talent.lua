local DMF = get_mod("DMF")
local ArchetypeTalents = require("scripts/settings/ability/archetype_talents/archetype_talents")
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

return buff_to_talent