#!/usr/bin/env lua
-- LUSP
-- 0.1
-- REPL (lua)
-- main.lua

local settings = require('settings')

if arg[0] then io.write(settings.VERSION, ' LUSP REPL (lua)', arg[0],'\n') end
if arg[1] then io.write(settings.VERSION, ' LUSP REPL (lua)', arg[1],'\n') end

-- lua<5.3
local unpack = table.unpack or unpack
local utf8 = require('utf8')


local Tests = require('tests')
local Lusp = require('Lusp')
local Def = require('Def')

-- local input = '( ( ( show (get 5 "hello" )) ) )'
-- local input = '   (   def    (    func x    ) ((   def   y   1    ) (   show     (   +     x     y   )))) (   func    1   )    '

local input = '(def x 1) (def y 2) (for (var [1 2]) ((mut x (+ x var)) (show (scope)))) (show (scope))'

-- local input  = '(error "Show Error")'

-- local input  = '(def (func) (-> (+ 1 x)) (-> (+ 1 x)))  (show (func 2))'

local input  = '(show)'

local function main()

    Tests.run(Lusp, Def)

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
