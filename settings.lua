-- DEF
-- settings.lua

local Settings = {
    VERSION = 'Def 1.0',
    EXIT = 'Ctrl+C to Exit',
    HELP = 'usage: \n\tdef\n\tdef [options]\n\tdef [expression]\n\tdef [path]\noptions:\n\t-help -h\thelp\n\t-version -v\tshow version',
    PROMPT = '> ',
}
Settings.HELP = Settings.HELP .. '\n\t-test -t\trun tests'

return Settings
