-- LUSP
-- re.lua

local token = '~'
local RE = {
    splitspace = '[^ ]+',

    trimspace = '^%s*(.-)%s*$',
    trimbracket = '^%((%(.-%))%)$',
    trimlist = '^%[(.-)%]$',
    trimlusp = '^%((.-)%)$',

    islusp = '%b()',
    islist = '%b[]',
    dquote = '[\"](.-)[\"]',
    squote = '[\'](.-)[\']',
    string = '^[\"\'](.-)[\"\']$',

    defall = '^%(%s*(.-)%s+([%g%s]+)%)$',
    deffunc = '^%(%s*(.-)%s*%)%s*(%(.-%))$',
    defif = '^(%(%s*.-%s*%))%s*(%(.-%))$',
    defexpr = '^(.-)%s*(%(.-%))$',
    defvar = '^(['..token..'%a][%w]*)%s*(.*)',

    token = token,
    var = '^'..token..'.-',
    comment = ';.-\n',
}

return RE
