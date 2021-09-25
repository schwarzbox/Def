-- DEF
-- re.lua

local token = '_'
local swapchar = 's'

local RE = {
    shellbag = '%#%!%s*.-%f[\n]',
    comment = ';%s*.-%f[\n]',
    splitspace = '[^ ]+',

    trimspace = '^%s*(.-)%s*$',
    trimbracket = '^%s?%((.-)%)%s?$',
    trimdef = '^%((.-)%)$',
    trimlist = '^%[(.-)%]$',
    trimcode = '^%{(.-)%}$',

    isdef = '%b()',
    islist = '%b[]',
    iscode = '%b{}',
    dquote = '%b""',
    squote = "%b''",

    unquote = '^[\"\'](.-)[\"\']$',

    defall = '^%(%s*(.-)%s+([%g%s]+)%)$',
    deffunc = '^%(%s*(.-)%s*%)%s+(%(.-%))$',
    defif = '^(%(%s*.-%s*%))%s+(%(.-%))$',
    defexpr = '^(.-)%s+(%(.-%))$',
    defvar = '^(%g+)%s*(.*)',
    defname = '^(['..token..'%a]['..token..'%w]*)',

    token = token,
    swapchar = swapchar,
    tokenvar = '^'..token..'.+'..token..'$',
    swapvar = '_?('..swapchar..'%d+'..swapchar..')_?',
    specials = {},
    returns = {}

}
function RE.tokenize(str)
    return RE.token..str..RE.token
end

RE.tokenscope = RE.tokenize('scope')
RE.tokendefined = RE.tokenize('defined')
RE.tokentrue = RE.tokenize('true')
RE.tokenfalse = RE.tokenize('false')
RE.tokenbreak = RE.tokenize('break')
RE.tokencontinue = RE.tokenize('continue')
RE.tokeniffunc = RE.tokenize('iffunc')
RE.tokenforfunc = RE.tokenize('forfunc')
RE.tokenforiter = RE.tokenize('foriter')

RE.specials[RE.tokenize('def')] = RE.tokenize('def')
RE.specials[RE.tokenize('mut')] = RE.tokenize('mut')
RE.specials[RE.tokenize('if')] = RE.tokenize('if')
RE.specials[RE.tokenize('for')] = RE.tokenize('for')
RE.specials[RE.tokenize('eval')] = RE.tokenize('eval')
RE.specials[RE.tokenize('call')] = RE.tokenize('call')

RE.tokenreturn = RE.tokenize('->')
RE.returns[RE.tokenreturn] = RE.tokenreturn
RE.returns[RE.tokenize('return')] = RE.tokenize('return')

return RE
