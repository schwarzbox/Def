#!/usr/bin/env lua
-- LUSP
-- 0.1
-- REPL (lua)
-- main.lua

-- luastatic main.lua settings.lua lusp.lua re.lua def.lua tests.lua error.lua /Library/Frameworks/Lua-5.3/bin/../lib/liblua.a -I/Library/Frameworks/Lua-5.3/bin/../include

local settings = require('settings')

local Lusp = require('Lusp')
local Def = require('Def')
local Tests = require('tests')

local function evaluate(expr, nocrash)
    local scope = {}
    local result, error = Lusp.eval(expr, Def, scope, nocrash)
    if result then
        if type(result) ~= 'table' then
            io.write(result,'\n')
        end
    elseif error then
        io.write(error,'\n')
    else
        -- io.write('Bug?Bug!', '\n')
        -- io.write('FUBAR', '\n')
        io.write('TDTTOE', '\n')
    end
end

local function main()
    -- Lusp.eval(input, Def, {})
    if arg[1]:match('^%-[%w]+') then
        io.write(settings.VERSION, ' REPL (lua) ', '\n')
        if arg[1] == '-help' or arg[1] == '-h' then
            io.write(settings.VERSION, ' REPL (lua) ', '\n')
            io.write(settings.HELP,'\n')
        elseif arg[1] == '-version' or arg[1] == '-v' then
            io.write(settings.VERSION,'\n')
        elseif arg[1] == '-test' or arg[1] == '-t' then
            io.write(settings.VERSION, ' REPL (lua) ', '\n')
            Tests.run(Lusp, Def)
        else
            io.write(settings.HELP, '\n')
        end
    elseif arg[1] then
        local file = io.open(arg[1], 'r')
        if not file then
            evaluate(arg[1])
        else
            local expr = file:read('*a')
            file:close()
            evaluate(expr)
        end
    else
        io.write(settings.VERSION, ' REPL (lua) ', '\n')
        io.write(settings.EXIT,'\n')
        while true do
            io.output():write(settings.PROMPT)
            evaluate(io.input():read(), true)
        end
    end
end

if #arg == 0 then
    io.write(settings.VERSION, ' REPL (lua) ', '\n')
else
    main()
end

