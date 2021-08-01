-- LUSP
-- def.lua

local settings = require('settings')

local unpack = table.unpack or unpack
local utf8 = require('utf8')


local Lusp = require('lusp')
local RE = require('re')

local Def = {}

-- definition

function Def.__lusp(_, predef, _)
    local res = {}
    for k,v in pairs(predef) do
        res[k:gsub('_', '',2)] = v
    end
    return res
end

function Def.__scope(_, _, scope)

    local res = {}
    for k,v in pairs(scope) do
        -- if type(v) == 'table' then
        --     res[k:gsub('_', '', 2)] = Def.__scope(_, _, scope)
        -- end
        res[k:gsub('_', '', 2)] = v
    end
    return res
end

function Def.__def(t, predef, scope, mutate)
    -- print(t[1])
    local fdef, fbody = t[1]:match(RE.deffunc)
    local edef, ebody = t[1]:match(RE.defexpr)
    local vdef, vbody = t[1]:match(RE.defvar)

    -- print('f',fdef, fbody)
    -- print('e',edef, ebody)
    -- print('d', vdef, vbody)
    if fdef then
        local name, args = fdef:match(RE.defvar)

        local param = Lusp.splitArgs(args)

        local function func(...)
            local argf = ...
            local upvalue = {}
            for i=1, #param do
                upvalue[param[i]] = argf[i]
            end
            for k,v in pairs(scope) do
                upvalue[k] = v
            end
            upvalue['__scope__'] = scope
            return Lusp.eval(fbody, predef, upvalue)
        end
        if mutate then
            if scope['__scope__'] and scope['__scope__']['__'..name] then
                scope['__scope__']['__'..name] = func
            else
                scope['__'..name] = func
            end
        else
            scope['__'..name] = func
        end

    elseif edef then
        if mutate then
            if scope['__scope__'] and scope['__scope__']['__'..edef] then
                scope['__scope__']['__'..edef] = Lusp.eval(ebody, predef, scope)
            else
                scope['__'..edef] = Lusp.eval(ebody, predef, scope)
            end
        else
            scope['__'..edef] = Lusp.eval(ebody, predef, scope)
        end
    else
        if mutate then
            if scope['__scope__'] and scope['__scope__']['__'..vdef] then
                scope['__scope__']['__'..vdef] = (
                    scope['__'..vbody] or Lusp.splitArgs(vbody)[1]
                )
            else
                scope['__'..vdef] = (
                    scope['__'..vbody] or Lusp.splitArgs(vbody)[1]
                )
            end
        else
            scope['__'..vdef] = (
                scope['__'..vbody] or Lusp.splitArgs(vbody)[1]
            )
        end
    end
end

function Def.__mut(t, predef, scope)
    Def.__def(t, predef, scope, true)
end

-- basic

function Def.__len(t)
    if type(t[1]) == 'string' then
        return #t[1]
    elseif type(t[1]) == 'table' then
        local res = 0
        for _,_ in pairs(t[1]) do
            res=res+1
        end
        return res
    end
end

function Def.__type(t)
    return type(t[1])
end

function Def.__assert(t)
    return assert(t[1], t[2])
end

function Def.__error(t)
    return error(t[1], t[2] and t[2]+1 or 5)
end

function Def.__num(t)
    return tonumber(t[1])
end

function Def.__str(t)
    return tostring(t[1])
end

function Def.__return(t)
    return unpack(t)
end

function Def.__eval(t, predef, scope)
    local expr = t[1]:gsub(RE.string, '%1')
    return Lusp.eval(expr, predef, scope)
end

function Def.__do(t, predef, scope)
    local file = io.open(t[1], 'r')
    local expr = file:read('*a')
    file:close()
    return Lusp.eval(expr, predef, scope)
end

function Def.__call(t)
    local res, err = pcall(t[1], {unpack(t, 2, #t)})
    if err then
        return err
    end
    return res
end


-- math

function Def.__add(t)
    print(#t)
    local res = t[1]
    for i=2, #t do res = res + t[i] end
    return res
end

function Def.__sub(t)
    local res = t[1]
    for i=2, #t do res = res - t[i] end
    return res
end

function Def.__mul(t)
    local res = t[1]
    for i=2, #t do res = res * t[i] end
    return res
end

function Def.__div(t)
    local res = t[1]
    for i=2, #t do res = res / t[i] end
    return res
end

function Def.__fdiv(t)
    local res = t[1]
    for i=2, #t do res = res // t[i] end
    return res
end

function Def.__modulo(t)
    local res = t[1]
    for i=2, #t do res = res % t[i] end
    return res
end

function Def.__pow(t)
    local res = t[1]
    for i=2, #t do res = res ^ (t[i]) end
    return res
end

function Def.__abs(t)
    return math.abs(t[1])
end

function Def.__acos(t)
    return math.acos(t[1])
end

function Def.__asin(t)
    return math.asin(t[1])
end

function Def.__atan(t)
    return math.atan(t[1])
end

function Def.__ceil(t)
    return math.ceil(t[1])
end

function Def.__cos(t)
    return math.cos(t[1])
end

function Def.__deg(t)
    return math.deg(t[1])
end

function Def.__exp(t)
    return math.exp(t[1])
end

function Def.__floor(t)
    return math.floor(t[1])
end

function Def.__log(t)
    return math.log(unpack(t))
end

function Def.__max(t)
    return math.max(unpack(t))
end

function Def.__min(t)
    return math.min(unpack(t))
end

function Def.__rad(t)
    return math.rad(t[1])
end

function Def.__round(t)
    local after = t[2] or 2
    return t[1]-t[1]%(1/10^after)
end

function Def.__randomseed(t)
    math.randomseed(t[1] or os.time())
end

function Def.__random(t)
    return math.random(unpack(t))
end

function Def.__sin(t)
    return math.sin(t[1])
end

function Def.__sqrt(t)
    return math.sqrt(t[1])
end

function Def.__tan(t)
    return math.tan(t[1])
end

-- condition

function Def.__eq(t)
    if t[1] == t[2] then return true else return false end
end

function Def.__neq(t)
    if t[1] ~= t[2] then return true else return false end
end

function Def.__ge(t)
    if t[1] > t[2] then return true else return false end
end

function Def.__gte(t)
    if t[1] >= t[2] then return true else return false end
end

function Def.__le(t)
    if t[1] < t[2] then return true else return false end
end

function Def.__lte(t)
    if t[1] <= t[2] then return true else return false end
end

function Def.__and(t)
    local res = t[1]
    for i=2, #t do res = res and t[i] end
    return res
end

function Def.__or(t)
    local res = t[1]
    for i=2, #t do res = res or t[i] end
    return res
end

function Def.__not(t)
    return not t[1]
end

function Def.__if(t, predef, scope)
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

function Def.__for(t, predef, scope)
    local cond, expr = t[1]:match(RE.deffunc)

    local var, iter = cond:match(RE.defvar)

    local callfunc = Lusp.checkScope(expr, predef, scope)

    if not callfunc then
        local deffunc = '(def (function__ '..var..') '.. expr .. ')'
        Lusp.eval(deffunc, predef, scope)
        callfunc = scope['__function__']
    end

    Lusp.eval('(def iterable__ '..iter..')', predef, scope)

    for k,v in pairs(scope['__iterable__']) do
        local result, err
        if scope['__iterable__'].dict then
            result, err = pcall(callfunc, {k})
        else
            result, err = pcall(callfunc, {v})
        end
        if not result and err:find('__break__') then break end
    end
    scope['__iterable__'] = nil
    scope['__function__'] = nil
end

function Def.__break()
    error('__break__')
end

function Def.__continue()
    error('__continue__')
end

-- list

function Def.__range(t)
    local res = {}
    local last = t[2] or t[1]
    local first = t[2] and t[1] or 1
    local step = t[3] or 1

    for i=first, last, step do
        res[#res+1]=i
    end
    return res
end

function Def.__list(t)
    local res = {}
    for i=1, #t[1] do
        res[i] = t[1]:sub(i, i)
    end
    return res
end

function Def.__first(t)
    return t[1][1]
end

function Def.__last(t)
    return t[1][#t[1]]
end

function Def.__push(t)
    t[2][#t[2]+1] = t[1]
    return t[2]
end

function Def.__pop(t)
    t[1][#t[1]] = nil
    return t[1]
end

function Def.__sort(t)
    if t[2] then
        table.sort(t[1], function(a,b) return a>b end)
    else
        table.sort(t[1])
    end
    return t[1]
end

function Def.__flip(t)
    local res = {}
    for i=#t[1], 1, -1 do
        res[#res+1] = t[1][i]
    end
    return res
end

function Def.__concat(t)
    local res = ''
    for i=1, #t[1] do
        res = res .. t[1][i] .. (t[2] and t[2] or '')
    end
    return (t[2] and res:sub(1, #res-1)) or res
end

-- dict&list

function Def.__dict(t)
    local res = {}
    for i=1, #t do
        res[t[i][1]] = t[i][2]
    end
    setmetatable(res, {__index={dict=true}})
    return res
end

function Def.__keys(t)
    local res = {}
    for k,_ in pairs(t[1]) do
        res[#res+1] = k
    end
    return res
end

function Def.__values(t)
    local res = {}
    for _,v in pairs(t[1]) do
        res[#res+1] = v
    end
    return res
end

function Def.__map(t)
    local res = {}
    for k,v in pairs(t[2]) do
        res[k]=t[1]({v})
    end
    return res
end

function Def.__filter(t)
    local res = {}
    for k,v in pairs(t[2]) do
        if t[1]({v}) then
            res[k]=v
        end
    end
    return res
end

function Def.__unpack(t)
    return table.unpack(t[1], t[2] or 1, t[3] or #t[1])
end

function Def.__pack(t)
    return table.pack(unpack(t))
end

-- dict&list&string

function Def.__get(t)
    if type(t[2]) == 'string' then
        return t[2]:sub(t[1],t[1])
    elseif type(t[2]) == 'table' then
        return t[2][t[1]]
    end
end

function Def.__has(t)
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

function Def.__set(t)
    if type(t[3]) == 'string' then
        return t[3]:gsub(t[1],t[2])
    elseif type(t[3]) == 'table' then
        t[3][t[1]] = t[2]
        return t[3]
    end
end

function Def.__del(t)
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

function Def.__merge(t)
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

function Def.__insert(t)
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

function Def.__upper(t)
    return string.upper(t[1])
end

function Def.__lower(t)
    return string.lower(t[1])
end

function Def.__capitalize(t)
    return string.gsub(t[1], '^.', string.upper)
end

function Def.__title(t)
    local res = ''
    for word in t[1]:gmatch('%g+') do
        res = res .. string.gsub(word, '^.', string.upper) .. ' '
    end
    return res:sub(1, #res-1)
end

function Def.__repeat(t)
    return t[2]:rep(t[1])
end

function Def.__replace(t)
    return string.gsub(t[3], t[1], t[2])
end

function Def.__match(t)
    return string.match(t[3], t[1], t[2])
end

function Def.__reverse(t)
    return t[1]:reverse()
end

function Def.__trim(t)
    local trim = RE.trimspace
    if t[2] then
        trim = '^'..t[2]..'*(.-)'..t[2]..'*$'
    end
    return t[1]:gsub(trim, '%1')
end

function Def.__format(t)
    return string.format(unpack(t))
end

function Def.__byte(t)
    return {string.byte(unpack(t))}
end

function Def.__char(t)
    return Def.__list({string.char(unpack(t))})
end


-- io

function Def.__arg()
    return arg
end

function Def.__readfile(t)
    local file = io.open(t[1], 'r')
    if not file then return nil end
    local res = file:read('*a')
    file:close()
    return res
end

function Def.__readlines(t)
    local file = io.open(t[1], 'r')
    if not file then return nil end
    local res = {}
    for line in file:lines() do res[#res+1] = line end
    return res
end

function Def.__writefile(t)
    local file = io.open(t[2], 'w')
    if not file then return nil end
    file:write(t[1])
    file:close()
end

function Def.__readbin(t)
    local file = io.open(t[1], 'rb')
    if not file then return nil end
    local res = file:read('*a')
    file:close()
    return res
end

function Def.__writebin(t)
    local file = io.open(t[2], 'wb')
    if not file then return nil end
    file:write(t[1])
    file:close()
end

function Def.__input()
    return io.read()
end


-- os

function Def.__clock()
    return os.clock()
end

function Def.__date(t)
    return os.date(unpack(t))
end

function Def.__time(t)
    return os.time(t[1])
end

function Def.__difftime(t)
    return os.difftime(unpack(t))
end

function Def.__execute(t)
    return os.execute(t[1])
end

function Def.__remove(t)
    return os.remove(t[1])
end

function Def.__rename(t)
    return os.rename(t[1], t[2])
end

function Def.__tmpname()
    return os.tmpname()
end

function Def.__getenv(t)
    return os.getenv(t[1])
end

function Def.__setlocale(t)
    return os.setlocale(t[1])
end

function Def.__exit(t)
    return os.exit(t[1])
end

-- output

local function printer(value)
    if type(value) == 'table' then
        io.write('[ ')
        for k,v in pairs(value) do
            io.write('[ ')
            printer(k)
            io.write(': ')
            printer(v)
            io.write('] ')
        end
        io.write('] ')
    else
        io.write(tostring(value), ' ')
    end
end

function Def.__show(t)
    io.write('>')
    for i=1, #t do
        printer(t[i])
    end
    io.write('\n')
end

-- sugar

Def['__VERSION'] = settings.VERSION
Def['__#'] = Def.__len
Def['__?'] = Def.__type
Def['__->'] = Def.__return
Def['__+'] = Def.__add
Def['__-'] = Def.__sub
Def['__*'] = Def.__mul
Def['__/'] = Def.__div
Def['__//'] = Def.__fdiv
Def['__PI'] = math.pi
Def['__HUGE'] = math.huge
Def['__MAXINT'] = math.maxinteger
Def['__MININT'] = math.mininteger
Def['__=='] = Def.__eq
Def['__!='] = Def.__neq
Def['__>'] = Def.__ge
Def['__>='] = Def.__gte
Def['__<'] = Def.__le
Def['__<='] = Def.__lte
Def['__&&'] = Def.__and
Def['__||'] = Def.__or
Def['__!'] = Def.__not
Def['__if'] = Def.__if
Def['__#t'] = true
Def['__#f'] = false
Def['__#n'] = nil
Def['__..'] = Def.__merge

return Def
