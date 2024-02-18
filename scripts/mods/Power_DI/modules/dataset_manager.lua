local mod = get_mod("Power_DI")
local PDI
local dataset_manager = {}

dataset_manager.registered_datasets = {}
local shared_data = {}
local function_set, must_yield, is_array, force_dataset_generation

--Wrap a function with a the coroutine yield check--
local function coroutine_wrapper(self,fn)
    local coroutine_function = function(...)
        if must_yield(self) then
            coroutine:yield()
        end
        return fn(...)
    end
    return coroutine_function
end
--Coroutine to clone a datasource to a dataset--
local function clone_datasource_coroutine (self, datasource_name)
    PDI.debug("clone_datasource_coroutine","start")
    if self.datasource_proxies[datasource_name] then
        local function clone(self, t)
            local clone = {}
            for key, value in pairs(t) do
                if PDI.coroutine_manager.must_yield(self) then
                    coroutine:yield()
                end
                if value == t then
                    clone[key] = clone
                elseif type(value) == "table" then
                    clone[key] = table.clone(value)
                else
                    clone[key] = value
                end
            end
            return clone
        end
        self.dataset = clone(self, PDI.data.session_data.datasources[datasource_name])
        PDI.debug("clone_datasource_coroutine","end")
    end
end

--Coroutine to append a dataset with an other datasource--
local function append_datasource_coroutine (self, datasource_name)
    PDI.debug("append_datasource_coroutine", "start")
    if self.datasource_proxies[datasource_name] then
        local input_table = self.dataset
        local datasource = PDI.data.session_data.datasources[datasource_name]
        if is_array(input_table) and is_array(datasource) then
            PDI.debug("append_datasource_coroutine", "array")
            local original_size = #input_table
            for k, v in ipairs(input_table) do
                if must_yield(self) then
                    coroutine.yield()
                end
                input_table[k].original_index = k
            end
            for k, v in ipairs(datasource) do
                if must_yield(self) then
                    coroutine.yield()
                end
                input_table[original_size+k] = table.clone(v)
                input_table[original_size+k].original_index = k
            end
            PDI.debug("append_datasource_coroutine", "end")
        elseif type(input_table) == "table" then
            PDI.debug("append_datasource_coroutine", "table")
            for k, v in pairs(datasource) do
                if must_yield(self) then
                    coroutine.yield()
                end
                input_table[k] = table.clone(v)
            end
            PDI.debug("append_datasource_coroutine", "end")
        end
    end
end

--Coroutine to iterate over a dataset--
local function iterate_dataset_coroutine(self, calculation_function)
    PDI.debug("iterate_dataset_coroutine", "start")
    local calculation_function = coroutine_wrapper(self,calculation_function)
    if is_array(self.dataset) then
        PDI.debug("iterate_dataset_coroutine", "array")
        for k, v in ipairs(self.dataset) do
            calculation_function(k,v)
        end
    else
        PDI.debug("iterate_dataset_coroutine", "table")
        for k, v in pairs(self.dataset) do
            calculation_function(k,v)
        end
    end
    PDI.debug("iterate_dataset_coroutine", "end")
end

--Coroutine to iterate over a datasource--
local function iterate_datasource_coroutine(self, datasource, calculation_function)
    PDI.debug("iterate_datasource_coroutine", "start")
    local calculation_function = coroutine_wrapper(self,calculation_function)
    if is_array(datasource) then
        PDI.debug("iterate_datasource_coroutine", "array")
        for k, v in ipairs(datasource) do
            if type(v) == "table" then
                v = table.clone(v)
            end
            calculation_function(k,v)
        end
    else
        PDI.debug("iterate_datasource_coroutine", "table")
        for k, v in pairs(datasource) do
            if type(v) == "table" then
                v = table.clone(v)
            end
            calculation_function(k,v)
        end
    end
    PDI.debug("iterate_datasource_coroutine", "end")
end

--Coroutine to iterate over a lookup table--
-- local function iterate_lookup_coroutine(self, lookup, calculation_function)
--     PDI.debug("iterate_lookup_coroutine", "start")
--     local calculation_function = coroutine_wrapper(self,calculation_function)
--     if is_array(lookup) then
--         PDI.debug("iterate_lookup_coroutine", "array")
--         for k, v in ipairs(lookup) do
--             if type(v) == "table" then
--                 v = table.clone(v)
--             end
--             calculation_function(k,v)
--         end
--     else
--         PDI.debug("iterate_lookup_coroutine", "table")
--         for k, v in pairs(lookup) do
--             if type(v) == "table" then
--                 v = table.clone(v)
--             end
--             calculation_function(k,v)
--         end
--     end
--     PDI.debug("iterate_lookup_coroutine", "end")
-- end

--Coroutine to sort a dataset--
local function sort_dataset_coroutine (self, sort_function)
    local function set2( t , i , j , ival , jval )
        t[ i ] = ival ; -- lua_rawseti(L, 1, i);
        t[ j ] = jval ; -- lua_rawseti(L, 1, j);
     end
     local function default_comp( a , b )
        return a < b
     end
    local function auxsort( t , l , u , sort_comp )
 
        while l < u do 
            if PDI.coroutine_manager.must_yield(self) then
                coroutine:yield()
            end
           -- sort elements a[l], a[(l+u)/2] and a[u]
     
           do
              local a = t[ l ] -- lua_rawgeti(L, 1, l);
              local b = t[ u ] -- lua_rawgeti(L, 1, u);
     
              if sort_comp( b , a ) then
                 set2( t , l , u , b , a ) -- /* swap a[l] - a[u] */
              end
           end
     
           if u - l == 1 then break end -- only 2 elements
     
           local i = math.floor( ( l + u ) / 2 ) ; -- -- for tail recursion (i).
     
           do
              local a = t[ i ] -- lua_rawgeti(L, 1, i);
              local b = t[ l ] -- lua_rawgeti(L, 1, l);
     
              if sort_comp( a , b ) then -- a[i] < a[l] ?
                 set2( t , i , l , b , a )
              else
                 b = nil -- remove a[l]
                 b = t[ u ]
                 if sort_comp( b , a ) then -- a[u]<a[i] ?
                    set2( t , i , u , b , a )
                 end
              end
           end
     
           if u - l == 2 then break end ; -- only 3 elements
     
           local P = t[ i ] -- Pivot.
           local P2 = P -- lua_pushvalue(L, -1);
           local b = t[ u - 1 ]
     
           set2( t , i , u - 1 , b , P2 )
           -- a[l] <= P == a[u-1] <= a[u], only need to sort from l+1 to u-2 */
     
           i = l ;
     
           local j = u - 1 ; -- for tail recursion (j).
     
           while true do -- for( ; ; )
              -- invariant: a[l..i] <= P <= a[j..u]
              -- repeat ++i until a[i] >= P
     
              i = i + 1 ; -- ++i
              local a = t[ i ] -- lua_rawgeti(L, 1, i)
     
              while sort_comp( a , P ) do
                 i = i + 1 ; -- ++i
                 a = t[ i ] -- lua_rawgeti(L, 1, i)
              end
     
              -- repeat --j until a[j] <= P
     
              j = j - 1 ; -- --j
              local b = t[ j ]
     
              while sort_comp( P , b ) do
                 j = j - 1 ; -- --j
                 b = t[ j ] -- lua_rawgeti(L, 1, j)
              end
     
              if j < i then
                 break
              end
     
              set2( t , i , j , b , a )
           end -- End for.
     
           t[ u - 1 ] , t[ i ] = t[ i ] , t[ u - 1 ] ;
     
           -- a[l..i-1] <= a[i] == P <= a[i+1..u] */
           -- adjust so that smaller half is in [j..i] and larger one in [l..u] */
     
           if ( i - l ) < ( u - i ) then
              j = l ;
              i = i - 1 ;
              l = i + 2 ;
           else
              j = i + 1 ;
              i = u ;
              u = j - 2 ;
           end
     
           auxsort( t , j , i , sort_comp ) ;  -- call recursively the smaller one */
     
        end
        -- end of while
        -- repeat the routine for the larger one
     
     end
    PDI.debug("sort_dataset_coroutine", "start")
    assert(type(self.dataset) == "table")
    if sort_function then
       assert(type(sort_function) == "function")
    end
 
    auxsort(self.dataset, 1, #self.dataset, sort_function or default_comp)
    PDI.debug("sort_dataset_coroutine", "end")
end

--Generate the proxy tables which will be available to the dataset creation functions--
local function generate_proxies(session)
    local proxies = {}
    proxies.datasource_proxies = {}
    proxies.lookup_proxies = {}
    local datasources = session.datasources
    local lookup_tables = PDI.lookup_manager.get_lookup_tables()
   
    for datasource_name, datasource_table in pairs(datasources) do
        proxies.datasource_proxies[datasource_name] = PDI.utilities.create_proxy_table(datasource_table)
    end
    for lookup_table, lookup_data in pairs(lookup_tables) do
        proxies.lookup_proxies[lookup_table] = PDI.utilities.create_proxy_table(lookup_data)
    end
    return proxies
end

--Generate the shared data tables that will be accessible to the dataset creation functions--
local function generate_session_shared_data(session)
    local proxies = generate_proxies(session)
    local shared_data = {}
    for dataset_name, dataset_settings in pairs(dataset_manager.registered_datasets) do
        shared_data[dataset_name] = {}
        local shared_data_dataset = shared_data[dataset_name]
        shared_data_dataset.name = dataset_name
        shared_data_dataset.dataset = {}
        shared_data_dataset.datasource_proxies = {}
        shared_data_dataset.lookup_proxies = proxies.lookup_proxies
        for _, datasource_name in pairs(dataset_settings.required_datasources) do
            shared_data_dataset.datasource_proxies[datasource_name] = proxies.datasource_proxies[datasource_name]
        end
        for function_name, fn in pairs(function_set) do
            shared_data_dataset[function_name] = fn
        end
    end
    return shared_data
end

--Initialize module--
dataset_manager.init = function (input_table)
    PDI = input_table
    must_yield = PDI.coroutine_manager.must_yield
    is_array = PDI.utilities.is_array
    local dataset_templates = mod:io_dofile([[Power_DI\scripts\mods\Power_DI\templates\dataset_templates]])
    for dataset_name, dataset_template in pairs(dataset_templates) do
        mod.datasets.register_dataset(dataset_template)
    end
end

--Update function, currently not needed--
dataset_manager.update = function()

end

--Function to register a dataset, accessible via the API--
dataset_manager.register_dataset = function(dataset_template)
    local dataset_name = dataset_template.name
    if not dataset_name or type(dataset_name) ~= "string" then
        error("data source name must be a string")
    elseif not dataset_template or type(dataset_template) ~= "table" then
        error("required dataset template not supplied")
    elseif dataset_manager.registered_datasets[dataset_name] then
        error("dataset with the name \""..dataset_name.."\" already exists")
    else
        for _,v in pairs(dataset_template.required_datasources) do
            if not PDI.datasource_manager.registered_datasources[v] then
                error("data source with the name \""..v.."\" not found")
            end
        end

        local dataset_function = dataset_template.dataset_function
        dataset_template.dataset_function = string.dump(dataset_function)
        dataset_template.hash = PDI.utilities.hash(dataset_template)
        dataset_template.dataset_function = dataset_function
        dataset_manager.registered_datasets[dataset_name] = dataset_template
        return true
    end
end

--Function to get a list of the available datasets, accessible via the API--
dataset_manager.get_available_datasets = function()
    local output = {}
    local registered_datasets = dataset_manager.registered_datasets
    for dataset_name, _ in pairs(registered_datasets) do
        output[#output+1] = dataset_name
    end
    table.sort(output)
    return output
end

--Function to prepare the session data table for datasets--
dataset_manager.prepare_session = function (session)
    session.dataset_template_hash_lookup = session.dataset_template_hash_lookup or {}
    session.datasets = session.datasets or {}
    for dataset_name, dataset_template in pairs(dataset_manager.registered_datasets) do
        session.datasets[dataset_name] = session.datasets[dataset_name] or {}
    end
    shared_data = generate_session_shared_data(session)
end

--Returns a dataset template by name--
dataset_manager.get_dataset_template = function(dataset_name)
    return table.clone(dataset_manager.registered_datasets[dataset_name])
end

-- dataset_manager.check_dataset_template_hash = function(dataset_name, hash)
--     local dataset_template = dataset_manager.registered_datasets[dataset_name]
--     local dataset_template_hash = dataset_template.hash
--     return dataset_template_hash == hash
-- end
dataset_manager.check_dataset_template_hash = function(dataset_template)
    local dataset_name = dataset_template.name
    local dataset_template_hash = dataset_template.hash
    local dataset_hash_lookup = PDI.data.session_data.dataset_template_hash_lookup
    local dataset_hash =  dataset_hash_lookup and dataset_hash_lookup[dataset_name]
    return dataset_hash and dataset_template_hash == dataset_hash
end

--Generate a dataset, uses coroutines--
dataset_manager.generate_dataset = function(template, force)
    PDI.debug("generate_dataset","start")
    force_dataset_generation = force
    local dataset_name = template.name
    local hash_check
    if force then
        hash_check = false
    else
        hash_check = dataset_manager.check_dataset_template_hash(template)
    end

    if hash_check then
        local dataset = PDI.data.session_data.datasets[dataset_name]
        return PDI.promise.resolved({dataset, true})
    else
        local promise  = PDI.promise:new()
        local shared_data = shared_data[template.name]
        shared_data.promise = promise
        shared_data.dataset = {}
        template.dataset_function(shared_data)
        return promise
    end
end

--Dataset creation helper functions, these functions are available to the dataset creation functions--

--Function that need to be called by the dataset creation function to resolve the promise--
dataset_manager.dataset_complete = function(self)
    local dataset_name = self.name
    local dataset_template = dataset_manager.registered_datasets[dataset_name]
    local dataset_template_hash = dataset_template.hash

    if force_dataset_generation then
        PDI.data.session_data.dataset_template_hash_lookup[dataset_name] = nil
        force_dataset_generation = nil
    else
        PDI.data.session_data.dataset_template_hash_lookup[dataset_name] = dataset_template_hash
    end

    PDI.data.session_data.datasets[dataset_name] = self.dataset
    self.promise:resolve({self.dataset, false})
    PDI.debug("generate_dataset","end")
end

--Function to append the dataset with a datasource, returns a promise, uses coroutines--
dataset_manager.append_dataset = function(self, datasource_name)
    if next(self.dataset) == nil then
        return PDI.coroutine_manager.new(clone_datasource_coroutine, self, datasource_name)
    else
        return PDI.coroutine_manager.new(append_datasource_coroutine, self, datasource_name)
    end
end

--Function to iterate over the dataset, returns a promise, uses coroutines--
dataset_manager.iterate_dataset = function(self, calculation_function)
    return PDI.coroutine_manager.new(iterate_dataset_coroutine, self, calculation_function)
end

--Function to iterate over a datasource, returns a promise, uses coroutines--
dataset_manager.iterate_datasource = function(self, data_source_name, calculation_function)
    local dataset_template = dataset_manager.get_dataset_template(self.name)
    local required_datasources = dataset_template.required_datasources
    local has_datasource_required = false
    for _, required_datasource_name in ipairs(required_datasources) do
        if required_datasource_name == data_source_name then
            has_datasource_required = true
        end
    end

    if not has_datasource_required then
        error("Use of datasource has not been declared")
        return
    end
    
    local datasource = PDI.data.session_data.datasources[data_source_name]
    return PDI.coroutine_manager.new(iterate_datasource_coroutine, self, datasource, calculation_function)
end

--Function to iterate over a datasource, returns a promise, uses coroutines--
-- dataset_manager.iterate_lookup = function(self, lookup_name, calculation_function)  
--     local lookup = PDI.data.session_data.datasources[lookup_name]
--     return PDI.coroutine_manager.new(iterate_datasource_coroutine, self, lookup, calculation_function)
-- end

--Function to sort the dataset, returns a promise, uses coroutines--
dataset_manager.sort_dataset = function(self, sort_function)
    return PDI.coroutine_manager.new(sort_dataset_coroutine, self, sort_function)
end

--Array with the functions that will be made available to the dataset creation functions--
function_set = {
    append_dataset = dataset_manager.append_dataset,
    iterate_dataset = dataset_manager.iterate_dataset,
    iterate_datasource = dataset_manager.iterate_datasource,
    --iterate_lookup = dataset_manager.iterate_lookup,
    sort_dataset = dataset_manager.sort_dataset,
    complete_dataset = dataset_manager.dataset_complete,
}
return dataset_manager 
