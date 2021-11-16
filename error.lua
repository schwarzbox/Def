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
    local path = 'root'
    if scope[RE.tokendefined] then
        path = 'root'..RE.errsep.. scope[RE.tokendefined]
    end

    return (
        'Error: '..message:gsub('[%g%s]-: ','', 1)..' | '.. path
    )
end

function Error.undefined(tag, inp)
    error(tag..' undefined | '.. inp)
end

function Error.unableDefine(action, definition)
    if action then
        error('unable to define | ('..action..' '..definition..')')
    else
        error('unable to define | '..definition)
    end
end

function Error.wrongCharInput(inp)
    error('wrong char in input '..inp)
end

function Error.wrongChar(inp, char)
    error('wrong char in '..inp..' | '.. char)
end

function Error.wrongAction(inp)
    error('wrong action '.. inp)
end

function Error.wrongLazy(inp)
    error('wrong lazy '.. inp)
end

function Error.wrongType(action, arg, expected)
    error(
        'bad argument #'..arg..' to \''..action..'\' expected | '.. expected
    )
end

function Error.wrongNumberArgs(action, expected)
    error('wrong number of args to \''..action..'\' expected | '..expected)
end

function Error.wrongKey(action, arg)
    error('bad argument #'..arg..' to \''..action..'\' (position out of bounds)')
end

function Error.wrongDefault(action, expected)
    error('wrong default condition to \''..action..'\' expected | '.. expected)
end

function Error.wrongScope(action, expected)
    error('wrong scope to \''..action..'\' expected | '.. expected)
end

function Error.unpairedQuotes(char)
    error('unpaired quotes | '.. char)
end

function Error.checkFile(inp, action)
    if io.type(inp) == 'closed file' then
        Error.wrongType(action, 1, 'open file')
    end
    if io.type(inp) ~= 'file' then
        Error.wrongType(action, 1, 'file')
    end
end

function Error.checkDefinition(inp, action, definition)
    if not inp:match(RE.defname) then
        Error.unableDefine(action, definition)
    end

    local match = string.match(inp, RE.excluded)
    if match then
        Error.wrongChar(inp, match)
    end
end

function Error.checkExpression(inp, action, definition)
    if #inp:gsub(RE.trimdef, '%1') == 0 then
         Error.unableDefine(action, definition)
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

return Error
