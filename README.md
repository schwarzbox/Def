# Def

Programming language from Scheme family.

v1.0

Def is implemented in Lua.

``` scheme
#!/usr/bin/env def
(show VERSION)
; check predefined functions
(show (predef))
; check selfdefined functions
(show (selfdef))

```

Examples.

1. Basic

``` scheme
; define var
(def var 'kiss')
(show (upper var))

; define vars
(def a b c (2 4 8))
(show a b c)

; math
(show (+ a b c))

; define list
(def lst [2 4 8])

; unpack
(def a b c (unpack lst))
(show a b c)

; define function
(def (returnAll) (
   (2 2 2 2 2 2)
))
(show (returnAll))

; closure
(def (closure x)
 (
  (def (nested)
    (mut x (+ x 1))
  )
  nested
 )
)

(def counter (closure 10))

(show (counter))
(show (counter))
(show (counter))

; factorial
(def (fact var)
 (if (== var 1)
  (var)
  (* var (fact (- var 1))))
)

(show (fact 6))

; strings

(def n 10000)

(def t (clock))
(def string '')
(for (v (range n))
    (mut string (.. string "0000"))
 )

(show 'Join' n '| string |' (- (clock) t))

```

2. Lambda.

``` scheme
(show (map [1 2 3] (lambda (x) (+  x 1))))
(show (concat (map [1 2 3] (L () (1))) "|"))
```

3. Load

``` scheme
(writefile "tmp.def" "(def (print message) (show message))")
(load "tmp.def")
(print "Hello World")
```

4. Thread

``` scheme
; create thread
(def th
 (thread
  (def (func n) (
   (for (var (range n))
    (yield 'do'))
   'fin')
  )
 )
)

(show (? th))
(show (run th 2))
(show (run th))
(show (run th))
; check that thread is dead
(show (? th))

; wrap function
(def (func n) (
 (for (var (range n))
   (yield 'do')
   )
 'fin'
 )
)

(def coro (wrap func))

(show (? coro))
(show (coro 2))
(show (coro))
(show (coro))
; can't check that thread is dead
(show (? coro))

```

5. Lazy

``` scheme
; @ stop code evaluation
(def lazyCode @[(* (sin 1.1) (cos 2.03))])
; use do to evaluate code
(show (do lazyCode))
; change lazyCode
(set (first lazyCode) 3 @(cos 1))
(show (last (do lazyCode)))
```

6. Get N-th fibonachi number

``` scheme
(def n 16)

(def (fibonachi n)
 (if (< n 2)
  (n)
  (+ (fibonachi (- n 1)) (fibonachi (- n 2)))
 )
)

(def t (clock))
(show 'Fibonacci' n '|' (fibonachi n) '|' (- (clock) t))
```

7. Get N-th fibonachi number with cache

``` scheme
(def cache (dict))
(def (fibocache n)
 (
  (def fib
   (switch
    (< n 2) (n)
    (has (keys cache) n) (get cache n)
    (true) (+ (fibocache (- n 1)) (fibocache (- n 2))))
   )
  (set cache n fib)
  fib
 )
)

(show (fibocache 30))
```

8. Colatz problem (with 27 you get C stack overflow)

``` scheme
(def (colatz n)
 (switch
  (== n 1) (n)
  (== (modulo n 2) 0) (colatz (// n 2))
  (true) (colatz (+ 1 (* 3  n)))
 )
)
(show (colatz 19))
```
