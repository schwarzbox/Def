-- LUSP
-- re.lua

local token = '_'

local RE = {
    comment = ';.-\n',
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
    defvar = '^(%g+)%s*(.*)',
    defname = '^(['..token..'%a%-]['..token..'%w%-]*)',

    token = token,
    tokenvar = '^'..token..'.+'..token..'$',
    specials = {}

}
function RE.tokenize(str)
    return RE.token..str..RE.token
end

RE.tokentrue = RE.tokenize('true')
RE.tokenfalse = RE.tokenize('false')

RE.specials[RE.tokenize('def')] = RE.tokenize('def')
RE.specials[RE.tokenize('mut')] = RE.tokenize('mut')
RE.specials[RE.tokenize('if')] = RE.tokenize('if')
RE.specials[RE.tokenize('for')] = RE.tokenize('for')
RE.specials[RE.tokenize('eval')] = RE.tokenize('eval')
RE.specials[RE.tokenize('call')] = RE.tokenize('call')

return RE
