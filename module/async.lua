--[[-- Util Module - Async
- Provides a method of spreading work across multiple ticks and running functions at a later time
@core Async
@alias Async

@usage-- Bypass permission groups
-- This is a simple example, you should have some kind of validation to prevent security flaws
local function setAdmin(player, state)
    player.admin = state
end

local setAdminAsync = Async.register(setAdmin)
setAdminAsync(game.players[1], true)

@usage-- Functions stored in global table
-- This can be used to create run time configurable callbacks, although this is not recommended
global.myCallback = Async.register(function()
    game.print("I got called!")
end)

-- The function can be called just like any other function
global.myCallback()

@usage-- Creating singleton threads / tasks
-- This allows you to split large tasks across multiple ticks to prevent lag
local myTask = Async.register(function(remainingWork)
    game.print("Working... " .. remainingWork)
    if remainingWork > 0 then
        return Async.status.continue(remainingWork - 1)
    end
end)

myTask:start_task(10) -- Queues the task
myTask:start_task(10) -- Does nothing, task is already running
myTask:start_now(10) -- Ignores the already running instance and starts a second one

@usage-- Actions with variable delays
-- on_nth_tick is great for consistent delays, but tasks allow for variable delays
local linearBackoff = Async.register(function(startingDelay, remainingWork)
    game.print("Working... " .. remainingWork)
    if remainingWork > 0 then
        local newDelay = startingDelay + 1
        return Async.status.delay(newDelay, newDelay, remainingWork - 1)
    end
end)

linearBackoff(1, 10)

@usage-- Getting return values
-- you can capture the return values of an async function using the event
local fillTableAsync = Async.register(function(tbl, val, remainingWork)
    table.insert(tbl, val)
    if remainingWork > 0 then
        return Async.status.continue(tbl, val, remainingWork - 1)
    else
        return Async.status.complete(tbl)
    end
end)

local function on_function_complete(event)
    if event.async_id ~= fillTableAsync.id then return end
    local filledTable = unpack(event.return_values)
    game.print("Table has length of " .. #filledTable)
end

fillTableAsync({}, "foo", 10) -- Puts 10 lots of foo into the table

]]

local ExpUtil = require("modules.exp_util.common") --- @dep exp_util.common

local Async = {
    status = {}, -- Stores the allowed return types from a async function
    events = {}, -- Stores all event handlers for this module
    _prototype = {}, -- Prototype of the async function type
    _queue_pressure = {}, -- Stores the count of each function in the queue to avoid queue iteration during start_task
    _functions = {}, -- Stores a reference to all registered functions
    --- Raised when any async function has finished execution
    -- @event on_function_complete
    -- @tparam AsyncFunction async_id The function which finished execution, comparable to the return of register
    -- @tparam table return_values An array representing the values returned by the completed function
    on_function_complete = script.generate_event_name()
}

Async._metatable = {
    __call = function(self, ...) Async._prototype.start_soon(self, ...) end,
    __index = Async._prototype,
    __class = "AsyncFunction"
}

script.register_metatable("AsyncFunction", Async._metatable)

local function ensure_global()
    if global.async_next then return end
    global.async_next = {} -- Stores a queue of async functions to be executed on the next tick
    global.async_queue = {} -- Stores a queue of async functions to be executed on a later tick
end

--- Static Methods.
-- Static methods of the class
-- @section async-static

--- Register a new async function
-- @tparam function func The function which becomes the async function
-- @treturn AsyncFunction The newly registered async function
function Async.register(func)
    ExpUtil.assert_not_runtime()

    local debug_info = debug.getinfo(2, "Sn")
    local file_name = debug_info.source:match('^.+/currently%-playing/(.+)$'):sub(1, -5)
    local func_name = debug_info.name or "<anonymous:"..debug_info.linedefined..">"
    local my_id = file_name..":"..func_name

    Async._functions[my_id] = func
    Async._queue_pressure[my_id] = 0
    return setmetatable({ id = my_id }, Async._metatable)
end

--- Prototype Methods.
-- Prototype methods of the class instances
-- @section async-prototype

--- Run an async function on the next tick, this is the default and can be used to bypass permission groups
-- @param ... The arguments to call the function with
function Async._prototype:start_soon(...)
    assert(Async._functions[self.id], "Async function is not registered")
    Async._queue_pressure[self.id] = Async._queue_pressure[self.id] + 1

    ensure_global()
    local index = #global.async_next + 1
    global.async_next[index] = {
        id = self.id,
        args = {...}
    }
end

--- Run an async function after the given number of ticks
-- @tparam number ticks The number of ticks to call the function after
-- @param ... The arguments to call the function with
function Async._prototype:start_after(ticks, ...)
    assert(Async._functions[self.id], "Async function is not registered")
    Async._queue_pressure[self.id] = Async._queue_pressure[self.id] + 1

    ensure_global()
    local index = #global.async_queue + 1
    global.async_queue[index] = {
        id = self.id,
        args = {...},
        tick = game.tick + ticks
    }
end

--- Run an async function on the next tick if the function is not already queued, allows singleton task/thread behaviour
-- @param ... The arguments to call the function with
function Async._prototype:start_task(...)
    assert(Async._functions[self.id], "Async function is not registered")
    if Async._queue_pressure[self.id] > 0 then return end
    self:start_soon(...)
end

--- Run an async function on this tick, then queue it based on its return value
-- @param ... The arguments to call the function with
function Async._prototype:start_now(...)
    assert(Async._functions[self.id], "Async function is not registered")
    local rtn = { Async._functions[self.id](...) }
    if rtn[1] == Async.status.continue then
        Async._prototype.start_soon(self, unpack(rtn[2])) -- proto used to allow reuse in Async.run
    elseif rtn[1] == Async.status.delay then
        Async._prototype.start_after(self, rtn[2], unpack(rtn[3])) -- proto used to allow reuse in Async.run
    else
        -- The function has finished execution, raise the custom event
        script.raise_event(Async.on_function_complete, {
            event = Async.on_function_complete,
            tick = game.tick,
            async_id = self.id,
            returned = rtn
        })
    end
end

--- Status Returns.
-- Return values used by async functions
-- @section async-status

--- Default status, will raise on_function_complete
-- @param ... The return value of the async call
function Async.status.complete(...)
    return ...
end

--- Will queue the function to be called again on the next tick using the new arguments
-- @param ... The arguments to call the function with
function Async.status.continue(...)
    return Async.status.continue, {...}
end

--- Will queue the function to be called again on a later tick using the new arguments
-- @param ... The arguments to call the function with
function Async.status.delay(ticks, ...)
    return Async.status.delay, ticks, {...}
end

--- Executes an async function and processes the return value
local function exec(pending)
    local rtn = { Async._functions[pending.id](unpack(pending.args)) }
    if rtn[1] == Async.status.continue then
        local index = #global.async_next + 1
        global.async_next[index] = pending
        pending.tick = nil
        pending.args = rtn[2]
    elseif rtn[1] == Async.status.delay then
        local index = #global.async_queue + 1
        global.async_queue[index] = pending
        pending.tick = game.tick + rtn[2]
        pending.args = rtn[3]
    else
        -- The function has finished execution, raise the custom event
        Async._queue_pressure[pending.id] = Async._queue_pressure[pending.id] - 1
        script.raise_event(Async.on_function_complete, {
            event = Async.on_function_complete,
            tick = game.tick,
            async_id = pending.id,
            returned = rtn
        })
    end
end

--- Each tick, run all next tick functions, then check if any in the queue need to be executed
local function on_tick()
    ensure_global()
    local tick = game.tick
    for index, pending in ipairs(global.async_next) do
        global.async_next[index] = nil
        exec(pending)
    end
    for index, pending in ipairs(global.async_queue) do
        -- TODO implement a priority queue based on tick to allow for early return
        if pending.tick <= tick then
            global.async_queue[index] = nil
            exec(pending)
        end
    end
end

--- On load, check the queue status and update the pressure values
local function on_load()
    if not global.async_next then return end
    for _, pending in ipairs(global.async_next) do
        local count = Async._queue_pressure[pending[1].id]
        Async._queue_pressure[pending[1].id] = count + 1
    end
    for _, pending in ipairs(global.async_queue) do
        local count = Async._queue_pressure[pending[1].id]
        Async._queue_pressure[pending[1].id] = count + 1
    end
end

Async.on_load = on_load
Async.events[defines.events.on_tick] = on_tick
return Async