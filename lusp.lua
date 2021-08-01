-- LUSP-
-- lusp.lua

local unpack = table.unpack or unpack
local utf8 = require('utf8')

local RE = require('re')

local Lusp = {}

function Lusp.cleanInput(args)

end

function Lusp.splitArgs(args)
    local arr = {}
    if args then
        -- args = args:gsub('%(%s*%(','((')
        local match = string.match(args, RE.splitspace)

        while match do
            if string.find(match, '%(%(', 1) then
                args = args:gsub(RE.trimbracket, '%1')

            elseif string.find(match, '^[\"]') then
                args = args:gsub(RE.squote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '^[\']') then
                args = args:gsub(RE.dquote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, ';') then
                args = args:gsub(RE.comment, '')
            elseif string.find(match, '%(+%s*def$')
                or string.find(match, '%(+%s*mut$')
                or string.find(match, '%(+%s*if$')
                or string.find(match, '%(+%s*for$')
                or string.find(match, '%(+%s*eval$')
                then

                args = args:gsub(RE.islusp,
                    function(s)
                        local def, body = s:match(RE.defall)
                        arr[#arr+1] = {'__'..def, body}
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
            else
                args = args:gsub(match, '', 1)

                arr[#arr+1] = tonumber(match) or '__'..match
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
        predef[value]
        or (scope['__scope__'] and scope['__scope__'][value])
        or scope[value]
    )
end

function Lusp.replaceVars(value, predef, scope)
    if value == '__#t' or value == '__#f' or value == '__#n' then
        return predef[value]
    end

    if type(value) == 'string' then
        local res = Lusp.checkScope(value, predef, scope)

        if res == '__#t' or res == '__#f' or res == '__#n' then
            return predef[res]
        end
        if res == nil and value:match(RE.var) then
            return nil
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
    Lusp.convertArgs(values, predef, scope)

    local act = Lusp.checkScope(action, predef, scope)

    if act then
        return act(values, predef, scope)
    else
        print('action undefined')
    end
end

function Lusp.eval(inp, predef, scope)
    local tree = Lusp.splitArgs(inp)

    local output = {}
    for i=1, #tree do
        output[#output+1] = Lusp.walkTree(tree[i], predef, scope)
    end

    return unpack(output)
end

return Lusp
