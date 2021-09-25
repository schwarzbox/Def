-- Def
-- tests.lua

local unpack = table.unpack or unpack

local settings = require('settings')

local RE = require('re')

local Tests = {
    isdebug = false,
    savederror = false,
    tmpfile="tmpfile.txt",
    tmpbin="tmpbin",
    tmpexpr="tmpexpr.txt"
}

Tests.tests = {
    -- clear
    {'( # ( get "kiss" 1  ) )', 1, 'clear'},
    {'(((+ 2 2 2 2) (+ 2 2 2 2)))', 8},
    {'((-> (.. (((? "kiss"))) ((((? "kiss")))))))', 'stringstring'},
    {'(? "kiss"))', 'error'},
    {'(? "kiss)', 'error'},
    {"(? kiss')", 'error'},
    {'(-> "[2 4))', 'error'},
    {'(-> (# "  kiss  ") (? "     "))', 8, 'string'},
    {'(-> ")(  \' 1 \'  ))(" \') "  2   ")((\')', ")(  ' 1 '  ))(", " ) \"  2   \")(("},
    {'(def var "kiss \'def\'") (-> var)', "kiss 'def'"},
    {'(def var \'kiss "def"\') (-> var)', 'kiss "def"'},
    {'(def var "_2_") (-> var)', "_2_"},
    {'(def var "_show_") (-> var)', "_show_"},

    --comment
    {'(def var1 (+ 42 42)) ; (def var2 (+ 2 2))\n (# (selfdef))', 1, 'comment'},
    {'(def file "'.. Tests.tmpexpr.. '") (writefile "; (-> \'comment\')\n" file) (do file)', nil},
    {'(def file "'.. Tests.tmpexpr.. '") (writefile "(-> \'comment\')\n" file) (do file\n)', 'comment'},

    -- predef&token
    {'(? (first (keys (predef))))', 'string'},
    {'(has (first (keys (predef))) "'..RE.token..'" )', false},
    {'(.. "'..RE.token..'" "42")', RE.token..'42'},

    -- no override
    {'(def show (+ 0 42)) (-> show)', 42},

    -- basic
    {'(-> VERSION)', settings.VERSION .. ' ('.. _VERSION .. ')', 'basic'},
    {'(len [1 2 3])', 3},
    {'(# (range 1 8))', 8},
    {'(# (range 8))', 8},
    {'(# (range 1 8 2))', 4},
    {'(# (dict ["?" 2] ["kiss" 4]))', 2},
    {'(# "kiss")', 4},
    {'(# "\'kiss\' \'kiss\'")', 13},
    {'(# "2")', 1},
    {'(# " ")', 1},
    {'(type 1)', 'number'},
    {'(? "kiss")', 'string'},
    {'(? "kiss \'world\'")', 'string'},
    {'(? (last ["def" "predef" "selfdef"]))', 'string'},
    {'(? add)', 'function'},
    {'(? false)', 'boolean'},
    {'(? [])', 'list'},
    {'(? (dict ["?" 2] ["kiss" 4]))', 'dict'},
    {'(? "show")', 'string'},
    {'(? (first [def selfdef]))','function'},
    {'(? (last [def selfdef]))','function'},
    {'(assert (== 2 2) "Assertion Error")', true},
    {'(assert (!= 2 2) "Assertion Error")', 'error'},
    {'(def (fake) (error "error")) (def (emp) (-> false)) (fake) (emp)', 'error'},
    {'(num "2")', 2},
    {'(str 2)', "2"},
    {'(return "")', ''},
    {'(-> 3)', 3},
    {'(-> (-> (* 2 2 2)))', 8},
    {'(-> true)', true},
    {'(-> false)', false},
    {'(def (func) (def bool false) (-> bool)) (-> (func))', false},
    {'(-> 2 "kiss" 42)', 2, "kiss", 42},
    {'(+ (-> 2 2 2) (-> 2))', 8},
    {'(def (func x) ((# x) (-> "kiss") x)) (func "KISS")', 'kiss'},
    {'(def (func x) ((# x) x)) (func "KISS")', 'KISS'},
    {'(def (func x) ((def x (upper x)) x)) (func "kiss")', "KISS"},
    {'(eval "(+ 2 2 2)")', 6},
    {'(eval "(-> \'comment\')")', 'comment'},
    {'(eval "(join "kiss" "kiss")")', "kisskiss"},
    {'(eval "(def ct "") (for (var ["42" "L"]) (mut ct (.. ct var))) (-> ct)")', "42L"},
    {'(eval "(def (var) (-> "kiss"))") (var)', "kiss"},
    {'(eval \"(def var (-> \"kiss\"))\") (-> var)', "kiss"},

    {'(def f "'.. Tests.tmpexpr.. '") (writefile "(+ 2 2)" f) (do f)', 4},
    {'(def f "'.. Tests.tmpexpr.. '") (writefile "(def (module) (-> \'kiss\'))" f) (do f) (module)', "kiss"},
    {'(call add 2 2)', 4},
    {'(def x 2) (def y 2) (call sub x y)', 0},
    {'(call add "kiss" 128)', false},
    {'(? (last (pack (call add "kiss" var))))', 'string'},
    {'(show (call add "kiss" 128)) (-> "42")', "42"},
    {'(show (call add "kiss" var)) (-> "42")', "42"},
    {'(show (call add "kiss" -var)) (-> "42")', "42"},

    -- bits
    {'(& 1 1)', 1},
    {'(& 2 1)', 0},
    {'(| 2 1)', 3},
    {'(~ 1 0)', 1},
    {'(~ 2 1)', 3},
    {'(<< 1 1)', 2},
    {'(>> 1 1)', 0},
    {'(<< 1 1 1 1 1 1 1 1)', 128},
    {'(<< 1 7)', 128},
    {'(>> 1 -4)', 16},
    {'(<< 1 4)', 16},
    {'(>> 1 4)', 0},
    {'(~ 0)', -1},
    {'(| 0 (pow 2 32))', 4294967296},
    {'(def setup (| 0 (<< 1 0))) (-> (| setup (<< 1 3 )))', 9},
    {'(def setup (| 1 (<< 1 3))) (-> (& setup (<< 1 3 )))', 8},
    {'(def setup (| 1 (<< 1 3))) (-> (& setup (~ (<< 1 3))))', 1},

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
    {'(fmod PI 4)', math.pi},
    {'(log 2 7)', math.log(2, 7)},
    {'(max 20 3 5 6)', 20},
    {'(min 20 3 5 6)', 3},
    {'(modf PI)', 3},
    {'(modf 6.14)',6, 0.14},
    {'(-> MAXINT)', math.maxinteger},
    {'(-> MININT)', math.mininteger},
    {'(-> PI)', math.pi},
    {'(rad 45)', math.rad(45)},
    {'(round 3.1416 2)', 3.14},
    {'(randomseed 2) (random 0 42)', 34},
    {'(-> (randomseed))', true},
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
    {'(and 2 true)', true},
    {'(&& 2 false)', false},
    {'(or true 2)', true},
    {'(|| false 4)', 4},
    {'(! false)', true},
    {'(! (> 2 4))', true},
    {'(def x 0) (if (== x 0) (def x 2) (def x 4)) (-> x)', 0},
    {'(def x y (-> 0 0)) (if (== 4 4) (mut x 1) (mut y 0)) (-> x)', 1},
    {'(def x 0) (if (!= (? 4 ) "string") (def x 1)) (-> x)', 0},
    {'(if (has (keys (dict ["kiss" 42] [2 "42"])) "kiss") (-> 1) (-> 0))', 1},
    {'(if (-> 0) (-> true) (-> false))', true},
    {'(if (-> "") (-> true) (-> false))', true},
    {'(if (-> false) (-> true) (-> false))', false},
    {'(if (->) (-> true) (-> false))', false},

    -- for
    {'(def x 0) (for (var [2 4]) (mut x (+ var 1))) (-> x)', 5, 'for'},
    {'(def x (for (var [2 4]) (+ var 1))) (-> x)', 5},
    {'(def x 0) (for (var (range 2 4)) (mut x (+ var 1))) (-> x)', 5},
    {'(def x (for (var (range 2 8)) (if (== var 4) (-> var) (* var 4)))) (-> x)', 32},
    {'(def x (for (var (range 0 8)) (if (== var 4) (-> var) (mut var (* 2 var))))) (-> x)', 4},

    -- break&continue
    {'(def x 0) (for (var (range 2 4)) ((if (== var 3) (break) (mut x var)))) (-> x)', 2, 'break&continue'},
    {'(def x (for (var (range 2 4)) (if (== var 3) (break) (-> var)))) (-> x)', 2},
    {'(def x 0) (for (var (range 2 8)) ((if (== var 4) ((continue) (mut x var))))) (-> x)', 0},
    {'(def x 0) (for (var (range 2 8)) (if (== var 4) (continue) (mut x var))) (-> x)', 8},
    {'(def x (for (var (range 2 4)) (if (== var 4) (continue) (* var 2)))) (-> x)', 6},


    -- list
    {'(last (range 2 8))', 8, 'list'},
    {'(last (list "kiss"))', 's'},
    {'(last (list "kiss kiss" " "))', 'kiss'},
    {'(first [2 4 8 16 "kiss"])', 2},
    {'(last [2 4 8 16 "kiss"])', "kiss"},
    {'(? (last ["2"]))', 'string'},
    {'(? (last [["L" [4] 2] [4 [4 [16 16] "U" 8]] 2 1]))', 'number'},
    {'(? (last [42 [2 2] 32 [1 1]]))', 'list'},
    {'(first (push [] 1))', 1},
    {'(first (push [] "kiss" ))', "kiss"},
    {'(first (push [] "kiss"))', "kiss"},
    {'(def lst [1 2 3]) (push lst 4) (last lst)', 4},
    {'(def lst [1 2 3]) (def lst (push lst 4)) (last lst)', 4},
    {'(last (pop ["42" "kiss"]))', "42"},
    {'(def lst [1 2 3]) (pop lst) (last lst)', 2},
    {'(def lst [1 2 3]) (mut lst (pop lst)) (last lst)', 2},
    {'(first (sort [32 2 4 16 8]))', 2},
    {'(first (sort [32 2 4 16 8] true))', 32},
    {'(def lst [32 2 4 16 8]) (sort lst) (first lst)', 32},
    {'(def lst [32 2 4 16 8]) (def lst (sort lst)) (first lst)', 2},
    {'(first (flip [32 2 4 16 8]))', 8},
    {'(concat ["L" "U" "S" "P"])', 'LUSP'},
    {'(concat ["K" "I" "S" "S"] "|")', 'K|I|S|S'},
    {'(unpack [0 42])', 0},
    {'(unpack [0 1 2 4 8 16 32] 2 4)', 1, 2, 4, 8},
    {'(def var1 var2 var3 (unpack [2 4 8])) (-> var2)', 4},
    {'(last (pack 0 42))', 42},

    -- dict
    {'(# (dict))', 0, 'dict'},
    {'(def tab (dict ["?" "kiss"] [1 2])) (# (del tab 1))', 1},
    {'(def tab (dict ["?" "kiss"])) (has (set tab "?" "Hi") "Hi")', true},
    {'(def tab (dict ["?" "kiss"])) (def var tab) (get var "?")', 'kiss'},
    {'(last (keys [32 2 4 16 8]))', 5},
    {'(last (values [32 2 4 16 8]))', 8},
    {'(has (keys (dict ["kiss" 42] [2 "42"])) "kiss")', true},
    {'(has (values (dict ["kiss" 42] [2 "42"])) "42")', true},
    {'(first (map [2 3.14 4 "kiss" 16 true] ?))', 'number'},
    {'(last (map [2 3.1416] round))', 3.14},
    {'(def (func var) (-> (== var 16))) (# (filter [2 4 4 16] func))', 1},
    {'(get (map (dict ["42" "kiss"]) type) "42")', 'string'},

    -- list&dict&string
    {'(get "kiss" 2)', 'i', 'list&dict&string'},
    {'(get ["42" "kiss"] 2)', 'kiss'},
    {'(get "kiss" 1)', 'k'},
    {'(get "kiss" 4)', 's'},
    {'(def tab (dict ["?" 42] ["2" "32"])) (get tab "2")', '32'},
    {'(has ["42" "kiss"] "42")',true},
    {'(has (dict ["42" "kiss"]) "kiss")',true},
    {'(has "kiss" "s")', true},
    {'(has "kiss" "z")', false},
    {'(set "kiss" 3 "l")', 'kils'},
    {'(def var (set "kiss" 4 "42")) (get var (# var))', '2'},
    {'(def lst ["42" "kiss"]) (first (set lst 1 0))', 0},
    {'(def tab (dict ["42" "kiss"])) (has (set tab "42" "0") "0")', true},
    {'(get (del [2 4] 1) 1)', 4},
    {'(get (del "kiss" 1) 1)', 'i'},
    {'(def var "kiss") (del var (# var))', "kis"},
    {'(get (del (dict ["?" 4] ["kiss" 42]) "?") "kiss")', 42},
    {'(last (merge ["?" 42] ["kiss" "32"]))', "32"},
    {'(get (merge (dict ["?" 42]) (dict ["kiss" "32"])) "kiss")', "32"},
    {'(# (merge (dict ["?" 42]) (range 4)))', 5},
    {'(# (merge (range 1 8) (range 16 32 4)))', 13},
    {'(? (merge (range 1 8) (range 16 32 4)))', 'dict'},
    {'(get (merge (dict ["?" "42"]) (dict ["kiss" "kiss"])) "?")', '42'},
    {'(get (insert ["42" "kiss"] 2 "8" ) 2)', '8'},
    {'(get (insert (dict ["2" "42"]) 1 "kiss") 1)', 'kiss'},
    {'(insert "kiss" 5 "42")', "kiss42"},

    -- string
    {'(upper "kiss")', "KISS"},
    {'(lower "KISS")', "kiss"},
    {'(capitalize "kiss 42 world")', 'Kiss 42 world'},
    {'(title "kiss-42 kiss.def")', 'Kiss-42 Kiss.def'},
    {'(repeat "kiss" 4)', 'kisskisskisskiss'},
    {'(replace "kiss" "k" "m")', 'miss'},
    {'(replace "kiss" "s" "l")', 'kill'},
    {'(find "kiss42" "42")', 5},
    {'(match "kiss42" "42" 1)', '42'},
    {'(match "kiss42" "%d+" 1)', '42'},
    {'(match "kiss42" "2" 5)', '2'},
    {'(reverse "KISS")', "SSIK"},
    {'(trim "  \nkiss \t")', "kiss"},
    {'(trim "||kiss||" "||")', "kiss"},
    {'(trim "\n\nkiss\n\n\n" "\n")',"kiss"},
    {'(.. "? " "kiss")', '? kiss'},
    {'(join "42" "kiss")', '42kiss'},
    {'(format "%s | %s" "kiss" "?")', "kiss | ?"},
    {'(format "%q" "kiss")', "\"kiss\""},
    {'(format "%c%c%c" 65 66 67)', "ABC"},
    {'(format "%.1f" 42.42)', "42.4"},
    {'(# (byte "⌘" 1 (# "⌘")))', 3},
    {'(first (byte "KISS" 1 -1))', 75},
    {'(first (char 65 66 67))', 'A'},
    {'(unpack (char 65 66 67) 1 1)', 'A'},
    {'(def a b c (unpack (char 65 66 67))) (-> c)', 'C'},
    {'(insert (unpack ["kiss" 5 "42"]))', "kiss42"},

    -- input
    {'(def f "'.. Tests.tmpfile.. '") (writefile "42" f) (readfile f)', '42', 'input'},
    {'(first (readlines "tests.lua"))', '-- Def'},
    {'(def f "'.. Tests.tmpbin.. '") (writebin "42" f) (readbin f)', '42'},
    -- {'(# ARGS)', 2},
    -- {'(input "42")', '42'},

    -- os
    {'(> 1 (clock))', true, 'os'},
    {'(date "%d.%m.%Y")', os.date("%d.%m.%Y")},
    {'(date "%x %X" (time (date "*t" 10800)))', os.date("%x %X", os.time(os.date('*t', 10800)))},

    {'(get (date "*t") "hour")', os.date('*t').hour},
    {'(time (dict ["year" 1983] ["month" 7] ["day" 19]))',
        os.time({year=1983, month=7, day=19})},
    {'(def var (time (dict ["year" 1983] ["month" 7] ["day" 19]))) (difftime  (time) var)', os.difftime(os.time(), os.time({year=1983,month=7,day=19}))},
    {'(execute)', true},
    {'(execute "mkdir 42") (remove "42")', true},
    {'(execute "mkdir 42") (rename "42" "kiss") (remove "kiss")', true},
    {'(? (tmpname))', 'string'},
    {'(getenv "USER")', os.getenv('USER')},
    {'(getenv "HOME")', os.getenv('HOME')},
    {'(setlocale)', os.setlocale()},
    {'(setlocale "fr_FR") (-> (num 3.14))', tonumber(3.14); os.setlocale('C')},
    -- {'(exit true) (exit 0)', true},

    --def
    {'(-> (def x 0))', nil},
    {'(-> (mut x 0))', nil},
    {'(def var42 "2") (# var42)', 1, 'def'},
    {'(def var "kiss") (-> var)', 'kiss'},
    {'(def var (+ 8 8)) (-> (? var))', 'number'},
    {'(def x 8) (def y 8) (-> (+ x y))', 16},
    {'(def lst [2 4 8 16 true]) (type lst)', 'list'},
    {'(def x (+ 8 8)) (def y 8) (-> (+ x y))', 24},
    {'(def (func x) (-> (- 2 x))) (func 2)', 0},
    {'(def (func x) (+ x 2)) (func 2)', 4},
    {'(def (func x y) (-> x y)) (def v1 v2 (func 1 2)) (-> v2)', 2},
    {'(def (func v1 v2) (-> (add v1 v2))) (func 2 2)', 4},
    {'(def (func var) (-> var)) (+ (func 2) (func 4))', 6},
    {'(def (func x y) ((-> x) (-> y))) (func 1 2)', 1},
    {'(def (func v1 v2) ((def v1 (+ v1 1)) (-> true) (add v1 v2))) (func 2 2)', true},
    {'(def (func v1 v2) ((def v1 (+ v1 1)) (add v1 v2))) (func 2 2)', 5},
    {'(def (func x) (+ 1 x) (-> (modf x))) (func 6.14)', 6, 0.14},
    {'(def (func) (== 2 2)) (def var (if (-> func) (-> true) (-> false))) (-> var)', true},
    {'(def x 1) (for (var [1]) (mut x (+ x var))) (def (func x) (mut x (.. x x)) (-> x)) (-> (func "kiss"))', 'kisskiss'},
    {'(def (func) (for (var (range 2 16)) ((if (== var 4) (-> var) (-> (* 4 var))) (-> var)))) (-> (func))', 16},
    {'(def (func s1) (def s2 "ss \'def\'") (upper (.. s1 s2))) (-> (func \'ki\'))',"KISS 'DEF'"},

    -- return def
    {'(def (func x) (def (f y) (+ x y)) (-> f)) (def savefunc (func 2)) (savefunc 40)', 42, 'return def'},
    {'(def (func) (-> upper)) (def savefunc (func)) (savefunc "kiss")', 'KISS'},
    {'(def (main x) (def (f1 y) (def (f2 z) (* x y z)) (-> f2)) (-> f1)) (def setmain (main 2)) (def setfunc (setmain 4)) (setfunc 8)', 64},

    -- mut
    {'(def var 0) (for (var (range 2 4)) (def var (+ var var))) (-> var)', 0, 'mut'},
    {'(def var 0) (for (var (range 2 4)) (mut var (+ var var))) (-> var)', 8},
    {'(def x 0) (def tab (dict ["?" 4])) (for (var tab) (mut x (get tab var))) (-> x)', 4},
    {'(def x 0) (def (func) (for (v1 (range 2 16)) (for (v2 (range 2 16)) ((if (== v2 4) (-> v2) (mut x (* 2 v2))))))) (func)', 4},
    {'(def x 0) (def (func) (for (var (range 2 8)) ((if (== var 4) (mut x var) (mut x (* 2 var))) (-> var)))) (func) (-> x)', 16},

    -- scope
    {'(def (func x) (-> (+ 1 x))) (def (same) (mut (func y) (-> (+ 2 y))) (func 1)) (-> (same))', 3, 'scope'},
    {'(def (func x) (-> (+ 1 x))) (def (same) (def (func y) (-> (+ 2 y))) (func 1)) (-> (same))', 3},
    {'(def (func x) (-> (+ 1 x))) (def (diff) (def (func y) (-> (+ 2 y))) (func 1)) (diff) (-> (func 1))', 2},

    -- integration
    {'(def (func v1) ((def v2 1) (-> (+ v1 v2)))) (-> (func 1))', 2, 'integration'},
    {'(def (func var) (-> (round var 1))) (def y (func 3.14)) (-> y)', 3.1},
    {'(def (func x y) ((def x (+ 1 x)) (def y (+ 2 y)) (-> [x y]))) (last (func 2 2))', 4},
    {'(def (fact var) (if (== var 1) (-> var) (-> (* var (fact (- var 1)))))) (fact 6)', 720},
    {'(def (fibo n) (if (< n 2) (-> n) (-> (+ (fibo (- n 1)) (fibo (- n 2)))))) (fibo 7)', 13},

    -- error
    {'("predef" (-> "predef"))', 'error', 'error'},
    {'(merge ["?" 42] "kiss" "32")', 'error'},
    {'(merge "kiss" ["?" 42])', 'error'},
    {'(for ("var" [2 4]) (-> var))', 'error'},
    {'(def "var" 2) (-> var)', 'error'},
    {'(def "var1" "var2" (unpack ["kiss" "42"]))', 'error'},
    {'(def ("var") (-> false))','error'},
    {'(def (func x) (256)) (func 2)', 'error'},
    {'(def (func x) (x)) (func 128)', 'error'},
    {'(def (func x) (x)) (func "kiss")', 'error'},
    {'("'..RE.tokenize('predef')..'")', 'error'},
    {'('..RE.tokenize('predef')..')', 'error'},
    {'(def -var  (- 1 -1))', 'error'},
    {'(def -var  -1)','error'},
    {'(def (func-func var)  (-> -1))','error'},
    {'(# [undef merge])', 'error'},
    {'(# #)', 'error'},
    {'(def 42var 42)', 'error'},
    {'(def ?var 2)', 'error'},
    {'(def ^v^ 2) (show ^v^)','error'},
    {'(def (func) ((def x 2))) (func) (-> x)', 'error'},
    {'(def (fake) (def x 2)) (func)', 'error'},
    {'(-> var)', 'error'},
    {'(if (== 4 4) (def x 1) (def y 0)) (->  y)', 'error'},
    {'(def ('..RE.tokenize('func')..') (-> true))', 'error'},
    {'(if (== 4 4) (def '..RE.tokenize('x')..' 1)) (-> '..RE.tokenize('x')..')','error'},
    {'(for ('..RE.tokenize('var')..' [2 4]) (-> '..RE.tokenize('var')..'))', 'error'},
    {'(eval "(def '..RE.tokenize('var')..' (-> "predef"))") (-> '..RE.tokenize('var')..')', 'error'},
    {'(def var #n) (if (-> var) (-> true) (-> false))', 'error'},
    {'(get (del (dict ["42" "kiss"]) "42") "42")', 'error'},
    {'(get (del [2 4] 1) 2)', 'error'},
    {'(readfile "nofile")', 'error'},
    {'(setlocale "all")', 'error'},
}

function Tests.execute(Eval, Def, test)
    local result = Eval.eval(test[1], Def, {})

    local check =
        (
            (
                Tests.savederror and tostring(Tests.savederror):find('Error:')
                and assert('error' == test[2], '\n--Fail\n')
            )
            or assert(result == test[2], '\n--Fail\n')
        )
        and 'Pass'
    return check
end

function Tests.run(Eval, Def)
    Tests.isdebug = true

    io.write('--Def Tests--\n')

    local failed = {}
    for id, test in pairs(Tests.tests) do
        if #test==3 then
            io.write('--Group ', test[3],'\n')
        end
        local body = '--Test '..id..'\n'..test[1]
        io.write(body)

        local exe, result = pcall(Tests.execute, Eval, Def, test)
        Tests.savederror = false

        if not exe then
            failed[#failed+1] = body..'\n'
        end
        io.write('\n--', result, '\n\n')
    end


    os.remove(Tests.tmpfile)
    os.remove(Tests.tmpbin)
    os.remove(Tests.tmpexpr)

    io.write('--Total ',#Tests.tests)
    io.write('\n\n--Failed ', #failed, '\n')
    io.write(unpack(failed))
    io.write('\n--Done--\n')
end

return Tests
