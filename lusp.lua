-- LUSP-
-- lusp.lua

local unpack = table.unpack or unpack
local utf8 = require('utf8')

local Tests = require('tests')
local RE = require('re')


local Lusp = {}

function Lusp.error(message, scope)
    local err = Lusp.geterror(message, scope)

    if Tests.isdebug then
        Tests.savederror = err
    else
        io.write(err..'\n')
        os.exit(0)
    end
end

function Lusp.geterror(message, scope)
    return ('Error: '..message:gsub('[%g]+: ','')..' | '.. (scope['name'] or 'root'))
end

function Lusp.checkBraces(args)
    local _, lbr = args:gsub('%(', '')
    local _, rbr = args:gsub('%)', '')

    local _, lqbr = args:gsub('%[', '')
    local _, rqbr = args:gsub('%]', '')


    if lbr ~= rbr then
        error('unpaired braces ()')
    end

    if lqbr ~= rqbr then
        error('unpaired braces []')
    end
end

function Lusp.checkQuotes(args)
    local _, dquotes = args:gsub('"', '')
    local _, squotes = args:gsub("'", '')

    if dquotes > 0 and dquotes % 2 ~= 0 then
        error('unpaired quotes "')
    end
    if squotes > 0 and squotes % 2 ~= 0 then
        error("unpaired quotes '")
    end
end

function Lusp.splitArgs(args)
    local arr = {}
    if args then
        Lusp.checkBraces(args)
        Lusp.checkQuotes(args)

        args = args:gsub('%(%s+','('):gsub('%(%s+%(','(('):gsub('%)%s+%)','))')

        local match = string.match(args, RE.splitspace)

        while match do

            if string.find(match, '%(%(', 1) then
                args = args:gsub(RE.trimbracket, '%1')

            elseif string.find(match, '^[\"]') then
                args = args:gsub(RE.dquote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '^[\']') then
                args = args:gsub(RE.squote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, ';') then
                args = args:gsub(RE.comment, '')
            elseif string.find(match, RE.token) then
                error('wrong literal '.. RE.token)
            elseif string.find(match, '%(+%s*def$')
                or string.find(match, '%(+%s*mut$')
                or string.find(match, '%(+%s*if$')
                or string.find(match, '%(+%s*for$')
                or string.find(match, '%(+%s*eval$')
                or string.find(match, '%(+%s*call$')
                then

                args = args:gsub(RE.islusp,
                    function(s)
                        local def, body = s:match(RE.defall)

                        arr[#arr+1] = {RE.token..def, body}
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '%[') then
                args = args:gsub(RE.islist,
                    function(s)
                        for tab in string.gmatch(s, RE.islist) do
                            arr[#arr+1] = Lusp.splitArgs(
                                tab:gsub(RE.trimlist, '%1')
                            )
                            setmetatable(arr[#arr], {__index={list=true}})
                        end
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '%(') then
                args = args:gsub(RE.islusp,
                    function(s)
                        for tab in string.gmatch(s, RE.islusp) do
                            arr[#arr+1] = Lusp.splitArgs(
                                tab:gsub(RE.trimlusp, '%1')
                            )
                        end
                        return ''
                    end,
                    1
                )
            elseif tonumber(match) then
                args = args:gsub(match, '', 1)

                arr[#arr+1] = tonumber(match)
            else

                args = args:gsub(match, '', 1)

                arr[#arr+1] = RE.token..match
                -- print('m',match)
            end
            match = string.match(args, RE.splitspace)
        end
    end
    return arr
end

function Lusp.walkTree(tree, predef, scope)
    local args = {}
    local action = tree[1]

    for i=2, #tree do
        if type(tree[i]) == 'table' and not tree[i].list then
            local results = {Lusp.walkTree(tree[i], predef, scope)}
            for j=1, #results do
                args[#args+1] = results[j]
            end
        else
            args[#args+1] = tree[i]
        end
    end

    return Lusp.execute(action, args, predef, scope)
end

function Lusp.checkScope(value, predef, scope)
    return (
        scope[value]
        or predef[value]
        or (scope['scope'] and scope['scope'][value])
    )
end

function Lusp.replaceVars(value, predef, scope)
    if value == RE.token..'#t' or value == RE.token..'#f' then
        return predef[value]
    end

    if type(value) == 'string' then
        if (scope[value] == false
            or (scope['scope'] and scope['scope'][value] == false)) then
            return false
        end

        local res = Lusp.checkScope(value, predef, scope)

        if res == RE.token..'#t' or res == RE.token..'#f' then
            return predef[res]
        end

        if res == nil and value:match(RE.var) then
            error('variable undefined')
        end

        return res or value
    end

    return value
end

function Lusp.convertArgs(values, predef, scope)
    for k,v in pairs(values) do
        if type(v)=='table' then
            Lusp.convertArgs(v, predef, scope)
        else
            values[k] = Lusp.replaceVars(v, predef, scope)
        end
    end
end

function Lusp.execute(action, values, predef, scope)
    local act = Lusp.checkScope(action, predef, scope)

    if (
        action~=RE.token..'def'
        and action~=RE.token..'mut'
        and action~=RE.token..'if'
        and action~=RE.token..'for'
        and action~=RE.token..'eval'
        and action~=RE.token..'call'
        ) then

        Lusp.convertArgs(values, predef, scope)
    end

    if act then
        return act(values, predef, scope)
    else
        error('action undefined')
    end
end

function Lusp.run(inp, predef, scope)
    local tree = Lusp.splitArgs(inp)

    local output = {}
    for i=1, #tree do
        local res = {Lusp.walkTree(tree[i], predef, scope)}

        for _=1, #res do
            output[#output+1] = res
        end
    end
    return unpack(output)
end

function Lusp.eval(inp, predef, scope, noerror)
    local exe, result = pcall(Lusp.run, inp, predef, scope)

    if exe then
        if result then
            return unpack(result)
        end
        return result
    elseif result:find('break') or result:find('continue') then
        return 'break'
    else
        if noerror then
            return exe, Lusp.geterror(result, scope)
        end
        Lusp.error(result, scope)
    end
end

return Lusp
