#!/usr/bin/env lua
-- LUSP
-- 0.1
-- REPL (lua)
-- main.lua

local settings = require('settings')

if arg[0] then io.write(settings.VERSION, ' LUSP REPL (lua)', arg[0],'\n') end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')


local Lusp = require('Lusp')
local Tests = require('tests')
local Def = require('Def')

--
local input ='(show (call add "Lusp" 42)) (show "alex")'
-- local input = '(def vvvv -2) (show (* vvvv vvvv))'
-- error
-- local input = '(show (call * 2 "2"))'

local function main()
    -- Tests.run(Lusp, Def)

    io.write(settings.VERSION, '\n')
    io.write(settings.HELP,'\n')

    -- while true do
        -- io.output():write(settings.PROMPT)
        -- input = io.input():read()

        Lusp.eval(input, Def, {})
        -- io.write(walkTree(root), '\n')
    -- end
end

main()
