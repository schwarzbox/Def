#!/usr/bin/env lua
-- DEF
-- 1.0
-- REPL (lua)
-- main.lua

-- luastatic main.lua settings.lua eval.lua re.lua def.lua error.lua /Library/Frameworks/Lua-5.3/bin/../lib/liblua.a -I/Library/Frameworks/Lua-5.3/bin/../include

-- luastatic main.lua settings.lua eval.lua re.lua def.lua error.lua tests.lua /Library/Frameworks/Lua-5.3/bin/../lib/libluajit-5.1.a -I/Library/Frameworks/Lua-5.3/bin/../include/luajit-2.0 -pagezero_size 10000 -image_base 100000000


-- 1.1
-- line error

local settings = require('settings')

local Def = require('def')
local Eval = require('eval')
local RE = require('re')
local Tests = require('tests')

local function evaluate(expr, scope, safecall)
    local result, error = Eval.eval(expr, Def, scope, safecall)

    if result then
        return result
    elseif error then
        io.write(error,'\n')
    else
        io.write('\nTDTTOE\n')
    end
end

local function main()
    if arg[1] and arg[1]:match('^%-[%w]+') then
        if arg[1] == '-help' or arg[1] == '-h' then
            io.write(settings.VERSION, ' REPL', '\n')
            io.write(settings.HELP,'\n')
        elseif arg[1] == '-version' or arg[1] == '-v' then
            io.write(settings.VERSION,'\n')
        elseif arg[1] == '-test' or arg[1] == '-t' then
            io.write(settings.VERSION, ' REPL', '\n')
            Tests.run(Eval, Def)
        else
            io.write(settings.VERSION, ' REPL', '\n')
            io.write(settings.HELP, '\n')
        end
    elseif arg[1] then
        local file = io.open(arg[1], 'r')
        if not file then
            local inp = arg[1]:gsub('(%()%s*show ', '%1')
            local result = evaluate(inp, {})
            if result then
                Def[RE.tokenshow]({result})
            end
        else
            io.write(settings.VERSION, '\n')
            local expr = file:read('*a')
            file:close()
            evaluate(expr, {})
        end
    else
        io.write(settings.VERSION, ' REPL', '\n')
        io.write(settings.EXIT,'\n')
        local scope = {}
        while true do
            io.output():write(settings.PROMPT)
            local inp = io.input():read():gsub('(%()%s*show ', '%1')
            local result = evaluate(inp, scope, true)
            if result then
                Def[RE.tokenshow]({result})
            end
        end
    end
end

main()
