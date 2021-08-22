-- LUSP
-- def.lua

local unpack = table.unpack or unpack

local settings = require('settings')

local Lusp = require('lusp')
local Error = require('error')
local RE = require('re')

local Def = {}

-- definition

function Def._lusp_(_, predef, _)
    local res = {}
    for k,v in pairs(predef) do
        res[k:gsub(RE.token, '')] = v
    end
    return res
end

function Def._scope_(_, _, scope)
    local res = {}
    for k,v in pairs(scope) do
        if k == '_scope_' then
            res[k] = Def._scope_(_,_, v)
        else
            res[k:gsub(RE.token, '')] = v
        end
    end
    return res
end


local function define(scope, tokenize, result, mutate)
    scope[tokenize] = result
    if mutate then
        if scope['_scope_'] and scope['_scope_'][tokenize] then
            scope['_scope_'][tokenize] = result
        end
    end
end

function Def._def_(t, predef, scope, mutate)
    local fdef, fbody = t[1]:match(RE.deffunc)
    local edef, ebody = t[1]:match(RE.defexpr)
    local vdef, vbody = t[1]:match(RE.defvar)

    -- print('f',fdef, fbody)
    -- print('e',edef, ebody)
    -- print('d', vdef, vbody)

    if fdef then
        local name, args = fdef:match(RE.defvar)
        Error.checkVariable(name)
        Error.checkDefinition(name, t[1], mutate and 'mut' or 'def')

        local param = Lusp.splitArgs(args)

        local function func(...)
            local argf = ...
            local upvalue = {}

            for k,v in pairs(scope) do
                upvalue[k] = v
            end
            for i=1, #param do
                upvalue[param[i]] = argf[i]
            end
            upvalue['_scope_'] = scope
            upvalue['_name_'] = name
            return Lusp.eval(fbody, predef, upvalue)
        end

        define(scope, RE.tokenize(name), func, mutate)

    elseif edef then
        for var in edef:gmatch(RE.splitspace) do
            Error.checkVariable(var)
            Error.checkDefinition(var, t[1], mutate and 'mut' or 'def')
        end
        local vars = Lusp.splitArgs(edef)
        local res = {Lusp.eval(ebody, predef, scope)}
        for i=1, #vars do
            define(scope, vars[i], res[i], mutate)
        end

    elseif vdef then
        Error.checkVariable(vdef)
        Error.checkDefinition(vdef, t[1], mutate and 'mut' or 'def')

        local res = (
            scope[RE.tokenize(vbody)]
            or Lusp.eval('(-> '..vbody..')', predef, scope)
        )

        define(scope, RE.tokenize(vdef), res, mutate)

    else
        Error.unableDefine(t[1], mutate and 'mut' or 'def')
    end
end

function Def._mut_(t, predef, scope)
    Def._def_(t, predef, scope, true)
end

-- basic

function Def._len_(t)
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

function Def._type_(t)
    return type(t[1])
end

function Def._assert_(t)
    if t[2] then
        assert(t[1], t[2])
    else
        assert(t[1])
    end
    return true
end

function Def._error_(t)
    error(t[1])
end

function Def._num_(t)
    return tonumber(t[1])
end

function Def._str_(t)
    return tostring(t[1])
end

function Def._return_(t)
    return unpack(t)
end

function Def._eval_(t, predef, scope)
    local expr = t[1]:gsub(RE.string, '%1')
    return Lusp.eval(expr, predef, scope)
end

function Def._do_(t, predef, scope)
    local file = io.open(t[1], 'r')
    local expr = file:read('*a')
    file:close()
    return Lusp.eval(expr, predef, scope)
end

function Def._call_(t, predef, scope)
    return Lusp.eval('('..t[1]..')', predef, scope, true)
end


-- math

function Def._add_(t)
    local res = t[1]
    for i=2, #t do res = res + t[i] end
    return res
end

function Def._sub_(t)
    local res = t[1]
    for i=2, #t do res = res - t[i] end
    return res
end

function Def._mul_(t)
    local res = t[1]
    for i=2, #t do res = res * t[i] end
    return res
end

function Def._div_(t)
    local res = t[1]
    for i=2, #t do res = res / t[i] end
    return res
end

function Def._fdiv_(t)
    local res = t[1]
    for i=2, #t do res = res // t[i] end
    return res
end

function Def._modulo_(t)
    local res = t[1]
    for i=2, #t do res = res % t[i] end
    return res
end

function Def._pow_(t)
    local res = t[1]
    for i=2, #t do res = res ^ (t[i]) end
    return res
end

function Def._abs_(t)
    return math.abs(t[1])
end

function Def._acos_(t)
    return math.acos(t[1])
end

function Def._asin_(t)
    return math.asin(t[1])
end

function Def._atan_(t)
    return math.atan(t[1])
end

function Def._ceil_(t)
    return math.ceil(t[1])
end

function Def._cos_(t)
    return math.cos(t[1])
end

function Def._deg_(t)
    return math.deg(t[1])
end

function Def._exp_(t)
    return math.exp(t[1])
end

function Def._floor_(t)
    return math.floor(t[1])
end

function Def._fmod_(t)
    return math.fmod(t[1], t[2])
end

function Def._log_(t)
    return math.log(unpack(t))
end

function Def._max_(t)
    return math.max(unpack(t))
end

function Def._min_(t)
    return math.min(unpack(t))
end

function Def._modf_(t)
    return math.modf(t[1])
end

function Def._rad_(t)
    return math.rad(t[1])
end

function Def._round_(t)
    local after = t[2] or 2
    return t[1]-t[1]%(1/10^after)
end

function Def._randomseed_(t)
    math.randomseed(t[1] or os.time())
end

function Def._random_(t)
    return math.random(unpack(t))
end

function Def._sin_(t)
    return math.sin(t[1])
end

function Def._sqrt_(t)
    return math.sqrt(t[1])
end

function Def._tan_(t)
    return math.tan(t[1])
end

function Def._ult_(t)
    return math.ult(t[1], t[2])
end

-- condition

function Def._eq_(t)
    if t[1] == t[2] then return true else return false end
end

function Def._neq_(t)
    if t[1] ~= t[2] then return true else return false end
end

function Def._ge_(t)
    if t[1] > t[2] then return true else return false end
end

function Def._gte_(t)
    if t[1] >= t[2] then return true else return false end
end

function Def._le_(t)
    if t[1] < t[2] then return true else return false end
end

function Def._lte_(t)
    if t[1] <= t[2] then return true else return false end
end

function Def._and_(t)
    local res = t[1]
    for i=2, #t do res = res and t[i] end
    return res
end

function Def._or_(t)
    local res = t[1]
    for i=2, #t do res = res or t[i] end
    return res
end

function Def._not_(t)
    return not t[1]
end

function Def._if_(t, predef, scope)
    local cond, expr = t[1]:match(RE.defif)

    if Lusp.eval(cond, predef, scope) then
        return Lusp.eval(expr:match(RE.islusp), predef, scope)
    else
        return Lusp.eval(
            expr:gsub(RE.islusp, '', 1):match(RE.islusp), predef, scope
        )
    end
end


-- for

function Def._for_(t, predef, scope)
    local cond, expr = t[1]:match(RE.deffunc)

    local name, iter = cond:match(RE.defvar)

    Error.checkVariable(name)
    Error.checkDefinition(name, t[1], 'for')

    local callfunc = Lusp.getDefinition(expr, predef, scope)

    local funcname = RE.tokenize('function')
    if not callfunc then
        local deffunc = '(def (function '..name..') '.. expr .. ')'
        Lusp.eval(deffunc, predef, scope)
        callfunc = scope[funcname]
    end

    local itername = RE.tokenize('iterable')
    Lusp.eval('(def iterable '..iter..')', predef, scope)

    for k,v in pairs(scope[itername]) do
        local _, result
        if scope[itername].isdict then
            _, result = pcall(callfunc, {k})
        else
            _, result = pcall(callfunc, {v})
        end
        if result and result == '_break_' then break end
    end
    scope[itername] = nil
    scope[funcname] = nil
end

function Def._break_()
    error('_break_')
end

function Def._continue_()
    error('_continue_')
end

-- list

function Def._range_(t)
    local res = {}
    local last = t[2] or t[1]
    local first = t[2] and t[1] or 1
    local step = t[3] or 1

    for i=first, last, step do
        res[#res+1]=i
    end
    return res
end

function Def._list_(t)
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
    return res
end

function Def._first_(t)
    return t[1][1]
end

function Def._last_(t)
    return t[1][#t[1]]
end

function Def._push_(t)
    t[2][#t[2]+1] = t[1]
    return t[2]
end

function Def._pop_(t)
    t[1][#t[1]] = nil
    return t[1]
end

function Def._sort_(t)
    if t[2] then
        table.sort(t[1], function(a,b) return a>b end)
    else
        table.sort(t[1])
    end
    return t[1]
end

function Def._flip_(t)
    local res = {}
    for i=#t[1], 1, -1 do
        res[#res+1] = t[1][i]
    end
    return res
end

function Def._concat_(t)
    local res = ''
    for i=1, #t[1] do
        res = res .. t[1][i] .. (t[2] and t[2] or '')
    end
    return (t[2] and res:sub(1, #res-1)) or res
end

-- dict&list

function Def._dict_(t)
    local res = {}
    for i=1, #t do
        res[t[i][1]] = t[i][2]
    end
    setmetatable(res, {__index={isdict=true}})
    return res
end

function Def._keys_(t)
    local res = {}
    for k,_ in pairs(t[1]) do
        res[#res+1] = k
    end
    return res
end

function Def._values_(t)
    local res = {}
    for _,v in pairs(t[1]) do
        res[#res+1] = v
    end
    return res
end

function Def._map_(t)
    local res = {}
    for k,v in pairs(t[2]) do
        res[k]=t[1]({v})
    end
    return res
end

function Def._filter_(t)
    local res = {}
    for k,v in pairs(t[2]) do
        if t[1]({v}) then
            res[k]=v
        end
    end
    return res
end

function Def._unpack_(t)
    return unpack(t[1], t[2] or 1, t[3] or #t[1])
end

function Def._pack_(t)
    return table.pack(unpack(t))
end

-- dict&list&string

function Def._get_(t)
    if type(t[2]) == 'string' then
        return t[2]:sub(t[1],t[1])
    elseif type(t[2]) == 'table' then
        local res = t[2][t[1]]
        if res == nil then
            Error.undefined('key', t[1])
        end
        return res
    end
end

function Def._has_(t)
    if type(t[2]) == 'string' then
        return t[2]:find(t[1]) and true or false
    elseif type(t[2]) == 'table' then
        for _,v in pairs(t[2]) do
            if v == t[1] then
                return true
            end
        end
    end
end

function Def._set_(t)
    if type(t[3]) == 'string' then
        return t[3]:gsub(t[1],t[2])
    elseif type(t[3]) == 'table' then
        t[3][t[1]] = t[2]
        return t[3]
    end
end

function Def._del_(t)
    if type(t[2]) == 'string' then
        return t[2]:gsub(t[1],'')
    elseif type(t[2]) == 'table' and t[2].isdict then
        t[2][t[1]] = nil
        return t[2]
    elseif type(t[2]) == 'table' then
        table.remove(t[2], t[1])
        return t[2]
    end
end

function Def._merge_(t)
    if type(t[1]) == 'string' then
        local res = ''
        for i=1, #t do
            res = res .. t[i]
        end
        return res
    elseif type(t[1]) == 'table' then
        local res = {}

        for i=1, #t do
            for k,v in pairs(t[i]) do
                res[k] = v
            end
        end
        return res
    end
end

function Def._insert_(t)
    if type(t[3]) == 'string' then
        return t[3]:sub(1, t[1]-1)..t[2]..t[3]:sub(t[1])
    elseif type(t[3]) == 'table' and t[3].isdict then
        t[3][t[1]] = t[2]
        return t[3]
    elseif type(t[3]) == 'table' then
        table.insert(t[3], t[1], t[2])
        return t[3]
    end
end


-- string

function Def._upper_(t)
    return string.upper(t[1])
end

function Def._lower_(t)
    return string.lower(t[1])
end

function Def._capitalize_(t)
    return string.gsub(t[1], '^.', string.upper)
end

function Def._title_(t)
    local res = ''
    for word in t[1]:gmatch('%g+') do
        res = res .. string.gsub(word, '^.', string.upper) .. ' '
    end
    return res:sub(1, #res-1)
end

function Def._repeat_(t)
    return t[2]:rep(t[1])
end

function Def._replace_(t)
    return string.gsub(t[3], t[1], t[2])
end

function Def._match_(t)
    return string.match(t[3], t[1], t[2])
end

function Def._reverse_(t)
    return t[1]:reverse()
end

function Def._trim_(t)
    local trim = RE.trimspace
    if t[2] then
        trim = '^'..t[2]..'*(.-)'..t[2]..'*$'
    end
    return t[1]:gsub(trim, '%1')
end

function Def._format_(t)
    return string.format(unpack(t))
end

function Def._byte_(t)
    return {string.byte(unpack(t))}
end

function Def._char_(t)
    return Def._list_({string.char(unpack(t))})
end


-- io

function Def._readfile_(t)
    local file = io.open(t[1], 'r')
    if not file then Error.undefined('file', t[1]) end
    local res = file:read('*a')
    file:close()
    return res
end

function Def._readlines_(t)
    local file = io.open(t[1], 'r')
    if not file then Error.undefined('file', t[1]) end
    local res = {}
    for line in file:lines() do res[#res+1] = line end
    return res
end

function Def._writefile_(t)
    local file = io.open(t[2], 'w')
    if not file then Error.undefined('file', t[2]) end
    file:write(t[1])
    file:close()
end

function Def._readbin_(t)
    local file = io.open(t[1], 'rb')
    if not file then Error.undefined('file', t[1]) end
    local res = file:read('*a')
    file:close()
    return res
end

function Def._writebin_(t)
    local file = io.open(t[2], 'wb')
    if not file then Error.undefined('file', t[2]) end
    file:write(t[1])
    file:close()
end

function Def._input()
    return io.read()
end


-- os

function Def._clock_()
    return os.clock()
end

function Def._date_(t)
    return os.date(unpack(t))
end

function Def._time_(t)
    return os.time(t[1])
end

function Def._difftime_(t)
    return os.difftime(unpack(t))
end

function Def._execute_(t)
    return os.execute(t[1])
end

function Def._remove_(t)
    return os.remove(t[1])
end

function Def._rename_(t)
    return os.rename(t[1], t[2])
end

function Def._tmpname_()
    return os.tmpname()
end

function Def._getenv_(t)
    local res = os.getenv(t[1])
    if res == nil then
        Error.undefined('environment', t[1])
    end
    return res
end

function Def._setlocale_(t)
    local res = os.setlocale(t[1])
    if res == nil then
        Error.undefined('locale', t[1])
    end
    return res
end

function Def._exit_(t)
    return os.exit(t[1])
end

-- bits
function Def._band_(t)
    local res = t[1]
    for i=2, #t do res = res & t[i] end
    return res
end

function Def._bor_(t)
    local res = t[1]
    for i=2, #t do res = res | t[i] end
    return res
end

function Def._bxor_(t)
    if #t==1 then
        return ~t[1]
    end
    local res = t[1]
    for i=2, #t do res = res ~ t[i] end
    return res
end

function Def._lshift_(t)
    local res = t[1]
    for i=2, #t do res = res << t[i] end
    return res
end

function Def._rshift_(t)
    local res = t[1]
    for i=2, #t do res = res >> t[i] end
    return res
end

-- output

local function printer(value)
    if type(value) == 'table' then
        io.write('[ ')
        for k,v in pairs(value) do
            io.write(' ')
            printer(k)
            io.write(': ')
            printer(v)
            io.write(' ')
        end
        io.write('] ')
    else
        io.write(tostring(value), ' ')
    end
end

function Def._show_(t)
    for i=1, #t do
        printer(t[i])
    end
    io.write('\n')
end

-- sugar
Def[RE.tokenize('ARGS')] = arg
Def[RE.tokenize('VERSION')] = settings.VERSION .. ' ('.. _VERSION .. ')'
Def[RE.tokenize('#')] = Def._len_
Def[RE.tokenize('?')] = Def._type_
Def[RE.tokenize('+')] = Def._add_
Def[RE.tokenize('-')] = Def._sub_
Def[RE.tokenize('*')] = Def._mul_
Def[RE.tokenize('/')] = Def._div_
Def[RE.tokenize('//')] = Def._fdiv_
Def[RE.tokenize('PI')] = math.pi
Def[RE.tokenize('HUGE')] = math.huge
Def[RE.tokenize('MAXINT')] = math.maxinteger
Def[RE.tokenize('MININT')] = math.mininteger
Def[RE.tokenize('==')] = Def._eq_
Def[RE.tokenize('!=')] = Def._neq_
Def[RE.tokenize('>')] = Def._ge_
Def[RE.tokenize('>=')] = Def._gte_
Def[RE.tokenize('<')] = Def._le_
Def[RE.tokenize('<=')] = Def._lte_
Def[RE.tokenize('&&')] = Def._and_
Def[RE.tokenize('||')] = Def._or_
Def[RE.tokenize('!')] = Def._not_
Def[RE.tokenize('true')] = true
Def[RE.tokenize('false')] = false
Def[RE.tokenize('->')] = Def._return_
Def[RE.tokenize('..')] = Def._merge_
-- bits
Def[RE.tokenize('&')] = Def._band_
Def[RE.tokenize('|')] = Def._bor_
Def[RE.tokenize('~')] = Def._bxor_
Def[RE.tokenize('<<')] = Def._lshift_
Def[RE.tokenize('>>')] = Def._rshift_


return Def
