-- DEF
-- re.lua

local salt = os.time() // 128
local swapchar = 't'
local swapkey = os.time() + salt
local token = '_'
local lazy = '@'

local RE = {
    shellbag = '%#%!%s*.-%f[\n]',
    comment = ';%s*.-%f[\n]',
    splitspace = '[^ ]+',

    trimspace = '^%s*(.-)%s*$',
    trimbracket = '^%s?%((.-)%)%s?$',
    trimdef = '^%((.-)%)$',
    trimlist = '^%[(.-)%]$',
    trimlazy = '^'..lazy..'%[(.-)%]$',

    isdef = '%b()',
    islist = '%b[]',
    islazy = lazy..'%b[]',
    islazydef = lazy..'(%b())',
    dquote = '%b""',
    squote = "%b''",
    dbraces = '%(%(',

    unquote = '^[\"\'](.-)[\"\']$',

    defall = '^%(%s*(.-)%s+([%g%s]+)%)$',
    deffunc = '^%(%s*(.-)%s*%)%s+(.*)$',
    defcond = '^(%b())%s+(%(.*%))$',
    defswitch = '(%b())%s+(%b())',
    defexpr = '^(.-)%s+(%(.*%))$',
    defvar = '^(%g+)%s*(.*)',
    defname = '^([%a][%w]*)',
    excluded = '[`~!@#$%%^&*%(%)-_+=%{%}%[%]|\\"\'?/;:<>,%.]',

    lazy = lazy,
    token = token,
    tokenvar = '^'..token..salt..token..'(.+)'..token..salt..token..'$',
    swapchar = swapchar,
    swapkey = swapkey,
    swapdef = '('..swapchar..'%d+'..swapchar..')',
    swapvar = token..salt..token..'('..swapchar..'%d+'..swapchar..')'..token..salt..token,

    specials = {},
}
function RE.tokenize(str)
    return RE.token..salt..RE.token..str..RE.token..salt..RE.token
end

RE.tokenscope = RE.tokenize('scope')
RE.tokendefined = RE.tokenize('defined')
RE.tokentrue = RE.tokenize('true')
RE.tokenfalse = RE.tokenize('false')
RE.tokenbreak = RE.tokenize('break')
RE.tokencontinue = RE.tokenize('continue')
RE.tokenreturn = RE.tokenize('return')

RE.tokendef = RE.tokenize('def')
RE.tokenmut = RE.tokenize('mut')
RE.tokenlambda = RE.tokenize('lambda')
RE.tokenL = RE.tokenize('L')
RE.tokenif = RE.tokenize('if')
RE.tokenswitch = RE.tokenize('switch')
RE.tokenwhile = RE.tokenize('while')
RE.tokenfor = RE.tokenize('for')
RE.tokeneval = RE.tokenize('eval')
RE.tokentry = RE.tokenize('try')

RE.specials[RE.tokendef] = RE.tokendef
RE.specials[RE.tokenmut] = RE.tokenmut
RE.specials[RE.tokenlambda] = RE.tokenlambda
RE.specials[RE.tokenL] = RE.tokenL
RE.specials[RE.tokenif] = RE.tokenif
RE.specials[RE.tokenswitch] = RE.tokenswitch
RE.specials[RE.tokenwhile] = RE.tokenwhile
RE.specials[RE.tokenfor] = RE.tokenfor
RE.specials[RE.tokeneval] = RE.tokeneval
RE.specials[RE.tokentry] = RE.tokentry

RE.tokenshow = RE.tokenize('show')

return RE
