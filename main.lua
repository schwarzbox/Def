#!/usr/bin/env lua
-- DEF
-- 0.395
-- REPL (lua)
-- main.lua

-- luastatic main.lua settings.lua eval.lua re.lua def.lua tests.lua error.lua /Library/Frameworks/Lua-5.3/bin/../lib/liblua.a -I/Library/Frameworks/Lua-5.3/bin/../include

-- luastatic main.lua settings.lua eval.lua re.lua def.lua tests.lua error.lua /Library/Frameworks/Lua-5.3/bin/../lib/libluajit-5.1.a -I/Library/Frameworks/Lua-5.3/bin/../include/luajit-2.0 -pagezero_size 10000 -image_base 100000000

-- Def 0.391
-- Fibonacci 20 | 6765 | 2.197202  | 2.137343 | 1.146592
-- Fibonacci 21 | 10946 | 3.58716  | 3.641506 | 1.884274
-- Fibonacci 22 | 17711 | 6.26245  | 5.923081 | 3.200597
-- Fibonacci 23 | 28657 | 9.264225 | 9.27107  | 5.099651
-- Fibonacci 24 | 46368 | 15.4336  | 15.715937 | 7.974817
-- Fibonacci 25 | 75025 | 25.8339  | 24.708644 | 13.114007
-- goal (luajit)
-- Fibonacci 26 | 121393 | 23.493196

local settings = require('settings')

local Def = require('def')
local Eval = require('eval')
local Tests = require('tests')

local function evaluate(expr, scope, safecall)
    local result, error = Eval.eval(expr, Def, scope, safecall)
    if result then
        return result
    elseif error then
        io.write(error,'\n')
    else
        -- io.write('\nTDTTOE\n')
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
            local result = evaluate(arg[1], {})
            if result then
                Def._show_({result})
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
            local result = evaluate(io.input():read(), scope, true)
            if result then
                Def._show_({result})
            end
        end
    end
end

main()
