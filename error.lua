-- DEF
-- error.lua

local RE = require('re')
local Tests = require('tests')

local Error = {}


function Error.error(message, scope)
    local err = Error.getError(message, scope)

    if Tests.isdebug then
        Tests.savederror = err
    else
        io.write(err..'\n')
        os.exit(0)
    end
end

function Error.getError(message, scope)
    -- print(message)
    local space = (scope[RE.tokendefined] or 'root')
    return (
    'Error: '..message:gsub('[%g%s]+: ','')..' | '.. space
    )
end

function Error.undefined(tag, inp)
    error(tag..' undefined | '.. inp)
end

function Error.notexpression(inp)
    error('wrong expression '.. inp)
end

function Error.unableDefine(action, definition)
    error('unable to define | ('..action..' '..definition..')')
end

function Error.wrongCharInFirstAction(inp, char)
    error('wrong char in first action '..inp..' | '.. char)
end

function Error.wrongCharInput(inp)
    error('wrong char in input '..inp)
end

function Error.wrongChar(inp, char)
    error('wrong char in '..inp..' | '.. char)
end

function Error.wrongType(action, type, param)
    error('wrong type for '..action..' | '..type..' | '.. param)
end

function Error.checkDefinition(inp, action, definition)
    if not inp:match(RE.defname) then
        Error.unableDefine(action, definition)
    end
end

function Error.checkVariable(inp)
    if string.find(inp, RE.token) then
        Error.wrongChar(inp, RE.token)
    end

    if string.find(inp, '-') then
        Error.wrongChar(inp, '-')
    end
end

function Error.checkBraces(args)
    local _, lbr = args:gsub('%(', '')
    local _, rbr = args:gsub('%)', '')

    local _, lqbr = args:gsub('%[', '')
    local _, rqbr = args:gsub('%]', '')


    if lbr ~= rbr then
        error('unpaired braces | ()')
    end

    if lqbr ~= rqbr then
        error('unpaired braces | []')
    end
end

function Error.checkQuotes(args)
    local _, dquotes = args:gsub('"', '')
    local _, squotes = args:gsub("'", '')

    if dquotes > 0 and dquotes % 2 ~= 0 then
        error('unpaired quotes | "')
    end
    if squotes > 0 and squotes % 2 ~= 0 then
        error("unpaired quotes | '")
    end
end

return Error
