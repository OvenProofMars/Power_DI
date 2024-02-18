--Module to do real time generation, currently not used--

local mod = get_mod("Power_DI")
local DMF = get_mod("DMF")
local PDI
local realtime_generation_manager = {}
local realtime_reports = {"player_attack_report"}
local realtime_config = {}
local realtime_generation_queue = {}
local last_update = 0
local min_time_between_updates = 5

local function generation_allowed()
    return PDI.utilities.in_game() and PDI.utilities.has_gameplay_timer() and #realtime_generation_queue == 0 and (os.clock() - last_update > min_time_between_updates)
end
local function handle_queue()
    if #realtime_generation_queue > 0 then
        local queue_item = realtime_generation_queue[1]
        local template = queue_item.template
        local generation_function
        if queue_item.type == "dataset" then
            generation_function = PDI.dataset_manager.generate_dataset
        elseif queue_item.type == "report" then
            generation_function = PDI.report_manager.generate_report
        else
            error("unknown realtime generation type")
        end
        generation_function(template)
        :next(
            function()
                table.remove(realtime_generation_queue,1)
                last_update = os.clock()
                handle_queue()
            end
        )
    end
end

realtime_generation_manager.init = function (input_table)
    PDI = input_table
end
realtime_generation_manager.update = function ()
    if generation_allowed() then
        for _, dataset_config in pairs(realtime_config) do
            local queue_item = {}
            queue_item.type = "dataset"
            queue_item.template = dataset_config.template
            table.insert(realtime_generation_queue, queue_item)
            for _, report_template in pairs(dataset_config.related_reports) do
                local queue_item = {}
                queue_item.type = "report"
                queue_item.template = report_template
                table.insert(realtime_generation_queue, queue_item)
            end
        end
        handle_queue()
    end
end
realtime_generation_manager.prepare_session = function(session)
    realtime_config = {}
    for _, report_name in ipairs(realtime_reports) do
        local report_template = PDI.report_manager.get_report_template(report_name)
        local dataset_name = report_template.dataset_name
        local dataset_template = PDI.dataset_manager.get_dataset_template(report_template.dataset_name)
        local dataset_config = realtime_config[dataset_name]
        if not dataset_config then
            realtime_config[dataset_name] = {}
            dataset_config = realtime_config[dataset_name]
            dataset_config.template = dataset_template
        end
        dataset_config.related_reports = dataset_config.related_reports or {}
        dataset_config.related_reports[report_name] = report_template
    end
end

return realtime_generation_manager