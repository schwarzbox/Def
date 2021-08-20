-- LUSP
-- tests.lua

local settings = require('settings')
local RE = require('re')

local unpack = table.unpack or unpack
local utf8 = require('utf8')

local Tests = {
    isdebug = false,
    tmpfile="lusp.txt", tmpbin="lusp.bin", tmpexpr="expr.lusp"
}

Tests.tests = {
    -- clear
    {'( # ( get 1  "lusp" ) )', 1, 'clear'},
    {'(? "lusp"))', 'error'},
    {'(? "lusp)', 'error'},
    {"(? lusp')", 'error'},
    {'(-> "[2 4))', 'error'},

    --comment
    {'(def var1 (+ 42 42)) ; (def var2 (+ 2 2))\n (# (scope))', 1, 'comment'},
    {'(def file "'.. Tests.tmpexpr.. '") (writefile "; (-> \'comment\')\n" file) (do file)', nil},
    {'(def file "'.. Tests.tmpexpr.. '") (writefile "(-> \'comment\')" file) (do file)', 'comment'},
    -- lusp&token
    {'(? (first (keys (lusp))))', 'string'},
    {'(def merge (+ 0 42)) (-> merge)', 42},
    -- {'(has "'..RE.token..'v" (first (keys (lusp))))', false},
    -- {'(.. "'..RE.token..'~" "42")','~42'},
    -- basic
    {'(-> VERSION)', settings.VERSION .. ' ('.. _VERSION .. ')', 'basic'},
    {'(len [1 2 3])', 3},
    {'(# (range 1 8))', 8},
    {'(# (dict ["?" 2] ["Lusp" 4]))', 2},
    {'(# "Lusp")', 4},
    {'(# "\'Lusp\' \'Lusp\'")', 13},
    {'(# "2")', 1},
    {'(# " ")', 1},
    {'(type 1)', 'number'},
    {'(? "Lusp")', 'string'},
    {'(? "Lusp \'world\'")', 'string'},
    {'(? (last ["def" "lusp" "merge"]))', 'string'},
    {'(? add)', 'function'},
    {'(? #f)', 'boolean'},
    {'(? [])', 'table'},
    {'(? (dict ["?" 2] ["Lusp" 4]))', 'table'},
    {'(? "show")', 'string'},
    {'(? (first [def merge]))','function'},
    {'(? (last [def merge]))','function'},
    {'(assert (== 2 2) "Assertion Error")', true},
    {'def (fake) (error "error")) (def (emp) (-> #f)) (fake) (emp)', 'error'},
    {'(num "2")', 2},
    {'(str 2)', "2"},
    {'(return "")', ''},
    {'(-> 3)', 3},
    {'(-> (-> (* 2 2 2)))', 8},
    {'(-> #t)', true},
    {'(-> #f)', false},
    {'(-> 2 "Lusp" 42)', 2},
    {'(eval "(+ 2 2 2)")', 6},
    {'(eval "(-> \'comment\')")', 'comment'},
    {'(eval "(merge "Lusp" "Lusp")")', "LuspLusp"},
    {'(eval "(def ct "") (for (var ["42" "L"]) (mut ct (.. ct var))) (-> ct)")', "42L"},
    {'(eval "(def (var) (-> "Lusp"))") (var)', "Lusp"},
    {'(eval "(def var (-> "Lusp"))") (-> var)', "Lusp"},

    {'(def f "'.. Tests.tmpexpr.. '") (writefile "(+ 2 2)" f) (do f)', 4},
    {'(def f "'.. Tests.tmpexpr.. '") (writefile "(def (module) (-> \'Lusp\'))" f) (do f) (module)', "Lusp"},
    {'(call add 2 2)', 4},
    {'(def x 2) (def y 2) (call sub x y)', 0},
    {'(call add "Lusp" 128)', false},
    {'(? (last (pack (call add "Lusp" var))))', 'string'},
    {'(show (call add "Lusp" 128)) (-> "lusp")', "lusp"},
    {'(show (call add "Lusp" var)) (-> "lusp")', "lusp"},


    -- math
    {'(add -2 -2 -4)', -8, 'math'},
    {'(+ 2 2 2 2)', 8},
    {'(sub 2 2 2 2)', -4},
    {'(- 2 2)', 0},
    {'(mul 2 2 4)', 16},
    {'(* 2 2)', 4},
    {'(div 2 0)', 1/0},
    {'(/ 2 4)', 0.5},
    {'(fdiv 4 3)', 1},
    {'(// 8 3)', 2},
    {'(modulo 3 4)', 3},
    {'(pow 2 10)', 1024},
    {'(pow 2 0.5)', math.pow(2, 0.5)},
    {'(+ (/ (+ 2 (- 2 (* 2 (pow 2 2)))) 4) 1)', 0},
    {'(abs -1)', 1},
    {'(acos -1)', math.acos(-1)},
    {'(asin -1)', math.asin(-1)},
    {'(atan -1)', math.atan(-1)},
    {'(ceil PI)', math.ceil(math.pi)},
    {'(cos -1)', math.cos(-1)},
    {'(deg -1)', math.deg(-1)},
    {'(exp 1)', math.exp(1)},
    {'(-> HUGE)', math.huge},
    {'(floor PI)', math.floor(math.pi)},
    {'(first (fmod PI 4))', math.pi},
    {'(log 2 7)', math.log(2, 7)},
    {'(max 20 3 5 6)', 20},
    {'(min 20 3 5 6)', 3},
    {'(first (modf PI))', 3},
    {'(-> MAXINT)', math.maxinteger},
    {'(-> MININT)', math.mininteger},
    {'(-> PI)', math.pi},
    {'(rad 45)', math.rad(45)},
    {'(round 3.1416 2)', 3.14},
    {'(randomseed 2) (random 0 42)', 34},
    {'(pow 2 0.5)', math.pow(2, 0.5)},
    {'(sin -1)', math.sin(-1)},
    {'(sqrt 1)', math.sqrt(1)},
    {'(sqrt 128)', math.sqrt(128)},
    {'(tan -1)', math.tan(-1)},
    {'(ult 42 128)', math.ult(42, 128)},

    -- condition
    {'(== 2 2)', true, 'condition'},
    {'(== 1 0)', false},
    {'(!= 2 2)', false},
    {'(!= 3.14 3.1416)', true},
    {'(!= 2 2)', false},
    {'(!= 2 2)', false},
    {'(> 2 1)', true},
    {'(>= 2 2)', true},
    {'(>= 4 2)', true},
    {'(< 2 1)', false},
    {'(<= 2 2)', true},
    {'(<= 4 2)', false},
    {'(and 2 #t)', true},
    {'(&& 2 #f)', false},
    {'(or #t 2)', true},
    {'(|| #f 4)', 4},
    {'(! #f)', true},
    {'(! (> 2 4))', true},
    {'(if (== 4 4) (def x 1) (def y 0)) (-> x)', 1},
    {'(if (!= (? 4 ) "string") (def x 1)) (-> x)', 1},
    {'(if (has "Lusp" (keys (dict ["Lusp" 42] [2 "42"]))) (-> 1) (-> 0))', 1},

    -- for
    {'(def ct 0) (for (var [2 4]) (mut ct (+ var 1))) (-> ct)', 5, 'for'},
    {'(def ct 0) (for (var (range 2 4)) (mut ct (+ var 1))) (-> ct)', 5},
    {'(def ct 0) (for (var (range 2 8)) ((if (== var 5) (break) (mut ct var)))) (-> ct)', 4},
    {'(def ct 0) (for (var (range 2 8)) ((if (== var 5) ((continue) (mut ct var))))) (-> ct)', 0},
    {'(def ct 0) (def tab (dict ["?" 4])) (for (var tab) (mut ct (get var tab))) (-> ct)', 4},

    -- list
    {'(last (range 2 8))', 8, 'list'},
    {'(last (list "Lusp"))', 'p'},
    {'(last (list "lusp lusp" " "))',  'lusp'},
    {'(first [2 4 8 16 "Lusp"])', 2},
    {'(last [2 4 8 16 "Lusp"])', "Lusp"},
    {'(? (last ["2"]))', 'string'},
    {'(? (last [["L" [4] 2] [4 [4 [16 16] "U" 8]] 2 1]))', 'number'},
    {'(? (last [42 [2 2] 32 [1 1]]))', 'table'},
    {'(first (push 1 []))', 1},
    {'(first (push "Lusp" []))', "Lusp"},
    {'(last (pop ["42" "Lusp"]))', "42"},
    {'(first (sort [32 2 4 16 8]))', 2},
    {'(first (sort [32 2 4 16 8] #t))', 32},
    {'(first (flip [32 2 4 16 8]))', 8},
    {'(concat ["L" "U" "S" "P"])', 'LUSP'},
    {'(concat ["L" "U" "S" "P"] "|")', 'L|U|S|P'},
    {'(unpack [0 42])', 0},
    {'(def var1 var2 var3 (unpack [2 4 8])) (-> var2)', 4},
    {'(last (pack 0 42))', 42},

    -- dict
    {'(def tab (dict ["?" "Lusp"] [1 2])) (# (del 1 tab))', 1, 'dict'},
    {'(def tab (dict ["?" "Lusp"])) (has "Hi" (set "?" "Hi" tab))', true},
    {'(def tab (dict ["?" "Lusp"])) (def var tab) (get "?" var)', 'Lusp'},
    {'(last (keys [32 2 4 16 8]))', 5},
    {'(last (values [32 2 4 16 8]))', 8},
    {'(has "Lusp" (keys (dict ["Lusp" 42] [2 "42"])))', true},
    {'(has "42" (values (dict ["Lusp" 42] [2 "42"])))', true},
    {'(first (map ? [2 3.14 4 "Lusp" 16 #t]))', 'number'},
    {'(last (map round [2 3.1416]))', 3.14},
    {'(def (func var) (-> (== var 16))) (# (filter func [2 4 4 16]))', 1},
    {'(get "42" (map type (dict ["42" "Lusp"])))', 'string'},

    -- list&dict&string
    {'(get 2 "Lusp")', 'u', 'list&dict&string'},
    {'(get 2 ["42" "Lusp"])', 'Lusp'},
    {'(get 1 "Lusp")', 'L'},
    {'(get 4 "Lusp")', 'p'},
    {'(def tab (dict ["?" 42] ["2" "32"])) (get "2" tab)', '32'},
    {'(has "42" ["42" "Lusp"])',true},
    {'(has "Lusp" (dict ["42" "Lusp"]))',true},
    {'(has "s" "Lusp")', true},
    {'(has "z" "Lusp")', false},
    {'(has "i" (set "u" "i" "Lusp"))', true},
    {'(def var (set "p" "42" "Lusp")) (get (# var) var)', '2'},
    {'(def lst ["42" "Lusp"]) (first (set 1 0 lst))', 0},
    {'(def tab (dict ["42" "Lusp"])) (has "0" (set "42" "0" tab))', true},
    {'(get 1 (del 1 [2 4]))', 4},
    {'(get 1 (del "L" "Lusp"))', 'u'},
    {'(get "Lusp" (del "?" (dict ["?" 4] ["Lusp" 42])))', 42},
    {'(last (merge ["?" 42] ["Lusp" "32"]))', "32"},
    {'(.. "? " "Lusp")', '? Lusp'},
    {'(get "?" (.. (dict ["?" "42"]) (dict ["Lusp" "Lusp"])))', '42'},
    {'(get 2 (insert 2 "8" ["42" "Lusp"]))', '8'},
    {'(get 1 (insert 1 "Lusp" (dict ["2" "42"])))', 'Lusp'},
    {'(insert 5 "42" "Lusp")', "Lusp42"},

    -- string
    {'(upper "lusp")', "LUSP"},
    {'(lower "LUSP")', "lusp"},
    {'(capitalize "lusp 42 world")', 'Lusp 42 world'},
    {'(title "lusp-42 lusp.lusp")', 'Lusp-42 Lusp.lusp'},
    {'(repeat 4 "Lusp")', 'LuspLuspLuspLusp'},
    {'(replace "u" "i" "lusp" )', 'lisp'},
    {'(match "42" 1 "Lusp42")', '42'},
    {'(match "%d+" 1 "Lusp42")', '42'},
    {'(match "2" 5 "Lusp42")', '2'},
    {'(reverse "LUSP")', "PSUL"},
    {'(trim "  \nLUSP \t")', "LUSP"},
    {'(trim "||LUSP||" "||")', "LUSP"},
    {'(format "%s | %s" "Lusp" "?")', "Lusp | ?"},
    {'(format "%q" "Lusp")', "\"Lusp\""},
    {'(format "%c%c%c" 65 66 67)', "ABC"},
    {'(format "%.1f" 42.42)', "42.4"},
    {'(# (byte "⌘" 1 (# "⌘")))', 3},
    {'(first (byte "Lusp" 1 -1))', 76},
    {'(first (char 65 66 67))', 'A'},
    {'(unpack (char 65 66 67) 1 1)', 'A'},
    {'(insert (unpack [5 "42" "Lusp"]))', "Lusp42"},

    -- input
    {'(# ARGS)', 2, 'input'},
    {'(def f "'.. Tests.tmpfile.. '") (writefile "Lusp" f) (readfile f)', 'Lusp'},
    {'(first (readlines "tests.lua"))', '-- LUSP'},
    {'(def f "'.. Tests.tmpbin.. '") (writebin "Lusp" f) (readbin f)', 'Lusp'},
    -- {'(def var (input )) (show var)', 'Lusp'},

    -- os
    {'(> 1 (clock))', true, 'os'},
    {'(date "%d.%m.%Y")', os.date("%d.%m.%Y")},
    {'(date "%x %X" (time (date "*t" 10800)))', os.date("%x %X", os.time(os.date('*t', 10800)))},

    {'(get "hour" (date "*t"))', os.date('*t').hour},
    {'(time (dict ["year" 1983] ["month" 7] ["day" 19]))',
        os.time({year=1983, month=7, day=19})},
    {'(def var (time (dict ["year" 1983] ["month" 7] ["day" 19]))) (difftime  (time) var)', os.difftime(os.time(), os.time({year=1983,month=7,day=19}))},
    {'(execute)', true},
    {'(execute "mkdir lusp") (remove "lusp")', true},
    {'(execute "mkdir lusp") (rename "lusp" "lu") (remove "lu")', true},
    {'(? (tmpname))', 'string'},
    {'(getenv "USER")', os.getenv('USER')},
    {'(getenv "HOME")', os.getenv('HOME')},
    {'(setlocale)', os.setlocale()},
    {'(setlocale "fr_FR") (num 3.14)',
        os.setlocale('fr_FR'); tonumber(3.14); os.setlocale('C')
    },
    -- {'(exit #t) (exit 0)', true},

    --definition
    {'(def var42 "2") (# var42)', 1, 'definition'},
    {'(def (func x) (-> (- 2 x))) (func 2)', 0},
    {'(def lst [2 4 8 16 #t]) (type lst)', 'table'},
    {'(def (func) (== 2 2)) (def Func (if (-> func) (-> #t) (-> #f))) (-> Func)', true},
    {'(def (func x) (-> (+ 1 x))) (def (same) (mut (func y) (-> (+ 2 y))) (func 1)) (-> (same))', 3},
    {'(def (func x) (-> (+ 1 x))) (def (same) (def (func y) (-> (+ 2 y))) (func 1)) (-> (same))', 3},
    {'(def (func x) (-> (+ 1 x))) (def (diff) (def (func y) (-> (+ 2 y))) (func 1)) (-> (func 1))', 2},
    {'(def var "lusp") (-> var)', 'lusp'},
    {'(def x 8) (def y 8) (-> (+ x y))', 16},
    {'(def x (+ 8 8)) (def y 8) (-> (+ x y))', 24},
    {'(def (func x y) (-> x y)) (def v1 v2 (func 1 2)) (-> v2)', 2},
    {'(def func (+ 8 8)) (-> (? func))', 'number'},
    {'(def (func v1 v2) (-> (add v1 v2))) (func 2 2)', 4},
    {'(def (func var) (-> var)) (+ (func 2) (func 4))', 6},
    {'(def (func x y) ((-> x) (-> y))) (func 1 2)', 1},
    {'(def (func v1 v2) ((def v1 (+ v1 1)) (-> #t) (add v1 v2))) (func 2 2)', true},
    {'(def (func v1 v2) ((def v1 (+ v1 1)) (add v1 v2))) (func 2 2)', 5},
    -- integration
    {'(def (func v1) ((def v2 1) (-> (+ v1 v2)))) (-> (func 1))', 2, 'integration'},
    {'(def same 1) (for (var [1]) (mut same (+ same var))) (def (func same) (show same) (-> same)) (-> (func "lusp"))', 'lusp'},
    {'(def (func var) (-> (round var 1))) (def y (func 3.14)) (-> y)', 3.1},
    {'(def (func x y) ((def x (+ 1 x)) (def y (+ 2 y)) (-> [x y]))) (last (func 2 2))', 4},
    {'(def (fact var) (if (== var 1) (-> var) (-> (* var (fact (- var 1)))))) (-> (fact 6))', 720},

    -- error
    {'(# [undef merge])', 'error', 'error'},
    {'(# #)', 'error'},
    {'(def 42var 42)', 'error'},
    {'(def (func) ((def x 2))) (func) (-> x)', 'error'},
    {'(def (fake) (def x 2)) (func)', 'error'},
    {'(-> var)', 'error'},
    {'(if (== 4 4) (def x 1) (def y 0)) (->  y)', 'error'},
    {'(def (~func) (-> #t))', 'error'},
    {'(if (== 4 4) (def ~x 1)) (-> ~x)','error'},
    {'(for (~var [2 4]) (-> ~var))', 'error'},
    {'(eval "(def ~var (-> "Lusp"))") (-> ~var)', 'error'},
    {'(def var #n) (if (-> var) (-> #t) (-> #f))', 'error'},
    {'(get "42" (del "42" (dict ["42" "lusp"])))', 'error'},
    {'(get 2 (del 1 [2 4]))', 'error'},
    {'(readfile "nofile")', 'error'},
    {'(setlocale "all")', 'error'},
}

function Tests.execute(Lusp, Def, tests)
    local result = Lusp.eval(tests[1], Def, {})

    local test = (
        (
            Tests.savederror and tostring(Tests.savederror):find('Error:')
            and assert('error' == tests[2], 'Fail')
        )
        or assert(result == tests[2], 'Fail')
        )
        and 'Pass'
    Tests.savederror = nil
    return test
end

function Tests.run(Lusp, Def)
    Tests.isdebug = true

    io.write('--Lusp Tests--\n')
    for id, tests in pairs(Tests.tests) do
        if #tests==3 then
            io.write('--Group ', tests[3],'\n')
        end
        io.write('--Test ', id,'\n', tests[1])

        io.write('\n--', Tests.execute(Lusp, Def, tests), '\n\n')
    end
    os.remove(Tests.tmpfile)
    os.remove(Tests.tmpbin)
    os.remove(Tests.tmpexpr)

    io.write('\n--Total ',#Tests.tests)
    io.write('\n--Done--\n')
end

return Tests
