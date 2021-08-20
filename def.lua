-- LUSP
-- def.lua

local settings = require('settings')

local unpack = table.unpack or unpack
local utf8 = require('utf8')


local Lusp = require('lusp')
local RE = require('re')

local Def = {}
local Local = {}

-- definition

function Local._lusp(_, predef, _)
    local res = {}
    for k,v in pairs(predef) do
        res[k:gsub('^'..RE.token, '', 1)] = v
    end
    return res
end


function Local._scope(_, _, scope)
    local res = {}
    for k,v in pairs(scope) do
        if k == 'scope' then
            res[k] = Local._scope(_,_, v)
        else
            res[k:gsub('^'..RE.token, '', 1)] = v
        end
    end
    return res
end

function Local._def(t, predef, scope, mutate)
    local fdef, fbody = t[1]:match(RE.deffunc)
    local edef, ebody = t[1]:match(RE.defexpr)
    local vdef, vbody = t[1]:match(RE.defvar)

    -- print('f',fdef, fbody)
    -- print('e',edef, ebody)
    -- print('d', vdef, vbody)

    if fdef then
        local name, args = fdef:match(RE.defvar)
        if string.find(name, RE.token) then
            error('wrong literal '.. RE.token)
        end
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
            upvalue['scope'] = scope
            upvalue['name'] = name
            return Lusp.eval(fbody, predef, upvalue)
        end
        scope[RE.token..name] = func
        if mutate then
            if scope['scope'] and scope['scope'][RE.token..name] then
                scope['scope'][RE.token..name] = func
            end
        end

    elseif edef then
        -- if string.find(edef, RE.token) then
        --     error('wrong literal '.. RE.token)
        -- end
        local vars = Lusp.splitArgs(edef)
        local res = {Lusp.eval(ebody, predef, scope)}
        for i=1, #vars do
            local name = vars[i]:match(RE.defvar)
            scope[name] = res[i]
            if mutate then
                if scope['scope'] and scope['scope'][name] then
                    scope['scope'][name] = res[i]
                end
            end
        end

    elseif vdef then
        if string.find(vdef, RE.token) then
            error('wrong literal '.. RE.token)
        end

        local res = (
            scope[RE.token..vbody]
            or Lusp.eval('(-> '..vbody..')', predef, scope)
        )
        scope[RE.token..vdef] = res
        if mutate then
            if scope['scope'] and scope['scope'][RE.token..vdef] then
                scope['scope'][RE.token..vdef] = res
            end
        end
    else
        if mutate then
            error('unable to define (mut '.. t[1]..')')
        end
        error('unable to define (def '.. t[1]..')')
    end
end

function Local._mut(t, predef, scope)
    Local._def(t, predef, scope, true)
end

-- basic

function Local._len(t)
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

function Local._type(t)
    return type(t[1])
end

function Local._assert(t)
    if t[2] then
        assert(t[1], t[2])
    else
        assert(t[1])
    end
    return true
end

function Local._error(t)
    error(t[1])
end

function Local._num(t)
    return tonumber(t[1])
end

function Local._str(t)
    return tostring(t[1])
end

function Local._return(t)
    return unpack(t)
end

function Local._eval(t, predef, scope)
    local expr = t[1]:gsub(RE.string, '%1')
    return Lusp.eval(expr, predef, scope)
end

function Local._do(t, predef, scope)
    local file = io.open(t[1], 'r')
    local expr = file:read('*a')
    file:close()
    return Lusp.eval(expr, predef, scope)
end

function Local._call(t, predef, scope)
    return Lusp.eval('('..t[1]..')', predef, scope, true)
end


-- math

function Local._add(t)
    local res = t[1]
    for i=2, #t do res = res + t[i] end
    return res
end

function Local._sub(t)
    local res = t[1]
    for i=2, #t do res = res - t[i] end
    return res
end

function Local._mul(t)
    local res = t[1]
    for i=2, #t do res = res * t[i] end
    return res
end

function Local._div(t)
    local res = t[1]
    for i=2, #t do res = res / t[i] end
    return res
end

function Local._fdiv(t)
    local res = t[1]
    for i=2, #t do res = res // t[i] end
    return res
end

function Local._modulo(t)
    local res = t[1]
    for i=2, #t do res = res % t[i] end
    return res
end

function Local._pow(t)
    local res = t[1]
    for i=2, #t do res = res ^ (t[i]) end
    return res
end

function Local._abs(t)
    return math.abs(t[1])
end

function Local._acos(t)
    return math.acos(t[1])
end

function Local._asin(t)
    return math.asin(t[1])
end

function Local._atan(t)
    return math.atan(t[1])
end

function Local._ceil(t)
    return math.ceil(t[1])
end

function Local._cos(t)
    return math.cos(t[1])
end

function Local._deg(t)
    return math.deg(t[1])
end

function Local._exp(t)
    return math.exp(t[1])
end

function Local._floor(t)
    return math.floor(t[1])
end

function Local._fmod(t)
    return {math.fmod(t[1], t[2])}
end

function Local._log(t)
    return math.log(unpack(t))
end

function Local._max(t)
    return math.max(unpack(t))
end

function Local._min(t)
    return math.min(unpack(t))
end

function Local._modf(t)
    return {math.modf(t[1])}
end

function Local._rad(t)
    return math.rad(t[1])
end

function Local._round(t)
    local after = t[2] or 2
    return t[1]-t[1]%(1/10^after)
end

function Local._randomseed(t)
    math.randomseed(t[1] or os.time())
end

function Local._random(t)
    return math.random(unpack(t))
end

function Local._sin(t)
    return math.sin(t[1])
end

function Local._sqrt(t)
    return math.sqrt(t[1])
end

function Local._tan(t)
    return math.tan(t[1])
end

function Local._ult(t)
    return math.ult(t[1], t[2])
end

-- condition

function Local._eq(t)
    if t[1] == t[2] then return true else return false end
end

function Local._neq(t)
    if t[1] ~= t[2] then return true else return false end
end

function Local._ge(t)
    if t[1] > t[2] then return true else return false end
end

function Local._gte(t)
    if t[1] >= t[2] then return true else return false end
end

function Local._le(t)
    if t[1] < t[2] then return true else return false end
end

function Local._lte(t)
    if t[1] <= t[2] then return true else return false end
end

function Local._and(t)
    local res = t[1]
    for i=2, #t do res = res and t[i] end
    return res
end

function Local._or(t)
    local res = t[1]
    for i=2, #t do res = res or t[i] end
    return res
end

function Local._not(t)
    return not t[1]
end

function Local._if(t, predef, scope)
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

function Local._for(t, predef, scope)
    local cond, expr = t[1]:match(RE.deffunc)

    local var, iter = cond:match(RE.defvar)
    if string.find(var, RE.token) then
        error('wrong literal '.. RE.token)
    end
    local callfunc = Lusp.checkScope(expr, predef, scope)

    local funcname = RE.token..'function'
    if not callfunc then
        local deffunc = '(def (function '..var..') '.. expr .. ')'
        Lusp.eval(deffunc, predef, scope)
        callfunc = scope[funcname]
    end

    local itername = RE.token..'iterable'
    Lusp.eval('(def iterable '..iter..')', predef, scope)

    for k,v in pairs(scope[itername]) do
        local _, result
        if scope[itername].dict then
            _, result = pcall(callfunc, {k})
        else
            _, result = pcall(callfunc, {v})
        end
        if result and result == 'break' then break end
    end
    scope[itername] = nil
    scope[funcname] = nil
end

function Local._break()
    error('break')
end

function Local._continue()
    error('continue')
end

-- list

function Local._range(t)
    local res = {}
    local last = t[2] or t[1]
    local first = t[2] and t[1] or 1
    local step = t[3] or 1

    for i=first, last, step do
        res[#res+1]=i
    end
    return res
end

function Local._list(t)
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

function Local._first(t)
    return t[1][1]
end

function Local._last(t)
    return t[1][#t[1]]
end

function Local._push(t)
    t[2][#t[2]+1] = t[1]
    return t[2]
end

function Local._pop(t)
    t[1][#t[1]] = nil
    return t[1]
end

function Local._sort(t)
    if t[2] then
        table.sort(t[1], function(a,b) return a>b end)
    else
        table.sort(t[1])
    end
    return t[1]
end

function Local._flip(t)
    local res = {}
    for i=#t[1], 1, -1 do
        res[#res+1] = t[1][i]
    end
    return res
end

function Local._concat(t)
    local res = ''
    for i=1, #t[1] do
        res = res .. t[1][i] .. (t[2] and t[2] or '')
    end
    return (t[2] and res:sub(1, #res-1)) or res
end

-- dict&list

function Local._dict(t)
    local res = {}
    for i=1, #t do
        res[t[i][1]] = t[i][2]
    end
    setmetatable(res, {__index={dict=true}})
    return res
end

function Local._keys(t)
    local res = {}
    for k,_ in pairs(t[1]) do
        res[#res+1] = k
    end
    return res
end

function Local._values(t)
    local res = {}
    for _,v in pairs(t[1]) do
        res[#res+1] = v
    end
    return res
end

function Local._map(t)
    local res = {}
    for k,v in pairs(t[2]) do
        res[k]=t[1]({v})
    end
    return res
end

function Local._filter(t, _, scope)
    local res = {}
    for k,v in pairs(t[2]) do
        if t[1]({v}) then
            res[k]=v
        end
    end
    return res
end

function Local._unpack(t)
    return unpack(t[1], t[2] or 1, t[3] or #t[1])
end

function Local._pack(t)
    return table.pack(unpack(t))
end

-- dict&list&string

function Local._get(t)
    if type(t[2]) == 'string' then
        return t[2]:sub(t[1],t[1])
    elseif type(t[2]) == 'table' then
        local res = t[2][t[1]]
        if res == nil then
            error('key undefined')
        end
        return res
    end
end

function Local._has(t)
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

function Local._set(t)
    if type(t[3]) == 'string' then
        return t[3]:gsub(t[1],t[2])
    elseif type(t[3]) == 'table' then
        t[3][t[1]] = t[2]
        return t[3]
    end
end

function Local._del(t)
    if type(t[2]) == 'string' then
        return t[2]:gsub(t[1],'')
    elseif type(t[2]) == 'table' and t[2].dict then
        t[2][t[1]] = nil
        return t[2]
    elseif type(t[2]) == 'table' then
        table.remove(t[2], t[1])
        return t[2]
    end
end

function Local._merge(t)
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

function Local._insert(t)
    if type(t[3]) == 'string' then
        return t[3]:sub(1, t[1]-1)..t[2]..t[3]:sub(t[1])
    elseif type(t[3]) == 'table' and t[3].dict then
        t[3][t[1]] = t[2]
        return t[3]
    elseif type(t[3]) == 'table' then
        table.insert(t[3], t[1], t[2])
        return t[3]
    end
end


-- string

function Local._upper(t)
    return string.upper(t[1])
end

function Local._lower(t)
    return string.lower(t[1])
end

function Local._capitalize(t)
    return string.gsub(t[1], '^.', string.upper)
end

function Local._title(t)
    local res = ''
    for word in t[1]:gmatch('%g+') do
        res = res .. string.gsub(word, '^.', string.upper) .. ' '
    end
    return res:sub(1, #res-1)
end

function Local._repeat(t)
    return t[2]:rep(t[1])
end

function Local._replace(t)
    return string.gsub(t[3], t[1], t[2])
end

function Local._match(t)
    return string.match(t[3], t[1], t[2])
end

function Local._reverse(t)
    return t[1]:reverse()
end

function Local._trim(t)
    local trim = RE.trimspace
    if t[2] then
        trim = '^'..t[2]..'*(.-)'..t[2]..'*$'
    end
    return t[1]:gsub(trim, '%1')
end

function Local._format(t)
    return string.format(unpack(t))
end

function Local._byte(t)
    return {string.byte(unpack(t))}
end

function Local._char(t)
    return Local._list({string.char(unpack(t))})
end


-- io

function Local._readfile(t)
    local file = io.open(t[1], 'r')
    if not file then error('file undefined') end
    local res = file:read('*a')
    file:close()
    return res
end

function Local._readlines(t)
    local file = io.open(t[1], 'r')
    if not file then error('file undefined') end
    local res = {}
    for line in file:lines() do res[#res+1] = line end
    return res
end

function Local._writefile(t)
    local file = io.open(t[2], 'w')
    if not file then error('file undefined') end
    file:write(t[1])
    file:close()
end

function Local._readbin(t)
    local file = io.open(t[1], 'rb')
    if not file then error('file undefined') end
    local res = file:read('*a')
    file:close()
    return res
end

function Local._writebin(t)
    local file = io.open(t[2], 'wb')
    if not file then error('file undefined') end
    file:write(t[1])
    file:close()
end

function Local._input()
    return io.read()
end


-- os

function Local._clock()
    return os.clock()
end

function Local._date(t)
    return os.date(unpack(t))
end

function Local._time(t)
    return os.time(t[1])
end

function Local._difftime(t)
    return os.difftime(unpack(t))
end

function Local._execute(t)
    return os.execute(t[1])
end

function Local._remove(t)
    return os.remove(t[1])
end

function Local._rename(t)
    return os.rename(t[1], t[2])
end

function Local._tmpname()
    return os.tmpname()
end

function Local._getenv(t)
    local res = os.getenv(t[1])
    if res == nil then
        error('environment undefined')
    end
    return res
end

function Local._setlocale(t)
    local res = os.setlocale(t[1])
    if res == nil then
        error('locale undefined')
    end
    return res
end

function Local._exit(t)
    return os.exit(t[1])
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

function Local._show(t)
    for i=1, #t do
        printer(t[i])
    end
    io.write('\n')
end

-- sugar
Def[RE.token..'ARGS'] = arg
Def[RE.token..'VERSION'] = settings.VERSION .. ' ('.. _VERSION .. ')'
Def[RE.token..'#'] = Local._len
Def[RE.token..'?'] = Local._type
Def[RE.token..'+'] = Local._add
Def[RE.token..'-'] = Local._sub
Def[RE.token..'*'] = Local._mul
Def[RE.token..'/'] = Local._div
Def[RE.token..'//'] = Local._fdiv
Def[RE.token..'PI'] = math.pi
Def[RE.token..'HUGE'] = math.huge
Def[RE.token..'MAXINT'] = math.maxinteger
Def[RE.token..'MININT'] = math.mininteger
Def[RE.token..'=='] = Local._eq
Def[RE.token..'!='] = Local._neq
Def[RE.token..'>'] = Local._ge
Def[RE.token..'>='] = Local._gte
Def[RE.token..'<'] = Local._le
Def[RE.token..'<='] = Local._lte
Def[RE.token..'&&'] = Local._and
Def[RE.token..'||'] = Local._or
Def[RE.token..'!'] = Local._not
Def[RE.token..'#t'] = true
Def[RE.token..'#f'] = false



for k,v in pairs(Local) do
    local name = RE.token..k:gsub('_','')
    -- print(Def[name], name)
    if not Def[name] then
        -- print(name)
        Def[name]=v
    end
end

Def[RE.token..'->'] = Local._return
Def[RE.token..'..'] = Local._merge

return Def
