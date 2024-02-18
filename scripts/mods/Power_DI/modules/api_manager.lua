local mod = get_mod("Power_DI")
local PDI
local api_manager = {}

--Internal functions--
api_manager.init = function(input_table)
    PDI = input_table

    --Utilities--
    mod.utilities = {}
    mod.utilities.get_gameplay_time = function()
        return PDI.utilities.get_gameplay_time()
    end

    --Datasource API--
    mod.datasources = {}
    mod.datasources.get_available_datasources = function()
        return PDI.datasource_manager.get_available_datasources()
    end
    mod.datasources.register_datasource = function(datasource_template)
        return PDI.datasource_manager.register_datasource(datasource_template)
    end

    --Dataset API--
    mod.datasets = {}
    mod.datasets.get_available_datasets = function()
        return PDI.dataset_manager.get_available_datasets()
    end
    mod.datasets.register_dataset = function(dataset_template)
        return PDI.dataset_manager.register_dataset(dataset_template)
    end

    --Lookup tables API--
    mod.lookup_tables = {}
    mod.lookup_tables.get_available_lookup_tables = function()
        return PDI.lookup_manager.get_available_lookup_tables()
    end
    mod.lookup_tables.register_lookup_table = function(lookup_table_template)
        return PDI.lookup_manager.register_lookup_table(lookup_table_template)
    end

    --Report API--
    mod.reports = {}
    mod.reports.get_available_reports = function()
        return PDI.report_manager.get_available_reports()
    end
    mod.reports.register_report = function(report_template)
        return PDI.report_manager.register_report(report_template)
    end
end

return api_manager