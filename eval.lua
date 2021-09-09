-- DEF
-- eval.lua

local unpack = table.unpack or unpack

local Error = require('error')
local RE = require('re')

local Eval = {}

function Eval.splitArgs(args, isdef)
    local arr = {}
    if args then
        local match = string.match(args, RE.splitspace)
        local cnt = 0


        while match do
            print(match)
            print(args)
            if string.find(match, '%(%(', 1) then
                print('br', args:gsub(RE.trimbracket, '%1'))
                args = args:gsub(RE.trimbracket, '%1')
                print(args)
            elseif string.find(match, '%(+%s*def$')
                or string.find(match, '%(+%s*mut$')
                or string.find(match, '%(+%s*if$')
                or string.find(match, '%(+%s*for$')
                or string.find(match, '%(+%s*eval$')
                or string.find(match, '%(+%s*call$')
                then

                args = args:gsub(RE.isdef,
                    function(s)
                        local def, body = s:match(RE.defall)

                        arr[#arr+1] = {RE.tokenize(def), body}
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '^[\"]') then
                if #arr == 0 and isdef then
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
                if #arr == 0 and isdef then
                    Error.wrongCharAction("'", match)
                end
                args = args:gsub(RE.squote,
                    function(s)
                        arr[#arr+1] = s
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '%[') then
                args = args:gsub(RE.islist,
                    function(s)
                        for tab in string.gmatch(s, RE.islist) do
                            arr[#arr+1] = Eval.splitArgs(
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
                args = args:gsub(RE.isdef,
                    function(s)
                        for tab in string.gmatch(s, RE.isdef) do
                            arr[#arr+1] = Eval.splitArgs(
                                tab:gsub(RE.trimdef, '%1'),
                                true
                            )
                            setmetatable(arr[#arr], {__index={isdef=true}})
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
            cnt = cnt +1
            if cnt==13 then break end
            print(cnt)
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

        if (
            scope[value] == false
            or (scope[RE.tokenscope] and scope[RE.tokenscope][value] == false)
        ) then
            return false
        end

        local result = Eval.getDef(value, predef, scope)

        if Eval.isBool(result) then return predef[result] end

        if result == nil and value:match(RE.tokenvar) then
            Error.undefined('variable', value:gsub(RE.token, ''))
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
    local act = Eval.getDef(action, predef, scope)

    if not RE.specials[action] then
        Eval.convertArgs(values, predef, scope)
    end

    if act then
        return act(values, predef, scope)
    else
        Error.undefined('action', action:gsub(RE.token, ''))
    end
end

function Eval.walkTree(tree, predef, scope)
    local args = {}
    local action = tree[1]

    for i=2, #tree do
        if type(tree[i]) == 'table' and not tree[i].islist then
            local results = {Eval.walkTree(tree[i], predef, scope)}
            for j=1, #results do
                args[#args+1] = results[j]
            end
        else
            args[#args+1] = tree[i]
        end
    end
    return Eval.exeTree(action, args, predef, scope)
end

function Eval.cleanArgs(args)
    args = args:gsub(RE.shellbag, '')
    return (
        (args .. '\n')
        :gsub(RE.comment, '')
        :gsub('%s+',' ')
        :gsub('%s+%)',')')
        :gsub('%(%s+','(')
        :gsub('%(%s+%(','((')
        :gsub('%)%s+%)','))')
        :gsub(RE.trimspace, '%1')
    )
end

function Eval.run(args, predef, scope)
    local output = {}

    if args then
        Error.checkBraces(args)
        Error.checkQuotes(args)

        local tree = Eval.splitArgs(Eval.cleanArgs(args))

        for i=1, #tree do
            output[#output+1] = {Eval.walkTree(tree[i], predef, scope)}
            -- finish evaluate after first return
            if RE.returns[tree[i][1]] then
                break
            end
        end
    end

    -- return last expr in definition
    return output and output[#output]
end

function Eval.eval(inp, predef, scope, safecall)
    local exe, result = pcall(Eval.run, inp, predef, scope)

    if exe then
        if result then
            return unpack(result)
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
