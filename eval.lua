-- DEF
-- eval.lua

local unpack = table.unpack or unpack

local Error = require('error')
local RE = require('re')


local Eval = {swapstr = {}, swapkey = RE.swapkey}


function Eval.splitArgs(args, islazy)
    local arr = {}

    if args then
        local match = string.match(args, RE.splitspace)

        while match do
            local key = string.match(match, '['..RE.lazy..'%(%[]')

            if string.find(match, RE.dbraces) then
                local result = ''
                for arg in args:gmatch(RE.isdef) do
                    result = result .. ' ' .. arg:gsub(RE.trimbracket, '%1')
                end
                args = result
            elseif key == RE.lazy and string.find(match, RE.lazy..'%[') then
                args = args:gsub(RE.islazy,
                    function(s)
                        arr[#arr+1] = Eval.splitArgs(
                            s:gsub(RE.trimlazy, '%1'), true
                        )
                        setmetatable(arr[#arr], {__index={islazy=true}})
                        return ''
                    end,
                    1
                )
            elseif key == RE.lazy and string.find(match, RE.lazy..'%(') then
                args = args:gsub(RE.islazydef,
                    function(s)
                        if #s==0 then
                            Error.wrongLazy(match)
                        end

                        local result, _ = Eval.getStr(s, RE.swapdef)
                        arr[#arr+1] = result
                        return ''
                    end,
                    1
                )
            elseif key == RE.lazy then
                args = args:gsub(RE.lazy..'(%g*)', '', 1)
                local result, _ = Eval.getStr(
                    match:gsub(RE.lazy, ''), RE.swapdef
                )
                if #result==0 then
                    Error.wrongLazy(match)
                end

                arr[#arr+1] = result
            elseif key == '[' then
                args = args:gsub(RE.islist,
                    function(s)
                        arr[#arr+1] = Eval.splitArgs(
                            s:gsub(RE.trimlist, '%1'), islazy
                        )
                        setmetatable(arr[#arr], {__index={islist=true}})
                        return ''
                    end,
                    1
                )
            elseif not islazy
                and (string.find(match, '%(+%s*def$')
                or string.find(match, '%(+%s*mut$')
                or string.find(match, '%(+%s*lambda$')
                or string.find(match, '%(+%s*L$')
                or string.find(match, '%(+%s*if$')
                or string.find(match, '%(+%s*switch$')
                or string.find(match, '%(+%s*while$')
                or string.find(match, '%(+%s*for$')
                or string.find(match, '%(+%s*eval$')
                or string.find(match, '%(+%s*try$'))
                then

                args = args:gsub(RE.isdef,
                    function(s)
                        local res, _ = Eval.getStr(s, RE.swapdef)

                        local def, body = res:match(RE.defall)
                        arr[#arr+1] = {RE.tokenize(def), body}
                        return ''
                    end,
                    1
                )
            elseif key == '(' then
                args = args:gsub(RE.isdef,
                    function(s)
                        arr[#arr+1] = Eval.splitArgs(
                            s:gsub(RE.trimdef, '%1'), islazy
                        )

                        -- NOTE: check empty def
                        if not islazy then
                            Error.checkExpression(s, nil, s)
                        end

                        setmetatable(arr[#arr], {__index={isdef=true}})
                        return ''
                    end,
                    1
                )
            elseif not islazy and tonumber(match) then
                args = args:gsub(match, '', 1)
                arr[#arr+1] = tonumber(match)
            else
                local old = args
                if match == '..' then
                    args = args:gsub('%.%.', '', 1)
                else
                    args = args:gsub(match, '', 1)
                end

                if old==args then
                    Error.wrongCharInput(match)
                end

                if islazy then
                    arr[#arr+1] = match
                else
                    arr[#arr+1] = RE.tokenize(match)
                end
            end
            match = string.match(args, RE.splitspace)
        end
    end

    return arr
end

function Eval.isBool(value)
    if value == RE.tokentrue or value == RE.tokenfalse then
        return true
    end
    return false
end

function Eval.getStr(value, regexp)
    local res, num1, num2
    res, num1 = value:gsub(regexp,
        function(s)
            local var = Eval.swapstr[s]
            return var
        end
    )

    res, num2 = res:gsub(regexp,
        function(s)
            local var = Eval.swapstr[s]
            return var
        end
    )
    return res, num1 + num2
end

function Eval.getDef(value, predef, scope)
    return (
        scope[value]
        or (scope[RE.tokenscope] and scope[RE.tokenscope][value])
        or predef[value]
    )
end

function Eval.replaceArgs(value, predef, scope)
    if type(value) == 'string' then
        if Eval.isBool(value) then return predef[value] end
        if scope[value] == false then return false end

        local result, num = Eval.getStr(value, RE.swapvar)
        if num>0 then return result:gsub(RE.unquote, '%1') end

        result = Eval.getDef(value, predef, scope)
        if Eval.isBool(result) then return predef[result] end

        if result == nil and value:match(RE.tokenvar) then
            Error.undefined('variable',
                value:gsub(RE.swapdef, ''):gsub(RE.tokenvar, '%1')
            )
        end

        return result or value
    end
    return value
end

function Eval.convertArgs(values, predef, scope)
    for k,v in pairs(values) do
        if type(v)=='table' then
            Eval.convertArgs(v, predef, scope)
        else
            values[k] = Eval.replaceArgs(v, predef, scope)
        end
    end
end

function Eval.exeTree(action, values, predef, scope)
    if not RE.specials[action] then
        Eval.convertArgs(values, predef, scope)
    end

    if type(action) == 'string' then
        if Eval.isBool(action) then return predef[action], unpack(values) end

        local result, num = Eval.getStr(action, RE.swapvar)
        if num>0 then return result:gsub(RE.unquote, '%1'), unpack(values) end

        local act = Eval.getDef(action, predef, scope)

        if act then
            if type(act) == 'function' then
                return act(values, predef, scope)
            end
            return act, unpack(values)
        else
            Error.undefined('action', action:gsub(RE.tokenvar, '%1'))
        end
    else

        return action, unpack(values)
    end
end

function Eval.walkTree(tree, predef, scope)
    local args = {}

    if type(tree) == 'table' and not tree.islazy then
        for i=1, #tree do
            if type(tree[i]) == 'table' then
                local results = {Eval.walkTree(tree[i], predef, scope)}
                for j=1, #results do
                    args[#args+1] = results[j]
                end

            else
                args[#args+1] = tree[i]
            end
        end

        if tree.islist or tree.isdict  then
            setmetatable(args, getmetatable(tree))
            return Eval.exeTree(RE.tokenreturn, {args}, predef, scope)
        end

        return Eval.exeTree(tree[1], {unpack(args, 2, #args)}, predef, scope)
    else
        return Eval.exeTree(RE.tokenreturn, {tree}, predef, scope)
    end
end


function Eval.swapString(str)
    Eval.swapkey = Eval.swapkey+1
    local key = RE.swapchar..Eval.swapkey..RE.swapchar
    Eval.swapstr[key] = (
        str
        :gsub('([\\])([fnrtv\\])',
            function(_, s)
                if s == 'f' then return '\f'
                elseif s == 'n' then return '\n'
                elseif s == 'r' then return '\r'
                elseif s == 't' then return '\t'
                elseif s == 'v' then return '\v'
                elseif s == '\\' then return '\\'
                end
            end
        )
    )
    return key
end

function Eval.swapStrings(args)
    local match = string.match(args, '[;\'\"]')
    while match and #args > 1 do
        local oldargs = args
        if  match == ';' then
            args = args:gsub(RE.comment, '')
        elseif match == '"' then
            args = args:gsub(RE.dquote,
                Eval.swapString, 1
            )
        elseif match == "'" then
            args = args:gsub(RE.squote,
                Eval.swapString, 1
            )
        end
        if args == oldargs then
            Error.unpairedQuotes(match)
        end
        match = string.match(args, '[;\'\"]')
    end

    return args
end


function Eval.cleanArgs(args)
    local swap = Eval.swapStrings(args..'\n')

    local cleaned = (
        swap
        :gsub(RE.shellbag, '')
        :gsub('\n',' ')
        :gsub('%s+',' ')
        :gsub('%s+%)',')')
        :gsub('%(%s+','(')
        :gsub('%(%s+%(','((')
        :gsub('%)%s+%)','))')
        :gsub(RE.trimspace, '%1')
    )

    Error.checkBraces(cleaned)
    return cleaned
end

function Eval.call(args, predef, scope, output)
    if args then
        local cleaned = Eval.cleanArgs(args)
        local tree = Eval.splitArgs(cleaned)

        for i=1, #tree do
            output[#output+1] = {Eval.walkTree(tree[i], predef, scope)}
        end
    end
    -- NOTE: return last expr
    return output and output[#output]
end

function Eval.eval(inp, predef, scope, safecall)
    local output = {}
    local exe, result = pcall(Eval.call, inp, predef, scope, output)

    if exe then

        if result and result[1] ~= nil then
            return unpack(result)
        else
            -- NOTE: can't process empty file
            Error.error('eval undefined', scope)
        end
    elseif result:find(RE.tokenbreak) then
        return RE.tokenbreak
    elseif result:find(RE.tokencontinue) then
        return RE.tokencontinue
    else
        if safecall then
            return exe, Error.getError(result, scope)
        end
        Error.error(result, scope)
    end
end

return Eval
