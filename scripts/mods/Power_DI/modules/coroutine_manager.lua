local mod = get_mod("Power_DI")
local PDI
local coroutine_manager = {}

local queue = {}
local max_cycles = mod:get("max_cycles")
local yield_counter = 0

--Function to handle the coroutine queue--
local function iterate_queue()
    local item = queue[1]
    if item then
        local status, output = coroutine.resume(item.co)
        if status == true then
            if output ~= coroutine then
                table.remove(queue, 1)
                item.promise:resolve(output)
            end
        elseif status == false then
            table.remove(queue, 1)
            local error_table = {
                error = output,
                stacktrace = debug.traceback(item.co)
            }
            PDI.debug("Coroutine", error_table)
            item.promise:reject(error_table)
        end
    end
end

--Initializing module--
coroutine_manager.init = function (input_table)
    PDI = input_table
    coroutine_manager.max_cycles = mod:get("max_cycles")
end

--Update function--
coroutine_manager.update = function()
    iterate_queue()
end

--Function to create a new coroutine, returns a promise--
coroutine_manager.new = function(fn, ...)
    local coroutine_function = callback(fn,...)
    local co = coroutine.create(coroutine_function)
    local promise = PDI.promise:new()
    local temp_table = {}
    temp_table.co = co
    temp_table.promise = promise
    table.insert(queue, temp_table)
    return promise
end

--Function to check if the coroutine must yield--
coroutine_manager.must_yield = function()
    yield_counter = yield_counter + 1
    if yield_counter >= max_cycles then
        yield_counter = 0
        return true
    end
    return false
end

--Function to set the max cycles--
coroutine_manager.set_max_cycles = function (value)
    max_cycles = value
end
return coroutine_manager