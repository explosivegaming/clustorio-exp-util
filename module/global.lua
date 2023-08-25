--[[-- Util Module - Global
- Provides a method of using global with the guarantee that keys will not conflict
@core Global
@alias Global

@usage--- Drop in boiler plate:
-- Below is a drop in boiler plate which ensures your global access will not conflict with other modules
local global = {}
Global.register(global, function(tbl)
    global = tbl
end)

@usage--- Registering new global tables:
-- The boiler plate above is not recommend because it is not descriptive in its function
-- Best practice is to list out all variables you are storing in global and their function
local MyModule = {
    public_data = {} -- Stores data which other modules can access
}

local private_data = {} -- Stores data which other modules cant access
local more_private_data = {} -- Stores more data which other modules cant access
-- You can not store a whole module in global because not all data types are serialisable
Global.register({ MyModule.public_data, private_data, more_private_data }, function(tbl)
    -- You can also use this callback to set metatable on class instances you have stored in global
    MyModule.public_data = tbl[1]
    private_data = tbl[2]
    more_private_data = tbl[3]
end)

@usage--- Registering new global primitives:
-- It is not recommended to register primitives in global, but sometimes it can not be avoided
local my_primitive__g = Global.register_primitive(1) -- Initialise the primitive to a value of 1

-- Increment my_primitive by 1
local function increment_my_primitive()
    local my_primitive = Global.get_primitive(my_primitive__g)
    Global.set_primitive(my_primitive__g, my_primitive + 1)
end

]]

local ExpUtil = require("modules.exp_util.common") --- @dep exp_util.common

local Global = {
    _next_tbl = 1, -- The next valid id to be used when a table is registered in global
    _next_prim = 1, -- The next valid id to be used when a primitive is registered in global
    _on_load = {}, -- Array of on_load callbacks for tables registered in global
    _debug_info = { -- Stores the file name that each global value was registered in
        tables = {}, -- File names for registered tables
        primitives = {} -- File names for registered primitives
    }
}

global.registered_tables = {} -- Stores all registered tables
global.registered_primitives = {} -- Stores all registered primitives

--- Register a new table to be stored in global, it is ensured that it will not conflict with an existing table, can not be called during runtime
-- @tparam table tbl The initial value for the table you are registering, this should be a local variable
-- @tparam function on_load The callback for on_load used to replace local references and metatables
function Global.register(tbl, on_load)
    ExpUtil.assert_not_runtime()
    ExpUtil.assert_argument_types("table", "function")

    local my_id = Global._next_tbl
    Global._next_tbl = my_id + 1

    Global._on_load[my_id] = on_load
    Global._debug_info.tables[my_id] = ExpUtil.safe_file_path(2)
    global.registered_tables[my_id] = tbl
end

--- Register a new primitive to be stored in global, it is ensured that it will not conflict with an existing primitive, can not be called during runtime
-- @param prim The initial value for the primitive, it should not be a local variable because the reference is not retained
-- @treturn number A unique id which can be used with get_primitive and set_primitive
function Global.register_primitive(prim)
    ExpUtil.assert_not_runtime()

    local my_id = Global._next_prim
    Global._next_prim = my_id + 1

    Global._debug_info.primitives[my_id] = ExpUtil.safe_file_path(2)
    global.registered_primitives[my_id] = prim
    return my_id
end

--- Get the value of the primitive with the given id, must be the value returned by register_primitive for expected behaviour
-- @tparam number id The id of the global primitive as returned by register_primitive, all other values have undefined behaviour
-- @return The value which this id was referencing
function Global.get_primitive(id)
    ExpUtil.assert_argument_type(id, "number", 1, "id")
    assert(id > 0 and id < Global._next_prim, "Global primitive ID is out of range")

    return global.registered_primitives[id]
end

--- Set the value of the primitive with the given id, must be the value returned by register_primitive for expected behaviour
-- @tparam number id The id of the global primitive as returned by register_primitive, all other values have undefined behaviour
-- @param val The value to set the primitive to
-- @return The value which the primitive now holds, always the same as the value passed
function Global.set_primitive(id, val)
    ExpUtil.assert_argument_type(id, "number", 1, "id")
    assert(id > 0 and id < Global._next_prim, "Global primitive ID is out of range")

    global.registered_primitives[id] = val
    return val
end

--- Event Handler, calls on on_load callbacks for registered tables
function Global.on_load()
    for i in 1, Global._next_tbl - 1 do
        Global._on_load[i](global.registered_tables[i])
    end
end

return Global