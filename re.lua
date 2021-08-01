-- LUSP
-- re.lua

local RE = {
    trimspace = '^%s*(.-)%s*$',
    trimbracket = '^%((%(.-%))%)$',
    splitspace = '[^ ]+',
    islusp = '%b()',
    islist = '%b[]',
    squote = '[\"](.-)[\"]',
    dquote = '[\'](.-)[\']',
    string = '^[\"\'](.-)[\"\']$',
    trimlist = '^%[(.-)%]$',
    trimlusp = '^%((.-)%)$',
    deffunc = '^%(%s*(.-)%s*%)%s+(%(.-%))$',
    defif = '^(%(%s*.-%s*%))%s+(%(.-%))$',
    defexpr = '^([%_%w]+)%s+(%(.-%))$',
    defvar = '^([%_%w]+)%s*([%g%s]*)',
    defall = '^%(%s*(.-)%s+([%g%s]+)%)$',
    comment = ';.-\n',
    var = '^__.-'
}

return RE
