--luacheck:ignore global require
--luacheck:ignore global package

local package = require 'modules.exp_util.include.package'
local loaded = package.loaded
local _require = require

function require(path)
    if package.lifecycle == package.lifecycle_stage.runtime then
        return loaded[path] or error('Can only require files at runtime that have been required in the control stage.', 2)
    else
        return _require(path)
    end
end

return _require