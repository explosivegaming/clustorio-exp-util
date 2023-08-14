--[[-- Util Module - Common
- Adds some commonly used functions used in many modules
@core Common
@alias Common
]]

local Common = {
    --- A large mapping of colour rgb values by their common name
    color = require 'modules.exp_util.include.color'
}

--- Raise an error if we are not in runtime
function Common.assert_not_runtime()

end

--- Raise an error if a function is a closure and we are in runtime
-- @tparam function func The function to assert is not a closure if we are in runtime
function Common.assert_not_closure(func)

end

--- Raise an error if the type of a value is not as expected
-- @param value The value to assert the type of
-- @tparam string type_name The name of the type that value is expected to be
-- @tparam[opt] string value_name The name of the value being tested, this is included in the error message
function Common.assert_type(value, type_name, value_name)

end

--- Raise an error if the type of any argument is not as expected, can be costly, for frequent callers see assert_argument_type
-- @tparam string ... The type for each argument of the calling function
function Common.assert_argument_types(...)

end

--- Raise an error if the type of any argument is not as expected, more performant than assert_argument_types, but requires more manual input
-- @tparam string ... The type for each argument of the calling function
function Common.assert_argument_type(arg_value, type_name, arg_name, arg_index)

end

--- Write a luu table to a file as a json string, note the defaults are different to game.write_file
-- @tparam string path The path to write the json to
-- @tparam table value The table to write to file
-- @tparam[opt=false] boolean overwrite When true the json replaces the full contents of the file
-- @tparam[opt=0] number player_index The player's machine to write on, nil means all, 0 means host only
function Common.write_json(path, tbl, overwrite, player_index)

end

--- Clear a file by replacing its contents with an empty string
-- @tparam string path The path to clear the contents of
-- @tparam[opt] number player_index The player's machine to write on, nil means all, 0 means host only
function Common.clear_file(path, player_index)

end

--- Same as require but will return nil if the module does not exist, all other errors will propagate to the caller
-- @tparam string module_path The path to the module to require, same syntax as normal require
-- @return The contents of the module, or nil if the module does not exist or did not return a value
function Common.optional_require(module_path)

end

--- Attempt a simple autocomplete search from a set of options
-- @tparam table options The table representing the possible options which can be selected
-- @tparam string input The user input string which should be matched to an option
-- @tparam boolean use_key When true the keys will be searched, when false the values will be searched
-- @tparam boolean rtn_key When true the selected key will be returned, when false the selected value will be returned
-- @return The selected key or value which first matches the input text
function Common.auto_complete(options, input, use_key, rtn_key)

end

--- Format a tick value into one of a selection of pre-defined formats (short, long, clock)
-- @tparam number ticks The number of ticks which will be represented, can be any duration or time value
-- @tparam string format The format to display, must be one of: short, long, clock
-- @tparam[opt] table units A table selecting which units should be displayed, options are: days, hours, minutes, seconds
-- @treturn string The ticks formatted into a string of the desired format
function Common.format_time(ticks, format, units)

end

--- Format a tick value into one of a selection of pre-defined formats (short, long, clock)
-- @tparam number ticks The number of ticks which will be represented, can be any duration or time value
-- @tparam string format The format to display, must be one of: short, long, clock
-- @tparam[opt] table units A table selecting which units should be displayed, options are: days, hours, minutes, seconds
-- @treturn LocaleString The ticks formatted into a LocaleString of the desired format
function Common.format_locale_time(ticks, format, units)

end

--- Insert a copy of the given items into the found / created entities. If no entities are found then they will be created if possible.
-- @tparam table items The items which are to be inserted into the entities, an array of LuaItemStack
-- @tparam LuaSurface surface The surface which will be searched to find the entities
-- @tparam table options A table of various optional options similar to find_entities_filtered
-- position + radius or area can be used to define a search area on the surface
-- type can be used to find all entities of a given type, such as a chest
-- name can be used to further specify which entity to insert into, this field is required if entity creation is desired
-- allow_creation is a boolean which when true will allow the function to create new entities in order to insert all items
-- @treturn LuaEntity the last entity that had items inserted into it
function Common.copy_item_stacks(items, surface, options)

end

--- Move the given items into the found / created entities. If no entities are found then they will be created if possible.
-- @tparam table items The items which are to be inserted into the entities, an array of LuaItemStack
-- @tparam LuaSurface surface The surface which will be searched to find the entities
-- @tparam table options A table of various optional options similar to find_entities_filtered
-- position + radius or area can be used to define a search area on the surface
-- type can be used to find all entities of a given type, such as a chest
-- name can be used to further specify which entity to insert into, this field is required if entity creation is desired
-- allow_creation is a boolean which when true will allow the function to create new entities in order to insert all items
-- @treturn LuaEntity the last entity that had items inserted into it
function Common.move_item_stacks(items, surface, options)

end

return Common