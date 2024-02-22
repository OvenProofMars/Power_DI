local mod = get_mod("Power_DI")
local PDI, user_reports
local report_manager = {}
report_manager.registered_reports = {}

--Generate the filter function from a string, function will be run in separate environment--
local function generate_filter_function (template)
    PDI.debug("generate_filter_function", "start")
    local registered_dataset = PDI.dataset_manager.get_dataset_template(template.dataset_name)
    local function_string = template.filter_function_string
    if not function_string then
        local function_string_prefix = [[local arg1 = select(1, ...) return ]]
        if template.filters[1] and template.filters[1] ~= "" then
            for i = 1,#template.filters,1 do
                local filter_string = template.filters[i]
                function_string = (function_string or "").."("..filter_string..")"
                if i < #template.filters then
                    function_string = function_string.." and "
                end
            end
            for field_name, _ in pairs(registered_dataset.legend) do
                function_string = string.gsub(function_string,field_name,"localize(arg1."..field_name..")")
            end
            function_string = string.gsub(function_string,"=","==")
            function_string = string.gsub(function_string,"~","~=")
            function_string = function_string_prefix..function_string
        else
            function_string = "return true"
        end
    end
    local filter_function = Mods.lua.loadstring(function_string)
    local functions_table = {
        select=select,
        localize = PDI.utilities.localize
    }
    setfenv(filter_function, functions_table)
    PDI.debug("generate_filter_function", "start")
    return filter_function
end
--Generate the calculated field functions from strings, functions will be run in separate environment--
local function generate_calculated_field_functions (template)
    PDI.debug("generate_calculated_field_functions", "start")
    local calculated_field_functions = {}
    local registered_dataset = PDI.dataset_manager.get_dataset_template(template.dataset_name)
    local value_templates = template.values

    for _, value_template in ipairs(value_templates) do
        if value_template.type == "calculated_field" then
            local function_string = value_template.function_string
            local function_string_prefix = [[local arg1 = select(1, ...) return ]]
            for _, value_template_2 in ipairs(value_templates) do
                local field_name = value_template_2.label                
                if value_template_2.type ~= "calculated_field" then
                    function_string = string.gsub(function_string, field_name, "arg1."..field_name)
                end
            end
            function_string = function_string
            function_string = string.gsub(function_string,"=","==")
            function_string = function_string_prefix..function_string
            
            local filter_function = Mods.lua.loadstring(function_string)
            setfenv(filter_function, {select=select})
            calculated_field_functions[value_template.label] = filter_function
        end
    end
    PDI.debug("generate_calculated_field_functions", "end")
    return calculated_field_functions
end

--Generate the functions that get used to format the final values--
local function generate_field_format_functions (template)
    PDI.debug("generate_field_format_functions", "start")

    local field_format_functions = {}
    --local registered_dataset = PDI.dataset_manager.get_dataset_template(template.dataset_name)
    local value_templates = template.values

    for _, value_template in ipairs(value_templates) do
        if value_template.format == "number" then
            local function number_format(input)
               local value = input[value_template.label]
               return tostring(math.floor(value)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
            end
            field_format_functions[value_template.label] = number_format
        elseif value_template.format == "percentage" then
            local function percent_format(input)
                local value = input[value_template.label]
                local output = string.format("%.1f", tostring(value*100))
                output = output.."%"
                
                return output
            end
            field_format_functions[value_template.label] = percent_format
        end
    end
    PDI.debug("generate_field_format_functions", "end")
    return field_format_functions
end

--Coroutine that generates a legend of the values of the fields in a dataset, currently not used--
-- local function generate_legend_cache_coroutine(template)
--     PDI.debug("generate_legend_cache_coroutine", "start")
--     legend_cache = {}
--     local dataset = PDI.data.session_data.datasets[template.dataset_name]
--     for _, item in pairs(dataset) do
--         for value_name, value in pairs(item) do
--             if PDI.coroutine_manager.must_yield() then
--                 coroutine:yield()
--             end
--             legend_cache[value_name] = legend_cache[value_name] or {}
--             legend_cache[value_name].type = type(value)
--             legend_cache[value_name].values = legend_cache[value_name].values or {}
--             legend_cache[value_name].values[value] = legend_cache[value_name].values[value] and legend_cache[value_name].values[value] +1 or 1
--         end
--     end
--     PDI.debug("generate_legend_cache_coroutine", "end")
-- end

--Coroutine that generates a pivot table from a dataset--
local function generate_pivot_table_report_coroutine(template)
    PDI.debug("generate_pivot_table_report_coroutine", "start")

    local filter_function = generate_filter_function(template)
    local dataset_template = PDI.dataset_manager.get_dataset_template(template.dataset_name)
    local column_type = dataset_template.legend[template.columns[1]]
    local dataset = PDI.data.session_data.datasets[template.dataset_name]
    local report_output = {}
    report_output.data = {}
    report_output.values_as_rows = {}
    report_output.rows = {}
    report_output.columns = {}
    report_output.template = table.clone(template)

    local output_data =  report_output.data

    PDI.debug("generate_pivot_table_report_coroutine", "group data start")
    for _, item in ipairs(dataset) do
        if PDI.coroutine_manager.must_yield() then
            coroutine:yield()
        end
        if filter_function(item) then

            local current_totals_output = output_data

            for _, column_name in ipairs(template.columns) do
                local column_value = item[column_name] or "nil"
                current_totals_output["child_columns"] = current_totals_output["child_columns"] or {}
                current_totals_output = current_totals_output["child_columns"]
                current_totals_output[column_value] = current_totals_output[column_value]  or {}
                current_totals_output = current_totals_output[column_value]

                for _, value_template in ipairs(template.values) do
                    local current_value_ouput = current_totals_output
                    local value_type = value_template.type
                    local value_label = value_template.label
                    local field_name = value_template.field_name
                    current_value_ouput["values"] = current_value_ouput["values"] or {}
                    current_value_ouput = current_value_ouput["values"]
                    if value_type == "sum" then
                        current_value_ouput[value_label] = (current_value_ouput[value_label] or 0) + (item[field_name] or 0)
                    elseif value_type == "count" then
                        current_value_ouput[value_label] = (current_value_ouput[value_label] or 0) + 1
                    end                
                end
            end

            local current_row_output = output_data

            for _, row_name in ipairs(template.rows) do
                local row_value = item[row_name] or "nil"
                current_row_output["child_rows"] = current_row_output["child_rows"] or {}
                current_row_output = current_row_output["child_rows"]
                current_row_output[row_value] = current_row_output[row_value] or {}
                current_row_output = current_row_output[row_value]

                local current_column_output = current_row_output

                for _, column_name in ipairs(template.columns) do
                    local column_value = item[column_name] or "nil"
                    current_column_output["child_columns"] = current_column_output["child_columns"] or {}
                    current_column_output = current_column_output["child_columns"]
                    current_column_output[column_value] = current_column_output[column_value]  or {}
                    current_column_output = current_column_output[column_value]

                    for _, value_template in ipairs(template.values) do
                        local current_value_ouput = current_column_output
                        local value_type = value_template.type
                        local value_label = value_template.label
                        local field_name = value_template.field_name
                        current_value_ouput["values"] = current_value_ouput["values"] or {}
                        current_value_ouput = current_value_ouput["values"]
                        if value_type == "sum" then
                            current_value_ouput[value_label] = (current_value_ouput[value_label] or 0) + (item[field_name] or 0)
                        elseif value_type == "count" then
                            current_value_ouput[value_label] = (current_value_ouput[value_label] or 0) + 1
                        end                
                    end
                end
            end
        end
    end
    PDI.debug("generate_pivot_table_report_coroutine", "group data end")

    local function add_calculated_fields(input_table, functions_table)
        local columns_table = input_table.child_columns
        if columns_table then
            for _, column_table in pairs(columns_table) do

                if PDI.coroutine_manager.must_yield() then
                    coroutine:yield()
                end

                local values_table = column_table.values
                for value_name, calculated_field_function in pairs(functions_table) do
                    local calculated_value = calculated_field_function(values_table)
                    if calculated_value == math.huge then
                        calculated_value = 0
                    end
                    values_table[value_name] = calculated_value
                end
                local child_columns_table = column_table.child_columns
                if child_columns_table then
                    for _, column_table in pairs(child_columns_table) do
                        add_calculated_fields(column_table, functions_table)
                    end   
                end
            end
        end
        local rows_table = input_table.child_rows
        if rows_table then
            for _, row_table in pairs(rows_table) do

                if PDI.coroutine_manager.must_yield() then
                    coroutine:yield()
                end

                add_calculated_fields(row_table,functions_table)
            end   
        end
    end

    local calculated_field_functions = generate_calculated_field_functions(template)
    local field_format_functions = generate_field_format_functions(template)

    PDI.debug("generate_pivot_table_report_coroutine", "calculated fields start")
    add_calculated_fields(report_output.data, calculated_field_functions)
    PDI.debug("generate_pivot_table_report_coroutine", "calculated fields end")
    PDI.debug("generate_pivot_table_report_coroutine", "format fields start")
    add_calculated_fields(report_output.data, field_format_functions)
    PDI.debug("generate_pivot_table_report_coroutine", "format fields end")

    local function generate_rows_structure(input_table, output_table)
        local rows_table = input_table.child_rows
        if rows_table then
            for row_name, row_table in pairs(rows_table) do

                if PDI.coroutine_manager.must_yield() then
                    coroutine:yield()
                end

                local index = #output_table+1
                output_table[index] = {}
                local output_row_table = output_table[index]
                output_row_table.name = row_name

                if row_table.child_rows then
                    output_row_table.children = {}
                    generate_rows_structure(row_table, output_row_table.children)
                end
            end
            table.sort(output_table, function(a,b) return a.name < b.name end)
        end
    end

    PDI.debug("generate_pivot_table_report_coroutine", "row structure start")
    generate_rows_structure(report_output.data, report_output.rows)
    PDI.debug("generate_pivot_table_report_coroutine", "row structure end")

    local function generate_columns_structure(input_table, output_table)
        local columns_table = input_table.child_columns
        if columns_table then
            for column_name, column_table in pairs(columns_table) do

                if PDI.coroutine_manager.must_yield() then
                    coroutine:yield()
                end

                local index = #output_table+1
                output_table[index] = {}
                local output_column_table = output_table[index]
                
                output_column_table.name = column_name
                output_column_table.type = column_type

                if column_table.child_columns then
                    output_column_table.children = {}
                    generate_columns_structure(column_table, output_column_table.children)
                end
            end
            table.sort(output_table, function(a,b) return a.name < b.name end)
        end
    end
    
    PDI.debug("generate_pivot_table_report_coroutine", "column structure start")
    generate_columns_structure(report_output.data, report_output.columns)
    PDI.debug("generate_pivot_table_report_coroutine", "column structure end")

    local function generate_values_structure_columns(source_table, output_table, columns_array, value_name)
        
        local source_columns_table = source_table.child_columns
        if source_columns_table then
            for k, v in ipairs(columns_array) do

                if PDI.coroutine_manager.must_yield() then
                    coroutine:yield()
                end

                local source_column_table = source_columns_table and source_columns_table[v.name]
                local value = source_column_table and source_column_table.values and source_column_table.values[value_name] or 0
                table.insert(output_table, value)
                for k2, v2 in ipairs(source_columns_table) do
                    generate_values_structure_columns(v2, output_table, columns_array, value_name)
                end
            end
        end
    end
    local function generate_values_structure(source_table, indexed_array, indexed_columns_array, value_name)

        indexed_array.values = {}
        local values_array = indexed_array.values

        generate_values_structure_columns(source_table, values_array, indexed_columns_array, value_name)
        
        local indexed_child_rows = indexed_array.children
        if indexed_child_rows then
            for _, indexed_child_row in pairs(indexed_child_rows) do
                local source_child_row = source_table.child_rows[indexed_child_row.name]
                generate_values_structure(source_child_row, indexed_child_row, indexed_columns_array, value_name)
            end
        end
    end

    local visible_fields = {}

    for _, value_template in ipairs(template.values) do
        if value_template.visible then
            table.insert(visible_fields, value_template.label)
        end
    end

    PDI.debug("generate_pivot_table_report_coroutine", "values structure start")
    for _, field_name in ipairs(visible_fields) do
        local output_table = report_output.values_as_rows
        local index = #output_table+1
        output_table[index] = {}
        output_table = output_table[index]
        output_table.name = field_name
        output_table.children = table.clone(report_output.rows)
        generate_values_structure(report_output.data, output_table, report_output.columns, field_name)
    end
    PDI.debug("generate_pivot_table_report_coroutine", "values structure end")
    PDI.data.session_data.reports[template.id] = report_output
    PDI.debug("generate_pivot_table_report_coroutine", "end")
    return report_output
end

--These function still need to be created--
local function generate_table_report_coroutine(template)
end
local function generate_graph_report_coroutine(template)
end
local function generate_timeline_report_coroutine(template)
end
--------------------------------------------

--Initialize the module, registers the report templates--
report_manager.init = function (input_table)
    PDI = input_table
    report_manager.report_templates = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\report_templates]])
    for _, report_template in pairs(report_manager.report_templates) do
        mod.reports.register_report(report_template)      
    end
end

--Update function, currently not used--
report_manager.update = function()

end

--Function to register a report, accessible via the API--
report_manager.register_report = function(template)
    if not template or type(template) ~= "table" then
        error("required report template not supplied")
    elseif not template.name and not type(template.name) == "string" then
        error("template does not contain a valid name")
    else
        report_manager.registered_reports[template.name] = template
        return true
    end
end

--Function to get a list of the available reports, accessible via the API--
report_manager.get_available_reports = function()
    local output = {}
    local registered_reports = report_manager.registered_reports
    for report_name, _ in pairs(registered_reports) do
        output[#output+1] = report_name
    end
    table.sort(output)
    return output
end

--Function to add a custom report to the user's save data--
report_manager.add_user_report = function(report_template)
    local uuid = PDI.utilities.uuid()
    report_template.id = uuid
    user_reports[uuid] = report_template
    PDI.save_manager.save_user_data()
    return uuid
end

report_manager.delete_user_report = function(report_id)
    user_reports[report_id] = nil
    PDI.save_manager.save_user_data()
end

report_manager.get_user_reports = function()
    if user_reports then
        return user_reports
    end
    user_reports = PDI.data.save_data.report_templates
    if not user_reports then
        PDI.data.save_data.report_templates = {}
        user_reports = PDI.data.save_data.report_templates
    end
    if not next(user_reports) then
        for _, report_template in pairs(report_manager.registered_reports) do
            local uuid = PDI.utilities.uuid()
            local user_report_template = table.clone(report_template)
            if string.sub(report_template.name,1,5) == "mloc_" then
                user_report_template.name = mod:localize(user_report_template.name)
            end
            user_report_template.id = uuid
            user_report_template.template_name = report_template.name
            user_reports[uuid] = user_report_template
        end
        PDI.save_manager.save_user_data()
    end
    return user_reports
end

--Function to get a report template by name--
report_manager.get_report_template = function(report_name)
    return table.clone(report_manager.registered_reports[report_name])
end

--Function to prepare the session data for report data--
report_manager.prepare_session = function(session)
    session.report_template_hash_lookup = session.report_template_hash_lookup or {}
    session.reports = session.reports or {}
    -- for report_id, _ in pairs(user_reports) do
    --     session.reports[report_id] = session.reports[report_id] or {}
    -- end
end

--Function to create a legend of the values of the fields in a dataset, currently not used--
-- report_manager.generate_legend_cache = function(template)
--     return PDI.coroutine_manager.new(generate_legend_cache_coroutine, template)
-- end

report_manager.check_report_template_hash = function(report_template)
    local report_id = report_template.id
    local report_template_hash = PDI.utilities.hash(report_template)
    local report_hash_lookup = PDI.data.session_data.report_template_hash_lookup
    local report_hash =  report_hash_lookup and report_hash_lookup[report_id]

    return report_hash and report_hash == report_template_hash
end

--Function to generate a report, returns a promise, uses coroutines--
report_manager.generate_report = function(template, force)
    local dataset_manager = PDI.dataset_manager
    local report_id = template.id
    local dataset_hash_check
    local report_hash_check
    local hash_check

    if force then
        hash_check = false
    else
        local dataset_name = template.dataset_name
        local dataset_template = dataset_manager.get_dataset_template(dataset_name)
        dataset_hash_check = dataset_manager.check_dataset_template_hash(dataset_template)
        report_hash_check = report_manager.check_report_template_hash(template)
        hash_check = dataset_hash_check and report_hash_check
    end

    if hash_check then
        local report = PDI.data.session_data.reports[report_id]
        return PDI.promise.resolved({report, true})
    else
        local dataset_name = template.dataset_name
        local promise = PDI.promise:new()
        local dataset_template = dataset_manager.get_dataset_template(dataset_name)
        dataset_manager.generate_dataset(dataset_template, force)
        :next(
            function()
                return PDI.coroutine_manager.new(generate_pivot_table_report_coroutine, template)
            end,
            function(err)
                return promise:reject(err)
            end
        )
        :next(
            function(data)
                if data then
                    local hash = PDI.utilities.hash(template)
                    local report_hash_lookup = PDI.data.session_data.report_template_hash_lookup

                    if force then
                        report_hash_lookup[report_id] = nil
                    else
                        report_hash_lookup[report_id] = hash
                    end
                    
                    return promise:resolve({data, false})
                end
            end,
            function(err)
                return promise:reject(err)
            end
        )
        return promise
    end
end



return report_manager