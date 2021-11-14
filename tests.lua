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
    {'( # ( get "kiss" 1  ) )', {1}, 'clear'},
    {'(((+ 2 2 2 2) (+ 2 2 2 2)))', {8}},
    {'(((.. (((? "kiss"))) ((((? "kiss")))))))', {'stringstring'}},
    {'((((+ ((pow 2 3))))))', {8.0}},
    {'(? "kiss"))', {'error'}},
    {'(? "kiss)', {'error'}},
    {"(? kiss')", {'error'}},
    {'("[2 4))', {'error'}},
    {'(def st1 \'"\') (def st2 \'"\') (def st3 "\'") (st3)', {"'"}},
    {'(8 "string")', {8, 'string'}},
    {'((# "  kiss  ") (? "     "))', {'string'}},
    {'(first [(# "  kiss  ") (? "     ")])', {8}},
    {'(")(  \' 1 \'  ))(" \') "  2   ")((\')', {")(  \' 1 \'  ))(", ') "  2   ")(('}},
    {'(def var "kiss \'def\'") (var)', {"kiss 'def'"}},
    {'(def var \'kiss "def"\') (var)', {'kiss "def"'}},
    {'(def var "_2_") (var)', {"_2_"}},
    {'(def var "1\t2\n3") (var)', {"1\t2\n3"}},

    --comment
    {'(def var1 (+ 42 42)) ; (def var2 (+ 2 2))\n (# (selfdef))', {1}, 'comment'},
    {'(def file "'.. Tests.tmpexpr.. '") (writefile file "; (+ 42 1)") (load file)', {'error'}},
    {'(def file "'.. Tests.tmpexpr.. '") (writefile file "(+ 42 1)") (load file)', {43}},
    -- show
    {'(# (show (? show)))', {10}},
    {'(# (show))', {0}},

    -- predef&token
    {'(? (first (keys (predef))))', {'string'}},
    {'(has (first (keys (predef))) "'..RE.token..'" )', {false}},

    -- no override
    {'(def show (+ 0 42)) (show)', {42}},

    -- basic
    {'(VERSION)', {settings.VERSION .. ' ('.. _VERSION .. ')'}, 'basic'},
    {'(len [1 2 3])', {3}},
    {'(# (range 1 8))', {8}},
    {'(# (range 8))', {8}},
    {'(# (range 1 8 2))', {4}},
    {'(# (dict ["?" 2] ["kiss" 4]))', {2}},
    {'(# "kiss")', {4}},
    {'(# "\'kiss\' \'kiss\'")', {13}},
    {'(# "2")', {1}},
    {'(# " ")', {1}},
    {'(type 1)', {'number'}},
    {'(? "kiss")',{'string'}},
    {'(? "kiss \'world\'")', {'string'}},
    {'(? (last ["def" "predef" "selfdef"]))', {'string'}},
    {'(? add)', {'function'}},
    {'(? false)', {'boolean'}},
    {'(? [])', {'list'}},
    {'(? (dict ["?" 2] ["kiss" 4]))', {'dict'}},
    {'(? "show")', {'string'}},
    {'(? (first [def selfdef]))',{'function'}},
    {'(? (last [def selfdef]))',{'function'}},
    {'(assert (== 2 2) "Assertion Error")',{true}},
    {'(assert (!= 2 2) "Assertion Error")', {'error'}},
    {'(def (fake) (error "error")) (def (emp) (false)) (fake) (emp)', {'error'}},
    {'(num "2")', {2}},
    {'(str 2)', {"2"}},
    {'("")', {''}},
    {'("" 0)', {'', 0}},
    {'(3)', {3}},
    {'(((* 2 2 2)))', {8}},
    {'(true)', {true}},
    {'(false)', {false}},
    {'(def (func) ((def fail false) fail)) (func)', {false}},
    {'(2 "kiss" 42)', {2, "kiss", 42}},
    {'(+ (2 2 2) (2))', {8}},
    {'(def (func x) ((# x) ("kiss") x)) (func "KISS")', {'KISS'}},
    {'(def (func x) ((# x) x)) (func "KISS")', {'KISS'}},
    {'(def (func x) ((def x (upper x)) x)) (func "kiss")', {"KISS"}},
    {'(eval "(+ 2 2 2)")', {6}},
    {'(eval "(\'comment\')")', {'comment'}},
    {'(eval "(join "kiss" "kiss")")', {"kisskiss"}},
    {'(eval "(def ct "") (for (var ["42" "L"]) (mut ct (.. ct var))) (ct)")', {"42L"}},
    {'(eval "(def (var) ("kiss"))") (var)', {"kiss"}},
    {'(eval \"(def var (\"kiss\"))\") (var)', {"kiss"}},

    {'(def f "'.. Tests.tmpexpr.. '") (writefile f "(+ 2 2)") (load f)', {4}},
    {'(def f "'.. Tests.tmpexpr.. '") (writefile f "(def (module) (\'kiss\'))") (load f) (module)', {"kiss"}},
    {'(try add 2 2)', {4}},
    {'(def x 2) (def y 2) (try sub x y)', {0}},
    {'(def res err (try add "kiss" 128)) res', {false}},
    {'(? (last (pack (try add "kiss" var))))', {'string'}},
    {'(show (try add "kiss" 128)) ("42")', {"42"}},
    {'(show (try add "kiss" var)) ("42")', {"42"}},
    {'(show (try add "kiss" -var)) ("42")', {"42"}},
    {'(def (wh *) ((unpack *))) ((wh 0 2))', {0, 2}},

    -- bits
    {'(& 1 1)', {1}, 'bits'},
    {'(& 2 1)', {0}},
    {'(| 2 1)', {3}},
    {'(~ 1 0)', {1}},
    {'(~ 2 1)', {3}},
    {'(<< 1 1)', {2}},
    {'(>> 1 1)', {0}},
    {'(<< 1 1 1 1 1 1 1 1)', {128}},
    {'(<< 1 7)', {128}},
    {'(>> 1 -4)', {16}},
    {'(<< 1 4)', {16}},
    {'(>> 1 4)', {0}},
    {'(~ 0)', {-1}},
    {'(| 0 (pow 2 32))', {4294967296}},
    {'(def setup (| 0 (<< 1 0))) ((| setup (<< 1 3 )))', {9}},
    {'(def setup (| 1 (<< 1 3))) ((& setup (<< 1 3 )))', {8}},
    {'(def setup (| 1 (<< 1 3))) ((& setup (~ (<< 1 3))))', {1}},

    -- math
    {'(add -2 -2 -4)', {-8}, 'math'},
    {'(+ 2 2 2 2)', {8}},
    {'(sub 2 2 2 2)', {-4}},
    {'(- 2 2)', {0}},
    {'(mul 2 2 4)', {16}},
    {'(* 2 2)', {4}},
    {'(div 2 0)', {1/0}},
    {'(/ 2 4)', {0.5}},
    {'(fdiv 4 3)', {1}},
    {'(// 8 3)', {2}},
    {'(modulo 3 4)', {3}},
    {'(pow 2 10)', {1024}},
    {'(pow 2 0.5)', {math.pow(2, 0.5)}},
    {'(+ (/ (+ 2 (- 2 (* 2 (pow 2 2)))) 4) 1)', {0}},
    {'(abs -1)', {1}},
    {'(acos -1)', {math.acos(-1)}},
    {'(asin -1)', {math.asin(-1)}},
    {'(atan -1)', {math.atan(-1)}},
    {'(ceil PI)', {math.ceil(math.pi)}},
    {'(cos -1)', {math.cos(-1)}},
    {'(deg -1)', {math.deg(-1)}},
    {'(exp 1)', {math.exp(1)}},
    {'(HUGE)', {math.huge}},
    {'(floor PI)', {math.floor(math.pi)}},
    {'(fmod PI 4)', {math.pi}},
    {'(log 2 7)', {math.log(2, 7)}},
    {'(max 20 3 5 6)', {20}},
    {'(min 20 3 5 6)', {3}},
    {'(modf PI)', {math.modf(math.pi)}},
    {'(modf 6.14)', {math.modf(6.14)}},
    {'(MAXINT)', {math.maxinteger}},
    {'(MININT)', {math.mininteger}},
    {'(PI)', {math.pi}},
    {'(rad 45)', {math.rad(45)}},
    {'(round 3.1416 2)', {3.14}},
    {'((randomseed))', {true}},
    {'(randomseed 2) (random 0 42)', {34}},
    {'(pow 2 0.5)', {math.pow(2, 0.5)}},
    {'(sin -1)', {math.sin(-1)}},
    {'(sqrt 1)', {math.sqrt(1)}},
    {'(sqrt 128)', {math.sqrt(128)}},
    {'(tan -1)', {math.tan(-1)}},
    {'(ult 42 128)', {math.ult(42, 128)}},

    -- condition
    {'(== 2 2)', {true}, 'condition'},
    {'(== 1 0)', {false}},
    {'(!= 2 2)', {false}},
    {'(!= 3.14 3.1416)', {true}},
    {'(!= 2 2)', {false}},
    {'(!= 2 2)', {false}},
    {'(> 2 1)', {true}},
    {'(>= 2 2)', {true}},
    {'(>= 4 2)', {true}},
    {'(< 2 1)', {false}},
    {'(<= 2 2)', {true}},
    {'(<= 4 2)', {false}},
    {'(and 0 0)', {0}},
    {'(and 2 true)', {true}},
    {'(&& 2 false)', {false}},
    {'(or true 2)', {true}},
    {'(|| false 4)', {4}},
    {'(|| (== (# "kiss") 4) (== (# "def") 4))', {true}},
    {'(! false)', {true}},
    {'(! (> 2 4))', {true}},
    {'(def x 0) (if (== x 0) (def x 2) (def x 4)) (x)', {0}},
    {'(def x y (0 0)) (if (== 4 4) (mut x 1) (mut y 0)) (x)', {1}},
    {'(def x 0) (if (!= (? 4 ) "string") (def x 1)) (x)', {0}},
    {'(if (has (keys (dict ["kiss" 42] [2 "42"])) "kiss") (1) (0))', {1}},
    {'(if (0) (true) (false))', {true}},
    {'(if ("") (true) (false))', {true}},
    {'(if (false) (true) (false))', {false}},
    {'(if (== 0 1) (true))', {false}},
    {'(def x 1) (switch (== x 1) ("kiss") (== x 2) ("42"))', {'kiss'}},
    {'(def x 1) (def lst []) (while (true) (switch (== x 3) (break) (== x 2) ((push lst x) (continue)) (true) ((push lst x) (mut x (+ x 1))))) (# lst)', {3}},
    {'(def x 1) (def lst []) (while (< (# lst) 1) (switch (== x 3) (push lst x) (true) (mut x (+ x 1)))) (last lst)', {3}},
    {'(def x 3) (switch (== x 1) (1) (== x 2) (2) (true) ("default"))', {'default'}},
    {'(def x 3) (switch (== x 1) (1) (== x 2) (2))', {'error'}},


    -- for
    {'(def x 0) (for (var [2 4]) (mut x (+ var 1))) (x)', {5}, 'for'},
    {'(def x (for (var [2 4]) (+ var 1))) (x)', {5}},
    {'(def x 0) (for (var (range 2 4)) (mut x (+ var 1))) (x)', {5}},
    {'(def x (for (var (range 2 8)) (if (== var 4) (var) (* var 4)))) (x)', {32}},
    {'(def x (for (var (range 0 8)) (if (== var 2) (break) (mut var (* 4 var)))))', {4}},
    {'(def x (for (var []) (var))) x', {false}},

    -- while
    {'(def cnt 0) (while (&& (< cnt 64) (> cnt -1)) (mut cnt (+ cnt 1))) cnt', {64}},
    {'(def cnt 0) (while (&& (< c 64) (> cnt -1)) (mut cnt (+ cnt 1))) cnt', {'error'}},

    -- break&continue
    {'(def cnt 0) (while (< cnt 64) (if (> cnt 32) (break) (mut cnt (+ cnt 1)))) (cnt)', {33}, 'break&continue'},
    {'(def cnt 0) (while (< cnt 4) (if (== cnt 2) (break)) (mut cnt (+ cnt 1))) cnt', {2}},
    {'(def x 0) (def cnt 0) (while (< cnt 4) (mut cnt (+ cnt 1)) (if (== x 2) (continue)) (mut x (+ x 1))) x', {2}},
    {'(def x 0) (def cnt 0) (while (< cnt 4) (mut cnt (+ cnt 1)) (if (== cnt 2) (continue)) (mut x (+ x 1))) x', {3}},
    {'(def lst []) (while (true) (push lst (# lst)) (if (> (# lst) 2) (break))) (last lst)', {2}},
    {'(def lst []) (while (< (# lst) 8) (push lst (# lst)) (if (|| (== (# lst) 2) (== (# lst) 4)) (continue)) (push lst "|")) (concat lst)', {'0|2|4|6|'}},
    {'(def x 0) (while (true) (while (true) (if (== x 2) (break) (mut x (+ x 1)))) (if (== x 2) (break))) x', {2}},
    {'(def x 0) (for (var (range 2 4)) ((if (== var 3) (break) (mut x var)))) (x)', {2}},
    {'(def x 0) (for (var (range 2 4)) (if (== var 3) (break) (mut x var)) (mut x (+ x 1))) x', {3}},
    {'(def x (for (var (range 2 4)) (if (== var 3) (break) (var)))) (x)', {2}},
    {'(def x 0) (for (var (range 1 4)) (if (== var 3) (break)) (mut x (* var 2))) (x)', {4}},
    {'(def x 0) (for (var (range 2 8)) ((if (== var 4) ((continue) (mut x var))))) (x)', {0}},
    {'(def x 0) (for (var (range 1 8)) (if (== var 4) (continue)) (mut x (+ x 1))) (x)', {7}},
    {'(def x 0) (for (var (range 2 8)) (if (== var 4) (continue) (mut x var))) x', {8}},
    {'(def x (for (var (range 2 4)) (if (== var 4) (continue) (* var 2)))) x', {6}},

    -- return
    {'(def (func x) (if (> x 2) ("return"))) (func 3)', {'return'}, 'return'},
    {'(def (func x) (if (> x 2) ("return")) (x)) (func 3)', {3}},
    {'(def (func x) ((if (> x 2) ("return")))) (func 3)', {'return'}},
    {'(def (func) (return clock)) (? (func))', {'function'}},
    {'(def (func x) (def (f y) (+ x y)) f) (def savefunc (func 2)) (savefunc 40)', {42},},
    {'(def (func) upper) (def savefunc (func)) (savefunc "kiss")', {'KISS'}},
    {'(def (main x) (def (f1 y) (def (f2 z) (* x y z)) f2) f1) (def setmain (main 2)) (def setfunc (setmain 4)) (setfunc 8)', {64}},
    {'(def z ["Z"]) (first z)', {"Z"}},
    {'(def z (list "Z")) (first z)', {"Z"}},
    {'(def z ("Z")) (first z)', {'error'}},

    -- list
    {'(last (range 2 8))', {8}, 'list'},
    {'(last (split "kiss"))', {'s'}},
    {'(last (split "kiss kiss" " "))', {'kiss'}},
    {'(first [2 4 8 16 "kiss"])', {2}},
    {'(last [2 4 8 16 "kiss"])', {"kiss"}},
    {'(first [])', {'error'}},
    {'(? (last ["2"]))', {'string'}},
    {'(? (last [["L" [4] 2] [4 [4 [16 16] "U" 8]] 2 1]))', {'number'}},
    {'(? (last [42 [2 2] 32 [1 1]]))', {'list'}},
    {'(last [])', {'error'}},
    {'(first (push [] 1))', {1}},
    {'(first (push [] "kiss" ))', {"kiss"}},
    {'(first (push [] "kiss"))', {"kiss"}},
    {'(def lst [1 2 3]) (push lst 4) (last lst)', {4}},
    {'(def lst [1 2 3]) (def lst (push lst 4)) (last lst)', {4}},
    {'(pop ["42" "kiss"])', {"kiss"}},
    {'(pop [])', {'error'}},
    {'(def lst [1 2 3]) (pop lst) (last lst)', {2}},
    {'(def lst [1 2 3]) (mut lst (pop lst)) (lst)', {3}},
    {'(first (sort [32 2 4 16 8]))', {2}},
    {'(first (sort [32 2 4 16 8] true))', {32}},
    {'(def lst [32 2 4 16 8]) (sort lst) (first lst)', {32}},
    {'(def lst [32 2 4 16 8]) (def lst (sort lst)) (first lst)', {2}},
    {'(first (flip [32 2 4 16 8]))', {8}},
    {'(concat ["L" "U" "S" "P"])', {'LUSP'}},
    {'(concat ["K" "I" "S" "S"] "|")', {'K|I|S|S'}},
    {'(concat ["K" "I" "S" "S"] "|" 2 3)', {'I|S'}},
    {'(unpack [0 42])', {0, 42}},
    {'(unpack [0 1 2 4 8 16 32] 2 4)', {1, 2, 4, 8}},
    {'(def var1 var2 var3 (unpack [2 4 8])) (var2)', {4}},
    {'(last (pack 0 42))', {42}},
    {'(last [upper (lower "KISS") (+ 1 1)])', {2}},
    {'(def lst [1 2 3 4 5 6]) (move lst 2 (# lst) 1) (get lst 1)', {2}},
    {'(def lst [1 2 3 4 5 6]) (move lst 1 3 4) (get lst 4)', {1}},
    {'(def cp []) (def lst [1 2 3 4 5 6]) (move lst 1 3 4 cp) (get cp 4)', {1}},

    -- dict
    {'(# (dict))', {0}, 'dict'},
    {'(def tab (dict ["?" "kiss"] [1 2])) (# (del tab 1))', {1}},
    {'(def tab (dict ["?" "kiss"])) (has (set tab "?" "Hi") "Hi")', {true}},
    {'(def tab (dict ["?" "kiss"])) (def var tab) (get var "?")', {'kiss'}},
    {'(last (keys [32 2 4 16 8]))', {5}},
    {'(last (values [32 2 4 16 8]))', {8}},
    {'(has (keys (dict ["kiss" 42] [2 "42"])) "kiss")', {true}},
    {'(has (values (dict ["kiss" 42] [2 "42"])) "42")', {true}},
    {'(def lst (range 4)) (def var 5) (if (has lst var) (true) (push lst var)) (last lst)', {5}},
    {'(first (map [2 3.14 4 "kiss" 16 true] ?))', {'number'}},
    {'(last (map [2 3.1416] round))', {3.14}},
    {'(def (func var) ((== var 16))) (# (filter [2 4 4 16] func))', {1}},
    {'(get (filter [2 4 8 16 32] (def (f x) (> x 16))) 5)', {32}},
    {'(get (map (dict ["42" "kiss"]) type) "42")', {'string'}},
    {'(last (merge ["?" 42] ["kiss" "32"]))', {"32"}},
    {'(get (merge (dict ["?" 42]) (dict ["kiss" "32"])) "kiss")', {"32"}},
    {'(# (merge (dict ["?" 42]) (range 4)))', {5}},
    {'(# (merge (range 1 8) (range 16 32 4)))', {13}},
    {'(? (merge (range 1 8) (range 16 32 4)))', {'list'}},
    {'(get (merge (dict ["?" "42"]) (dict ["kiss" "kiss"])) "?")', {'42'}},

    -- list&dict&string
    {'(get "kiss" 1)', {'k'}, 'list&dict&string'},
    {'(get ["42" "kiss"] 2)', {'kiss'}},
    {'(get (dict ["42" "kiss"]) "42")', {'kiss'}},
    {'(has ["42" "kiss"] "42")', {true}},
    {'(get [2 4 8] 2)', {4}},
    {'(has [2 4 8] 2)', {true}},
    {'(has (dict ["42" "kiss"]) "kiss")', {true}},
    {'(has "kiss" "s")', {true}},
    {'(has "kiss" "z")', {false}},
    {'(def tab (dict ["?" 42] ["2" "32"])) (get tab "2")', {'32'}},
    {'(set "kiss" 3 "l")', {'kils'}},
    {'(def var (set "kiss" 4 "42")) (get var (# var))', {'2'}},
    {'(def lst ["42" "kiss"]) (first (set lst 1 0))', {0}},
    {'(def tab (dict ["42" "kiss"])) (has (set tab "42" "0") "0")', {true}},
    {'(get (del [2 4] 1) 1)', {4}},
    {'(get (del "kiss" 1) 1)', {'i'}},
    {'(def var "kiss") (del var (# var))', {"kis"}},
    {'(get (del (dict ["?" 4] ["kiss" 42]) "?") "kiss")', {42}},
    {'(get (insert ["42" "kiss"] 2 "8" ) 2)', {'8'}},
    {'(get (insert (dict ["2" "42"]) 1 "kiss") 1)', {'kiss'}},
    {'(insert "kiss" 5 "42")', {"kiss42"}},
    {'(def var "kiss") (next var)', {'k'}},
    {'(def var "kiss") (next var 1)', {'i'}},
    {'(def lst [1 2 3 4 5 6]) (next lst)', {1, 1}},
    {'(def lst [1 2 3 4 5 6]) (next lst 1)', {2, 2}},

    -- string
    {'(upper "kiss")', {"KISS"}, 'string'},
    {'(lower "KISS")', {"kiss"}},
    {'(capitalize "kiss 42 world")', {'Kiss 42 world'}},
    {'(title "kiss-42 kiss.def")', {'Kiss-42 Kiss.def'}},
    {'(repeat "kiss" 4)', {'kisskisskisskiss'}},
    {'(replace "kiss" "k" "m")', {'miss', 1}},
    {'(replace "kiss" "s" "l")', {'kill', 2}},
    {'(find "kiss42" "42")', {5, 6}},
    {'(match "kiss42" "42" 1)', {'42'}},
    {'(match "kiss42" "%d+" 1)', {'42'}},
    {'(match "kiss42" "2" 5)', {'2'}},
    {'(reverse "KISS")', {"SSIK"}},
    {'(trim "  \nkiss \t")', {"kiss", 1}},
    {'(trim "||kiss||" "||")', {"kiss", 1}},
    {'(trim "\n\nkiss\n\n\n" "\n")', {"kiss", 1}},
    {' (? ..)', {'function'}},
    {'(.. "? " "kiss")', {'? kiss'}},
    {'(join "42" "kiss")', {'42kiss'}},
    {'(.. "_" "42")', {'_42'}},
    {'(format "%s | %s" "kiss" "?")', {"kiss | ?"}},
    {'(format "%q" "kiss")', {"\"kiss\""}},
    {'(format "%c%c%c" 65 66 67)', {"ABC"}},
    {'(format "%.1f" 42.42)', {"42.4"}},
    {'(# (byte "⌘" 1 (# "⌘")))', {3}},
    {'(first (byte "KISS" 1 -1))', {75}},
    {'(first (char 65 66 67))', {'A'}},
    {'(unpack (char 65 66 67) 1 1)', {'A'}},
    {'(def a b c (unpack (char 65 66 67))) (c)', {'C'}},
    {'(insert (unpack ["kiss" 5 "42"]))', {"kiss42"}},

    -- input
    {'(def f "'.. Tests.tmpfile.. '") (writefile f "42") (readfile f)', {'42'}, 'input'},
    {'(def f (open "'.. Tests.tmpfile.. '" "w+")) (? f)', {'open file'}},
    {'(def f (open "'.. Tests.tmpfile.. '")) (close f) (type f)', {'closed file'}},
    {'(first (readlines "tests.lua"))', {'-- Def'}},
    {'(def lst []) (def ln (open "tests.lua")) (def it (lines ln)) (for (var it) (push lst var)) (close ln) (first lst)', {'-- Def'}},
    {'(def f "'.. Tests.tmpbin.. '") (def fl (open f "wb")) (write fl "42") (close fl) (def fl (open f "rb")) (read fl "a")', {'42'}},
    {'(def fl (open "'.. Tests.tmpfile.. '" "w+")) (write fl "def") (seek fl "cur" -1) (read fl)', {'f'}},
    {'(def tmp (tmpfile)) (write tmp "tmp") (seek tmp "set" 0) (read tmp "a")', {'tmp'}},
    {'(def sf (shell "ls" "r")) (has (read sf "l") "def")', {true}},
    {'(def sh (shell \'cat > "'.. Tests.tmpfile.. '"\' \'w\')) (write sh "kiss") (close sh) (first (readlines "'.. Tests.tmpfile.. '"))', {'kiss'}},
    {'(def f (open "tmp")) (close f) (seek f)', {'error'}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w+")) (write f "kiss") (seek f)', {4}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w+")) (write f "kiss") (seek f "set")', {0}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w+")) (write f "kiss") (seek f "cur" -2)', {2}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w+")) (write f "kiss") (seek f "set") (read f 1)', {"k"}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w+")) (write f "kiss") (seek f "set") (read f 1) (seek f "end" -1)', {3}},
    {'(def f1 (open "'.. Tests.tmpfile.. '" "w")) (write f1 "kiss") (flush f1) (def f2 (open "'.. Tests.tmpfile.. '")) (seek f2 "set") (read f2)', {'kiss'}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w")) (buffer f "no") (write f "kiss") (def var (readfile "'.. Tests.tmpfile.. '")) (close f) (var)', {'kiss'}},
    -- ('')
    {'(def f (open "'.. Tests.tmpfile.. '" "w")) (buffer f "line") (write f "kiss") (def var (readfile "'.. Tests.tmpfile.. '")) (close f) (var)', {''}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w")) (buffer f "line") (write f "kiss\n") (readfile "'.. Tests.tmpfile.. '")', {'kiss\n'}},
    {'(def f (open "'.. Tests.tmpfile.. '" "w")) (buffer f "full") (write f "kiss\n") (flush f) (readfile "'.. Tests.tmpfile.. '")', {'kiss\n'}},
    -- for tests 3
    {'(# ARGS)', {3}},
    -- {'(input "42")', '42'},

    -- os
    {'(> 1 (clock))', {true}, 'os'},
    {'(date)', {'error'}},
    {'(date "%d.%m.%Y")', {os.date("%d.%m.%Y")}},
    {'(date "%x %X" (time (date "*t" 10800)))', {os.date("%x %X", os.time(os.date('*t', 10800)))}},

    {'(get (date "*t") "hour")', {os.date('*t').hour}},
    {'(time (dict ["year" 1983] ["month" 7] ["day" 19]))',
        {os.time({year=1983, month=7, day=19})}},
    {'(def var (time (dict ["year" 1983] ["month" 7] ["day" 19]))) (difftime  (time) var)', {os.difftime(os.time(), os.time({year=1983,month=7,day=19}))}},
    {'(execute "mkdir 42") (remove "42")', {true}},
    {'(execute "mkdir 42") (rename "42" "kiss") (remove "kiss")', {true}},
    {'(? (tmpname))', {'string'}},
    {'(getenv "USER")', {os.getenv('USER')}},
    {'(getenv "HOME")', {os.getenv('HOME')}},
    {'(setlocale)', {os.setlocale()}},
    {'(setlocale "fr_FR") ((num 3.14))', {tonumber(3.14); os.setlocale('C')}},
    -- {'(exit true) (exit 1)', {true}},
    -- {'(exit false) (exit 0)', {false}},

    --def
    {'((def x 0))', {0}, 'def'},
    {'((mut x 0))', {0}},
    {'(def (func x) (x)) (func 128)', {128}},
    {'(def (func x) (x)) (func "kiss")', {'kiss'}},
    {'(def (func x) (x)) (func true)', {true}},
    {'(def (func x) (x "kiss")) (func upper)', {'KISS'}},
    {'(def (func x) (x)) (? (wrap upper))', {'function'}},
    {'(def (func x) (x)) (? (iter [1 2]))', {'suspended thread'}},
    {'(def st "%s%")', {"%s%"}},
    {'(def var42 "2") (# var42)', {1}},
    {'(.. "_" "42")', {'_42'}},
    {'(def var "kiss") (var)', {'kiss'}},
    {'(def var (+ 8 8)) (? var)', {'number'}},
    {'(def v1 v2 ("1" 2)) ((v1) v2)', {2}},
    {'(def v1 v2 ("1" 2)) (v1 v2)', {"1", 2}},
    {'(def v1 v2 ("1" 2)) (first [v1 v2])', {'1'}},
    {'(def (func) ((def v1 v2 ("1" 2)) ((? v1) v2))) (func)', {2}},
    {'(def (func) ((def v1 v2 ("1" 2)) (v1 v2))) (func)', {"1", 2}},
    {'(def x 8) (def y 8) ((+ x y))', {16}},
    {'(def lst [2 4 8 16 true]) (type lst)', {'list'}},
    {'(def x (+ 8 8)) (def y 8) ((+ x y))', {24}},
    {'(def (func x) ((- 2 x))) (func 2)', {0}},
    {'(def (func x) (+ x 2)) (func 2)', {4}},
    {'(def v1 v2 ("predef" ("predef"))) (v1)', {'predef'}},
    {'(def (f st) (upper st)) ((f "kiss"))', {"KISS"}},
    {'(def lst [(def k 2) (+ 2 2) (upper "kiss")]) (first lst)', {2}},
    {'(def x ([1])) (last x)', {1}},
    {'(1 (1))', {1, 1}},
    {'(true 1)', {true, 1}},
    {'(("_predef_"))', {'_predef_'}},
    {'(def v1 "_kiss_") (def v2 v1) ((upper v2))', {'_KISS_'}},
    {'(def var "_show_") ((lower var))', {"_show_"}},
    {'(("_kiss_"))', {'_kiss_'}},
    {'(def (func x) (256)) (func 2)', {256}},
    {'(def (func x y) (x y)) (def v1 v2 (func 1 2)) (v2)', {2}},
    {'(def (func v1 v2) ((add v1 v2))) (func 2 2)', {4}},
    {'(def (func var) (var)) (+ (func 2) (func 4))', {6}},
    {'(def (func x y) ((x) (y))) (func 1 2)', {2}},
    {'(def (func v1 v2) ((def v1 (+ v1 1)) (? v1) (add v1 v2))) (func 2 2)', {5}},
    {'(def (func x) (+ 1 x) ((modf x))) (func 6.14)', {math.modf(6.14)}},
    {'(def (func) (== 2 2)) (def var (if (func) (true) (false))) (var)', {true}},
    {'(def x 1) (for (var [1]) (mut x (+ x var))) (def (func x) (mut x (.. x x)) (x)) ((func "kiss"))', {'kisskiss'}},
    {'(def (func) (for (var (range 2 16)) ((if (== var 4) (var) ((* 4 var))) (var)))) ((func))', {16}},
    {'(def (func st) (upper st)) (func "kiss")', {'KISS'}},
    {'(def (func s1) (def s2 "ss \'def\'") (upper (.. s1 s2))) ((func \'ki\'))',{"KISS 'DEF'"}},

    -- lambda
    {'(concat (map [1 2 3] (L () (1))) "|")', {'1|1|1'}, 'lambda'},
    {'(first (map [1 2 3] (lambda (x) (+  x 1))))', {2}},
    {'(map [1 2 3] (lambda (x) (+  x 1))) (# (selfdef))', {0}},
    {'(last (last (map [1 2 3] (L (*) (push * (+ (get * 1) 1))))))', {4}},

    -- mut
    {'(def var 0) (for (var (range 2 4)) (def var (+ var var))) (var)', {0}, 'mut'},
    {'(def var 0) (for (var (range 2 4)) (mut var (+ var var))) (var)', {8}},
    {'(def x 0) (def tab (dict ["?" 4])) (for (var tab) (mut x (get tab var))) (x)', {4}},
    {'(def (func) (for (v1 (range 2 16)) (for (v2 (range 2 16)) ((if (== v2 4) (mut x (* v2 2)) (mut y (* v1 2))))))) (func)', {32}},
    {'(def (func) (for (v1 (range 2 16)) (for (v2 (range 2 16)) ((if (== v2 4) (mut x (* v2 2))))))) (func)', {8}},

    {'(def x 0) (def (func) (for (var (range 2 8)) ((if (== var 4) (mut x var) (mut x (* 2 var))) (var)))) (func) (x)', {16}},

    -- scope
    {'(def (func x) ((+ 1 x))) (def (same) (mut (func y) ((+ 2 y))) (func 1)) ((same))', {3}, 'scope'},
    {'(def (func x) ((+ 1 x))) (def (same) (def (func y) ((+ 2 y))) (func 1)) ((same))', {3}},
    {'(def (func x) ((+ 1 x))) (def (diff) (def (func y) ((+ 2 y))) (func 1)) (diff) ((func 1))', {2}},
    {'(def (nif x) (if (> x 1) (if (== x 2) ("two") (if (== x 3) ("three") ("four"))) ("zero"))) (nif 5)', {'four'}},

    -- integration
    {'(def (func v1) ((def v2 1) ((+ v1 v2)))) ((func 1))', {2}, 'integration'},
    {'(def (func var) ((round var 1))) (def y (func 3.14)) (y)', {3.1}},
    {'(def (func x y) ((def x (+ 1 x)) (def y (+ 2 y)) [x y])) (last (func 2 2))', {4}},
    {'(def (func x y) (def x (+ 1 x)) (def y (+ 2 y)) [x y]) (last (func 2 2))', {4}},
    {'(def (fact var) (if (== var 1) (var) ((* var (fact (- var 1)))))) (fact 6)', {720}},
    {'(def (fibo n) (if (< n 2) (n) ((+ (fibo (- n 1)) (fibo (- n 2)))))) (fibo 7)', {13}},
    {'(def (recur x) (if (< x 10) ((recur (+ x 1))) (x))) ((recur 0))', {10}},
    {'(def (closure x) (def (nested x) ((upper x))) (nested)) (def other (closure "kiss")) (other)', {'KISS'}},
    {'(def (colatz x) (if (== (modulo x 2) 0) (colatz (// x 2)) (if (== x 1) (x) (colatz (+ 1 (* 3  x)))))) (colatz 3)', {1}},
    {'(def (colatz x) (switch (== x 1) (x) (== (modulo x 2) 0) (colatz (// x 2)) (true) (colatz (+ 1 (* 3  x))))) (colatz 3)', {1}},

    -- coroutine&threads
    {'(? (thread add))',{ "suspended thread"}, 'coroutine&threads'},
    {'(? (iter (range 2)))', {"suspended thread"}},
    {'(? (wrap upper))', {"function"}},
    {'(def (func r) (for (var (range r)) (yield "do")) ("fin")) (def coro (wrap func)) (coro 2) (coro) (coro)', {"fin"}},
    {'(def coro (thread (def (f x y) ((yield x) (yield y))))) (run coro 1 2) (run coro)', {2}},
    {'(def coro (thread (def (f x y) ((yield x) (yield y))))) (run coro 1 2) (run coro) (run coro) (type coro)', {'dead thread'}},
    {'(def itlist (iter [1 2])) (run itlist) (run itlist) ((run itlist))', {false}},
    {'(def itd (iter (dict ["who" "ami"] ["kiss" "42"]))) (run itd) (run itd) (run itd)', {false}},

    -- code
    {'(def expr @[(* (sin 1.1) (cos 2.03))]) (set (last (first expr)) 1 "sin") (get (last (first expr)) 1)', {'sin'}, 'code'},
    {'(def expr @[(* (sin 1.1) (cos 2.03))]) (set (last (first expr)) 1 "sin") (last (do expr))', {math.sin(1.1) * math.sin(2.03)}},
    {'(def expr @[(* (sin 1.1) (cos 2.03))]) (set (first expr) 3 @(cos 1)) (last (do expr))', {math.sin(1.1) * math.cos(1)}},
    {'(def cd @[(def (func x y ) (+ x y)) (func 2 2)]) (last (do cd))', {4}},
    {'(last (do @[(def (func x y ) (+ x y)) (func 2 2)]))', {4}},
    {'(def cd @[(def (func x y ) (+ x y)) (func 2 2)]) (set (last cd) 3 "14") (last (do cd))', {16}},
    {'(def cd @[(def (func x y) (+ x y))]) (mut cd (merge cd @[(func 4 4)])) (last (do cd))', {8}},
    {'(def cd @[(.. "kiss" "42")]) (last (do cd))', {"kiss42"}},
    {'(def cd @[(.. "2")]) (push (last cd) @"32") (set (last cd) 1 @*) (last (do cd))', {64}},
    {'(def cd @[(def var 2) (upper "kiss")]) (last (do cd))', {'KISS'}},
    {'(def cd @[(def var1 2) @(def var2 4)]) (last (do (last cd)))', {'error'}},
    {'(def cd @[(.. "2")]) (set cd 1 (merge (last cd) @[2])) (set (last cd) 3 @"2") (last (do cd))', {'22'}},
    {'(def cd @[(concat (map [1 2 3] (L () (1))) "|")]) (set (last cd) (# (last cd)) @"%") (last (do cd))', {'1%1%1'}},
    {'(# (show @"kiss"))', {8}},
    {'(def x (@[1])) (last x)', {"1"}},
    {'(def x @([1])) x', {"([1])"}},
    {'(# (eval "(@[])"))', {0}},
    {'(? @[])', {'lazy'}},
    {'@(false true)', {"(false true)"}},
    {'(last [@false true])', {true}},
    {'(def cd @[]) (push cd @)', {'error'}},
    {'(@false)', {'error'}},

    -- error
    {'(merge ["?" 42] "kiss" "32")', {'error'}, 'error'},
    {'(def (empty)) (empty)', {'error'}},
    {'(merge "kiss" ["?" 42])', {'error'}},
    {'(for ("var" [2 4]) (var))', {'error'}},
    {'(def "var" 2) (var)', {'error'}},
    {'(def "var1" "var2" (unpack ["kiss" "42"]))', {'error'}},
    {'(def ("var") (false))', {'error'}},
    {'('..RE.tokenize('predef')..')', {'error'}},
    {'(def -var  (- 1 -1))', {'error'}},
    {'(def (func-func var)  (-1))', {'error'}},
    {'(def (_func var)  (-1))', {'error'}},
    {'(def (func_ var)  (-1))', {'error'}},
    {'(def (func) (upper)) (func)', {'error'}},
    {'(# [undef merge])', {'error'}},
    {'(# #)', {'error'}},
    {'(def e )', {'error'}},
    {'(def e ())', {'error'}},
    {'(def (emp) ()) (? (emp))', {'error'}},
    {'(if (== 2 2))', {'error'}},
    {'(def 42var 42)', {'error'}},
    {'(def var@ 2)', {'error'}},
    {'(def ?var 2)', {'error'}},
    {'(def ^v^ 2) (show ^v^)', {'error'}},
    {'(def (func) ((def x 2))) (func) (x)', {'error'}},
    {'(def (fake) (def x 2)) (func)', {'error'}},
    {'(var)', {'error'}},
    {'(if (== 4 4) (def x 1) (def y 0)) ( y)', {'error'}},
    {'(def ('..RE.tokenize('func')..') (true))', {'error'}},
    {'(if (== 4 4) (def '..RE.tokenize('x')..' 1)) ('..RE.tokenize('x')..')', {'error'}},
    {'(for ('..RE.tokenize('var')..' [2 4]) ('..RE.tokenize('var')..'))', {'error'}},
    {'(eval "(def '..RE.tokenize('var')..' ("predef"))") ('..RE.tokenize('var')..')', {'error'}},
    {'(def var #n) (if (var) (true) (false))', {'error'}},
    {'(get (del (dict ["42" "kiss"]) "42") "42")', {'error'}},
    {'(get (del [2 4] 1) 2)', {'error'}},
    {'(get "kiss" 0)', {'error'}},
    {'(insert [1 2 3 4] 6 5)', {'error'}},
    {'(insert [1 2 3 4] "5" 5)', {'error'}},
    {'(set ["k" "v"] 4 "kiss")', {'error'}},
    {'(readfile "nofile")', {'error'}},
    {'(setlocale "all")', {'error'}},
    {'(def dct (dict [])) (# dct)', {'error'}},
    {'(def dct (dict ["k"])) (# dct)', {'error'}},
    {'(if () (true) (false))', {'error'}},
    {'(? ())', {'error'}},
    {'(def x 1) (switch (== x 1) () (== x 2) ())', {'error'}},
    {'(? (continue))', {'error'}},
    {'(if (== 2 2) (break) (mut var (* 4 var)))', {'error'}}
}

function Tests.assert(results, test)
    local fail
    for i=1, #results do
        fail = assert(results[i] == test[2][i], '\n--Fail\n') and 'Pass'
    end
    return fail
end

function Tests.execute(Eval, Def, test)
    local results = {Eval.eval(test[1], Def, {})}

    return (
        (
            Tests.savederror
            and tostring(Tests.savederror):find('Error:')
            and assert('error' == test[2][1], '\n--Fail\n')
        )
        or Tests.assert(results, test)

    ) and 'Pass'
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
        print(exe, result)
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
