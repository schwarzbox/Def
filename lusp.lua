-- LUSP-
-- lusp.lua

local unpack = table.unpack or unpack

local Error = require('error')
local RE = require('re')

local Lusp = {}

function Lusp.cleanInput(args)
    local nocomments = args:gsub(';%s*.-%f[\n]','')
    return nocomments:gsub('%s+',' '):gsub('%s+%)',')'):gsub('%(%s+','('):gsub('%(%s+%(','(('):gsub('%)%s+%)','))')
end
function Lusp.splitArgs(args, islusp)
    local arr = {}
    if args then
        Error.checkBraces(args)
        Error.checkQuotes(args)

        args = Lusp.cleanInput(args)

        local match = string.match(args, RE.splitspace)

        while match do
            if string.find(match, '%(%(', 1) then
                args = args:gsub(RE.trimbracket, '%1')
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

                        arr[#arr+1] = {RE.tokenize(def), body}
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '^[\"]') then
                if #arr == 0 and islusp then
                    Error.wrongCharAction('"', match)
                end
                args = args:gsub(RE.dquote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '^[\']') then
                if #arr == 0 and islusp then
                    Error.wrongCharAction("'", match)
                end
                args = args:gsub(RE.squote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, ';') then
                args = args:gsub(RE.comment, '')
            elseif string.find(match, '%[') then
                args = args:gsub(RE.islist,
                    function(s)
                        for tab in string.gmatch(s, RE.islist) do
                            arr[#arr+1] = Lusp.splitArgs(
                                tab:gsub(RE.trimlist, '%1'),
                                false
                            )
                            setmetatable(arr[#arr], {__index={islist=true}})
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
                                tab:gsub(RE.trimlusp, '%1'),
                                true
                            )
                            setmetatable(arr[#arr], {__index={islusp=true}})
                        end
                        return ''
                    end,
                    1
                )
            elseif tonumber(match) then
                args = args:gsub(match, '', 1)

                arr[#arr+1] = tonumber(match)
            else

                local old = args
                args = args:gsub(match, '', 1)
                if old==args then
                    Error.wrongCharInput(match)
                end

                arr[#arr+1] = RE.tokenize(match)

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
        if type(tree[i]) == 'table' and not tree[i].islist then
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

function Lusp.isBool(value)
    if value == RE.tokentrue or value == RE.tokenfalse then
        return true
    end
    return false
end

function Lusp.getDefinition(value, predef, scope)
    return (
        scope[value]
        or (scope['_scope_'] and scope['_scope_'][value])
        or predef[value]
    )
end

function Lusp.replaceVars(value, predef, scope)
    if Lusp.isBool(value) then return predef[value] end

    if type(value) == 'string' then
        if (scope[value] == false
            or (scope['_scope_'] and scope['_scope_'][value] == false)) then
            return false
        end

        local result = Lusp.getDefinition(value, predef, scope)

        if Lusp.isBool(result) then return predef[result] end

        if result == nil and value:match(RE.tokenvar) then
            Error.undefined('variable', value:gsub(RE.token, ''))
        end

        return result or value
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
    local act = Lusp.getDefinition(action, predef, scope)

    if not RE.specials[action] then
        Lusp.convertArgs(values, predef, scope)
    end

    if act then
        return act(values, predef, scope)
    else
        Error.undefined('action', action:gsub(RE.token, ''))
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

function Lusp.eval(inp, predef, scope, nocrash)
    local exe, result = pcall(Lusp.run, inp, predef, scope)

    if exe then
        if result then
            return unpack(result)
        end
        return result
    elseif result:find('_break_') or result:find('_continue_') then
        return '_break_'
    else
        if nocrash then
            return exe, Error.getError(result, scope)
        end
        Error.error(result, scope)
    end
end

return Lusp
