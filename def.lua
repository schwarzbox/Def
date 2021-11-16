-- DEF
-- def.lua

local unpack = table.unpack or unpack

local settings = require('settings')

local Eval = require('eval')
local Error = require('error')
local RE = require('re')

local Def = {}
local D = {}
local DD = {}


-- definition

function D.predef(_, predef, _)
    local res = {}
    for k,v in pairs(predef) do
        res[k:gsub(RE.tokenvar, '%1')] = v
    end

    setmetatable(res, {__index={isdict=true}})
    return res
end

function D.selfdef(_, _, scope)
    local res = {}
    for k,v in pairs(scope) do
        if k == RE.tokenscope then
            local result = D.selfdef(_,_, v)
            if #result>0 then
                res[k:gsub(RE.tokenvar, '%1')] = result
            end
        else
            if k~= RE.tokendefined then
                res[k:gsub(RE.tokenvar, '%1')] = v
            end
        end
    end

    setmetatable(res, {__index={isdict=true}})
    return res
end


local function define(scope, tokenize, result, mutate)
    if mutate then
        if scope[tokenize] then
            scope[tokenize] = result
        end
    else
        scope[tokenize] = result
    end
    if mutate then
        if scope[RE.tokenscope] then
            define(scope[RE.tokenscope], tokenize, result, mutate)
        end
    end
end

local function trace(scope, path, name)
    if scope[RE.tokendefined] then
        return  scope[RE.tokendefined] ..RE.errsep.. (path or name)
    else
        return path or name
    end
end

function D.def(t, predef, scope, mutate, lambda, path)
    if #t ~= 1 then
        Error.wrongNumberArgs('def', 1)
    end

    local deffunc, fbody = t[1]:match(RE.deffunc)
    local defexpr, ebody = t[1]:match(RE.defexpr)
    local defvar, vbody = t[1]:match(RE.defvar)

    if deffunc then
        if lambda then
            deffunc = 'lambda ' .. deffunc
        end
        local name, args = deffunc:match(RE.defvar)

        Error.checkDefinition(name, mutate and 'mut' or 'def', t[1])
        Error.checkExpression(fbody, mutate and 'mut' or 'def', t[1])

        local param
        if args == '*' then
            param = '*'
        else
            for arg in string.gmatch(args, RE.splitspace) do
                Error.checkDefinition(arg, mutate and 'mut' or 'def', t[1])
            end
            param = Eval.splitArgs(args)
        end

        local function func(...)
            local argf = ...
            local defscope = {}

            for k,v in pairs(scope) do
                defscope[k] = v
            end

            if param == '*' then
                setmetatable(argf, {__index={islist=true}})
                defscope[RE.tokenize('*')] = argf
            else
                for i=1, #param do
                    defscope[param[i]] = argf[i]
                end
            end

            defscope[RE.tokenscope] = scope
            defscope[RE.tokendefined] = trace(scope, path, name)

            return Eval.eval(fbody, predef, defscope)
        end

        if not lambda then
            define(scope, RE.tokenize(name), func, mutate)
        end

        return func

    elseif defexpr then
        for name in defexpr:gmatch(RE.splitspace) do
            Error.checkDefinition(name, mutate and 'mut' or 'def', t[1])
        end
        Error.checkExpression(ebody, mutate and 'mut' or 'def', t[1])

        local vars = Eval.splitArgs(defexpr)

        local res = {Eval.eval(ebody, predef, scope)}

        for i=1, #vars do
            define(scope, vars[i], res[i], mutate)
        end

        return unpack(res)

    elseif defvar then
        Error.checkDefinition(defvar, mutate and 'mut' or 'def', t[1])
        Error.checkExpression(vbody, mutate and 'mut' or 'def', t[1])

        local res = (
            scope[RE.tokenize(vbody)]
            or Eval.eval(vbody, predef, scope)
        )

        define(scope, RE.tokenize(defvar), res, mutate)

        return res

    else
        Error.unableDefine(mutate and 'mut' or 'def', t[1])
    end
end

function D.mut(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('mut', 1)
    end

    return D.def(t, predef, scope, true)
end

function D.lambda(t, predef, scope, path)
    if #t ~= 1 then
        Error.wrongNumberArgs('lambda', 1)
    end

    return D.def(t, predef, scope, false, true, path)
end

-- basic

function D.len(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('len', 1)
    end

    if type(t[1]) == 'string' then
        return #t[1]
    elseif type(t[1]) == 'table' then
        local res = 0
        for _,_ in pairs(t[1]) do
            res=res+1
        end
        return res
    else
        return #t[1]
    end
end

function D.type(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('type', 1)
    end

    local tp =  io.type(t[1]) or type(t[1])

    if tp == 'table' then
        return (
            t[1].isdict and 'dict'
            or t[1].islist and 'list'
            or t[1].islazy and 'lazy'
            or t[1].isdef and 'def'
            or tp
        )
    elseif tp == 'thread' then
        return coroutine.status(t[1]) .. ' '..tp
    elseif tp == 'file' then
        return 'open ' .. io.type(t[1])
    end
    return tp
end

function D.assert(t)
    if #t < 1 then
        Error.wrongNumberArgs('assert', 1)
    end
    if t[2] ~= nil and type(t[2]) ~= 'string' then
        Error.wrongType('assert', 2, 'string')
    end

    if t[2] then
        assert(t[1], t[2])
    else
        assert(t[1])
    end
    return true
end

function D.error(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('error', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('error', 1, 'string')
    end

    error(t[1])
end

function D.num(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('num', 1)
    end

    local res = tonumber(t[1])
    if res == nil then
        return false
    end

    return res
end

function D.str(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('str', 1)
    end

    return tostring(t[1])
end


function D.eval(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('eval', 1)
    end

    local expr = t[1]:gsub(RE.unquote, '%1')
    return Eval.eval(expr, predef, scope)
end

local function doTree(t)
    local res = ''
    for i=1, #t do
        if type(t[i]) == 'table' and t[i].isdef then
            res = res .. '('..doTree(t[i]) ..') '
        elseif type(t[i]) == 'table' and t[i].islist or t[i].islazy then
            res = res .. '['..doTree(t[i]) ..'] '
        else
            res = res .. t[i]..' '
        end
    end

    return res
end

function DD.do_(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('do', 1)
    end
    if type(t[1]) ~= 'table' or t[1].isdict then
        Error.wrongType('do', 1, 'list lazy or def')
    end

    return Eval.eval(doTree(t), predef, scope)
end

function D.load(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('load', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('load', 1, 'string')
    end

    local file = io.open(t[1], 'r')
    if file == nil then
        Error.undefined('load', t[1])
    end

    local expr = file:read('*a')
    io.close(file)

    return Eval.eval(expr, predef, scope)
end

function D.try(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('try', 1)
    end

    return Eval.eval('('..t[1]..')', predef, scope, true)
end

function DD.return_(t)
    return unpack(t)
end

-- math

function D.add(t)
    if #t < 1 then
        Error.wrongNumberArgs('add', 1)
    end

    local res = t[1]
    for i=2, #t do res = res + t[i] end
    return res
end

function D.sub(t)
    if #t < 1 then
        Error.wrongNumberArgs('sub', 1)
    end

    local res = t[1]
    for i=2, #t do res = res - t[i] end
    return res
end

function D.mul(t)
    if #t < 1 then
        Error.wrongNumberArgs('mul', 1)
    end

    local res = t[1]
    for i=2, #t do res = res * t[i] end
    return res
end

function D.div(t)
    if #t < 1 then
        Error.wrongNumberArgs('div', 1)
    end

    local res = t[1]
    for i=2, #t do res = res / t[i] end
    return res
end

function D.fdiv(t)
    if #t < 1 then
        Error.wrongNumberArgs('fdiv', 1)
    end

    local res = t[1]
    for i=2, #t do res = res // t[i] end
    return res
end

function D.modulo(t)
    if #t < 1 then
        Error.wrongNumberArgs('modulo', 1)
    end

    local res = t[1]
    for i=2, #t do res = res % t[i] end
    return res
end

function D.pow(t)
    if #t < 1 then
        Error.wrongNumberArgs('pow', 1)
    end

    local res = t[1]
    for i=2, #t do res = res ^ (t[i]) end
    return res
end

function D.abs(t)
    return math.abs(t[1])
end

function D.acos(t)
    return math.acos(t[1])
end

function D.asin(t)
    return math.asin(t[1])
end

function D.atan(t)
    return math.atan(t[1])
end

function D.ceil(t)
    return math.ceil(t[1])
end

function D.cos(t)
    return math.cos(t[1])
end

function D.deg(t)
    return math.deg(t[1])
end

function D.exp(t)
    return math.exp(t[1])
end

function D.floor(t)
    return math.floor(t[1])
end

function D.fmod(t)
    return math.fmod(unpack(t))
end

function D.log(t)
    return math.log(unpack(t))
end

function D.max(t)
    return math.max(unpack(t))
end

function D.min(t)
    return math.min(unpack(t))
end

function D.modf(t)
    return math.modf(t[1])
end

function D.rad(t)
    return math.rad(t[1])
end

function D.round(t)
    local after = t[2] or 2
    return t[1]-t[1]%(1/10^after)
end

function D.randomseed(t)
    math.randomseed(t[1] or os.time())
    return true
end

function D.random(t)
    return math.random(unpack(t))
end

function D.sin(t)
    return math.sin(t[1])
end

function D.sqrt(t)
    return math.sqrt(t[1])
end

function D.tan(t)
    return math.tan(t[1])
end

function D.ult(t)
    return math.ult(unpack(t))
end

-- condition

function D.eq(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('eq', 2)
    end

    if t[1] == t[2] then return true else return false end
end

function D.neq(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('neq', 2)
    end

    if t[1] ~= t[2] then return true else return false end
end

function D.ge(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('ge', 2)
    end

    if t[1] > t[2] then return true else return false end
end

function D.gte(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('gte', 2)
    end

    if t[1] >= t[2] then return true else return false end
end

function D.le(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('le', 2)
    end

    if t[1] < t[2] then return true else return false end
end

function D.lte(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('lte', 2)
    end

    if t[1] <= t[2] then return true else return false end
end

function DD.and_(t)
    if #t < 1 then
        Error.wrongNumberArgs('and', 1)
    end

    local res = t[1]
    for i=2, #t do res = res and t[i] end
    return res
end

function DD.or_(t)
    if #t < 1 then
        Error.wrongNumberArgs('or', 1)
    end

    local res = t[1]
    for i=2, #t do res = res or t[i] end
    return res
end

function DD.not_(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('not', 1)
    end

    return not t[1]
end


function DD.if_(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('if', 1)
    end

    local cond, body = t[1]:match(RE.defcond)
    if not body then Error.unableDefine('if', t[1]) end

    local defscope = {}
    for k,v in pairs(scope) do
        defscope[k] = v
    end
    defscope[RE.tokendefined] = trace(scope, 'if', nil)

    if Eval.eval(cond, predef, defscope) then
        local expr1 = body:match(RE.isdef)
        defscope[RE.tokenscope] = scope

        local result = Eval.eval(expr1, predef, defscope)

        if result and result == RE.tokenbreak then
            DD.break_(nil, nil, scope)
        end
        if result and result == RE.tokencontinue then
            D.continue(nil, nil, scope)
        end
        return result
    else
        local expr2 = body:gsub(RE.isdef, '', 1):match(RE.isdef)

        if expr2 then
            defscope[RE.tokenscope] = scope

            local result = Eval.eval(expr2, predef, defscope)

            if result and result == RE.tokenbreak then
                DD.break_(nil, nil, scope)
            end
            if result and result == RE.tokencontinue then
                D.continue(nil, nil, scope)
            end

            return result
        else
            return false
        end
    end
end

-- switch

function D.switch(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('switch', 1)
    end

    local defscope = {}
    for k,v in pairs(scope) do
        defscope[k] = v
    end

    local check, result
    for cond, body in t[1]:gmatch(RE.defswitch) do
        check = Eval.eval(cond, predef, defscope)

        if type(check) ~= 'boolean' then
            Error.wrongAction(cond)
        end

        if check then
            defscope[RE.tokenscope] = scope
            defscope[RE.tokendefined] = trace(scope, 'switch', nil)
            result = Eval.eval(body, predef, defscope)

            if result and result == RE.tokenbreak then
                DD.break_(nil, nil, scope)
            end

            if result and result ~= RE.tokencontinue then
                return result
            end
        end
    end

    if check == nil then
        Error.unableDefine('switch', t[1])
    else
        Error.wrongDefault('switch', "(true) ('default')" )
    end
end

-- while

function DD.while_(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('while', 1)
    end

    local cond, body = t[1]:match(RE.defcond)
    if not body then Error.unableDefine('while', t[1]) end

    local callfunc = Eval.getDef(body, predef, scope)

    if not callfunc then
        callfunc = D.lambda({'() ('.. body .. ')'}, predef, scope, 'while')
    end

    local _, result, last
    while D.lambda({'() ('.. cond .. ')'}, predef, scope, 'while')() do
        _, result = pcall(callfunc)

        if result and result == RE.tokenbreak then break end
        if result and result ~= RE.tokencontinue then last = result end
    end

    return last or false
end

-- for

function DD.for_(t, predef, scope)
    if #t ~= 1 then
        Error.wrongNumberArgs('for', 1)
    end

    local cond, body = t[1]:match(RE.deffunc)
    if not body then Error.unableDefine('for', t[1]) end

    local name, iter = cond:match(RE.defvar)
    Error.checkDefinition(name, 'for', t[1])

    local callfunc = Eval.getDef(body, predef, scope)

    if not callfunc then
        callfunc = D.lambda({'('..name..') '.. body}, predef, scope, 'for')
    end

    local iterable = D.lambda(
        {'() (return '..iter..')'}, predef, scope, 'for'
    )()

    local _, result, last
    if type(iterable) == 'table' then
        for k,v in pairs(iterable) do
            if iterable.isdict then
                _, result = pcall(callfunc, {k})
            else
                _, result = pcall(callfunc, {v})
            end
            if result and result == RE.tokenbreak then break end
            if result and result ~= RE.tokencontinue then last = result end
        end
    else
        for line in iterable do
            _, last = pcall(callfunc, {line})
        end
    end

    return last or false
end

function DD.break_(_,_,scope)
    if not (string.match(scope[RE.tokendefined] or '', 'while')
        or string.match(scope[RE.tokendefined] or '', 'for')) then
        Error.wrongScope('break', 'for or while')
    end
    error(RE.tokenbreak)
end

function D.continue(_,_,scope)
    if not (string.match(scope[RE.tokendefined] or '', 'while')
        or string.match(scope[RE.tokendefined] or '', 'for')) then
        Error.wrongScope('continue', 'for or while')
    end
    error(RE.tokencontinue)
end

-- coroutine&threads

function D.iter(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('iter', 1)
    end
    if type(t[1]) ~= 'table' then
        Error.wrongType('iter', 1, 'dict list lazy or def')
    end

    return coroutine.create(
        function()
            for k,v in pairs(t[1]) do
                if t[1].isdict then
                    coroutine.yield(k)
                else
                    coroutine.yield(v)
                end
            end
        end
    )
end

function D.thread(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('thread', 1)
    end
    if type(t[1]) ~= 'function' then
        Error.wrongType('thread', 1, 'function')
    end

    return coroutine.create(t[1])
end

function D.run(t)
    if #t < 1 then
        Error.wrongNumberArgs('run', 1)
    end
    if type(t[1]) == 'thread' and coroutine.status(t[1]) ~= 'suspended' then
        Error.wrongType('run', 1, 'dead thread')
    end
    if type(t[1]) ~= 'thread' then
        Error.wrongType('run', 1, 'thread')
    end

    local args = {}
    for i=2, #t do args[#args+1] = t[i] end
    if #args == 0 then
        args = {}
    end

    local exe, res = coroutine.resume(t[1], args)
    return exe and res or (res or false)
end

function D.wrap(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('wrap', 1)
    end
    if type(t[1]) ~= 'function' then
        Error.wrongType('wrap', 1, 'function')
    end

    return coroutine.wrap(t[1])
end

function D.yield(t)
    return coroutine.yield(t[1])
end

-- list

function D.range(t)
    if #t < 1 then
        Error.wrongNumberArgs('range', 1)
    end
    for i=1, 3 do
        if t[i] ~= nil and type(t[i]) ~= 'number' then
            Error.wrongType('range', i, 'number')
        end
    end

    local res = {}
    local last = t[2] or t[1]
    local first = t[2] and t[1] or 1
    local step = t[3] or 1

    for i=first, last, step do
        res[#res+1]=i
    end

    return setmetatable(res, {__index={islist=true}})
end


local function clone(t)
    local res = {}
    for k,v in pairs(t) do
        res[k]=v
    end
    return res
end

function D.list(t)
    return setmetatable(clone(t), {__index={islist=true}})
end

function D.split(t)
    if #t < 1 then
        Error.wrongNumberArgs('split', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('split', 1, 'string')
    end
    if t[2] ~= nil and type(t[2]) ~= 'string' then
        Error.wrongType('split', 2, 'string')
    end

    local res = {}
    local sep = t[2] or ''
    if #sep>0 then
        for i in string.gmatch(t[1],'[^'..sep..']+') do
            res[#res+1]=i
        end
    else
        for i=1, #t[1] do
            res[i]=t[1]:sub(i,i)
        end
    end

    return setmetatable(res, {__index={islist=true}})
end

function D.first(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('first', 1)
    end
    if type(t[1]) ~= 'table' or t[1].isdict then
        Error.wrongType('first', 1, 'list lazy or def')
    end

    local res = t[1][1]
    if res == nil then
        Error.undefined('first', #t[1])
    end

    return res
end

function D.last(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('last', 1)
    end
    if type(t[1]) ~= 'table' or t[1].isdict then
        Error.wrongType('last', 1, 'list lazy or def')
    end

    local res = t[1][#t[1]]
    if res == nil then
        Error.undefined('last', #t[1])
    end

    return res
end

function D.push(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('push', 2)
    end

    if type(t[1]) ~= 'table' or t[1].isdict then
        Error.wrongType('push', 1, 'list lazy or def')
    end

    t[1][#t[1]+1] = t[2]

    return t[1]
end

function D.pop(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('pop', 1)
    end
    if type(t[1]) ~= 'table' or t[1].isdict then
        Error.wrongType('pop', 1, 'list lazy or def')
    end

    local res = t[1][#t[1]]
    t[1][#t[1]] = nil
    if res == nil then
        Error.undefined('pop', #t[1])
    end

    return res
end

function D.sort(t)
    if #t < 1 then
        Error.wrongNumberArgs('sort', 1)
    end
    if type(t[1]) ~= 'table' or not t[1].islist then
        Error.wrongType('sort', 1, 'list')
    end
    if t[2] ~= nil and type(t[2]) ~= 'boolean' then
        Error.wrongType('sort', 2, 'boolean')
    end

    local res = clone(t[1])
    if t[2] then
        table.sort(res, function(a, b) return a>b end)
    else
        table.sort(res)
    end

    return setmetatable(res, getmetatable(t[1]))
end

function D.flip(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('flip', 1)
    end
    if type(t[1]) ~= 'table' or not t[1].islist then
        Error.wrongType('flip', 1, 'list')
    end

    local res = {}
    for i=#t[1], 1, -1 do
        res[#res+1] = t[1][i]
    end

    return setmetatable(res, getmetatable(t[1]))
end

function D.concat(t)
    if #t < 1 then
        Error.wrongNumberArgs('concat', 1)
    end
    if type(t[1]) ~= 'table' or not t[1].islist then
        Error.wrongType('unpack', 1, 'list')
    end
    if t[2] ~= nil and type(t[2]) ~= 'string' then
        Error.wrongType('concat', 2, 'string')
    end

    return table.concat(unpack(t))
end

function D.unpack(t)
    if #t < 1 then
        Error.wrongNumberArgs('unpack', 1)
    end
    if type(t[1]) ~= 'table' or not t[1].islist then
        Error.wrongType('unpack', 1, 'list')
    end
    for i=2, 4 do
        if t[i] ~= nil and type(t[i]) ~= 'number' then
            Error.wrongType('unpack', i, 'number')
        end
    end

    return unpack(t[1], t[2] or 1, t[3] or #t[1])
end

function D.pack(t)
    return setmetatable(table.pack(unpack(t)), {__index={islist=true}})
end

function D.move(t)
    if #t < 4 then
        Error.wrongNumberArgs('move', 4)
    end
    if type(t[1]) ~= 'table' or not t[1].islist then
        Error.wrongType('move', 1, 'list')
    end
    for i=2, 4 do
        if type(t[i]) ~= 'number' then
            Error.wrongType('move', i, 'number')
        end
    end
    if t[5] ~= nil and type(t[5]) ~= 'table' then
         Error.wrongType('move', 5, 'dict list lazy or def')
    end

    return setmetatable(table.move(unpack(t)), {__index={isdict=true}})
end


-- dict

function D.dict(t)
    for i=1, #t do
        if type(t[i]) ~= 'table' then
            Error.wrongType('dict', i, 'list or lazy')
        end
    end

    local res = {}
    for i=1, #t do
        if #t[i] ~= 2 then
            Error.wrongNumberArgs('dict', 2)
        end

        res[t[i][1]] = t[i][2]
    end

    return setmetatable(res, {__index={isdict=true}})
end

-- dict&list


function D.keys(t)
    if #t ~=1 then
        Error.wrongNumberArgs('keys', 1)
    end
    if type(t[1]) ~= 'table' then
        Error.wrongType('keys', 1, 'dict list lazy or def')
    end

    local res = {}
    for k,_ in pairs(t[1]) do
        res[#res+1] = k
    end

    return setmetatable(res, {__index={islist=true}})
end

function D.values(t)
    if #t ~=1 then
        Error.wrongNumberArgs('values', 1)
    end
    if type(t[1]) ~= 'table' then
        Error.wrongType('values', 1, 'dict list lazy or def')
    end

    local res = {}
    for _,v in pairs(t[1]) do
        res[#res+1] = v
    end

    return setmetatable(res, {__index={islist=true}})
end

function D.map(t)
    if #t ~=2 then
        Error.wrongNumberArgs('map', 2)
    end
    if type(t[1]) ~= 'table' then
        Error.wrongType('map', 1, 'dict list lazy or def')
    end
    if type(t[2]) ~= 'function' then
        Error.wrongType('map', 2, 'function')
    end

    local res = {}
    for k,v in pairs(t[1]) do
        res[k]=t[2]({v})
    end

    return setmetatable(res, getmetatable(t[1]))
end

function D.filter(t)
    if #t ~=2 then
        Error.wrongNumberArgs('filter', 2)
    end
    if type(t[1]) ~= 'table' then
        Error.wrongType('filter', 1, 'dict list lazy or def')
    end
    if type(t[2]) ~= 'function' then
        Error.wrongType('filter', 2, 'function')
    end

    local res = {}
    for k,v in pairs(t[1]) do
        if t[2]({v}) then
            res[k]=v
        end
    end

    return setmetatable(res, {__index={isdict=true}})
end


function D.merge(t)
    local res = {}

    for i=1, #t do
        if type(t[i]) ~= 'table' then
            Error.wrongType('merge', i, 'dict list lazy or def')
        end

        for k,v in pairs(t[i]) do
            local key = k
            if type(key) == 'number' and res[key] then
                while res[key] do
                    key = key + 1
                end
            end
            res[key] = v
        end
    end

    return setmetatable(res, getmetatable(t[1]))
end

-- dict&list&string

function D.get(t)
    local res
    if #t ~= 2 then
        Error.wrongNumberArgs('get', 2)
    end

    if type(t[1]) == 'string' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('get', 2, 'number')
        end

        res = t[1]:sub(t[2],t[2])
        if res == '' then
            Error.undefined('key', t[2])
        end

        return t[1]:sub(t[2],t[2])
    elseif type(t[1]) == 'table' and t[1].isdict then
        res = t[1][t[2]]
        if res == nil then
            Error.undefined('key', t[2])
        end

        return res
    elseif type(t[1]) == 'table' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('get', 2, type(t[2]), tostring(t[2]))
        end
        if t[2] <= 0 or t[2] > #t[1] then
            Error.wrongKey('get', 2)
        end

        res = t[1][t[2]]
        if res == nil then
            Error.undefined('key', t[2])
        end

        return res
    end

    Error.wrongType('get', 1, 'string dict list lazy or def')
end

function D.has(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('has', 2)
    end

    if type(t[1]) == 'string' then
        if type(t[2]) ~= 'string' then
            Error.wrongType('del', 2, 'number')
        end

        return t[1]:find(t[2]) and true or false
    elseif type(t[1]) == 'table' then
        for _,v in pairs(t[1]) do
            if v == t[2] then
                return true
            end
        end
        return false
    end

    Error.wrongType('has', 1, 'string dict list lazy or def')
end

function D.set(t)
    if #t ~= 3 then
        Error.wrongNumberArgs('set', 3)
    end

    if type(t[1]) == 'string' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('set', 2, 'number')
        end
        if type(t[3]) ~= 'string' then
            Error.wrongType('set', 2, 'string')
        end

        return t[1]:sub(1, t[2]-1)..t[3]..t[1]:sub(t[2]+1, #t[1])
    elseif type(t[1]) == 'table' and t[1].isdict then
        t[1][t[2]] = t[3]
        return t[1]
    elseif type(t[1]) == 'table' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('set', 2, 'number')
        end
        if t[2] <= 0 or t[2] > #t[1]+1 then
            Error.wrongKey('set', 2)
        end

        t[1][t[2]] = t[3]
        return t[1]
    end
    Error.wrongType('set', 1, 'string dict list lazy or def')
end

function D.del(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('del', 2)
    end

    if type(t[1]) == 'string' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('del', 2, 'number')
        end

        return t[1]:sub(1, t[2]-1)..t[1]:sub(t[2]+1, #t[1])
    elseif type(t[1]) == 'table' and t[1].isdict then
        t[1][t[2]] = nil
        return t[1]
    elseif type(t[1]) == 'table' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('del', 2, 'number')
        end
        if t[2] <= 0 or t[2] > #t[1] then
            Error.wrongKey('del', 2)
        end

        table.remove(t[1], t[2])
        return t[1]
    end

    Error.wrongType('del', 1, 'string dict list lazy or def')
end

function D.insert(t)
    if #t ~= 3 then
        Error.wrongNumberArgs('insert', 3)
    end

    if type(t[1]) == 'string' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('insert', 2, 'number')
        end
        if type(t[3]) ~= 'string' then
            Error.wrongType('insert', 3, 'string')
        end

        return t[1]:sub(1, t[2]-1)..t[3]..t[1]:sub(t[2])
    elseif type(t[1]) == 'table' and t[1].isdict then
        t[1][t[2]] = t[3]
        return t[1]
    elseif type(t[1]) == 'table' then
        if type(t[2]) ~= 'number' then
            Error.wrongType('insert', 2, 'number')
        end

        table.insert(t[1], t[2], t[3])
        return t[1]
    end

    Error.wrongType('insert', 1, 'string dict list lazy or def')
end

function D.next(t)
    if #t < 1 then
        Error.wrongNumberArgs('next', 1)
    end
    if t[2] ~= nil and type(t[2]) ~= 'number' then
        Error.wrongType('next', 2, 'number')
    end

    if type(t[1]) == 'string' then
        return t[1]:sub((t[2] or 0) + 1, (t[2] or 0) + 1)
    elseif type(t[1]) == 'table' then
        return next(t[1], t[2])
    end

    Error.wrongType('next', 1, 'string dict list lazy or def')
end

-- string

function D.upper(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('upper', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('upper', 1, 'string')
    end

    return string.upper(t[1])
end

function D.lower(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('lower', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('lower', 1, 'string')
    end

    return string.lower(t[1])
end

function D.capitalize(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('capitalize', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('capitalize', 1, 'string')
    end

    local res = string.gsub(t[1], '^.', string.upper)
    return res
end

function D.title(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('title', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('title', 1, 'string')
    end

    local res = ''
    for word in t[1]:gmatch('%g+') do
        res = res .. string.gsub(word, '^.', string.upper) .. ' '
    end

    return string.sub(res, 1, #res-1)
end

function DD.repeat_(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('repeat', 2)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('repeat', 1, 'string')
    end

    return string.rep(t[1], t[2])
end

function D.replace(t)
    if #t ~= 3 then
        Error.wrongNumberArgs('replace', 3)
    end
    for i=1, 3 do
        if type(t[i]) ~= 'string' then
            Error.wrongType('replace', i, 'string')
        end
    end

    local res = string.gsub(t[1], t[2], t[3])
    return res
end

function D.reverse(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('reverse', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('reverse', 1, 'string')
    end

    return string.reverse(t[1])
end

function D.find(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('find', 2)
    end
    for i=1, 2 do
        if type(t[i]) ~= 'string' then
            Error.wrongType('find', i, 'string')
        end
    end

    return string.find(t[1], t[2]) or false
end

function D.match(t)
    if #t < 2 then
        Error.wrongNumberArgs('match', 3)
    end
    for i=1, 2 do
        if type(t[i]) ~= 'string' then
            Error.wrongType('match', i, 'string')
        end
    end
    if t[3] ~= nil and type(t[3]) ~= 'number' then
        Error.wrongType('match', 3, 'number')
    end

    return string.match(t[1], t[2], t[3]) or false
end

function D.trim(t)
    if #t < 1 then
        Error.wrongNumberArgs('trim', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('trim', 1, 'string')
    end
    if t[2] ~= nil and type(t[2]) ~= 'string' then
        Error.wrongType('trim', 2, 'string')
    end

    local trim = RE.trimspace
    if t[2] then
        trim = '^['..t[2]..']*(.-)['..t[2]..']*$'
    end

    local res = string.gsub(t[1], trim, '%1')
    return res
end

function D.join(t)
    local res = ''
    for i=1, #t do
        if type(t[i]) == 'string' then
            res = res .. t[i]
        else
            Error.wrongType('join', i, 'string')
        end
    end

    return res
end

function D.format(t)
    if #t < 1 then
        Error.wrongNumberArgs('format', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('format', 1, 'string')
    end

    return string.format(unpack(t))
end

function D.byte(t)
    if #t == 0 then
        return setmetatable({}, {__index={islist=true}})
    end
    return setmetatable({string.byte(unpack(t))}, {__index={islist=true}})
end

function D.char(t)
    return D.split({string.char(unpack(t))})
end


-- io

function D.input()
    return io.read()
end

local openmodes = {
    ['r']=true, ['r+']=true, ['rb']=true,
    ['w']=true, ['w+']=true, ['wb']=true,
    ['a']=true, ['a+']=true, ['ab']=true
}
function D.open(t)
    if #t < 1 then
        Error.wrongNumberArgs('open', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('open', 1, 'string')
    end
    if t[2] ~= nil and not openmodes[t[2]] then
        Error.wrongType('open', 2, 'r/r+/rb w/w+/wb a/a+/ab')
    end

    local file = io.open(t[1], t[2] or 'r')
    if not file then Error.undefined('file', t[1]) end
    return file
end


function D.close(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('close', 1)
    end
    Error.checkFile(t[1], 'close')

    return io.close(t[1])
end

function D.tmpfile()
    return io.tmpfile()
end


local readmodes={
    ['*l']=true, ['*L']=true,
    ['l']=true, ['L']=true,
    ['*n']=true, ['n']=true,
    ['*num']=true, ['num']=true,
    ['*a']=true, ['a']=true
}
function D.read(t)
    if #t < 1 then
        Error.wrongNumberArgs('read', 1)
    end
    Error.checkFile(t[1], 'read')

    if t[2] ~= nil and (not readmodes[t[2]] and type(t[2])~='number') then
        Error.wrongType('read', 2, '*l/l *L/L *n/n *num/num *a/a or number')
    end

    return t[1]:read(t[2] or '*a')
end

function D.lines(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('lines', 1)
    end
    Error.checkFile(t[1], 'lines')

    return t[1]:lines()
end

function D.write(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('write', 2)
    end
    Error.checkFile(t[1], 'write')

    if type(t[2]) ~= 'string' then
        Error.wrongType('write', 2, 'string')
    end

    t[1]:write(t[2])
    return true
end

local seekmodes = {
    ['set']=true, ['cur']=true, ['end']=true
}
function D.seek(t)
    if #t < 1 then
        Error.wrongNumberArgs('seek', 1)
    end
    Error.checkFile(t[1], 'seek')
    if t[2] ~= nil and not seekmodes[t[2]] then
        Error.wrongType('seek', 2, 'cur set or end')
    end
    if t[3] ~= nil and type(t[3]) ~= 'number' then
        Error.wrongType('seek', 3, 'number')
    end

    return t[1]:seek(t[2], t[3])
end

function D.flush(t)
    if #t < 1 then
        Error.wrongNumberArgs('flush', 1)
    end
    Error.checkFile(t[1], 'flush')

    return t[1]:flush()
end

local buffermodes = {
    ['no']=true, ['line']=true, ['full']=true
}
function D.buffer(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('buffer', 1)
    end
    Error.checkFile(t[1], 'buffer')
    Error.checkFile(t[1], 'seek')
    if t[2] ~= nil and not buffermodes[t[2]] then
        Error.wrongType('seek', 2, 'no line or full')
    end
    if t[2] ~= nil and type(t[2]) ~= 'string' then
        Error.wrongType('buffer', 3, 'string')
    end

    return t[1]:setvbuf(t[2])
end

function D.readfile(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('readfile', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('readfile', 1, 'string')
    end

    local file = io.open(t[1], 'r')
    if not file then Error.undefined('file', t[1]) end

    local res = file:read('*a')
    io.close(file)
    return res
end

function D.readlines(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('readlines', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('readlines', 1, 'string')
    end
    local file = io.lines(t[1])
    if not file then Error.undefined('file', t[1]) end

    local res = {}
    for line in file do res[#res+1] = line end
    setmetatable(res, {__index={islist=true}})
    return res
end

function D.writefile(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('writefile', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('writefile', 1, 'string')
    end
    if type(t[2]) ~= 'string' then
        Error.wrongType('writefile', 2, 'string')
    end

    local file = io.open(t[1], 'w')
    if not file then Error.undefined('file', t[1]) end

    file:write(t[2])
    io.close(file)
    return true
end

function D.shell(t)
    if #t < 1 then
        Error.wrongNumberArgs('shell', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('shell', 1, 'string')
    end
    if t[2] ~= nil and (t[2]~='r' and t[2]~='w') then
        Error.wrongType('shell', 2, 'r/w')
    end

    return io.popen(t[1], t[2])
end

-- os

function D.clock()
    return os.clock()
end

function D.date(t)
    if #t < 1 then
        Error.wrongNumberArgs('date', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('date', 1, 'string')
    end
    if t[2] ~= nil and type(t[2]) ~= 'number' then
        Error.wrongType('date', 2, 'number')
    end

    local date = os.date(t[1], t[2])
    if type(date) == 'table' then
        return setmetatable(date, {__index={isdict=true}})
    end

    return date
end

function D.time(t)
    if t[1] ~= nil and type(t[1]) ~= 'table' then
        Error.wrongType('time', 1, 'dict')
    end

    return os.time(t[1])
end

function D.difftime(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('difftime', 2)
    end
    for i=1, 2 do
        if type(t[i]) ~= 'number' then
            Error.wrongType('difftime', i, 'string')
        end
    end

    return os.difftime(t[1], t[2])
end

function D.execute(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('execute', 1)
    end

    return os.execute(t[1])
end

function D.remove(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('remove', 1)
    end

    return os.remove(t[1])
end

function D.rename(t)
    if #t ~= 2 then
        Error.wrongNumberArgs('rename', 2)
    end

    return os.rename(t[1], t[2])
end

function D.tmpname()
    return os.tmpname()
end

function D.getenv(t)
    if #t ~= 1 then
        Error.wrongNumberArgs('getenv', 1)
    end
    if type(t[1]) ~= 'string' then
        Error.wrongType('getenv', 1, 'string')
    end

    local res = os.getenv(t[1])
    if res == nil then
        Error.undefined('environment', t[1])
    end

    return res
end

function D.setlocale(t)
    local res = os.setlocale(t[1])
    if res == nil then
        Error.undefined('locale', t[1])
    end

    return res
end

function D.exit(t)
    return os.exit(t[1])
end

-- bits

function D.band(t)
    if #t < 2 then
        Error.wrongNumberArgs('band', 2)
    end

    local res = t[1]
    for i=2, #t do res = res & t[i] end
    return res
end

function D.bor(t)
    if #t < 2 then
        Error.wrongNumberArgs('bor', 2)
    end

    local res = t[1]
    for i=2, #t do res = res | t[i] end
    return res
end

function D.bxor(t)
    if #t < 1 then
        Error.wrongNumberArgs('bxor', 1)
    end

    if #t==1 then
        return ~t[1]
    end
    local res = t[1]
    for i=2, #t do res = res ~ t[i] end
    return res
end

function D.lshift(t)
    if #t < 2 then
        Error.wrongNumberArgs('lshift', 2)
    end

    local res = t[1]
    for i=2, #t do res = res << t[i] end
    return res
end

function D.rshift(t)
    if #t < 2 then
        Error.wrongNumberArgs('rshift', 2)
    end

    local res = t[1]
    for i=2, #t do res = res >> t[i] end
    return res
end

-- output

local function printer(value, output)
    if type(value) == 'table' then
        output[#output+1]=('[')
        for k,v in pairs(value) do
            output[#output+1]=(' ')
            printer(k, output)
            output[#output+1]=(': ')
            printer(v, output)
            output[#output+1]=(' ')
        end
        output[#output+1]=(']')
    else
        if type(value) == 'string' then
            output[#output+1]=(
                "'"..Eval.getStr(value, RE.swapdef).."' "
            )
        else
            output[#output+1]=(tostring(value)..' ')
        end
    end
    return output
end

function D.show(t)
    local output = {}
    for i=1, #t do
        output = printer(t[i], output)
    end
    local res = table.concat(output):gsub(RE.trimspace, '%1')

    io.write(res)
    io.write('\n')

    return res
end

for k,v in pairs(D) do
    Def[RE.tokenize(k)] = v
end

-- sugar

Def[RE.tokenize('ARGS')] = arg
Def[RE.tokenize('VERSION')] = settings.VERSION .. ' ('.. _VERSION .. ')'
Def[RE.tokenize('#')] = D.len
Def[RE.tokenize('do')] = DD.do_
Def[RE.tokenize('?')] = D.type
Def[RE.tokenize('+')] = D.add
Def[RE.tokenize('-')] = D.sub
Def[RE.tokenize('*')] = D.mul
Def[RE.tokenize('/')] = D.div
Def[RE.tokenize('//')] = D.fdiv
Def[RE.tokenize('PI')] = math.pi
Def[RE.tokenize('HUGE')] = math.huge
Def[RE.tokenize('MAXINT')] = math.maxinteger
Def[RE.tokenize('MININT')] = math.mininteger
Def[RE.tokenize('==')] = D.eq
Def[RE.tokenize('!=')] = D.neq
Def[RE.tokenize('>')] = D.ge
Def[RE.tokenize('>=')] = D.gte
Def[RE.tokenize('<')] = D.le
Def[RE.tokenize('<=')] = D.lte
Def[RE.tokenize('and')] = DD.and_
Def[RE.tokenize('or')] = DD.or_
Def[RE.tokenize('not')] = DD.not_
Def[RE.tokenize('&&')] = DD.and_
Def[RE.tokenize('||')] = DD.or_
Def[RE.tokenize('!')] = DD.not_
Def[RE.tokenize('..')] = D.join
Def[RE.tokenize('repeat')] = DD.repeat_
Def[RE.tokenreturn] = DD.return_

Def[RE.tokenbreak] = DD.break_
Def[RE.tokenL] = D.lambda
Def[RE.tokenif] = DD.if_
Def[RE.tokenwhile] = DD.while_
Def[RE.tokenfor] = DD.for_

Def[RE.tokentrue] = true
Def[RE.tokenfalse] = false

-- bits

Def[RE.tokenize('&')] = D.band
Def[RE.tokenize('|')] = D.bor
Def[RE.tokenize('~')] = D.bxor
Def[RE.tokenize('<<')] = D.lshift
Def[RE.tokenize('>>')] = D.rshift


return Def
