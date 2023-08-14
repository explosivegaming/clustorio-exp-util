--luacheck:ignore global print

local locale_string = {'', '[PRINT] ', nil}
local _print = print

function print(str)
    _print(str)
    locale_string[3] = str
    log(locale_string)
end

return _print