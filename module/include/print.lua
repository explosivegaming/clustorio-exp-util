--luacheck:ignore global print

local locale_string_print = {'', '[INFO] ', nil}
local locale_string_warn = {'', '[WARN] ', nil}
local _print = print

function print(str)
    locale_string_print[3] = str
    log(locale_string_print)
end

function warn(str)
    locale_string_warn[3] = str
    log(locale_string_warn)
end

return _print
