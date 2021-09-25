-- DEF
-- eval.lua

local unpack = table.unpack or unpack

local Error = require('error')
local RE = require('re')

local swapnum = os.time() + os.time() // 2
local Eval = {swapstr = {}, swapkey = swapnum}




function Eval.splitArgs(args, isdef)
    local arr = {}
    if args then
        local match = string.match(args, RE.splitspace)

        while match do
            if string.find(match, '%(%(', 1) then
                local result = ''
                for arg in args:gmatch(RE.isdef) do
                    result = result .. ' ' .. arg:gsub(RE.trimbracket, '%1')
                end
                args = result
            elseif string.find(match, '%(+%s*def$')
                or string.find(match, '%(+%s*mut$')
                or string.find(match, '%(+%s*if$')
                or string.find(match, '%(+%s*for$')
                or string.find(match, '%(+%s*eval$')
                or string.find(match, '%(+%s*call$')
                then

                args = args:gsub(RE.isdef,
                    function(s)
                        local def, body = Eval.getStr(s):match(RE.defall)
                        arr[#arr+1] = {RE.tokenize(def), body}
                        return ''
                    end,
                    1
                )
             elseif string.find(match, '%[') then
                args = args:gsub(RE.islist,
                    function(s)
                        arr[#arr+1] = Eval.splitArgs(
                            s:gsub(RE.trimlist, '%1'),
                            false
                        )
                        setmetatable(arr[#arr], {__index={islist=true}})
                        return ''
                    end,
                    1
                )
            elseif string.find(match, '%(') then
                args = args:gsub(RE.isdef,
                    function(s)
                        arr[#arr+1] = Eval.splitArgs(
                            s:gsub(RE.trimdef, '%1'),
                            true
                        )
                        setmetatable(arr[#arr], {__index={isdef=true}})
                        return ''
                    end,
                    1
                )
            elseif tonumber(match) then
                if #arr == 0 and isdef then
                    Error.wrongCharInFirstAction(match, 'number')
                end
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

function Eval.isBool(value)
    if value == RE.tokentrue or value == RE.tokenfalse then
        return true
    end
    return false
end

function Eval.getStr(value)
    return value:gsub(RE.swapvar,
        function(s)
            return Eval.swapstr[s]
        end
    ):gsub(RE.swapvar,
        function(s)
            return Eval.swapstr[s]
        end
    )
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
        local result, num = Eval.getStr(value):gsub(RE.unquote, '%1')
        if num>0 then return result end

        if Eval.isBool(value) then return predef[value] end

        if scope[value] == false
            -- or (scope[RE.tokenscope] and scope[RE.tokenscope][value] == false)
        then
            return false
        end

        result = Eval.getDef(value, predef, scope)
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
    local act = Eval.getStr(action)
    if act ~= action then
        Error.wrongCharInFirstAction(act, type(act))
    end

    act = Eval.getDef(action, predef, scope)

    if not RE.specials[action] then
        Eval.convertArgs(values, predef, scope)
    end

    if act then
        if type(act) == 'function' then
            return act(values, predef, scope)
        else
            Error.wrongCharInFirstAction(act, type(act))
        end
    else
        Error.undefined('action', action:gsub(RE.token, ''))
    end
end

function Eval.walkTree(tree, predef, scope)
    local args = {}

    if type(tree) == 'table' then
        local action = tree[1]

            for i=2, #tree do
                if type(tree[i]) == 'table' then
                    if tree[i].islist or tree[i].isdict then
                        args[#args+1] = tree[i]
                    else
                        local results = {Eval.walkTree(tree[i], predef, scope)}
                        for j=1, #results do
                            args[#args+1] = results[j]
                        end
                    end
                else
                    args[#args+1] = tree[i]
                end
            end

        return Eval.exeTree(action, args, predef, scope)
    else
        return Eval.exeTree(RE.tokenreturn, {tree}, predef, scope)
    end
end


function Eval.cleanArgs(args)
    args = args:gsub(RE.shellbag, ''):gsub(RE.comment, ''):gsub('\n','')..'\n'

    local swap = args
    for match in swap:gmatch('[\"\']') do
        if match == '"' then
            swap = swap:gsub(RE.dquote,
                function(s)
                    Eval.swapkey = Eval.swapkey+1
                    local key = RE.swapchar..Eval.swapkey..RE.swapchar
                    Eval.swapstr[key] = s
                    return key
                end,
                1
            )
        elseif  match == "'" then
            swap = swap:gsub(RE.squote,
                function(s)
                    Eval.swapkey = Eval.swapkey+1
                    local key = RE.swapchar..Eval.swapkey..RE.swapchar
                    Eval.swapstr[key] = s
                    return key
                end,
                1
            )
        end
    end

    local cleaned = (
        swap
        :gsub('%s+',' ')
        :gsub('%s+%)',')')
        :gsub('%(%s+','(')
        :gsub('%(%s+%(','((')
        :gsub('%)%s+%)','))')
        :gsub(RE.trimspace, '%1')
    )

    Error.checkBraces(cleaned)
    Error.checkQuotes(cleaned)

    return cleaned
end

function Eval.run(args, predef, scope)
    local output = {}

    if args then
        local cleaned = Eval.cleanArgs(args)
        local tree = Eval.splitArgs(cleaned)

        for i=1, #tree do
            output[#output+1] = {Eval.walkTree(tree[i], predef, scope)}

            -- 1 finish evaluate after first return
            -- 2 return literals
            if type(tree[i]) == 'table' and RE.returns[tree[i][1]] then
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
